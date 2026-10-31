import "package:himig/backend/entities/album.dart";
import "package:himig/backend/helpers/cache/types.dart";
import "package:himig/utils/result.dart";

class MockCacheHelper extends CacheHelper {
  @override
  FutureResult<void> cacheArtist(int artistId) async => Result.ok(null);

  @override
  FutureResult<void> cacheAlbum(Album album) async => Result.ok(null);
}
