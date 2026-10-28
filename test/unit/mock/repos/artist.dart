import "dart:math";

import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/repos/artist/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

class MockArtistRepo extends ArtistRepo {
  final List<Artist> _artists = [];

  void setArtistList(List<Artist> artists) {
    _artists.clear();
    _artists.addAll(artists.map((artist) => artist.copyWith()));
  }

  @override
  FutureResult<List<Artist>> getArtistList(
    RepoClient client, {
    int page = 1,
    int count = 20,
  }) async => Result.ok(
    _artists.sublist((page - 1) * count, min(_artists.length, page * count)),
  );

  @override
  FutureResult<Map<String, int>> getArtistMap(RepoClient client) async {
    return Result.ok({for (var artist in _artists) artist.name: artist.id});
  }

  @override
  FutureResult<Artist> insertArtist(RepoClient client, Artist artist) async {
    artist.id = _artists.length;
    _artists.add(artist);
    return Result.ok(artist);
  }

  @override
  FutureResult<int> deleteAllArtists(RepoClient client) async {
    final count = _artists.length;
    _artists.clear();
    return Result.ok(count);
  }
}
