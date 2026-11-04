import "dart:io";

import "package:himig/backend/dtos/audio_metadata.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/artist/types.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/services/metadata/types.dart";
import "package:himig/backend/services/source/shared_v1.dart";
import "package:himig/backend/services/source/types.dart";
import "package:himig/locales/app_localizations.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart" as path_provider;

// TODO: Future implementation, use Isolates/multithreading
class FolderSourceImplementation extends SourceImplementation<FolderSource> {
  final RepoDatabase _repoDatabase;
  final AlbumRepo _albumRepo;
  final ArtistRepo _artistRepo;
  final SongRepo _songRepo;
  final MetadataService _metadataService;

  FolderSourceImplementation({
    required this._repoDatabase,
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
  FutureResult<int> scanSource(FolderSource source) async {
    logger.info("Scanning with folder (${source.name})");

    try {
      final directory = Directory(source.path);
      final entities = await _listSafe(directory);
      if (entities.isEmpty) {
        return Result.ok(0);
      }

      final temporaryDirectory = await path_provider.getTemporaryDirectory();

      final countResult = await _albumRepo.countAlbums(_repoDatabase.client);
      if (countResult is ResultError) {
        return countResult.toError();
      }

      // Key - artist:album
      int? artistId;

      // Scans the first song in the album, and uses that for all songs.
      // Although this is a bug since the song can have different cover art.
      Uri? coverArtUri;
      for (final file in entities) {
        if (file is! File) {
          continue;
        }

        final metadataResult = await _metadataService.getAudioMetadata(file);
        if (metadataResult is ResultError) {
          logger.error("Could not parse metadata", error: metadataResult.error);
          continue;
        }

        final metadata = metadataResult.value;
        final artistName =
            metadata.artist ??
            AppLocalizations.instance.translate(.generic, "unknown");
        final albumName =
            metadata.album ??
            AppLocalizations.instance.translate(.generic, "unknown");
        final songTitle =
            metadata.title ?? path.basenameWithoutExtension(file.path);
        final localUri = Uri.file(file.path);

        final result = await _repoDatabase.startTransaction((client) async {
          final artistResult = await _getOrInsertArtist(
            client,
            source,
            artistName: artistName,
            albumName: albumName,
          );
          if (artistResult is ResultError) {
            return artistResult.toError();
          }

          final albumResult = await _upsertAlbum(
            client,
            source,
            artistId: artistResult.value,
            artistName: artistName,
            albumName: albumName,
            metadata: metadata,
            parentFolder: file.parent.path,
            temporaryPath: temporaryDirectory.path,
          );
          if (albumResult is ResultError) {
            return albumResult.toError();
          }
          int albumId = albumResult.value.id;

          final songResult = await _songRepo.findSongByNames(
            client,
            songTitle,
            albumName,
            artistName,
          );
          if (songResult is ResultError) {
            return songResult.toError();
          }

          if (songResult.value != null) {
            final updated = await updateExistingSongLocal(
              client,
              _songRepo,
              songResult.value!,
              source.id,
              localUri,
            );
            if (updated) {
              return Result.ok(null);
            }
            // If the song was not updated, create a new one instead
          }

          final createResult = Song.create(
            title: songTitle,
            duration: metadata.duration ?? Duration.zero,
            fileExtension: path.extension(file.path),
            reference: file.path,
            releaseYear: metadata.releaseYear,
            localSourceId: source.id,
            localUri: localUri,
            coverArtUri: coverArtUri,
            albumId: albumId,
            artistId: artistId,
          );
          if (createResult is ResultError) {
            return createResult.toError();
          }

          final newSong = createResult.value;
          return await _songRepo.insertSong(client, newSong);
        });

        if (result is ResultError) {
          logger.warn(
            "Could not insert '$songTitle' by '$artistName' from album '$albumName'",
            error: result.error,
          );
        } else {
          logger.info(
            "Inserted '$songTitle' by '$artistName' from album '$albumName'",
          );
        }
      }

      final finalCountResult = await _albumRepo.countAlbums(
        _repoDatabase.client,
      );
      if (finalCountResult is ResultError) {
        logger.warn(
          "Could not get the final count for albums",
          error: finalCountResult.error,
        );
        return Result.ok(0);
      }

      return Result.ok(finalCountResult.value - countResult.value);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  FutureResult<int> _getOrInsertArtist(
    RepoClient client,
    FolderSource source, {
    required String artistName,
    required String albumName,
  }) async {
    final findResult = await _artistRepo.findArtistByName(client, artistName);
    if (findResult is ResultError) {
      return findResult.toError();
    }

    if (findResult.value != null) {
      return Result.ok(findResult.value!.id);
    }

    final insertResult = await _artistRepo.insertArtist(
      client,
      Artist(
        name: artistName,
        // TODO: Might need to get this from MusicBrainz and get it from their socials
        //imageUri: None,
      ),
    );
    if (insertResult is ResultError) {
      return insertResult.toError();
    }

    return Result.ok(insertResult.value.id);
  }

  FutureResult<Album> _upsertAlbum(
    RepoClient client,
    FolderSource source, {
    required int artistId,
    required String artistName,
    required String albumName,
    required AudioMetadataDto metadata,
    required String parentFolder,
    required String temporaryPath,
  }) async {
    final findResult = await _albumRepo.findAlbumByNames(
      client,
      albumName,
      artistName,
    );
    if (findResult is ResultError) {
      return findResult.toError();
    }

    if (findResult.value == null) {
      Uri? coverArtUri;

      // TODO: Check if any image exists in the folder as a backup as well
      if (metadata.image != null) {
        final key = "$artistName-$albumName";
        final imagePath = "$temporaryPath/$key";
        final imageFile = File("$temporaryPath/$key");
        final exists = await imageFile.exists();
        if (!exists) {
          await imageFile.writeAsBytes(metadata.image!);
        }
        coverArtUri = Uri.file(imagePath);
      }

      final insertResult = await _albumRepo.insertAlbum(
        client,
        Album(
          name: albumName,
          artistId: artistId,
          localSourceId: source.id,
          localPath: parentFolder,
          releaseYear: metadata.releaseYear,
          coverArtUri: coverArtUri,
        ),
      );

      if (insertResult is ResultError) {
        return insertResult.toError();
      }

      return Result.ok(insertResult.value);
    }

    final existingAlbum = findResult.value!;
    if (existingAlbum.localPath != null) {
      if (existingAlbum.localPath == parentFolder) {
        return Result.ok(existingAlbum);
      }

      return Result.error(
        Exception("Album $albumName already has a local path"),
      );
    }

    final error = existingAlbum.setLocal(source.id, parentFolder);
    if (error != null) {
      return Result.error(error);
    }

    return await _albumRepo.updateAlbum(client, existingAlbum);
  }

  @override
  Uri? getLocalSongUri(FolderSource source, Song song) {
    return Uri.file(
      path.join(
        source.path,
        song.artistName,
        song.albumName,
        "${song.title}.${song.fileExtension}",
      ),
    );
  }

  @override
  FutureResult<bool> isConnected(FolderSource source) async => Result.ok(true);
}
