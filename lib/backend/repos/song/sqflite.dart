import "package:himig/backend/entities/song.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/utils/result.dart";

class SqfliteSongRepo extends SongRepo {
  Song _rowToSong(Map row) {
    final localUri = row["local_uri"];
    final remoteUri = row["remote_uri"];
    final coverArtUri = row["cover_art_uri"];
    return Song(
      id: row["id"],
      title: row["title"],
      album: row["album"],
      artist: row["artist"],
      duration: row["duration"],
      reference: row["reference"],
      releaseYear: row["release_year"],
      localSourceId: row["local_source_id"],
      localUri: localUri == null ? null : Uri.parse(localUri),
      remoteSourceId: row["remote_source_id"],
      remoteUri: remoteUri == null ? null : Uri.parse(remoteUri),
      coverArtUri: remoteUri == null ? null : Uri.parse(coverArtUri),
      albumId: row["album_id"],
    );
  }

  @override
  Future<Result<List<Song>>> getSongList(
    RepoClient client, {
    int page = 1,
    int count = 20,
  }) async {
    final result = await client.select("SELECT * FROM songs limit ?, ?", [
      count * (page - 1),
      count,
    ]);
    switch (result) {
      case ResultError(:var error):
        return Result.error(error);

      case ResultOk(:var value):
        return Result.ok(value.map(_rowToSong).toList());
    }
  }

  @override
  Future<Result<List<Song>>> getSongsByAlbum(
    RepoClient client,
    int albumId,
  ) async {
    final result = await client.select(
      "SELECT * FROM songs where album_id = ?",
      [albumId],
    );
    switch (result) {
      case ResultError(:var error):
        return Result.error(error);

      case ResultOk(:var value):
        return Result.ok(value.map(_rowToSong).toList());
    }
  }

  @override
  Future<Result<Song>> insertSong(RepoClient client, Song song) async {
    final result = await client.insert("songs", {
      "title": song.title,
      "album": song.album,
      "artist": song.artist,
      "duration": song.duration,
      "reference": song.reference,
      "release_year": song.releaseYear,
      "local_source_id": song.localSourceId,
      "local_uri": song.localUri?.toString(),
      "remote_source_id": song.remoteSourceId,
      "remote_uri": song.remoteUri?.toString(),
      "cover_art_uri": song.coverArtUri?.toString(),
      "album_id": song.albumId,
    });

    switch (result) {
      case ResultError(:var error):
        return Result.error(error);

      case ResultOk(:var value):
        if (value == 0) {
          return Result.error(Exception("Song was not inserted"));
        }
        song.id = value;
    }

    return Result.ok(song);
  }

  @override
  Future<Result<Song>> updateSong(RepoClient client, Song song) async {
    final result = await client.update(
      "songs",
      {
        "title": song.title,
        "album": song.album,
        "artist": song.artist,
        "duration": song.duration,
        "reference": song.reference,
        "release_year": song.releaseYear,
        "local_source_id": song.localSourceId,
        "local_uri": song.localUri?.toString(),
        "remote_source_id": song.remoteSourceId,
        "remote_uri": song.remoteUri?.toString(),
        "cover_art_uri": song.coverArtUri?.toString(),
        "album_id": song.albumId,
      },
      {"id": song.id},
    );

    switch (result) {
      case ResultError(:var error):
        return Result.error(error);

      case ResultOk(:var value):
        if (value == 0) {
          return Result.error(Exception("Song was not updated"));
        }
    }

    return Result.ok(song);
  }

  @override
  Future<Result<int>> deleteAllSongs(RepoClient client) async {
    return await client.delete("songs");
  }
}
