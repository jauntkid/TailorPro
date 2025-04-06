import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color primary = Color(0xFFF82C2C);
  static const Color secondary = Color(0xFF444444);
  static const Color background = Colors.black;
  static const Color cardBackground = Color(0xFF18181B);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color statusInProgress = Color(0xFF10B981);
  static const Color statusReady = Color(0xFF3B82F6);
  static const Color accentColor = Color(0xFFF82C2C);
  static const Color dividerColor = Color(0xFF2A2A2A);
  static const Color borderColor = Color(0xFFE5E7EB);

  // Status Background Colors
  static const Color statusInProgressBg = Color(0x3310B981);
  static const Color statusReadyBg = Color(0x333B82F6);

  // Font Styles
  static const TextStyle headingLarge = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    height: 1,
  );

  static const TextStyle headingMedium = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    height: 1,
  );

  static const TextStyle bodyLarge = TextStyle(
    color: textPrimary,
    fontSize: 16,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    height: 1,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: textPrimary,
    fontSize: 16,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static const TextStyle bodyRegular = TextStyle(
    color: textPrimary,
    fontSize: 16,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    color: textSecondary,
    fontSize: 14,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    height: 1,
  );

  static const TextStyle buttonLarge = TextStyle(
    color: textPrimary,
    fontSize: 16,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    height: 1,
  );

  static const TextStyle buttonMedium = TextStyle(
    color: Colors.black,
    fontSize: 14,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    height: 1,
  );

  static const TextStyle tabLabel = TextStyle(
    fontSize: 12,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    height: 1,
  );

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(borderRadiusMedium),
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.all(primary),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusLarge),
      ),
    ),
    padding: MaterialStateProperty.all(
      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  );

  static ButtonStyle secondaryButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.all(secondary),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusLarge),
      ),
    ),
    padding: MaterialStateProperty.all(
      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  );
}
