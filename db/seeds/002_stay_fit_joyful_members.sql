BEGIN;

DELETE FROM member_measurements
WHERE member_id IN (
  SELECT id
  FROM members
  WHERE studio_id = (SELECT id FROM studios WHERE name = 'Stay Fit & Joyful')
    AND email IN (
      'ana.horvat@stayfitjoyful.demo',
      'ivan.kovac@stayfitjoyful.demo',
      'marija.babic@stayfitjoyful.demo',
      'luka.novak@stayfitjoyful.demo',
      'petra.maric@stayfitjoyful.demo',
      'tomislav.juric@stayfitjoyful.demo',
      'ema.peric@stayfitjoyful.demo',
      'nikola.bosnjak@stayfitjoyful.demo'
    )
);

DELETE FROM app_users
WHERE studio_id = (SELECT id FROM studios WHERE name = 'Stay Fit & Joyful')
  AND email IN (
    'ana.horvat@stayfitjoyful.demo',
    'ivan.kovac@stayfitjoyful.demo',
    'marija.babic@stayfitjoyful.demo',
    'luka.novak@stayfitjoyful.demo',
    'petra.maric@stayfitjoyful.demo',
    'tomislav.juric@stayfitjoyful.demo',
    'ema.peric@stayfitjoyful.demo',
    'nikola.bosnjak@stayfitjoyful.demo'
  );

DELETE FROM bookings
WHERE member_id IN (
  SELECT id
  FROM members
  WHERE studio_id = (SELECT id FROM studios WHERE name = 'Stay Fit & Joyful')
    AND email IN (
      'ana.horvat@stayfitjoyful.demo',
      'ivan.kovac@stayfitjoyful.demo',
      'marija.babic@stayfitjoyful.demo',
      'luka.novak@stayfitjoyful.demo',
      'petra.maric@stayfitjoyful.demo',
      'tomislav.juric@stayfitjoyful.demo',
      'ema.peric@stayfitjoyful.demo',
      'nikola.bosnjak@stayfitjoyful.demo'
    )
);

DELETE FROM member_fixed_schedules
WHERE member_id IN (
  SELECT id
  FROM members
  WHERE studio_id = (SELECT id FROM studios WHERE name = 'Stay Fit & Joyful')
    AND email IN (
      'ana.horvat@stayfitjoyful.demo',
      'ivan.kovac@stayfitjoyful.demo',
      'marija.babic@stayfitjoyful.demo',
      'luka.novak@stayfitjoyful.demo',
      'petra.maric@stayfitjoyful.demo',
      'tomislav.juric@stayfitjoyful.demo',
      'ema.peric@stayfitjoyful.demo',
      'nikola.bosnjak@stayfitjoyful.demo'
    )
);

DELETE FROM member_memberships
WHERE member_id IN (
  SELECT id
  FROM members
  WHERE studio_id = (SELECT id FROM studios WHERE name = 'Stay Fit & Joyful')
    AND email IN (
      'ana.horvat@stayfitjoyful.demo',
      'ivan.kovac@stayfitjoyful.demo',
      'marija.babic@stayfitjoyful.demo',
      'luka.novak@stayfitjoyful.demo',
      'petra.maric@stayfitjoyful.demo',
      'tomislav.juric@stayfitjoyful.demo',
      'ema.peric@stayfitjoyful.demo',
      'nikola.bosnjak@stayfitjoyful.demo'
    )
);

DELETE FROM members
WHERE studio_id = (SELECT id FROM studios WHERE name = 'Stay Fit & Joyful')
  AND email IN (
    'ana.horvat@stayfitjoyful.demo',
    'ivan.kovac@stayfitjoyful.demo',
    'marija.babic@stayfitjoyful.demo',
    'luka.novak@stayfitjoyful.demo',
    'petra.maric@stayfitjoyful.demo',
    'tomislav.juric@stayfitjoyful.demo',
    'ema.peric@stayfitjoyful.demo',
    'nikola.bosnjak@stayfitjoyful.demo'
  );

WITH member_data(first_name, last_name, email, phone, date_of_birth) AS (
  VALUES
    ('Ana', 'Horvat', 'ana.horvat@stayfitjoyful.demo', '+385 91 555 0101', '1992-04-12'::DATE),
    ('Ivan', 'Kovač', 'ivan.kovac@stayfitjoyful.demo', '+385 91 555 0102', '1988-11-03'::DATE),
    ('Marija', 'Babić', 'marija.babic@stayfitjoyful.demo', '+385 91 555 0103', '1995-07-21'::DATE),
    ('Luka', 'Novak', 'luka.novak@stayfitjoyful.demo', '+385 91 555 0104', '1990-02-17'::DATE),
    ('Petra', 'Marić', 'petra.maric@stayfitjoyful.demo', '+385 91 555 0105', '1997-09-08'::DATE),
    ('Tomislav', 'Jurić', 'tomislav.juric@stayfitjoyful.demo', '+385 91 555 0106', '1985-06-25'::DATE),
    ('Ema', 'Perić', 'ema.peric@stayfitjoyful.demo', '+385 91 555 0107', '2000-01-14'::DATE),
    ('Nikola', 'Bošnjak', 'nikola.bosnjak@stayfitjoyful.demo', '+385 91 555 0108', '1993-12-30'::DATE)
)
INSERT INTO members (
  studio_id,
  first_name,
  last_name,
  email,
  phone,
  date_of_birth,
  status
)
SELECT
  studios.id,
  member_data.first_name,
  member_data.last_name,
  member_data.email,
  member_data.phone,
  member_data.date_of_birth,
  'active'
