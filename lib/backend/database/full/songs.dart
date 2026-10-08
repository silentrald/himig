String getCreateTableSongs() {
  return """
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
      .trim();
}
