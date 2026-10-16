BEGIN;

CREATE TABLE app_user_refresh_sessions (
  id UUID PRIMARY KEY,
  app_user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  current_token_hash CHAR(64) NOT NULL,
  previous_token_hash CHAR(64),
  previous_token_valid_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  last_used_at TIMESTAMPTZ NOT NULL,
  idle_expires_at TIMESTAMPTZ NOT NULL,
  absolute_expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  CONSTRAINT app_user_refresh_sessions_expiry_check
    CHECK (idle_expires_at <= absolute_expires_at)
);

CREATE INDEX app_user_refresh_sessions_user_idx
  ON app_user_refresh_sessions (app_user_id);
CREATE INDEX app_user_refresh_sessions_expiry_idx
  ON app_user_refresh_sessions (idle_expires_at);
CREATE INDEX app_user_refresh_sessions_user_active_idx
  ON app_user_refresh_sessions (app_user_id)
  WHERE revoked_at IS NULL;

COMMIT;
