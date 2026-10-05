BEGIN;

ALTER TABLE members
  DROP CONSTRAINT members_email_key,
  ADD CONSTRAINT members_studio_email_unique UNIQUE (studio_id, email);

ALTER TABLE trainers
  DROP CONSTRAINT trainers_email_key,
  ADD CONSTRAINT trainers_studio_email_unique UNIQUE (studio_id, email);

ALTER TABLE class_types
  DROP CONSTRAINT class_types_name_key,
  ADD CONSTRAINT class_types_studio_name_unique UNIQUE (studio_id, name);

ALTER TABLE membership_plans
  DROP CONSTRAINT membership_plans_name_key,
  ADD CONSTRAINT membership_plans_studio_name_unique UNIQUE (studio_id, name);

COMMIT;
