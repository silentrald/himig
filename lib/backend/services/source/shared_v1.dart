import "package:himig/backend/entities/song.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

/// @returns - true if the song was updated, else false
Future<bool> updateExistingSongLocal(
  RepoClient client,
  SongRepo songRepo,
  Song song,
  int sourceId,
  Uri uri,
) => _updateExistingSong(client, songRepo, song, sourceId, uri, true);

/// @returns - true if the song was updated, else false
Future<bool> updateExistingSongRemote(
  RepoClient client,
  SongRepo songRepo,
  Song song,
  int sourceId,
  Uri uri,
) => _updateExistingSong(client, songRepo, song, sourceId, uri, false);

/// @returns - true if the song was updated, else false
Future<bool> _updateExistingSong(
  RepoClient client,
  SongRepo songRepo,
  Song song,
  int sourceId,
  Uri uri,
  bool local,
) async {
  final error = local
      ? song.setLocal(sourceId, uri)
      : song.setRemote(sourceId, uri);
  if (error != null) {
    logger.warn(
      "Could not set local value $sourceId:$uri, skipping song ${song.title}",
    );
    return true;
  }

  final updateResult = await songRepo.updateSong(client, song);
  if (updateResult is ResultError) {
    logger.warn(
      "Could not get song from database, trying to create the song again",
      error: updateResult.error,
    );
  }
  return true;
}
