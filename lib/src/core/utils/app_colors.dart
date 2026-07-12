import 'package:flutter/material.dart';

/// App color palette — ivory light mode, matte dark mode, violet accent.
class AppColors {
  // --- Brand primary (violet) ---
  static const Color primaryColor = Color(0xFF7C3AED);
  static const Color primaryColorLight = Color(0xFF9B6CFB); // dark-mode brand
  static const Color primaryColorDark = Color(0xFF5B21B6); // deep violet

  // --- Accent ---
  static const Color accentTeal = Color(0xFF2C9A94);
  static const Color accentViolet = Color(0xFF8244EE);
  static const Color accentVioletLight = Color(0xFF9B6CFB);

  // --- Backgrounds (scaffold) ---
  static const Color scaffoldBackgroundColorDark = Color(0xFF121212); // matte black
  static const Color scaffoldBackgroundColorLight = Color(0xFFFAF8F2); // ivory

  // --- Surfaces (cards / dialogs) ---
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color splashBackgroundColor = Color(0xFF121212);

  // --- Borders / inputs ---
  static const Color borderDark = Color(0xFF333333);
  static const Color borderLight = Color(0xFFE2E0DA);
  static const Color inputDark = Color(0xFF2A2A2A);
  static const Color inputLight = Color(0xFFF0EEE8);

  // --- Foreground / text ---
  static const Color foregroundDark = Color(0xFFF5F5F5);
  static const Color foregroundLight = Color(0xFF1A1A1A);
  static const Color textDark = foregroundLight;
  static const Color textLight = foregroundDark;
  static const Color mutedForegroundDark = Color(0xFFB0B0B0);
  static const Color mutedForegroundLight = Color(0xFF6E6E6E);

  // --- Semantic ---
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveDark = Color(0xFFF87171);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // --- Legacy convenience aliases (keep names widgets already use) ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color blackWithOpacity = Color(0x80000000);
  static const Color whiteWithOpacity = Color(0x80FFFFFF);
  static const Color opacityLayerColor = Color(0xFFE2E0DA);
  static const Color red = destructive;
  static const Color green = success;
  static const Color light = Color(0xFFE2E0DA);
}
