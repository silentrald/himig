import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:himig/constant.dart";
import "package:yaml/yaml.dart";

enum AppLocaleKey { generic, source, folderReadWrite }

enum ErrorLocaleKey { _ }

class AppLocalizations {
  final Locale locale;
  var _appMap = YamlMap();
  var _errorMap = YamlMap();
  var _appFallbackMap = YamlMap();
  var _errorFallbackMap = YamlMap();

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationDelegate();

  static AppLocalizations? of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  static AppLocalizations get instance => _AppLocalizationDelegate.instance;

  Future<void> load() async {
    _appMap = loadYaml(
      await rootBundle.loadString(
        "lib/locales/app/${locale.languageCode}.yaml",
      ),
    );
    _errorMap = loadYaml(
      await rootBundle.loadString(
        "lib/locales/error/${locale.languageCode}.yaml",
      ),
    );

    // Load the fallback if the current locale is not english
    if (_appFallbackMap.isEmpty && locale != Locale("en")) {
      _appFallbackMap = loadYaml(
        await rootBundle.loadString(
          "lib/locales/app/${locale.languageCode}.yaml",
        ),
      );
      _errorFallbackMap = loadYaml(
        await rootBundle.loadString("lib/locales/error/en.yaml"),
      );
    }
  }

  String _processText(String text, Map<String, dynamic>? arguments) {
    if (arguments == null) {
      return text;
    }

    for (final entry in arguments.entries) {
      text = text.replaceAll("{${entry.key}}", entry.value.toString());
    }
    return text;
  }

  String app(AppLocaleKey key, String id, [Map<String, dynamic>? arguments]) {
    var map = _appMap[key.name];
    if (!map.containsKey(id)) {
      map = _appFallbackMap[key.name];
    }

    assert(map.containsKey(id), "app map with $key does not contain $id");
    return _processText(map[id], arguments);
  }

  String error(
    ErrorLocaleKey key,
    String id, [
    Map<String, dynamic>? arguments,
  ]) {
    var map = _errorMap[key.name];
    if (!map.containsKey(id)) {
      map = _errorFallbackMap[key.name];
    }

    assert(map.containsKey(id), "error map with $key does not contain $id");
    return _processText(map[id], arguments);
  }
}

class _AppLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationDelegate();

  static late AppLocalizations instance;

  @override
  bool isSupported(Locale locale) => supportedLocales.contains(locale);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();

    instance = localizations;

    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationDelegate old) => true;
}
