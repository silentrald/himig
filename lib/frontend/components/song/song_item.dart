import "package:flutter/material.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/frontend/components/generic/overflow_text.dart";

class SongItem extends StatelessWidget {
  final Song _song;
  final double _width;
  final VoidCallback? _onTap;

  final _iconSize = 16.0;
  final _padding = 16.0;

  const SongItem(this._song, {super.key, required this._width, this._onTap});

  @override
  Widget build(BuildContext context) {
    final minutes = (_song.duration.inSeconds / 60).truncate();
    final seconds = (_song.duration.inSeconds % 60)
        .truncate()
        .toString()
        .padLeft(2, "0");
    final durationText = "$minutes:$seconds";

    final durationWidth = (TextPainter(
      text: TextSpan(text: durationText),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout()).size.width;

    var textWidth = _width - (_padding * 2) - durationWidth - 1.0;
    if (_song.localUri != null && _song.remoteUri != null) {
      textWidth -= _iconSize;
    }

    return GestureDetector(
      onTap: _onTap,
      child: Ink(
        padding: EdgeInsets.all(_padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OverflowText(_song.title, width: textWidth),

            Row(
              children: [
                ?_buildIcon(),
                Text(durationText, textAlign: .right),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildIcon() {
    if (_song.localUri == null || _song.remoteUri == null) {
      return null;
    }

    return Icon(Icons.file_download, size: _iconSize);
  }
}
