import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

abstract class ArtistRepo {
  FutureResult<List<Artist>> getArtistList(
    RepoClient client, {
    int page = 1,
    int count = 20,
  });
  // TODO: Remove this since this seems to be inefficient for big data
  //   but just good for testing for now
  FutureResult<Map<String, int>> getArtistMap(RepoClient client);

  FutureResult<Artist> insertArtist(RepoClient client, Artist artist);

  FutureResult<int> deleteAllArtists(RepoClient client);
}
