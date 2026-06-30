import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Cupertino 滚轮时间选择器（底部弹起）
class CupertinoTimePickerDialog {
  /// 弹起时间选择器
  ///
  /// [initialTime] 格式为 "HH:mm"
  /// 返回用户选择的 "HH:mm" 字符串；用户取消时返回 null
  static Future<String?> show(BuildContext context, {required String initialTime}) {
    // 解析初始时间，年月日固定为 2020-01-01，仅用时分
    final parts = initialTime.split(':');
    int initialHour = 0;
    int initialMinute = 0;
    if (parts.length == 2) {
      initialHour = int.tryParse(parts[0]) ?? 0;
      initialMinute = int.tryParse(parts[1]) ?? 0;
      if (initialHour < 0 || initialHour > 23) initialHour = 0;
      if (initialMinute < 0 || initialMinute > 59) initialMinute = 0;
    }
    DateTime selected = DateTime(2020, 1, 1, initialHour, initialMinute);

    // 主题色
    const Color accent = Color(0xFFB95C26);
    const Color grayText = Color(0xFF5C5C66);

    return showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Material(
              color: Colors.transparent,
              child: Container(
                height: 280,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // 顶部按钮行
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(null),
                            child: const Text(
                              '取消',
                              style: TextStyle(
                                fontSize: 16,
                                color: grayText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                '选择时间',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1C1C24),
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final hh = selected.hour.toString().padLeft(2, '0');
                              final mm = selected.minute.toString().padLeft(2, '0');
                              Navigator.of(ctx).pop('$hh:$mm');
                            },
                            child: const Text(
                              '确定',
                              style: TextStyle(
                                fontSize: 16,
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFEDEDED)),
                    // 滚轮选择器
                    Expanded(
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: true,
                        minuteInterval: 1,
                        initialDateTime: selected,
                        onDateTimeChanged: (DateTime value) {
                          setState(() {
                            selected = DateTime(
                              2020,
                              1,
                              1,
                              value.hour,
                              value.minute,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
