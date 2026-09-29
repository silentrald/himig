import "package:himig/backend/entities/source.dart";
import "package:himig/backend/repos/repo.dart";
import "package:himig/utils/result.dart";

abstract class SourceRepo {
  Future<Result<List<Source>>> getAllSources(RepoClient client);
  Future<Result<Source>> insertSource(RepoClient client, Source source);
  Future<Result<Source>> updateSource(RepoClient client, Source source);
  Future<Result<int>> deleteAllSources(RepoClient client);
}
