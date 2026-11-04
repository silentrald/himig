import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/errors/project_error.dart";
import "package:himig/backend/repos/artist/types.dart";
import "package:himig/backend/repos/sqflite.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

class SqfliteArtistRepo extends ArtistRepo {
  static const _tableName = "artists";

  Artist _rowToArtist(Map row) {
    final imageUri = row["image_uri"];
    return Artist(
      id: row["id"],
      name: row["name"],
      imageUri: imageUri == null ? null : Uri.parse(imageUri),
    );
  }

  @override
  FutureResult<Artist> getArtist(RepoClient client, int artistId) async {
    final result = await client.select("SELECT * FROM artists WHERE id = ?", [
      artistId,
    ]);
    if (result is ResultError) {
      return result.toError();
    }

    if (result.value.isEmpty) {
      return Result.error(
        ProjectError(.repo, "notFound", {
          "record": (.generic, "album"),
          "id": (null, artistId.toString()),
        }),
      );
    }

    return Result.ok(_rowToArtist(result.value[0]));
  }

  @override
  FutureResult<List<Artist>> getArtistList(
    RepoClient client, {
    int page = 1,
    int count = 20,
  }) async {
    final result = await client.select(
      "SELECT * FROM artists ORDER BY name LIMIT ?, ?",
      [count * (page - 1), count],
    );

    if (result is ResultError) {
      return result.toError();
    }

    return Result.ok(result.value.map(_rowToArtist).toList());
  }

  @override
  FutureResult<Artist?> findArtistByName(
    RepoClient client,
    String artistName,
  ) async {
    final result = await client.select("SELECT * FROM artists WHERE name = ?", [
      artistName,
    ]);
    if (result is ResultError) {
      return result.toError();
    }

    if (result.value.isEmpty) {
      return Result.ok(null);
    }

    return Result.ok(_rowToArtist(result.value[0]));
  }

  @override
  FutureResult<Artist> insertArtist(RepoClient client, Artist artist) async {
    final result = await client.insert(_tableName, {
      "name": artist.name,
      "image_uri": artist.imageUri?.toString(),
    });

    if (result is ResultError) {
      return result.toError();
    }

    final id = result.value;
    if (id == 0) {
      return Result.error(Exception("Artist was not inserted"));
    }

    return Result.ok(artist.copyWith(id: id));
  }

  @override
  FutureResult<int> deleteAllArtists(RepoClient client) =>
      deleteAllAndResetTable(client, _tableName);
}
