import "package:himig/backend/errors/multi_project_error.dart";
import "package:himig/backend/errors/project_error.dart";
import "package:himig/utils/result.dart";

class Song {
  int id;
  final String title;
  final String? albumName;
  final String? artistName;
  final Duration duration;

  /// For remote source - id
  /// For local source - path
  final String reference;

  final int? releaseYear;

  /// Reference to [Source]
  int? _localSourceId;
  Uri? _localUri;

  /// Reference to [Source]
  int? _remoteSourceId;
  Uri? _remoteUri;
  final Uri? coverArtUri;

  /// Reference to [Album]
  final int? albumId;

  /// Reference to [Artist]
  final int? artistId;

  Song({
    this.id = 0,
    required this.title,
    this.albumName,
    this.artistName,
    required this.duration,
    required this.reference,

    this.releaseYear,
    this._localSourceId,
    this._localUri,
    this._remoteSourceId,
    this._remoteUri,
    this.coverArtUri,
    this.albumId,
    this.artistId,
  });

  static ProjectError? validatePair(int? sourceId, Uri? uri, bool local) {
    if ((sourceId == null) ^ (uri == null)) {
      // Both should be null or not null
      return ProjectError(.entitySong, "pair", {
        "source": (.generic, local ? "local" : "remote"),
      });
    }
    return null;
  }

  static ProjectError? validateSources(
    int? localSourceId,
    Uri? localUri,
    int? remoteSourceId,
    Uri? remoteUri,
  ) {
    final localPair = localSourceId != null && localUri != null;
    final remotePair = remoteSourceId != null && remoteUri != null;

    if (!localPair && !remotePair) {
      return ProjectError(.entitySong, "sources");
    }

    return null;
  }

  static Result<Song> create({
    required String title,
    String? albumName,
    String? artistName,
    required Duration duration,
    required String reference,
    int? releaseYear,
    int? localSourceId,
    Uri? localUri,
    int? remoteSourceId,
    Uri? remoteUri,
    Uri? coverArtUri,
    int? albumId,
    int? artistId,
  }) {
    final List<ProjectError> errors = [
      ?validatePair(localSourceId, localUri, true),
      ?validatePair(remoteSourceId, remoteUri, false),
      ?validateSources(localSourceId, localUri, remoteSourceId, remoteUri),
    ];
    if (errors.isNotEmpty) {
      return Result.error(MultiProjectError(errors));
    }

    return Result.ok(
      Song(
        title: title,
        albumName: albumName,
        artistName: artistName,
        duration: duration,
        reference: reference,
        releaseYear: releaseYear,
        localSourceId: localSourceId,
        localUri: localUri,
        remoteSourceId: remoteSourceId,
        remoteUri: remoteUri,
        coverArtUri: coverArtUri,
        albumId: albumId,
        artistId: artistId,
      ),
    );
  }

  int? get localSourceId => _localSourceId;
  Uri? get localUri => _localUri;
  int? get remoteSourceId => _remoteSourceId;
  Uri? get remoteUri => _remoteUri;
  int get sourceId => _localSourceId ?? _remoteSourceId!;
  Uri get uri => _localUri ?? _remoteUri!;

  ProjectError? setLocal(int? sourceId, Uri? uri) {
    final error = validatePair(sourceId, uri, true);
    if (error == null) {
      _localSourceId = sourceId;
      _localUri = uri;
    }
    return error;
  }

  ProjectError? setRemote(int? sourceId, Uri? uri) {
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
