import 'package:flutter/material.dart';

class AppTheme {
  // Màu chủ đạo: xanh dược + teal
  static const seed = Color(0xFF0EA5A5); // teal xanh y tế
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  static ThemeData _base(Color seed, Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: b == Brightness.light
          ? const Color(0xFFF7FAFC)
          : const Color(0xFF0B1215),
      cardTheme: CardThemeData(
        elevation: 0.8,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: b == Brightness.light ? Colors.white : scheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static ThemeData get light => _base(seed, Brightness.light);
  static ThemeData get dark => _base(seed, Brightness.dark);
}
