import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/quick_time_slot.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/theme.dart';

/// 快捷时段管理页
class SlotManagePage extends StatefulWidget {
  const SlotManagePage({super.key});

  @override
  State<SlotManagePage> createState() => _SlotManagePageState();
}

class _SlotManagePageState extends State<SlotManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('快捷时段')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, null),
        backgroundColor: AppTheme.accent,
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      body: Consumer<AppProvider>(
        builder: (context, p, _) {
          if (p.timeSlots.isEmpty) {
            return const EmptyState(icon: '⏰', text: '暂无快捷时段，点击右下角添加');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: p.timeSlots.length,
            itemBuilder: (context, i) {
              final s = p.timeSlots[i];
              return _SlotTile(
                slot: s,
                onEdit: () => _edit(context, s),
                onDelete: () => _delete(context, s),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, QuickTimeSlot? slot) async {
    final isEdit = slot != null;
    final nameCtl = TextEditingController(text: slot?.name ?? '');
    final startCtl = TextEditingController(text: slot?.startTime ?? '11:00');
    final endCtl = TextEditingController(text: slot?.endTime ?? '13:00');
    final sortCtl = TextEditingController(text: (slot?.sortOrder ?? 0).toString());

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? '编辑时段' : '新增时段',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            const Text('名称', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextField(controller: nameCtl, decoration: const InputDecoration(hintText: '如：午餐')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _TimeField(controller: startCtl, label: '开始')),
                const SizedBox(width: 10),
                Expanded(child: _TimeField(controller: endCtl, label: '结束')),
              ],
            ),
            const SizedBox(height: 12),
            const Text('排序', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextField(controller: sortCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '0')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存'))),
              ],
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final name = nameCtl.text.trim();
    if (name.isEmpty) {
      if (!context.mounted) return;
      showToast(context, '请填写名称');
      return;
    }
    final start = startCtl.text.trim();
    final end = endCtl.text.trim();
    final sort = int.tryParse(sortCtl.text.trim()) ?? 0;
    final p = context.read<AppProvider>();
    if (isEdit && slot != null) {
      await p.updateTimeSlot(slot.copyWith(name: name, startTime: start, endTime: end, sortOrder: sort));
    } else {
      await p.createTimeSlot(QuickTimeSlot(name: name, startTime: start, endTime: end, sortOrder: sort));
    }
    if (!context.mounted) return;
    showToast(context, '已保存');
  }

  Future<void> _delete(BuildContext context, QuickTimeSlot slot) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除时段'),
        content: Text('确定删除「${slot.name}」？'),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, child: const Text('取消'), onPressed: () => Navigator.pop(ctx, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('删除'), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (ok != true) return;
    final p = context.read<AppProvider>();
    await p.deleteTimeSlot(slot.id!);
    if (!context.mounted) return;
    showToast(context, '已删除');
  }
}

/// 时间输入字段（HH:mm）
class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _TimeField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(CupertinoIcons.clock, size: 18),
            isDense: true,
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final initial = controller.text.isNotEmpty ? controller.text : '11:00';
    final parts = initial.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 11, minute: int.tryParse(parts[1]) ?? 0),
    );
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      controller.text = '$hh:$mm';
    }
  }
}

class _SlotTile extends StatelessWidget {
  final QuickTimeSlot slot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SlotTile({required this.slot, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(CupertinoIcons.clock_fill, size: 18, color: AppTheme.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(slot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  Text('${slot.startTime} — ${slot.endTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            IconButton(icon: const Icon(CupertinoIcons.pencil, size: 18), onPressed: onEdit),
            IconButton(icon: const Icon(CupertinoIcons.delete, size: 18, color: AppTheme.danger), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
