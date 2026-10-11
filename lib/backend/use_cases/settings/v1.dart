import "package:himig/backend/entities/source.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/artist/types.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/source/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/services/source/types.dart";
import "package:himig/backend/use_cases/settings/types.dart";
import "package:himig/state.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

class SettingsUseCaseV1 extends SettingsUseCase {
  final RepoDatabase _database;
  final SourceRepo _sourceRepo;
  final AlbumRepo _albumRepo;
  final ArtistRepo _artistRepo;
  final SongRepo _songRepo;
  final SourceService _sourceService;

  SettingsUseCaseV1({
    required this._database,
    required this._sourceRepo,
    required this._albumRepo,
    required this._artistRepo,
    required this._songRepo,
    required this._sourceService,
  });

  Future<Result<void>> _validateSource(Source source) async {
    final connectedResult = await _sourceService.isConnected(source);
    if (connectedResult is ResultError) {
      return connectedResult.toError();
    }

    if (!connectedResult.value) {
      return Result.error(Exception("Could not connect to ${source.name}"));
    }

    return Result.ok(null);
  }

  @override
  Future<Result<void>> addSource(Source source) async {
    final validateResult = _validateSource(source);
    if (validateResult is ResultError) {
      return validateResult;
    }

    final result = await _sourceRepo.insertSource(_database.client, source);
    if (result is ResultError) {
      return result.toError();
    }

    AppState().addSource(result.value);
    return Result.ok(null);
  }

  @override
  Future<Result<void>> editSource(Source source) async {
    final validateResult = _validateSource(source);
    if (validateResult is ResultError) {
      return validateResult;
    }

    final result = await _sourceRepo.updateSource(_database.client, source);
    switch (result) {
      case ResultError(:var error):
        return Result.error(error);

      case ResultOk(:var value):
        AppState().updateSource(value);
        return Result.ok(null);
    }
  }

  @override
  Future<Result<int>> scanSources() async {
    return await _database.startTransaction((client) async {
      final artistResult = await _artistRepo.deleteAllArtists(client);
      if (artistResult is ResultError) {
        return artistResult.toError();
      }

      final albumResult = await _albumRepo.deleteAllAlbums(client);
      if (albumResult is ResultError) {
        return albumResult.toError();
      }

      final songResult = await _songRepo.deleteAllSongs(client);
      if (songResult is ResultError) {
        return songResult.toError();
      }

      int count = 0;
      for (final source in AppState().sourceList) {
        final result = await _sourceService.scanSource(source, client);
        switch (result) {
          case ResultOk(:var value):
            count += value;
          case ResultError(:var error):
            logger.warn(
              "Could not scan source ${source.id}:${source.name}, Reason ${error.toString()}",
            );
        }
      }

      return Result.ok(count);
    });
  }
}
