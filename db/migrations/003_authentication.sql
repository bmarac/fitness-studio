BEGIN;

CREATE TABLE app_users (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  studio_id BIGINT NOT NULL REFERENCES studios(id),
  member_id BIGINT REFERENCES members(id),
  trainer_id BIGINT REFERENCES trainers(id),
  email VARCHAR(255) NOT NULL,
  password_hash TEXT NOT NULL,
  role VARCHAR(30) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT app_users_role_check
    CHECK (role IN ('admin', 'trainer', 'member')),
  CONSTRAINT app_users_status_check
    CHECK (status IN ('active', 'inactive', 'blocked')),
  CONSTRAINT app_users_profile_check
    CHECK (
      (role = 'member' AND member_id IS NOT NULL AND trainer_id IS NULL)
      OR
      (role = 'trainer' AND trainer_id IS NOT NULL AND member_id IS NULL)
      OR
      (role = 'admin' AND member_id IS NULL AND trainer_id IS NULL)
    ),
  CONSTRAINT app_users_studio_email_unique
    UNIQUE (studio_id, email)
);

CREATE UNIQUE INDEX app_users_member_id_unique
  ON app_users (member_id)
  WHERE member_id IS NOT NULL;

CREATE UNIQUE INDEX app_users_trainer_id_unique
  ON app_users (trainer_id)
  WHERE trainer_id IS NOT NULL;

CREATE INDEX app_users_studio_status_idx
  ON app_users (studio_id, status);

COMMIT;
