import "package:himig/backend/entities/song.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/backend/services/source/types.dart";
import "package:himig/utils/result.dart";

class MockSourceService extends SourceService {
  bool _connected = false;

  @override
  FutureResult<int> scanSource(Source source) async {
    return Result.ok(0);
  }

  @override
  Uri? getLocalSongUri(Source source, Song song) {
    return null;
  }

  @override
  FutureResult<bool> isConnected(Source source) async {
    return Result.ok(_connected);
  }

  void setConnected(bool connected) {
    _connected = connected;
  }
}
