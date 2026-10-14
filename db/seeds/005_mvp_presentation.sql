BEGIN;

-- Keep the demo studio ready for the complete MVP walkthrough. This seed is
-- intentionally idempotent so it can also be applied to an existing demo
-- database without removing or resetting user-created data.
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
  'Mia',
  'Radić',
  'mia.radic@stayfitjoyful.demo',
  '+385 91 555 0199',
  '1998-05-16'::DATE,
  'active'
FROM studios
WHERE studios.name = 'Stay Fit & Joyful'
ON CONFLICT (studio_id, email) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  phone = EXCLUDED.phone,
  date_of_birth = EXCLUDED.date_of_birth,
  status = EXCLUDED.status,
  updated_at = now();

INSERT INTO studio_settings (studio_id, setting, value, value_type)
SELECT studios.id, settings.setting, settings.value, 'string'
FROM studios
CROSS JOIN (VALUES
  ('payment_recipient_name', 'Stay Fit & Joyful'),
  ('payment_iban', 'HR1723600001101234565'),
  ('payment_model', 'HR00'),
  ('payment_reference', '12345'),
  ('payment_description', 'Clanarina'),
  ('payment_member_reminder_days', '0,1'),
  ('payment_admin_reminder_days', '2'),
  ('payment_notification_time', '09:00')
) AS settings(setting, value)
WHERE studios.name = 'Stay Fit & Joyful'
ON CONFLICT (studio_id, setting) DO UPDATE SET
  value = EXCLUDED.value,
  value_type = EXCLUDED.value_type,
  updated_at = now();

-- Extend every active demo schedule through the next four weeks. Existing
-- sessions are preserved and the recurring-session unique index prevents
-- duplicates when this seed is run again.
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
  generated.starts_at,
  generated.starts_at + make_interval(mins => schedules.duration_minutes),
  schedules.capacity,
  'scheduled'
FROM recurring_class_schedules AS schedules
JOIN studios ON studios.id = schedules.studio_id
CROSS JOIN generate_series(
  date_trunc('week', CURRENT_DATE),
  date_trunc('week', CURRENT_DATE) + INTERVAL '4 weeks',
  INTERVAL '1 week'
) AS generated_weeks(week_start)
CROSS JOIN LATERAL (
  SELECT (
    generated_weeks.week_start::DATE
      + (schedules.day_of_week - 1)
      + schedules.starts_at_time
  ) AT TIME ZONE studios.timezone AS starts_at
) AS generated
WHERE studios.name = 'Stay Fit & Joyful'
  AND schedules.status = 'active'
  AND generated.starts_at > now()
  AND generated.starts_at::DATE >= schedules.valid_from
  AND (schedules.valid_until IS NULL OR generated.starts_at::DATE <= schedules.valid_until)
  AND NOT EXISTS (
    SELECT 1
    FROM class_sessions AS existing
    WHERE existing.recurring_schedule_id = schedules.id
      AND existing.starts_at = generated.starts_at
  );

-- Populate fixed-schedule bookings only when the member has never had a
-- booking for that session. A deliberately cancelled booking therefore stays
-- cancelled after rerunning the seed.
INSERT INTO bookings (
  studio_id,
  member_id,
  class_session_id,
  status,
  booked_at,
  booking_source
)
SELECT
  fixed_schedules.studio_id,
  fixed_schedules.member_id,
  sessions.id,
  'booked',
  LEAST(sessions.starts_at - INTERVAL '14 days', now()),
  'fixed_schedule'
FROM member_fixed_schedules AS fixed_schedules
JOIN studios ON studios.id = fixed_schedules.studio_id
JOIN class_sessions AS sessions
  ON sessions.recurring_schedule_id = fixed_schedules.recurring_schedule_id
WHERE studios.name = 'Stay Fit & Joyful'
  AND fixed_schedules.status = 'active'
  AND sessions.status = 'scheduled'
  AND sessions.starts_at > now()
  AND sessions.starts_at::DATE >= fixed_schedules.starts_on
  AND (fixed_schedules.ends_on IS NULL OR sessions.starts_at::DATE <= fixed_schedules.ends_on)
  AND NOT EXISTS (
    SELECT 1
    FROM bookings AS existing
    WHERE existing.member_id = fixed_schedules.member_id
      AND existing.class_session_id = sessions.id
  );

-- Enable billing for the member used in the presentation. The first run uses
-- today's date as the stable monthly anchor; later runs keep that original
-- anchor and do not create another obligation.
UPDATE member_memberships AS memberships
SET
  billing_starts_on = CURRENT_DATE,
  next_billing_on = CURRENT_DATE,
  updated_at = now()
FROM members
WHERE memberships.member_id = members.id
  AND members.email = 'ana.horvat@stayfitjoyful.demo'
  AND members.studio_id = (
    SELECT id FROM studios WHERE name = 'Stay Fit & Joyful'
  )
  AND memberships.billing_starts_on IS NULL;

INSERT INTO membership_payment_obligations (
  studio_id,
  member_membership_id,
  period_starts_on,
  period_ends_on,
  due_on,
  plan_name,
  full_amount,
  amount_due,
  currency,
  status,
  recipient_name,
  iban,
  payment_model,
  payment_reference,
  payment_description
)
SELECT
  memberships.studio_id,
  memberships.id,
  memberships.billing_starts_on,
  (memberships.billing_starts_on + INTERVAL '1 month')::DATE,
  memberships.billing_starts_on,
  plans.name,
  plans.price_amount,
  plans.price_amount,
  plans.currency,
  'pending',
  'Stay Fit & Joyful',
  'HR1723600001101234565',
  'HR00',
  '12345',
  'Clanarina'
FROM member_memberships AS memberships
JOIN members ON members.id = memberships.member_id
JOIN membership_plans AS plans ON plans.id = memberships.membership_plan_id
JOIN studios ON studios.id = memberships.studio_id
WHERE studios.name = 'Stay Fit & Joyful'
  AND members.email = 'ana.horvat@stayfitjoyful.demo'
  AND memberships.billing_starts_on IS NOT NULL
ON CONFLICT (member_membership_id, period_starts_on) DO NOTHING;

UPDATE member_memberships AS memberships
SET
  next_billing_on = (memberships.billing_starts_on + INTERVAL '1 month')::DATE,
  updated_at = now()
FROM members
WHERE memberships.member_id = members.id
  AND members.email = 'ana.horvat@stayfitjoyful.demo'
  AND members.studio_id = (
    SELECT id FROM studios WHERE name = 'Stay Fit & Joyful'
  )
  AND memberships.billing_starts_on IS NOT NULL
  AND memberships.next_billing_on <= memberships.billing_starts_on;

COMMIT;
