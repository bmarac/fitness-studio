CREATE TABLE members (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(50),
  date_of_birth DATE,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT members_status_check
    CHECK (status IN ('active', 'inactive', 'paused', 'blocked'))
);

CREATE TABLE trainers (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(50),
  bio TEXT,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT trainers_status_check
    CHECK (status IN ('active', 'inactive'))
);

CREATE TABLE class_types (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  description TEXT,
  default_duration_minutes INTEGER NOT NULL,
  default_capacity INTEGER NOT NULL,
  difficulty_level VARCHAR(30) NOT NULL DEFAULT 'all_levels',
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT class_types_duration_check
    CHECK (default_duration_minutes > 0),
  CONSTRAINT class_types_capacity_check
    CHECK (default_capacity > 0),
  CONSTRAINT class_types_difficulty_check
    CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced', 'all_levels')),
  CONSTRAINT class_types_status_check
    CHECK (status IN ('active', 'inactive'))
);

CREATE TABLE class_sessions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  class_type_id BIGINT NOT NULL REFERENCES class_types(id),
  trainer_id BIGINT NOT NULL REFERENCES trainers(id),
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  capacity INTEGER NOT NULL,
  room_name VARCHAR(120),
  status VARCHAR(30) NOT NULL DEFAULT 'scheduled',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT class_sessions_time_check
    CHECK (ends_at > starts_at),
  CONSTRAINT class_sessions_capacity_check
    CHECK (capacity > 0),
  CONSTRAINT class_sessions_status_check
    CHECK (status IN ('scheduled', 'cancelled', 'completed'))
);

CREATE TABLE bookings (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  member_id BIGINT NOT NULL REFERENCES members(id),
  class_session_id BIGINT NOT NULL REFERENCES class_sessions(id),
  status VARCHAR(30) NOT NULL DEFAULT 'booked',
  booked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  cancelled_at TIMESTAMPTZ,
  attended_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT bookings_status_check
    CHECK (status IN ('booked', 'cancelled', 'attended', 'no_show', 'waitlisted'))
);

CREATE UNIQUE INDEX bookings_one_active_per_member_session
  ON bookings (member_id, class_session_id)
  WHERE status IN ('booked', 'attended', 'no_show', 'waitlisted');

CREATE TABLE membership_plans (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  description TEXT,
  duration_days INTEGER NOT NULL,
  session_limit INTEGER,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT membership_plans_duration_check
    CHECK (duration_days > 0),
  CONSTRAINT membership_plans_session_limit_check
    CHECK (session_limit IS NULL OR session_limit > 0),
  CONSTRAINT membership_plans_status_check
    CHECK (status IN ('active', 'inactive'))
);

CREATE TABLE member_memberships (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  member_id BIGINT NOT NULL REFERENCES members(id),
  membership_plan_id BIGINT NOT NULL REFERENCES membership_plans(id),
  starts_on DATE NOT NULL,
  ends_on DATE NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT member_memberships_dates_check
    CHECK (ends_on >= starts_on),
  CONSTRAINT member_memberships_status_check
    CHECK (status IN ('active', 'expired', 'paused', 'cancelled'))
);

CREATE INDEX class_sessions_starts_at_idx ON class_sessions (starts_at);
CREATE INDEX bookings_class_session_id_idx ON bookings (class_session_id);
CREATE INDEX bookings_member_id_idx ON bookings (member_id);
CREATE INDEX member_memberships_member_id_idx ON member_memberships (member_id);
