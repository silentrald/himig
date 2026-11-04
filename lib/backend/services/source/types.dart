import "package:himig/backend/entities/song.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/utils/result.dart";

abstract class SourceService {
  /// Scan a specific source with every album and song then stores
  ///   the data in the database
  FutureResult<int> scanSource(Source source);

  /// If null is returned, then source does not support local handling
  Uri? getLocalSongUri(Source source, Song song);

  /// Check if the source can connect to a server. If it's local, always return true.
  FutureResult<bool> isConnected(Source source);
}

abstract class SourceImplementation<T extends Source> {
  /// Scan a specific source with every album and song then stores
  ///   the data in the database
  FutureResult<int> scanSource(T source);

  /// If null is returned, then source does not support local handling
  Uri? getLocalSongUri(T source, Song song);

  /// Check if the source can connect to a server. If it's local, always return true.
  FutureResult<bool> isConnected(T source);
}
