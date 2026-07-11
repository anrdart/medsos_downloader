import 'package:flutter/material.dart';

/// App color palette — Ekalliptus design language.
/// Emerald green brand + teal/violet accents on a deep navy canvas.
/// Mirrors the token set used at ekalliptus.com.
class AppColors {
  // --- Brand primary (Ekalliptus green) ---
  static const Color primaryColor = Color(0xFF29A37A); // light primary (hsl 160 60% 40%)
  static const Color primaryColorLight = Color(0xFF33CC99); // dark-mode primary (hsl 160 60% 50%)
  static const Color primaryColorDark = Color(0xFF1E7A5C); // deeper green for pressed/shadows

  // --- Accent teal ---
  static const Color accentTeal = Color(0xFF2C9A94); // hsl 170 55% 38%
  static const Color accentTealLight = Color(0xFF34B8AF); // hsl 170 55% 45%

  // --- Accent-2 violet (for highlights / glow halos) ---
  static const Color accentViolet = Color(0xFF7C3AED); // hsl 262 83% 60%
  static const Color accentVioletLight = Color(0xFF9B6CFB); // hsl 262 83% 67%

  // --- Backgrounds (scaffold) ---
  static const Color scaffoldBackgroundColorDark = Color(0xFF0C1222); // hsl 222 47% 6%
  static const Color scaffoldBackgroundColorLight = Color(0xFFF1F5F9); // hsl 220 14% 96%

  // --- Surfaces (cards / dialogs) ---
  static const Color cardDark = Color(0xFF111A2E); // hsl 223 47% 10%
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color splashBackgroundColor = Color(0xFF0C1222);

  // --- Borders / inputs ---
  static const Color borderDark = Color(0xFF222E44); // hsl 217 33% 20%
  static const Color borderLight = Color(0xFFCBD5DD); // hsl 220 13% 85%
  static const Color inputDark = Color(0xFF1D283A); // hsl 217 33% 17%
  static const Color inputLight = Color(0xFFE0E6EB); // hsl 220 13% 91%

  // --- Foreground / text ---
  static const Color foregroundDark = Color(0xFFEAF2FA); // hsl 210 40% 96%
  static const Color foregroundLight = Color(0xFF0F172A); // hsl 222 47% 11%
  static const Color textDark = foregroundLight;
  static const Color textLight = foregroundDark;
  static const Color mutedForegroundDark = Color(0xFF7588A3); // hsl 215 20% 55%
  static const Color mutedForegroundLight = Color(0xFF6E7884); // hsl 220 9% 46%

  // --- Semantic ---
  static const Color destructive = Color(0xFFE23333); // light destructive
  static const Color destructiveDark = Color(0xFFCD3030);
  static const Color success = Color(0xFF21C45D); // status won/paid
  static const Color warning = Color(0xFFF59F0A); // pending/proposal
  static const Color info = Color(0xFF3C83F6); // contacted/processing

  // --- Legacy convenience aliases (keep names widgets already use) ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color blackWithOpacity = Color(0x80000000);
  static const Color whiteWithOpacity = Color(0x80FFFFFF);
  static const Color opacityLayerColor = Color(0xFFCBD5DD);
  static const Color red = destructive;
  static const Color green = success;
  static const Color light = Color(0xFFCBD5DD);
}
