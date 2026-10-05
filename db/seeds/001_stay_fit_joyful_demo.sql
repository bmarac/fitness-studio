BEGIN;

TRUNCATE TABLE
  app_user_roles,
  app_users,
  bookings,
  member_fixed_schedules,
  member_memberships,
  class_sessions,
  recurring_class_schedules,
  members,
  membership_plans,
  class_types,
  trainers,
  studio_settings,
  studios
RESTART IDENTITY CASCADE;

INSERT INTO studios (name, timezone, status)
VALUES ('Stay Fit & Joyful', 'Europe/Zagreb', 'active');

INSERT INTO studio_settings (studio_id, setting, value, value_type)
SELECT id, setting, value, value_type
FROM studios
CROSS JOIN (VALUES
  ('booking_mode', 'fixed_schedule', 'enum'),
  ('allow_makeups', 'true', 'boolean'),
  ('class_session_generation_weeks_ahead', '4', 'integer')
) AS settings(setting, value, value_type)
WHERE studios.name = 'Stay Fit & Joyful';

INSERT INTO trainers (
  studio_id,
  first_name,
  last_name,
  email,
  status
)
SELECT
  studios.id,
  trainers.first_name,
  trainers.last_name,
  trainers.email,
  'active'
FROM studios
CROSS JOIN (VALUES
  ('Filip', 'Šarić', 'filip.saric@stayfitjoyful.demo'),
  ('Kristina', 'Lisec', 'kristina.lisec@stayfitjoyful.demo')
) AS trainers(first_name, last_name, email)
WHERE studios.name = 'Stay Fit & Joyful';

INSERT INTO class_types (
  studio_id,
  name,
  description,
  default_duration_minutes,
  default_capacity,
  difficulty_level,
  status
)
SELECT
  studios.id,
  class_types.name,
  class_types.description,
  60,
  8,
  'all_levels',
  'active'
FROM studios
CROSS JOIN (VALUES
  ('Pilates', 'Grupni pilates trening.'),
  ('Kružni pilates', 'Kružni grupni pilates trening.'),
  ('Trening snage i izdržljivosti', 'Grupni trening snage i izdržljivosti.')
) AS class_types(name, description)
WHERE studios.name = 'Stay Fit & Joyful';

INSERT INTO membership_plans (
  studio_id,
  name,
  description,
  duration_days,
  session_limit,
  session_limit_period,
  price_amount,
  currency,
  status
)
SELECT
  studios.id,
  plans.name,
  plans.description,
  30,
  plans.session_limit,
  'week',
  plans.price_amount,
  'EUR',
  'active'
FROM studios
CROSS JOIN (VALUES
  ('Grupni trening 1x tjedno', 'Jedan grupni trening tjedno.', 1, 45.00::NUMERIC),
  ('Grupni trening 2x tjedno', 'Dva grupna treninga tjedno.', 2, 70.00::NUMERIC),
  ('Grupni trening 3x tjedno', 'Tri grupna treninga tjedno.', 3, 85.00::NUMERIC)
) AS plans(name, description, session_limit, price_amount)
WHERE studios.name = 'Stay Fit & Joyful';

WITH schedule_data(day_of_week, starts_at_time, class_type_name, trainer_first_name) AS (
  VALUES
    (1, '10:00'::TIME, 'Pilates', 'Kristina'),
    (1, '17:00'::TIME, 'Kružni pilates', 'Kristina'),
    (1, '18:00'::TIME, 'Pilates', 'Kristina'),
    (1, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    (1, '19:00'::TIME, 'Pilates', 'Kristina'),
    (1, '20:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    (1, '21:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    (2, '09:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    (2, '17:00'::TIME, 'Trening snage i izdržljivosti', 'Kristina'),
    (2, '18:00'::TIME, 'Pilates', 'Kristina'),
    (2, '19:00'::TIME, 'Pilates', 'Kristina'),
    (2, '20:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    (3, '10:00'::TIME, 'Pilates', 'Kristina'),
    (3, '17:00'::TIME, 'Kružni pilates', 'Kristina'),
    (3, '18:00'::TIME, 'Pilates', 'Kristina'),
    (3, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    (3, '19:00'::TIME, 'Pilates', 'Kristina'),
    (3, '20:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    (3, '21:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    (4, '09:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    (4, '17:00'::TIME, 'Trening snage i izdržljivosti', 'Kristina'),
    (4, '18:00'::TIME, 'Pilates', 'Kristina'),
    (4, '19:00'::TIME, 'Pilates', 'Kristina'),
    (4, '20:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    (5, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip')
)
INSERT INTO recurring_class_schedules (
  studio_id,
  class_type_id,
  trainer_id,
  day_of_week,
  starts_at_time,
  duration_minutes,
  capacity,
  valid_from,
  status
)
SELECT
  studios.id,
  class_types.id,
  trainers.id,
  schedule_data.day_of_week,
  schedule_data.starts_at_time,
  60,
  8,
  date_trunc('week', CURRENT_DATE)::DATE,
  'active'
FROM schedule_data
JOIN studios ON studios.name = 'Stay Fit & Joyful'
JOIN class_types
  ON class_types.studio_id = studios.id
  AND class_types.name = schedule_data.class_type_name
JOIN trainers
  ON trainers.studio_id = studios.id
  AND trainers.first_name = schedule_data.trainer_first_name;

INSERT INTO class_sessions (
  studio_id,
  recurring_schedule_id,
  class_type_id,
  trainer_id,
  starts_at,
  ends_at,
  capacity,
  status
)
SELECT
  schedules.studio_id,
  schedules.id,
  schedules.class_type_id,
  schedules.trainer_id,
  (
    week_start::DATE + (schedules.day_of_week - 1)
      + schedules.starts_at_time
  ) AT TIME ZONE studios.timezone,
  (
    week_start::DATE + (schedules.day_of_week - 1)
      + schedules.starts_at_time
  ) AT TIME ZONE studios.timezone
    + make_interval(mins => schedules.duration_minutes),
  schedules.capacity,
  'scheduled'
FROM recurring_class_schedules AS schedules
JOIN studios ON studios.id = schedules.studio_id
CROSS JOIN generate_series(
  date_trunc('week', CURRENT_DATE),
  date_trunc('week', CURRENT_DATE) + INTERVAL '4 weeks',
  INTERVAL '1 week'
) AS generated_weeks(week_start)
WHERE schedules.status = 'active';

COMMIT;
