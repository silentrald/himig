// ignore_for_file: no_leading_underscores_for_library_prefixes, library_prefixes

import "package:himig/backend/database/full/albums.dart";
import "package:himig/backend/database/full/artists.dart";
import "package:himig/backend/database/full/songs.dart";
import "package:himig/backend/database/full/source.dart";
import "package:himig/backend/database/version.dart";
import "package:himig/backend/database/versions/v1_init.dart";
import "package:himig/backend/database/versions/v2_file_extension.dart";
import "package:himig/backend/database/versions/v3_reference.dart";
import "package:himig/constant.dart" as constant;
import "package:himig/utils/logger.dart" as logger;
import "package:himig/utils/versions.dart";
import "package:sqflite/sqlite_api.dart";

DatabaseVersion? _getDatabaseChanges(int version) => switch (version) {
  1 => V1InitDatabaseVersion(),
  2 => V2FileExtensionDatabaseVersion(),
  3 => V3ReferenceDatabaseVersion(),
  _ => null,
};

Future<Version> _getSqliteVersion(Database database) async {
  final versionQuery = await database.rawQuery(
    "SELECT sqlite_version() AS version",
  );
  return Version.of(versionQuery[0]["version"].toString());
}

Future<void> onCreateDatabase(
  Database database,
  int version, {
  Version? sqliteVersion, // For testing purposes
}) async {
  // Enable foreign key support
  await database.execute("PRAGMA foreign_keys = ON");

  if (version != constant.databaseVersion) {
    // Build the database from the scratch up until the current version
    return onUpgradeDatabase(
      database,
      0,
      version,
      sqliteVersion: sqliteVersion,
    );
  }

  for (var table in [
    getCreateTableSources(),
    getCreateTableArtists(),
    getCreateTableAlbums(), // requires sources,artists
    getCreateTableSongs(), // requires sources,albums
  ]) {
    await database.execute(table);
  }
}

Future<void> onUpgradeDatabase(
  Database database,
  int oldVersion,
  int newVersion, {
  Version? sqliteVersion, // For testing purposes
}) async {
  logger.info("Upgrading db version from v$oldVersion -> v$newVersion");

  sqliteVersion ??= await _getSqliteVersion(database);

  await database.execute("PRAGMA foreign_keys = ON");
  for (var version = oldVersion + 1; version <= newVersion; ++version) {
    for (var sql in _getDatabaseChanges(
      version,
    )!.getUpgradeChanges(sqliteVersion)) {
      await database.execute(sql);
    }
  }
}

Future<void> onDowngradeDatabase(
  Database database,
  int oldVersion,
  int newVersion, {
  Version? sqliteVersion, // For testing purposes
}) async {
  logger.info("Downgrading db version from v$oldVersion -> v$newVersion");

  sqliteVersion ??= await _getSqliteVersion(database);

  await database.execute("PRAGMA foreign_keys = ON");
  for (var version = oldVersion; version > newVersion; --version) {
    for (var sql in _getDatabaseChanges(
      version,
    )!.getDowngradeChanges(sqliteVersion)) {
      await database.execute(sql);
    }
  }
}
