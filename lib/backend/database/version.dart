abstract class DatabaseVersion {
  List<String> getUpgradeChanges();
  List<String> getDowngradeChanges();
}
