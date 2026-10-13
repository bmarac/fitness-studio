BEGIN;

-- Remove the abandoned invitation flow if its development-only migration was
-- previously applied. Codes were never deployed and are not migrated.
DROP TABLE IF EXISTS studio_invitations;

CREATE TEMP TABLE app_user_merge_map ON COMMIT DROP AS
SELECT
  id AS old_id,
  first_value(id) OVER (
    PARTITION BY lower(email)
    ORDER BY COALESCE(last_login_at, updated_at, created_at) DESC, id DESC
  ) AS keep_id
FROM app_users;

CREATE TABLE app_user_studios (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  app_user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  studio_id BIGINT NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  member_id BIGINT REFERENCES members(id),
  trainer_id BIGINT REFERENCES trainers(id),
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT app_user_studios_user_studio_unique UNIQUE (app_user_id, studio_id),
  CONSTRAINT app_user_studios_profile_check CHECK (member_id IS NULL OR trainer_id IS NULL),
  CONSTRAINT app_user_studios_status_check CHECK (status IN ('active', 'inactive', 'blocked'))
);

CREATE UNIQUE INDEX app_user_studios_member_unique
  ON app_user_studios (member_id) WHERE member_id IS NOT NULL;
CREATE UNIQUE INDEX app_user_studios_trainer_unique
  ON app_user_studios (trainer_id) WHERE trainer_id IS NOT NULL;
CREATE INDEX app_user_studios_studio_status_idx
  ON app_user_studios (studio_id, status);

INSERT INTO app_user_studios (
  app_user_id, studio_id, member_id, trainer_id, status, joined_at, updated_at
)
SELECT DISTINCT ON (merge.keep_id, users.studio_id)
       merge.keep_id, users.studio_id, users.member_id, users.trainer_id,
       users.status, users.created_at, users.updated_at
FROM app_users users
JOIN app_user_merge_map merge ON merge.old_id = users.id
ORDER BY merge.keep_id, users.studio_id,
         (users.status = 'active') DESC,
         COALESCE(users.last_login_at, users.updated_at, users.created_at) DESC,
         users.id DESC;

CREATE TABLE app_user_studio_roles (
  app_user_studio_id BIGINT NOT NULL REFERENCES app_user_studios(id) ON DELETE CASCADE,
  role VARCHAR(30) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (app_user_studio_id, role),
  CONSTRAINT app_user_studio_roles_role_check
    CHECK (role IN ('admin', 'trainer', 'member'))
);

INSERT INTO app_user_studio_roles (app_user_studio_id, role, created_at)
SELECT membership.id, role.role, role.created_at
FROM app_user_roles role
JOIN app_users users ON users.id = role.app_user_id
JOIN app_user_merge_map merge ON merge.old_id = users.id
JOIN app_user_studios membership
  ON membership.app_user_id = merge.keep_id
 AND membership.studio_id = users.studio_id;

UPDATE member_measurements target
SET recorded_by_user_id = merge.keep_id
FROM app_user_merge_map merge
WHERE target.recorded_by_user_id = merge.old_id
  AND merge.old_id <> merge.keep_id;

UPDATE membership_payment_obligations target
SET reported_by_user_id = merge.keep_id
FROM app_user_merge_map merge
WHERE target.reported_by_user_id = merge.old_id
  AND merge.old_id <> merge.keep_id;

UPDATE membership_payment_obligations target
SET confirmed_by_user_id = merge.keep_id
FROM app_user_merge_map merge
WHERE target.confirmed_by_user_id = merge.old_id
  AND merge.old_id <> merge.keep_id;

UPDATE app_notifications target
SET app_user_id = merge.keep_id
FROM app_user_merge_map merge
WHERE target.app_user_id = merge.old_id
  AND merge.old_id <> merge.keep_id;

UPDATE app_user_device_tokens target
SET app_user_id = merge.keep_id
FROM app_user_merge_map merge
WHERE target.app_user_id = merge.old_id
  AND merge.old_id <> merge.keep_id;

CREATE INDEX app_user_studio_roles_role_idx ON app_user_studio_roles (role);

DROP TABLE app_user_roles;

DELETE FROM app_users users
USING app_user_merge_map merge
WHERE users.id = merge.old_id
  AND merge.old_id <> merge.keep_id;

UPDATE app_users SET email = lower(trim(email));

DROP INDEX app_users_studio_status_idx;
DROP INDEX app_users_member_id_unique;
DROP INDEX app_users_trainer_id_unique;

ALTER TABLE app_users
  DROP CONSTRAINT app_users_studio_email_unique,
  DROP CONSTRAINT app_users_profile_check,
  DROP CONSTRAINT app_users_studio_id_fkey,
  DROP CONSTRAINT app_users_member_id_fkey,
  DROP CONSTRAINT app_users_trainer_id_fkey,
  DROP COLUMN studio_id,
  DROP COLUMN member_id,
  DROP COLUMN trainer_id;

CREATE UNIQUE INDEX app_users_email_unique ON app_users (lower(email));
CREATE INDEX app_users_status_idx ON app_users (status);

-- Preserve join codes from the abandoned studios.public_code implementation
-- when upgrading a development database that already contains that column.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'studios'
      AND column_name = 'public_code'
  ) THEN
    EXECUTE $sql$
      INSERT INTO studio_settings (studio_id, setting, value, value_type)
      SELECT id, 'join_code', upper(trim(public_code)), 'string'
      FROM studios
      WHERE public_code IS NOT NULL AND trim(public_code) <> ''
      ON CONFLICT (studio_id, setting) DO UPDATE SET
        value = EXCLUDED.value,
        value_type = EXCLUDED.value_type,
        updated_at = now()
    $sql$;
    EXECUTE 'ALTER TABLE studios DROP COLUMN public_code';
  END IF;
END $$;

INSERT INTO studio_settings (studio_id, setting, value, value_type)
VALUES (1, 'join_code', 'STAYFIT', 'string')
ON CONFLICT (studio_id, setting) DO NOTHING;

CREATE UNIQUE INDEX studio_settings_join_code_unique
  ON studio_settings (upper(value))
  WHERE setting = 'join_code';

COMMIT;
