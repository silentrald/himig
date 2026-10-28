import "dart:math";

import "package:audio_service/audio_service.dart";
import "package:flutter/foundation.dart";
import "package:himig/backend/dtos/simple_song.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/services/player/types.dart";
import "package:himig/utils/logger.dart" as logger;
import "package:just_audio/just_audio.dart";

MediaItem _convertSongToMediaItem(Song song) => MediaItem(
  id: song.uri.toString(),
  title: song.title,
  album: song.albumName,
  artist: song.artistName,
  duration: song.duration,
  artUri: song.coverArtUri,
);

AudioSource _convertSongToAudioSource(Song song) => AudioSource.uri(
  Uri.parse(song.uri.toString()),
  tag: _convertSongToMediaItem(song),
);

/// Logic Paths
/// - Media related buttons should pass thru [AudioHandler].
/// - Playlist / Song List update should directly be editted in [AudioPlayer].
class MainPlayerService extends PlayerService {
  late final AudioHandler _audioHandler;

  @override
  Future<void> init(String channelId, String channelName) async {
    _audioHandler = await AudioService.init(
      builder: () => _AudioPlayerHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: channelId,
        androidNotificationChannelName: channelName,
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }

  @override
  Future<void> play() => _audioHandler.play();

  @override
  Future<void> pause() => _audioHandler.pause();

  @override
  Future<void> seek(Duration position) => _audioHandler.seek(position);

  @override
  Future<void> skip(int index) => _audioHandler.skipToQueueItem(index);

  @override
  Future<void> skipToNext() => _audioHandler.skipToNext();

  @override
  Future<void> skipToPrevious() => _audioHandler.skipToPrevious();

  @override
  Future<void> setShuffle(bool shuffle) =>
      _audioHandler.setShuffleMode(shuffle ? .all : .none);

  @override
  Future<void> setRepeat(PlayerRepeat repeat) =>
      _audioHandler.setRepeatMode(switch (repeat) {
        .none => .none,
        .all => .all,
        .one => .one,
      });

  /// Initialize the song list and play it immediately.
  ///
  /// [index] - Starting index to play the song list.
  /// [shuffle] - if set to true, disregards the passed [index] and
  ///   randomly picks the first song in the song lists.
  @override
  Future<void> playSongList(
    List<Song> songs, {
    int index = 0,
    bool shuffle = false,
  }) async {
    await setShuffle(shuffle);

    if (shuffle) {
      index = Random().nextInt(songs.length);
    }
    await (_audioHandler as _AudioPlayerHandler).player.setAudioSources(
      songs.map(_convertSongToAudioSource).toList(),
      initialIndex: index,
    );

    await play();
  }

  /// Directly manipulate the [AudioPlayer] which should broadcast it with [AudioHandler].
  @override
  Future<void> addSong(Song song) => (_audioHandler as _AudioPlayerHandler)
      .player
      .addAudioSource(_convertSongToAudioSource(song));

  /// Directly manipulate the [AudioPlayer] which should broadcast it with [AudioHandler].
  @override
  Future<void> addSongList(List<Song> songs) =>
      (_audioHandler as _AudioPlayerHandler).player.addAudioSources(
        songs.map(_convertSongToAudioSource).toList(),
      );

  /// Directly manipulate the [AudioPlayer] which should broadcast it with [AudioHandler].
  @override
  Future<void> clearSongList() async {
    await _audioHandler.pause();
    await (_audioHandler as _AudioPlayerHandler).player.clearAudioSources();
  }

  @override
  void Function() onSongChanged(ValueChanged<SimpleSong> callback) {
    final subscription = _audioHandler.mediaItem.listen((MediaItem? item) {
      if (item != null) {
        callback(
          SimpleSong(
            title: item.title,
            artist: item.artist,
            coverArtUri: item.artUri,
            duration: item.duration,
          ),
        );
      }
    });

    return () => subscription.cancel();
  }

  @override
  void Function() onStatusChanged(ValueChanged<PlayerStatus> callback) {
    final subscription = _audioHandler.playbackState.listen((playbackState) {
      callback(
        PlayerStatus(
          playing: playbackState.playing,
          shuffle: playbackState.shuffleMode == .all,
          repeat: switch (playbackState.repeatMode) {
            .all => .all,
            .one => .one,
            _ => .none,
          },
          position: playbackState.position,
          updatePosition: playbackState.updatePosition,
          bufferedPosition: playbackState.bufferedPosition,
        ),
      );
    });

    return () => subscription.cancel();
  }
}

/// Handling for playing audio in the background
class _AudioPlayerHandler extends BaseAudioHandler {
  final player = AudioPlayer();

  _AudioPlayerHandler() {
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    player.currentIndexStream.forEach((int? currentIndex) {
      if (currentIndex == null) {
        return;
      }

      final current = player.sequence[currentIndex].tag as MediaItem;
      if (mediaItem.value?.id == current.id) {
        return;
      }

      logger.debug("Currently playing ${current.title} in ${current.id}.");
      mediaItem.add(current);
    });
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() => player.seekToNext();

  @override
  Future<void> skipToPrevious() => player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) =>
      player.seek(Duration.zero, index: index);

  @override
  Future<void> stop() => player.stop();

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) =>
      player.setShuffleModeEnabled(shuffleMode == .all);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) =>
      player.setLoopMode(switch (repeatMode) {
        .all => .all,
        .one => .one,
        _ => .off,
      });

  @override
  Future<void> addQueueItem(MediaItem mediaItem) => player.addAudioSource(
    AudioSource.uri(Uri.parse(mediaItem.id), tag: mediaItem),
  );

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    await player.addAudioSources(
      mediaItems
          .map((mi) => AudioSource.uri(Uri.parse(mi.id), tag: mi))
          .toList(),
    );
  }

  @override
  Future<void> removeQueueItemAt(int index) =>
      player.removeAudioSourceAt(index);

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: switch (player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: player.playing,
      shuffleMode: player.shuffleModeEnabled ? .all : .none,
      repeatMode: switch (player.loopMode) {
        LoopMode.off => AudioServiceRepeatMode.none,
        LoopMode.all => AudioServiceRepeatMode.all,
        LoopMode.one => AudioServiceRepeatMode.one,
      },
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
