import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import 'helpers/test_database.dart';
import 'package:xinyuan_hotel/data/database.dart';
import 'package:xinyuan_hotel/data/dao/floor_dao.dart';
import 'package:xinyuan_hotel/data/dao/area_dao.dart';
import 'package:xinyuan_hotel/data/dao/table_dao.dart';
import 'package:xinyuan_hotel/data/dao/time_slot_dao.dart';
import 'package:xinyuan_hotel/data/dao/reservation_dao.dart';
import 'package:xinyuan_hotel/data/models/area.dart';
import 'package:xinyuan_hotel/data/models/dining_table.dart';
import 'package:xinyuan_hotel/data/models/floor.dart';
import 'package:xinyuan_hotel/data/models/quick_time_slot.dart';
import 'package:xinyuan_hotel/data/models/reservation.dart';

/// DAO 全量集成测试
/// 通过 sqflite_common_ffi + 内存/临时文件数据库，验证所有 DAO 行为
void main() {
  // 确保全局只初始化一次 ffi + path_provider mock
  setUpAll(() {
    TestDatabaseEnvironment.ensureInitialized();
  });

  // 每个测试前重置数据库（删除后重新创建）
  late DatabaseHelper dbHelper;
  late FloorDao floorDao;
  late AreaDao areaDao;
  late TableDao tableDao;
  late TimeSlotDao timeSlotDao;
  late ReservationDao reservationDao;

  setUp(() async {
    // 删除现有 db 文件，让 DatabaseHelper 重新创建（触发 _onCreate + 预置数据）
    await DatabaseHelper().deleteDb();
    dbHelper = DatabaseHelper();
    floorDao = FloorDao(dbHelper);
    areaDao = AreaDao(dbHelper);
    tableDao = TableDao(dbHelper);
    timeSlotDao = TimeSlotDao(dbHelper);
    reservationDao = ReservationDao(dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('FloorDao 全量', () {
    test('初始预置数据 - 2 个楼层', () async {
      final floors = await floorDao.getAll();
      expect(floors.length, 2);
      expect(floors[0].name, '一楼');
      expect(floors[0].sortOrder, 1);
      expect(floors[0].isMain, false);
      expect(floors[1].name, '二楼');
      expect(floors[1].isMain, true);
    });

    test('按 sortOrder 排序', () async {
      final floors = await floorDao.getAll();
      expect(floors[0].sortOrder <= floors[1].sortOrder, true);
    });

    test('getById - 存在', () async {
      final floor = await floorDao.getById(1);
      expect(floor, isNotNull);
      expect(floor!.name, '一楼');
    });

    test('getById - 不存在返回 null', () async {
      final floor = await floorDao.getById(999);
      expect(floor, isNull);
    });

    test('create - 新楼层', () async {
      final id = await floorDao.create(Floor(name: '三楼', sortOrder: 3, isMain: false));
      expect(id, greaterThan(0));
      final floors = await floorDao.getAll();
      expect(floors.length, 3);
      final newFloor = floors.firstWhere((f) => f.id == id);
      expect(newFloor.name, '三楼');
    });

    test('update - 修改楼层', () async {
      final floors = await floorDao.getAll();
      final first = floors.first;
      await floorDao.update(first.copyWith(name: '改名', isMain: true));
      final updated = await floorDao.getById(first.id!);
      expect(updated!.name, '改名');
      expect(updated.isMain, true);
    });

    test('canDelete - 有子区域不可删', () async {
      // 一楼已有区域，不可删
      final can = await floorDao.canDelete(1);
      expect(can, false);
    });

    test('canDelete - 无子区域可删', () async {
      // 新建一个无子区域的楼层
      final id = await floorDao.create(Floor(name: '空楼'));
      final can = await floorDao.canDelete(id);
      expect(can, true);
    });

    test('delete - 删除空楼层', () async {
      final id = await floorDao.create(Floor(name: '空楼'));
      await floorDao.delete(id);
      final floors = await floorDao.getAll();
      expect(floors.length, 2);
      expect(await floorDao.getById(id), isNull);
    });

    test('delete - 有子区域受外键限制', () async {
      // 一楼有区域，外键 ON DELETE RESTRICT 应阻止
      expect(
        () => floorDao.delete(1),
        throwsA(anything),
      );
    });
  });

  group('AreaDao 全量', () {
    test('初始预置数据 - 5 个区域', () async {
      final areas = await areaDao.getAll();
      expect(areas.length, 5);
      // 验证名称
      final names = areas.map((a) => a.name).toSet();
      expect(names, containsAll(['一楼大厅', '二楼大厅', 'VIP1号包厢', 'VIP2号包厢', '牡丹厅包厢']));
    });

    test('getByFloorId - 按楼层查询', () async {
      final floor1Areas = await areaDao.getByFloorId(1);
      expect(floor1Areas.length, 1);
      expect(floor1Areas.first.name, '一楼大厅');

      final floor2Areas = await areaDao.getByFloorId(2);
      expect(floor2Areas.length, 4);
    });

    test('getByType - 大厅', () async {
      final halls = await areaDao.getByType(AreaType.hall);
      expect(halls.length, 2);
      expect(halls.every((a) => a.type == AreaType.hall), true);
    });

    test('getByType - 包厢', () async {
      final rooms = await areaDao.getByType(AreaType.privateRoom);
      expect(rooms.length, 3);
      expect(rooms.every((a) => a.type == AreaType.privateRoom), true);
    });

    test('create - 新区域', () async {
      final id = await areaDao.create(Area(floorId: 2, name: '新包厢', type: AreaType.privateRoom, sortOrder: 99));
      final areas = await areaDao.getAll();
      expect(areas.length, 6);
      final newArea = await areaDao.getById(id);
      expect(newArea!.name, '新包厢');
    });

    test('update - 修改区域', () async {
      await areaDao.update(Area(id: 1, floorId: 1, name: '改大厅', type: AreaType.hall, sortOrder: 5));
      final a = await areaDao.getById(1);
      expect(a!.name, '改大厅');
      expect(a.sortOrder, 5);
    });

    test('canDelete - 有桌位不可删', () async {
      // 一楼大厅有桌位 A1/A2，不可删
      final can = await areaDao.canDelete(1);
      expect(can, false);
    });

    test('canDelete - 无桌位可删', () async {
      // 新建无桌位区域
      final id = await areaDao.create(Area(floorId: 1, name: '空区域', type: AreaType.hall));
      final can = await areaDao.canDelete(id);
      expect(can, true);
    });

    test('delete - 删除空区域', () async {
      final id = await areaDao.create(Area(floorId: 1, name: '空区域', type: AreaType.hall));
      await areaDao.delete(id);
      expect(await areaDao.getById(id), isNull);
    });

    test('delete - 有桌位受外键限制', () async {
      expect(
        () => areaDao.delete(1),
        throwsA(anything),
      );
    });

    test('外键约束 - floorId 不存在应失败', () async {
      expect(
        () => areaDao.create(Area(floorId: 999, name: '孤儿', type: AreaType.hall)),
        throwsA(anything),
      );
    });
  });

  group('TableDao 全量', () {
    test('初始预置数据 - 12 张桌', () async {
      final tables = await tableDao.getAll();
      expect(tables.length, 12);
    });

    test('getByAreaId - 一楼大厅 2 张', () async {
      final tables = await tableDao.getByAreaId(1);
      expect(tables.length, 2);
      expect(tables.every((t) => t.name.startsWith('A')), true);
    });

    test('getByAreaId - 二楼大厅 6 张', () async {
      final tables = await tableDao.getByAreaId(2);
      expect(tables.length, 6);
    });

    test('getByAreaId - VIP2号包厢 2 张', () async {
      final tables = await tableDao.getByAreaId(4);
      expect(tables.length, 2);
      // 大圆桌 20 位 + 小方桌 4 位
      final seats = tables.map((t) => t.seats).toSet();
      expect(seats, containsAll([20, 4]));
    });

    test('getById - 存在', () async {
      final t = await tableDao.getById(1);
      expect(t, isNotNull);
      expect(t!.name, 'A1');
      expect(t.seats, 8);
    });

    test('getById - 不存在', () async {
      expect(await tableDao.getById(999), isNull);
    });

    test('create - 新桌位', () async {
      final id = await tableDao.create(DiningTable(areaId: 1, name: 'A3', seats: 6, sortOrder: 3));
      final t = await tableDao.getById(id);
      expect(t!.name, 'A3');
      expect(t.seats, 6);
    });

    test('update - 修改桌位', () async {
      await tableDao.update(DiningTable(id: 1, areaId: 1, name: '改A1', seats: 10, sortOrder: 9));
      final t = await tableDao.getById(1);
      expect(t!.name, '改A1');
      expect(t.seats, 10);
    });

    test('delete - 删除桌位', () async {
      await tableDao.delete(1);
      expect(await tableDao.getById(1), isNull);
      final tables = await tableDao.getAll();
      expect(tables.length, 11);
    });

    test('外键约束 - areaId 不存在应失败', () async {
      expect(
        () => tableDao.create(DiningTable(areaId: 999, name: '孤儿', seats: 4)),
        throwsA(anything),
      );
    });

    test('排序 - 按 sortOrder', () async {
      final tables = await tableDao.getByAreaId(1);
      expect(tables[0].sortOrder <= tables[1].sortOrder, true);
    });
  });

  group('TimeSlotDao 全量', () {
    test('初始预置数据 - 2 个时段', () async {
      final slots = await timeSlotDao.getAll();
      expect(slots.length, 2);
      expect(slots[0].name, '午餐');
      expect(slots[0].startTime, '11:00');
      expect(slots[0].endTime, '13:00');
      expect(slots[1].name, '晚餐');
    });

    test('getById - 存在', () async {
      final s = await timeSlotDao.getById(1);
      expect(s, isNotNull);
      expect(s!.name, '午餐');
    });

    test('getById - 不存在', () async {
      expect(await timeSlotDao.getById(999), isNull);
    });

    test('create - 新时段', () async {
      final id = await timeSlotDao.create(QuickTimeSlot(name: '下午茶', startTime: '14:00', endTime: '16:00', sortOrder: 3));
      final s = await timeSlotDao.getById(id);
      expect(s!.name, '下午茶');
    });

    test('update - 修改时段', () async {
      await timeSlotDao.update(QuickTimeSlot(id: 1, name: '午市', startTime: '10:30', endTime: '13:30', sortOrder: 1));
      final s = await timeSlotDao.getById(1);
      expect(s!.name, '午市');
      expect(s.startTime, '10:30');
    });

    test('delete - 删除时段', () async {
      await timeSlotDao.delete(1);
      final slots = await timeSlotDao.getAll();
      expect(slots.length, 1);
    });
  });

  group('ReservationDao 全量', () {
    test('初始无预订', () async {
      final list = await reservationDao.getAll();
      expect(list, isEmpty);
    });

    test('create - 大厅桌预订', () async {
      final id = await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '2026-06-27T10:00:00',
        updatedAt: '2026-06-27T10:00:00',
      ));
      expect(id, greaterThan(0));
      final r = await reservationDao.getById(id);
      expect(r, isNotNull);
      expect(r!.customerTitle, '张先生');
      expect(r.tableId, 1);
      expect(r.status, ReservationStatus.booked);
    });

    test('create - 包厢预订', () async {
      final id = await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '17:00',
        endTime: '19:00',
        areaId: 4,
        customerTitle: '李女士',
        guestCount: 8,
        createdAt: '',
        updatedAt: '',
      ));
      final r = await reservationDao.getById(id);
      expect(r!.areaId, 4);
      expect(r.tableId, isNull);
      expect(r.guestCount, 8);
    });

    test('getByDate - 按日期查询', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-28',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '李先生',
        createdAt: '',
        updatedAt: '',
      ));
      final today = await reservationDao.getByDate('2026-06-27');
      expect(today.length, 1);
      expect(today.first.customerTitle, '张先生');
    });

    test('getByDate - 按开始时间排序', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '13:00',
        endTime: '15:00',
        tableId: 1,
        customerTitle: '晚',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 2,
        customerTitle: '早',
        createdAt: '',
        updatedAt: '',
      ));
      final list = await reservationDao.getByDate('2026-06-27');
      expect(list[0].startTime, '11:00');
      expect(list[1].startTime, '13:00');
    });

    test('getByDateRange - 范围查询', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-25',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-30',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'C',
        createdAt: '',
        updatedAt: '',
      ));
      final range = await reservationDao.getByDateRange('2026-06-26', '2026-06-28');
      expect(range.length, 1);
      expect(range.first.customerTitle, 'B');
    });

    test('getByStatus - 按状态查询', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        status: ReservationStatus.booked,
        createdAt: '',
        updatedAt: '',
      ));
      final id2 = await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '12:00',
        endTime: '14:00',
        tableId: 2,
        customerTitle: 'B',
        status: ReservationStatus.completed,
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '13:00',
        endTime: '15:00',
        tableId: 3,
        customerTitle: 'C',
        status: ReservationStatus.cancelled,
        createdAt: '',
        updatedAt: '',
      ));

      final booked = await reservationDao.getByStatus(ReservationStatus.booked);
      expect(booked.length, 1);
      expect(booked.first.customerTitle, 'A');

      final completed = await reservationDao.getByStatus(ReservationStatus.completed);
      expect(completed.length, 1);

      final cancelled = await reservationDao.getByStatus(ReservationStatus.cancelled);
      expect(cancelled.length, 1);

      // 按日期+状态
      final bookedToday = await reservationDao.getByStatus(ReservationStatus.booked, date: '2026-06-27');
      expect(bookedToday.length, 1);
      final bookedOtherDay = await reservationDao.getByStatus(ReservationStatus.booked, date: '2026-06-28');
      expect(bookedOtherDay.length, 0);
    });

    test('getConflictsForTable - 同桌同时段冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final conflicts = await reservationDao.getConflictsForTable(
        tableId: 1,
        date: '2026-06-27',
        startTime: '12:00',
        endTime: '14:00',
      );
      expect(conflicts.length, 1);
    });

    test('getConflictsForTable - 同桌不冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final conflicts = await reservationDao.getConflictsForTable(
        tableId: 1,
        date: '2026-06-27',
        startTime: '13:00',
        endTime: '15:00',
      );
      expect(conflicts, isEmpty);
    });

    test('getConflictsForTable - 不同桌不冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final conflicts = await reservationDao.getConflictsForTable(
        tableId: 2,
        date: '2026-06-27',
        startTime: '12:00',
        endTime: '14:00',
      );
      expect(conflicts, isEmpty);
    });

    test('getConflictsForTable - 不同日期不冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final conflicts = await reservationDao.getConflictsForTable(
        tableId: 1,
        date: '2026-06-28',
        startTime: '12:00',
        endTime: '14:00',
      );
      expect(conflicts, isEmpty);
    });

    test('getConflictsForTable - 已完成不冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        status: ReservationStatus.completed,
        createdAt: '',
        updatedAt: '',
      ));
      final conflicts = await reservationDao.getConflictsForTable(
        tableId: 1,
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
      );
      expect(conflicts, isEmpty); // 已完成不参与冲突
    });

    test('getConflictsForTable - 已取消不冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        status: ReservationStatus.cancelled,
        createdAt: '',
        updatedAt: '',
      ));
      final conflicts = await reservationDao.getConflictsForTable(
        tableId: 1,
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
      );
      expect(conflicts, isEmpty);
    });

    test('getConflictsForTable - excludeId 排除自身', () async {
      final id = await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final conflicts = await reservationDao.getConflictsForTable(
        tableId: 1,
        date: '2026-06-27',
        startTime: '12:00',
        endTime: '14:00',
        excludeId: id,
      );
      expect(conflicts, isEmpty); // 排除自身
    });

    test('getConflictsForArea - 同包厢同时段冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final conflicts = await reservationDao.getConflictsForArea(
        areaId: 4,
        date: '2026-06-27',
        startTime: '12:00',
        endTime: '14:00',
      );
      expect(conflicts.length, 1);
    });

    test('getConflictsForArea - 不同包厢不冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final conflicts = await reservationDao.getConflictsForArea(
        areaId: 5,
        date: '2026-06-27',
        startTime: '12:00',
        endTime: '14:00',
      );
      expect(conflicts, isEmpty);
    });

    test('update - 修改预订', () async {
      final id = await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '原名',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.update(Reservation(
        id: id,
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '改名',
        createdAt: '',
        updatedAt: '2026-06-27T11:00:00',
      ));
      final r = await reservationDao.getById(id);
      expect(r!.customerTitle, '改名');
    });

    test('changeStatus - 状态变更', () async {
      final id = await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.changeStatus(id, ReservationStatus.completed, '2026-06-27T13:30:00');
      final r = await reservationDao.getById(id);
      expect(r!.status, ReservationStatus.completed);
      expect(r.updatedAt, '2026-06-27T13:30:00');
    });

    test('delete - 删除预订', () async {
      final id = await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.delete(id);
      expect(await reservationDao.getById(id), isNull);
    });

    test('getAll - 按日期+时间排序', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-28',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final list = await reservationDao.getAll();
      expect(list[0].date, '2026-06-27');
      expect(list[1].date, '2026-06-28');
    });
  });
}
