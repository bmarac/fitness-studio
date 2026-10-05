BEGIN;

CREATE TABLE studios (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  timezone VARCHAR(100) NOT NULL DEFAULT 'Europe/Zagreb',
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT studios_status_check
    CHECK (status IN ('active', 'inactive'))
);

CREATE TABLE studio_settings (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  studio_id BIGINT NOT NULL REFERENCES studios(id),
  setting VARCHAR(100) NOT NULL,
  value TEXT NOT NULL,
  value_type VARCHAR(30) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT studio_settings_value_type_check
    CHECK (value_type IN ('boolean', 'integer', 'decimal', 'string', 'enum')),
  CONSTRAINT studio_settings_studio_setting_unique
    UNIQUE (studio_id, setting)
);

INSERT INTO studios (name)
VALUES ('Fitness Studio');

INSERT INTO studio_settings (studio_id, setting, value, value_type)
SELECT id, 'booking_mode', 'open_booking', 'enum'
FROM studios
ORDER BY id
LIMIT 1;

ALTER TABLE members ADD COLUMN studio_id BIGINT;
ALTER TABLE trainers ADD COLUMN studio_id BIGINT;
ALTER TABLE class_types ADD COLUMN studio_id BIGINT;
ALTER TABLE class_sessions ADD COLUMN studio_id BIGINT;
ALTER TABLE bookings ADD COLUMN studio_id BIGINT;
ALTER TABLE membership_plans ADD COLUMN studio_id BIGINT;
ALTER TABLE member_memberships ADD COLUMN studio_id BIGINT;

UPDATE members
SET studio_id = (SELECT id FROM studios ORDER BY id LIMIT 1);

UPDATE trainers
SET studio_id = (SELECT id FROM studios ORDER BY id LIMIT 1);

UPDATE class_types
SET studio_id = (SELECT id FROM studios ORDER BY id LIMIT 1);

UPDATE class_sessions
SET studio_id = (SELECT id FROM studios ORDER BY id LIMIT 1);

UPDATE bookings
SET studio_id = (SELECT id FROM studios ORDER BY id LIMIT 1);

UPDATE membership_plans
SET studio_id = (SELECT id FROM studios ORDER BY id LIMIT 1);

UPDATE member_memberships
SET studio_id = (SELECT id FROM studios ORDER BY id LIMIT 1);

ALTER TABLE members
  ALTER COLUMN studio_id SET NOT NULL,
  ADD CONSTRAINT members_studio_id_fkey
    FOREIGN KEY (studio_id) REFERENCES studios(id);

ALTER TABLE trainers
  ALTER COLUMN studio_id SET NOT NULL,
  ADD CONSTRAINT trainers_studio_id_fkey
    FOREIGN KEY (studio_id) REFERENCES studios(id);

ALTER TABLE class_types
  ALTER COLUMN studio_id SET NOT NULL,
  ADD CONSTRAINT class_types_studio_id_fkey
    FOREIGN KEY (studio_id) REFERENCES studios(id);

ALTER TABLE class_sessions
  ALTER COLUMN studio_id SET NOT NULL,
  ADD CONSTRAINT class_sessions_studio_id_fkey
    FOREIGN KEY (studio_id) REFERENCES studios(id);

ALTER TABLE bookings
  ALTER COLUMN studio_id SET NOT NULL,
  ADD CONSTRAINT bookings_studio_id_fkey
    FOREIGN KEY (studio_id) REFERENCES studios(id);

ALTER TABLE membership_plans
  ALTER COLUMN studio_id SET NOT NULL,
  ADD CONSTRAINT membership_plans_studio_id_fkey
    FOREIGN KEY (studio_id) REFERENCES studios(id);

ALTER TABLE member_memberships
  ALTER COLUMN studio_id SET NOT NULL,
  ADD CONSTRAINT member_memberships_studio_id_fkey
    FOREIGN KEY (studio_id) REFERENCES studios(id);

CREATE INDEX members_studio_id_idx ON members (studio_id);
CREATE INDEX trainers_studio_id_idx ON trainers (studio_id);
CREATE INDEX class_types_studio_id_idx ON class_types (studio_id);
CREATE INDEX class_sessions_studio_id_idx ON class_sessions (studio_id);
CREATE INDEX bookings_studio_id_idx ON bookings (studio_id);
CREATE INDEX membership_plans_studio_id_idx ON membership_plans (studio_id);
CREATE INDEX member_memberships_studio_id_idx ON member_memberships (studio_id);
CREATE INDEX studio_settings_studio_id_idx ON studio_settings (studio_id);

