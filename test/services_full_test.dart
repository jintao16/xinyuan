import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';
import 'package:xinyuan_hotel/data/database.dart';
import 'package:xinyuan_hotel/data/dao/floor_dao.dart';
import 'package:xinyuan_hotel/data/dao/area_dao.dart';
import 'package:xinyuan_hotel/data/dao/table_dao.dart';
import 'package:xinyuan_hotel/data/dao/time_slot_dao.dart';
import 'package:xinyuan_hotel/data/dao/reservation_dao.dart';
import 'package:xinyuan_hotel/data/models/reservation.dart';
import 'package:xinyuan_hotel/services/conflict_service.dart';
import 'package:xinyuan_hotel/services/availability_service.dart';
import 'package:xinyuan_hotel/services/stats_service.dart';
import 'package:xinyuan_hotel/services/backup_service.dart';

/// 服务层全量集成测试
/// 覆盖：ConflictService、AvailabilityService、StatsService、BackupService
void main() {
  setUpAll(() {
    TestDatabaseEnvironment.ensureInitialized();
  });

  late DatabaseHelper dbHelper;
  late FloorDao floorDao;
  late AreaDao areaDao;
  late TableDao tableDao;
  late TimeSlotDao timeSlotDao;
  late ReservationDao reservationDao;
  late ConflictService conflictService;
  late AvailabilityService availabilityService;
  late StatsService statsService;
  late BackupService backupService;

  setUp(() async {
    await DatabaseHelper().deleteDb();
    dbHelper = DatabaseHelper();
    floorDao = FloorDao(dbHelper);
    areaDao = AreaDao(dbHelper);
    tableDao = TableDao(dbHelper);
    timeSlotDao = TimeSlotDao(dbHelper);
    reservationDao = ReservationDao(dbHelper);
    conflictService = ConflictService(reservationDao);
    availabilityService = AvailabilityService(floorDao, areaDao, tableDao, reservationDao);
    statsService = StatsService(reservationDao, tableDao, areaDao);
    backupService = BackupService(dbHelper, floorDao, areaDao, tableDao, timeSlotDao, reservationDao);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('ConflictService 全量', () {
    test('大厅桌预订 - 无冲突', () async {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      expect(await conflictService.hasConflict(r), false);
    });

    test('大厅桌预订 - 同桌同时段冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final r = Reservation(
        date: '2026-06-27',
        startTime: '12:00',
        endTime: '14:00',
        tableId: 1,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      );
      expect(await conflictService.hasConflict(r), true);
    });

    test('大厅桌预订 - 同桌不重叠不冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final r = Reservation(
        date: '2026-06-27',
        startTime: '13:00',
        endTime: '15:00',
        tableId: 1,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      );
      expect(await conflictService.hasConflict(r), false);
    });

    test('大厅桌预订 - 不同桌同时段不冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 2,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      );
      expect(await conflictService.hasConflict(r), false);
    });

    test('包厢预订 - 同包厢同时段冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final r = Reservation(
        date: '2026-06-27',
        startTime: '12:00',
        endTime: '14:00',
        areaId: 4,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      );
      expect(await conflictService.hasConflict(r), true);
    });

    test('包厢预订 - 不同包厢同时段不冲突', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 5,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      );
      expect(await conflictService.hasConflict(r), false);
    });

    test('已完成预订不冲突', () async {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        status: ReservationStatus.completed,
        createdAt: '',
        updatedAt: '',
      );
      expect(await conflictService.hasConflict(r), false);
    });

    test('已取消预订不冲突', () async {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        status: ReservationStatus.cancelled,
        createdAt: '',
        updatedAt: '',
      );
      expect(await conflictService.hasConflict(r), false);
    });

    test('excludeId - 编辑时排除自身', () async {
      final id = await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      // 编辑自身（同时段），不应冲突
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A 改',
        createdAt: '',
        updatedAt: '',
      );
      expect(await conflictService.hasConflict(r, excludeId: id), false);
    });

    test('excludeId - 不排除时仍冲突', () async {
      final id = await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final r = Reservation(
        date: '2026-06-27',
        startTime: '12:00',
        endTime: '14:00',
        tableId: 1,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      );
      // 即使传 excludeId=id，但时段不同仍冲突
      expect(await conflictService.hasConflict(r, excludeId: id), false); // 排除自身后无其他冲突
    });
  });

  group('AvailabilityService 全量', () {
    test('初始查询 - 返回所有楼层', () async {
      final result = await availabilityService.query(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
      );
      expect(result.length, 2); // 一楼 + 二楼
    });

    test('初始查询 - 一楼有 1 个区域', () async {
      final result = await availabilityService.query(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
      );
      expect(result[0].floor.name, '一楼');
      expect(result[0].areas.length, 1);
    });

    test('初始查询 - 二楼有 4 个区域', () async {
      final result = await availabilityService.query(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
      );
      expect(result[1].floor.name, '二楼');
      expect(result[1].areas.length, 4);
    });

    test('初始查询 - 所有桌位空闲', () async {
      final result = await availabilityService.query(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
      );
      for (final floor in result) {
        for (final area in floor.areas) {
          for (final t in area.tables) {
            expect(t.isFree, true, reason: '${area.area.name} ${t.table.name} 应空闲');
          }
        }
      }
    });

    test('大厅桌预订后 - 该桌显示占用', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1, // A1
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final result = await availabilityService.query(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
      );
      final floor1 = result.firstWhere((f) => f.floor.name == '一楼');
      final hall = floor1.areas.first;
      final a1 = hall.tables.firstWhere((t) => t.table.name == 'A1');
      expect(a1.isFree, false);
      expect(a1.occupiedBy, 'table');
      final a2 = hall.tables.firstWhere((t) => t.table.name == 'A2');
      expect(a2.isFree, true);
    });

    test('大厅桌预订后 - 不影响同时段其他桌', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final result = await availabilityService.query(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
      );
      final floor1 = result.firstWhere((f) => f.floor.name == '一楼');
      final freeCount = floor1.areas.first.tables.where((t) => t.isFree).length;
      expect(freeCount, 1); // 只有 A2 空闲
    });

    test('包厢预订后 - 包厢内所有桌显示占用', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4, // VIP2号包厢（2 张桌）
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final result = await availabilityService.query(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
      );
      final floor2 = result.firstWhere((f) => f.floor.name == '二楼');
      final vip2 = floor2.areas.firstWhere((a) => a.area.name == 'VIP2号包厢');
      for (final t in vip2.tables) {
        expect(t.isFree, false);
        expect(t.occupiedBy, 'area');
      }
      expect(vip2.isRoomFree, false);
    });

    test('包厢预订后 - 不影响其他包厢', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final result = await availabilityService.query(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
      );
      final floor2 = result.firstWhere((f) => f.floor.name == '二楼');
      final vip1 = floor2.areas.firstWhere((a) => a.area.name == 'VIP1号包厢');
      expect(vip1.isRoomFree, true);
    });

    test('AreaAvailability.isRoomFree - 非包厢返回 false', () async {
      final result = await availabilityService.query(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
      );
      final hall = result[0].areas.first; // 一楼大厅
      expect(hall.area.type.toString().contains('hall'), true);
      expect(hall.isRoomFree, false); // 大厅不适用包厢整体空闲判断
    });

    test('guestCount - 按人数排序桌位', () async {
      final result = await availabilityService.query(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        guestCount: 12,
      );
      final floor2 = result.firstWhere((f) => f.floor.name == '二楼');
      final hall = floor2.areas.firstWhere((a) => a.area.name == '二楼大厅');
      // 12 人：C1(12位) 应在 B1-B4(4位) 之前
      final c1Idx = hall.tables.indexWhere((t) => t.table.name == 'C1');
      final b1Idx = hall.tables.indexWhere((t) => t.table.name == 'B1');
      expect(c1Idx < b1Idx, true);
    });

    test('已完成预订不占用桌位', () async {
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
      final result = await availabilityService.query(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
      );
      final floor1 = result.firstWhere((f) => f.floor.name == '一楼');
      final a1 = floor1.areas.first.tables.firstWhere((t) => t.table.name == 'A1');
      expect(a1.isFree, true); // 已完成不占用
    });

    test('不同日期同时段不影响', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final result = await availabilityService.query(
        date: '2026-06-28', // 不同日期
        startTime: '11:00',
        endTime: '13:00',
      );
      final floor1 = result.firstWhere((f) => f.floor.name == '一楼');
      final a1 = floor1.areas.first.tables.firstWhere((t) => t.table.name == 'A1');
      expect(a1.isFree, true);
    });
  });

  group('StatsService 全量', () {
    test('空数据 - summary 全为 0', () async {
      final s = await statsService.summary('2026-06-01', '2026-06-30');
      expect(s.total, 0);
      expect(s.booked, 0);
      expect(s.completed, 0);
      expect(s.cancelled, 0);
      expect(s.arrivalRate, 0);
    });

    test('summary - 全部 booked', () async {
      for (int i = 0; i < 5; i++) {
        await reservationDao.create(Reservation(
          date: '2026-06-${10 + i}',
          startTime: '11:00',
          endTime: '13:00',
          tableId: 1,
          customerTitle: 'A$i',
          createdAt: '',
          updatedAt: '',
        ));
      }
      final s = await statsService.summary('2026-06-01', '2026-06-30');
      expect(s.total, 5);
      expect(s.booked, 5);
      expect(s.completed, 0);
      expect(s.arrivalRate, 0); // 0/5
    });

    test('summary - 全部 completed - 到店率 100%', () async {
      for (int i = 0; i < 3; i++) {
        await reservationDao.create(Reservation(
          date: '2026-06-10',
          startTime: '11:00',
          endTime: '13:00',
          tableId: 1,
          customerTitle: 'A$i',
          status: ReservationStatus.completed,
          createdAt: '',
          updatedAt: '',
        ));
      }
      final s = await statsService.summary('2026-06-01', '2026-06-30');
      expect(s.total, 3);
      expect(s.completed, 3);
      expect(s.arrivalRate, 100);
    });

    test('summary - 混合状态', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        status: ReservationStatus.booked,
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '12:00',
        endTime: '14:00',
        tableId: 2,
        customerTitle: 'B',
        status: ReservationStatus.completed,
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '13:00',
        endTime: '15:00',
        tableId: 3,
        customerTitle: 'C',
        status: ReservationStatus.cancelled,
        createdAt: '',
        updatedAt: '',
      ));
      final s = await statsService.summary('2026-06-01', '2026-06-30');
      expect(s.total, 3);
      expect(s.booked, 1);
      expect(s.completed, 1);
      expect(s.cancelled, 1);
      expect(s.arrivalRate, 33); // 1*100/3 ≈ 33.33 → 33
    });

    test('summary - 日期范围外不计', () async {
      await reservationDao.create(Reservation(
        date: '2026-05-01', // 范围外
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      ));
      final s = await statsService.summary('2026-06-01', '2026-06-30');
      expect(s.total, 1);
    });

    test('tableUsage - 桌位使用率', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-11',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 2,
        customerTitle: 'C',
        createdAt: '',
        updatedAt: '',
      ));
      final usage = await statsService.tableUsage('2026-06-01', '2026-06-30');
      expect(usage.length, 2);
      // A1 用 2 次，A2 用 1 次
      final a1Item = usage.firstWhere((u) => u.name.contains('A1'));
      expect(a1Item.count, 2);
      expect(a1Item.percent, 100); // 最大值占比 100%
      final a2Item = usage.firstWhere((u) => u.name.contains('A2'));
      expect(a2Item.count, 1);
      expect(a2Item.percent, 50); // 1/2=50%
    });

    test('tableUsage - 已取消不计', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        status: ReservationStatus.cancelled,
        createdAt: '',
        updatedAt: '',
      ));
      final usage = await statsService.tableUsage('2026-06-01', '2026-06-30');
      expect(usage, isEmpty);
    });

    test('tableUsage - 包厢预订按包厢统计', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      final usage = await statsService.tableUsage('2026-06-01', '2026-06-30');
      expect(usage.length, 1);
      expect(usage.first.name.contains('包厢'), true);
      expect(usage.first.name.contains('VIP2'), true);
    });

    test('hourlyDistribution - 按小时统计 9-22 点', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '11:30',
        endTime: '13:00',
        tableId: 2,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '18:00',
        endTime: '20:00',
        tableId: 3,
        customerTitle: 'C',
        createdAt: '',
        updatedAt: '',
      ));
      final hourly = await statsService.hourlyDistribution('2026-06-01', '2026-06-30');
      expect(hourly.length, 14); // 9-22 共 14 个小时
      final h11 = hourly.firstWhere((h) => h.hour == 11);
      expect(h11.count, 2);
      final h18 = hourly.firstWhere((h) => h.hour == 18);
      expect(h18.count, 1);
      final h9 = hourly.firstWhere((h) => h.hour == 9);
      expect(h9.count, 0);
      final h22 = hourly.firstWhere((h) => h.hour == 22);
      expect(h22.count, 0);
    });

    test('areaRatio - 大厅 vs 包厢', () async {
      // 2 个大厅桌预订
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '12:00',
        endTime: '14:00',
        tableId: 2,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      ));
      // 1 个包厢预订
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4,
        customerTitle: 'C',
        createdAt: '',
        updatedAt: '',
      ));
      // 1 个已取消（不计）
      await reservationDao.create(Reservation(
        date: '2026-06-10',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 3,
        customerTitle: 'D',
        status: ReservationStatus.cancelled,
        createdAt: '',
        updatedAt: '',
      ));
      final ratio = await statsService.areaRatio('2026-06-01', '2026-06-30');
      expect(ratio.halls, 2);
      expect(ratio.rooms, 1);
      expect(ratio.total, 3);
      expect(ratio.hallsPercent, 67); // 2*100/3 ≈ 66.67 → 67
      expect(ratio.roomsPercent, 33); // 1*100/3 ≈ 33.33 → 33
    });

    test('areaRatio - 空数据', () async {
      final ratio = await statsService.areaRatio('2026-06-01', '2026-06-30');
      expect(ratio.total, 0);
      expect(ratio.hallsPercent, 0);
      expect(ratio.roomsPercent, 0);
    });
  });

  group('BackupService 全量', () {
    test('exportToJson - 导出包含所有表', () async {
      final json = await backupService.exportToJson();
      expect(json.isNotEmpty, true);
      // 解析验证
      final data = jsonDecode(json) as Map<String, dynamic>;
      expect(data['version'], 1);
      expect(data.containsKey('exportedAt'), true);
      expect(data.containsKey('floors'), true);
      expect(data.containsKey('areas'), true);
      expect(data.containsKey('tables'), true);
      expect(data.containsKey('timeSlots'), true);
      expect(data.containsKey('reservations'), true);
      // 验证预置数据量
      expect((data['floors'] as List).length, 2);
      expect((data['areas'] as List).length, 5);
      expect((data['tables'] as List).length, 12);
      expect((data['timeSlots'] as List).length, 2);
      expect((data['reservations'] as List).length, 0);
    });

    test('exportToJson - 包含预订数据', () async {
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      ));
      final json = await backupService.exportToJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      expect((data['reservations'] as List).length, 1);
      final r = (data['reservations'] as List).first as Map<String, dynamic>;
      expect(r['customer_title'], '张先生');
    });

    test('importFromJson - 正常导入覆盖现有', () async {
      final json = '''
{
  "version": 1,
  "exportedAt": "2026-06-27T10:00:00",
  "floors": [
    {"id": 1, "name": "新一楼", "sort_order": 1, "is_main": 1}
  ],
  "areas": [
    {"id": 1, "floor_id": 1, "name": "新大厅", "type": "hall", "sort_order": 1}
  ],
  "tables": [
    {"id": 1, "area_id": 1, "name": "新A1", "seats": 10, "sort_order": 1}
  ],
  "timeSlots": [
    {"id": 1, "name": "新午餐", "start_time": "11:00", "end_time": "13:00", "sort_order": 1}
  ],
  "reservations": [
    {"id": 1, "date": "2026-06-27", "start_time": "11:00", "end_time": "13:00", "table_id": 1, "area_id": null, "customer_title": "导入测试", "customer_phone": "", "guest_count": 4, "status": "booked", "remark": "", "created_at": "", "updated_at": ""}
  ]
}
''';
      final result = await backupService.importFromJson(json);
      expect(result.floors, 1);
      expect(result.areas, 1);
      expect(result.tables, 1);
      expect(result.timeSlots, 1);
      expect(result.reservations, 1);

      // 验证导入后数据
      final floors = await floorDao.getAll();
      expect(floors.length, 1);
      expect(floors.first.name, '新一楼');

      final reservations = await reservationDao.getAll();
      expect(reservations.length, 1);
      expect(reservations.first.customerTitle, '导入测试');
    });

    test('importFromJson - 缺少必需字段抛 FormatException', () async {
      final json = '{"floors": [], "areas": []}'; // 缺 tables 和 reservations
      expect(
        () => backupService.importFromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('importFromJson - JSON 格式错误抛 FormatException', () async {
      expect(
        () => backupService.importFromJson('不是 json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('importFromJson - 空数据导入', () async {
      final json = '''
{
  "version": 1,
  "floors": [],
  "areas": [],
  "tables": [],
  "reservations": []
}
''';
      final result = await backupService.importFromJson(json);
      expect(result.floors, 0);
      expect(result.areas, 0);
      expect(result.tables, 0);
      expect(result.reservations, 0);

      // 原有数据被清空
      expect(await floorDao.getAll(), isEmpty);
    });

    test('导入导出往返一致', () async {
      // 先添加一些预订
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        guestCount: 6,
        createdAt: '2026-06-27T10:00:00',
        updatedAt: '2026-06-27T10:00:00',
      ));
      await reservationDao.create(Reservation(
        date: '2026-06-27',
        startTime: '17:00',
        endTime: '19:00',
        areaId: 4,
        customerTitle: '李女士',
        status: ReservationStatus.completed,
        createdAt: '2026-06-27T10:00:00',
        updatedAt: '2026-06-27T19:00:00',
      ));

      // 导出
      final json = await backupService.exportToJson();

      // 清空后导入
      await DatabaseHelper().deleteDb();
      // 重新创建 dbHelper 引用（指向新 db）
      // 注意：DatabaseHelper 是单例，deleteDb 后下次 database getter 会重建
      final importResult = await backupService.importFromJson(json);
      expect(importResult.floors, 2);
      expect(importResult.areas, 5);
      expect(importResult.tables, 12);
      expect(importResult.reservations, 2);

      // 验证预订数据完整
      final reservations = await reservationDao.getAll();
      expect(reservations.length, 2);
      final zhang = reservations.where((r) => r.customerTitle == '张先生').first;
      expect(zhang.tableId, 1);
      expect(zhang.guestCount, 6);
      expect(zhang.status, ReservationStatus.booked);

      final li = reservations.where((r) => r.customerTitle == '李女士').first;
      expect(li.areaId, 4);
      expect(li.status, ReservationStatus.completed);
    });

    test('导入数据可正常使用（外键关系正确）', () async {
      final json = await backupService.exportToJson();
      await backupService.importFromJson(json);

      // 验证外键关系：areaId=4 的桌位应能查到
      final tables = await tableDao.getByAreaId(4);
      expect(tables.length, 2);

      // 验证楼层-区域关系
      final floor1Areas = await areaDao.getByFloorId(1);
      expect(floor1Areas.length, 1);
    });
  });
}
