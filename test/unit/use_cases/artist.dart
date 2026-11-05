import "package:collection/collection.dart";
import "package:flutter_test/flutter_test.dart";
import "package:himig/backend/dtos/album_songs.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/use_cases/artist/v1.dart";
import "package:himig/utils/result.dart";

import "../mock/helpers/cache.dart";
import "../mock/repos/album.dart";
import "../mock/repos/main.dart";
import "../mock/repos/song.dart";

void main() {
  group("[Use Case - Artist V1]", () {
    final repoDatabase = MockRepoDatabase();
    final albumRepo = MockAlbumRepo();
    final songRepo = MockSongRepo();
    final cacheHelper = MockCacheHelper();
    final artistUseCase = ArtistUseCaseV1(
      database: repoDatabase,
      albumRepo: albumRepo,
      songRepo: songRepo,
      cacheHelper: cacheHelper,
    );

    final albumSongsList1 = [
      AlbumSongsDto(
        album: Album(id: 1, artistId: 1, name: "My 1st album"),
        songs: [
          Song(
            title: "some song 1",
            duration: Duration(seconds: 123),
            fileExtension: "mp3",
            albumId: 1,
            artistId: 1,
          ),
          Song(
            title: "some song 2",
            duration: Duration(seconds: 124),
            fileExtension: "mp3",
            albumId: 1,
            artistId: 1,
          ),
          Song(
            title: "some song 3",
            duration: Duration(seconds: 125),
            fileExtension: "mp3",
            albumId: 1,
            artistId: 1,
          ),
          Song(
            title: "some song 4",
            duration: Duration(seconds: 126),
            fileExtension: "mp3",
            albumId: 1,
            artistId: 1,
          ),
        ],
      ),
      AlbumSongsDto(
        album: Album(id: 2, artistId: 1, name: "Last album"),
        songs: [
          Song(
            title: "other",
            duration: Duration(seconds: 120),
            fileExtension: "flac",
            albumId: 2,
            artistId: 1,
          ),
        ],
      ),
    ];
    final albumSongsList2 = [
      AlbumSongsDto(
        album: Album(id: 100, artistId: 2, name: "asdf"),
        songs: [
          Song(
            id: 100,
            albumId: 100,
            artistId: 2,
            title: "asdf",
            duration: Duration(seconds: 200),
            fileExtension: "mp3",
          ),
        ],
      ),
    ];

    final singleSong1 = Song(
      id: 999,
      artistId: 999,
      title: "a_something",
      duration: Duration(seconds: 999),
      fileExtension: "mp3",
    );
    final singleSong2 = Song(
      id: 1000,
      artistId: 999,
      title: "b_something",
      duration: Duration(seconds: 999),
      fileExtension: "mp3",
    );

    final initialAlbums = [
      ...albumSongsList1.map((as) => as.album!),
      ...albumSongsList2.map((as) => as.album!),
      Album(id: 420, artistId: 420, name: "Outside album"),
    ];
    final initialSongs = [
      ...albumSongsList1.map((as) => as.songs).flattened,
      ...albumSongsList2.map((as) => as.songs).flattened,
      singleSong2,
      singleSong1,
    ];

    setUp(() {
      albumRepo.setAlbumList(initialAlbums);
      songRepo.setSongList(initialSongs);
    });

    group("getAlbumSongsList", () {
      test("Get album songs list 1", () async {
        final artistId = 1;
        final result = await artistUseCase.getAlbumSongsList(artistId);
        expect(result, isA<ResultOk>());

        expect(result.value, containsAll(albumSongsList1));
      });

      test("Get album songs list 2", () async {
        final artistId = 2;
        final result = await artistUseCase.getAlbumSongsList(artistId);
        expect(result, isA<ResultOk>());

        expect(result.value, containsAll(albumSongsList2));
      });

      test("Get album songs list empty", () async {
        final result = await artistUseCase.getAlbumSongsList(404);
        expect(result, isA<ResultOk>());

        expect(result.value, isEmpty);
      });

      test(
        "Get album songs where songs has an artist but no albums (Singles)",
        () async {
          final result = await artistUseCase.getAlbumSongsList(999);
          expect(result, isA<ResultOk>());

          expect(
            result.value,
            contains(AlbumSongsDto(songs: [singleSong1, singleSong2])),
          );
        },
      );
    });
  });
}
