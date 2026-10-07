import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/services/fetch/types.dart";
import "package:himig/backend/services/source/types.dart";
import "package:himig/backend/use_cases/album/types.dart";
import "package:himig/state.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

class AlbumUseCaseV1 extends AlbumUseCase {
  final RepoDatabase _database;
  final SongRepo _songRepo;
  final FetchService _fetchService;
  final SourceService _sourceService;

  AlbumUseCaseV1({
    required this._database,
    required this._songRepo,
    required this._fetchService,
    required this._sourceService,
  });

  @override
  Future<Result<List<Song>>> getSongsByAlbum(int albumId) {
    return _songRepo.getSongsByAlbum(_database.client, albumId);
  }

  @override
  Future<Result<void>> cacheAlbumSongs(Album album) async {
    final remoteSource = AppState().getSource(album.sourceId);
    if (remoteSource.localSourceId == null) {
      return Result.error(
        Exception("No local cache attached to ${remoteSource.name}."),
      );
    }

    final localSource = AppState().getSource(remoteSource.localSourceId!);

    return await _database.startTransaction((client) async {
      final songsResult = await _songRepo.getSongsByAlbum(client, album.id);
      if (songsResult is ResultError) {
        return Result.error(songsResult.error);
      }

      for (final song in (songsResult as ResultOk<List<Song>>).value) {
        if (song.remoteUri == null) {
          continue;
        }

        final request = FetchRequest(song.remoteUri!);
        final filepath = _sourceService.getLocalSongUri(localSource, song);
        if (filepath == null) {
          return Result.error(
            Exception(
              "Could not get a local source uri with ${localSource.name}.",
            ),
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
          continue;
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
      }

      return Result.ok(null);
    });
  }
}
