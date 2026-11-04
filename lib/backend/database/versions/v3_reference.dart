import "package:himig/backend/database/version.dart";
import "package:himig/backend/database/versions/supported.dart";
import "package:himig/utils/versions.dart";

class V3ReferenceDatabaseVersion extends DatabaseVersion {
  List<String> _dropSongsReferenceColumn(bool isDropColumnSupported) =>
      isDropColumnSupported
      ? ["ALTER TABLE songs DROP COLUMN reference"]
      : [
          "ALTER TABLE songs RENAME TO old_songs",
          """
CREATE TABLE songs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  duration INTEGER NOT NULL,
  release_year INTEGER,
  local_source_id INTEGER,
  local_uri TEXT,
  remote_source_id INTEGER,
  remote_uri TEXT,
  cover_art_uri TEXT,
  album_id INTEGER,
  artist_id INTEGER,
  file_extension TEXT NOT NULL,
  FOREIGN KEY (local_source_id) REFERENCES sources(id),
  FOREIGN KEY (remote_source_id) REFERENCES sources(id),
  FOREIGN KEY (album_id) REFERENCES albums(id),
  FOREIGN KEY (artist_id) REFERENCES artists(id)
)
            """
              .trim(),
          """
INSERT INTO songs(
  id, title, duration, release_year,
  local_source_id, local_uri,
  remote_source_id, remote_uri,
  cover_art_uri, album_id, artist_id, file_extension
)
SELECT
  id, title, duration, release_year,
  local_source_id, local_uri,
  remote_source_id, remote_uri,
  cover_art_uri, album_id, artist_id, 'mp3'
FROM old_songs
    """
              .trim(),
          "DROP TABLE old_songs",
        ];

  List<String> _addAlbumReferenceColumns(bool isDropColumnSupported) =>
      isDropColumnSupported
      ? [
          "ALTER TABLE albums ADD COLUMN local_path TEXT",
          "ALTER TABLE albums ADD COLUMN remote_id TEXT",
          """
UPDATE albums
SET local_path = reference
WHERE local_source_id IS NOT NULL
"""
              .trim(),
          """
UPDATE albums
SET remote_id = reference
WHERE remote_source_id IS NOT NULL
"""
              .trim(),
          "ALTER TABLE albums DROP COLUMN reference",
        ]
      : [
          "ALTER TABLE albums RENAME TO old_albums",
          """
CREATE TABLE albums (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  local_source_id INTEGER,
  remote_source_id INTEGER,
  artist_id INTEGER,
  release_year INT,
  cover_art_uri TEXT,
  local_path TEXT,
  remote_id TEXT,
  FOREIGN KEY (local_source_id) REFERENCES sources(id),
  FOREIGN KEY (remote_source_id) REFERENCES sources(id),
  FOREIGN KEY (artist_id) REFERENCES artists(id)
)
"""
              .trim(),
          """
INSERT INTO albums(
  id, name,
  local_source_id, remote_source_id,
  artist_id, release_year, cover_art_uri,
  local_path,
  remote_id
)
SELECT
  id, name,
  local_source_id, remote_source_id,
  artist_id, release_year, cover_art_uri,
  CASE
    WHEN local_source_id IS NOT NULL THEN reference
    ELSE null
  END,
  CASE
    WHEN remote_source_id IS NOT NULL THEN reference
    ELSE null
  END
FROM old_albums
          """
              .trim(),
          "DROP TABLE old_albums",
        ];

  @override
  List<String> getUpgradeChanges(Version sqliteVersion) {
    final isDropColumnSupported =
        sqliteVersion.compare(dropColumnSupportedVersion) >= 0;
    return [
      ?(isDropColumnSupported ? "PRAGMA foreign_keys = OFF" : null),
      ..._dropSongsReferenceColumn(isDropColumnSupported),
      ..._addAlbumReferenceColumns(isDropColumnSupported),

      // Adding local_path and remote_id to albums
      ?(isDropColumnSupported ? "PRAGMA foreign_keys = ON" : null),
    ];
  }

  @override
  List<String> getDowngradeChanges(Version sqliteVersion) => [
    "PRAGMA foreign_keys = OFF",

    // Merge the local_path and remote_id
    "ALTER TABLE albums ADD COLUMN reference TEXT",
    "UPDATE albums SET reference = COALESCE(remote_id, local_path)",
    "ALTER TABLE albums DROP COLUMN local_path",
    "ALTER TABLE albums DROP COLUMN remote_id",

    "ALTER TABLE songs RENAME TO old_songs",
    """
CREATE TABLE songs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  duration INTEGER NOT NULL,
  reference TEXT NOT NULL,
  release_year INTEGER,
  local_source_id INTEGER,
  local_uri TEXT,
  remote_source_id INTEGER,
  remote_uri TEXT,
  cover_art_uri TEXT,
  album_id INTEGER,
  artist_id INTEGER,
  file_extension TEXT NOT NULL,
  FOREIGN KEY (local_source_id) REFERENCES sources(id),
  FOREIGN KEY (remote_source_id) REFERENCES sources(id),
  FOREIGN KEY (album_id) REFERENCES albums(id),
  FOREIGN KEY (artist_id) REFERENCES artists(id)
)
"""
        .trim(),
    """
INSERT INTO songs(
  id, title, duration, reference, release_year,
  local_source_id, local_uri,
  remote_source_id, remote_uri,
  cover_art_uri, album_id, artist_id, file_extension
)
SELECT
  id, title, duration, 'X', release_year,
  local_source_id, local_uri,
  remote_source_id, remote_uri,
  cover_art_uri, album_id, artist_id, file_extension
FROM old_songs
          """
        .trim(),
    "DROP TABLE old_songs",
    "PRAGMA foreign_keys = ON",
  ];
}
