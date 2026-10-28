import "package:flutter_test/flutter_test.dart";
import "package:himig/backend/entities/album.dart";
import "package:himig/backend/entities/artist.dart";
import "package:himig/backend/use_cases/home/v1.dart";
import "package:himig/utils/result.dart";

import "../mock/repos/album.dart";
import "../mock/repos/artist.dart";
import "../mock/repos/main.dart";

void main() {
  group("[UseCase - Home V1]", () {
    final repoDatabase = MockRepoDatabase();
    final albumRepo = MockAlbumRepo();
    final artistRepo = MockArtistRepo();
    final homeUseCase = HomeUseCaseV1(
      database: repoDatabase,
      albumRepo: albumRepo,
      artistRepo: artistRepo,
    );

    final initialAlbums = [
      Album(id: 1, name: "My 1st album", reference: "reference"),
      Album(id: 2, name: "Last album", reference: "no-reference"),
    ];
    final initialArtists = [
      Artist(id: 1, name: "My"),
      Artist(id: 2, name: "Name"),
      Artist(id: 3, name: "Jeff"),
    ];

    setUp(() {
      albumRepo.setAlbumList(initialAlbums);
      artistRepo.setArtistList(initialArtists);
    });

    test("Get artist list", () async {
      final result = await homeUseCase.getArtistList();
      expect(result, isA<ResultOk>());
      for (final artist in initialArtists) {
        expect(result.value, contains(artist));
      }
      //expect(result.value, containsAll(initialArtists));
    });

    test("Get album list", () async {
      final result = await homeUseCase.getAlbumList();
      expect(result, isA<ResultOk>());
      expect(result.value, containsAll(initialAlbums));
    });
  });
}
