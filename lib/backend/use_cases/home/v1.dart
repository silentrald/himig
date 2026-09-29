import "package:himig/backend/entities/album.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/repo.dart";
import "package:himig/backend/use_cases/home/types.dart";
import "package:himig/utils/result.dart";

class HomeUseCaseV1 extends HomeUseCase {
  final RepoDatabase _database;
  final AlbumRepo _albumRepo;

  HomeUseCaseV1({required RepoDatabase database, required AlbumRepo albumRepo})
    : _database = database,
      _albumRepo = albumRepo;

  @override
  Future<Result<List<Album>>> getAlbumList({
    int page = 1,
    int count = 20,
    AlbumSort sort = AlbumSort.recentlyAdded,
  }) {
    return _albumRepo.getAlbumList(
      _database.client,
      page: page,
      count: count,
      sort: sort,
    );
  }
}
