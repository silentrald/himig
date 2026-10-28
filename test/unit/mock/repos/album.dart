import "dart:math";

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
  FutureResult<Album> insertAlbum(RepoClient client, Album album) async {
    album.id = _albums.length;
    _albums.add(album);
    return Result.ok(album);
  }

  @override
  FutureResult<int> deleteAllAlbums(RepoClient client) async {
    final count = _albums.length;
    _albums.clear();
    return Result.ok(count);
  }
}
