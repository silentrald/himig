import "package:himig/backend/entities/album.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/repo.dart";
import "package:himig/utils/result.dart";

class SqfliteAlbumRepo extends AlbumRepo {
  @override
  Future<Result<List<Album>>> getAlbumList(
    RepoClient client, {
    int page = 1,
    int count = 20,
    AlbumSort sort = AlbumSort.recentlyAdded,
    RepoClient? transaction,
  }) async {
    final result = await client.select(
      "SELECT * FROM albums order by name limit ?, ?",
      [count * (page - 1), count],
    );
    switch (result) {
      case ResultError(:var error):
        return Result.error(error);

      case ResultOk(:var value):
        return Result.ok(
          value.map((r) {
            final coverArtUri = r["cover_art_uri"];
            return Album(
              id: r["id"],
              name: r["name"],
              artist: r["artist"],
              sourceId: r["source_id"],
              reference: r["reference"],
              releaseYear: r["release_year"],
              coverArtUri: coverArtUri == null ? null : Uri.parse(coverArtUri),
            );
          }).toList(),
        );
    }
  }

  @override
  Future<Result<Album>> insertAlbum(RepoClient client, Album album) async {
    final result = await client.insert("albums", {
      "name": album.name,
      "artist": album.artist,
      "reference": album.reference,
      "release_year": album.releaseYear,
      "source_id": album.sourceId,
      "cover_art_uri": album.coverArtUri?.toString(),
    });

    switch (result) {
      case ResultError(:var error):
        return Result.error(error);

      case ResultOk(:var value):
        if (value == 0) {
          return Result.error(Exception("Album was not inserted"));
        }
        album.id = value;
    }

    return Result.ok(album);
  }

  @override
  Future<Result<int>> deleteAllAlbums(RepoClient client) async {
    return await client.delete("DELETE FROM albums");
  }
}
