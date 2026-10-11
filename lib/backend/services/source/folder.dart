import "dart:io";

import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/artist/types.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/services/metadata/types.dart";
import "package:himig/backend/services/source/types.dart";
import "package:himig/locales/app_localizations.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart" as path_provider;

// TODO: Collission checking
// Batch loading logs
class FolderSourceImplementation extends SourceImplementation<FolderSource> {
  final AlbumRepo _albumRepo;
  final ArtistRepo _artistRepo;
  final SongRepo _songRepo;
  final MetadataService _metadataService;

  FolderSourceImplementation({
    required this._albumRepo,
    required this._artistRepo,
    required this._songRepo,
    required this._metadataService,
  });

  Future<List<FileSystemEntity>> _listSafe(Directory directory) async {
    return directory.list(recursive: true, followLinks: false).handleError((
      error,
    ) {
      logger.error("Error in listing directory", error: error);
    }).toList();
  }

  @override
  Future<Result<int>> scanSource(FolderSource source, RepoClient client) async {
    try {
      final directory = Directory(source.path);
      final entities = await _listSafe(directory);
      if (entities.isEmpty) {
        return Result.ok(0);
      }

      final temporaryDirectory = await path_provider.getTemporaryDirectory();

      final mapResult = await _artistRepo.getArtistMap(client);
      if (mapResult is ResultError) {
        return mapResult.toError();
      }

      // Key - artist:album
      final Map<String, int> albumMap = {};
      final Map<String, int> artistMap = mapResult.value;
      int? albumId;
      int? artistId;

      // Scans the first song in the album, and uses that for all songs.
      // Although this is a bug since the song can have different cover art.
      Uri? coverArtUri;
      for (final file in entities) {
        if (file is! File) {
          continue;
        }

        final result = await _metadataService.getAudioMetadata(file);
        if (result is ResultError) {
          logger.error("Could not parse metadata", error: result.error);
          continue;
        }

        final metadata = result.value;
        final artistName =
            metadata.artist ??
            AppLocalizations.instance.app(.generic, "unknown");
        final albumName =
            metadata.album ??
            AppLocalizations.instance.app(.generic, "unknown");
        final key = "$artistName-$albumName";

        artistId = artistMap[artistName];
        if (artistId == null) {
          final artistResult = await _artistRepo.insertArtist(
            client,
            Artist(
              name: artistName,
              //imageUri: None,
            ),
          );
          if (artistResult is ResultError) {
            // TODO: if album fails to be inserted, create a fail queue
            logger.warn("Skipping $albumName. Reason ${artistResult.error}");
            continue;
          }

          artistId = artistResult.value.id;
          artistMap[artistName] = artistId;
        }

        albumId = albumMap[key];
        if (albumId == null) {
          coverArtUri = null;

          // TODO: Check if any image exists in the folder as a backup as well
          if (metadata.image != null) {
            final imagePath = "${temporaryDirectory.path}/$key";
            final imageFile = File("${temporaryDirectory.path}/$key");
            final exists = await imageFile.exists();
            if (!exists) {
              await imageFile.writeAsBytes(metadata.image!);
            }
            coverArtUri = Uri.file(imagePath);
          }

          final albumIdResult = await _albumRepo.insertAlbum(
            client,
            Album(
              name: albumName,
              artistId: artistId,
              localSourceId: source.id,
              reference: file.parent.path,
              releaseYear: metadata.releaseYear,
              coverArtUri: coverArtUri,
            ),
          );

          if (albumIdResult is ResultError) {
            logger.warn("Skipping $albumName. Reason ${albumIdResult.error}");
            continue;
          }

          albumId = albumIdResult.value.id;
          albumMap[key] = albumId;
        }

        final title =
            metadata.title ?? path.basenameWithoutExtension(file.path);
        final songResult = Song.create(
          title: title,
          duration: metadata.duration?.inSeconds ?? 0,
          reference: file.path,
          releaseYear: metadata.releaseYear,
          localSourceId: source.id,
          localUri: Uri.file(file.path),
          coverArtUri: coverArtUri,
          albumId: albumId,
          artistId: artistId,
        );
        switch (songResult) {
          case ResultError(:var error):
            logger.warn(
              "Skipping $title of $albumName. Reason ${error.toString()}",
            );
          case ResultOk(:var value):
            _songRepo.insertSong(client, value);
        }
      }
      return Result.ok(albumMap.length);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Uri? getLocalSongUri(FolderSource source, Song song) {
    // TODO: file extension, get from song
    return Uri.file(
      path.join(
        source.path,
        song.artistName,
        song.albumName,
        "${song.title}.flac",
      ),
    );
  }

  @override
  FutureResult<bool> isConnected(FolderSource source) async => Result.ok(true);
}
