import "package:himig/backend/dtos/album_songs.dart";
import "package:himig/utils/result.dart";

abstract class ArtistUseCase {
  /// Returns a list of albums with is associated songs
  FutureResult<List<AlbumSongsDto>> getAlbumSongsList(int artistId);

  FutureResult<void> cacheArtist(int artistId);
}
