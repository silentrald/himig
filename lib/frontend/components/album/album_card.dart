import "dart:io";

import "package:flutter/material.dart";
import "package:himig/backend/entities/source.dart";

class AlbumCard extends StatelessWidget {
  final _imageSize = 160.0;
  final _iconSize = 24.0;

  final String _album;
  final String _artist;
  final SourceType _sourceType;
  final Uri? _coverArtUri;
  final VoidCallback _onTap;

  const AlbumCard({
    super.key,
    required album,
    required artist,
    required coverArtUri,
    required SourceType sourceType,
    required VoidCallback onTap,
  }) : _album = album,
       _artist = artist,
       _sourceType = sourceType,
       _coverArtUri = coverArtUri,
       _onTap = onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: _imageSize,
      child: GestureDetector(
        onTap: _onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: _imageSize,
                  height: _imageSize,
                  color: theme.colorScheme.primary,
                  child: _getImage(context),
                ),
                Container(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: _iconSize,
                    height: _iconSize,
                    padding: EdgeInsets.all(4),
                    margin: EdgeInsets.all(4),
                    color: theme.colorScheme.onPrimary,
                    child: _getSourceIcon(theme.colorScheme.primary),
                  ),
                ),
              ],
            ),

            Text(
              _album,
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 16),
            ),

            Text(
              _artist,
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _getImage(BuildContext context) {
    if (_coverArtUri == null) {
      return null;
    }

    if (_coverArtUri.isScheme("file")) {
      return Image.file(
        File.fromUri(_coverArtUri),
        errorBuilder: (context, exception, stackTrace) => Container(),
      );
    }

    return Image.network(
      _coverArtUri.toString(),
      errorBuilder: (context, exception, stackTrace) => Container(),
    );
  }

  Icon _getSourceIcon(Color color) {
    switch (_sourceType) {
      case SourceType.folder:
        return Icon(Icons.folder, size: 16, color: color);
      case SourceType.subsonic:
        return Icon(Icons.api, size: 16, color: color);
    }
  }
}
