import "package:himig/backend/entities/source.dart";
import "package:himig/backend/repos/source/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

class MockSourceRepo extends SourceRepo {
  final List<Source> _sources = [];

  void addSourceList(List<Source> sources) {
    var count = _sources.length;

    for (final source in sources) {
      source.setId(count);
      ++count;
    }

    _sources.addAll(sources);
  }

  @override
  Future<Result<List<Source>>> getAllSources(RepoClient client) async =>
      Result.ok(_sources);

  @override
  Future<Result<Source>> insertSource(RepoClient client, Source source) async {
    source.setId(_sources.length);
    _sources.add(source);
    return Result.ok(source);
  }

  @override
  Future<Result<Source>> updateSource(RepoClient client, Source source) async {
    final index = _sources.indexWhere((s) => s.id == source.id);
    if (index == -1) {
      return Result.error(Exception("Could not find source"));
    }

    _sources[index] = source;
    return Result.ok(source);
  }

  @override
  Future<Result<int>> deleteAllSources(RepoClient client) async {
    final count = _sources.length;
    _sources.clear();
    return Result.ok(count);
  }
}
