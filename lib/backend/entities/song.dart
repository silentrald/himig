import "dart:convert";

import "package:flutter/foundation.dart";
import "package:himig/backend/errors/multi_project_error.dart";
import "package:himig/backend/errors/project_error.dart";
import "package:himig/utils/result.dart";

class Song {
  int id;
  final String title;
  final String? albumName;
  final String? artistName;
  final Duration duration;
  final String fileExtension;

  final int? releaseYear;

  /// Reference to [Source]
  int? _localSourceId;
  Uri? _localUri;

  /// Reference to [Source]
  int? _remoteSourceId;
  Uri? _remoteUri;
  final Uri? coverArtUri;

  /// Reference to [Album]
  final int? albumId;

  /// Reference to [Artist]
  final int? artistId;

  Song({
    this.id = 0,
    required this.title,
    this.albumName,
    this.artistName,
    required this.duration,
    required this.fileExtension,

    this.releaseYear,
    this._localSourceId,
    this._localUri,
    this._remoteSourceId,
    this._remoteUri,
    this.coverArtUri,
    this.albumId,
    this.artistId,
  });

  static ProjectError? validatePair(int? sourceId, Uri? uri, bool local) {
    if ((sourceId == null) ^ (uri == null)) {
      // Both should be null or not null
      return ProjectError(.entitySong, "pair", {
        "source": (.generic, local ? "local" : "remote"),
      });
    }
    return null;
  }

  static ProjectError? validateSources(
    int? localSourceId,
    Uri? localUri,
    int? remoteSourceId,
    Uri? remoteUri,
  ) {
    final localPair = localSourceId != null && localUri != null;
    final remotePair = remoteSourceId != null && remoteUri != null;

    if (!localPair && !remotePair) {
      return ProjectError(.entitySong, "sources");
    }

    return null;
  }

  static Result<Song> create({
    required String title,
    String? albumName,
    String? artistName,
    required Duration duration,
    required String fileExtension,
    required String reference,
    int? releaseYear,
    int? localSourceId,
    Uri? localUri,
    int? remoteSourceId,
    Uri? remoteUri,
    Uri? coverArtUri,
    int? albumId,
    int? artistId,
  }) {
    final List<ProjectError> errors = [
      ?validatePair(localSourceId, localUri, true),
      ?validatePair(remoteSourceId, remoteUri, false),
      ?validateSources(localSourceId, localUri, remoteSourceId, remoteUri),
    ];
    if (errors.isNotEmpty) {
      return Result.error(MultiProjectError(errors));
    }

    return Result.ok(
      Song(
        title: title,
        albumName: albumName,
        artistName: artistName,
        duration: duration,
        fileExtension: fileExtension,
        releaseYear: releaseYear,
        localSourceId: localSourceId,
        localUri: localUri,
        remoteSourceId: remoteSourceId,
        remoteUri: remoteUri,
        coverArtUri: coverArtUri,
        albumId: albumId,
        artistId: artistId,
      ),
    );
  }

  Result<Song> copyWith({
    int? id,
    String? title,
    String? albumName,
    String? artistName,
    Duration? duration,
    String? fileExtension,
    String? reference,
    int? releaseYear,
    int? localSourceId,
    Uri? localUri,
    int? remoteSourceId,
    Uri? remoteUri,
    Uri? coverArtUri,
    int? albumId,
    int? artistId,
  }) {
    final List<ProjectError> errors = [];
    ProjectError? error;

    localSourceId ??= _localSourceId;
    localUri ??= _localUri;
    remoteSourceId ??= _remoteSourceId;
    remoteUri ??= _remoteUri;

    final localReference = localSourceId != null || localUri != null;
    final remoteReference = remoteSourceId != null || remoteUri != null;
    if (localReference) {
      error = validatePair(localSourceId, localUri, true);
      if (error != null) {
        errors.add(error);
      }
    }

    if (remoteReference) {
      error = validatePair(remoteSourceId, remoteUri, false);
      if (error != null) {
        errors.add(error);
      }
    }

    if (localReference || remoteReference) {
      error = validateSources(
        localSourceId,
        localUri,
        remoteSourceId,
        remoteUri,
      );
      if (error != null) {
        errors.add(error);
      }
    }

    return Result.ok(
      Song(
        id: id ?? this.id,
        title: title ?? this.title,
        albumName: albumName ?? this.albumName,
        artistName: artistName ?? this.artistName,
        duration: duration ?? this.duration,
        fileExtension: fileExtension ?? this.fileExtension,
        releaseYear: releaseYear ?? this.releaseYear,
        localSourceId: localSourceId,
        localUri: localUri,
        remoteSourceId: remoteSourceId,
        remoteUri: remoteUri,
        coverArtUri: coverArtUri ?? this.coverArtUri,
      ),
    );
  }

  int? get localSourceId => _localSourceId;
  Uri? get localUri => _localUri;
  int? get remoteSourceId => _remoteSourceId;
  Uri? get remoteUri => _remoteUri;
  int get sourceId => _localSourceId ?? _remoteSourceId!;
  Uri get uri => _localUri ?? _remoteUri!;

  ProjectError? setLocal(int? sourceId, Uri? uri) {
    final error = validatePair(sourceId, uri, true);
    if (error == null) {
      _localSourceId = sourceId;
      _localUri = uri;
    }
    return error;
  }

  ProjectError? setRemote(int? sourceId, Uri? uri) {
    final error = validatePair(sourceId, uri, false);
    if (error == null) {
      _remoteSourceId = sourceId;
      _remoteUri = uri;
    }
    return error;
  }

  Map<String, dynamic> _toJson() => {
    "id": id,
    "title": title,
    "albumName": albumName,
    "artistName": artistName,
    "duration": duration.inMilliseconds,
    "releaseYear": releaseYear,
    "localSourceId": _localSourceId,
    "localUri": _localUri,
    "remoteSourceId": _remoteSourceId,
    "remoteUri": _remoteUri,
    "coverArtUri": coverArtUri?.toString(),
    "albumId": albumId,
    "artistId": artistId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Song && mapEquals(_toJson(), other._toJson()));

  @override
  int get hashCode => id;

  @override
  String toString() => jsonEncode(_toJson());
}
