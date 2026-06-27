import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/reservation.dart';
import '../../providers/app_provider.dart';
import '../../utils/time_util.dart';
import '../../widgets/common.dart';
import '../../widgets/theme.dart';
import 'reservation_form_page.dart';

class ReservationListPage extends StatefulWidget {
  const ReservationListPage({super.key});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  String _date = TimeUtil.today();
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return FutureBuilder<List<Reservation>>(
          future: provider.getReservationsByDate(_date),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final list = _statusFilter == 'all'
                ? all
                : all.where((r) => r.status.dbValue == _statusFilter).toList();

            return ListView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
              children: [
                PageHeader(
                  subtitle: TimeUtil.formatDateZh(_date),
                  title: '预订',
                  trailing: OutlinedButton.icon(
                    onPressed: () => _pickDate(context),
                    icon: const Icon(CupertinoIcons.calendar, size: 14),
                    label: const Text('切换日期', style: TextStyle(fontSize: 13)),
                  ),
                ),

                // 状态筛选
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      const SizedBox(width: 4),
                      FilterPill(label: '全部', active: _statusFilter == 'all', onTap: () => setState(() => _statusFilter = 'all')),
                      const SizedBox(width: 8),
                      FilterPill(label: '已预订', active: _statusFilter == 'booked', onTap: () => setState(() => _statusFilter = 'booked')),
                      const SizedBox(width: 8),
                      FilterPill(label: '已完成', active: _statusFilter == 'completed', onTap: () => setState(() => _statusFilter = 'completed')),
                      const SizedBox(width: 8),
                      FilterPill(label: '已取消', active: _statusFilter == 'cancelled', onTap: () => setState(() => _statusFilter = 'cancelled')),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 新建按钮
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationFormPage()));
                    setState(() {});
                  },
                  icon: const Icon(CupertinoIcons.add, size: 18),
                  label: const Text('新建预订'),
                ),

                const SizedBox(height: 16),

                // 列表
                if (list.isEmpty)
                  const EmptyState(icon: '📭', text: '该日期暂无预订记录')
                else
                  ...list.map((r) => _ReservationTile(
                        reservation: r,
                        label: provider.getReservationLabel(r),
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => ReservationFormPage(editId: r.id)));
                          setState(() {});
                        },
                      )),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = TimeUtil.formatDate(picked);
      });
    }
  }
}

class _ReservationTile extends StatelessWidget {
  final Reservation reservation;
  final String label;
  final VoidCallback onTap;

  const _ReservationTile({required this.reservation, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final isCancelled = r.status == ReservationStatus.cancelled;
    final isUpcoming = r.status == ReservationStatus.booked &&
        r.date == TimeUtil.today() &&
        TimeUtil.isUpcoming(r.startTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isUpcoming)
                Container(
                  width: 4,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2)),
                )
              else
                const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Opacity(
                    opacity: isCancelled ? 0.6 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${r.startTime} — ${r.endTime}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                        const SizedBox(height: 4),
                        Text(
                          r.customerTitle.isEmpty ? '未留名' : r.customerTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            decoration: isCancelled ? TextDecoration.lineThrough : null,
                            fontStyle: isCancelled ? FontStyle.italic : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$label${r.guestCount != null ? ' · ${r.guestCount}人' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                            decoration: isCancelled ? TextDecoration.lineThrough : null,
                            fontStyle: isCancelled ? FontStyle.italic : null,
                          ),
                        ),
                        if (r.customerPhone.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('📞 ${r.customerPhone}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                        ],
                        if (r.remark.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('📝 ${r.remark}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Align(
                alignment: Alignment.topRight,
                child: StatusTag(status: r.status),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
