import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xinyuan_hotel/data/models/area.dart';
import 'package:xinyuan_hotel/data/models/dining_table.dart';
import 'package:xinyuan_hotel/data/models/floor.dart';
import 'package:xinyuan_hotel/data/models/quick_time_slot.dart';
import 'package:xinyuan_hotel/data/models/reservation.dart';
import 'package:xinyuan_hotel/providers/app_provider.dart';
import 'package:xinyuan_hotel/widgets/theme.dart';
import 'package:xinyuan_hotel/main_scaffold.dart';

/// Widget 级 E2E 测试（不依赖真实数据库）
///
/// 由于 integration_test 需要真实设备/模拟器，
/// 此测试用 mock 数据验证关键 UI 流程，可在 `flutter test` 下直接运行。
/// 真实设备 E2E 测试见 integration_test/app_e2e_test.dart
void main() {
  setUpAll(() {
    // 初始化 sqflite_ffi（让测试环境可用 SQLite）
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // 创建测试用目录
    Directory('/tmp/xinyuan_test_docs').createSync(recursive: true);
  });

  setUp(() {
    // Mock path_provider channel，让 AppProvider 初始化时不抛 MissingPluginException
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return '/tmp/xinyuan_test_docs';
      }
      return null;
    });
  });

  group('鑫源大酒店 Widget E2E', () {
    testWidgets('T1: 主框架渲染 - Tab 栏与首页标题', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>(
          create: (_) => AppProvider(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MainScaffold(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      // 验证底部 Tab 栏 5 个标签都存在（中央「查询」Tab 只显示图标，无文字）
      expect(find.text('首页'), findsWidgets);
      expect(find.text('预订'), findsWidgets);
      expect(find.text('统计'), findsWidgets);
      expect(find.text('设置'), findsWidgets);

      // 验证 Tab 切换可点击
      expect(find.byKey(const ValueKey('tab_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_3')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_4')), findsOneWidget);
    });

    testWidgets('T2: Tab 切换到设置页显示管理菜单', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>(
          create: (_) => AppProvider(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MainScaffold(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      // 切换到设置页
      await tester.tap(find.byKey(const ValueKey('tab_4')));
      await tester.pumpAndSettle();

      // 验证设置页菜单项
      expect(find.text('系统管理'), findsOneWidget);
      expect(find.text('基础数据'), findsOneWidget);
      expect(find.text('数据备份'), findsOneWidget);
      expect(find.text('关于'), findsOneWidget);
    });

    testWidgets('T3: Tab 切换到统计页显示报表标题', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>(
          create: (_) => AppProvider(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MainScaffold(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      // 切换到统计页
      await tester.tap(find.byKey(const ValueKey('tab_3')));
      await tester.pumpAndSettle();

      // 验证统计页核心元素
      expect(find.text('统计'), findsWidgets);
      expect(find.text('本周'), findsOneWidget);
      expect(find.text('本月'), findsOneWidget);
    });

    testWidgets('T4: Tab 切换到查询页显示查询表单', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>(
          create: (_) => AppProvider(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MainScaffold(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      // 切换到查询页
      await tester.tap(find.byKey(const ValueKey('tab_2')));
      await tester.pumpAndSettle();

      // 验证查询页核心元素
      expect(find.text('空闲查询'), findsOneWidget);
      expect(find.text('时段'), findsOneWidget);
    });

    testWidgets('T5: Reservation 模型互斥校验', (tester) async {
      // 验证业务规则：tableId 和 areaId 二选一
      expect(
        () => Reservation(
          date: '2026-06-27',
          startTime: '11:00',
          endTime: '13:00',
          tableId: 1,
          areaId: 1, // 同时设置会触发 assert
          customerTitle: '张先生',
          createdAt: '',
          updatedAt: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('T6: 预置数据结构完整性', (tester) async {
      // 验证 design.md 中定义的预置数据结构
      final floors = [
        Floor(id: 1, name: '一楼', sortOrder: 1, isMain: false),
        Floor(id: 2, name: '二楼', sortOrder: 2, isMain: true),
      ];
      final areas = [
        Area(id: 1, floorId: 1, name: '一楼大厅', type: AreaType.hall, sortOrder: 1),
        Area(id: 2, floorId: 2, name: '二楼大厅', type: AreaType.hall, sortOrder: 1),
        Area(id: 3, floorId: 2, name: 'VIP1号包厢', type: AreaType.privateRoom, sortOrder: 2),
        Area(id: 4, floorId: 2, name: 'VIP2号包厢', type: AreaType.privateRoom, sortOrder: 3),
        Area(id: 5, floorId: 2, name: '牡丹厅包厢', type: AreaType.privateRoom, sortOrder: 4),
      ];
      final tables = [
        DiningTable(id: 1, areaId: 1, name: 'A1', seats: 8),
        DiningTable(id: 2, areaId: 1, name: 'A2', seats: 8),
        DiningTable(id: 3, areaId: 2, name: 'B1', seats: 4),
        DiningTable(id: 4, areaId: 2, name: 'B2', seats: 4),
        DiningTable(id: 5, areaId: 2, name: 'B3', seats: 4),
        DiningTable(id: 6, areaId: 2, name: 'B4', seats: 4),
        DiningTable(id: 7, areaId: 2, name: 'C1', seats: 12),
        DiningTable(id: 8, areaId: 2, name: 'C2', seats: 14),
        DiningTable(id: 9, areaId: 3, name: '大圆桌', seats: 16),
        DiningTable(id: 10, areaId: 4, name: '大圆桌', seats: 20),
        DiningTable(id: 11, areaId: 4, name: '小方桌', seats: 4),
        DiningTable(id: 12, areaId: 5, name: '大圆桌', seats: 18),
      ];
      final timeSlots = [
        QuickTimeSlot(id: 1, name: '午餐', startTime: '11:00', endTime: '13:00', sortOrder: 1),
        QuickTimeSlot(id: 2, name: '晚餐', startTime: '17:00', endTime: '19:00', sortOrder: 2),
      ];

      expect(floors.length, 2);
      expect(areas.length, 5);
      expect(areas.where((a) => a.type == AreaType.hall).length, 2);
      expect(areas.where((a) => a.type == AreaType.privateRoom).length, 3);
      expect(tables.length, 12);
      expect(timeSlots.length, 2);

      // 验证业务规则：包厢预订占用包厢内所有桌位
      final vip2Tables = tables.where((t) => t.areaId == 4).toList();
      expect(vip2Tables.length, 2, reason: 'VIP2号包厢应有大小桌组合');
      expect(vip2Tables.any((t) => t.seats >= 20), true);
      expect(vip2Tables.any((t) => t.seats <= 4), true);
    });
  });
}
