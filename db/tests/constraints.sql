\set ON_ERROR_STOP on

BEGIN;

DO $$
BEGIN
  IF to_regclass('public.app_user_studios') IS NULL
     OR to_regclass('public.member_measurements') IS NULL
     OR to_regclass('public.membership_payment_obligations') IS NULL THEN
    RAISE EXCEPTION 'Fresh database is missing migrated tables';
  END IF;
END $$;

-- Email addresses are unique inside one studio, but reusable in another.
DO $$
DECLARE
  primary_studio BIGINT := (SELECT min(id) FROM studios);
  second_studio BIGINT;
  existing_email TEXT := (SELECT email FROM members WHERE studio_id = primary_studio LIMIT 1);
BEGIN
  INSERT INTO studios (name, timezone, status)
  VALUES ('Database constraint test studio', 'Europe/Zagreb', 'active')
  RETURNING id INTO second_studio;

  BEGIN
    INSERT INTO members (studio_id, first_name, last_name, email, status)
    VALUES (primary_studio, 'Duplicate', 'Member', existing_email, 'active');
    RAISE EXCEPTION 'Duplicate member email in one studio was accepted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;

  INSERT INTO members (studio_id, first_name, last_name, email, status)
  VALUES (second_studio, 'Other', 'Studio', existing_email, 'active');
END $$;

-- Global account email uniqueness is case-insensitive.
DO $$
DECLARE
  existing_email CONSTANT TEXT := 'database.account@example.test';
BEGIN
  INSERT INTO app_users (email, password_hash, status)
  VALUES (existing_email, 'test-hash', 'active');

  BEGIN
    INSERT INTO app_users (email, password_hash, status)
    VALUES (upper(existing_email), 'test-hash', 'active');
    RAISE EXCEPTION 'Case-insensitive duplicate account email was accepted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;
END $$;

-- Only one active booking may exist for a member and class session; a
-- cancelled historical record for the same pair remains valid.
DO $$
DECLARE
  source_booking bookings%ROWTYPE;
  cancelled_count INTEGER;
BEGIN
  SELECT * INTO source_booking
  FROM bookings
  WHERE status IN ('booked', 'attended', 'no_show', 'waitlisted', 'late_cancelled')
  LIMIT 1;

  IF source_booking.id IS NULL THEN
    RAISE EXCEPTION 'Demo seed does not contain an active booking';
  END IF;

  BEGIN
    INSERT INTO bookings (
      studio_id, member_id, class_session_id, status, booking_source
    ) VALUES (
      source_booking.studio_id,
      source_booking.member_id,
      source_booking.class_session_id,
      'booked',
      'admin'
    );
    RAISE EXCEPTION 'Duplicate active booking was accepted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;

  INSERT INTO bookings (
    studio_id, member_id, class_session_id, status, booking_source, cancelled_at
  ) VALUES (
    source_booking.studio_id,
    source_booking.member_id,
    source_booking.class_session_id,
    'cancelled',
    'admin',
    now()
  );

  SELECT count(*) INTO cancelled_count
  FROM bookings
  WHERE member_id = source_booking.member_id
    AND class_session_id = source_booking.class_session_id
    AND status = 'cancelled';
  IF cancelled_count < 1 THEN
    RAISE EXCEPTION 'Cancelled booking history was not stored';
  END IF;
END $$;

-- A studio membership cannot point at member and trainer profiles together.
DO $$
DECLARE
  studio BIGINT := (SELECT min(id) FROM studios);
  member BIGINT := (SELECT id FROM members WHERE studio_id = studio LIMIT 1);
  trainer BIGINT := (SELECT id FROM trainers WHERE studio_id = studio LIMIT 1);
  account BIGINT;
BEGIN
  INSERT INTO app_users (email, password_hash, status)
  VALUES ('database.constraints@example.test', 'test-hash', 'active')
  RETURNING id INTO account;

  BEGIN
    INSERT INTO app_user_studios (
      app_user_id, studio_id, member_id, trainer_id, status
    ) VALUES (account, studio, member, trainer, 'active');
    RAISE EXCEPTION 'Membership with both member and trainer profiles was accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END $$;

-- Measurement rows must reference a real member.
DO $$
DECLARE
  studio BIGINT := (SELECT min(id) FROM studios);
BEGIN
  BEGIN
    INSERT INTO member_measurements (studio_id, member_id, measured_at)
    VALUES (studio, 9223372036854775807, now());
    RAISE EXCEPTION 'Measurement with a missing member was accepted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;
END $$;

-- Join codes are globally unique regardless of letter case.
DO $$
DECLARE
  studio BIGINT;
BEGIN
  INSERT INTO studios (name, timezone, status)
  VALUES ('Join code constraint studio', 'Europe/Zagreb', 'active')
  RETURNING id INTO studio;

  BEGIN
    INSERT INTO studio_settings (studio_id, setting, value, value_type)
    VALUES (studio, 'join_code', 'stayfit', 'string');
    RAISE EXCEPTION 'Case-insensitive duplicate join code was accepted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;
END $$;

ROLLBACK;

SELECT 'database constraints passed' AS result;
