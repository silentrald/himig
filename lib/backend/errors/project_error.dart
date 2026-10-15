import "package:flutter/foundation.dart";
import "package:himig/locales/enums.dart";

class ProjectError implements Exception {
  final ErrorLocaleKey key;
  final String id;

  /// [AppLocaleKey]? - key
  /// [String] - id/text
  /// If [AppLocaleKey]? is not null, treat the [String] value as an id to
  ///   reference the value in the translation resource.
  /// If [AppLocaleKey?] is null, then immediately use the [String] value
  ///   as text.
  final Map<String, (AppLocaleKey?, String)>? arguments;

  const ProjectError(this.key, this.id, [this.arguments]);

  @override
  bool operator ==(Object other) {
    return other is ProjectError &&
        key == other.key &&
        id == other.id &&
        mapEquals(arguments, other.arguments);
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;

  @override
  String toString() {
    if (arguments == null) {
      return "${key.name}-$id";
    }

    return "${key.name}-$id $arguments";
  }
}
