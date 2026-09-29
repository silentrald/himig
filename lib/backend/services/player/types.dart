import "package:flutter/foundation.dart";
import "package:himig/backend/entities/song.dart";

// Should be responsible for handling player/background audio.
abstract class PlayerService {
  Future<void> init(String channelId, String channelName);

  Future<void> play();
  Future<void> pause();
  Future<void> skip(int index);
  Future<void> skipToNext();
  Future<void> skipToPrevious();

  Future<void> addSong(Song song);
  Future<void> clearQueue();

  // Events

  /// Should return a [VoidCallback] that stops listening the changes
  VoidCallback onSongChanged(ValueChanged<SimpleSong> callback);
}
