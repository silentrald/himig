// https://flutterlocalisation.com/blog/flutter-change-language-runtime

import "package:flutter/widgets.dart";
import "package:shared_preferences/shared_preferences.dart";

class LocaleController extends ChangeNotifier {
  static const String _storageKey = "app_locale";

  Locale? _locale;
  Locale? get locale => _locale;

  /// Initialize and load saved locale
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_storageKey);

    if (savedLocale != null) {
      final parts = savedLocale.split("_");
      _locale = Locale(parts[0], parts.length > 1 ? parts[1] : null);
    }
    // If no saved locale, _locale remains null (use system default)
    notifyListeners();
  }

  /// Change the app locale
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;

    _locale = newLocale;
    notifyListeners();

    // Persist the selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      "${newLocale.languageCode}_${newLocale.countryCode ?? ""}",
    );
  }

  /// Reset to system locale
  Future<void> resetToSystemLocale() async {
    _locale = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Get display name for locale
  static String getDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case "en":
        return "English";
      case "ja":
        return "日本語";
      default:
        return locale.languageCode;
    }
  }

  /// Get flag emoji for locale
  static String getFlag(Locale locale) {
    switch ("${locale.languageCode}_${locale.countryCode}") {
      case "en_US":
        return "🇺🇸";
      case "ja_JP":
        return "🇯🇵";
      default:
        return "🌐";
    }
  }
}
