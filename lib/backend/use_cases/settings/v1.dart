import "package:himig/backend/entities/source.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/repo.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/source/types.dart";
import "package:himig/backend/services/source/types.dart";
import "package:himig/backend/use_cases/settings/types.dart";
import "package:himig/state.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

class SettingsUseCaseV1 extends SettingsUseCase {
  final RepoDatabase _database;
  final SourceRepo _sourceRepo;
  final AlbumRepo _albumRepo;
  final SongRepo _songRepo;
  final SourceService _sourceService;

  SettingsUseCaseV1({
    required RepoDatabase database,
    required SourceRepo sourceRepo,
    required AlbumRepo albumRepo,
    required SongRepo songRepo,
    required SourceService sourceService,
  }) : _database = database,
       _sourceRepo = sourceRepo,
       _albumRepo = albumRepo,
       _songRepo = songRepo,
       _sourceService = sourceService;

  @override
  Future<Result<void>> loadSources() async {
    final result = await _sourceRepo.getAllSources(_database.client);
    switch (result) {
      case ResultError(:var error):
        return Result.error(error);

      case ResultOk(:var value):
        AppState().addSourceList(value);
        return Result.ok(null);
    }
  }

  @override
  Future<Result<void>> addSource(Source source) async {
    final result = await _sourceRepo.insertSource(_database.client, source);
    switch (result) {
      case ResultError(:var error):
        return Result.error(error);

      case ResultOk(:var value):
        AppState().addSource(value);
        return Result.ok(null);
    }
  }

  @override
  Future<Result<void>> editSource(Source source) async {
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
      final albumResult = await _albumRepo.deleteAllAlbums(client);
      if (albumResult is ResultError) {
        return Result.error(albumResult.error);
      }

      final songResult = await _songRepo.deleteAllSongs(client);
      if (songResult is ResultError) {
        return Result.error(songResult.error);
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
