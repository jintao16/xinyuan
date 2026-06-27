import 'package:flutter_test/flutter_test.dart';
import 'package:xinyuan_hotel/utils/time_util.dart';

void main() {
  group('TimeUtil', () {
    test('toMinutes 正确转换 HH:mm', () {
      expect(TimeUtil.toMinutes('00:00'), 0);
      expect(TimeUtil.toMinutes('01:00'), 60);
      expect(TimeUtil.toMinutes('11:30'), 690);
      expect(TimeUtil.toMinutes('23:59'), 1439);
      expect(TimeUtil.toMinutes('invalid'), 0);
    });

    test('overlap 时段重叠判断 - s1 < e2 && s2 < e1', () {
      // 完全不重叠
      expect(TimeUtil.overlap('10:00', '11:00', '12:00', '13:00'), false);
      // 相邻不重叠（结束=开始）
      expect(TimeUtil.overlap('10:00', '11:00', '11:00', '12:00'), false);
      // 部分重叠
      expect(TimeUtil.overlap('10:00', '12:00', '11:00', '13:00'), true);
      // 包含
      expect(TimeUtil.overlap('10:00', '14:00', '11:00', '12:00'), true);
      // 完全相同
      expect(TimeUtil.overlap('11:00', '13:00', '11:00', '13:00'), true);
    });

    test('formatDate 格式化日期为 YYYY-MM-DD', () {
      expect(TimeUtil.formatDate(DateTime(2026, 6, 27)), '2026-06-27');
      expect(TimeUtil.formatDate(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('dateOffset 日期偏移', () {
      expect(TimeUtil.dateOffset('2026-06-27', 1), '2026-06-28');
      expect(TimeUtil.dateOffset('2026-06-27', -1), '2026-06-26');
      expect(TimeUtil.dateOffset('2026-01-01', -1), '2025-12-31');
    });

    test('formatDateZh 中文日期格式', () {
      // 2026-06-27 是星期五
      expect(TimeUtil.formatDateZh('2026-06-27'), contains('6月27日'));
      expect(TimeUtil.formatDateZh('2026-06-27'), contains('星期五'));
    });
  });
}
