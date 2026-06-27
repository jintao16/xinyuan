import 'package:flutter_test/flutter_test.dart';
import 'package:xinyuan_hotel/data/models/area.dart';
import 'package:xinyuan_hotel/data/models/dining_table.dart';
import 'package:xinyuan_hotel/data/models/floor.dart';
import 'package:xinyuan_hotel/data/models/quick_time_slot.dart';
import 'package:xinyuan_hotel/data/models/reservation.dart';

void main() {
  group('ReservationStatus', () {
    test('从 db value 还原', () {
      expect(ReservationStatus.fromDb('booked'), ReservationStatus.booked);
      expect(ReservationStatus.fromDb('completed'), ReservationStatus.completed);
      expect(ReservationStatus.fromDb('cancelled'), ReservationStatus.cancelled);
      // 无效值默认 booked
      expect(ReservationStatus.fromDb('invalid'), ReservationStatus.booked);
    });

    test('occupies 只有 booked 占用资源', () {
      expect(ReservationStatus.booked.occupies, true);
      expect(ReservationStatus.completed.occupies, false);
      expect(ReservationStatus.cancelled.occupies, false);
    });

    test('label 中文标签', () {
      expect(ReservationStatus.booked.label, '已预订');
      expect(ReservationStatus.completed.label, '已完成');
      expect(ReservationStatus.cancelled.label, '已取消');
    });
  });

  group('Reservation 模型', () {
    test('tableId 与 areaId 互斥校验（构造时不抛错）', () {
      // 大厅桌预订
      expect(() => Reservation(
            date: '2026-06-27',
            startTime: '11:00',
            endTime: '13:00',
            tableId: 1,
            customerTitle: '张先生',
            createdAt: '',
            updatedAt: '',
          ), returnsNormally);

      // 包厢预订
      expect(() => Reservation(
            date: '2026-06-27',
            startTime: '11:00',
            endTime: '13:00',
            areaId: 1,
            customerTitle: '李女士',
            createdAt: '',
            updatedAt: '',
          ), returnsNormally);
    });

    test('toMap/fromMap 往返一致', () {
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
      expect(map['area_id'], null);
      expect(map['status'], 'completed');
      expect(map['guest_count'], 6);

      final restored = Reservation.fromMap(map);
      expect(restored.id, 5);
      expect(restored.date, '2026-06-27');
      expect(restored.tableId, 3);
      expect(restored.areaId, null);
      expect(restored.status, ReservationStatus.completed);
      expect(restored.customerTitle, '张先生');
    });

    test('copyWith 不改变原实例', () {
      final r = Reservation(
        date: '2026-06-27',
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      );
      final r2 = r.copyWith(status: ReservationStatus.cancelled);
      expect(r.status, ReservationStatus.booked);
      expect(r2.status, ReservationStatus.cancelled);
      expect(r2.tableId, 1);
    });
  });

  group('AreaType', () {
    test('从 db value 还原', () {
      expect(AreaType.fromDb('hall'), AreaType.hall);
      expect(AreaType.fromDb('private_room'), AreaType.privateRoom);
      expect(AreaType.fromDb('invalid'), AreaType.hall);
    });

    test('label 中文标签', () {
      expect(AreaType.hall.label, '大厅');
      expect(AreaType.privateRoom.label, '包厢');
    });
  });

  group('Floor model', () {
    test('fromMap/toMap 往返', () {
      final f = Floor(id: 1, name: '一楼', sortOrder: 1, isMain: false);
      final map = f.toMap();
      expect(map['name'], '一楼');
      expect(map['is_main'], 0);
      expect(map['sort_order'], 1);

      final restored = Floor.fromMap({
        'id': 2,
        'name': '二楼',
        'sort_order': 2,
        'is_main': 1,
      });
      expect(restored.id, 2);
      expect(restored.isMain, true);
    });
  });

  group('DiningTable model', () {
    test('fromMap/toMap 往返', () {
      final t = DiningTable(id: 1, areaId: 2, name: 'A1', seats: 8, sortOrder: 1);
      final map = t.toMap();
      expect(map['name'], 'A1');
      expect(map['seats'], 8);

      final restored = DiningTable.fromMap({
        'id': 1,
        'area_id': 2,
        'name': 'A1',
        'seats': 8,
        'sort_order': 1,
      });
      expect(restored.seats, 8);
      expect(restored.areaId, 2);
    });
  });

  group('QuickTimeSlot model', () {
    test('fromMap/toMap 往返', () {
      final s = QuickTimeSlot(id: 1, name: '午餐', startTime: '11:00', endTime: '13:00', sortOrder: 1);
      final map = s.toMap();
      expect(map['name'], '午餐');
      expect(map['start_time'], '11:00');
      expect(map['end_time'], '13:00');

      final restored = QuickTimeSlot.fromMap({
        'id': 1,
        'name': '午餐',
        'start_time': '11:00',
        'end_time': '13:00',
        'sort_order': 1,
      });
      expect(restored.name, '午餐');
      expect(restored.startTime, '11:00');
    });
  });
}
