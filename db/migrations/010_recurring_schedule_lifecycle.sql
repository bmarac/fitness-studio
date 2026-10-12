BEGIN;

ALTER TABLE recurring_class_schedules
  DROP CONSTRAINT recurring_class_schedules_status_check;

ALTER TABLE recurring_class_schedules
  ADD COLUMN status_effective_from DATE;

UPDATE recurring_class_schedules
SET
  status = 'paused',
  status_effective_from = GREATEST(valid_from, CURRENT_DATE)
WHERE status = 'inactive';

ALTER TABLE recurring_class_schedules
  ADD CONSTRAINT recurring_class_schedules_status_check
    CHECK (status IN ('active', 'paused', 'ended')),
  ADD CONSTRAINT recurring_class_schedules_status_date_check
    CHECK (
      (status = 'active' AND status_effective_from IS NULL)
      OR (status IN ('paused', 'ended') AND status_effective_from IS NOT NULL)
    );

ALTER TABLE class_sessions
  ADD COLUMN cancellation_reason VARCHAR(30),
  ADD CONSTRAINT class_sessions_cancellation_reason_check
    CHECK (
      cancellation_reason IS NULL
      OR cancellation_reason IN ('single_session', 'schedule_paused', 'schedule_ended')
    );

ALTER TABLE bookings
  ADD COLUMN cancellation_reason VARCHAR(30),
  ADD CONSTRAINT bookings_cancellation_reason_check
    CHECK (
      cancellation_reason IS NULL
      OR cancellation_reason IN (
        'single_session',
        'schedule_paused',
        'schedule_ended',
        'fixed_assignment'
      )
    );

COMMIT;
