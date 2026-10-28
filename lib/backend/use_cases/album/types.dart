import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/utils/result.dart";

abstract class AlbumUseCase {
  Future<Result<List<Song>>> getSongListByAlbum(int albumId);

  Future<Result<void>> cacheAlbumSongs(Album album);
}
