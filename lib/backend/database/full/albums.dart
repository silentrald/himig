String getCreateTableAlbums() {
  return """
CREATE TABLE albums (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  source_id INTEGER NOT NULL,
  artist TEXT,
  reference TEXT,
  release_year INT,
  cover_art_uri TEXT,
  FOREIGN KEY (source_id) REFERENCES sources(id)
)
""";
}
