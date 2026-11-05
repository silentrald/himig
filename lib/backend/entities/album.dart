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

  int? _localSourceId;
  int? _remoteSourceId;

  String? _localPath;
  String? _remoteId;

  final int? releaseYear;
  final Uri? coverArtUri;

  Album({
    this.id = 0,
    required this.name,
    this.artistId,
    this.artistName,
    this._localSourceId,
    this._remoteSourceId,
    this._localPath,
    this._remoteId,
    this.releaseYear,
    this.coverArtUri,
  });

  static ProjectError? validatePair(
    int? sourceId,
    String? idOrPath,
    bool local,
  ) {
    if ((sourceId == null) ^ (idOrPath == null)) {
      return ProjectError(.entityAlbum, "pair", {
        "source": (.generic, local ? "local" : "remote"),
      });
    }
    return null;
  }

  static ProjectError? validateSources(
    int? localSourceId,
    String? localPath,
    int? remoteSourceId,
    String? remoteId,
  ) {
    final localPair = localSourceId != null && localPath != null;
    final remotePair = remoteSourceId != null && remoteId != null;

    if (!localPair && !remotePair) {
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
    String? localPath,
    String? remoteId,
    int? releaseYear,
    Uri? coverArtUri,
  }) {
    final List<ProjectError> errors = [
      ?validatePair(localSourceId, localPath, true),
      ?validatePair(remoteSourceId, remoteId, false),
      ?validateSources(localSourceId, localPath, remoteSourceId, remoteId),
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
        localPath: localPath,
        remoteId: remoteId,
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
    String? localPath,
    String? remoteId,
    int? releaseYear,
    Uri? coverArtUri,
  }) => Album(
    id: id ?? this.id,
    name: name ?? this.name,
    artistId: artistId ?? this.artistId,
    artistName: artistName ?? this.artistName,
    localSourceId: localSourceId ?? _localSourceId,
    remoteSourceId: remoteSourceId ?? _remoteSourceId,
    localPath: localPath ?? _localPath,
    remoteId: remoteId ?? _remoteId,
    releaseYear: releaseYear ?? this.releaseYear,
    coverArtUri: coverArtUri ?? this.coverArtUri,
  );

  String? get localPath => _localPath;
  String? get remoteId => _remoteId;
  int? get localSourceId => _localSourceId;
  int? get remoteSourceId => _remoteSourceId;
  int get sourceId => _localSourceId ?? _remoteSourceId ?? 0;

  ProjectError? setLocal(int? localSourceId, String? localPath) {
    final error = validatePair(localSourceId, localPath, true);
    if (error == null) {
      _localSourceId = localSourceId;
      _localPath = localPath;
    }
    return error;
  }

  ProjectError? setRemote(int? remoteSourceId, String? remoteId) {
    final error = validatePair(remoteSourceId, remoteId, false);
    if (error == null) {
      _remoteSourceId = remoteSourceId;
      _remoteId = _remoteId;
    }
    return error;
  }

  Map<String, dynamic> _toJson() => {
    "id": id,
    "name": name,
    "artistId": artistId,
    "artistName": artistName,
    "localSourceId": _localSourceId,
    "remoteSourceId": _remoteSourceId,
    "localPath": _localPath,
    "remoteId": _remoteId,
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