CREATE TABLE recurring_class_schedules (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  studio_id BIGINT NOT NULL REFERENCES studios(id),
  class_type_id BIGINT NOT NULL REFERENCES class_types(id),
  trainer_id BIGINT NOT NULL REFERENCES trainers(id),
  day_of_week SMALLINT NOT NULL,
  starts_at_time TIME NOT NULL,
  duration_minutes INTEGER NOT NULL,
  capacity INTEGER NOT NULL,
  room_name VARCHAR(120),
  valid_from DATE NOT NULL,
  valid_until DATE,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT recurring_class_schedules_day_check
    CHECK (day_of_week BETWEEN 1 AND 7),
  CONSTRAINT recurring_class_schedules_duration_check
    CHECK (duration_minutes > 0),
  CONSTRAINT recurring_class_schedules_capacity_check
    CHECK (capacity > 0),
  CONSTRAINT recurring_class_schedules_dates_check
    CHECK (valid_until IS NULL OR valid_until >= valid_from),
  CONSTRAINT recurring_class_schedules_status_check
    CHECK (status IN ('active', 'inactive'))
);

CREATE INDEX recurring_class_schedules_studio_id_idx
  ON recurring_class_schedules (studio_id);

CREATE INDEX recurring_class_schedules_schedule_idx
  ON recurring_class_schedules (studio_id, day_of_week, starts_at_time);

ALTER TABLE class_sessions
  ADD COLUMN recurring_schedule_id BIGINT,
  ADD CONSTRAINT class_sessions_recurring_schedule_id_fkey
    FOREIGN KEY (recurring_schedule_id) REFERENCES recurring_class_schedules(id);

CREATE UNIQUE INDEX class_sessions_recurring_starts_at_unique
  ON class_sessions (recurring_schedule_id, starts_at)
  WHERE recurring_schedule_id IS NOT NULL;

CREATE TABLE member_fixed_schedules (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  studio_id BIGINT NOT NULL REFERENCES studios(id),
  member_id BIGINT NOT NULL REFERENCES members(id),
  recurring_schedule_id BIGINT NOT NULL REFERENCES recurring_class_schedules(id),
  starts_on DATE NOT NULL,
  ends_on DATE,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT member_fixed_schedules_dates_check
    CHECK (ends_on IS NULL OR ends_on >= starts_on),
  CONSTRAINT member_fixed_schedules_status_check
    CHECK (status IN ('active', 'paused', 'cancelled'))
);

CREATE INDEX member_fixed_schedules_member_idx
  ON member_fixed_schedules (studio_id, member_id, status);

CREATE INDEX member_fixed_schedules_schedule_idx
  ON member_fixed_schedules (recurring_schedule_id, status);

CREATE UNIQUE INDEX member_fixed_schedules_one_active_assignment
  ON member_fixed_schedules (member_id, recurring_schedule_id)
  WHERE status IN ('active', 'paused');

ALTER TABLE membership_plans
  ADD COLUMN session_limit_period VARCHAR(30);

UPDATE membership_plans
SET session_limit_period = 'membership'
WHERE session_limit IS NOT NULL;

ALTER TABLE membership_plans
  ADD CONSTRAINT membership_plans_session_limit_period_check
    CHECK (session_limit_period IS NULL OR session_limit_period IN ('week', 'month', 'membership')),
  ADD CONSTRAINT membership_plans_session_limit_pair_check
    CHECK (
      (session_limit IS NULL AND session_limit_period IS NULL)
      OR
      (session_limit IS NOT NULL AND session_limit_period IS NOT NULL)
    );

ALTER TABLE bookings
  ADD COLUMN booking_source VARCHAR(30) NOT NULL DEFAULT 'self_service',
  ADD COLUMN makeup_for_booking_id BIGINT,
  ADD CONSTRAINT bookings_booking_source_check
    CHECK (booking_source IN ('self_service', 'fixed_schedule', 'makeup', 'admin')),
  ADD CONSTRAINT bookings_makeup_for_booking_id_fkey
    FOREIGN KEY (makeup_for_booking_id) REFERENCES bookings(id),
  ADD CONSTRAINT bookings_makeup_source_check
    CHECK (
      (booking_source = 'makeup' AND makeup_for_booking_id IS NOT NULL)
      OR
      (booking_source <> 'makeup' AND makeup_for_booking_id IS NULL)
    );

CREATE UNIQUE INDEX bookings_one_active_makeup_per_cancelled_booking
  ON bookings (makeup_for_booking_id)
  WHERE makeup_for_booking_id IS NOT NULL
    AND status IN ('booked', 'attended', 'no_show', 'waitlisted');

COMMIT;
