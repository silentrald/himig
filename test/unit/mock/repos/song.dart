import "dart:math";

import "package:himig/backend/entities/song.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

class MockSongRepo extends SongRepo {
  final List<Song> _songs = [];

  void setSongList(List<Song> songs) {
    _songs.clear();
    _songs.addAll(songs);
  }

  @override
  FutureResult<List<Song>> getSongList(
    RepoClient client, {
    int page = 1,
    int count = 20,
  }) async => Result.ok(
    _songs.sublist((page - 1) * count, min(_songs.length, page * count)),
  );

  @override
  FutureResult<List<Song>> getSongListByAlbum(
    RepoClient client,
    int albumId,
  ) async => Result.ok(_songs.where((s) => s.albumId == albumId).toList());

  @override
  FutureResult<List<Song>> getSongListByArtist(
    RepoClient client,
    int artistId,
  ) async => Result.ok(_songs.where((s) => s.artistId == artistId).toList());

  @override
  FutureResult<Song> insertSong(RepoClient client, Song song) async {
    song.id = _songs.length;
    _songs.add(song);
    return Result.ok(song);
  }

  @override
  FutureResult<Song> updateSong(RepoClient client, Song song) async {
    var index = _songs.indexWhere((s) => s.id == song.id);
    if (index == -1) {
      return Result.error(Exception("Could not find song"));
    }

    _songs[index] = song;
    return Result.ok(song);
  }

  @override
  FutureResult<int> deleteAllSongs(RepoClient client) async {
    final count = _songs.length;
    _songs.clear();
    return Result.ok(count);
  }
}
