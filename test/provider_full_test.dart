import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';
import 'package:xinyuan_hotel/data/database.dart';
import 'package:xinyuan_hotel/data/models/area.dart';
import 'package:xinyuan_hotel/data/models/dining_table.dart';
import 'package:xinyuan_hotel/data/models/floor.dart';
import 'package:xinyuan_hotel/data/models/quick_time_slot.dart';
import 'package:xinyuan_hotel/data/models/reservation.dart';
import 'package:xinyuan_hotel/providers/app_provider.dart';

/// AppProvider 全量集成测试
void main() {
  setUpAll(() {
    TestDatabaseEnvironment.ensureInitialized();
  });

  late AppProvider provider;

  setUp(() async {
    await DatabaseHelper().deleteDb();
    provider = AppProvider();
    await provider.init();
  });

  tearDown(() async {
    await DatabaseHelper().close();
  });

  group('AppProvider 初始化', () {
    test('init 加载预置数据', () async {
      expect(provider.floors.length, 2);
      expect(provider.areas.length, 5);
      expect(provider.tables.length, 12);
      expect(provider.timeSlots.length, 2);
      expect(provider.todayReservations, isEmpty);
    });

    test('缓存访问器返回非空列表', () {
      expect(provider.floors, isNotEmpty);
      expect(provider.areas, isNotEmpty);
      expect(provider.tables, isNotEmpty);
      expect(provider.timeSlots, isNotEmpty);
    });

    test('服务访问器返回实例', () {
      expect(provider.conflictService, isNotNull);
      expect(provider.availabilityService, isNotNull);
      expect(provider.statsService, isNotNull);
      expect(provider.backupService, isNotNull);
    });

    test('DAO 访问器返回实例', () {
      expect(provider.floorDao, isNotNull);
      expect(provider.areaDao, isNotNull);
      expect(provider.tableDao, isNotNull);
      expect(provider.timeSlotDao, isNotNull);
      expect(provider.reservationDao, isNotNull);
    });
  });

  group('AppProvider 预订操作', () {
    test('createReservation - 无冲突成功', () async {
      final r = Reservation(
        date: DateTime.now().toIso8601String().split('T')[0],
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      final (ok, msg) = await provider.createReservation(r);
      expect(ok, true);
      expect(msg, '预订成功');
      expect(provider.todayReservations.length, 1);
    });

    test('createReservation - 同桌同时段冲突失败', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final r1 = Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      final (ok1, _) = await provider.createReservation(r1);
      expect(ok1, true);

      final r2 = Reservation(
        date: today,
        startTime: '12:00',
        endTime: '14:00',
        tableId: 1,
        customerTitle: '李先生',
        createdAt: '',
        updatedAt: '',
      );
      final (ok2, msg2) = await provider.createReservation(r2);
      expect(ok2, false);
      expect(msg2, contains('已被预订'));
    });

    test('createReservation - 包厢预订成功', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final r = Reservation(
        date: today,
        startTime: '17:00',
        endTime: '19:00',
        areaId: 4,
        customerTitle: '李女士',
        guestCount: 10,
        createdAt: '',
        updatedAt: '',
      );
      final (ok, _) = await provider.createReservation(r);
      expect(ok, true);
      expect(provider.todayReservations.length, 1);
    });

    test('updateReservation - 编辑自身不冲突', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final r = Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      final (ok, _) = await provider.createReservation(r);
      expect(ok, true);

      final created = provider.todayReservations.first;
      final updated = created.copyWith(customerTitle: '改名');
      final (ok2, msg2) = await provider.updateReservation(updated);
      expect(ok2, true);
      expect(msg2, '已保存修改');
    });

    test('changeReservationStatus - 状态变更', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final r = Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      final (ok, _) = await provider.createReservation(r);
      expect(ok, true);

      final id = provider.todayReservations.first.id!;
      await provider.changeReservationStatus(id, ReservationStatus.completed);
      final updated = provider.todayReservations.first;
      expect(updated.status, ReservationStatus.completed);
    });

    test('deleteReservation - 删除预订', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final r = Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      await provider.createReservation(r);
      expect(provider.todayReservations.length, 1);

      final id = provider.todayReservations.first.id!;
      await provider.deleteReservation(id);
      expect(provider.todayReservations, isEmpty);
    });

    test('completed 状态释放资源 - 同桌可再预订', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final r1 = Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      await provider.createReservation(r1);

      // 标记完成
      final id = provider.todayReservations.first.id!;
      await provider.changeReservationStatus(id, ReservationStatus.completed);

      // 同桌同时段再预订 - 应成功（已完成不占资源）
      final r2 = Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '李先生',
        createdAt: '',
        updatedAt: '',
      );
      final (ok, _) = await provider.createReservation(r2);
      expect(ok, true);
    });

    test('getReservationLabel - 大厅桌预订', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final r = Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      await provider.createReservation(r);
      final label = provider.getReservationLabel(provider.todayReservations.first);
      expect(label, contains('一楼大厅'));
      expect(label, contains('A1'));
    });

    test('getReservationLabel - 包厢预订', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final r = Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4,
        customerTitle: '李女士',
        createdAt: '',
        updatedAt: '',
      );
      await provider.createReservation(r);
      final label = provider.getReservationLabel(provider.todayReservations.first);
      expect(label, 'VIP2号包厢');
    });

    test('getReservationLabel - 桌位不存在显示 -', () async {
      final r = Reservation(
        date: '2026-01-01',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 999,
        customerTitle: 'X',
        createdAt: '',
        updatedAt: '',
      );
      final label = provider.getReservationLabel(r);
      expect(label, '- · -');
    });

    test('todayReservations 只返回今日预订', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await provider.reservationDao.create(Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '今日',
        createdAt: '',
        updatedAt: '',
      ));
      await provider.reservationDao.create(Reservation(
        date: '2025-01-01',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '历史',
        createdAt: '',
        updatedAt: '',
      ));
      await provider.refreshReservations();
      expect(provider.todayReservations.length, 1);
      expect(provider.todayReservations.first.customerTitle, '今日');
    });

    test('今日统计计数 - bookedCountToday 等', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await provider.reservationDao.create(Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      await provider.reservationDao.create(Reservation(
        date: today,
        startTime: '12:00',
        endTime: '14:00',
        tableId: 2,
        customerTitle: 'B',
        status: ReservationStatus.completed,
        createdAt: '',
        updatedAt: '',
      ));
      await provider.reservationDao.create(Reservation(
        date: today,
        startTime: '13:00',
        endTime: '15:00',
        tableId: 3,
        customerTitle: 'C',
        status: ReservationStatus.cancelled,
        createdAt: '',
        updatedAt: '',
      ));
      await provider.refreshReservations();

      expect(provider.bookedCountToday, 1);
      expect(provider.completedCountToday, 1);
      expect(provider.cancelledCountToday, 1);
    });
  });

  group('AppProvider 楼层操作', () {
    test('createFloor - 新建楼层', () async {
      await provider.createFloor(Floor(name: '三楼', sortOrder: 3));
      expect(provider.floors.length, 3);
      expect(provider.floors.any((f) => f.name == '三楼'), true);
    });

    test('updateFloor - 修改楼层', () async {
      final first = provider.floors.first;
      await provider.updateFloor(first.copyWith(name: '改一楼'));
      expect(provider.floors.first.name, '改一楼');
    });

    test('deleteFloor - 空楼层可删', () async {
      final id = await provider.floorDao.create(Floor(name: '空楼'));
      await provider.refreshAll();
      final (ok, _) = await provider.deleteFloor(id);
      expect(ok, true);
      expect(provider.floors.any((f) => f.id == id), false);
    });

    test('deleteFloor - 有子区域不可删', () async {
      final (ok, msg) = await provider.deleteFloor(1); // 一楼有区域
      expect(ok, false);
      expect(msg, contains('有区域'));
    });
  });

  group('AppProvider 区域操作', () {
    test('createArea - 新建区域', () async {
      await provider.createArea(Area(floorId: 1, name: '新区域', type: AreaType.hall, sortOrder: 9));
      expect(provider.areas.length, 6);
    });

    test('updateArea - 修改区域', () async {
      final first = provider.areas.first;
      await provider.updateArea(first.copyWith(name: '改大厅'));
      expect(provider.areas.first.name, '改大厅');
    });

    test('deleteArea - 空区域可删', () async {
      final id = await provider.areaDao.create(Area(floorId: 1, name: '空区域', type: AreaType.hall));
      await provider.refreshAll();
      final (ok, _) = await provider.deleteArea(id);
      expect(ok, true);
    });

    test('deleteArea - 有桌位不可删', () async {
      final (ok, msg) = await provider.deleteArea(1); // 一楼大厅有桌位
      expect(ok, false);
      expect(msg, contains('有桌位'));
    });
  });

  group('AppProvider 桌位操作', () {
    test('createTable - 新建桌位', () async {
      await provider.createTable(DiningTable(areaId: 1, name: 'A3', seats: 6, sortOrder: 3));
      expect(provider.tables.length, 13);
    });

    test('updateTable - 修改桌位', () async {
      final first = provider.tables.first;
      await provider.updateTable(first.copyWith(name: '改A1', seats: 10));
      expect(provider.tables.first.name, '改A1');
      expect(provider.tables.first.seats, 10);
    });

    test('deleteTable - 删除桌位', () async {
      final id = provider.tables.first.id!;
      await provider.deleteTable(id);
      expect(provider.tables.any((t) => t.id == id), false);
    });
  });

  group('AppProvider 时段操作', () {
    test('createTimeSlot - 新建时段', () async {
      await provider.createTimeSlot(QuickTimeSlot(name: '下午茶', startTime: '14:00', endTime: '16:00', sortOrder: 3));
      expect(provider.timeSlots.length, 3);
    });

    test('updateTimeSlot - 修改时段', () async {
      final first = provider.timeSlots.first;
      await provider.updateTimeSlot(first.copyWith(name: '午市'));
      expect(provider.timeSlots.first.name, '午市');
    });

    test('deleteTimeSlot - 删除时段', () async {
      final id = provider.timeSlots.first.id!;
      await provider.deleteTimeSlot(id);
      expect(provider.timeSlots.length, 1);
    });
  });

  group('AppProvider 备份操作', () {
    test('importData - 导入后刷新缓存', () async {
      final json = await provider.exportData();
      // 由于 exportData 返回文件路径而非内容，这里直接测试 provider 缓存
      expect(provider.floors.length, 2);

      // 手动构造一个导入 JSON
      final importJson = '''
{
  "version": 1,
  "floors": [{"id": 1, "name": "导入楼", "sort_order": 1, "is_main": 0}],
  "areas": [{"id": 1, "floor_id": 1, "name": "导入区", "type": "hall", "sort_order": 1}],
  "tables": [{"id": 1, "area_id": 1, "name": "导入桌", "seats": 4, "sort_order": 1}],
  "timeSlots": [],
  "reservations": []
}
''';
      final result = await provider.importData(importJson);
      expect(result.floors, 1);

      // 缓存应已刷新
      expect(provider.floors.length, 1);
      expect(provider.floors.first.name, '导入楼');
      expect(provider.areas.length, 1);
      expect(provider.tables.length, 1);
      expect(provider.timeSlots, isEmpty);
    });
  });
}
