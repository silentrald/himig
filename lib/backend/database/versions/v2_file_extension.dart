import "package:himig/backend/database/version.dart";

class V2FileExtensionDatabaseVersion extends DatabaseVersion {
  @override
  List<String> getUpgradeChanges() => [
    "PRAGMA foreign_keys = OFF",
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
  file_extension text NOT NULL,
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
  id, title, duration, reference, release_year,
  local_source_id, local_uri,
  remote_source_id, remote_uri,
  cover_art_uri, album_id, artist_id, 'mp3'
FROM old_songs
          """
        .trim(),
    "DROP TABLE old_songs",
    "PRAGMA foreign_keys = ON",
  ];

  @override
  List<String> getDowngradeChanges() => [
    "ALTER TABLE songs DROP COLUMN file_extension",
  ];
}
