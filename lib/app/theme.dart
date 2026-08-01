import 'package:flutter/material.dart';

/// アプリのライト/ダークテーマ。
///
/// §15.4:
/// - 高コントラスト配色 (通常テキスト コントラスト比 ≥ 4.5:1、主要ボタン ≥ 7:1)
/// - 大型タップ領域 (主要 CTA 72dp / タイル 88dp、最小 56×56dp)
/// - 夜間は自動でダークテーマへ (呼び出し側で切替判定)
class AppTheme {
  const AppTheme._();

  // 主要 CTA。ライト背景 #FFFFFF 上での #B00020 は約 8.6:1、
  // ダーク背景 #121212 上での #FF7A85 は約 7.3:1 (WCAG AAA)。
  static const _lightPrimary = Color(0xFFB00020);
  static const _lightOnPrimary = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightOnSurface = Color(0xFF111111); // ≒ 18:1

  static const _darkPrimary = Color(0xFFFF7A85);
  static const _darkOnPrimary = Color(0xFF1A0004);
  static const _darkSurface = Color(0xFF121212);
  static const _darkOnSurface = Color(0xFFF2F2F2); // ≒ 15:1

  static ThemeData light() => _base(
    Brightness.light,
    const ColorScheme.light(
      primary: _lightPrimary,
      onPrimary: _lightOnPrimary,
      secondary: Color(0xFF005CBF),
      onSecondary: Colors.white,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      error: Color(0xFFB00020),
      onError: Colors.white,
    ),
  );

  static ThemeData dark() => _base(
    Brightness.dark,
    const ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: _darkOnPrimary,
      secondary: Color(0xFF87B7FF),
      onSecondary: Color(0xFF001C3B),
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      error: Color(0xFFFF6B6B),
      onError: Color(0xFF1A0000),
    ),
  );

  static ThemeData _base(Brightness brightness, ColorScheme scheme) {
    final baseText = ThemeData(brightness: brightness).textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      // 最小タップ領域を 56dp に押し上げる
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 56),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 56),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(88, 56)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
      ),
      textTheme: baseText.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}
