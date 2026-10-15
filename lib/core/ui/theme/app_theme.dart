import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF294D3B),
          brightness: brightness,
        ).copyWith(
          primary: Color(isDark ? 0xFFD0DDCE : 0xFF294D3B),
          onPrimary: Color(isDark ? 0xFF172219 : 0xFFFFFFFF),
          surface: Color(isDark ? 0xFF202620 : 0xFFF7F7F2),
          onSurface: Color(isDark ? 0xFFF3F3ED : 0xFF202620),
          onSurfaceVariant: Color(isDark ? 0xFFB5BFB5 : 0xFF626B63),
          outlineVariant: Color(isDark ? 0xFF3E4840 : 0xFFD9DDD5),
          error: Color(isDark ? 0xFFF2A7A2 : 0xFFA33131),
          onError: Color(isDark ? 0xFF202620 : 0xFFFFFFFF),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
