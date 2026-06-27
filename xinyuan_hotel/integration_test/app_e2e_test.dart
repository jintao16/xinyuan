import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:xinyuan_hotel/data/models/reservation.dart';
import 'package:xinyuan_hotel/main.dart';
import 'package:xinyuan_hotel/providers/app_provider.dart';

/// E2E 测试套件
///
/// 遵循 e2e-testing-patterns 原则：
/// - 测试用户行为而非实现
/// - 每个测试独立（通过 resetToSeedForTesting 重置数据）
/// - 使用 ValueKey 作为稳定选择器
/// - 覆盖关键用户路径
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('鑫源大酒店 E2E 关键路径', () {
    /// 在每个测试前重置数据库到初始预置数据状态
    Future<void> resetApp(WidgetTester tester) async {
      // 通过 pumpWidget 重新启动应用以获取 provider
      await tester.pumpWidget(const XinyuanApp());
      await tester.pumpAndSettle();
      final provider = tester.element(find.byType(XinyuanApp)).read<AppProvider>();
      await provider.resetToSeedForTesting();
      await tester.pumpAndSettle();
    }

    testWidgets('T1: 应用启动显示首页主标题', (tester) async {
      await resetApp(tester);

      // 验证首页标题
      expect(find.text('鑫源大酒店'), findsOneWidget);
      expect(find.text('今日 · '), findsOneWidget);
      // 底部 Tab 栏可见
      expect(find.text('首页'), findsWidgets);
      expect(find.text('预订'), findsWidgets);
      expect(find.text('查询'), findsWidgets);
      expect(find.text('统计'), findsWidgets);
      expect(find.text('设置'), findsWidgets);
    });

    testWidgets('T2: 预置数据正确加载（2楼层 5区域 12桌位 2时段）', (tester) async {
      await resetApp(tester);
      final provider = tester.element(find.byType(XinyuanApp)).read<AppProvider>();

      expect(provider.floors.length, 2);
      expect(provider.areas.length, 5);
      expect(provider.tables.length, 12);
      expect(provider.timeSlots.length, 2);
      expect(provider.todayReservations.length, 0);
    });

    testWidgets('T3: Tab 栏切换到各页面', (tester) async {
      await resetApp(tester);

      // 切换到「预订」页
      await tester.tap(find.byKey(const ValueKey('tab_1')));
      await tester.pumpAndSettle();
      expect(find.text('新建预订'), findsWidgets);

      // 切换到「查询」页
      await tester.tap(find.byKey(const ValueKey('tab_2')));
      await tester.pumpAndSettle();
      expect(find.text('空闲查询'), findsOneWidget);

      // 切换到「统计」页
      await tester.tap(find.byKey(const ValueKey('tab_3')));
      await tester.pumpAndSettle();
      expect(find.text('统计'), findsWidgets);

      // 切换到「设置」页
      await tester.tap(find.byKey(const ValueKey('tab_4')));
      await tester.pumpAndSettle();
      expect(find.text('系统管理'), findsOneWidget);
      expect(find.text('楼层管理'), findsOneWidget);
      expect(find.text('区域管理'), findsOneWidget);
      expect(find.text('桌位管理'), findsOneWidget);
      expect(find.text('快捷时段'), findsOneWidget);
    });

    testWidgets('T4: 完整预订流程 - 新建大厅桌预订', (tester) async {
      await resetApp(tester);

      // 1. 首页点击「新建预订」
      await tester.tap(find.byKey(const ValueKey('home_btn_new_reservation')));
      await tester.pumpAndSettle();

      // 2. 验证进入表单页
      expect(find.text('新建预订'), findsWidgets);
      expect(find.text('客户称呼'), findsOneWidget);

      // 3. 选择大厅桌位模式（默认即 table 模式，选择第一个空闲桌）
      // 桌位选择器加载需要时间，等待
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 4. 填写客户称呼
      await tester.enterText(
        find.byKey(const ValueKey('form_field_customer_title')),
        '张先生',
      );
      await tester.pumpAndSettle();

      // 5. 点击保存（应成功创建）
      await tester.tap(find.byKey(const ValueKey('form_btn_save')));
      await tester.pumpAndSettle();

      // 6. 验证返回首页，今日预订数+1
      expect(find.text('鑫源大酒店'), findsOneWidget);
      final provider = tester.element(find.byType(XinyuanApp)).read<AppProvider>();
      expect(provider.todayReservations.length, 1);
      expect(provider.todayReservations.first.customerTitle, '张先生');
    });

    testWidgets('T5: 预订列表展示今日预订', (tester) async {
      await resetApp(tester);

      // 先创建一条预订
      // 直接通过 form 创建（验证列表展示而非创建流程本身）
      await tester.tap(find.byKey(const ValueKey('home_btn_new_reservation')));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.enterText(find.byKey(const ValueKey('form_field_customer_title')), '李女士');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('form_btn_save')));
      await tester.pumpAndSettle();

      // 切换到预订列表页
      await tester.tap(find.byKey(const ValueKey('tab_1')));
      await tester.pumpAndSettle();

      // 验证列表显示
      expect(find.text('李女士'), findsOneWidget);
      expect(find.text('已预订'), findsWidgets);
    });

    testWidgets('T6: 空闲查询页正常加载并显示桌位', (tester) async {
      await resetApp(tester);

      // 切换到查询页
      await tester.tap(find.byKey(const ValueKey('tab_2')));
      await tester.pumpAndSettle();

      // 验证显示楼层
      expect(find.text('空闲查询'), findsOneWidget);
      // 等待异步加载
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 验证显示预置的楼层数据
      expect(find.text('二楼 · 主楼'), findsOneWidget);
      // 验证显示区域
      expect(find.text('二楼大厅'), findsOneWidget);
      expect(find.text('VIP1号包厢'), findsOneWidget);
    });

    testWidgets('T7: 统计页正常加载', (tester) async {
      await resetApp(tester);

      // 切换到统计页
      await tester.tap(find.byKey(const ValueKey('tab_3')));
      await tester.pumpAndSettle();

      // 等待异步加载
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 验证显示统计卡片标题
      expect(find.text('预订汇总'), findsOneWidget);
      expect(find.text('到店率'), findsOneWidget);
      expect(find.text('区域占比'), findsOneWidget);
      expect(find.text('时段分布'), findsOneWidget);
      expect(find.text('桌位使用率'), findsOneWidget);
    });

    testWidgets('T8: 设置页进入楼层管理', (tester) async {
      await resetApp(tester);

      // 切换到设置页
      await tester.tap(find.byKey(const ValueKey('tab_4')));
      await tester.pumpAndSettle();

      // 点击「楼层管理」
      await tester.tap(find.text('楼层管理'));
      await tester.pumpAndSettle();

      // 验证显示预置的 2 个楼层
      expect(find.text('楼层管理'), findsWidgets);
      expect(find.text('一楼'), findsOneWidget);
      expect(find.text('二楼'), findsOneWidget);
    });

    testWidgets('T9: 冲突检测 - 同桌同时段不能重复预订', (tester) async {
      await resetApp(tester);
      final provider = tester.element(find.byType(XinyuanApp)).read<AppProvider>();

      // 第一次创建预订（应成功）
      final r1 = await _createTestReservation(
        provider,
        customerTitle: '王先生',
        startTime: '11:00',
        endTime: '13:00',
      );
      expect(r1.$1, true, reason: '首次预订应成功');

      // 同桌同时段第二次创建（应失败-冲突）
      final r2 = await _createTestReservation(
        provider,
        customerTitle: '赵先生',
        startTime: '12:00', // 与 11-13 重叠
        endTime: '14:00',
      );
      expect(r2.$1, false, reason: '冲突的时段应被拒绝');
      expect(r2.$2, contains('已被预订'));
    });

    testWidgets('T10: 状态流转 - 已预订 → 已完成', (tester) async {
      await resetApp(tester);
      final provider = tester.element(find.byType(XinyuanApp)).read<AppProvider>();

      // 创建预订
      final createResult = await _createTestReservation(
        provider,
        customerTitle: '孙先生',
        startTime: '17:00',
        endTime: '19:00',
      );
      expect(createResult.$1, true);
      final reservationId = provider.todayReservations.first.id!;

      // 变更状态为已完成
      await provider.changeReservationStatus(reservationId, ReservationStatus.completed);

      // 验证状态已变更
      expect(provider.todayReservations.first.status, ReservationStatus.completed);
      expect(provider.completedCountToday, 1);
      expect(provider.bookedCountToday, 0);
    });

    testWidgets('T11: 已完成状态不再占用资源（可被重新预订）', (tester) async {
      await resetApp(tester);
      final provider = tester.element(find.byType(XinyuanApp)).read<AppProvider>();

      // 创建并完成一条预订
      final r1 = await _createTestReservation(
        provider,
        customerTitle: '周先生',
        startTime: '11:00',
        endTime: '13:00',
      );
      expect(r1.$1, true);
      final id = provider.todayReservations.first.id!;
      await provider.changeReservationStatus(id, ReservationStatus.completed);

      // 同桌同时段应能再次预订（因前者已完成不占资源）
      final r2 = await _createTestReservation(
        provider,
        customerTitle: '吴先生',
        startTime: '11:00',
        endTime: '13:00',
      );
      expect(r2.$1, true, reason: '已完成预订不占资源，应可重新预订');
    });

    testWidgets('T12: 已取消状态不再占用资源', (tester) async {
      await resetApp(tester);
      final provider = tester.element(find.byType(XinyuanApp)).read<AppProvider>();

      final r1 = await _createTestReservation(
        provider,
        customerTitle: '郑先生',
        startTime: '11:00',
        endTime: '13:00',
      );
      expect(r1.$1, true);
      final id = provider.todayReservations.first.id!;
      await provider.changeReservationStatus(id, ReservationStatus.cancelled);

      final r2 = await _createTestReservation(
        provider,
        customerTitle: '钱先生',
        startTime: '11:00',
        endTime: '13:00',
      );
      expect(r2.$1, true, reason: '已取消预订不占资源');
    });
  });
}

/// 测试辅助：通过 provider 创建大厅桌预订
/// 使用第一个大厅区域的第一张桌
Future<(bool, String)> _createTestReservation(
  AppProvider provider, {
  required String customerTitle,
  required String startTime,
  required String endTime,
}) async {
  final hallArea = provider.areas.firstWhere((a) => a.type.name == 'hall');
  final table = provider.tables.firstWhere((t) => t.areaId == hallArea.id);
  final reservation = Reservation(
    date: DateTime.now().toIso8601String().substring(0, 10),
    startTime: startTime,
    endTime: endTime,
    tableId: table.id,
    customerTitle: customerTitle,
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
  );
  return provider.createReservation(reservation);
}
