String getCreateTableArtists() {
  return """
CREATE TABLE artists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  image_uri TEXT,
  CONSTRAINT unq_artists_name UNIQUE (name)
)
"""
      .trim();
}
