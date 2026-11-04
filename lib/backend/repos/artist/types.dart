import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

abstract class ArtistRepo {
  FutureResult<Artist> getArtist(RepoClient client, int artistId);
  FutureResult<List<Artist>> getArtistList(
    RepoClient client, {
    int page = 1,
    int count = 20,
  });

  // Returns an artist by name, if none found, return null
  FutureResult<Artist?> findArtistByName(RepoClient client, String artistName);

  FutureResult<Artist> insertArtist(RepoClient client, Artist artist);

  FutureResult<int> deleteAllArtists(RepoClient client);
}
