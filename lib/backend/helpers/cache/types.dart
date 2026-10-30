import "package:himig/backend/entities/album.dart";
import "package:himig/utils/result.dart";

abstract class CacheHelper {
  FutureResult<void> cacheArtist(int artistId);
  FutureResult<void> cacheAlbum(Album album);
}
