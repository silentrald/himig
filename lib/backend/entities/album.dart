import "dart:convert";

import "package:flutter/foundation.dart";
import "package:himig/backend/errors/multi_project_error.dart";
import "package:himig/backend/errors/project_error.dart";
import "package:himig/utils/result.dart";

enum AlbumSort { recentlyAdded, releaseYear }

class Album {
  int id;
  final String name;
  final int? artistId;
  final String? artistName;

  final int? _localSourceId;
  final int? _remoteSourceId;

  /// For remote source - id
  /// For local source - path
  final String reference;

  final int? releaseYear;
  final Uri? coverArtUri;

  Album({
    this.id = 0,
    required this.name,
    this.artistId,
    this.artistName,
    this._localSourceId,
    this._remoteSourceId,
    required this.reference,
    this.releaseYear,
    this.coverArtUri,
  });

  static ProjectError? validateSources(
    int? remoteSourceId,
    int? localSourceId,
  ) {
    if (localSourceId == null && remoteSourceId == null) {
      return ProjectError(.entityAlbum, "sources");
    }

    return null;
  }

  static Result<Album> create({
    required String name,
    int? artistId,
    String? artistName,
    int? localSourceId,
    int? remoteSourceId,
    required reference,
    int? releaseYear,
    Uri? coverArtUri,
  }) {
    final List<ProjectError> errors = [
      ?validateSources(localSourceId, remoteSourceId),
    ];

    if (errors.isNotEmpty) {
      return Result.error(MultiProjectError(errors));
    }

    return Result.ok(
      Album(
        name: name,
        artistId: artistId,
        artistName: artistName,
        localSourceId: localSourceId,
        remoteSourceId: remoteSourceId,
        reference: reference,
        releaseYear: releaseYear,
        coverArtUri: coverArtUri,
      ),
    );
  }

  Album copyWith({
    int? id,
    String? name,
    int? artistId,
    String? artistName,
    int? localSourceId,
    int? remoteSourceId,
    String? reference,
    int? releaseYear,
    Uri? coverArtUri,
  }) => Album(
    id: id ?? this.id,
    name: name ?? this.name,
    artistId: artistId ?? this.artistId,
    artistName: artistName ?? this.artistName,
    localSourceId: localSourceId ?? _localSourceId,
    remoteSourceId: remoteSourceId ?? _remoteSourceId,
    reference: reference ?? this.reference,
    releaseYear: releaseYear ?? this.releaseYear,
    coverArtUri: coverArtUri ?? this.coverArtUri,
  );

  int? get localSourceId => _localSourceId;
  int? get remoteSourceId => _remoteSourceId;
  int get sourceId => _localSourceId ?? _remoteSourceId ?? 0;

  Map<String, dynamic> _toJson() => {
    "id": id,
    "name": name,
    "artistId": artistId,
    "artistName": artistName,
    "localSourceId": _localSourceId,
    "remoteSourceId": _remoteSourceId,
    "reference": reference,
    "releaseYear": releaseYear,
    "coverArtUri": coverArtUri?.toString(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Album && mapEquals(_toJson(), other._toJson()));

  @override
  int get hashCode => id;

  @override
  String toString() => jsonEncode(_toJson());
}
