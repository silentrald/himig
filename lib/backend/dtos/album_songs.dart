import "package:flutter/foundation.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/song.dart";

/// Album with the associated songs
class AlbumSongsDto {
  final Album? _album;
  final List<Song> _songs;

  AlbumSongsDto({this._album, this._songs = const []});

  Album? get album => _album;
  List<Song> get songs => _songs;

  void addSong(Song song) {
    _songs.add(song);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumSongsDto &&
          _album == other._album &&
          listEquals(_songs, other._songs));

  @override
  int get hashCode => _album?.id ?? 0;

  @override
  String toString() => "{ album: $_album; songs: [$_songs]  }";
}
