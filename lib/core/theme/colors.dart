import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4A90D9);
  static const Color primaryLight = Color(0xFF7BB3E8);
  static const Color primaryDark = Color(0xFF2E6BB0);

  static const Color secondary = Color(0xFF6EC1A7);
  static const Color secondaryLight = Color(0xFF95D4BF);
  static const Color secondaryDark = Color(0xFF4DA886);

  static const Color accent = Color(0xFFFFB74D);

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textHint = Color(0xFFBDC3C7);

  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  static const Color divider = Color(0xFFECF0F1);
}

extension ColorExt on Color {
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
