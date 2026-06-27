import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/theme.dart';
import 'floor_manage_page.dart';
import 'area_manage_page.dart';
import 'table_manage_page.dart';
import 'slot_manage_page.dart';

/// 设置页
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.read<AppProvider>();
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
      children: [
        const PageHeader(subtitle: '系统管理', title: '设置'),

        const SectionTitle('基础数据'),
        GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _MenuItem(
                icon: CupertinoIcons.building_2_fill,
                color: const Color(0xFFB95C26),
                title: '楼层管理',
                trailing: '${p.floors.length} 个',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FloorManagePage())),
              ),
              _MenuItem(
                icon: CupertinoIcons.square_grid_2x2_fill,
                color: const Color(0xFF2F80ED),
                title: '区域管理',
                trailing: '${p.areas.length} 个',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AreaManagePage())),
              ),
              _MenuItem(
                icon: CupertinoIcons.table_fill,
                color: const Color(0xFF30A75F),
                title: '桌位管理',
                trailing: '${p.tables.length} 个',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TableManagePage())),
              ),
              _MenuItem(
                icon: CupertinoIcons.clock_fill,
                color: const Color(0xFFE69F1C),
                title: '快捷时段',
                trailing: '${p.timeSlots.length} 个',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotManagePage())),
              ),
            ],
          ),
        ),

        const SectionTitle('数据备份'),
        GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _MenuItem(
                icon: CupertinoIcons.arrow_up_doc_fill,
                color: AppTheme.success,
                title: '导出数据',
                subtitle: '保存为 JSON 文件',
                onTap: () => _export(context),
              ),
              _MenuItem(
                icon: CupertinoIcons.arrow_down_doc_fill,
                color: AppTheme.info,
                title: '导入数据',
                subtitle: '从 JSON 文件恢复（覆盖现有）',
                onTap: () => _import(context),
              ),
            ],
          ),
        ),

        const SectionTitle('关于'),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('鑫源大酒店 · 餐饮预订系统', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              SizedBox(height: 6),
              Text('版本 1.0.0', style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
              SizedBox(height: 4),
              Text('纯本地存储 · 无需联网', style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context) async {
    final p = context.read<AppProvider>();
    try {
      final path = await p.exportData();
      if (!context.mounted) return;
      showToast(context, '已导出：$path');
    } catch (e) {
      if (!context.mounted) return;
      showToast(context, '导出失败：$e');
    }
  }

  Future<void> _import(BuildContext context) async {
    final picked = await FilePicker.platform.pickFiles(withData: true, type: FileType.custom, allowedExtensions: ['json']);
    if (picked == null || picked.files.single.bytes == null) return;
    final confirm = await showCupertinoDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('导入数据'),
        content: const Text('将清空当前所有数据并替换为导入数据，确定继续？'),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, child: const Text('取消'), onPressed: () => Navigator.pop(ctx, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('覆盖导入'), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;
    final p = context.read<AppProvider>();
    try {
      final json = String.fromCharCodes(picked.files.single.bytes!);
      final result = await p.importData(json);
      if (!context.mounted) return;
      showToast(context, '已导入：楼层${result.floors} 区域${result.areas} 桌位${result.tables} 预订${result.reservations}');
    } catch (e) {
      if (!context.mounted) return;
      showToast(context, '导入失败：$e');
    }
  }
}

/// 菜单项
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) Text(trailing!, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
          const SizedBox(width: 4),
          const Icon(CupertinoIcons.chevron_right, size: 14, color: AppTheme.textTertiary),
        ],
      ),
    );
  }
}
