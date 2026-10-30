import "package:himig/backend/dtos/home_data.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/artist.dart";
import "package:himig/utils/result.dart";

abstract class HomeUseCase {
  FutureResult<HomeData> getInitialData({int count = 20});

  FutureResult<List<Artist>> getArtistList({int page = 1, int count = 20});

  FutureResult<List<Album>> getAlbumList({
    int page = 1,
    int count = 20,
    AlbumSort sort = AlbumSort.recentlyAdded,
  });

  FutureResult<Map<int, bool>> getConnectedSources();
}
