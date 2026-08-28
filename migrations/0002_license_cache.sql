CREATE TABLE IF NOT EXISTS license_cache (
  token_hash TEXT PRIMARY KEY,
  valid INTEGER NOT NULL CHECK(valid IN (0, 1)),
  checked_at INTEGER NOT NULL
);
