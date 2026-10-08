String getCreateTableAlbums() {
  return """
CREATE TABLE albums (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  source_id INTEGER NOT NULL,
  artist_id INTEGER NOT NULL,
  reference TEXT,
  release_year INT,
  cover_art_uri TEXT,
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (artist_id) REFERENCES artists(id)
)
"""
      .trim();
}
