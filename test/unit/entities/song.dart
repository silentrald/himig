import "package:flutter_test/flutter_test.dart";
import "package:himig/backend/entities/song.dart";
import "package:himig/backend/errors/multi_project_error.dart";
import "package:himig/backend/errors/project_error.dart";
import "package:himig/locales/enums.dart";
import "package:himig/utils/result.dart";

void _expectSong(
  Song song, {
  int id = 0,
  required String title,
  String? albumName,
  String? artistName,
  required Duration duration,
  required String reference,
  int? releaseYear,

  required int sourceId,
  int? localSourceId,
  int? remoteSourceId,

  required Uri uri,
  Uri? localUri,
  Uri? remoteUri,

  Uri? coverArtUri,
  int? albumId,
  int? artistId,
}) {
  expect(song.id, id);
  expect(song.title, title);
  expect(song.albumName, albumName);
  expect(song.artistName, artistName);
  expect(song.duration, duration);
  expect(song.reference, reference);
  expect(song.releaseYear, releaseYear);

  expect(song.sourceId, sourceId);
  expect(song.localSourceId, localSourceId);
  expect(song.remoteSourceId, remoteSourceId);

  expect(song.uri, uri);
  expect(song.localUri, localUri);
  expect(song.remoteUri, remoteUri);

  expect(song.coverArtUri, coverArtUri);
  expect(song.albumId, albumId);
  expect(song.artistId, artistId);
}

void _testValidSong({
  required String title,
  String? albumName,
  String? artistName,
  required Duration duration,
  required String reference,
  int? releaseYear,

  required int sourceId,
  int? localSourceId,
  int? remoteSourceId,

  required Uri uri,
  Uri? localUri,
  Uri? remoteUri,

  Uri? coverArtUri,
  int? albumId,
  int? artistId,
}) {
  final songResult = Song.create(
    title: title,
    albumName: albumName,
    artistName: artistName,
    duration: duration,
    reference: reference,
    releaseYear: releaseYear,
    localSourceId: localSourceId,
    remoteSourceId: remoteSourceId,
    localUri: localUri,
    remoteUri: remoteUri,
    coverArtUri: coverArtUri,
    albumId: albumId,
    artistId: artistId,
  );

  expect(songResult, isA<ResultOk>());

  _expectSong(
    songResult.value,
    title: title,
    albumName: albumName,
    artistName: artistName,
    duration: duration,
    reference: reference,
    releaseYear: releaseYear,
    sourceId: sourceId,
    localSourceId: localSourceId,
    remoteSourceId: remoteSourceId,
    uri: uri,
    localUri: localUri,
    remoteUri: remoteUri,
    coverArtUri: coverArtUri,
    albumId: albumId,
    artistId: artistId,
  );
}

void _testInvalidSourceSong({
  int? localSourceId,
  int? remoteSourceId,
  Uri? localUri,
  Uri? remoteUri,
  required List<ProjectError> errors,
}) {
  final result = Song.create(
    title: "some random title",
    duration: Duration(seconds: 123),
    reference: "some-reference",
    localSourceId: localSourceId,
    remoteSourceId: remoteSourceId,
    localUri: localUri,
    remoteUri: remoteUri,
  );
  expect(result, isA<ResultError>());
  expect(result.error, isA<MultiProjectError>());
  expect((result.error as MultiProjectError).errors, containsAll(errors));
}

