import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'widgets/theme.dart';
import 'pages/home/home_page.dart';
import 'pages/reservation/reservation_list_page.dart';
import 'pages/availability/availability_page.dart';
import 'pages/statistics/statistics_page.dart';
import 'pages/settings/settings_page.dart';

/// 主框架：环境背景 + 页面切换 + 底部浮动 Tab 栏
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final pages = const [
    HomePage(),
    ReservationListPage(),
    AvailabilityPage(),
    StatisticsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 环境背景（液态玻璃反射源）
          const _AmbientBackground(),

          // 2. 内容区域
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: IndexedStack(index: _currentIndex, children: pages),
              ),
            ),
          ),

          // 3. 底部浮动 Tab 栏
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: _GlassTabBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}

/// 环境背景：三个渐变光斑 + 噪点纹理
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 渐变底色
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF5F3EF),
                Color(0xFFFAF7F2),
                Color(0xFFF0EBE3),
              ],
            ),
          ),
        ),
        // 光斑 1 - 金棕色
        Positioned(
          top: -80,
          right: -60,
          child: _Blob(
            size: 320,
            colors: [const Color(0xFFD4915A).withOpacity(0.7), Colors.transparent],
          ),
        ),
        // 光斑 2 - 紫色
        Positioned(
          bottom: 100,
          left: -80,
          child: _Blob(
            size: 280,
            colors: [const Color(0xFFB48CC8).withOpacity(0.5), Colors.transparent],
          ),
        ),
        // 光斑 3 - 蓝绿色
        Positioned(
          top: 40,
          right: 30,
          child: _Blob(
            size: 240,
            colors: [const Color(0xFF78B4C8).withOpacity(0.4), Colors.transparent],
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final List<Color> colors;
  const _Blob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: const SizedBox(),
      ),
    );
  }
}

/// 底部浮动液态玻璃 Tab 栏
class _GlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassTabBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _TabItem(icon: CupertinoIcons.house_fill, label: '首页', isActive: currentIndex == 0),
      _TabItem(icon: CupertinoIcons.calendar, label: '预订', isActive: currentIndex == 1),
      _TabItem(icon: CupertinoIcons.search_circle_fill, label: '查询', isCenter: true, isActive: currentIndex == 2),
      _TabItem(icon: CupertinoIcons.chart_bar_alt_fill, label: '统计', isActive: currentIndex == 3),
      _TabItem(icon: CupertinoIcons.settings_solid, label: '设置', isActive: currentIndex == 4),
    ];

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1F2650).withOpacity(0.18), blurRadius: 40, offset: const Offset(0, 12)),
          BoxShadow(color: const Color(0xFF1F2650).withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              return Expanded(
                child: GestureDetector(
                  key: ValueKey('tab_$i'),
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: items[i],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isCenter;

  const _TabItem({required this.icon, required this.label, this.isActive = false, this.isCenter = false});

  @override
  Widget build(BuildContext context) {
    if (isCenter) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -12),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.accent, AppTheme.accentDeep],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: isActive ? AppTheme.accent : AppTheme.textTertiary),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? AppTheme.accent : AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }
}
