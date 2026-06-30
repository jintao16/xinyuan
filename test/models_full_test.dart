import 'package:flutter_test/flutter_test.dart';
import 'package:xinyuan_hotel/data/models/area.dart';
import 'package:xinyuan_hotel/data/models/dining_table.dart';
import 'package:xinyuan_hotel/data/models/floor.dart';
import 'package:xinyuan_hotel/data/models/quick_time_slot.dart';
import 'package:xinyuan_hotel/data/models/reservation.dart';

/// 全量模型测试 - 覆盖所有模型的构造、序列化、copyWith、枚举、边界
void main() {
  group('ReservationStatus 枚举全量', () {
    test('fromDb - 所有有效值', () {
      expect(ReservationStatus.fromDb('booked'), ReservationStatus.booked);
      expect(ReservationStatus.fromDb('completed'), ReservationStatus.completed);
      expect(ReservationStatus.fromDb('cancelled'), ReservationStatus.cancelled);
    });

    test('fromDb - 无效值默认 booked', () {
      expect(ReservationStatus.fromDb('invalid'), ReservationStatus.booked);
      expect(ReservationStatus.fromDb(''), ReservationStatus.booked);
      expect(ReservationStatus.fromDb('BOOKED'), ReservationStatus.booked);
      expect(ReservationStatus.fromDb('未知'), ReservationStatus.booked);
    });

    test('dbValue 值正确', () {
      expect(ReservationStatus.booked.dbValue, 'booked');
      expect(ReservationStatus.completed.dbValue, 'completed');
      expect(ReservationStatus.cancelled.dbValue, 'cancelled');
    });

    test('label 中文标签全量', () {
      expect(ReservationStatus.booked.label, '已预订');
      expect(ReservationStatus.completed.label, '已完成');
      expect(ReservationStatus.cancelled.label, '已取消');
    });

    test('occupies 只有 booked 占用', () {
      expect(ReservationStatus.booked.occupies, true);
      expect(ReservationStatus.completed.occupies, false);
      expect(ReservationStatus.cancelled.occupies, false);
    });

    test('color 不同状态颜色不同', () {
      final colors = {
        ReservationStatus.booked.color,
        ReservationStatus.completed.color,
        ReservationStatus.cancelled.color,
      };
      expect(colors.length, 3, reason: '三种状态颜色应不同');
    });

    test('backgroundColor 不同状态背景色不同', () {
      final bgs = {
        ReservationStatus.booked.backgroundColor,
        ReservationStatus.completed.backgroundColor,
        ReservationStatus.cancelled.backgroundColor,
      };
      expect(bgs.length, 3);
    });
  });

  group('AreaType 枚举全量', () {
    test('fromDb - 所有有效值', () {
      expect(AreaType.fromDb('hall'), AreaType.hall);
      expect(AreaType.fromDb('private_room'), AreaType.privateRoom);
    });

    test('fromDb - 无效值默认 hall', () {
      expect(AreaType.fromDb('invalid'), AreaType.hall);
      expect(AreaType.fromDb(''), AreaType.hall);
      expect(AreaType.fromDb('HALL'), AreaType.hall);
    });

    test('dbValue 值正确', () {
      expect(AreaType.hall.dbValue, 'hall');
      expect(AreaType.privateRoom.dbValue, 'private_room');
    });

    test('label 中文标签', () {
      expect(AreaType.hall.label, '大厅');
      expect(AreaType.privateRoom.label, '包厢');
    });
  });

  group('Floor 模型全量', () {
    test('默认值构造', () {
      final f = Floor(name: '一楼');
      expect(f.id, isNull);
      expect(f.name, '一楼');
      expect(f.sortOrder, 0);
      expect(f.isMain, false);
    });

    test('完整构造', () {
      final f = Floor(id: 1, name: '二楼', sortOrder: 2, isMain: true);
      expect(f.id, 1);
      expect(f.name, '二楼');
      expect(f.sortOrder, 2);
      expect(f.isMain, true);
    });

    test('toMap 包含正确字段', () {
      final f = Floor(id: 5, name: '三楼', sortOrder: 3, isMain: false);
      final map = f.toMap();
      expect(map['id'], 5);
      expect(map['name'], '三楼');
      expect(map['sort_order'], 3);
      expect(map['is_main'], 0);
    });

    test('toMap - 无 id 时不包含 id 字段', () {
      final f = Floor(name: '四楼');
      final map = f.toMap();
      expect(map.containsKey('id'), false);
      expect(map['name'], '四楼');
    });

    test('fromMap - is_main 1 转 true', () {
      final f = Floor.fromMap({'id': 1, 'name': '一楼', 'sort_order': 1, 'is_main': 1});
      expect(f.isMain, true);
    });

    test('fromMap - is_main 0 转 false', () {
      final f = Floor.fromMap({'id': 1, 'name': '一楼', 'sort_order': 1, 'is_main': 0});
      expect(f.isMain, false);
    });

    test('fromMap - sort_order 缺省为 0', () {
      final f = Floor.fromMap({'id': 1, 'name': '一楼', 'is_main': 0});
      expect(f.sortOrder, 0);
    });

    test('copyWith 不改变原实例', () {
      final f = Floor(id: 1, name: '一楼', sortOrder: 1, isMain: false);
      final f2 = f.copyWith(name: '新名');
      expect(f.name, '一楼');
      expect(f2.name, '新名');
      expect(f2.id, 1);
      expect(f2.sortOrder, 1);
    });

    test('copyWith - 全字段覆盖', () {
      final f = Floor(id: 1, name: '一楼', sortOrder: 1, isMain: false);
      final f2 = f.copyWith(id: 2, name: '二楼', sortOrder: 2, isMain: true);
      expect(f2.id, 2);
      expect(f2.name, '二楼');
      expect(f2.sortOrder, 2);
      expect(f2.isMain, true);
    });

    test('toString 包含关键字段', () {
      final f = Floor(id: 1, name: '一楼', sortOrder: 1, isMain: true);
      final s = f.toString();
      expect(s, contains('Floor'));
      expect(s, contains('一楼'));
      expect(s, contains('isMain'));
    });

    test('相等性 - 同 id 相等', () {
      final f1 = Floor(id: 1, name: '一楼', sortOrder: 1, isMain: false);
      final f2 = Floor(id: 1, name: '不同名', sortOrder: 9, isMain: true);
      expect(f1 == f2, true);
      expect(f1.hashCode, f2.hashCode);
    });

    test('相等性 - 不同 id 不等', () {
      final f1 = Floor(id: 1, name: '一楼');
      final f2 = Floor(id: 2, name: '一楼');
      expect(f1 == f2, false);
    });
  });

  group('Area 模型全量', () {
    test('默认 sortOrder', () {
      final a = Area(floorId: 1, name: '大厅', type: AreaType.hall);
      expect(a.sortOrder, 0);
      expect(a.id, isNull);
    });

    test('完整构造', () {
      final a = Area(id: 1, floorId: 2, name: 'VIP1', type: AreaType.privateRoom, sortOrder: 3);
      expect(a.id, 1);
      expect(a.floorId, 2);
      expect(a.name, 'VIP1');
      expect(a.type, AreaType.privateRoom);
      expect(a.sortOrder, 3);
    });

    test('toMap 字段正确', () {
      final a = Area(id: 1, floorId: 2, name: 'VIP1', type: AreaType.privateRoom, sortOrder: 3);
      final map = a.toMap();
      expect(map['id'], 1);
      expect(map['floor_id'], 2);
      expect(map['name'], 'VIP1');
      expect(map['type'], 'private_room');
      expect(map['sort_order'], 3);
    });

    test('fromMap - sort_order 缺省 0', () {
      final a = Area.fromMap({'id': 1, 'floor_id': 2, 'name': 'VIP1', 'type': 'private_room'});
      expect(a.sortOrder, 0);
    });

    test('fromMap - num 类型转换', () {
      final a = Area.fromMap({
        'id': 1,
        'floor_id': 2.0, // num
        'name': 'VIP1',
        'type': 'private_room',
        'sort_order': 3.0,
      });
      expect(a.floorId, 2);
      expect(a.sortOrder, 3);
    });

    test('copyWith 全字段', () {
      final a = Area(id: 1, floorId: 2, name: 'VIP1', type: AreaType.privateRoom, sortOrder: 1);
      final a2 = a.copyWith(id: 2, floorId: 3, name: 'VIP2', type: AreaType.hall, sortOrder: 5);
      expect(a2.id, 2);
      expect(a2.floorId, 3);
      expect(a2.name, 'VIP2');
      expect(a2.type, AreaType.hall);
      expect(a2.sortOrder, 5);
    });

    test('相等性 - 同 id 相等', () {
      final a1 = Area(id: 1, floorId: 2, name: 'A', type: AreaType.hall);
      final a2 = Area(id: 1, floorId: 3, name: 'B', type: AreaType.privateRoom);
      expect(a1 == a2, true);
    });
  });

  group('DiningTable 模型全量', () {
    test('默认 sortOrder', () {
      final t = DiningTable(areaId: 1, name: 'A1', seats: 8);
      expect(t.sortOrder, 0);
      expect(t.id, isNull);
    });

    test('toMap 字段正确', () {
      final t = DiningTable(id: 5, areaId: 2, name: 'B1', seats: 4, sortOrder: 1);
      final map = t.toMap();
      expect(map['id'], 5);
      expect(map['area_id'], 2);
      expect(map['name'], 'B1');
      expect(map['seats'], 4);
      expect(map['sort_order'], 1);
    });

    test('fromMap - num 类型转换', () {
      final t = DiningTable.fromMap({
        'id': 1,
        'area_id': 2.0,
        'name': 'A1',
        'seats': 8.0,
        'sort_order': 1.0,
      });
      expect(t.areaId, 2);
      expect(t.seats, 8);
      expect(t.sortOrder, 1);
    });

    test('fromMap - sort_order 缺省 0', () {
      final t = DiningTable.fromMap({
        'id': 1,
        'area_id': 2,
        'name': 'A1',
        'seats': 8,
      });
      expect(t.sortOrder, 0);
    });

    test('copyWith 不改变原实例', () {
      final t = DiningTable(id: 1, areaId: 2, name: 'A1', seats: 8, sortOrder: 1);
      final t2 = t.copyWith(seats: 12);
      expect(t.seats, 8);
      expect(t2.seats, 12);
      expect(t2.name, 'A1');
    });

    test('边界 - seats 为 0', () {
      final t = DiningTable(areaId: 1, name: '测试', seats: 0);
      expect(t.seats, 0);
    });

    test('边界 - 名称为空字符串', () {
      final t = DiningTable(areaId: 1, name: '', seats: 4);
      expect(t.name, '');
    });
  });

  group('QuickTimeSlot 模型全量', () {
    test('默认 sortOrder', () {
      final s = QuickTimeSlot(name: '午餐', startTime: '11:00', endTime: '13:00');
      expect(s.sortOrder, 0);
      expect(s.id, isNull);
    });

    test('toMap 字段', () {
      final s = QuickTimeSlot(id: 1, name: '午餐', startTime: '11:00', endTime: '13:00', sortOrder: 1);
      final map = s.toMap();
      expect(map['id'], 1);
      expect(map['name'], '午餐');
      expect(map['start_time'], '11:00');
      expect(map['end_time'], '13:00');
      expect(map['sort_order'], 1);
    });

    test('fromMap 往返', () {
      final s = QuickTimeSlot(id: 1, name: '晚餐', startTime: '17:00', endTime: '19:00', sortOrder: 2);
      final map = s.toMap();
      final restored = QuickTimeSlot.fromMap(map);
      expect(restored.id, 1);
      expect(restored.name, '晚餐');
      expect(restored.startTime, '17:00');
      expect(restored.endTime, '19:00');
      expect(restored.sortOrder, 2);
    });

    test('copyWith', () {
      final s = QuickTimeSlot(id: 1, name: '午餐', startTime: '11:00', endTime: '13:00', sortOrder: 1);
      final s2 = s.copyWith(name: '下午茶', startTime: '14:00', endTime: '16:00');
      expect(s2.name, '下午茶');
      expect(s2.startTime, '14:00');
      expect(s2.endTime, '16:00');
      expect(s2.id, 1);
    });
  });

  group('Reservation 模型全量', () {
    test('大厅桌预订 - 默认 status booked', () {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      expect(r.status, ReservationStatus.booked);
      expect(r.customerPhone, '');
      expect(r.guestCount, isNull);
      expect(r.remark, '');
    });

    test('包厢预订 - 完整字段', () {
      final r = Reservation(
        id: 10,
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        areaId: 4,
        customerTitle: '李女士',
        customerPhone: '13800000000',
        guestCount: 8,
        status: ReservationStatus.completed,
        remark: '靠窗',
        createdAt: '2026-06-27T10:00:00',
        updatedAt: '2026-06-27T13:00:00',
      );
      expect(r.id, 10);
      expect(r.areaId, 4);
      expect(r.tableId, isNull);
      expect(r.customerPhone, '13800000000');
      expect(r.guestCount, 8);
      expect(r.status, ReservationStatus.completed);
      expect(r.remark, '靠窗');
    });

    test('互斥校验 - 同时传 tableId 和 areaId 抛 AssertionError', () {
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

    test('互斥校验 - 都不传也抛 AssertionError', () {
      expect(
        () => Reservation(
          date: '2026-06-27',
          startTime: '11:00',
          endTime: '13:00',
          customerTitle: '张先生',
          createdAt: '',
          updatedAt: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('toMap 全字段正确', () {
      final r = Reservation(
        id: 5,
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 3,
        customerTitle: '张先生',
        customerPhone: '13800000000',
        guestCount: 6,
        status: ReservationStatus.completed,
        remark: '靠窗',
        createdAt: '2026-06-27T10:00:00',
        updatedAt: '2026-06-27T12:00:00',
      );
      final map = r.toMap();
      expect(map['id'], 5);
      expect(map['date'], '2026-06-27');
      expect(map['start_time'], '11:00');
      expect(map['end_time'], '13:00');
      expect(map['table_id'], 3);
      expect(map['area_id'], isNull);
      expect(map['customer_title'], '张先生');
      expect(map['customer_phone'], '13800000000');
      expect(map['guest_count'], 6);
      expect(map['status'], 'completed');
      expect(map['remark'], '靠窗');
      expect(map['created_at'], '2026-06-27T10:00:00');
      expect(map['updated_at'], '2026-06-27T12:00:00');
    });

    test('toMap - 无 id 不包含 id 字段', () {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      final map = r.toMap();
      expect(map.containsKey('id'), false);
    });

    test('fromMap - 字段缺失默认值', () {
      final r = Reservation.fromMap({
        'id': 1,
        'date': '2026-06-27',
        'start_time': '11:00',
        'end_time': '13:00',
        'table_id': 1,
        'status': 'booked',
      });
      expect(r.customerTitle, '');
      expect(r.customerPhone, '');
      expect(r.guestCount, isNull);
      expect(r.remark, '');
      expect(r.createdAt, '');
      expect(r.updatedAt, '');
    });

    test('fromMap - 包厢预订', () {
      final r = Reservation.fromMap({
        'id': 2,
        'date': '2026-06-27',
        'start_time': '17:00',
        'end_time': '19:00',
        'area_id': 4,
        'customer_title': '李女士',
        'guest_count': 10,
        'status': 'cancelled',
        'remark': 'VIP',
        'created_at': '2026-06-27T10:00:00',
        'updated_at': '2026-06-27T16:00:00',
      });
      expect(r.areaId, 4);
      expect(r.tableId, isNull);
      expect(r.guestCount, 10);
      expect(r.status, ReservationStatus.cancelled);
    });

    test('copyWith - 状态变更', () {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      final r2 = r.copyWith(status: ReservationStatus.completed, updatedAt: '2026-06-27T13:30:00');
      expect(r.status, ReservationStatus.booked); // 原实例不变
      expect(r2.status, ReservationStatus.completed);
      expect(r2.updatedAt, '2026-06-27T13:30:00');
      expect(r2.customerTitle, '张先生');
    });

    test('copyWith - 切换桌位', () {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      final r2 = r.copyWith(tableId: 5);
      expect(r2.tableId, 5);
    });

    test('toString 包含关键字段', () {
      final r = Reservation(
        id: 1,
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      final s = r.toString();
      expect(s, contains('Reservation'));
      expect(s, contains('张先生'));
      expect(s, contains('2026-06-27'));
    });

    test('相等性 - 同 id 相等', () {
      final r1 = Reservation(
        id: 1,
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      );
      final r2 = Reservation(
        id: 1,
        date: '2026-12-31',
        startTime: '17:00',
        endTime: '19:00',
        tableId: 99,
        customerTitle: 'B',
        createdAt: '',
        updatedAt: '',
      );
      expect(r1 == r2, true);
      expect(r1.hashCode, r2.hashCode);
    });

    test('边界 - 客户名称为空', () {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '',
        createdAt: '',
        updatedAt: '',
      );
      expect(r.customerTitle, '');
    });

    test('边界 - 备注超长', () {
      final longRemark = '备注' * 1000;
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        remark: longRemark,
        createdAt: '',
        updatedAt: '',
      );
      expect(r.remark.length, 2000);
    });
  });
}
