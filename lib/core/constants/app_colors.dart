import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (Islamic Emerald & Slate)
  static const Color primary = Color(0xFF0D5C3A);
  static const Color primaryDark = Color(0xFF073822);
  static const Color primaryLight = Color(0xFFE8F5EE);

  // Accent Gold Palette
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color accentGoldLight = Color(0xFFFFF9E6);
  static const Color secondary = Color(0xFF1E826B);

  // Surface & Neutral Colors
  static const Color background = Color(0xFFF6F9F8);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF2F7);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF718096);
  static const Color textOnPrimary = Colors.white;

  // Status Badges
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D5C3A), Color(0xFF167C52)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFF3C64F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0D5C3A), Color(0xFF063B23)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
