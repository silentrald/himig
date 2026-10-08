import "package:flutter/material.dart";
import "package:himig/backend/entities/artist.dart";
import "package:himig/frontend/components/generic/uri_image.dart";

class ArtistCard extends StatelessWidget {
  final double _imageSize;

  final Artist _artist;
  final void Function()? _onTap;

  const ArtistCard({
    super.key,
    this._imageSize = 160.0,
    required this._artist,
    this._onTap,
  });

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
            UriImage(
              _artist.imageUri,
              backgroundColor: theme.colorScheme.primary,
            ),

            Text(
              _artist.name,
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
