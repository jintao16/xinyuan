import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/dining_table.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/theme.dart';

/// 桌位管理页
class TableManagePage extends StatefulWidget {
  const TableManagePage({super.key});

  @override
  State<TableManagePage> createState() => _TableManagePageState();
}

class _TableManagePageState extends State<TableManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('桌位管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, null),
        backgroundColor: AppTheme.accent,
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      body: Consumer<AppProvider>(
        builder: (context, p, _) {
          if (p.tables.isEmpty) {
            return const EmptyState(icon: '🍽️', text: '暂无桌位，点击右下角添加');
          }
          // 按区域分组
          final groups = <int, List<DiningTable>>{};
          for (final t in p.tables) {
            groups.putIfAbsent(t.areaId, () => []).add(t);
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final entry in groups.entries) ...[
                () {
                  final area = p.areas.where((a) => a.id == entry.key).firstOrNull;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text('${area?.name ?? '-'}（${entry.value.length}）',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                  );
                }(),
                for (final t in entry.value)
                  _TableTile(
                    table: t,
                    onEdit: () => _edit(context, t),
                    onDelete: () => _delete(context, t),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, DiningTable? table) async {
    final isEdit = table != null;
    final p = context.read<AppProvider>();
    if (p.areas.isEmpty) {
      showToast(context, '请先创建区域');
      return;
    }
    int selectedAreaId = table?.areaId ?? p.areas.first.id!;
    final nameCtl = TextEditingController(text: table?.name ?? '');
    final seatsCtl = TextEditingController(text: (table?.seats ?? 4).toString());
    final sortCtl = TextEditingController(text: (table?.sortOrder ?? 0).toString());

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? '编辑桌位' : '新增桌位',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                const Text('所属区域', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedAreaId,
                  decoration: const InputDecoration(isDense: true),
                  items: p.areas.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name}（${a.type.label}）'))).toList(),
                  onChanged: (v) => setS(() => selectedAreaId = v ?? selectedAreaId),
                ),
                const SizedBox(height: 12),
                const Text('桌名', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextField(controller: nameCtl, decoration: const InputDecoration(hintText: '如：A1')),
                const SizedBox(height: 12),
                const Text('座位数', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextField(controller: seatsCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '4')),
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
          );
        },
      ),
    );

    if (saved != true) return;
    final name = nameCtl.text.trim();
    if (name.isEmpty) {
      if (!context.mounted) return;
      showToast(context, '请填写桌名');
      return;
    }
    final seats = int.tryParse(seatsCtl.text.trim()) ?? 0;
    if (seats <= 0) {
      if (!context.mounted) return;
      showToast(context, '座位数必须大于 0');
      return;
    }
    final sort = int.tryParse(sortCtl.text.trim()) ?? 0;
    if (isEdit && table != null) {
      await p.updateTable(table.copyWith(areaId: selectedAreaId, name: name, seats: seats, sortOrder: sort));
    } else {
      await p.createTable(DiningTable(areaId: selectedAreaId, name: name, seats: seats, sortOrder: sort));
    }
    if (!context.mounted) return;
    showToast(context, '已保存');
  }

  Future<void> _delete(BuildContext context, DiningTable table) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除桌位'),
        content: Text('确定删除「${table.name}」？'),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, child: const Text('取消'), onPressed: () => Navigator.pop(ctx, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('删除'), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (ok != true) return;
    final p = context.read<AppProvider>();
    await p.deleteTable(table.id!);
    if (!context.mounted) return;
    showToast(context, '已删除');
  }
}

class _TableTile extends StatelessWidget {
  final DiningTable table;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TableTile({required this.table, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(CupertinoIcons.table_fill, size: 18, color: AppTheme.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(table.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  Text('${table.seats}人',
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
