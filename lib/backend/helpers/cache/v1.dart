import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/backend/errors/project_error.dart";
import "package:himig/backend/helpers/cache/types.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/services/fetch/types.dart";
import "package:himig/backend/services/source/types.dart";
import "package:himig/state.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

class CacheHelperV1 extends CacheHelper {
  final AppState _appState;
  final RepoDatabase _database;
  final SongRepo _songRepo;
  final FetchService _fetchService;
  final SourceService _sourceService;

  CacheHelperV1({
    required this._appState,
    required this._database,
    required this._songRepo,
    required this._fetchService,
    required this._sourceService,
  });

  FutureResult<void> _downloadSong(
    RepoClient client,
    Song song,
    Source localSource,
  ) async {
    if (song.remoteUri == null) {
      return Result.ok(null);
    }

    final request = FetchRequest(song.remoteUri!);
    final filepath = _sourceService.getLocalSongUri(localSource, song);
    if (filepath == null) {
      return Result.error(
        ProjectError(.serviceSource, "noLocalSourceUri", {
          "name": (null, localSource.name),
        }),
      );
    }
    final downloadResult = await _fetchService.download(
      request,
      filepath.toFilePath(),
      progress: (count, total) {
        logger.info("Download Progress: ${count / total * 100}%");
      },
    );
    if (downloadResult is ResultError) {
      logger.error(
        "Could not download song ${song.title}. Reason: ${downloadResult.error.toString()}",
      );
      return Result.ok(null);
    }

    song.setLocal(localSource.id, filepath);
    final songResult = await _songRepo.updateSong(client, song);
    switch (songResult) {
      case ResultError(:var error):
        logger.error(
          "Could not cache song ${song.title}. Reason: ${error.toString()}.",
        );
      case ResultOk():
        logger.info("Cached song ${song.title}.");
    }

    return Result.ok(null);
  }

  @override
  FutureResult<void> cacheArtist(int artistId) async {
    return await _database.startTransaction((client) async {
      final songsResult = await _songRepo.getSongListByArtist(client, artistId);
      if (songsResult is ResultError) {
        return songsResult.toError();
      }

      // Check if all the sources available have remoteSources
      final sourceIds = songsResult.value
          .where((song) => song.localSourceId == null)
          .map((song) => song.remoteSourceId!)
          .toSet()
          .toList(); // Removes duplicate
      final Set<int> skipSourceIds = {};

      for (final id in sourceIds) {
        final remoteSource = _appState.getSource(id);
        if (remoteSource.localSourceId == null) {
          logger.warn("No local cache attached to ${remoteSource.name}");
          skipSourceIds.add(id);
        }
      }

      if (sourceIds.length == skipSourceIds.length) {
        return Result.error(ProjectError(.serviceSource, "noLocalSources"));
      }

      for (final song in songsResult.value) {
        if (skipSourceIds.contains(song.remoteSourceId)) {
          continue;
        }

        final remoteSource = _appState.getSource(song.remoteSourceId!);
        final localSource = _appState.getSource(remoteSource.localSourceId!);
        final result = await _downloadSong(client, song, localSource);
        if (result is ResultError) {
          return result.toError();
        }
      }

      return Result.ok(null);
    });
  }

  @override
  FutureResult<void> cacheAlbum(Album album) async {
    final remoteSource = _appState.getSource(album.sourceId);
    if (remoteSource.localSourceId == null) {
      return Result.error(
        ProjectError(.serviceSource, "noLocalSource", {
          "name": (null, remoteSource.name),
        }),
      );
    }

    final localSource = _appState.getSource(remoteSource.localSourceId!);

    return await _database.startTransaction((client) async {
      final songsResult = await _songRepo.getSongListByAlbum(client, album.id);
      if (songsResult is ResultError) {
        return songsResult.toError();
      }

      for (final song in songsResult.value) {
        final result = await _downloadSong(client, song, localSource);
        if (result is ResultError) {
          return result.toError();
        }
      }

      return Result.ok(null);
    });
  }
}
