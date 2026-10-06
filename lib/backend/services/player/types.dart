import "package:flutter/foundation.dart";
import "package:himig/backend/entities/song.dart";

enum PlayerRepeat { none, all, one }

// Separate this to another class
class PlayerStatus {
  bool playing;
  bool shuffle;
  PlayerRepeat repeat;
  Duration position;
  Duration updatePosition;
  Duration bufferedPosition;

  PlayerStatus({
    required this.playing,
    required this.shuffle,
    required this.repeat,
    this.position = Duration.zero,
    this.updatePosition = Duration.zero,
    this.bufferedPosition = Duration.zero,
  });

  void nextRepeatMode() {
    repeat = switch (repeat) {
      .none => .all,
      .all => .one,
      .one => .none,
    };
  }

  void resetDuration() {
    position = Duration.zero;
    updatePosition = Duration.zero;
    bufferedPosition = Duration.zero;
  }
}

// Should be responsible for handling player/background audio.
abstract class PlayerService {
  Future<void> init(String channelId, String channelName);

  Future<void> play();
  Future<void> pause();

  /// Seek/Changes the current position of the song
  Future<void> seek(Duration position);
  Future<void> skip(int index);
  Future<void> skipToNext();
  Future<void> skipToPrevious();

  //Future<void> setShuffle(bool shuffle);
  Future<void> setRepeat(PlayerRepeat repeat);

  Future<void> addSong(Song song);
  Future<void> clearQueue();

  // Events

  /// Should return a [VoidCallback] that stops listening the changes
  void Function() onSongChanged(ValueChanged<SimpleSong> callback);
  void Function() onStatusChanged(ValueChanged<PlayerStatus> callback);
}
