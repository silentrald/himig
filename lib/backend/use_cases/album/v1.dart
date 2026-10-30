import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/helpers/cache/types.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/use_cases/album/types.dart";
import "package:himig/utils/result.dart";

class AlbumUseCaseV1 extends AlbumUseCase {
  final RepoDatabase _database;
  final SongRepo _songRepo;
  final CacheHelper _cacheHelper;

  AlbumUseCaseV1({
    required this._database,
    required this._songRepo,
    required this._cacheHelper,
  });

  @override
  Future<Result<List<Song>>> getSongListByAlbum(int albumId) {
    return _songRepo.getSongListByAlbum(_database.client, albumId);
  }

  @override
  Future<Result<void>> cacheAlbumSongs(Album album) =>
      _cacheHelper.cacheAlbum(album);
}
