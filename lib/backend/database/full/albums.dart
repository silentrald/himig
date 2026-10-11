String getCreateTableAlbums() {
  return """
CREATE TABLE albums (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  local_source_id INTEGER,
  remote_source_id INTEGER,
  artist_id INTEGER NOT NULL,
  reference TEXT,
  release_year INT,
  cover_art_uri TEXT,
  FOREIGN KEY (local_source_id) REFERENCES sources(id),
  FOREIGN KEY (remote_source_id) REFERENCES sources(id),
  FOREIGN KEY (artist_id) REFERENCES artists(id)
)
"""
      .trim();
}
