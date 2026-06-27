import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/stats_service.dart';
import '../../utils/time_util.dart';
import '../../widgets/common.dart';
import '../../widgets/theme.dart';

/// 统计报表页
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  /// 周期：week / month
  String _period = 'week';
  DateTime _end = DateTime.now();

  ReservationSummary? _summary;
  List<TableUsageItem>? _tableUsage;
  List<HourlyItem>? _hourly;
  AreaRatio? _areaRatio;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  (String, String) _range() {
    final end = _end;
    final start = _period == 'week'
        ? end.subtract(const Duration(days: 7))
        : DateTime(end.year, end.month, 1);
    return (TimeUtil.formatDate(start), TimeUtil.formatDate(end));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = context.read<AppProvider>();
    final (s, e) = _range();
    final summary = await p.statsService.summary(s, e);
    final usage = await p.statsService.tableUsage(s, e);
    final hourly = await p.statsService.hourlyDistribution(s, e);
    final ratio = await p.statsService.areaRatio(s, e);
    if (mounted) {
      setState(() {
        _summary = summary;
        _tableUsage = usage;
        _hourly = hourly;
        _areaRatio = ratio;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final (s, e) = _range();
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
      children: [
        PageHeader(
          subtitle: '$s 至 $e',
          title: '统计',
        ),

        // 周期切换
        Row(
          children: [
            FilterPill(label: '本周', active: _period == 'week', onTap: () {
              setState(() => _period = 'week');
              _load();
            }),
            const SizedBox(width: 8),
            FilterPill(label: '本月', active: _period == 'month', onTap: () {
              setState(() => _period = 'month');
              _load();
            }),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(CupertinoIcons.calendar, size: 14),
              label: const Text('截止', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (_loading)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator()))
        else if (_summary == null)
          const EmptyState(icon: '📊', text: '暂无统计数据')
        else
          ...[
            _SummarySection(summary: _summary!),
            const SizedBox(height: 16),
            _AreaRatioSection(ratio: _areaRatio!),
            const SizedBox(height: 16),
            _HourlySection(items: _hourly!),
            const SizedBox(height: 16),
            _TableUsageSection(items: _tableUsage!),
          ],
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _end = picked);
      _load();
    }
  }
}

/// 汇总卡片
class _SummarySection extends StatelessWidget {
  final ReservationSummary summary;
  const _SummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('预订汇总', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _Item(value: summary.total, label: '总数', color: AppTheme.accent),
              _Item(value: summary.booked, label: '已预订', color: AppTheme.info),
              _Item(value: summary.completed, label: '已完成', color: AppTheme.success),
              _Item(value: summary.cancelled, label: '已取消', color: AppTheme.textTertiary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('到店率', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Expanded(
                child: LinearProgressIndicator(
                  value: summary.arrivalRate / 100,
                  minHeight: 8,
                  backgroundColor: AppTheme.glassBgSoft,
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Text('${summary.arrivalRate}%',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.success)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Item({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// 区域占比
class _AreaRatioSection extends StatelessWidget {
  final AreaRatio ratio;
  const _AreaRatioSection({required this.ratio});

  @override
  Widget build(BuildContext context) {
    if (ratio.total == 0) {
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('区域占比', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            const Text('暂无数据', style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
          ],
        ),
      );
    }
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('区域占比', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: [
                        PieChartSectionData(
                          value: ratio.halls.toDouble(),
                          color: AppTheme.accent,
                          radius: 24,
                          title: '${ratio.hallsPercent}%',
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        PieChartSectionData(
                          value: ratio.rooms.toDouble(),
                          color: const Color(0xFF78B4C8),
                          radius: 24,
                          title: '${ratio.roomsPercent}%',
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('大厅 ${ratio.halls} 单', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF78B4C8), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('包厢 ${ratio.rooms} 单', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 时段分布
class _HourlySection extends StatelessWidget {
  final List<HourlyItem> items;
  const _HourlySection({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxCount = items.fold<int>(1, (a, b) => a > b.count ? a : b.count);
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('时段分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxCount.toDouble() * 1.2,
                barGroups: items
                    .map((h) => BarChartGroupData(
                          x: h.hour,
                          barRods: [
                            BarChartRodData(
                              toY: h.count.toDouble(),
                              width: 10,
                              color: AppTheme.accent,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        ))
                    .toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('9时 — 22时', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
        ],
      ),
    );
  }
}

/// 桌位使用率
class _TableUsageSection extends StatelessWidget {
  final List<TableUsageItem> items;
  const _TableUsageSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('桌位使用率', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('暂无数据', style: TextStyle(color: AppTheme.textTertiary, fontSize: 13))
          else
            ...items.take(8).map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 100, child: Text(it.name, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: it.percent / 100,
                          minHeight: 8,
                          backgroundColor: AppTheme.glassBgSoft,
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(width: 30, child: Text('${it.count}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accent), textAlign: TextAlign.right)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
