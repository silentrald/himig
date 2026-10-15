import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/artist/types.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/services/fetch/types.dart";
import "package:himig/backend/services/source/types.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/result.dart";

// TODO: Collision checking
class SubsonicSourceImplementation
    extends SourceImplementation<SubsonicSource> {
  final AlbumRepo _albumRepo;
  final ArtistRepo _artistRepo;
  final SongRepo _songRepo;
  final FetchService _fetchService;

  SubsonicSourceImplementation({
    required this._albumRepo,
    required this._artistRepo,
    required this._songRepo,
    required this._fetchService,
  });

  @override
  Future<Result<int>> scanSource(
    SubsonicSource source,
    RepoClient client,
  ) async {
    // TODO: Pagination logic, use a producer/consumer
    final request = FetchRequest(
      // TODO: Type can be enumerized, check https://www.subsonic.org/pages/api.jsp#getAlbumList
      source.getUri("/rest/getAlbumList", {
        "f": "json",
        "type": "alphabeticalByName",
        "size": "500",
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

    final mapResult = await _artistRepo.getArtistMap(client);
    if (mapResult is ResultError) {
      return mapResult.toError();
    }

    final Map<String, int> artistMap = mapResult.value;
    int? artistId;

    // TODO: Album/Song queuing, to do it in a background even if the app is closed
    for (final albumJson in albumList) {
      final albumName = (albumJson["name"] ?? "unknown").trim();
      final artistName = albumJson["artist"];

      artistId = artistMap[artistName];
      if (artistId == null) {
        final artistResult = await _artistRepo.insertArtist(
          client,
          Artist(
            name: artistName,
            imageUri: source.getUri("/rest/getCoverArt", {
              "id": albumJson["parent"],
            }),
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

      final album = Album(
        name: albumName,
        artistId: artistId,
        remoteSourceId: source.id,
        reference: albumJson["id"],
        releaseYear: albumJson["year"],
        coverArtUri: source.getUri("/rest/getCoverArt", {
          "id": albumJson["coverArt"],
        }),
      );

      final albumResult = await _insertAlbumAndSongs(source, client, album);
      switch (albumResult) {
        case ResultOk():
          logger.info("Inserted ${album.name} with songs");
        case ResultError(:var error):
          // TODO: if album fails to be inserted, create a fail queue
          logger.warn("Skipping $albumName. Reason $error");
      }
    }

    return Result.ok(albumCount);
  }

  Future<Result<void>> _insertAlbumAndSongs(
    SubsonicSource source,
    RepoClient client,
    Album album,
  ) async {
    // Insert album
    switch (await _albumRepo.insertAlbum(client, album)) {
      case ResultError(:var error):
        return Result.error(error);
      case ResultOk(:var value):
        album = value;
    }

    // Insert songs
    final request = FetchRequest(
      source.getUri("/rest/getAlbum", {"f": "json", "id": album.reference}),
    );
    final result = await _fetchService.getJson(request);
    if (result is ResultError) {
      return Result.error(result.error);
    }

    final json = result.value.data!;
    final subsonicAlbum = json["subsonic-response"]["album"];

    for (var song in subsonicAlbum["song"]) {
      final id = song["id"];
      final createResult = Song.create(
        title: song["title"],
        // Subsonic returns duration in seconds
        duration: Duration(seconds: song["duration"]),
        reference: id,
        releaseYear: song["year"],
        remoteSourceId: source.id,
        remoteUri: source.getUri("/rest/stream", {"id": id}),
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

      final songResult = await _songRepo.insertSong(client, createResult.value);
      switch (songResult) {
        case ResultError(:var error):
          logger.warn(
            "Skipping '${album.name}' '${song["title"]}'. Reason ${error.toString()}",
          );
        case ResultOk(:var value):
          logger.info("Inserted '${album.name}' '${value.title}'");
      }
    }

    return Result.ok(null);
  }

  @override
  Uri? getLocalSongUri(SubsonicSource source, Song song) {
    return null;
  }

  @override
  FutureResult<bool> isConnected(SubsonicSource source) async {
    final request = FetchRequest(source.getUri("/rest/ping", {"f": "json"}));
    final pingResult = await _fetchService.getJson(request);
    if (pingResult is ResultError) {
      return Result.ok(false);
    }

    final status = pingResult.value.data?["subsonic-response"]["status"];
    return Result.ok(status == "ok");
  }
}
