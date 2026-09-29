import "package:himig/backend/entities/song.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/backend/repos/repo.dart";
import "package:himig/backend/services/source/types.dart";
import "package:himig/utils/result.dart";

class MainSourceService extends SourceService {
  final SourceImplementation<FolderSource> _folderSourceImpl;
  final SourceImplementation<SubsonicSource> _subsonicSourceImpl;

  MainSourceService({
    required SourceImplementation<FolderSource> folderSourceImpl,
    required SourceImplementation<SubsonicSource> subsonicSourceImpl,
  }) : _folderSourceImpl = folderSourceImpl,
       _subsonicSourceImpl = subsonicSourceImpl;

  SourceImplementation<dynamic> _getImplementation(Source source) {
    switch (source) {
      case FolderSource():
        return _folderSourceImpl;

      case SubsonicSource():
        return _subsonicSourceImpl;

      // NOTE: Add the additional source implementation here
    }
  }

  @override
  Future<Result<int>> scanSource(Source source, RepoClient client) {
    return _getImplementation(source).scanSource(source, client);
  }

  @override
  Uri? getLocalSongUri(Source source, Song song) {
    return _getImplementation(source).getLocalSongUri(source, song);
  }
}
