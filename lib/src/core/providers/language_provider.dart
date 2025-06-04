import 'package:flutter/foundation.dart';
import '../services/language_service.dart';

class LanguageProvider extends ChangeNotifier {
  final LanguageService _languageService = LanguageService.instance;

  LanguageProvider() {
    // Listen to language service changes
    _languageService.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
    notifyListeners();
  }

  SupportedLanguage get currentLanguage => _languageService.currentLanguage;

  Future<void> changeLanguage(SupportedLanguage language) async {
    await _languageService.changeLanguage(language);
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }
}
