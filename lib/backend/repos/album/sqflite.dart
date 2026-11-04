import "package:himig/backend/entities/album.dart";
import "package:himig/backend/errors/project_error.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/sqflite.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

class SqfliteAlbumRepo extends AlbumRepo {
  static const _tableName = "albums";

  Album _rowToAlbum(Map row) {
    final coverArtUri = row["cover_art_uri"];
    return Album(
      id: row["id"],
      name: row["name"],
      artistId: row["artist_id"],
      artistName: row["artist_name"],
      localSourceId: row["local_source_id"],
      remoteSourceId: row["remote_source_id"],
      localPath: row["local_path"],
      remoteId: row["remote_id"],
      releaseYear: row["release_year"],
      coverArtUri: coverArtUri == null ? null : Uri.parse(coverArtUri),
    );
  }

  FutureResult<List<Album>> _getAlbumListHelper(
    RepoClient client,
    String query,
    List<dynamic> arguments,
  ) async {
    final result = await client.select(query, arguments);
    if (result is ResultError) {
      return result.toError();
    }

    return Result.ok(result.value.map(_rowToAlbum).toList());
  }

  @override
  FutureResult<Album> getAlbum(RepoClient client, int albumId) async {
    final result = await _getAlbumListHelper(
      client,
      """
SELECT *,
  al.id as id,
  al.name as name,
  ar.name as artist_name
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
WHERE al.id = ?
"""
          .trim(),
      [albumId],
    );
    if (result is ResultError) {
      return result.toError();
    }

    if (result.value.isEmpty) {
      return Result.error(
        ProjectError(.repo, "notFound", {
          "record": (.generic, "album"),
          "id": (null, albumId.toString()),
        }),
      );
    }

    return Result.ok(result.value[0]);
  }

  @override
  FutureResult<List<Album>> getAlbumList(
    RepoClient client, {
    int page = 1,
    int count = 20,
    AlbumSort sort = AlbumSort.recentlyAdded,
    RepoClient? transaction,
  }) => _getAlbumListHelper(
    client,
    """
SELECT *,
  al.id as id,
  al.name as name,
  ar.name as artist_name
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
ORDER BY name LIMIT ?, ?
      """
        .trim(),
    [count * (page - 1), count],
  );

  @override
  FutureResult<List<Album>> getAlbumListByArtist(
    RepoClient client,
    int artistId,
  ) => _getAlbumListHelper(
    client,
    """
SELECT *,
  (SELECT name FROM artists WHERE id = ?) as artist_name
FROM albums
WHERE artist_id = ?
ORDER BY release_year DESC, name
      """
        .trim(),
    [artistId, artistId],
  );

  @override
  FutureResult<Album?> findAlbumByNames(
    RepoClient client,
    String albumName,
    String artistName,
  ) async {
    final result = await _getAlbumListHelper(
      client,
      """
SELECT *,
  al.id as id,
  al.name as name,
  ar.name as artist_name
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
WHERE al.name = ?
  AND ar.name = ?
"""
          .trim(),
      [albumName, artistName],
    );
    if (result is ResultError) {
      return result.toError();
    }

    if (result.value.isEmpty) {
      return Result.ok(null);
    }

    return Result.ok(result.value[0]);
  }

  @override
  FutureResult<int> countAlbums(RepoClient client) async {
    final result = await client.select("SELECT count(*) AS count FROM albums");
    if (result is ResultError) {
      return result.toError();
    }
    return Result.ok(result.value[0]["count"]);
  }

  @override
  FutureResult<Album> insertAlbum(RepoClient client, Album album) async {
    final result = await client.insert(_tableName, {
      "name": album.name,
      "artist_id": album.artistId,
      "local_path": album.localPath,
      "remote_id": album.remoteId,
      "release_year": album.releaseYear,
      "local_source_id": album.localSourceId,
      "remote_source_id": album.remoteSourceId,
      "cover_art_uri": album.coverArtUri?.toString(),
    });

    if (result is ResultError) {
      return result.toError();
    }

    if (result.value == 0) {
      return Result.error(
        ProjectError(.repo, "noneInserted", {"record": (.generic, "album")}),
      );
    }

    return Result.ok(album.copyWith(id: result.value));
  }

  @override
  FutureResult<Album> updateAlbum(RepoClient client, Album album) async {
    final result = await client.update(
      _tableName,
      {
        "name": album.name,
        "artist_id": album.artistId,
        "local_path": album.localPath,
        "remote_id": album.remoteId,
        "release_year": album.releaseYear,
        "local_source_id": album.localSourceId,
        "remote_source_id": album.remoteSourceId,
        "cover_art_uri": album.coverArtUri?.toString(),
      },
      {"id": album.id},
    );

    if (result is ResultError) {
      return result.toError();
    }

    if (result.value == 0) {
      return Result.error(
        ProjectError(.repo, "noneUpdated", {
          "record": (.generic, "album"),
          "id": (.generic, album.id.toString()),
        }),
      );
    }

    return Result.ok(album.copyWith(id: result.value));
  }

  @override
  FutureResult<int> deleteAllAlbums(RepoClient client) =>
      deleteAllAndResetTable(client, _tableName);
}
