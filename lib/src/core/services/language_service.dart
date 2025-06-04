import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SupportedLanguage {
  english('en', '🇺🇸', 'English'),
  indonesian('id', '🇮🇩', 'Bahasa Indonesia');

  const SupportedLanguage(this.code, this.flag, this.name);

  final String code;
  final String flag;
  final String name;
}

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';

  static LanguageService? _instance;
  static LanguageService get instance => _instance ??= LanguageService._();
  LanguageService._();

  SupportedLanguage _currentLanguage = SupportedLanguage.english;

  SupportedLanguage get currentLanguage => _currentLanguage;
  Locale get currentLocale => Locale(_currentLanguage.code);

  /// Initialize language service and load saved language preference
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageKey) ?? _defaultLanguage;

    // Try to find the saved language, default to English if not found
    try {
      _currentLanguage = SupportedLanguage.values.firstWhere(
        (lang) => lang.code == savedLanguageCode,
        orElse: () => SupportedLanguage.english,
      );
    } catch (e) {
      _currentLanguage = SupportedLanguage.english;
    }
  }

  /// Change language and persist the selection
  Future<void> changeLanguage(SupportedLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);

    // Notify listeners about language change
    notifyListeners();
  }

  /// Get system language if supported, otherwise return default
  SupportedLanguage getSystemLanguage() {
    final systemLocale = PlatformDispatcher.instance.locale.languageCode;

    try {
      return SupportedLanguage.values.firstWhere(
        (lang) => lang.code == systemLocale,
        orElse: () => SupportedLanguage.english,
      );
    } catch (e) {
      return SupportedLanguage.english;
    }
  }

  /// Auto-detect language based on system settings (for first-time users)
  Future<void> autoDetectLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSelectedLanguage = prefs.containsKey(_languageKey);

    if (!hasSelectedLanguage) {
      final systemLanguage = getSystemLanguage();
      await changeLanguage(systemLanguage);
    }
  }
}
