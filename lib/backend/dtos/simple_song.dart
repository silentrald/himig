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