void main() {
  group("[Entity - Song]", () {
    test("Simple local song", () {
      final localSourceId = 1;
      final localUri = Uri.parse("file://some/local/song.mp3");
      _testValidSong(
        title: "some random title",
        duration: Duration(seconds: 123),
        reference: "some-id",
        sourceId: localSourceId,
        localSourceId: localSourceId,
        uri: localUri,
        localUri: localUri,
      );
    });

    test("Simple remote song", () {
      final remoteSourceId = 2;
      final remoteUri = Uri.parse("https://random-song.com");
      _testValidSong(
        title: "some random title",
        duration: Duration(seconds: 123),
        reference: "some-id",
        sourceId: remoteSourceId,
        localSourceId: remoteSourceId,
        uri: remoteUri,
        localUri: remoteUri,
      );
    });

    test("Simple mixed song", () {
      final localSourceId = 3;
      final remoteSourceId = 4;
      final localUri = Uri.parse("file://some/local/song.mp3");
      final remoteUri = Uri.parse("https://random-song.com");
      _testValidSong(
        title: "some random title",
        duration: Duration(seconds: 123),
        reference: "some-id",
        sourceId: localSourceId,
        localSourceId: localSourceId,
        remoteSourceId: remoteSourceId,
        uri: localUri,
        localUri: localUri,
        remoteUri: remoteUri,
      );
    });

    test("Full local song", () {
      final localSourceId = 1;
      final localUri = Uri.parse("file://some/local/song.mp3");

      _testValidSong(
        title: "some random title",
        albumName: "album",
        artistName: "artist",
        duration: Duration(seconds: 123),
        reference: "some-id",
        releaseYear: 2026,
        sourceId: localSourceId,
        localSourceId: localSourceId,
        uri: localUri,
        localUri: localUri,
        coverArtUri: Uri.parse("file://some/folder/cover.png"),
        albumId: 5,
        artistId: 6,
      );
    });

    test("Full remote song", () {
      final remoteSourceId = 2;
      final remoteUri = Uri.parse("https://random-song.com");

      _testValidSong(
        title: "some random title",
        albumName: "album",
        artistName: "artist",
        duration: Duration(seconds: 123),
        reference: "some-id",
        releaseYear: 2026,
        sourceId: remoteSourceId,
        remoteSourceId: remoteSourceId,
        uri: remoteUri,
        remoteUri: remoteUri,
        coverArtUri: Uri.parse("file://some/folder/cover.png"),
        albumId: 5,
        artistId: 6,
      );
    });

    test("Full mixed song", () {
      final localSourceId = 3;
      final remoteSourceId = 4;
      final localUri = Uri.parse("file://some/local/song.mp3");
      final remoteUri = Uri.parse("https://random-song.com");

      _testValidSong(
        title: "some random title",
        albumName: "album",
        artistName: "artist",
        duration: Duration(seconds: 123),
        reference: "some-id",
        releaseYear: 2026,
        sourceId: localSourceId,
        localSourceId: localSourceId,
        remoteSourceId: remoteSourceId,
        uri: localUri,
        localUri: localUri,
        remoteUri: remoteUri,
        coverArtUri: Uri.parse("file://some/folder/cover.png"),
        albumId: 5,
        artistId: 6,
      );
    });

    test(
      "Missing localUri for local song",
      () => _testInvalidSourceSong(
        localSourceId: 1,
        errors: [
          ProjectError(.entitySong, "pair", {"source": (.generic, "local")}),
          ProjectError(.entitySong, "sources"),
        ],
      ),
    );
    test(
      "Missing localSourceId for local song",
      () => _testInvalidSourceSong(
        localUri: Uri.parse("file://some/local/song.mp3"),
        errors: [
          ProjectError(.entitySong, "pair", {"source": (.generic, "local")}),
          ProjectError(.entitySong, "sources"),
        ],
      ),
    );
    test(
      "Missing remoteUri for remote song",
      () => _testInvalidSourceSong(
        remoteSourceId: 1,
        errors: [
          ProjectError(.entitySong, "pair", {"source": (.generic, "remote")}),
          ProjectError(.entitySong, "sources"),
        ],
      ),
    );
    test(
      "Missing remoteSourceId for remote song",
      () => _testInvalidSourceSong(
        remoteUri: Uri.parse("https://random-song.com"),
        errors: [
          ProjectError(.entitySong, "pair", {"source": (.generic, "remote")}),
          ProjectError(.entitySong, "sources"),
        ],
      ),
    );
    test(
      "Missing source and uri for song",
      () => _testInvalidSourceSong(
        errors: [ProjectError(.entitySong, "sources")],
      ),
    );
  });
}
