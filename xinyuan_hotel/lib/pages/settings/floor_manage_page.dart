import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/floor.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/theme.dart';

/// 楼层管理页
class FloorManagePage extends StatefulWidget {
  const FloorManagePage({super.key});

  @override
  State<FloorManagePage> createState() => _FloorManagePageState();
}

class _FloorManagePageState extends State<FloorManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('楼层管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, null),
        backgroundColor: AppTheme.accent,
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      body: Consumer<AppProvider>(
        builder: (context, p, _) {
          if (p.floors.isEmpty) {
            return const EmptyState(icon: '🏢', text: '暂无楼层，点击右下角添加');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: p.floors.length,
            itemBuilder: (context, i) {
              final f = p.floors[i];
              return _FloorTile(
                floor: f,
                index: i + 1,
                onEdit: () => _edit(context, f),
                onDelete: () => _delete(context, f),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, Floor? floor) async {
    final isEdit = floor != null;
    final nameCtl = TextEditingController(text: floor?.name ?? '');
    final sortCtl = TextEditingController(text: (floor?.sortOrder ?? 0).toString());
    bool isMain = floor?.isMain ?? false;

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
                Text(isEdit ? '编辑楼层' : '新增楼层',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                const Text('名称', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextField(controller: nameCtl, decoration: const InputDecoration(hintText: '如：一楼')),
                const SizedBox(height: 12),
                const Text('排序', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextField(controller: sortCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '0')),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('主楼', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: isMain,
                  onChanged: (v) => setS(() => isMain = v),
                ),
                const SizedBox(height: 8),
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
      // ignore: use_build_context_synchronously
      showToast(context, '请填写名称');
      return;
    }
    final sort = int.tryParse(sortCtl.text.trim()) ?? 0;
    final p = context.read<AppProvider>();
    if (isEdit && floor != null) {
      await p.updateFloor(floor.copyWith(name: name, sortOrder: sort, isMain: isMain));
    } else {
      await p.createFloor(Floor(name: name, sortOrder: sort, isMain: isMain));
    }
    if (!context.mounted) return;
    showToast(context, '已保存');
  }

  Future<void> _delete(BuildContext context, Floor floor) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除楼层'),
        content: Text('确定删除「${floor.name}」？'),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, child: const Text('取消'), onPressed: () => Navigator.pop(ctx, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('删除'), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (ok != true) return;
    final p = context.read<AppProvider>();
    final (s, msg) = await p.deleteFloor(floor.id!);
    if (!context.mounted) return;
    showToast(context, msg);
  }
}

class _FloorTile extends StatelessWidget {
  final Floor floor;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FloorTile({required this.floor, required this.index, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text('$index', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.accent))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(floor.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  if (floor.isMain)
                    const Text('主楼', style: TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            IconButton(icon: const Icon(CupertinoIcons.pencil, size: 16), onPressed: onEdit),
            IconButton(icon: const Icon(CupertinoIcons.delete, size: 16, color: AppTheme.danger), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
