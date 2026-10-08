enum AlbumSort { recentlyAdded, releaseYear }

class Album {
  int id;
  final String name;
  final int artistId;
  final String? artistName;
  final int sourceId;

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
    required this.sourceId,
    required this.reference,
    this.releaseYear,
    this.coverArtUri,
  });

  Album copyWith({
    int? id,
    String? name,
    int? artistId,
    String? artistName,
    int? sourceId,
    String? reference,
    int? releaseYear,
    Uri? coverArtUri,
  }) => Album(
    id: id ?? this.id,
    name: name ?? this.name,
    artistId: artistId ?? this.artistId,
    artistName: artistName ?? this.artistName,
    sourceId: sourceId ?? this.sourceId,
    reference: reference ?? this.reference,
    releaseYear: releaseYear ?? this.releaseYear,
    coverArtUri: coverArtUri ?? this.coverArtUri,
  );
}
