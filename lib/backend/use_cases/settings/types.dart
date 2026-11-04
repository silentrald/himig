import "package:himig/backend/entities/source.dart";
import "package:himig/utils/result.dart";

abstract class SettingsUseCase {
  FutureResult<void> addSource(Source source);
  FutureResult<void> editSource(Source source);

  /// Scan every sources with every album and song
  ///   then stores them in a database.
  FutureResult<int> scanSources();

  FutureResult<Map<String, String>> getVersions();
}
