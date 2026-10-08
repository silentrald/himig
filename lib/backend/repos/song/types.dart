import "package:himig/backend/entities/song.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

abstract class SongRepo {
  FutureResult<List<Song>> getSongList(
    RepoClient client, {
    int page = 1,
    int count = 20,
  });
  FutureResult<List<Song>> getSongsByAlbum(RepoClient client, int albumId);
  FutureResult<List<Song>> getSongsByArtist(RepoClient client, int artistId);

  FutureResult<Song> insertSong(RepoClient client, Song song);
  FutureResult<Song> updateSong(RepoClient client, Song song);

  FutureResult<int> deleteAllSongs(RepoClient client);
}
