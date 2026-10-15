import "package:flutter/material.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/frontend/components/generic/uri_image.dart";
import "package:himig/locales/app_localizations.dart";
import "package:himig/state.dart";

class AlbumCard extends StatelessWidget {
  final double _imageSize;
  final double _iconSize;
  final bool _showArtistText;

  final Album _album;
  final VoidCallback? _onTap;

  final _iconPadding = 4.0;

  const AlbumCard(
    this._album, {
    super.key,
    this._imageSize = 160.0,
    this._iconSize = 24.0,
    this._showArtistText = true,
    this._onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context)!;

    return SizedBox(
      width: _imageSize,
      child: GestureDetector(
        onTap: _onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                UriImage(
                  _album.coverArtUri,
                  width: _imageSize,
                  height: _imageSize,
                  alignment: .topCenter,
                ),

                // Gradient
                Container(
                  width: _imageSize,
                  height: _imageSize,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: .topCenter,
                      end: .bottomCenter,
                      stops: [0.8, 1.0],
                      colors: [Colors.transparent, Colors.black],
                    ),
                  ),
                ),

                Container(
                  width: _iconSize,
                  height: _iconSize,
                  padding: EdgeInsets.all(_iconPadding),
                  margin: EdgeInsets.fromLTRB(
                    _imageSize - _iconSize - 2 * (_iconPadding),
                    _iconPadding,
                    _iconPadding,
                    _iconPadding,
                  ),
                  color: theme.colorScheme.onPrimary,
                  child: _getSourceIcon(theme.colorScheme.primary),
                ),
              ],
            ),

            Text(
              _album.name,
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 16),
            ),

            ?(_getArtistText(locale, theme)),
          ],
        ),
      ),
    );
  }

  Icon _getSourceIcon(Color color) {
    final source = AppState().getSource(_album.sourceId).type;
    switch (source) {
      case SourceType.folder:
        return Icon(Icons.folder, size: 16, color: color);
      case SourceType.subsonic:
        return Icon(Icons.api, size: 16, color: color);
    }
  }

  Widget? _getArtistText(AppLocalizations locale, ThemeData theme) {
    if (!_showArtistText) {
      return null;
    }

    return Text(
      _album.artistName ?? locale.translate(.generic, "unknown"),
      style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12),
    );
  }
}
