import 'package:flutter/material.dart';

class AppTheme {
  static const Color babyBlue = Color(0xFF89C4E1);
  static const Color _nearBlack = Color(0xFF1A1A1A);
  static const Color _surface = Color(0xFFF4F4F4);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: babyBlue,
      brightness: Brightness.light,
      surface: _surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _surface,
      appBarTheme: AppBarTheme(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: _nearBlack,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: babyBlue.withAlpha(70),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _nearBlack,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      // Chip theme sets structure only — label color is handled per-widget
      // to avoid M3's internal state override swallowing the color.
      chipTheme: ChipThemeData(
        selectedColor: babyBlue,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey[300]!),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: babyBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _nearBlack,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
