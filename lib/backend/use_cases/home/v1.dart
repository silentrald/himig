import "package:himig/backend/dtos/home_data.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/artist/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/services/source/types.dart";
import "package:himig/backend/use_cases/home/types.dart";
import "package:himig/state.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

class HomeUseCaseV1 extends HomeUseCase {
  final RepoDatabase _database;
  final AlbumRepo _albumRepo;
  final ArtistRepo _artistRepo;

  final AppState _appState;
  final SourceService _sourceService;

  HomeUseCaseV1({
    required this._database,
    required this._albumRepo,
    required this._artistRepo,
    required this._appState,
    required this._sourceService,
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

    final connectedResult = await getConnectedSources();
    if (connectedResult is ResultError) {
      return connectedResult.toError();
    }

    return Result.ok(
      HomeData(
        artists: artistResult.value,
        albums: albumResult.value,
        connectedSources: connectedResult.value,
      ),
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

  @override
  FutureResult<Map<int, bool>> getConnectedSources() async {
    final Map<int, bool> connectedSources = {};
    for (final source in _appState.sourceList) {
      final connectedResult = await _sourceService.isConnected(source);
      if (connectedResult is ResultError) {
        logger.warn(
          "Could not connect to source service due to an error",
          error: connectedResult.error,
        );
        connectedSources[source.id] = false;
        continue;
      }

      connectedSources[source.id] = connectedResult.value;
    }

    return Result.ok(connectedSources);
  }
}
