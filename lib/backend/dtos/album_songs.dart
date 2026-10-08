import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/song.dart";

/// Album with the associated songs
class AlbumSongsDto {
  final Album _album;
  final List<Song> _songs;

  AlbumSongsDto({required this._album, this._songs = const []});

  Album get album => _album;
  List<Song> get songs => _songs;

  void addSong(Song song) {
    _songs.add(song);
  }
}