FROM member_data
JOIN studios ON studios.name = 'Stay Fit & Joyful';

WITH membership_data(email, plan_name) AS (
  VALUES
    ('ana.horvat@stayfitjoyful.demo', 'Grupni trening 2x tjedno'),
    ('ivan.kovac@stayfitjoyful.demo', 'Grupni trening 1x tjedno'),
    ('marija.babic@stayfitjoyful.demo', 'Grupni trening 3x tjedno'),
    ('luka.novak@stayfitjoyful.demo', 'Grupni trening 2x tjedno'),
    ('petra.maric@stayfitjoyful.demo', 'Grupni trening 2x tjedno'),
    ('tomislav.juric@stayfitjoyful.demo', 'Grupni trening 3x tjedno'),
    ('ema.peric@stayfitjoyful.demo', 'Grupni trening 1x tjedno'),
    ('nikola.bosnjak@stayfitjoyful.demo', 'Grupni trening 3x tjedno')
)
INSERT INTO member_memberships (
  studio_id,
  member_id,
  membership_plan_id,
  starts_on,
  ends_on,
  status
)
SELECT
  members.studio_id,
  members.id,
  plans.id,
  CURRENT_DATE - 7,
  CURRENT_DATE + 22,
  'active'
FROM membership_data
JOIN members ON members.email = membership_data.email
JOIN membership_plans AS plans
  ON plans.studio_id = members.studio_id
  AND plans.name = membership_data.plan_name;

WITH assignment_data(
  email,
  day_of_week,
  starts_at_time,
  class_type_name,
  trainer_first_name
) AS (
  VALUES
    ('ana.horvat@stayfitjoyful.demo', 1, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('ana.horvat@stayfitjoyful.demo', 3, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('ivan.kovac@stayfitjoyful.demo', 1, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('marija.babic@stayfitjoyful.demo', 1, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('marija.babic@stayfitjoyful.demo', 2, '18:00'::TIME, 'Pilates', 'Kristina'),
    ('marija.babic@stayfitjoyful.demo', 3, '17:00'::TIME, 'Kružni pilates', 'Kristina'),
    ('luka.novak@stayfitjoyful.demo', 1, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('luka.novak@stayfitjoyful.demo', 4, '18:00'::TIME, 'Pilates', 'Kristina'),
    ('petra.maric@stayfitjoyful.demo', 1, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('petra.maric@stayfitjoyful.demo', 2, '20:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('tomislav.juric@stayfitjoyful.demo', 1, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('tomislav.juric@stayfitjoyful.demo', 3, '20:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('tomislav.juric@stayfitjoyful.demo', 5, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('ema.peric@stayfitjoyful.demo', 1, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('nikola.bosnjak@stayfitjoyful.demo', 1, '19:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('nikola.bosnjak@stayfitjoyful.demo', 2, '09:00'::TIME, 'Trening snage i izdržljivosti', 'Filip'),
    ('nikola.bosnjak@stayfitjoyful.demo', 4, '09:00'::TIME, 'Trening snage i izdržljivosti', 'Filip')
)
INSERT INTO member_fixed_schedules (
  studio_id,
  member_id,
  recurring_schedule_id,
  starts_on,
  status
)
SELECT
  members.studio_id,
  members.id,
  schedules.id,
  date_trunc('week', CURRENT_DATE)::DATE,
  'active'
FROM assignment_data
JOIN members ON members.email = assignment_data.email
JOIN class_types
  ON class_types.studio_id = members.studio_id
  AND class_types.name = assignment_data.class_type_name
JOIN trainers
  ON trainers.studio_id = members.studio_id
  AND trainers.first_name = assignment_data.trainer_first_name
JOIN recurring_class_schedules AS schedules
  ON schedules.studio_id = members.studio_id
  AND schedules.class_type_id = class_types.id
  AND schedules.trainer_id = trainers.id
  AND schedules.day_of_week = assignment_data.day_of_week
  AND schedules.starts_at_time = assignment_data.starts_at_time
  AND schedules.status = 'active';

INSERT INTO bookings (
  studio_id,
  member_id,
  class_session_id,
  status,
  booked_at,
  attended_at,
  booking_source
)
SELECT
  fixed_schedules.studio_id,
  fixed_schedules.member_id,
  sessions.id,
  CASE WHEN sessions.ends_at < now() THEN 'attended' ELSE 'booked' END,
  LEAST(sessions.starts_at - INTERVAL '14 days', now()),
  CASE WHEN sessions.ends_at < now() THEN sessions.ends_at ELSE NULL END,
  'fixed_schedule'
FROM member_fixed_schedules AS fixed_schedules
JOIN class_sessions AS sessions
  ON sessions.recurring_schedule_id = fixed_schedules.recurring_schedule_id
  AND sessions.starts_at::DATE >= fixed_schedules.starts_on
  AND (
    fixed_schedules.ends_on IS NULL
    OR sessions.starts_at::DATE <= fixed_schedules.ends_on
  )
WHERE fixed_schedules.status = 'active';

WITH ana_cancelled_booking AS (
  SELECT bookings.id
  FROM bookings
  JOIN members ON members.id = bookings.member_id
  JOIN class_sessions ON class_sessions.id = bookings.class_session_id
  WHERE members.email = 'ana.horvat@stayfitjoyful.demo'
    AND bookings.status = 'booked'
    AND class_sessions.starts_at > now()
  ORDER BY class_sessions.starts_at
  OFFSET 1
  LIMIT 1
)
UPDATE bookings
SET
  status = 'cancelled',
  cancelled_at = now(),
  updated_at = now()
WHERE id = (SELECT id FROM ana_cancelled_booking);

COMMIT;
