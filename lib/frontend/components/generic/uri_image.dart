import "dart:io";

import "package:flutter/material.dart";

class UriImage extends StatelessWidget {
  final Uri? _uri;
  final double _width;
  final double _height;
  final Color? _backgroundColor;
  final AlignmentGeometry _alignment;

  const UriImage(
    this._uri, {
    super.key,
    this._width = 160.0,
    this._height = 160.0,
    this._backgroundColor,
    this._alignment = .center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _height,
      color: _backgroundColor,
      child: _getImage(context),
    );
  }

  Widget? _getImage(BuildContext context) {
    if (_uri == null) {
      // TODO: check if needs alternate here
      return null;
    }

    if (_uri.isScheme("file")) {
      return Image.file(
        File.fromUri(_uri),
        alignment: _alignment,
        errorBuilder: (context, exception, stackTrace) => Container(),
      );
    }

    return Image.network(
      _uri.toString(),
      alignment: _alignment,
      errorBuilder: (context, exception, stackTrace) => Container(),
    );
  }
}
