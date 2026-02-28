import 'package:flutter/material.dart';

class AppTheme {
  // Pure black base with warm gold accent — minimal, premium feel
  static const _accent = Color(0xFFD4A574); // Warm gold / camel

  static ThemeData get light {
    final cs = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFF8F7F5),
      onSurface: const Color(0xFF1A1A1A),
    );
    return _build(cs);
  }

  static ThemeData get dark {
    final cs = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF0A0A0A),
      onSurface: const Color(0xFFF0EDEA),
      surfaceContainerHighest: const Color(0xFF1A1A1A),
      surfaceContainerHigh: const Color(0xFF151515),
      surfaceContainer: const Color(0xFF111111),
      surfaceContainerLow: const Color(0xFF0E0E0E),
      surfaceContainerLowest: const Color(0xFF000000),
      primaryContainer: const Color(0xFF2A2218),
      onPrimaryContainer: const Color(0xFFD4A574),
      outline: const Color(0xFF333333),
      outlineVariant: const Color(0xFF222222),
    );
    return _build(cs);
  }

  static ThemeData _build(ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;

    // Slightly bigger base fonts for readability
    final textTheme = TextTheme(
      titleLarge: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w600, color: cs.onSurface),
      titleMedium: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface),
      titleSmall: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: cs.onSurface),
      bodyLarge: TextStyle(fontSize: 17, color: cs.onSurface),
      bodyMedium: TextStyle(fontSize: 15, color: cs.onSurface),
      bodySmall: TextStyle(fontSize: 13, color: cs.onSurface),
      labelLarge: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
      labelMedium: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface),
      labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: TextStyle(
          color: cs.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF141414) : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? const Color(0xFF222222)
                : cs.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF141414) : cs.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.35)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: cs.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: 24);
          }
          return IconThemeData(
              color: cs.onSurface.withValues(alpha: 0.45), size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary);
          }
          return TextStyle(
              fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45));
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.15)),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outline.withValues(alpha: 0.1),
        space: 1,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : null,
        contentTextStyle: TextStyle(
          color: isDark ? const Color(0xFFF0EDEA) : null,
          fontSize: 14,
        ),
        actionTextColor: cs.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF161616) : null,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF0E0E0E) : null,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
