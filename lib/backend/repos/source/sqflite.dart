import "dart:convert";

import "package:himig/backend/entities/source.dart";
import "package:himig/backend/repos/repo.dart";
import "package:himig/backend/repos/source/types.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

class SqfliteSourceRepo extends SourceRepo {
  @override
  Future<Result<List<Source>>> getAllSources(RepoClient client) async {
    final result = await client.select("SELECT * FROM sources");

    if (result is ResultError) {
      return Result.error(result.error);
    }

    final List<Source> sources = [];
    for (final row in result.value) {
      final String type = row["type"];

      if (type == SourceType.folder.name) {
        sources.add(
          FolderSource.fromRepo(
            row["id"],
            row["name"],
            jsonDecode(row["data"]),
          ),
        );
      } else if (type == SourceType.subsonic.name) {
        sources.add(
          SubsonicSource.fromRepo(
            row["id"],
            row["name"],
            jsonDecode(row["data"]),
          ),
        );
      } else {
        logger.warn("Could not found source type $type");
      }
    }

    return Result.ok(sources);
  }

  @override
  Future<Result<Source>> insertSource(RepoClient client, Source source) async {
    final result = await client.insert("sources", {
      "name": source.name,
      "type": source.type.name,
      "data": source.serialize(),
    });

    switch (result) {
      case ResultError(:var error):
        return Result.error(error);

      case ResultOk(:var value):
        if (value == 0) {
          return Result.error(Exception("Source was not inserted"));
        }
        source.setId(value);
    }

    return Result.ok(source);
  }

  @override
  Future<Result<Source>> updateSource(RepoClient client, Source source) async {
    final result = await client.updateById("sources", "id", source.id, {
      "name": source.name,
      "type": source.type.name,
      "data": source.serialize(),
    });

    switch (result) {
      case ResultError(:var error):
        return Result.error(error);

      case ResultOk(:var value):
        if (value == 0) {
          return Result.error(Exception("Source was not inserted"));
        }
    }

    return Result.ok(source);
  }

  @override
  Future<Result<int>> deleteAllSources(RepoClient client) async {
    return await client.delete("DELETE FROM sources");
  }
}
