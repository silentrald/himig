import "dart:math";

import "package:collection/collection.dart";
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
  FutureResult<Artist> getArtist(RepoClient client, int artistId) async =>
      Result.ok(_artists.firstWhere((a) => a.id == artistId));

  @override
  FutureResult<List<Artist>> getArtistList(
    RepoClient client, {
    int page = 1,
    int count = 20,
  }) async => Result.ok(
    _artists.sublist((page - 1) * count, min(_artists.length, page * count)),
  );

  @override
  FutureResult<Artist?> findArtistByName(
    RepoClient client,
    String artistName,
  ) async => Result.ok(_artists.firstWhereOrNull((a) => a.name == artistName));

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
