import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/area.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/theme.dart';

/// 区域管理页
class AreaManagePage extends StatefulWidget {
  const AreaManagePage({super.key});

  @override
  State<AreaManagePage> createState() => _AreaManagePageState();
}

class _AreaManagePageState extends State<AreaManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('区域管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, null),
        backgroundColor: AppTheme.accent,
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      body: Consumer<AppProvider>(
        builder: (context, p, _) {
          if (p.areas.isEmpty) {
            return const EmptyState(icon: '🏬', text: '暂无区域，点击右下角添加');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: p.areas.length,
            itemBuilder: (context, i) {
              final a = p.areas[i];
              final floor = p.floors.where((f) => f.id == a.floorId).firstOrNull;
              return _AreaTile(
                area: a,
                floorName: floor?.name ?? '-',
                onEdit: () => _edit(context, a),
                onDelete: () => _delete(context, a),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, Area? area) async {
    final isEdit = area != null;
    final p = context.read<AppProvider>();
    if (p.floors.isEmpty) {
      showToast(context, '请先创建楼层');
      return;
    }
    int selectedFloorId = area?.floorId ?? p.floors.first.id!;
    String selectedType = area?.type.dbValue ?? AreaType.hall.dbValue;
    final nameCtl = TextEditingController(text: area?.name ?? '');
    final sortCtl = TextEditingController(text: (area?.sortOrder ?? 0).toString());

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
                Text(isEdit ? '编辑区域' : '新增区域',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                const Text('所属楼层', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedFloorId,
                  decoration: const InputDecoration(isDense: true),
                  items: p.floors.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                  onChanged: (v) => setS(() => selectedFloorId = v ?? selectedFloorId),
                ),
                const SizedBox(height: 12),
                const Text('类型', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'hall', child: Text('大厅')),
                    DropdownMenuItem(value: 'private_room', child: Text('包厢')),
                  ],
                  onChanged: (v) => setS(() => selectedType = v ?? selectedType),
                ),
                const SizedBox(height: 12),
                const Text('名称', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextField(controller: nameCtl, decoration: const InputDecoration(hintText: '如：一楼大厅')),
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
      showToast(context, '请填写名称');
      return;
    }
    final sort = int.tryParse(sortCtl.text.trim()) ?? 0;
    final type = AreaType.fromDb(selectedType);
    if (isEdit && area != null) {
      await p.updateArea(area.copyWith(floorId: selectedFloorId, name: name, type: type, sortOrder: sort));
    } else {
      await p.createArea(Area(floorId: selectedFloorId, name: name, type: type, sortOrder: sort));
    }
    if (!context.mounted) return;
    showToast(context, '已保存');
  }

  Future<void> _delete(BuildContext context, Area area) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除区域'),
        content: Text('确定删除「${area.name}」？'),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, child: const Text('取消'), onPressed: () => Navigator.pop(ctx, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('删除'), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (ok != true) return;
    final p = context.read<AppProvider>();
    final (s, msg) = await p.deleteArea(area.id!);
    if (!context.mounted) return;
    showToast(context, msg);
  }
}

class _AreaTile extends StatelessWidget {
  final Area area;
  final String floorName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AreaTile({required this.area, required this.floorName, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isRoom = area.type == AreaType.privateRoom;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isRoom ? const Color(0xFF78B4C8) : AppTheme.accent).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(isRoom ? CupertinoIcons.house_fill : CupertinoIcons.square_grid_2x2,
                  size: 18, color: isRoom ? const Color(0xFF78B4C8) : AppTheme.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(area.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  Text('$floorName · ${area.type.label}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
