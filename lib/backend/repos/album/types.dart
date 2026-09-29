import "package:himig/backend/entities/album.dart";
import "package:himig/backend/repos/repo.dart";
import "package:himig/utils/result.dart";

abstract class AlbumRepo {
  Future<Result<List<Album>>> getAlbumList(
    RepoClient client, {
    int page = 1,
    int count = 20,
    AlbumSort sort = AlbumSort.recentlyAdded,
  });

  Future<Result<Album>> insertAlbum(RepoClient client, Album album);

  Future<Result<int>> deleteAllAlbums(RepoClient client);
}
