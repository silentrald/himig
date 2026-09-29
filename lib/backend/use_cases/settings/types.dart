import "package:himig/backend/entities/source.dart";
import "package:himig/utils/result.dart";

abstract class SettingsUseCase {
  Future<Result<void>> loadSources();
  Future<Result<void>> addSource(Source source);
  Future<Result<void>> editSource(Source source);

  /// Scan every sources with every album and song
  ///   then stores them in a database.
  Future<Result<int>> scanSources();
}
