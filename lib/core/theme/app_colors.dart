import 'package:flutter/material.dart';

/// Palette de l'identité visuelle "Under & Over 7" : nuit bleu/violet + or.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0D0F1E);
  static const Color backgroundSecondary = Color(0xFF171A33);
  static const Color surface = Color(0xFF1C2040);
  static const Color surfaceElevated = Color(0xFF262B52);

  static const Color gold = Color(0xFFF2C14E);
  static const Color goldDim = Color(0xFFB9922E);

  static const Color green = Color(0xFF1FAE5D);
  static const Color greenBright = Color(0xFF34D673);

  static const Color textPrimary = Color(0xFFF5F6FA);
  static const Color textSecondary = Color(0xFF9BA0C2);
  static const Color textMuted = Color(0xFF6B7094);

  static const Color danger = Color(0xFFE5484D);
  static const Color info = Color(0xFF4EA1F2);
  static const Color cyan = Color(0xFF38C6D9);
  static const Color violet = Color(0xFF8B72F6);

  static const List<Color> backgroundGradient = [
    Color(0xFF0D0F1E),
    Color(0xFF181A33),
    Color(0xFF120E25),
  ];
}
