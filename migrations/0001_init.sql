CREATE TABLE IF NOT EXISTS workspaces (
  id TEXT PRIMARY KEY,
  is_demo INTEGER NOT NULL DEFAULT 0,
  expires_at INTEGER,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS records (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK(kind IN ('expense', 'income')),
  record_date TEXT NOT NULL,
  description TEXT NOT NULL,
  amount_pence INTEGER NOT NULL CHECK(amount_pence >= 0),
  category TEXT NOT NULL,
  source TEXT NOT NULL CHECK(source IN ('manual', 'bank')),
  evidence_name TEXT,
  evidence_mime TEXT,
  evidence_data BLOB,
  invoice_number TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_records_workspace_date ON records(workspace_id, record_date DESC);

CREATE TABLE IF NOT EXISTS audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  workspace_id TEXT NOT NULL,
  record_id TEXT,
  action TEXT NOT NULL,
  detail TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
