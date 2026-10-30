import "package:collection/collection.dart";
import "package:himig/backend/dtos/album_songs.dart";
import "package:himig/backend/helpers/cache/types.dart";
import "package:himig/backend/repos/album/types.dart";
import "package:himig/backend/repos/song/types.dart";
import "package:himig/backend/repos/types.dart";
import "package:himig/backend/use_cases/artist/types.dart";
import "package:himig/utils/result.dart";

class ArtistUseCaseV1 extends ArtistUseCase {
  final RepoDatabase _database;
  final AlbumRepo _albumRepo;
  final SongRepo _songRepo;
  final CacheHelper _cacheHelper;

  ArtistUseCaseV1({
    required this._database,
    required this._albumRepo,
    required this._songRepo,
    required this._cacheHelper,
  });

  @override
  FutureResult<List<AlbumSongsDto>> getAlbumSongsList(int artistId) async {
    return await _database.startTransaction((client) async {
      final List<AlbumSongsDto> list = [];

      final albumResult = await _albumRepo.getAlbumListByArtist(
        client,
        artistId,
      );
      if (albumResult is ResultError) {
        return albumResult.toError();
      }

      final songResult = await _songRepo.getSongListByArtist(client, artistId);
      if (songResult is ResultError) {
        return songResult.toError();
      }

      // Join the album and songs
      for (final album in albumResult.value) {
        final albumSongs = AlbumSongsDto(
          album: album,
          songs: songResult.value
              .where((song) => song.albumId == album.id)
              // TODO: needs to be sorted by track id
              //.sortedBy(keyOf)
              .toList(),
        );
        list.add(albumSongs);
      }

      // Join singles (album id is null)
      final singles = songResult.value
          .where((song) => song.albumId == null)
          .sortedBy((song) => song.title)
          .toList();
      if (singles.isNotEmpty) {
        list.add(
          AlbumSongsDto(
            songs: songResult.value
                .where((song) => song.albumId == null)
                .sortedBy((song) => song.title)
                .toList(),
          ),
        );
      }

      return Result.ok(list);
    });
  }

  @override
  FutureResult<void> cacheArtist(int artistId) =>
      _cacheHelper.cacheArtist(artistId);
}
