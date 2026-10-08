// ignore_for_file: no_leading_underscores_for_library_prefixes, library_prefixes

import "package:himig/backend/database/full/albums.dart";
import "package:himig/backend/database/full/artists.dart";
import "package:himig/backend/database/full/songs.dart";
import "package:himig/backend/database/full/source.dart";
import "package:himig/backend/database/version.dart";
import "package:himig/backend/database/versions/v1_init.dart";
import "package:sqflite/sqlite_api.dart";

DatabaseVersion? _getDatabaseChanges(int version) {
  switch (version) {
    case 1:
      return V1InitDatabaseVersion();

    default:
      return null;
  }
}

Future<void> onCreateDatabase(Database database, int version) async {
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
  for (var version = oldVersion; version <= newVersion; ++version) {
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
