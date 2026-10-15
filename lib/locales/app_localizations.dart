import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:himig/backend/errors/multi_project_error.dart";
import "package:himig/backend/errors/project_error.dart";
import "package:himig/locales/enums.dart";
import "package:yaml/yaml.dart";

const List<Locale> supportedLocales = [Locale("en", "US"), Locale("ja", "JP")];

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
    if (_appFallbackMap.isEmpty && locale != Locale("en", "US")) {
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

  String _findText(AppLocaleKey? key, String id) {
    if (key == null) {
      return id;
    }

    var map = _appMap[key.name];
    if (!map.containsKey(id)) {
      map = _appFallbackMap[key.name];
    }

    assert(map.containsKey(key), "app map with $key does not contain $key");
    return map[id];
  }

  /// [AppLocaleKey]? - key
  /// [String] - id/text
  /// If [AppLocaleKey]? is not null, treat the [String] value as an id to
  ///   reference the value in the translation resource.
  /// If [AppLocaleKey?] is null, then immediately use the [String] value
  ///   as text.
  String _processText(
    String text,
    Map<String, (AppLocaleKey?, String)>? arguments,
  ) {
    if (arguments == null) {
      return text;
    }

    for (final entry in arguments.entries) {
      text = text.replaceAll(
        "{${entry.key}}",
        _findText(entry.value.$1, entry.value.$2),
      );
    }
    return text;
  }

  /// [AppLocaleKey]? - key
  /// [String] - id/text
  /// If [AppLocaleKey]? is not null, treat the [String] value as an id to
  ///   reference the value in the translation resource.
  /// If [AppLocaleKey?] is null, then immediately use the [String] value
  ///   as text.
  String translate(
    AppLocaleKey key,
    String id, [
    Map<String, (AppLocaleKey?, String)>? arguments,
  ]) {
    var map = _appMap[key.name];
    if (!map.containsKey(id)) {
      map = _appFallbackMap[key.name];
    }

    assert(map.containsKey(id), "app map with $key does not contain $id");
    return _processText(map[id], arguments);
  }

  /// [AppLocaleKey]? - key
  /// [String] - id/text
  /// If [AppLocaleKey]? is not null, treat the [String] value as an id to
  ///   reference the value in the translation resource.
  /// If [AppLocaleKey?] is null, then immediately use the [String] value
  ///   as text.
  String _translateError(
    ErrorLocaleKey key,
    String id, [
    Map<String, (AppLocaleKey?, String)>? arguments,
  ]) {
    var map = _errorMap[key.name];
    if (!map.containsKey(id)) {
      map = _errorFallbackMap[key.name];
    }

    assert(map.containsKey(id), "error map with $key does not contain $id");
    return _processText(map[id], arguments);
  }

  String? translateProjectError(ProjectError? error) => error == null
      ? null
      : _translateError(error.key, error.id, error.arguments);

  // NOTE: check if the separator ", " needs to be changed for other locales
  String? translateMultipleProjectError(MultiProjectError? error) => error
      ?.errors
      .map((e) => _translateError(e.key, e.id, e.arguments))
      .join(", ");
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
