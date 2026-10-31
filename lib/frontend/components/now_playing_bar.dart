import "dart:async";

import "package:flutter/material.dart";
import "package:himig/backend/dtos/simple_song.dart";
import "package:himig/backend/services/player/types.dart";
import "package:himig/backend/services/storage/types.dart";
import "package:himig/frontend/components/generic/overflow_text.dart";
import "package:himig/frontend/components/generic/uri_image.dart";
import "package:himig/inject.dart";
import "package:himig/locales/app_localizations.dart";
import "package:himig/utils/logger.dart" as logger;

class NowPlayingBar extends StatefulWidget {
  final double height;
  final SimpleSong song;
  final void Function()? _onSongInfoPressed;

  const NowPlayingBar({
    super.key,
    required this.height,
    required this.song,
    this._onSongInfoPressed,
  });

  @override
  State<NowPlayingBar> createState() => _NowPlayingBarState();
}

class _NowPlayingBarState extends State<NowPlayingBar> {
  final _storageService = getInject<StorageService>();
  final _playerService = getInject<PlayerService>();

  final _imageSize = 50.0;
  final _buttonSize = 40.0;
  final _paddingSize = 8.0;
  final _updateTick = Duration(milliseconds: 500);

  var _status = PlayerStatus(
    playing: false,
    shuffle: false,
    repeat: PlayerRepeat.none,
    position: Duration(),
    updatePosition: Duration(),
    bufferedPosition: Duration(),
  );

  void Function()? _onStatusChanged;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Start the interval since a song is selected
    _startInterval();

    _initRepeatMode();

    _onStatusChanged = _playerService.onStatusChanged((playerStatus) {
      // There is some lag
      setState(() {
        _status = playerStatus;
      });
    });
  }

  Future<void> _initRepeatMode() async {
    final repeatString = await _storageService.getString(
      .repeatMode,
      PlayerRepeat.none.name,
    );
    final repeat = PlayerRepeat.of(repeatString);

    setState(() => _status.repeat = repeat);
    await _playerService.setRepeat(repeat);
    await _storageService.setString(.repeatMode, _status.repeat.name);
  }

  @override
  void didUpdateWidget(covariant NowPlayingBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.song != widget.song) {
      return;
    }

    // Reset the interval
    _startInterval();
    setState(() => _status.resetDuration());
  }

  @override
  void dispose() {
    _onStatusChanged?.call();

    super.dispose();
  }

  void _startInterval() {
    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer.periodic(
      _updateTick,
      (_) => setState(() => _status.position += _updateTick),
    );
  }

  void _stopInterval() {
    if (_timer == null) {
      return;
    }

    _timer!.cancel();
    _timer = null;
  }

  void _onTogglePlay() {
    if (_status.playing) {
      _playerService.pause();
      _stopInterval();
      logger.info("Pause song");
    } else {
      _playerService.play();
      _startInterval();
      logger.info("Play song");
    }
  }

  void _onPreviousPressed() {
    _playerService.skipToPrevious();
  }

  void _onNextPressed() {
    _playerService.skipToNext();
  }

  //void _onShufflePressed() {
  // TODO:
  //_playerService.setShuffle(!_shuffle);
  //}

  void _onRepeatPressed() async {
    // Needs to be updated since there is some noticeable lag when this
    //   is emitted in the playbackStatus event.
    setState(() => _status.nextRepeatMode());
    await _playerService.setRepeat(_status.repeat);
    await _storageService.setString(.repeatMode, _status.repeat.name);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final width = MediaQuery.of(context).size.width;
    final remainingWidth = width - (_buttonSize * 4) - (_paddingSize * 3);

    return Align(
      alignment: .bottomCenter,
      child: Container(
        padding: EdgeInsets.all(_paddingSize),
        height: widget.height,
        color: theme.colorScheme.primary,
        child: Column(
          mainAxisAlignment: .spaceAround,
          children: [
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                _buildSongInfo(locale, theme, width: remainingWidth),
                _buildMediaButtons(theme),
              ],
            ),

            // TODO: time info for song, scroll should be in the now playing page
            //SizedBox(width: _paddingSize),
            //_buildMediaScroll(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSongInfo(
    AppLocalizations locale,
    ThemeData theme, {
    required double width,
  }) {
    final titleWidth = width - _imageSize - _paddingSize;

    return GestureDetector(
      onTap: widget._onSongInfoPressed,
      child: Row(
        mainAxisAlignment: .start,

        children: [
          UriImage(
            widget.song.coverArtUri,
            width: _imageSize,
            height: _imageSize,
            backgroundColor: Colors.white,
          ),

          SizedBox(width: _paddingSize),

          Column(
            mainAxisSize: .min,
            mainAxisAlignment: .center,
            crossAxisAlignment: .start,
            children: [
              OverflowText(
                widget.song.title,
                width: titleWidth,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: .bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),

              Text(
                widget.song.artist ?? locale.translate(.generic, "unknown"),
                style: TextStyle(
                  fontSize: 12.0,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: .end,
      children: [
        //_buildMediaButton(
        //  _shuffle ? Icons.shuffle_on : Icons.shuffle,
        //  theme: theme,
        //  onPressed: _onShufflePressed,
        //),

        _buildMediaButton(
          Icons.skip_previous,
          theme: theme,
          onPressed: _onPreviousPressed,
        ),

        _buildMediaButton(
          _status.playing ? Icons.pause : Icons.play_arrow,
          theme: theme,
          onPressed: _onTogglePlay,
        ),

        _buildMediaButton(
          Icons.skip_next,
          theme: theme,
          onPressed: _onNextPressed,
        ),

        _buildMediaButton(
          switch (_status.repeat) {
            .none => Icons.repeat_sharp,
            .all => Icons.repeat_on_sharp,
            .one => Icons.repeat_one_on_sharp,
          },
          theme: theme,
          onPressed: _onRepeatPressed,
        ),
      ],
    );
  }

  Widget _buildMediaButton(
    IconData iconData, {
    required ThemeData theme,
    required void Function() onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(
        iconData,
        size: _buttonSize,
        color: theme.colorScheme.onPrimary,
      ),
    );
  }

  // TODO: Reuse in now playing page
  //Widget _buildMediaScroll(ThemeData theme) {
  //  final duration = widget.song.duration!.inMilliseconds;
  //
  //  return Slider(
  //    value: min(1.0, _status.position.inMilliseconds / duration),
  //    activeColor: theme.colorScheme.tertiary,
  //    thumbColor: theme.colorScheme.tertiary,
  //    secondaryActiveColor: theme.colorScheme.onSecondary,
  //    inactiveColor: theme.colorScheme.secondary,
  //    secondaryTrackValue: min(
  //      1.0,
  //      _status.bufferedPosition.inMilliseconds / duration,
  //    ),
  //    onChanged: (value) => _playerService.seek(
  //      Duration(milliseconds: (duration * value).truncate()),
  //    ),
  //  );
  //}
}
