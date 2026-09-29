import "dart:io";

import "package:flutter/material.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/services/player/types.dart";
import "package:himig/inject.dart";

class NowPlayingBar extends StatefulWidget {
  const NowPlayingBar({super.key});

  @override
  State<NowPlayingBar> createState() => _NowPlayingBarState();
}

class _NowPlayingBarState extends State<NowPlayingBar> {
  final _playerService = getInject<PlayerService>();

  bool _playing = true;
  SimpleSong? _song;

  late VoidCallback _closeSongChange;

  void _onTogglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _playerService.play();
    } else {
      _playerService.pause();
    }
  }

  void _onNextPressed() {
    _playerService.skipToNext();
  }

  @override
  void initState() {
    super.initState();
    _closeSongChange = _playerService.onSongChanged(
      (song) => setState(() => _song = song),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _closeSongChange();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          ?_getImage(_song?.coverArtUri),

          Text(_song?.title ?? ""),
          //Text(_song?.artist ?? ""),

          IconButton(
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow, size: 36),
            onPressed: _onTogglePlay,
          ),

          IconButton(
            icon: Icon(Icons.skip_next, size: 36),
            onPressed: _onNextPressed,
          ),
        ],
      ),
    );
  }

  // TODO: Create a component
  Widget? _getImage(Uri? coverArtUri) {
    final theme = Theme.of(context);
    if (coverArtUri == null) {
      return Container(
        color: theme.colorScheme.onPrimary,
        width: 50,
        height: 50,
      );
    }

    if (coverArtUri.isScheme("file")) {
      return Image.file(File.fromUri(coverArtUri), width: 50, height: 50);
    }

    return Image.network(coverArtUri.toString(), width: 50, height: 50);
  }
}
