import "package:himig/utils/result.dart";

class Song {
  int id;
  final String title;
  final String? album;
  final String? artist;
  final int duration; // In seconds

  /// For remote source - id
  /// For local source - path
  final String reference;

  final int? releaseYear;

  int? _localSourceId;
  Uri? _localUri;
  int? _remoteSourceId;
  Uri? _remoteUri;
  final Uri? coverArtUri;

  /// Reference to the [Album] entity
  final int? albumId;

  Song({
    this.id = 0,
    required this.title,
    required this.album,
    required this.artist,
    required this.duration,
    required this.reference,

    this.releaseYear,
    int? localSourceId,
    Uri? localUri,
    int? remoteSourceId,
    Uri? remoteUri,
    this.coverArtUri,
    this.albumId,
  }) : _localSourceId = localSourceId,
       _localUri = localUri,
       _remoteSourceId = remoteSourceId,
       _remoteUri = remoteUri;

  static String? validatePair(int? sourceId, Uri? uri, bool local) {
    if ((sourceId == null) ^ (uri == null)) {
      // Both should be null or not null
      return "${local ? "Local" : "Remote"} pair is invalid for song";
    }
    return null;
  }

  static String? validateSources(
    int? localSourceId,
    Uri? localUri,
    int? remoteSourceId,
    Uri? remoteUri,
  ) {
    final localPair = localSourceId != null && localUri != null;
    final remotePair = remoteSourceId != null && remoteUri != null;

    if (!localPair && !remotePair) {
      return "No sources found for song";
    }

    return null;
  }

  static Result<Song> create({
    int id = 0,
    required String title,
    required String? album,
    required String? artist,
    required int duration,
    required String reference,
    int? releaseYear,
    int? localSourceId,
    Uri? localUri,
    int? remoteSourceId,
    Uri? remoteUri,
    Uri? coverArtUri,
    int? albumId,
  }) {
    final List<String> errors = [
      ?validatePair(localSourceId, localUri, true),
      ?validatePair(remoteSourceId, remoteUri, false),
      ?validateSources(localSourceId, localUri, remoteSourceId, remoteUri),
    ];
    if (errors.isNotEmpty) {
      return Result.error(Exception(errors.join(",")));
    }

    return Result.ok(
      Song(
        id: id,
        title: title,
        album: album,
        artist: artist,
        duration: duration,
        reference: reference,
        releaseYear: releaseYear,
        localSourceId: localSourceId,
        localUri: localUri,
        remoteSourceId: remoteSourceId,
        remoteUri: remoteUri,
        coverArtUri: coverArtUri,
        albumId: albumId,
      ),
    );
  }

  int? get localSourceId => _localSourceId;
  Uri? get localUri => _localUri;
  int? get remoteSourceId => _remoteSourceId;
  Uri? get remoteUri => _remoteUri;
  int get sourceId => _localSourceId ?? _remoteSourceId!;
  Uri get uri => _localUri ?? _remoteUri!;

  String? setLocal(int? sourceId, Uri? uri) {
    final error = validatePair(sourceId, uri, true);
    if (error == null) {
      _localSourceId = sourceId;
      _localUri = uri;
    }
    return error;
  }

  String? setRemote(int? sourceId, Uri? uri) {
    final error = validatePair(sourceId, uri, false);
    if (error == null) {
      _remoteSourceId = sourceId;
      _remoteUri = uri;
    }
    return error;
  }
}

class SimpleSong {
  final String title;
  final String? artist;
  final Uri? coverArtUri;
  final Duration? duration;

  SimpleSong({
    required this.title,
    this.artist,
    this.coverArtUri,
    this.duration,
  });
}
