import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:himig/backend/database/main.dart";
import "package:himig/backend/database/versions/supported.dart";
import "package:himig/constant.dart" as constant;
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/versions.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

const minDatabaseVersion = 1;
const upgradeDatabase = "test_up";
const downgradeDatabase = "test_down";
const fullDatabase = "test_full";
const databasePath = "./.dart_tool/sqflite_common_ffi/databases";

final upgradeQueries = {
  1: [
    """
INSERT INTO sources(id, name, type, data) VALUES
  (1, 'Local Source', 'folder', '{}'),
  (2, 'Remote Source', 'subsonic', '{}')
"""
        .trim(),
    """
INSERT INTO albums(id, name, reference, local_source_id, remote_source_id) VALUES
  (1, 'Album 1', 'album-1', 1, null),
  (2, 'Album 2', 'album-2', null, 2)
      """
        .trim(),
    """
INSERT INTO songs(title, duration, reference, local_source_id) VALUES
  ('title 1', 100, 'some-reference', 1),
  ('delete this', 100, 'some-reference', 1),
  ('title 2', 100, 'some-reference', 1),
  ('title 3', 100, 'some-reference', 1)
"""
        .trim(),
    "DELETE FROM songs where title = 'delete this'",
  ],
  2: [
    """
INSERT INTO songs(title, duration, reference, file_extension, remote_source_id)
VALUES ('title 5', 100, 'some-reference', 'mp3', 2)
        """
        .trim(),
  ],
};

void _deleteFile(String path) {
  final file = File(path);
  if (file.existsSync()) {
    file.deleteSync();
  }
}

Future<Database> _openDatabaseHelper(
  String name,
  int version,
  Version sqliteVersion,
) => openDatabase(
  "$name-v$sqliteVersion.sql",
  version: version,
  onCreate: (database, version) =>
      onCreateDatabase(database, version, sqliteVersion: sqliteVersion),
  onUpgrade: (database, oldVersion, newVersion) => onUpgradeDatabase(
    database,
    oldVersion,
    newVersion,
    sqliteVersion: sqliteVersion,
  ),
  onDowngrade: (database, oldVersion, newVersion) => onDowngradeDatabase(
    database,
    oldVersion,
    newVersion,
    sqliteVersion: sqliteVersion,
  ),
);

void main() {
  logger.setLevel(.silent);

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  for (final sqliteVersion in [
    // Minimal version support for "DROP COLUMN"
    dropColumnSupportedVersion,
    // Legacy version, sanity check if query works, but does not check if the query is supported or not
    Version.of("3.34.1"),
  ]) {
    _deleteFile("$databasePath/$upgradeDatabase-v$sqliteVersion.sql");
    _deleteFile("$databasePath/$downgradeDatabase-v$sqliteVersion.sql");
    _deleteFile("$databasePath/$fullDatabase-v$sqliteVersion.sql");

    test(
      "Database with sqlite v$sqliteVersion upgrade v1 -> v${constant.databaseVersion}",
      () async {
        for (
          var version = minDatabaseVersion;
          version <= constant.databaseVersion;
          ++version
        ) {
          Database? sqfliteDatabase;
          try {
            sqfliteDatabase = await _openDatabaseHelper(
              upgradeDatabase,
              version,
              sqliteVersion,
            );
            expect(await sqfliteDatabase.getVersion(), version);
            expect(sqfliteDatabase.isOpen, isTrue);

            for (final query in upgradeQueries[version] ?? []) {
              await sqfliteDatabase.execute(query);
            }
          } on Exception catch (error) {
            fail("Upgrade issue v${version - 1} -> v$version. Reason $error");
          } finally {
            await sqfliteDatabase?.close();
          }
        }
      },
    );

    test(
      "Database with sqlite v$sqliteVersion full v${constant.databaseVersion}",
      () async {
        Database? sqfliteDatabase;
        try {
          sqfliteDatabase = await _openDatabaseHelper(
            fullDatabase,
            constant.databaseVersion,
            sqliteVersion,
          );
          expect(await sqfliteDatabase.getVersion(), constant.databaseVersion);
          expect(sqfliteDatabase.isOpen, isTrue);
        } finally {
          await sqfliteDatabase?.close();
        }
      },
    );

    test(
      "Database with sqlite v$sqliteVersion Downgrade v${constant.databaseVersion} -> v1",
      () async {
        for (
          var version = constant.databaseVersion;
          version >= minDatabaseVersion;
          --version
        ) {
          Database? sqfliteDatabase;
          try {
            sqfliteDatabase = await _openDatabaseHelper(
              downgradeDatabase,
              version,
              sqliteVersion,
            );
            expect(await sqfliteDatabase.getVersion(), version);
            expect(sqfliteDatabase.isOpen, isTrue);
            await sqfliteDatabase.close();
          } on Exception catch (error) {
            // Error already logged
            fail("Downgrade issue v${version + 1} -> v$version. Reason $error");
          } finally {
            await sqfliteDatabase?.close();
          }
        }
      },
    );
  }
}
