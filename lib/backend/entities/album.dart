import "package:himig/utils/result.dart";

enum AlbumSort { recentlyAdded, releaseYear }

class Album {
  int id;
  final String name;
  final int artistId;
  final String? artistName;

  final int? _localSourceId;
  final int? _remoteSourceId;

  /// For remote source - id
  /// For local source - path
  final String reference;

  final int? releaseYear;
  final Uri? coverArtUri;

  Album({
    this.id = 0,
    required this.name,
    this.artistId = 0,
    this.artistName,
    this._localSourceId,
    this._remoteSourceId,
    required this.reference,
    this.releaseYear,
    this.coverArtUri,
  });

  static String? validateSources(int? remoteSourceId, int? localSourceId) {
    if (localSourceId == null && remoteSourceId == null) {
      return "No sources found for album";
    }

    return null;
  }

  static Result<Album> create({
    int id = 0,
    required String name,
    int artistId = 0,
    String? artistName,
    int? localSourceId,
    int? remoteSourceId,
    required reference,
    int? releaseYear,
    Uri? coverArtUri,
  }) {
    final List<String> errors = [
      ?validateSources(localSourceId, remoteSourceId),
    ];

    if (errors.isNotEmpty) {
      return Result.error(Exception(errors.join(",")));
    }

    return Result.ok(
      Album(
        id: id,
        name: name,
        artistId: artistId,
        artistName: artistName,
        localSourceId: localSourceId,
        remoteSourceId: remoteSourceId,
        reference: reference,
        releaseYear: releaseYear,
        coverArtUri: coverArtUri,
      ),
    );
  }

  Album copyWith({
    int? id,
    String? name,
    int? artistId,
    String? artistName,
    int? localSourceId,
    int? remoteSourceId,
    String? reference,
    int? releaseYear,
    Uri? coverArtUri,
  }) => Album(
    id: id ?? this.id,
    name: name ?? this.name,
    artistId: artistId ?? this.artistId,
    artistName: artistName ?? this.artistName,
    localSourceId: localSourceId ?? _localSourceId,
    remoteSourceId: remoteSourceId ?? _remoteSourceId,
    reference: reference ?? this.reference,
    releaseYear: releaseYear ?? this.releaseYear,
    coverArtUri: coverArtUri ?? this.coverArtUri,
  );

  int? get localSourceId => _localSourceId;
  int? get remoteSourceId => _remoteSourceId;
  int get sourceId => _remoteSourceId ?? _localSourceId ?? 0;
}
