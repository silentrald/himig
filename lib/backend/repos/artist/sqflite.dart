import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/repos/artist/types.dart";
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
  FutureResult<Map<String, int>> getArtistMap(RepoClient client) async {
    final result = await client.select("SELECT * FROM artists");

    if (result is ResultError) {
      return result.toError();
    }

    return Result.ok({for (final row in result.value) row["name"]: row["id"]});
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
  FutureResult<int> deleteAllArtists(RepoClient client) async {
    return await client.delete(_tableName);
  }
}
