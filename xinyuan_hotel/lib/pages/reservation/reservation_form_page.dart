import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/area.dart';
import '../../data/models/dining_table.dart';
import '../../data/models/reservation.dart';
import '../../providers/app_provider.dart';
import '../../services/availability_service.dart';
import '../../utils/time_util.dart';
import '../../widgets/common.dart';
import '../../widgets/theme.dart';

/// 预订表单页（新建/编辑）
class ReservationFormPage extends StatefulWidget {
  final int? editId; // 编辑时传 id
  const ReservationFormPage({super.key, this.editId});

  @override
  State<ReservationFormPage> createState() => _ReservationFormPageState();
}

class _ReservationFormPageState extends State<ReservationFormPage> {
  final _formKey = GlobalKey<FormState>();

  // 表单字段
  String _date = '';
  String _startTime = '11:00';
  String _endTime = '13:00';
  String _customerTitle = '';
  String _customerPhone = '';
  String _remark = '';
  int? _guestCount;

  // 资源选择：tableId / areaId 二选一
  // _mode: 'table' = 大厅桌预订, 'room' = 包厢预订
  String _mode = 'table';
  int? _selectedTableId;
  int? _selectedAreaId;

  bool _loading = true;
  bool _saving = false;
  Reservation? _editing;

  @override
  void initState() {
    super.initState();
    _date = TimeUtil.today();
    if (widget.editId != null) {
      _loadEditing();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadEditing() async {
    final provider = context.read<AppProvider>();
    final r = await provider.reservationDao.getById(widget.editId!);
    if (r != null && mounted) {
      setState(() {
        _editing = r;
        _date = r.date;
        _startTime = r.startTime;
        _endTime = r.endTime;
        _customerTitle = r.customerTitle;
        _customerPhone = r.customerPhone;
        _remark = r.remark;
        _guestCount = r.guestCount;
        if (r.tableId != null) {
          _mode = 'table';
          _selectedTableId = r.tableId;
        } else if (r.areaId != null) {
          _mode = 'room';
          _selectedAreaId = r.areaId;
        }
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    }
    final isEdit = _editing != null;
    // 终态不可编辑资源/时间/客户
    final isTerminal = _editing != null &&
        (_editing!.status == ReservationStatus.completed ||
            _editing!.status == ReservationStatus.cancelled);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '预订详情' : '新建预订'),
        actions: [
          if (isEdit && !isTerminal)
            TextButton(
              onPressed: _saving ? null : _onDelete,
              child: const Text('删除', style: TextStyle(color: AppTheme.danger)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // 日期
            _FieldLabel('日期'),
            GestureDetector(
              onTap: isTerminal ? null : () => _pickDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(prefixIcon: Icon(CupertinoIcons.calendar, size: 18)),
                  controller: TextEditingController(text: TimeUtil.formatDateZh(_date)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 时间
            _FieldLabel('时段'),
            Row(
              children: [
                Expanded(child: _TimePickerField(label: '开始', value: _startTime, onChanged: isTerminal ? null : (v) => setState(() => _startTime = v))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('—')),
                Expanded(child: _TimePickerField(label: '结束', value: _endTime, onChanged: isTerminal ? null : (v) => setState(() => _endTime = v))),
              ],
            ),

            // 快捷时段
            const SizedBox(height: 8),
            Consumer<AppProvider>(
              builder: (context, p, _) {
                if (p.timeSlots.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final s in p.timeSlots) ...[
                        FilterPill(
                          label: '${s.name} ${s.startTime}-${s.endTime}',
                          active: _startTime == s.startTime && _endTime == s.endTime,
                          onTap: isTerminal
                              ? null
                              : () => setState(() {
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

            const SizedBox(height: 16),

            // 模式切换：大厅桌 / 包厢
            if (!isTerminal)
              _FieldLabel('预订类型')
            else
              _FieldLabel('预订资源（终态不可改）'),
            if (!isTerminal)
              Row(
                children: [
                  Expanded(
                    child: _ModeTab(
                      label: '大厅桌位',
                      icon: CupertinoIcons.square_grid_2x2,
                      active: _mode == 'table',
                      onTap: () => setState(() {
                        _mode = 'table';
                        _selectedAreaId = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ModeTab(
                      label: '包厢整体',
                      icon: CupertinoIcons.house,
                      active: _mode == 'room',
                      onTap: () => setState(() {
                        _mode = 'room';
                        _selectedTableId = null;
                      }),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // 资源选择
            if (_mode == 'table')
              _TableSelector(
                selectedTableId: _selectedTableId,
                date: _date,
                startTime: _startTime,
                endTime: _endTime,
                guestCount: _guestCount,
                enabled: !isTerminal,
                onSelect: (id) => setState(() => _selectedTableId = id),
              )
            else
              _RoomSelector(
                selectedAreaId: _selectedAreaId,
                date: _date,
                startTime: _startTime,
                endTime: _endTime,
                enabled: !isTerminal,
                onSelect: (id) => setState(() => _selectedAreaId = id),
              ),

            const SizedBox(height: 16),

            // 客户信息
            _FieldLabel('客户称呼'),
            TextFormField(
              initialValue: _customerTitle,
              enabled: !isTerminal,
              decoration: const InputDecoration(hintText: '如：张先生、李女士'),
              onChanged: (v) => _customerTitle = v,
            ),

            const SizedBox(height: 12),
            _FieldLabel('联系电话（选填）'),
            TextFormField(
              initialValue: _customerPhone,
              enabled: !isTerminal,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '手机号'),
              onChanged: (v) => _customerPhone = v,
            ),

            const SizedBox(height: 12),
            _FieldLabel('用餐人数（选填）'),
            TextFormField(
              initialValue: _guestCount?.toString() ?? '',
              enabled: !isTerminal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '人数'),
              onChanged: (v) => _guestCount = int.tryParse(v),
            ),

            const SizedBox(height: 12),
            _FieldLabel('备注（选填）'),
            TextFormField(
              initialValue: _remark,
              enabled: !isTerminal,
              maxLines: 2,
              decoration: const InputDecoration(hintText: '特殊要求等'),
              onChanged: (v) => _remark = v,
            ),

            const SizedBox(height: 24),

            // 状态变更按钮（仅编辑态）
            if (isEdit) ...[
              if (_editing!.status == ReservationStatus.booked) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : () => _changeStatus(ReservationStatus.completed),
                        icon: const Icon(CupertinoIcons.checkmark_alt, size: 18, color: AppTheme.success),
                        label: const Text('标记完成', style: TextStyle(color: AppTheme.success)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : () => _changeStatus(ReservationStatus.cancelled),
                        icon: const Icon(CupertinoIcons.xmark, size: 18, color: AppTheme.danger),
                        label: const Text('取消预订', style: TextStyle(color: AppTheme.danger)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (_editing!.status != ReservationStatus.booked)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => _changeStatus(ReservationStatus.booked),
                    icon: const Icon(CupertinoIcons.arrow_uturn_left, size: 18),
                    label: const Text('恢复为已预订'),
                  ),
                ),
              const SizedBox(height: 12),
            ],

            // 保存按钮
            if (!isTerminal)
              ElevatedButton(
                onPressed: _saving ? null : _onSave,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CupertinoActivityIndicator())
                    : Text(isEdit ? '保存修改' : '创建预订'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = TimeUtil.formatDate(picked));
  }

  Future<void> _onSave() async {
    // 基础校验
    if (_customerTitle.trim().isEmpty) {
      showToast(context, '请填写客户称呼');
      return;
    }
    if (_mode == 'table' && _selectedTableId == null) {
      showToast(context, '请选择大厅桌位');
      return;
    }
    if (_mode == 'room' && _selectedAreaId == null) {
      showToast(context, '请选择包厢');
      return;
    }
    if (!TimeUtil.overlap(_startTime, _endTime, _startTime, _endTime) &&
        TimeUtil.toMinutes(_startTime) >= TimeUtil.toMinutes(_endTime)) {
      showToast(context, '开始时间需早于结束时间');
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<AppProvider>();

    final reservation = Reservation(
      id: _editing?.id,
      date: _date,
      startTime: _startTime,
      endTime: _endTime,
      tableId: _mode == 'table' ? _selectedTableId : null,
      areaId: _mode == 'room' ? _selectedAreaId : null,
      customerTitle: _customerTitle.trim(),
      customerPhone: _customerPhone.trim(),
      guestCount: _guestCount,
      status: _editing?.status ?? ReservationStatus.booked,
      remark: _remark.trim(),
      createdAt: _editing?.createdAt ?? TimeUtil.nowIso(),
      updatedAt: TimeUtil.nowIso(),
    );

    final (ok, msg) = _editing == null
        ? await provider.createReservation(reservation)
        : await provider.updateReservation(reservation);

    if (!mounted) return;
    setState(() => _saving = false);
    showToast(context, msg);
    if (ok) Navigator.pop(context);
  }

  Future<void> _changeStatus(ReservationStatus status) async {
    if (_editing == null) return;
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    await provider.changeReservationStatus(_editing!.id!, status);
    if (!mounted) return;
    setState(() => _saving = false);
    showToast(context, status == ReservationStatus.completed ? '已标记完成' : status == ReservationStatus.cancelled ? '已取消' : '已恢复');
    Navigator.pop(context);
  }

  Future<void> _onDelete() async {
    if (_editing == null) return;
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除预订'),
        content: const Text('确定删除此预订记录？此操作不可撤销。'),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, child: const Text('取消'), onPressed: () => Navigator.pop(ctx, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('删除'), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    await context.read<AppProvider>().deleteReservation(_editing!.id!);
    if (!mounted) return;
    showToast(context, '已删除');
    Navigator.pop(context);
  }
}

/// 字段标签
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
    );
  }
}

/// 模式切换 Tab
class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: active ? AppTheme.accent.withOpacity(0.1) : AppTheme.glassBgSoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: active ? AppTheme.accent : AppTheme.glassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? AppTheme.accent : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: active ? AppTheme.accent : AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}

/// 时间选择字段
class _TimePickerField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String>? onChanged;
  const _TimePickerField({required this.label, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => _pick(context),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(CupertinoIcons.clock, size: 18),
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
      onChanged!('$hh:$mm');
    }
  }
}

/// 大厅桌位选择器
class _TableSelector extends StatefulWidget {
  final int? selectedTableId;
  final String date;
  final String startTime;
  final String endTime;
  final int? guestCount;
  final bool enabled;
  final ValueChanged<int> onSelect;

  const _TableSelector({
    required this.selectedTableId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.guestCount,
    required this.enabled,
    required this.onSelect,
  });

  @override
  State<_TableSelector> createState() => _TableSelectorState();
}

class _TableSelectorState extends State<_TableSelector> {
  List<FloorAvailability> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _TableSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.startTime != widget.startTime ||
        oldWidget.endTime != widget.endTime) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final provider = context.read<AppProvider>();
    final data = await provider.availabilityService.query(
      date: widget.date,
      startTime: widget.startTime,
      endTime: widget.endTime,
      guestCount: widget.guestCount,
    );
    if (mounted) setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(20), child: Center(child: CupertinoActivityIndicator()));
    }
    // 仅显示大厅区域
    final hallAreas = <AreaAvailability>[];
    for (final f in _data) {
      for (final a in f.areas) {
        if (a.area.type == AreaType.hall) hallAreas.add(a);
      }
    }
    if (hallAreas.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: Text('暂无大厅桌位数据', style: TextStyle(color: AppTheme.textTertiary)));
    }
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final a in hallAreas) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4, bottom: 6),
              child: Text('${a.area.name}（空闲 ${a.tables.where((t) => t.isFree).length}/${a.tables.length}）',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: a.tables.map((t) {
                final selected = t.table.id == widget.selectedTableId;
                final disabled = !t.isFree || !widget.enabled;
                return GestureDetector(
                  onTap: disabled ? null : () => widget.onSelect(t.table.id!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accent
                          : disabled
                              ? AppTheme.textTertiary.withOpacity(0.1)
                              : AppTheme.glassBgSoft,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: selected ? AppTheme.accent : AppTheme.glassBorder,
                      ),
                    ),
                    child: Text(
                      '${t.table.name}\n${t.table.seats}人',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : (disabled ? AppTheme.textTertiary : AppTheme.textPrimary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// 包厢选择器
class _RoomSelector extends StatefulWidget {
  final int? selectedAreaId;
  final String date;
  final String startTime;
  final String endTime;
  final bool enabled;
  final ValueChanged<int> onSelect;

  const _RoomSelector({
    required this.selectedAreaId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.enabled,
    required this.onSelect,
  });

  @override
  State<_RoomSelector> createState() => _RoomSelectorState();
}

class _RoomSelectorState extends State<_RoomSelector> {
  List<FloorAvailability> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _RoomSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.startTime != widget.startTime ||
        oldWidget.endTime != widget.endTime) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final provider = context.read<AppProvider>();
    final data = await provider.availabilityService.query(
      date: widget.date,
      startTime: widget.startTime,
      endTime: widget.endTime,
    );
    if (mounted) setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(20), child: Center(child: CupertinoActivityIndicator()));
    }
    final roomAreas = <AreaAvailability>[];
    for (final f in _data) {
      for (final a in f.areas) {
        if (a.area.type == AreaType.privateRoom) roomAreas.add(a);
      }
    }
    if (roomAreas.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: Text('暂无包厢数据', style: TextStyle(color: AppTheme.textTertiary)));
    }
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final a in roomAreas) ...[
            () {
              final selected = a.area.id == widget.selectedAreaId;
              final disabled = !a.isRoomFree || !widget.enabled;
              final seatsSum = a.tables.fold(0, (s, t) => s + t.table.seats);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: disabled ? null : () => widget.onSelect(a.area.id!),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accent
                          : disabled
                              ? AppTheme.textTertiary.withOpacity(0.1)
                              : AppTheme.glassBgSoft,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: selected ? AppTheme.accent : AppTheme.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.house_fill, size: 20,
                            color: selected ? Colors.white : (disabled ? AppTheme.textTertiary : AppTheme.accent)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.area.name,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                      color: selected ? Colors.white : (disabled ? AppTheme.textTertiary : AppTheme.textPrimary))),
                              Text('${a.tables.length}桌 · 共${seatsSum}位',
                                  style: TextStyle(fontSize: 12,
                                      color: selected ? Colors.white.withOpacity(0.85) : AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        if (disabled && !a.isRoomFree)
                          const Text('占用', style: TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              );
            }(),
          ],
        ],
      ),
    );
  }
}
