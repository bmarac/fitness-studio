BEGIN;

CREATE INDEX class_sessions_studio_starts_at_idx
  ON class_sessions (studio_id, starts_at, id);

CREATE INDEX class_sessions_studio_trainer_starts_at_idx
  ON class_sessions (studio_id, trainer_id, starts_at, id);

COMMIT;
