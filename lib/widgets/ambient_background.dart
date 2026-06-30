import 'package:flutter/material.dart';

/// 环境背景：三个渐变光斑 + 噪点纹理
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

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
        gradient: RadialGradient(
          colors: colors,
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }
}
