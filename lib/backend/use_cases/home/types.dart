import "package:himig/backend/entities/album.dart";
import "package:himig/utils/result.dart";

abstract class HomeUseCase {
  Future<Result<List<Album>>> getAlbumList({
    int page = 1,
    int count = 20,
    AlbumSort sort = AlbumSort.recentlyAdded,
  });
}
