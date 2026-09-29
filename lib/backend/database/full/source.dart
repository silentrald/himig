String getCreateTableSources() {
  return """
CREATE TABLE sources (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  data TEXT NOT NULL
)
"""
      .trim();
}
