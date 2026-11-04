import "package:himig/backend/entities/song.dart";
import "package:himig/backend/errors/project_error.dart";
import "package:himig/backend/repos/sqflite.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/utils/result.dart";

class SqfliteSongRepo extends SongRepo {
  static const _tableName = "songs";
  static const _selectPrefix = """
SELECT *,
  s.id as id,
  al.name as album_name,
  ar.name as artist_name
FROM songs s
  LEFT JOIN albums al ON al.id = s.album_id
  LEFT JOIN artists ar ON ar.id = s.artist_id""";

  Song _rowToSong(Map row) {
    final localUri = row["local_uri"];
    final remoteUri = row["remote_uri"];
    final coverArtUri = row["cover_art_uri"];
    return Song(
      id: row["id"],
      title: row["title"],
      albumName: row["album_name"],
      artistName: row["artist_name"],
      duration: Duration(milliseconds: row["duration"]),
      fileExtension: row["file_extension"],
      releaseYear: row["release_year"],
      localSourceId: row["local_source_id"],
      localUri: localUri == null ? null : Uri.parse(localUri),
      remoteSourceId: row["remote_source_id"],
      remoteUri: remoteUri == null ? null : Uri.parse(remoteUri),
      coverArtUri: coverArtUri == null ? null : Uri.parse(coverArtUri),
      albumId: row["album_id"],
      artistId: row["artist_id"],
    );
  }

  FutureResult<List<Song>> _getSongListHelper(
    RepoClient client,
    String query,
    List<dynamic> arguments,
  ) async {
    final result = await client.select(query, arguments);
    if (result is ResultError) {
      return result.toError();
    }

    return Result.ok(result.value.map(_rowToSong).toList());
  }

  @override
  FutureResult<Song> getSong(RepoClient client, int songId) async {
    final result = await _getSongListHelper(
      client,
      """
$_selectPrefix
WHERE s.id = ?
      """
          .trim(),
      [songId],
    );
    if (result is ResultError) {
      return result.toError();
    }

    if (result.value.isEmpty) {
      return Result.error(
        ProjectError(.repo, "notFound", {
          "record": (.generic, "song"),
          "id": (null, songId.toString()),
        }),
      );
    }

    return Result.ok(result.value[0]);
  }

  @override
  FutureResult<List<Song>> getSongList(
    RepoClient client, {
    int page = 1,
    int count = 20,
  }) => _getSongListHelper(
    client,
    """
$_selectPrefix
ORDER BY s.name
LIMIT ?, ?
"""
        .trim(),
    [count * (page - 1), count],
  );

  @override
  FutureResult<List<Song>> getSongListByAlbum(RepoClient client, int albumId) =>
      _getSongListHelper(
        client,
        """
$_selectPrefix
WHERE s.album_id = ?
      """
            .trim(),
        [albumId],
      );

  @override
  FutureResult<List<Song>> getSongListByArtist(
    RepoClient client,
    int artistId,
  ) => _getSongListHelper(
    client,
    """
$_selectPrefix
WHERE s.artist_id = ?
    """
        .trim(),
    [artistId],
  );

  @override
  FutureResult<Song?> findSongByNames(
    RepoClient client,
    String songTitle,
    String albumName,
    String? artistName,
  ) async {
    final result = await _getSongListHelper(
      client,
      """
$_selectPrefix
WHERE s.title = ?
  AND al.name = ?
  AND ar.name = ?
"""
          .trim(),
      [songTitle, albumName, artistName],
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
  FutureResult<Song> insertSong(RepoClient client, Song song) async {
    final result = await client.insert(_tableName, {
      "title": song.title,
      "duration": song.duration.inMilliseconds,
      "file_extension": song.fileExtension,
      "release_year": song.releaseYear,
      "local_source_id": song.localSourceId,
      "local_uri": song.localUri?.toString(),
      "remote_source_id": song.remoteSourceId,
      "remote_uri": song.remoteUri?.toString(),
      "cover_art_uri": song.coverArtUri?.toString(),
      "album_id": song.albumId,
      "artist_id": song.artistId,
    });

    if (result is ResultError) {
      return result.toError();
    }

    final id = result.value;
    if (result.value == 0) {
      return Result.error(
        ProjectError(.repo, "noneInserted", {"record": (.generic, "song")}),
      );
    }

    return Result.ok(song.copyWith(id: id).value);
  }

  @override
  FutureResult<Song> updateSong(RepoClient client, Song song) async {
    final result = await client.update(
      _tableName,
      {
        "title": song.title,
        "duration": song.duration.inMilliseconds,
        "file_extension": song.fileExtension,
        "release_year": song.releaseYear,
        "local_source_id": song.localSourceId,
        "local_uri": song.localUri?.toString(),
        "remote_source_id": song.remoteSourceId,
        "remote_uri": song.remoteUri?.toString(),
        "cover_art_uri": song.coverArtUri?.toString(),
        "album_id": song.albumId,
        "artist_id": song.artistId,
      },
      {"id": song.id},
    );

    if (result is ResultError) {
      return result.toError();
    }

    if (result.value == 0) {
      return Result.error(
        ProjectError(.repo, "noneUpdated", {
          "record": (.generic, "song"),
          "id": (null, song.id.toString()),
        }),
      );
    }

    return Result.ok(song);
  }

  @override
  FutureResult<int> deleteAllSongs(RepoClient client) =>
      deleteAllAndResetTable(client, _tableName);
}
