import "package:himig/backend/entities/source.dart";

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final Map<int, Source> _sources = {};
  List<Source> get sourceList => _sources.values.toList();

  void addSourceList(List<Source> sources) {
    for (final source in sources) {
      _sources[source.id] = source;
    }
  }

  void addSource(Source source) => _sources[source.id] = source;
  void updateSource(Source source) => _sources[source.id] = source;
  Source getSource(int id) => _sources[id]!; // Fast way to access

  List<Source> get writeableSources =>
      _sources.values.where((s) => s.writeable).toList();
}
