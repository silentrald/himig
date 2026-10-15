// ignore_for_file: file_names

import "package:himig/backend/database/version.dart";

class V1InitDatabaseVersion extends DatabaseVersion {
  @override
  List<String> getUpgradeChanges() {
    return [
      """
CREATE TABLE sources (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  data TEXT NOT NULL,
  CONSTRAINT unq_sources_name UNIQUE (name)
)
"""
          .trim(),
      """
CREATE TABLE artists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  image_uri TEXT,
  CONSTRAINT unq_artists_name UNIQUE (name)
)
"""
          .trim(),
      """
CREATE TABLE albums (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  local_source_id INTEGER,
  remote_source_id INTEGER,
  artist_id INTEGER,
  reference TEXT,
  release_year INT,
  cover_art_uri TEXT,
  FOREIGN KEY (local_source_id) REFERENCES sources(id),
  FOREIGN KEY (remote_source_id) REFERENCES sources(id),
  FOREIGN KEY (artist_id) REFERENCES artists(id)
)
"""
          .trim(),
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
  FOREIGN KEY (local_source_id) REFERENCES sources(id),
  FOREIGN KEY (remote_source_id) REFERENCES sources(id),
  FOREIGN KEY (album_id) REFERENCES albums(id),
  FOREIGN KEY (artist_id) REFERENCES artists(id)
)
"""
          .trim(),
    ];
  }

  @override
  List<String> getDowngradeChanges() {
    return [
      "DROP TABLE songs",
      "DROP TABLE albums",
      "DROP TABLE artists",
      "DROP TABLE sources",
      "PRAGMA foreign_keys = OFF",
    ];
  }
}
