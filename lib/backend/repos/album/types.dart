import "package:himig/backend/entities/album.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

abstract class AlbumRepo {
  FutureResult<Album> getAlbum(RepoClient client, int albumId);
  FutureResult<List<Album>> getAlbumList(
    RepoClient client, {
    int page = 1,
    int count = 20,
    AlbumSort sort = AlbumSort.recentlyAdded,
  });
  FutureResult<List<Album>> getAlbumListByArtist(
    RepoClient client,
    int artistId,
  );

  /// @params artistName - Helps disambiguate in getting the album
  FutureResult<Album?> findAlbumByNames(
    RepoClient client,
    String albumName,
    String artistName,
  );

  FutureResult<int> countAlbums(RepoClient client);

  FutureResult<Album> insertAlbum(RepoClient client, Album album);
  FutureResult<Album> updateAlbum(RepoClient client, Album album);

  FutureResult<int> deleteAllAlbums(RepoClient client);
}
