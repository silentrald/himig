import "package:himig/backend/entities/album.dart";
import "package:himig/backend/errors/multi_project_error.dart";
import "package:himig/locales/enums.dart";
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
  required String reference,
  int? releaseYear,
  Uri? coverArtUri,
}) {
  expect(album.id, id);
  expect(album.name, name);
  expect(album.artistId, artistId);
  expect(album.artistName, artistName);
  expect(album.sourceId, sourceId);
  expect(album.localSourceId, localSourceId);
  expect(album.remoteSourceId, remoteSourceId);
  expect(album.reference, reference);
  expect(album.releaseYear, releaseYear);
  expect(album.coverArtUri, coverArtUri);
}

void _testValidAlbum({
  required String name,
  int? artistId,
  String? artistName,
  required int sourceId,
  int? localSourceId,
  int? remoteSourceId,
  required String reference,
  int? releaseYear,
  Uri? coverArtUri,
}) {
  final albumResult = Album.create(
    name: name,
    artistId: artistId,
    artistName: artistName,
    localSourceId: localSourceId,
    remoteSourceId: remoteSourceId,
    reference: reference,
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
    reference: reference,
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
        reference: "some-reference",
      ),
    );

    test(
      "Simple remote album",
      () => _testValidAlbum(
        name: "some album name",
        sourceId: 2,
        remoteSourceId: 2,
        reference: "some-reference",
      ),
    );

    test(
      "Simple mixed album",
      () => _testValidAlbum(
        name: "some album name",
        sourceId: 3,
        localSourceId: 3,
        remoteSourceId: 4,
        reference: "some-reference",
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
        reference: "some-reference",
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
        reference: "some-reference",
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
        reference: "some-reference",
        releaseYear: 2026,
        coverArtUri: Uri.parse("file://some/cover.png"),
      ),
    );

    test("No source id", () {
      final name = "some album name";
      final reference = "some reference";
      final albumResult = Album.create(name: name, reference: reference);

      expect(albumResult, isA<ResultError>());

      final error = albumResult.error;
      expect(error, isA<MultiProjectError>());

      final mpe = error as MultiProjectError;
      expect(mpe.errors.length, 1);

      final pe = mpe.errors[0];
      expect(pe.key, ErrorLocaleKey.entityAlbum);
      expect(pe.id, "sources");
      expect(pe.arguments, isNull);
    });
  });
}
