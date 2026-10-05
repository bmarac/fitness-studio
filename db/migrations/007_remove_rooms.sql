BEGIN;

ALTER TABLE class_sessions
  DROP COLUMN room_name;

ALTER TABLE recurring_class_schedules
  DROP COLUMN room_name;

COMMIT;
