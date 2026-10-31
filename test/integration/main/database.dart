import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:himig/backend/database/main.dart";
import "package:himig/constant.dart" as constant;
import "package:sqflite_common_ffi/sqflite_ffi.dart";

const minDatabaseVersion = 1;

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  setUp(() {
    final file = File("./.dart_tool/sqflite_common_ffi/databases/test.sql");
    if (file.existsSync()) {
      file.deleteSync();
    }
  });

  test("Database Upgrade v1 -> v${constant.databaseVersion}", () async {
    for (
      var version = minDatabaseVersion;
      version <= constant.databaseVersion;
      ++version
    ) {
      try {
        final sqfliteDatabase = await openDatabase(
          "test.sql",
          version: version,
          onCreate: onCreateDatabase,
          onUpgrade: onUpgradeDatabase,
          onDowngrade: onDowngradeDatabase,
        );
        expect(await sqfliteDatabase.getVersion(), version);
        expect(sqfliteDatabase.isOpen, isTrue);
        await sqfliteDatabase.close();
      } on Exception catch (error) {
        fail("Upgrade issue v${version - 1} -> v$version due to $error");
      }
    }
  });

  test("Database full v${constant.databaseVersion}", () async {
    final sqfliteDatabase = await openDatabase(
      "test.sql",
      version: constant.databaseVersion,
      onCreate: onCreateDatabase,
      onUpgrade: onUpgradeDatabase,
      onDowngrade: onDowngradeDatabase,
    );
    expect(await sqfliteDatabase.getVersion(), constant.databaseVersion);
    expect(sqfliteDatabase.isOpen, isTrue);
    await sqfliteDatabase.close();
  });

  test("Database Downgrade v${constant.databaseVersion} -> v1", () async {
    for (
      var version = constant.databaseVersion;
      version >= minDatabaseVersion;
      --version
    ) {
      try {
        final sqfliteDatabase = await openDatabase(
          "test.sql",
          version: version,
          onCreate: onCreateDatabase,
          onUpgrade: onUpgradeDatabase,
          onDowngrade: onDowngradeDatabase,
        );
        expect(await sqfliteDatabase.getVersion(), version);
        expect(sqfliteDatabase.isOpen, isTrue);
        await sqfliteDatabase.close();
      } on Exception catch (error) {
        fail("Downgrade issue v${version + 1} -> v$version due to $error");
      }
    }
  });
}
