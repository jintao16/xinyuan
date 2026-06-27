import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/reservation.dart';
import '../../providers/app_provider.dart';
import '../../utils/time_util.dart';
import '../../widgets/common.dart';
import '../../widgets/theme.dart';
import '../reservation/reservation_form_page.dart';
import '../reservation/reservation_list_page.dart';
import '../availability/availability_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final today = TimeUtil.today();
        final upcoming = provider.upcoming;

        // 今日时段分布
        final hours = <int, int>{};
        for (final r in provider.todayReservations) {
          final h = int.tryParse(r.startTime.split(':')[0]) ?? 0;
          hours[h] = (hours[h] ?? 0) + 1;
        }
        final maxHour = hours.values.fold(1, (a, b) => a > b ? a : b);

        return ListView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
          children: [
            PageHeader(
              subtitle: '今日 · $today',
              title: '鑫源大酒店',
            ),

            // 统计卡片
            Row(
              children: [
                _StatCard(value: provider.bookedCountToday, label: '已预订', color: AppTheme.accent),
                const SizedBox(width: 10),
                _StatCard(value: provider.completedCountToday, label: '已完成', color: AppTheme.success),
                const SizedBox(width: 10),
                _StatCard(value: provider.cancelledCountToday, label: '已取消', color: AppTheme.textTertiary),
              ],
            ),

            // 即将到店 或 时段分布
            if (upcoming.isNotEmpty) ...[
              const SectionTitle('即将到店'),
              ...upcoming.map((r) => _UpcomingCard(
                    time: '${r.startTime} — ${r.endTime}',
                    customer: r.customerTitle.isEmpty ? '未留名' : r.customerTitle,
                    info: '${provider.getReservationLabel(r)}${r.guestCount != null ? ' · ${r.guestCount}人' : ''}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReservationFormPage(editId: r.id))),
                  )),
            ] else ...[
              const SectionTitle('今日时段'),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (int h = 9; h <= 22; h++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                                child: FractionallySizedBox(
                                  heightFactor: maxHour == 0 ? 0.05 : (hours[h] ?? 0) / maxHour,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [AppTheme.accent, AppTheme.accentSoft],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('9时 — 22时 预订分布', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                  ],
                ),
              ),
            ],

            // 快捷操作
            const SectionTitle('快捷操作'),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    key: const ValueKey('home_btn_new_reservation'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationFormPage())),
                    icon: const Icon(CupertinoIcons.add, size: 18),
                    label: const Text('新建预订'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('home_btn_availability'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvailabilityPage())),
                    icon: const Icon(CupertinoIcons.search, size: 18),
                    label: const Text('查询空闲'),
                  ),
                ),
              ],
            ),

            // 今日全部预订（前5条）
            if (provider.todayReservations.isNotEmpty) ...[
              const SectionTitle('今日全部预订'),
              ...provider.todayReservations.take(5).map((r) => _ReservationCard(
                    reservation: r,
                    label: provider.getReservationLabel(r),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReservationFormPage(editId: r.id))),
                  )),
              if (provider.todayReservations.length > 5)
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationListPage())),
                  child: const Text('查看全部 →'),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        borderRadius: AppTheme.radiusMd,
        child: Column(
          children: [
            Text(value.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.02)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final String time;
  final String customer;
  final String info;
  final VoidCallback onTap;

  const _UpcomingCard({required this.time, required this.customer, required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // 左侧高亮条
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
            ),
            GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accent, letterSpacing: 0.02)),
                    const SizedBox(height: 4),
                    Text(customer, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(info, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 0,
              right: 0,
              child: StatusTag(status: ReservationStatus.booked),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final String label;
  final VoidCallback onTap;

  const _ReservationCard({required this.reservation, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final isCancelled = r.status == ReservationStatus.cancelled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: onTap,
          child: Opacity(
            opacity: isCancelled ? 0.6 : 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.startTime} — ${r.endTime}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                      const SizedBox(height: 4),
                      Text(
                        r.customerTitle.isEmpty ? '未留名' : r.customerTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                          fontStyle: isCancelled ? FontStyle.italic : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$label${r.guestCount != null ? ' · ${r.guestCount}人' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                          fontStyle: isCancelled ? FontStyle.italic : null,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusTag(status: r.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
