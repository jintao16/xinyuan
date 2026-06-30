import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/test_database.dart';
import 'package:xinyuan_hotel/data/database.dart';
import 'package:xinyuan_hotel/data/models/reservation.dart';
import 'package:xinyuan_hotel/main_scaffold.dart';
import 'package:xinyuan_hotel/pages/availability/availability_page.dart';
import 'package:xinyuan_hotel/pages/home/home_page.dart';
import 'package:xinyuan_hotel/pages/reservation/reservation_list_page.dart';
import 'package:xinyuan_hotel/pages/settings/settings_page.dart';
import 'package:xinyuan_hotel/pages/statistics/statistics_page.dart';
import 'package:xinyuan_hotel/providers/app_provider.dart';
import 'package:xinyuan_hotel/widgets/common.dart';
import 'package:xinyuan_hotel/widgets/theme.dart';

/// Widget 层全量测试 - 验证页面渲染、交互、状态显示
void main() {
  setUpAll(() {
    TestDatabaseEnvironment.ensureInitialized();
  });

  late AppProvider provider;

  setUp(() async {
    await DatabaseHelper().deleteDb();
    provider = AppProvider();
    await provider.init();
  });

  tearDown(() async {
    await DatabaseHelper().close();
  });

  // 公共包装：用 provider 包裹被测 widget
  Widget wrap(Widget child) {
    return ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.light,
        home: child,
      ),
    );
  }

  group('HomePage Widget', () {
    testWidgets('渲染 - 标题和统计卡片', (tester) async {
      await tester.pumpWidget(wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('鑫源大酒店'), findsOneWidget);
      expect(find.text('已预订'), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
      expect(find.text('已取消'), findsOneWidget);
    });

    testWidgets('渲染 - 快捷操作按钮', (tester) async {
      await tester.pumpWidget(wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('新建预订'), findsOneWidget);
      expect(find.text('查询空闲'), findsOneWidget);
    });

    testWidgets('渲染 - 无预订时显示今日时段', (tester) async {
      await tester.pumpWidget(wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('今日时段'), findsOneWidget);
    });

    testWidgets('渲染 - 有预订时显示今日全部预订', (tester) async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await provider.reservationDao.create(Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      ));
      await provider.refreshReservations();

      await tester.pumpWidget(wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('今日全部预订'), findsOneWidget);
      expect(find.text('张先生'), findsOneWidget);
    });

    testWidgets('交互 - 点击新建预订跳转', (tester) async {
      await tester.pumpWidget(wrap(const HomePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('新建预订'));
      await tester.pumpAndSettle();
      // 跳转到 ReservationFormPage
      expect(find.text('创建预订'), findsOneWidget);
    });
  });

  group('ReservationListPage Widget', () {
    testWidgets('渲染 - 标题和筛选 pills', (tester) async {
      await tester.pumpWidget(wrap(const ReservationListPage()));
      await tester.pumpAndSettle();

      expect(find.text('预订'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('已预订'), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
      expect(find.text('已取消'), findsOneWidget);
    });

    testWidgets('渲染 - 空状态', (tester) async {
      await tester.pumpWidget(wrap(const ReservationListPage()));
      await tester.pumpAndSettle();

      expect(find.text('该日期暂无预订记录'), findsOneWidget);
    });

    testWidgets('渲染 - 有预订显示卡片', (tester) async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await provider.reservationDao.create(Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: '张先生',
        createdAt: '',
        updatedAt: '',
      ));
      await provider.refreshReservations();

      await tester.pumpWidget(wrap(const ReservationListPage()));
      await tester.pumpAndSettle();

      expect(find.text('张先生'), findsOneWidget);
      expect(find.text('11:00 — 13:00'), findsOneWidget);
    });

    testWidgets('交互 - 切换状态筛选', (tester) async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await provider.reservationDao.create(Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1,
        customerTitle: 'A',
        status: ReservationStatus.booked,
        createdAt: '',
        updatedAt: '',
      ));
      await provider.reservationDao.create(Reservation(
        date: today,
        startTime: '12:00',
        endTime: '14:00',
        tableId: 2,
        customerTitle: 'B',
        status: ReservationStatus.completed,
        createdAt: '',
        updatedAt: '',
      ));
      await provider.refreshReservations();

      await tester.pumpWidget(wrap(const ReservationListPage()));
      await tester.pumpAndSettle();

      // 初始显示全部
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);

      // 点击「已完成」筛选
      await tester.tap(find.text('已完成').last);
      await tester.pumpAndSettle();

      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('AvailabilityPage Widget', () {
    testWidgets('渲染 - 标题和查询表单', (tester) async {
      await tester.pumpWidget(wrap(const AvailabilityPage()));
      await tester.pumpAndSettle();

      expect(find.text('空闲查询'), findsOneWidget);
      expect(find.text('时段'), findsOneWidget);
      expect(find.text('用餐人数（选填）'), findsOneWidget);
      expect(find.text('查询'), findsOneWidget);
    });

    testWidgets('渲染 - 显示楼层和区域', (tester) async {
      await tester.pumpWidget(wrap(const AvailabilityPage()));
      await tester.pumpAndSettle();

      expect(find.text('一楼'), findsOneWidget);
      expect(find.text('二楼 · 主楼'), findsOneWidget);
      expect(find.text('一楼大厅'), findsOneWidget);
      expect(find.text('二楼大厅'), findsOneWidget);
      expect(find.text('VIP1号包厢'), findsOneWidget);
    });

    testWidgets('渲染 - 显示空闲数量', (tester) async {
      await tester.pumpWidget(wrap(const AvailabilityPage()));
      await tester.pumpAndSettle();

      // 一楼大厅 2/2 空闲
      expect(find.text('空闲 2/2'), findsOneWidget);
    });

    testWidgets('渲染 - 包厢显示空闲/占用', (tester) async {
      await tester.pumpWidget(wrap(const AvailabilityPage()));
      await tester.pumpAndSettle();

      // 初始所有包厢都空闲
      expect(find.text('空闲'), findsNWidgets(3)); // 3 个包厢
    });

    testWidgets('渲染 - 桌位预订后显示占用', (tester) async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await provider.reservationDao.create(Reservation(
        date: today,
        startTime: '11:00',
        endTime: '13:00',
        tableId: 1, // A1
        customerTitle: 'A',
        createdAt: '',
        updatedAt: '',
      ));
      await provider.refreshReservations();

      await tester.pumpWidget(wrap(const AvailabilityPage()));
      await tester.pumpAndSettle();

      // A1 被占用，一楼大厅 1/2 空闲
      expect(find.text('空闲 1/2'), findsOneWidget);
    });
  });

  group('StatisticsPage Widget', () {
    testWidgets('渲染 - 标题和周期切换', (tester) async {
      await tester.pumpWidget(wrap(const StatisticsPage()));
      await tester.pumpAndSettle();

      expect(find.text('统计'), findsOneWidget);
      expect(find.text('本周'), findsOneWidget);
      expect(find.text('本月'), findsOneWidget);
    });

    testWidgets('渲染 - 空数据状态', (tester) async {
      await tester.pumpWidget(wrap(const StatisticsPage()));
      await tester.pumpAndSettle();

      expect(find.text('预订汇总'), findsOneWidget);
      expect(find.text('到店率'), findsOneWidget);
    });

    testWidgets('渲染 - 区域占比空数据', (tester) async {
      await tester.pumpWidget(wrap(const StatisticsPage()));
      await tester.pumpAndSettle();

      expect(find.text('区域占比'), findsOneWidget);
      expect(find.text('暂无数据'), findsAtLeast(1));
    });

    testWidgets('交互 - 切换本月', (tester) async {
      await tester.pumpWidget(wrap(const StatisticsPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('本月'));
      await tester.pumpAndSettle();
      // 切换后仍能正常渲染
      expect(find.text('统计'), findsOneWidget);
    });
  });

  group('SettingsPage Widget', () {
    testWidgets('渲染 - 标题和基础数据菜单', (tester) async {
      await tester.pumpWidget(wrap(const SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsOneWidget);
      expect(find.text('基础数据'), findsOneWidget);
      expect(find.text('楼层管理'), findsOneWidget);
      expect(find.text('区域管理'), findsOneWidget);
      expect(find.text('桌位管理'), findsOneWidget);
      expect(find.text('快捷时段'), findsOneWidget);
    });

    testWidgets('渲染 - 数据备份菜单', (tester) async {
      await tester.pumpWidget(wrap(const SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('数据备份'), findsOneWidget);
      expect(find.text('导出数据'), findsOneWidget);
      expect(find.text('导入数据'), findsOneWidget);
    });

    testWidgets('渲染 - 关于信息', (tester) async {
      await tester.pumpWidget(wrap(const SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('关于'), findsOneWidget);
      expect(find.text('鑫源大酒店 · 餐饮预订系统'), findsOneWidget);
      expect(find.text('版本 1.0.0'), findsOneWidget);
    });

    testWidgets('渲染 - 菜单显示数量', (tester) async {
      await tester.pumpWidget(wrap(const SettingsPage()));
      await tester.pumpAndSettle();

      // 楼层数量
      expect(find.text('2 个'), findsOneWidget);
      // 区域数量
      expect(find.text('5 个'), findsOneWidget);
      // 桌位数量
      expect(find.text('12 个'), findsOneWidget);
      // 时段数量
      expect(find.text('2 个'), findsOneWidget);
    });
  });

  group('MainScaffold Widget', () {
    testWidgets('渲染 - 底部 Tab 栏 5 个按钮', (tester) async {
      await tester.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(home: MainScaffold()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('首页'), findsOneWidget);
      expect(find.text('预订'), findsOneWidget);
      expect(find.text('查询'), findsOneWidget);
      expect(find.text('统计'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('交互 - Tab 切换', (tester) async {
      await tester.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(home: MainScaffold()),
      ));
      await tester.pumpAndSettle();

      // 默认在首页
      expect(find.text('鑫源大酒店'), findsOneWidget);

      // 切到统计
      await tester.tap(find.text('统计'));
      await tester.pumpAndSettle();
      expect(find.text('预订汇总'), findsOneWidget);

      // 切到设置
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      expect(find.text('基础数据'), findsOneWidget);
    });
  });

  group('公共组件 Widget', () {
    testWidgets('StatusTag - 各状态显示', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: const [
              StatusTag(status: ReservationStatus.booked),
              StatusTag(status: ReservationStatus.completed),
              StatusTag(status: ReservationStatus.cancelled),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('已预订'), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
      expect(find.text('已取消'), findsOneWidget);
    });

    testWidgets('EmptyState - 显示图标和文字', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmptyState(icon: '📭', text: '测试空状态')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('测试空状态'), findsOneWidget);
      expect(find.text('📭'), findsOneWidget);
    });

    testWidgets('SectionTitle - 显示标题', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SectionTitle('区段标题')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('区段标题'), findsOneWidget);
    });

    testWidgets('FilterPill - 选中态', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FilterPill(
            label: '筛选',
            active: true,
            onTap: () => tapped = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('筛选'), findsOneWidget);
      await tester.tap(find.text('筛选'));
      expect(tapped, true);
    });

    testWidgets('PageHeader - 显示副标题和标题', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PageHeader(subtitle: '副标题', title: '主标题'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('副标题'), findsOneWidget);
      expect(find.text('主标题'), findsOneWidget);
    });
  });

  group('GlassContainer Widget', () {
    testWidgets('渲染子组件', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: GlassContainer(child: Text('玻璃内容')),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('玻璃内容'), findsOneWidget);
    });
  });
}
