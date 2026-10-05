BEGIN;

CREATE TABLE app_user_roles (
  app_user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  role VARCHAR(30) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (app_user_id, role),
  CONSTRAINT app_user_roles_role_check
    CHECK (role IN ('admin', 'trainer', 'member'))
);

INSERT INTO app_user_roles (app_user_id, role)
SELECT id, role
FROM app_users;

CREATE INDEX app_user_roles_role_idx ON app_user_roles (role);

ALTER TABLE app_users
  DROP CONSTRAINT app_users_profile_check,
  DROP CONSTRAINT app_users_role_check,
  DROP COLUMN role,
  ADD CONSTRAINT app_users_profile_check
    CHECK (member_id IS NULL OR trainer_id IS NULL);

COMMIT;
