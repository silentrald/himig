import "package:himig/backend/entities/song.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

abstract class SongRepo {
  Future<Result<List<Song>>> getSongList(
    RepoClient client, {
    int page = 1,
    int count = 20,
  });
  Future<Result<List<Song>>> getSongsByAlbum(RepoClient client, int albumId);

  Future<Result<Song>> insertSong(RepoClient client, Song song);
  Future<Result<Song>> updateSong(RepoClient client, Song song);

  Future<Result<int>> deleteAllSongs(RepoClient client);
}
