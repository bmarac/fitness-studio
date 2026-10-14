BEGIN;

UPDATE measurement_parameters
SET source = 'manual',
    calculation_type = NULL,
    updated_at = now()
WHERE source <> 'manual' OR calculation_type IS NOT NULL;

ALTER TABLE measurement_parameters
  DROP CONSTRAINT IF EXISTS measurement_parameters_calculation_check,
  DROP CONSTRAINT IF EXISTS measurement_parameters_source_check,
  DROP COLUMN calculation_type,
  DROP COLUMN source;

COMMIT;
