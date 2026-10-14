BEGIN;

DROP INDEX IF EXISTS bookings_one_active_makeup_per_cancelled_booking;

ALTER TABLE bookings
  DROP CONSTRAINT IF EXISTS bookings_makeup_source_check,
  DROP CONSTRAINT IF EXISTS bookings_makeup_for_booking_id_fkey,
  DROP CONSTRAINT bookings_booking_source_check,
  DROP CONSTRAINT bookings_status_check,
  DROP COLUMN IF EXISTS makeup_for_booking_id;

UPDATE bookings
SET booking_source = 'self_service'
WHERE booking_source = 'makeup';

ALTER TABLE bookings
  ADD CONSTRAINT bookings_booking_source_check
    CHECK (booking_source IN ('self_service', 'fixed_schedule', 'admin')),
  ADD CONSTRAINT bookings_status_check
    CHECK (status IN (
      'booked',
      'cancelled',
      'late_cancelled',
      'attended',
      'no_show',
      'waitlisted'
    ));

DROP INDEX bookings_one_active_per_member_session;

CREATE UNIQUE INDEX bookings_one_active_per_member_session
  ON bookings (member_id, class_session_id)
  WHERE status IN (
    'booked',
    'attended',
    'no_show',
    'waitlisted',
    'late_cancelled'
  );

DELETE FROM studio_settings
WHERE setting = 'allow_makeups';

INSERT INTO studio_settings (studio_id, setting, value, value_type)
SELECT id, 'cancellation_cutoff_hours', '12', 'integer'
FROM studios
ON CONFLICT (studio_id, setting) DO NOTHING;

COMMIT;
