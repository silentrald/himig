import "dart:math";

import "package:collection/collection.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

class MockAlbumRepo extends AlbumRepo {
  final List<Album> _albums = [];

  void setAlbumList(List<Album> albums) {
    _albums.clear();
    _albums.addAll(albums.map((album) => album.copyWith()));
  }

  @override
  FutureResult<Album> getAlbum(RepoClient client, int albumId) async =>
      Result.ok(_albums.firstWhere((a) => a.id == albumId));

  @override
  FutureResult<List<Album>> getAlbumList(
    RepoClient client, {
    int page = 1,
    int count = 20,
    AlbumSort sort = AlbumSort.recentlyAdded,
  }) async => Result.ok(
    _albums.sublist((page - 1) * count, min(_albums.length, page * count)),
  );

  @override
  FutureResult<List<Album>> getAlbumListByArtist(
    RepoClient client,
    int artistId,
  ) async => Result.ok(_albums.where((a) => a.artistId == artistId).toList());

  @override
  FutureResult<Album?> findAlbumByNames(
    RepoClient client,
    String albumName,
    String artistName,
  ) async => Result.ok(
    _albums.firstWhereOrNull(
      (a) => a.name == albumName && a.artistName == artistName,
    ),
  );

  @override
  FutureResult<int> countAlbums(RepoClient client) async =>
      Result.ok(_albums.length);

  @override
  FutureResult<Album> insertAlbum(RepoClient client, Album album) async {
    album.id = _albums.length;
    _albums.add(album);
    return Result.ok(album);
  }

  @override
  FutureResult<Album> updateAlbum(RepoClient client, Album album) async {
    var index = _albums.indexWhere((s) => s.id == album.id);
    if (index == -1) {
      return Result.error(Exception("Could not find album"));
    }

    _albums[index] = album;
    return Result.ok(album);
  }

  @override
  FutureResult<int> deleteAllAlbums(RepoClient client) async {
    final count = _albums.length;
    _albums.clear();
    return Result.ok(count);
  }
}
