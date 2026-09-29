import "package:flutter/material.dart";
import "package:himig/backend/entities/song.dart";

class SongItem extends StatelessWidget {
  final Song _song;
  final VoidCallback _onTap;

  const SongItem({super.key, required Song song, required VoidCallback onTap})
    : _song = song,
      _onTap = onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _onTap,
      child: Ink(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(_song.title), ?_buildIcon()],
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
