import "package:himig/backend/entities/album.dart";
import "package:himig/backend/errors/multi_project_error.dart";
import "package:himig/backend/errors/project_error.dart";
import "package:himig/utils/result.dart";
import "package:test/test.dart";

void _expectAlbum(
  Album album, {
  int id = 0,
  required String name,
  int? artistId,
  String? artistName,
  required int sourceId,
  int? localSourceId,
  int? remoteSourceId,
  int? releaseYear,
  Uri? coverArtUri,
  String? localPath,
  String? remoteId,
}) {
  expect(album.id, id);
  expect(album.name, name);
  expect(album.artistId, artistId);
  expect(album.artistName, artistName);
  expect(album.sourceId, sourceId);
  expect(album.localSourceId, localSourceId);
  expect(album.remoteSourceId, remoteSourceId);
  expect(album.releaseYear, releaseYear);
  expect(album.coverArtUri, coverArtUri);
  expect(album.localPath, localPath);
  expect(album.remoteId, remoteId);
}

void _testValidAlbum({
  required String name,
  int? artistId,
  String? artistName,
  required int sourceId,
  int? localSourceId,
  int? remoteSourceId,
  int? releaseYear,
  Uri? coverArtUri,
  String? localPath,
  String? remoteId,
}) {
  final albumResult = Album.create(
    name: name,
    artistId: artistId,
    artistName: artistName,
    localSourceId: localSourceId,
    remoteSourceId: remoteSourceId,
    localPath: localPath,
    remoteId: remoteId,
    releaseYear: releaseYear,
    coverArtUri: coverArtUri,
  );

  expect(albumResult, isA<ResultOk>());

  final album = albumResult.value;
  _expectAlbum(
    album,
    name: name,
    artistId: artistId,
    artistName: artistName,
    sourceId: sourceId,
    localSourceId: localSourceId,
    remoteSourceId: remoteSourceId,
    localPath: localPath,
    remoteId: remoteId,
    releaseYear: releaseYear,
    coverArtUri: coverArtUri,
  );
}

void main() {
  group("[Entity - Album]", () {
    test(
      "Simple local album",
      () => _testValidAlbum(
        name: "some album name",
        sourceId: 1,
        localSourceId: 1,
        localPath: "some-reference",
      ),
    );

    test(
      "Simple remote album",
      () => _testValidAlbum(
        name: "some album name",
        sourceId: 2,
        remoteSourceId: 2,
        remoteId: "some-reference",
      ),
    );

    test(
      "Simple mixed album",
      () => _testValidAlbum(
        name: "some album name",
        sourceId: 3,
        localSourceId: 3,
        remoteSourceId: 4,
        localPath: "some-local",
        remoteId: "some-remote",
      ),
    );

    test(
      "Full local album",
      () => _testValidAlbum(
        name: "some album name",
        artistId: 5,
        artistName: "Hello artist",
        sourceId: 6,
        localSourceId: 6,
        localPath: "asdfasdf",
        releaseYear: 2026,
        coverArtUri: Uri.parse("file://some/cover.png"),
      ),
    );

    test(
      "Full remote album",
      () => _testValidAlbum(
        name: "some album name",
        artistId: 7,
        artistName: "Hello artist",
        sourceId: 8,
        remoteSourceId: 8,
        remoteId: "some-id",
        releaseYear: 2026,
        coverArtUri: Uri.parse("file://some/cover.png"),
      ),
    );

    test(
      "Full mixed album",
      () => _testValidAlbum(
        name: "some album name",
        artistId: 9,
        artistName: "Hello artist",
        sourceId: 10,
        localSourceId: 10,
        remoteSourceId: 11,
        localPath: "local-path",
        remoteId: "remote-id",
        releaseYear: 2026,
        coverArtUri: Uri.parse("file://some/cover.png"),
      ),
    );

    group("Errors", () {
      void _testInvalidAlbum({
        int? localSourceId,
        int? remoteSourceId,
        String? localPath,
        String? remoteId,
        required List<ProjectError> errors,
      }) {
        final result = Album.create(
          name: "somea album name",
          localSourceId: localSourceId,
          remoteSourceId: remoteSourceId,
          localPath: localPath,
          remoteId: remoteId,
        );
        expect(result, isA<ResultError>());
        expect(result.error, isA<MultiProjectError>());
        expect((result.error as MultiProjectError).errors, containsAll(errors));
      }

      test(
        "Missing local source Id",
        () => _testInvalidAlbum(
          localPath: "some-path",
          errors: [
            ProjectError(.entityAlbum, "pair", {"source": (.generic, "local")}),
            ProjectError(.entityAlbum, "sources"),
          ],
        ),
      );

      test(
        "Missing local path",
        () => _testInvalidAlbum(
          localSourceId: 1,
          errors: [
            ProjectError(.entityAlbum, "pair", {"source": (.generic, "local")}),
            ProjectError(.entityAlbum, "sources"),
          ],
        ),
      );

      test(
        "Missing remote source id",
        () => _testInvalidAlbum(
          remoteId: "asdfasdfasdfasdf",
          errors: [
            ProjectError(.entityAlbum, "pair", {
              "source": (.generic, "remote"),
            }),
            ProjectError(.entityAlbum, "sources"),
          ],
        ),
      );

      test(
        "Missing remote path",
        () => _testInvalidAlbum(
          remoteSourceId: 2,
          errors: [
            ProjectError(.entityAlbum, "pair", {
              "source": (.generic, "remote"),
            }),
            ProjectError(.entityAlbum, "sources"),
          ],
        ),
      );

      test(
        "Missing sources/references",
        () =>
            _testInvalidAlbum(errors: [ProjectError(.entityAlbum, "sources")]),
      );
    });
  });
}
