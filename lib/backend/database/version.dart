import "package:himig/utils/versions.dart";

abstract class DatabaseVersion {
  List<String> getUpgradeChanges(Version sqliteVersion);
  List<String> getDowngradeChanges(Version sqliteVersion);
}
