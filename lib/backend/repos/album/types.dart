import "package:himig/backend/entities/album.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/utils/result.dart";

abstract class AlbumRepo {
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

  FutureResult<Album> insertAlbum(RepoClient client, Album album);

  FutureResult<int> deleteAllAlbums(RepoClient client);
}
