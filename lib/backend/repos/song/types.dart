import "package:himig/backend/entities/song.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

abstract class SongRepo {
  FutureResult<Song> getSong(RepoClient client, int songId);
  FutureResult<List<Song>> getSongList(
    RepoClient client, {
    int page = 1,
    int count = 20,
  });
  FutureResult<List<Song>> getSongListByAlbum(RepoClient client, int albumId);
  FutureResult<List<Song>> getSongListByArtist(RepoClient client, int artistId);

  FutureResult<Song?> findSongByNames(
    RepoClient client,
    String songTitle,
    String albumName,
    String? artistName,
  );

  FutureResult<Song> insertSong(RepoClient client, Song song);
  FutureResult<Song> updateSong(RepoClient client, Song song);

  FutureResult<int> deleteAllSongs(RepoClient client);
}
