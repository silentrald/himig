import "package:himig/backend/dtos/home_data.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/artist/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/use_cases/home/types.dart";
import "package:himig/utils/result.dart";

class HomeUseCaseV1 extends HomeUseCase {
  final RepoDatabase _database;
  final AlbumRepo _albumRepo;
  final ArtistRepo _artistRepo;

  HomeUseCaseV1({
    required this._database,
    required this._albumRepo,
    required this._artistRepo,
  });

  @override
  FutureResult<HomeData> getInitialData({int count = 20}) async {
    final albumResult = await getAlbumList(count: count);
    if (albumResult is ResultError) {
      return albumResult.toError();
    }

    final artistResult = await getArtistList(count: count);
    if (artistResult is ResultError) {
      return artistResult.toError();
    }

    // TODO: get the _connectedSources data here

    return Result.ok(
      HomeData(artists: artistResult.value, albums: albumResult.value),
    );
  }

  @override
  FutureResult<List<Artist>> getArtistList({int page = 1, int count = 20}) =>
      _artistRepo.getArtistList(_database.client, page: page, count: count);

  @override
  FutureResult<List<Album>> getAlbumList({
    int page = 1,
    int count = 20,
    AlbumSort sort = AlbumSort.recentlyAdded,
  }) => _albumRepo.getAlbumList(
    _database.client,
    page: page,
    count: count,
    sort: sort,
  );
}
