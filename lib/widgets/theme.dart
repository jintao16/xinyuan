import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// iOS 26 液态玻璃风格主题
class AppTheme {
  // 主色：金棕系，呼应酒店气质
  static const Color accent = Color(0xFFB95C26);
  static const Color accentSoft = Color(0xFFD4915A);
  static const Color accentDeep = Color(0xFF823C14);

  // 语义色
  static const Color success = Color(0xFF30A75F);
  static const Color warning = Color(0xFFE69F1C);
  static const Color danger = Color(0xFFEB5757);
  static const Color info = Color(0xFF2F80ED);

  // 文字
  static const Color textPrimary = Color(0xFF1C1C24);
  static const Color textSecondary = Color(0xFF5C5C66);
  static const Color textTertiary = Color(0xFF8E8E98);

  // 玻璃
  static Color glassBg = Colors.white.withOpacity(0.55);
  static Color glassBgStrong = Colors.white.withOpacity(0.72);
  static Color glassBgSoft = Colors.white.withOpacity(0.35);
  static Color glassBorder = Colors.white.withOpacity(0.65);

  // 圆角
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
  static const double radiusXl = 28;

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accentSoft,
        surface: const Color(0xFFFAF7F2),
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: glassBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.03, color: textPrimary),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textTertiary),
      ),
    );
  }
}

/// 液态玻璃容器
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? color;
  final double blurStrength;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.blurStrength = 24,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.glassBg,
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusLg),
        border: border ?? Border.all(color: AppTheme.glassBorder),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: const Color(0xFF1F2650).withOpacity(0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF1F2650).withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
          child: child,
        ),
      ),
    );
  }
}
