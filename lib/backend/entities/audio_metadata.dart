import "package:flutter/foundation.dart";

class AudioMetadata {
  final String? title;
  final String? album;
  final String? artist;
  final int? releaseYear;
  final Duration? duration;
  final Uint8List? image;

  AudioMetadata({
    required this.title,
    required this.album,
    required this.artist,
    required this.releaseYear,
    required this.duration,
    required this.image,
  });
}
