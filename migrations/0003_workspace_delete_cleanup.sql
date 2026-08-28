DELETE FROM audit_log
WHERE workspace_id NOT IN (SELECT id FROM workspaces);

CREATE INDEX IF NOT EXISTS idx_audit_workspace
ON audit_log(workspace_id);

CREATE TRIGGER IF NOT EXISTS delete_workspace_audit
AFTER DELETE ON workspaces
BEGIN
  DELETE FROM audit_log WHERE workspace_id = OLD.id;
END;
