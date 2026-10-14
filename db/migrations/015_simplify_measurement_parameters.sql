BEGIN;

ALTER TABLE measurement_parameters
  DROP CONSTRAINT IF EXISTS measurement_parameters_value_type_check,
  DROP CONSTRAINT IF EXISTS measurement_parameters_range_check,
  DROP CONSTRAINT IF EXISTS measurement_parameters_decimal_places_check,
  DROP COLUMN value_type,
  DROP COLUMN min_value,
  DROP COLUMN max_value,
  DROP COLUMN decimal_places;

COMMIT;
