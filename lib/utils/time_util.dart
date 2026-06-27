import 'package:intl/intl.dart';

/// 时间工具
class TimeUtil {
  /// 今日日期 YYYY-MM-DD
  static String today() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// 格式化 DateTime 为 YYYY-MM-DD
  static String formatDate(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  /// 当前时间 HH:mm
  static String nowTime() {
    return DateFormat('HH:mm').format(DateTime.now());
  }

  /// 当前 ISO 时间戳
  static String nowIso() {
    return DateTime.now().toIso8601String();
  }

  /// 将 HH:mm 转为分钟数
  static int toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  /// 时段重叠判断：[s1,e1) 与 [s2,e2) 重叠
  /// 算法：s1 < e2 && s2 < e1
  static bool overlap(String s1, String e1, String s2, String e2) {
    final start1 = toMinutes(s1);
    final end1 = toMinutes(e1);
    final start2 = toMinutes(s2);
    final end2 = toMinutes(e2);
    return start1 < end2 && start2 < end1;
  }

  /// 判断预订是否即将到店（开始时间在前后30分钟内）
  static bool isUpcoming(String startTime) {
    final now = toMinutes(nowTime());
    final start = toMinutes(startTime);
    return start >= now - 30 && start <= now + 30;
  }

  /// 格式化日期为中文（X月X日 星期X）
  static String formatDateZh(String dateStr) {
    final d = DateTime.parse(dateStr);
    const weeks = ['日', '一', '二', '三', '四', '五', '六'];
    return '${d.month}月${d.day}日 · 星期${weeks[d.weekday - 1]}';
  }

  /// 获取指定日期偏移的日期
  static String dateOffset(String dateStr, int days) {
    final d = DateTime.parse(dateStr);
    return DateFormat('yyyy-MM-dd').format(d.add(Duration(days: days)));
  }
}
