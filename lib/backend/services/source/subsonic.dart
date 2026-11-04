import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/artist/types.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/services/fetch/types.dart";
import "package:himig/backend/services/source/shared_v1.dart";
import "package:himig/backend/services/source/types.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

const albumBatch = 500;

// TODO: Future implementation, use Isolates/multithreading
class SubsonicSourceImplementation
    extends SourceImplementation<SubsonicSource> {
  final RepoDatabase _repoDatabase;
  final AlbumRepo _albumRepo;
  final ArtistRepo _artistRepo;
  final SongRepo _songRepo;
  final FetchService _fetchService;

  SubsonicSourceImplementation({
    required this._repoDatabase,
    required this._albumRepo,
    required this._artistRepo,
    required this._songRepo,
    required this._fetchService,
  });

  @override
  Future<Result<int>> scanSource(SubsonicSource source) async {
    logger.info("Scanning with subsonic api (${source.name})");

    int fullCount = 0;
    int currentCount = 0;
    do {
      final result = await _scanAlbums(source, fullCount, albumBatch);
      if (result is ResultError) {
        return result.toError();
      }

      currentCount = result.value;
      fullCount += result.value;
    } while (currentCount == albumBatch);

    return Result.ok(fullCount);
  }

  FutureResult<int> _scanAlbums(
    SubsonicSource source,
    int offset,
    int batch,
  ) async {
    final request = FetchRequest(
      source.getUri("/rest/getAlbumList", {
        "type": "alphabeticalByName",
        "offset": offset.toString(),
        "size": batch.toString(),
      }),
    );
    final result = await _fetchService.getJson(request);
    if (result is ResultError) {
      return Result.error(result.error);
    }

    final json = result.value.data!;
    final albumList = json["subsonic-response"]["albumList"]["album"];
    var albumCount = albumList.length;
    if (albumCount == 0) {
      return Result.ok(0);
    }

    for (final albumJson in albumList) {
      final albumName = (albumJson["name"] ?? "unknown").trim();
      final artistName = albumJson["artist"];

      final result = await _repoDatabase.startTransaction((client) async {
        final artistResult = await _getOrInsertArtist(
          client,
          source,
          artistName: artistName,
          albumName: albumName,
          remoteId: albumJson["parent"],
        );
        if (artistResult is ResultError) {
          return artistResult.toError();
        }

        final albumResult = await _upsertAlbum(
          client,
          source,
          albumJson: albumJson,
          artistId: artistResult.value,
          artistName: artistName,
          albumName: albumName,
        );
        if (albumResult is ResultError) {
          return albumResult.toError();
        }

        return await _insertSongs(source, client, albumResult.value);
      });

      switch (result) {
        case ResultOk():
          logger.info("Inserted album '$albumName' by '$artistName'");
        case ResultError(:var error):
          logger.warn(
            "Could not insert album '$albumName' by '$artistName'",
            error: error,
          );
      }
    }

    return Result.ok(albumCount);
  }

  FutureResult<int> _getOrInsertArtist(
    RepoClient client,
    SubsonicSource source, {
    required String artistName,
    required String albumName,
    required String remoteId,
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
        imageUri: source.getUri("/rest/getCoverArt", {"id": remoteId}),
      ),
    );
    if (insertResult is ResultError) {
      return insertResult.toError();
    }

    return Result.ok(insertResult.value.id);
  }

  FutureResult<Album> _upsertAlbum(
    RepoClient client,
    SubsonicSource source, {
    required Map<String, dynamic> albumJson,
    required int artistId,
    required String artistName,
    required String albumName,
  }) async {
    final findResult = await _albumRepo.findAlbumByNames(
      client,
      albumName,
      artistName,
    );
    if (findResult is ResultError) {
      return findResult.toError();
    }

    final remoteId = albumJson["id"];

    if (findResult.value == null) {
      final album = Album(
        name: albumName,
        artistId: artistId,
        remoteSourceId: source.id,
        remoteId: remoteId,
        releaseYear: albumJson["year"],
        coverArtUri: source.getUri("/rest/getCoverArt", {
          "id": albumJson["coverArt"],
        }),
      );

      // Insert album
      final insertResult = await _albumRepo.insertAlbum(client, album);
      if (insertResult is ResultError) {
        return insertResult.toError();
      }

      return Result.ok(insertResult.value);
    }

    final existingAlbum = findResult.value!;
    if (existingAlbum.remoteId != null) {
      return Result.error(
        Exception("Album $albumName already has a remote id"),
      );
    }

    final error = existingAlbum.setRemote(source.id, remoteId);
    if (error != null) {
      return Result.error(error);
    }

    return await _albumRepo.updateAlbum(client, existingAlbum);
  }

  FutureResult<void> _insertSongs(
    SubsonicSource source,
    RepoClient client,
    Album album,
  ) async {
    final request = FetchRequest(
      source.getUri("/rest/getAlbum", {"id": album.remoteId!}),
    );
    final result = await _fetchService.getJson(request);
    if (result is ResultError) {
      return result.toError();
    }

    final json = result.value.data!;
    final subsonicAlbum = json["subsonic-response"]["album"];

    for (var song in subsonicAlbum["song"]) {
      final id = song["id"];
      final songTitle = song["title"];
      final remoteUri = source.getUri("/rest/stream", {"id": id});

      final songResult = await _songRepo.findSongByNames(
        client,
        songTitle,
        album.name,
        album.artistName,
      );
      if (songResult is ResultError) {
        // Fails the full album if 1 song is erring
        return songResult.toError();
      }

      if (songResult.value != null) {
        final updated = await updateExistingSongRemote(
          client,
          _songRepo,
          songResult.value!,
          source.id,
          remoteUri,
        );
        if (updated) {
          continue;
        }
      }

      final createResult = Song.create(
        title: songTitle,
        // Subsonic returns duration in seconds
        duration: Duration(seconds: song["duration"]),
        fileExtension: song["suffix"],
        reference: id,
        releaseYear: song["year"],
        remoteSourceId: source.id,
        remoteUri: remoteUri,
        coverArtUri: source.getUri("/rest/getCoverArt", {
          "id": song["coverArt"],
        }),
        albumId: album.id,
        artistId: album.artistId,
      );
      if (createResult is ResultError) {
        logger.warn(
          "Skipping '${album.name}' '${song["title"]}'. Reason ${createResult.error.toString()}",
        );
        continue;
      }

      final insertSongResult = await _songRepo.insertSong(
        client,
        createResult.value,
      );
      if (insertSongResult is ResultError) {
        logger.warn(
          "Skipping '${album.name}' '${song["title"]}'",
          error: insertSongResult.error,
        );
        continue;
      }

      logger.info("Inserted '${album.name}' '$songTitle'");
    }

    return Result.ok(null);
  }

  @override
  Uri? getLocalSongUri(SubsonicSource source, Song song) {
    return null;
  }

  @override
  FutureResult<bool> isConnected(SubsonicSource source) async {
    final request = FetchRequest(source.getUri("/rest/ping"));
    final pingResult = await _fetchService.getJson(request);
    if (pingResult is ResultError) {
      return Result.ok(false);
    }

    final status = pingResult.value.data?["subsonic-response"]["status"];
    return Result.ok(status == "ok");
  }
}
