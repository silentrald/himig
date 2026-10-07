import "dart:io";

import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/services/metadata/types.dart";
import "package:himig/backend/services/source/types.dart";
import "package:himig/locales/app_localizations.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart" as path_provider;

class FolderSourceImplementation extends SourceImplementation<FolderSource> {
  final AlbumRepo _albumRepo;
  final SongRepo _songRepo;
  final MetadataService _metadataService;

  FolderSourceImplementation({
    required this._albumRepo,
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

      // Key - artist:album
      final Map<String, int> albums = {};
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
        final artist =
            metadata.artist ??
            AppLocalizations.instance.app(.generic, "unknown");
        final album =
            metadata.album ??
            AppLocalizations.instance.app(.generic, "unknown");
        final key = "$artist-$album";

        int? albumId = albums[key];
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
              name: album,
              artist: artist,
              sourceId: source.id,
              reference: file.parent.path,
              releaseYear: metadata.releaseYear,
              coverArtUri: coverArtUri,
            ),
          );

          switch (albumIdResult) {
            case ResultError(:var error):
              logger.warn("Skipping $album. Reason ${error.toString()}");
            case ResultOk(:var value):
              albumId = value.id;
              albums[key] = value.id;
          }
        }

        final title =
            metadata.title ?? path.basenameWithoutExtension(file.path);
        final songResult = Song.create(
          title: title,
          album: album,
          artist: artist,
          duration: metadata.duration ?? 0,
          reference: file.path,
          releaseYear: metadata.releaseYear,
          localSourceId: source.id,
          localUri: Uri.file(file.path),
          coverArtUri: coverArtUri,
          albumId: albumId,
        );
        switch (songResult) {
          case ResultError(:var error):
            logger.warn(
              "Skipping $title of $album. Reason ${error.toString()}",
            );
          case ResultOk(:var value):
            _songRepo.insertSong(client, value);
        }
      }
      return Result.ok(albums.length);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Uri? getLocalSongUri(FolderSource source, Song song) {
    // TODO: file extension, get from song
    return Uri.file(
      path.join(source.path, song.artist, song.album, "${song.title}.flac"),
    );
  }
}
