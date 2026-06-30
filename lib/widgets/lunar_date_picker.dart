import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

/// 汉化农历日历选择器对话框
///
/// 每个日期格显示：公历日 + 农历/节日/节气，并标注节假日。
class LunarDatePickerDialog {
  /// 弹出农历日历选择器，返回用户选择的 [DateTime]；取消则返回 null。
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showDialog<DateTime?>(
      context: context,
      builder: (ctx) => _LunarDatePicker(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }
}

class _LunarDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const _LunarDatePicker({
    required this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<_LunarDatePicker> createState() => _LunarDatePickerState();
}

class _LunarDatePickerState extends State<_LunarDatePicker> {
  // 主题色
  static const Color _accent = Color(0xFFB95C26);
  static const Color _textPrimary = Color(0xFF1C1C24);
  static const Color _textSecondary = Color(0xFF5C5C66);
  static const Color _textTertiary = Color(0xFF8E8E98);

  late DateTime _displayMonth; // 当前显示月份（取该月 1 号）
  late DateTime _selectedDate; // 当前选中日期

  final List<String> _weekHeaders = ['日', '一', '二', '三', '四', '五', '六'];

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    _selectedDate = _dateOnly(widget.initialDate);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isOutOfRange(DateTime d) {
    if (widget.firstDate != null && d.isBefore(_dateOnly(widget.firstDate!))) {
      return true;
    }
    if (widget.lastDate != null && d.isAfter(_dateOnly(widget.lastDate!))) {
      return true;
    }
    return false;
  }

  /// 获取某日期的展示副文本（农历/节日/节气），优先级：节日 > 节气 > 农历日
  String _subtitleFor(DateTime date) {
    final solar = Solar.fromDate(date);
    final lunar = solar.getLunar();

    // 农历节日
    final lunarFestivals = lunar.getFestivals();
    if (lunarFestivals.isNotEmpty) {
      return _truncate(lunarFestivals.first, 4);
    }
    // 公历节日
    final solarFestivals = solar.getFestivals();
    if (solarFestivals.isNotEmpty) {
      return _truncate(solarFestivals.first, 4);
    }
    // 节气
    final jq = lunar.getJieQi();
    if (jq.isNotEmpty) {
      return jq;
    }
    // 农历日：初一时显示月名（如"五月"、"腊月"），其他显示日名
    if (lunar.getDay() == 1) {
      return '${lunar.getMonthInChinese()}月';
    }
    return lunar.getDayInChinese();
  }

  String _truncate(String s, int max) {
    if (s.length > max) {
      return s.substring(0, max);
    }
    return s;
  }

  /// 是否为节假日（有节日或节气）
  bool _isHoliday(DateTime date) {
    final solar = Solar.fromDate(date);
    final lunar = solar.getLunar();
    if (lunar.getFestivals().isNotEmpty) return true;
    if (solar.getFestivals().isNotEmpty) return true;
    if (lunar.getJieQi().isNotEmpty) return true;
    return false;
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
    });
  }

  /// 生成 42 个日期格子对应的 DateTime
  List<DateTime> _buildGrid() {
    final firstOfMonth = DateTime(_displayMonth.year, _displayMonth.month, 1);
    // 周日为 0
    final leading = firstOfMonth.weekday % 7;
    final start = firstOfMonth.subtract(Duration(days: leading));
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final now = _dateOnly(DateTime.now());
    final grid = _buildGrid();
    final title = '${_displayMonth.year}年${_displayMonth.month}月';

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部：年月切换条
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: _textSecondary),
                  onPressed: _prevMonth,
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: _textSecondary),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 星期表头
            Row(
              children: _weekHeaders
                  .map((w) => Expanded(
                        child: Text(
                          w,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _textTertiary,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // 日期网格
            Column(
              children: List.generate(6, (row) {
                return Row(
                  children: List.generate(7, (col) {
                    final index = row * 7 + col;
                    final date = grid[index];
                    return Expanded(child: _buildCell(date, now));
                  }),
                );
              }),
            ),
            const SizedBox(height: 4),
            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text(
                    '取消',
                    style: TextStyle(color: _textTertiary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDate),
                  child: const Text(
                    '确定',
                    style: TextStyle(color: _accent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(DateTime date, DateTime now) {
    final inCurrentMonth = date.month == _displayMonth.month;
    final isToday = _isSameDay(date, now);
    final isSelected = _isSameDay(date, _selectedDate);
    final isOutOfRange = _isOutOfRange(date);
    final isHoliday = _isHoliday(date);

    // 文字颜色
    Color dayColor = _textPrimary;
    Color subColor = _textTertiary;
    if (!inCurrentMonth) {
      dayColor = _textPrimary.withOpacity(0.35);
      subColor = _textTertiary.withOpacity(0.35);
    }
    if (isOutOfRange) {
      dayColor = _textTertiary.withOpacity(0.4);
      subColor = _textTertiary.withOpacity(0.35);
    }

    final subtitle = _subtitleFor(date);

    // 背景装饰
    BoxDecoration? decoration;
    if (isSelected) {
      decoration = const BoxDecoration(
        color: _accent,
        shape: BoxShape.circle,
      );
    } else if (isToday) {
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _accent, width: 1.5),
      );
    } else if (isHoliday && inCurrentMonth && !isOutOfRange) {
      decoration = BoxDecoration(
        color: _accent.withOpacity(0.12),
        shape: BoxShape.circle,
      );
    }

    // 选中态文字白色
    Color? selDayColor;
    Color? selSubColor;
    if (isSelected) {
      selDayColor = Colors.white;
      selSubColor = Colors.white.withOpacity(0.92);
    }

    Widget content = Container(
      height: 56,
      decoration: decoration,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: selDayColor ?? dayColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: selSubColor ?? subColor,
            ),
          ),
        ],
      ),
    );

    if (isOutOfRange) {
      return content;
    }

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        setState(() {
          _selectedDate = date;
          // 若点击的是前后月补足格，同步切换显示月份
          if (date.month != _displayMonth.month) {
            _displayMonth = DateTime(date.year, date.month, 1);
          }
        });
      },
      child: content,
    );
  }
}
