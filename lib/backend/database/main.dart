// ignore_for_file: no_leading_underscores_for_library_prefixes, library_prefixes

import "package:himig/backend/database/full/albums.dart";
import "package:himig/backend/database/full/artists.dart";
import "package:himig/backend/database/full/songs.dart";
import "package:himig/backend/database/full/source.dart";
import "package:himig/backend/database/version.dart";
import "package:himig/backend/database/versions/v1_init.dart";
import "package:himig/backend/database/versions/v2_file_extension.dart";
import "package:himig/constant.dart" as constant;
import "package:sqflite/sqlite_api.dart";

DatabaseVersion? _getDatabaseChanges(int version) => switch (version) {
  1 => V1InitDatabaseVersion(),
  2 => V2FileExtensionDatabaseVersion(),
  _ => null,
};

Future<void> onCreateDatabase(Database database, int version) async {
  if (version != constant.databaseVersion) {
    // Build the database from the scratch up until the current version
    return onUpgradeDatabase(database, 0, version);
  }

  // Enable foreign key support
  await database.execute("PRAGMA foreign_keys = ON");

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
  int newVersion,
) async {
  for (var version = oldVersion + 1; version <= newVersion; ++version) {
    for (var sql in _getDatabaseChanges(version)!.getUpgradeChanges()) {
      await database.execute(sql);
    }
  }
}

Future<void> onDowngradeDatabase(
  Database database,
  int oldVersion,
  int newVersion,
) async {
  for (var version = oldVersion; version >= newVersion; --version) {
    for (var sql in _getDatabaseChanges(version)!.getDowngradeChanges()) {
      await database.execute(sql);
    }
  }
}
