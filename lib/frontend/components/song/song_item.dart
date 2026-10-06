import "package:flutter/material.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/frontend/components/generic/overflow_text.dart";

class SongItem extends StatelessWidget {
  final Song _song;
  final double _width;
  final VoidCallback _onTap;

  final _padding = 16.0;

  const SongItem({
    super.key,
    required this._song,
    required this._width,
    required this._onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _onTap,
      child: Ink(
        padding: EdgeInsets.all(_padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OverflowText(_song.title, width: _width - (_padding * 2)),
            ?_buildIcon(),
          ],
        ),
      ),
    );
  }

  Widget? _buildIcon() {
    if (_song.localUri == null || _song.remoteUri == null) {
      return null;
    }

    return Icon(Icons.file_download);
  }
}
