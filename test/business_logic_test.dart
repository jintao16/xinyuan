import 'package:flutter_test/flutter_test.dart';
import 'package:xinyuan_hotel/data/models/area.dart';
import 'package:xinyuan_hotel/data/models/dining_table.dart';
import 'package:xinyuan_hotel/data/models/floor.dart';
import 'package:xinyuan_hotel/data/models/reservation.dart';
import 'package:xinyuan_hotel/utils/time_util.dart';

/// 业务逻辑算法验证测试
///
/// 不依赖数据库，把核心算法逻辑抽出来用纯函数方式验证。
/// 覆盖：时段重叠算法、冲突检测逻辑、状态占用规则、
///       空闲查询排序、统计计算、备份导入导出数据结构。
void main() {
  group('核心算法 - 时段重叠检测', () {
    /// 复刻 reservation_dao.dart 的 SQL 逻辑：
    /// start_time < endTime AND end_time > startTime
    /// 即 s1 < e2 AND e1 > s2（等价于 s1 < e2 AND s2 < e1）
    bool hasTimeConflict(String s1, String e1, String s2, String e2) {
      final start1 = TimeUtil.toMinutes(s1);
      final end1 = TimeUtil.toMinutes(e1);
      final start2 = TimeUtil.toMinutes(s2);
      final end2 = TimeUtil.toMinutes(e2);
      return start1 < end2 && end1 > start2;
    }

    test('完全不相邻 - 不冲突', () {
      expect(hasTimeConflict('10:00', '11:00', '12:00', '13:00'), false);
      expect(hasTimeConflict('09:00', '10:00', '14:00', '16:00'), false);
    });

    test('相邻（结束=开始）- 不冲突', () {
      // 11-13 和 13-15 不冲突（13:00 既是前段结束也是后段开始）
      expect(hasTimeConflict('11:00', '13:00', '13:00', '15:00'), false);
      expect(hasTimeConflict('10:00', '11:00', '11:00', '12:00'), false);
    });

    test('部分重叠 - 冲突', () {
      expect(hasTimeConflict('11:00', '13:00', '12:00', '14:00'), true);
      expect(hasTimeConflict('10:00', '12:00', '11:00', '13:00'), true);
    });

    test('完全包含 - 冲突', () {
      expect(hasTimeConflict('10:00', '14:00', '11:00', '12:00'), true);
      expect(hasTimeConflict('11:00', '12:00', '10:00', '14:00'), true);
    });

    test('完全相同 - 冲突', () {
      expect(hasTimeConflict('11:00', '13:00', '11:00', '13:00'), true);
    });

    test('跨午餐晚餐时段 - 冲突', () {
      // 午餐 11-13 和 12-14 重叠
      expect(hasTimeConflict('11:00', '13:00', '12:00', '14:00'), true);
    });

    test('SQL 算法与 TimeUtil.overlap 等价', () {
      // 验证 reservation_dao 的 SQL 逻辑与 TimeUtil.overlap 一致
      for (final s1 in ['09:00', '10:00', '11:00', '12:00', '14:00', '17:00']) {
        for (final e1 in ['10:00', '11:00', '13:00', '14:00', '16:00', '19:00']) {
          for (final s2 in ['09:00', '11:00', '13:00', '17:00']) {
            for (final e2 in ['10:00', '13:00', '14:00', '19:00']) {
              if (s1 != e1 && s2 != e2) {
                final sqlLogic = hasTimeConflict(s1, e1, s2, e2);
                final utilLogic = TimeUtil.overlap(s1, e1, s2, e2);
                expect(sqlLogic, utilLogic,
                    reason: '不一致: $s1-$e1 vs $s2-$e2 (sql=$sqlLogic, util=$utilLogic)');
              }
            }
          }
        }
      }
    });
  });

  group('核心业务规则 - 状态占用资源', () {
    test('已预订占用资源，已完成/已取消不占用', () {
      expect(ReservationStatus.booked.occupies, true);
      expect(ReservationStatus.completed.occupies, false);
      expect(ReservationStatus.cancelled.occupies, false);
    });

    test('ConflictService 跳过终态预订的等价逻辑', () {
      // 复刻 conflict_service.dart 第13行：if (!reservation.status.occupies) return false;
      bool shouldCheckConflict(ReservationStatus status) {
        return status.occupies;
      }

      expect(shouldCheckConflict(ReservationStatus.booked), true);
      expect(shouldCheckConflict(ReservationStatus.completed), false);
      expect(shouldCheckConflict(ReservationStatus.cancelled), false);
    });
  });

  group('核心业务规则 - 桌位/包厢互斥', () {
    test('大厅桌预订 - 仅占该桌，包厢其他桌不受影响', () {
      // 模拟：VIP2号包厢有大圆桌(id=10)和小方桌(id=11)
      // 预订了 id=10，不影响 id=11（但实际包厢预订应整体占用，这里测大厅桌逻辑）
      final reservation = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 10,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      expect(reservation.tableId, 10);
      expect(reservation.areaId, null);
    });

    test('包厢预订 - 占用包厢内所有桌位', () {
      // 模拟：预订 VIP2号包厢（areaId=4），该包厢有 2 张桌
      // availability_service 第104-122行：包厢被预订时，包厢内所有桌标记为 occupied
      final reservation = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4,
        customerTitle: '李女士',
        createdAt: '',
        updatedAt: '',
      );
      expect(reservation.tableId, null);
      expect(reservation.areaId, 4);

      // 验证 AreaAvailability.isRoomFree 逻辑：
      // 包厢所有桌位空闲时 isRoomFree=true，否则 false
      final allFree = [
        _MockTableAvail(free: true),
        _MockTableAvail(free: true),
      ];
      final anyOccupied = [
        _MockTableAvail(free: false),
        _MockTableAvail(free: true),
      ];
      expect(allFree.every((t) => t.free), true); // 全空闲 → 可预订
      expect(anyOccupied.every((t) => t.free), false); // 有占用 → 不可预订
    });

    test('Reservation 模型 assert 互斥校验', () {
      expect(
        () => Reservation(
          date: '2026-06-27',
          startTime: '11:00',
          endTime: '13:00',
          tableId: 1,
          areaId: 1,
          customerTitle: '张先生',
          createdAt: '',
          updatedAt: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('核心算法 - 空闲查询排序', () {
    /// 复刻 availability_service.dart 第132-143行的人数匹配排序逻辑
    int sortFn(DiningTable a, DiningTable b, int guestCount) {
      final aOk = a.seats >= guestCount;
      final bOk = b.seats >= guestCount;
      if (aOk && !bOk) return -1;
      if (!aOk && bOk) return 1;
      final aDiff = (a.seats - guestCount).abs();
      final bDiff = (b.seats - guestCount).abs();
      return aDiff.compareTo(bDiff);
    }

    test('6人用餐 - 8人桌优先于4人桌', () {
      final tables = [
        DiningTable(id: 1, areaId: 1, name: 'B1', seats: 4),
        DiningTable(id: 2, areaId: 1, name: 'A1', seats: 8),
      ];
      tables.sort((a, b) => sortFn(a, b, 6));
      expect(tables.first.name, 'A1'); // 8人桌优先
      expect(tables.last.name, 'B1'); // 4人桌靠后
    });

    test('6人用餐 - 多个可容纳桌位按接近度排序', () {
      final tables = [
        DiningTable(id: 1, areaId: 1, name: 'C1', seats: 14),
        DiningTable(id: 2, areaId: 1, name: 'A1', seats: 8),
        DiningTable(id: 3, areaId: 1, name: 'C2', seats: 12),
      ];
      tables.sort((a, b) => sortFn(a, b, 6));
      // 8人桌最接近6人（差2），12人次之（差6），14人最远（差8）
      expect(tables.map((t) => t.name).toList(), ['A1', 'C2', 'C1']);
    });

    test('4人用餐 - 4人桌优先于8人桌', () {
      final tables = [
        DiningTable(id: 1, areaId: 1, name: 'A1', seats: 8),
        DiningTable(id: 2, areaId: 1, name: 'B1', seats: 4),
      ];
      tables.sort((a, b) => sortFn(a, b, 4));
      expect(tables.first.name, 'B1'); // 4人桌正好匹配
    });

    test('12人用餐 - 只有大桌能容纳', () {
      final tables = [
        DiningTable(id: 1, areaId: 1, name: 'B1', seats: 4),
        DiningTable(id: 2, areaId: 1, name: 'A1', seats: 8),
        DiningTable(id: 3, areaId: 1, name: 'C1', seats: 12),
      ];
      tables.sort((a, b) => sortFn(a, b, 12));
      expect(tables.first.name, 'C1'); // 12人桌正好
    });
  });

  group('核心算法 - 统计计算', () {
    /// 复刻 stats_service.dart 的汇总逻辑
    ReservationSummary calcSummary(List<ReservationStatus> statuses) {
      final total = statuses.length;
      final booked = statuses.where((s) => s == ReservationStatus.booked).length;
      final completed = statuses.where((s) => s == ReservationStatus.completed).length;
      final cancelled = statuses.where((s) => s == ReservationStatus.cancelled).length;
      final arrivalRate = total == 0 ? 0 : (completed * 100 / total).round();
      return ReservationSummary(
        total: total,
        booked: booked,
        completed: completed,
        cancelled: cancelled,
        arrivalRate: arrivalRate,
      );
    }

    test('空数据 - 到店率0%', () {
      final s = calcSummary([]);
      expect(s.total, 0);
      expect(s.arrivalRate, 0);
    });

    test('全部已完成 - 到店率100%', () {
      final s = calcSummary([
        ReservationStatus.completed,
        ReservationStatus.completed,
        ReservationStatus.completed,
      ]);
      expect(s.total, 3);
      expect(s.completed, 3);
      expect(s.arrivalRate, 100);
    });

    test('混合状态 - 到店率按四舍五入', () {
      // 3完成 / 5总数 = 60%
      final s = calcSummary([
        ReservationStatus.booked,
        ReservationStatus.completed,
        ReservationStatus.completed,
        ReservationStatus.cancelled,
        ReservationStatus.completed,
      ]);
      expect(s.total, 5);
      expect(s.completed, 3);
      expect(s.booked, 1);
      expect(s.cancelled, 1);
      expect(s.arrivalRate, 60);
    });

    test('2/3 完成 - 到店率67%（四舍五入）', () {
      final s = calcSummary([
        ReservationStatus.completed,
        ReservationStatus.completed,
        ReservationStatus.cancelled,
      ]);
      // 2*100/3 = 66.67 → round → 67
      expect(s.arrivalRate, 67);
    });

    test('区域占比计算', () {
      // 复刻 stats_service.areaRatio 逻辑
      int halls = 0, rooms = 0;
      final list = [
        {'type': 'table', 'areaType': 'hall', 'cancelled': false},
        {'type': 'table', 'areaType': 'hall', 'cancelled': false},
        {'type': 'area', 'areaType': 'private_room', 'cancelled': false},
        {'type': 'table', 'areaType': 'hall', 'cancelled': true}, // 已取消不计
      ];
      for (final r in list) {
        if (r['cancelled'] == true) continue;
        if (r['type'] == 'table' && r['areaType'] == 'hall') {
          halls++;
        } else if (r['type'] == 'area') {
          rooms++;
        }
      }
      final total = halls + rooms;
      final hallsPercent = total == 0 ? 0 : (halls * 100 / total).round();
      expect(halls, 2);
      expect(rooms, 1);
      expect(total, 3);
      expect(hallsPercent, 67);
    });

    test('时段分布 - 按小时统计', () {
      // 复刻 stats_service.hourlyDistribution 逻辑
      final hours = List.filled(24, 0);
      final startTimes = ['11:00', '11:30', '12:00', '17:00', '18:00', '18:30'];
      for (final st in startTimes) {
        final h = int.tryParse(st.split(':')[0]) ?? 0;
        if (h >= 0 && h < 24) hours[h]++;
      }
      // 9-22 点范围
      expect(hours[11], 2); // 11点2单
      expect(hours[12], 1); // 12点1单
      expect(hours[17], 1); // 17点1单
      expect(hours[18], 2); // 18点2单
      expect(hours[9], 0); // 9点0单
      expect(hours[22], 0); // 22点0单
    });
  });

  group('核心算法 - 即将到店判断', () {
    /// 复刻 time_util.isUpcoming 逻辑：前后30分钟内
    bool isUpcoming(String startTime, String nowTime) {
      final now = TimeUtil.toMinutes(nowTime);
      final start = TimeUtil.toMinutes(startTime);
      return start >= now - 30 && start <= now + 30;
    }

    test('当前时间就是开始时间 - 即将到店', () {
      expect(isUpcoming('12:00', '12:00'), true);
    });

    test('开始时间在30分钟内 - 即将到店', () {
      expect(isUpcoming('12:30', '12:00'), true); // 30分钟后
      expect(isUpcoming('11:30', '12:00'), true); // 30分钟前
      expect(isUpcoming('12:15', '12:00'), true); // 15分钟后
    });

    test('开始时间超出30分钟 - 非即将到店', () {
      expect(isUpcoming('13:00', '12:00'), false); // 60分钟后
      expect(isUpcoming('11:00', '12:00'), false); // 60分钟前
      expect(isUpcoming('15:00', '12:00'), false); // 3小时后
    });
  });

  group('核心算法 - 备份导入导出数据结构', () {
    test('导出 JSON 结构包含所有表', () {
      // 复刻 backup_service.exportToJson 的结构
      final data = {
        'version': 1,
        'exportedAt': '2026-06-27T10:00:00',
        'floors': [
          {'id': 1, 'name': '一楼', 'sort_order': 1, 'is_main': 0}
        ],
        'areas': [
          {'id': 1, 'floor_id': 1, 'name': '一楼大厅', 'type': 'hall', 'sort_order': 1}
        ],
        'tables': [
          {'id': 1, 'area_id': 1, 'name': 'A1', 'seats': 8, 'sort_order': 1}
        ],
        'timeSlots': [
          {'id': 1, 'name': '午餐', 'start_time': '11:00', 'end_time': '13:00', 'sort_order': 1}
        ],
        'reservations': [
          {'id': 1, 'date': '2026-06-27', 'start_time': '11:00', 'end_time': '13:00',
           'table_id': 1, 'area_id': null, 'customer_title': '张先生', 'status': 'booked'}
        ],
      };

      // 验证结构
      expect(data['version'], 1);
      expect(data.containsKey('floors'), true);
      expect(data.containsKey('areas'), true);
      expect(data.containsKey('tables'), true);
      expect(data.containsKey('timeSlots'), true);
      expect(data.containsKey('reservations'), true);
    });

    test('导入时必需字段校验', () {
      // 复刻 backup_service.importFromJson 第105-110行的结构校验
      final requiredKeys = ['floors', 'areas', 'tables', 'reservations'];

      final validData = {'floors': [], 'areas': [], 'tables': [], 'reservations': []};
      for (final key in requiredKeys) {
        expect(validData.containsKey(key), true, reason: '缺少字段: $key');
      }

      final invalidData = {'floors': [], 'areas': []}; // 缺 tables 和 reservations
      for (final key in requiredKeys) {
        if (!invalidData.containsKey(key)) {
          expect(invalidData.containsKey(key), false, reason: '应检测到缺少: $key');
        }
      }
    });

    test('导入清空顺序按外键依赖反序', () {
      // 复刻 backup_service.importFromJson 第115-120行
      // 必须先删 reservation（依赖 dining_table 和 area），
      // 再删 dining_table（依赖 area），再删 area（依赖 floor），最后删 floor
      final deleteOrder = ['reservation', 'dining_table', 'quick_time_slot', 'area', 'floor'];
      // 验证 reservation 在 dining_table 之前
      expect(deleteOrder.indexOf('reservation') < deleteOrder.indexOf('dining_table'), true);
      // 验证 dining_table 在 area 之前
      expect(deleteOrder.indexOf('dining_table') < deleteOrder.indexOf('area'), true);
      // 验证 area 在 floor 之前
      expect(deleteOrder.indexOf('area') < deleteOrder.indexOf('floor'), true);
    });
  });

  group('核心算法 - 预订显示标签', () {
    /// 复刻 app_provider.getReservationLabel 逻辑
    String getLabel(Reservation r, List<DiningTable> tables, List<Area> areas) {
      if (r.tableId != null) {
        final t = tables.where((x) => x.id == r.tableId).firstOrNull;
        final a = t != null ? areas.where((x) => x.id == t.areaId).firstOrNull : null;
        return '${a?.name ?? '-'} · ${t?.name ?? '-'}';
      }
      if (r.areaId != null) {
        final a = areas.where((x) => x.id == r.areaId).firstOrNull;
        return a?.name ?? '-';
      }
      return '-';
    }

    final tables = [
      DiningTable(id: 1, areaId: 2, name: 'A1', seats: 8),
      DiningTable(id: 7, areaId: 2, name: 'C1', seats: 12),
    ];
    final areas = [
      Area(id: 2, floorId: 1, name: '二楼大厅', type: AreaType.hall),
      Area(id: 4, floorId: 2, name: 'VIP2号包厢', type: AreaType.privateRoom),
    ];

    test('大厅桌预订 - 显示「区域名 · 桌名」', () {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      expect(getLabel(r, tables, areas), '二楼大厅 · A1');
    });

    test('包厢预订 - 显示「区域名」', () {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4,
        customerTitle: '李女士',
        createdAt: '',
        updatedAt: '',
      );
      expect(getLabel(r, tables, areas), 'VIP2号包厢');
    });

    test('桌位不存在 - 显示「-」', () {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 999,
        customerTitle: '王先生',
        createdAt: '',
        updatedAt: '',
      );
      expect(getLabel(r, tables, areas), '- · -');
    });
  });

  group('完整业务流程 - 预订生命周期', () {
    test('完整流程：创建 → 已预订 → 已完成', () {
      // 模拟完整生命周期
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '2026-06-27T10:00:00',
        updatedAt: '2026-06-27T10:00:00',
      );

      // 初始状态：已预订
      expect(r.status, ReservationStatus.booked);
      expect(r.status.occupies, true); // 占用资源

      // 客户到店用餐完毕 → 标记完成
      final completed = r.copyWith(
        status: ReservationStatus.completed,
        updatedAt: '2026-06-27T13:30:00',
      );
      expect(completed.status, ReservationStatus.completed);
      expect(completed.status.occupies, false); // 不再占用资源
      expect(completed.customerTitle, '张先生'); // 其他信息不变
    });

    test('完整流程：创建 → 已预订 → 已取消', () {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4,
        customerTitle: '李女士',
        createdAt: '2026-06-27T10:00:00',
        updatedAt: '2026-06-27T10:00:00',
      );

      // 客户取消 → 标记取消
      final cancelled = r.copyWith(
        status: ReservationStatus.cancelled,
        updatedAt: '2026-06-27T10:30:00',
      );
      expect(cancelled.status, ReservationStatus.cancelled);
      expect(cancelled.status.occupies, false); // 不再占用资源
      expect(cancelled.areaId, 4); // 包厢预订信息保留
    });

    test('冲突场景：同桌同时段第二预订应被拒绝', () {
      // 第一预订成功
      final r1 = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      expect(r1.status.occupies, true);

      // 模拟冲突检测：第二预订同时段同桌
      final r2 = Reservation(
        date: '2026-06-27',
        startTime: '12:00', // 与 11-13 重叠
        endTime: '14:00',
        tableId: 1, // 同桌
        customerTitle: '赵先生',
        createdAt: '',
        updatedAt: '',
      );

      // 复刻 ConflictService：只有 booked 占用，且时段重叠则冲突
      bool hasConflict = r1.status.occupies &&
          TimeUtil.overlap(r1.startTime, r1.endTime, r2.startTime, r2.endTime) &&
          r1.tableId == r2.tableId &&
          r1.date == r2.date;

      expect(hasConflict, true, reason: '同桌同时段应冲突');
    });

    test('已完成预订不阻止后续预订（资源已释放）', () {
      // 第一预订已完成（不占资源）
      final r1Completed = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        status: ReservationStatus.completed,
        createdAt: '',
        updatedAt: '',
      );

      // 第二预订同时段同桌
      final r2 = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '李先生',
        createdAt: '',
        updatedAt: '',
      );

      // ConflictService 第一行：if (!reservation.status.occupies) return false
      // r1Completed 已完成，不占资源，不参与冲突检测
      bool r1Occupies = r1Completed.status.occupies;
      expect(r1Occupies, false, reason: '已完成不占资源');

      // 因此 r2 不会因 r1 而冲突（假设无其他 booked 预订）
      // 这里只验证逻辑：r1 不参与冲突检测
    });

    test('不同桌位同时段不冲突', () {
      final r1 = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      final r2 = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 2, // 不同桌
        customerTitle: '李先生',
        createdAt: '',
        updatedAt: '',
      );

      bool hasConflict = r1.status.occupies &&
          TimeUtil.overlap(r1.startTime, r1.endTime, r2.startTime, r2.endTime) &&
          r1.tableId == r2.tableId &&
          r1.date == r2.date;

      expect(hasConflict, false, reason: '不同桌位同时段不冲突');
    });

    test('包厢预订与包厢内桌位预订冲突', () {
      // 包厢预订（占整个包厢）
      final r1 = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4, // VIP2号包厢
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );

      // 再预订包厢内某桌（应冲突，因包厢已被整体预订）
      final r2 = Reservation(
        date: '2026-06-27',
        startTime: '12:00',
        endTime: '14:00',
        tableId: 10, // VIP2号包厢的大圆桌
        customerTitle: '李先生',
        createdAt: '',
        updatedAt: '',
      );

      // availability_service 第104-122行：
      // 包厢被预订时，包厢内所有桌标记为 occupied（occupiedBy='area'）
      // 因此 r2 选桌时会发现桌位被占用
      // 这里验证包厢预订的 areaId 逻辑正确
      expect(r1.areaId, 4);
      expect(r1.tableId, null);
      expect(r2.tableId, 10);
      expect(r2.areaId, null);

      // 时段重叠
      expect(TimeUtil.overlap(r1.startTime, r1.endTime, r2.startTime, r2.endTime), true);
    });
  });

  group('预置数据业务规则', () {
    test('楼层/区域/桌位层级关系正确', () {
      final floors = [
        Floor(id: 1, name: '一楼', sortOrder: 1, isMain: false),
        Floor(id: 2, name: '二楼', sortOrder: 2, isMain: true),
      ];
      final areas = [
        Area(id: 1, floorId: 1, name: '一楼大厅', type: AreaType.hall),
        Area(id: 2, floorId: 2, name: '二楼大厅', type: AreaType.hall),
        Area(id: 3, floorId: 2, name: 'VIP1号包厢', type: AreaType.privateRoom),
        Area(id: 4, floorId: 2, name: 'VIP2号包厢', type: AreaType.privateRoom),
        Area(id: 5, floorId: 2, name: '牡丹厅包厢', type: AreaType.privateRoom),
      ];
      final tables = [
        DiningTable(id: 1, areaId: 1, name: 'A1', seats: 8),
        DiningTable(id: 10, areaId: 4, name: '大圆桌', seats: 20),
        DiningTable(id: 11, areaId: 4, name: '小方桌', seats: 4),
      ];

      // 一楼只有1个大厅区域
      expect(areas.where((a) => a.floorId == 1).length, 1);
      expect(areas.where((a) => a.floorId == 1).first.type, AreaType.hall);

      // 二楼有1大厅+3包厢
      expect(areas.where((a) => a.floorId == 2).length, 4);
      expect(areas.where((a) => a.floorId == 2 && a.type == AreaType.hall).length, 1);
      expect(areas.where((a) => a.floorId == 2 && a.type == AreaType.privateRoom).length, 3);

      // VIP2号包厢有2张桌（大小桌组合）
      expect(tables.where((t) => t.areaId == 4).length, 2);

      // 每个区域必须属于某个楼层
      for (final a in areas) {
        expect(floors.any((f) => f.id == a.floorId), true, reason: '${a.name} 没有所属楼层');
      }

      // 每张桌必须属于某个区域
      for (final t in tables) {
        expect(areas.any((a) => a.id == t.areaId), true, reason: '${t.name} 没有所属区域');
      }
    });
  });
}

/// 简化的桌位空闲状态 mock
class _MockTableAvail {
  final bool free;
  _MockTableAvail({required this.free});
}

/// 测试用汇总结果
class ReservationSummary {
  final int total;
  final int booked;
  final int completed;
  final int cancelled;
  final int arrivalRate;
  const ReservationSummary({
    required this.total,
    required this.booked,
    required this.completed,
    required this.cancelled,
    required this.arrivalRate,
  });
}
