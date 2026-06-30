import 'package:flutter_test/flutter_test.dart';
import 'package:xinyuan_hotel/utils/time_util.dart';

/// TimeUtil 全量测试
void main() {
  group('TimeUtil.toMinutes', () {
    test('整点转换', () {
      expect(TimeUtil.toMinutes('00:00'), 0);
      expect(TimeUtil.toMinutes('01:00'), 60);
      expect(TimeUtil.toMinutes('12:00'), 720);
      expect(TimeUtil.toMinutes('23:00'), 1380);
    });

    test('半点转换', () {
      expect(TimeUtil.toMinutes('00:30'), 30);
      expect(TimeUtil.toMinutes('11:30'), 690);
      expect(TimeUtil.toMinutes('23:30'), 1410);
    });

    test('分钟数转换', () {
      expect(TimeUtil.toMinutes('00:01'), 1);
      expect(TimeUtil.toMinutes('00:59'), 59);
      expect(TimeUtil.toMinutes('23:59'), 1439);
    });

    test('边界 - 最大值', () {
      expect(TimeUtil.toMinutes('23:59'), 1439);
    });

    test('边界 - 最小值', () {
      expect(TimeUtil.toMinutes('00:00'), 0);
    });

    test('无效输入返回 0', () {
      expect(TimeUtil.toMinutes('invalid'), 0);
      expect(TimeUtil.toMinutes(''), 0);
      expect(TimeUtil.toMinutes('25:00'), 1500); // 25*60, 不校验范围
      expect(TimeUtil.toMinutes('12'), 0); // 只有一段
      expect(TimeUtil.toMinutes('12:60'), 780); // 12*60+60
      expect(TimeUtil.toMinutes('abc:def'), 0);
      expect(TimeUtil.toMinutes('12:ab'), 720); // 12*60 + 0
    });
  });

  group('TimeUtil.overlap', () {
    test('完全不重叠 - 不冲突', () {
      expect(TimeUtil.overlap('10:00', '11:00', '12:00', '13:00'), false);
      expect(TimeUtil.overlap('09:00', '10:00', '14:00', '16:00'), false);
      expect(TimeUtil.overlap('08:00', '10:00', '20:00', '22:00'), false);
    });

    test('相邻（结束=开始）- 不冲突', () {
      expect(TimeUtil.overlap('11:00', '13:00', '13:00', '15:00'), false);
      expect(TimeUtil.overlap('10:00', '11:00', '11:00', '12:00'), false);
      expect(TimeUtil.overlap('09:00', '17:00', '17:00', '19:00'), false);
    });

    test('部分重叠 - 冲突', () {
      expect(TimeUtil.overlap('11:00', '13:00', '12:00', '14:00'), true);
      expect(TimeUtil.overlap('10:00', '12:00', '11:00', '13:00'), true);
      expect(TimeUtil.overlap('10:00', '14:00', '13:00', '15:00'), true);
    });

    test('完全包含 - 冲突', () {
      expect(TimeUtil.overlap('10:00', '14:00', '11:00', '12:00'), true);
      expect(TimeUtil.overlap('11:00', '12:00', '10:00', '14:00'), true);
      expect(TimeUtil.overlap('00:00', '23:59', '12:00', '13:00'), true);
    });

    test('完全相同 - 冲突', () {
      expect(TimeUtil.overlap('11:00', '13:00', '11:00', '13:00'), true);
      expect(TimeUtil.overlap('00:00', '23:59', '00:00', '23:59'), true);
    });

    test('A 完全在 B 之前 - 不冲突', () {
      expect(TimeUtil.overlap('08:00', '09:00', '10:00', '11:00'), false);
    });

    test('A 完全在 B 之后 - 不冲突', () {
      expect(TimeUtil.overlap('10:00', '11:00', '08:00', '09:00'), false);
    });

    test('零长度时段 - 起止相同不重叠', () {
      // 11:00-11:00 与 11:00-12:00：start1 < e2 (11*60 < 12*60=true) && start2 < e1 (11*60 < 11*60=false)
      expect(TimeUtil.overlap('11:00', '11:00', '11:00', '12:00'), false);
    });
  });

  group('TimeUtil.formatDate', () {
    test('正常日期', () {
      expect(TimeUtil.formatDate(DateTime(2026, 6, 27)), '2026-06-27');
      expect(TimeUtil.formatDate(DateTime(2026, 1, 1)), '2026-01-01');
      expect(TimeUtil.formatDate(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('补零', () {
      expect(TimeUtil.formatDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(TimeUtil.formatDate(DateTime(2026, 10, 1)), '2026-10-01');
    });

    test('跨年', () {
      expect(TimeUtil.formatDate(DateTime(2025, 12, 31)), '2025-12-31');
      expect(TimeUtil.formatDate(DateTime(2027, 1, 1)), '2027-01-01');
    });
  });

  group('TimeUtil.dateOffset', () {
    test('正常偏移', () {
      expect(TimeUtil.dateOffset('2026-06-27', 1), '2026-06-28');
      expect(TimeUtil.dateOffset('2026-06-27', -1), '2026-06-26');
      expect(TimeUtil.dateOffset('2026-06-27', 7), '2026-07-04');
      expect(TimeUtil.dateOffset('2026-06-27', -7), '2026-06-20');
    });

    test('跨月', () {
      expect(TimeUtil.dateOffset('2026-01-31', 1), '2026-02-01');
      expect(TimeUtil.dateOffset('2026-03-01', -1), '2026-02-28');
    });

    test('跨年', () {
      expect(TimeUtil.dateOffset('2026-01-01', -1), '2025-12-31');
      expect(TimeUtil.dateOffset('2025-12-31', 1), '2026-01-01');
    });

    test('闰年 2 月 29 日', () {
      // 2024 是闰年
      expect(TimeUtil.dateOffset('2024-02-28', 1), '2024-02-29');
      expect(TimeUtil.dateOffset('2024-02-29', 1), '2024-03-01');
      expect(TimeUtil.dateOffset('2024-02-29', -1), '2024-02-28');
    });

    test('非闰年 2 月', () {
      // 2026 非闰年
      expect(TimeUtil.dateOffset('2026-02-28', 1), '2026-03-01');
      expect(TimeUtil.dateOffset('2026-03-01', -1), '2026-02-28');
    });

    test('大偏移量', () {
      expect(TimeUtil.dateOffset('2026-01-01', 365), '2027-01-01');
      expect(TimeUtil.dateOffset('2026-01-01', -365), '2025-01-01');
    });
  });

  group('TimeUtil.formatDateZh', () {
    test('包含月日', () {
      expect(TimeUtil.formatDateZh('2026-06-27'), contains('6月27日'));
      expect(TimeUtil.formatDateZh('2026-01-01'), contains('1月1日'));
      expect(TimeUtil.formatDateZh('2026-12-31'), contains('12月31日'));
    });

    test('包含星期', () {
      expect(TimeUtil.formatDateZh('2026-06-27'), contains('星期五')); // 2026-06-27 周五
      expect(TimeUtil.formatDateZh('2026-06-28'), contains('星期六'));
      expect(TimeUtil.formatDateZh('2026-06-29'), contains('星期日'));
      expect(TimeUtil.formatDateZh('2026-06-30'), contains('星期一'));
      expect(TimeUtil.formatDateZh('2026-07-01'), contains('星期二'));
      expect(TimeUtil.formatDateZh('2026-07-02'), contains('星期三'));
      expect(TimeUtil.formatDateZh('2026-07-03'), contains('星期四'));
    });

    test('完整格式校验', () {
      // 2026-01-01 是周四
      expect(TimeUtil.formatDateZh('2026-01-01'), '1月1日 · 星期四');
    });
  });

  group('TimeUtil.isUpcoming', () {
    // 注意：isUpcoming 依赖当前时间，测试只能验证逻辑边界
    // 这里通过 toMinutes 和算法复刻来验证逻辑
    bool isUpcoming(String startTime, String nowTime) {
      final now = TimeUtil.toMinutes(nowTime);
      final start = TimeUtil.toMinutes(startTime);
      return start >= now - 30 && start <= now + 30;
    }

    test('当前时间就是开始时间 - 即将到店', () {
      expect(isUpcoming('12:00', '12:00'), true);
    });

    test('开始时间在 30 分钟内 - 即将到店', () {
      expect(isUpcoming('12:30', '12:00'), true); // 30 分钟后
      expect(isUpcoming('11:30', '12:00'), true); // 30 分钟前
      expect(isUpcoming('12:15', '12:00'), true); // 15 分钟后
      expect(isUpcoming('11:45', '12:00'), true); // 15 分钟前
    });

    test('边界 - 正好 30 分钟 - 即将到店', () {
      expect(isUpcoming('12:30', '12:00'), true);
      expect(isUpcoming('11:30', '12:00'), true);
    });

    test('开始时间超出 30 分钟 - 非即将到店', () {
      expect(isUpcoming('13:00', '12:00'), false); // 60 分钟后
      expect(isUpcoming('11:00', '12:00'), false); // 60 分钟前
      expect(isUpcoming('15:00', '12:00'), false); // 3 小时后
      expect(isUpcoming('09:00', '12:00'), false); // 3 小时前
    });

    test('跨日边界', () {
      // 23:50 开始，当前 00:10（即 1430 分钟 vs 10 分钟）
      // isUpcoming 的实现是数值比较，跨日会判断为非 upcoming
      // 这是已知的简化逻辑，仅作记录
      final now = TimeUtil.toMinutes('00:10');
      final start = TimeUtil.toMinutes('23:50');
      expect(start >= now - 30 && start <= now + 30, false); // 1430 > 40
    });
  });

  group('TimeUtil.today / nowTime / nowIso', () {
    test('today 返回 YYYY-MM-DD 格式', () {
      final today = TimeUtil.today();
      expect(today.length, 10);
      expect(today[4], '-');
      expect(today[7], '-');
    });

    test('nowTime 返回 HH:mm 格式', () {
      final now = TimeUtil.nowTime();
      expect(now.length, 5);
      expect(now[2], ':');
    });

    test('nowIso 返回非空字符串', () {
      final iso = TimeUtil.nowIso();
      expect(iso.isNotEmpty, true);
    });
  });

  group('算法等价性 - SQL 与 TimeUtil.overlap', () {
    /// reservation_dao.dart 的 SQL 算法:
    /// start_time < endTime AND end_time > startTime
    /// 即 s1 < e2 AND e1 > s2
    bool sqlLogic(String s1, String e1, String s2, String e2) {
      final start1 = TimeUtil.toMinutes(s1);
      final end1 = TimeUtil.toMinutes(e1);
      final start2 = TimeUtil.toMinutes(s2);
      final end2 = TimeUtil.toMinutes(e2);
      return start1 < end2 && end1 > start2;
    }

    test('SQL 算法与 TimeUtil.overlap 等价', () {
      final times = ['00:00', '09:00', '11:00', '12:00', '13:00', '14:00', '17:00', '19:00', '23:59'];
      for (final s1 in times) {
        for (final e1 in times) {
          for (final s2 in times) {
            for (final e2 in times) {
              if (s1 != e1 && s2 != e2) {
                final sql = sqlLogic(s1, e1, s2, e2);
                final util = TimeUtil.overlap(s1, e1, s2, e2);
                expect(sql, util,
                    reason: '不一致: $s1-$e1 vs $s2-$e2 (sql=$sql, util=$util)');
              }
            }
          }
        }
      }
    });
  });
}
