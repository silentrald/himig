enum AlbumSort { recentlyAdded, releaseYear }

class Album {
  int id;
  final String name;
  final String? artist;
  final int sourceId;

  /// For remote source - id
  /// For local source - path
  final String reference;

  final int? releaseYear;
  final Uri? coverArtUri;

  Album({
    this.id = 0,
    required this.name,
    this.artist,
    required this.sourceId,
    required this.reference,
    this.releaseYear,
    this.coverArtUri,
  });
}
