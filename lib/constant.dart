import "package:package_info_plus/package_info_plus.dart";

String appName = "unknown";
String packageName = "unknown";
String version = "unknown";
String buildNumber = "unknown";

const int databaseVersion = 1;

Future<void> setup() async {
  final packageInfo = await PackageInfo.fromPlatform();

  appName = packageInfo.appName;
  packageName = packageInfo.packageName;
  version = packageInfo.version;
  buildNumber = packageInfo.buildNumber;
}
