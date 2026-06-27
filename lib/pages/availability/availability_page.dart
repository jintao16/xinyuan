import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/area.dart';
import '../../data/models/reservation.dart';
import '../../providers/app_provider.dart';
import '../../services/availability_service.dart';
import '../../utils/time_util.dart';
import '../../widgets/common.dart';
import '../../widgets/theme.dart';
import '../reservation/reservation_form_page.dart';

/// 空闲查询页
class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  String _date = '';
  String _startTime = '11:00';
  String _endTime = '13:00';
  final _guestController = TextEditingController();
  int? _guestCount;

  List<FloorAvailability> _data = [];
  bool _loading = false;
  bool _queried = false;

  @override
  void initState() {
    super.initState();
    _date = TimeUtil.today();
    _runQuery();
  }

  Future<void> _runQuery() async {
    setState(() {
      _loading = true;
      _queried = true;
    });
    final provider = context.read<AppProvider>();
    final data = await provider.availabilityService.query(
      date: _date,
      startTime: _startTime,
      endTime: _endTime,
      guestCount: _guestCount,
    );
    if (mounted) setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _guestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
      children: [
        PageHeader(
          subtitle: TimeUtil.formatDateZh(_date),
          title: '空闲查询',
          trailing: OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(CupertinoIcons.calendar, size: 14),
            label: const Text('日期', style: TextStyle(fontSize: 13)),
          ),
        ),

        // 时段与人数筛选
        GlassContainer(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('时段', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _TimeField(value: _startTime, onChanged: (v) => setState(() => _startTime = v))),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('—')),
                  Expanded(child: _TimeField(value: _endTime, onChanged: (v) => setState(() => _endTime = v))),
                ],
              ),
              const SizedBox(height: 10),
              // 快捷时段
              Consumer<AppProvider>(
                builder: (context, p, _) {
                  if (p.timeSlots.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final s in p.timeSlots) ...[
                          FilterPill(
                            label: s.name,
                            active: _startTime == s.startTime && _endTime == s.endTime,
                            onTap: () => setState(() {
                              _startTime = s.startTime;
                              _endTime = s.endTime;
                            }),
                          ),
                          const SizedBox(width: 8),
                        ]
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text('用餐人数（选填）', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _guestController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '人数', isDense: true),
                      onChanged: (v) => _guestCount = int.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: _loading ? null : _runQuery, child: const Text('查询')),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 查询结果
        if (_loading)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator()))
        else if (!_queried)
          const EmptyState(icon: '🔍', text: '设置时段后点击「查询」')
        else if (_data.isEmpty)
          const EmptyState(icon: '📭', text: '无楼层/区域数据')
        else
          ..._data.map((f) => _FloorSection(
                floor: f,
                onBookTable: (tableId) => _goBook(tableId: tableId),
                onBookArea: (areaId) => _goBook(areaId: areaId),
              )),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = TimeUtil.formatDate(picked));
      _runQuery();
    }
  }

  Future<void> _goBook({int? tableId, int? areaId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReservationFormPage(),
      ),
    );
    _runQuery();
  }
}

/// 时间选择字段
class _TimeField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _TimeField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            prefixIcon: const Icon(CupertinoIcons.clock, size: 18),
            isDense: true,
          ),
          controller: TextEditingController(text: value),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final initial = TimeUtil.toMinutes(value);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      onChanged('$hh:$mm');
    }
  }
}

/// 楼层分区
class _FloorSection extends StatelessWidget {
  final FloorAvailability floor;
  final ValueChanged<int> onBookTable;
  final ValueChanged<int> onBookArea;

  const _FloorSection({required this.floor, required this.onBookTable, required this.onBookArea});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 楼层标题
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              floor.floor.name + (floor.floor.isMain ? ' · 主楼' : ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.02),
            ),
          ),
          // 区域
          ...floor.areas.map((a) => _AreaCard(area: a, onBookTable: onBookTable, onBookArea: onBookArea)),
        ],
      ),
    );
  }
}

/// 区域卡片
class _AreaCard extends StatelessWidget {
  final AreaAvailability area;
  final ValueChanged<int> onBookTable;
  final ValueChanged<int> onBookArea;

  const _AreaCard({required this.area, required this.onBookTable, required this.onBookArea});

  @override
  Widget build(BuildContext context) {
    final isRoom = area.area.type == AreaType.privateRoom;
    final freeCount = area.tables.where((t) => t.isFree).length;
    final totalCount = area.tables.length;
    final allOccupied = freeCount == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(isRoom ? CupertinoIcons.house_fill : CupertinoIcons.square_grid_2x2,
                    size: 16, color: AppTheme.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(area.area.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: allOccupied ? AppTheme.danger.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isRoom ? (area.isRoomFree ? '空闲' : '占用') : '空闲 $freeCount/$totalCount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: allOccupied ? AppTheme.danger : AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (isRoom)
              // 包厢：整行展示，预订整个包厢
              Opacity(
                opacity: area.isRoomFree ? 1 : 0.5,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        area.tables.map((t) => '${t.table.name}(${t.table.seats}位)').join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (area.isRoomFree) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => onBookArea(area.area.id!),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('预订包厢'),
                      ),
                    ],
                  ],
                ),
              )
            else
              // 大厅：桌位网格
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: area.tables.map((t) {
                  final disabled = !t.isFree;
                  return GestureDetector(
                    onTap: disabled ? null : () => onBookTable(t.table.id!),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 56),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: disabled ? AppTheme.textTertiary.withOpacity(0.1) : AppTheme.glassBgSoft,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.table.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: disabled ? AppTheme.textTertiary : AppTheme.textPrimary)),
                          const SizedBox(height: 2),
                          Text('${t.table.seats}人',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: disabled ? AppTheme.textTertiary : AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
