BEGIN;

CREATE TABLE measurement_parameters (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  studio_id BIGINT NOT NULL REFERENCES studios(id),
  code VARCHAR(80) NOT NULL,
  name VARCHAR(120) NOT NULL,
  unit VARCHAR(30),
  value_type VARCHAR(20) NOT NULL DEFAULT 'decimal',
  source VARCHAR(20) NOT NULL DEFAULT 'manual',
  calculation_type VARCHAR(30),
  min_value NUMERIC(12, 4),
  max_value NUMERIC(12, 4),
  decimal_places SMALLINT NOT NULL DEFAULT 1,
  sort_order INTEGER NOT NULL DEFAULT 0,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT measurement_parameters_studio_code_unique
    UNIQUE (studio_id, code),
  CONSTRAINT measurement_parameters_value_type_check
    CHECK (value_type IN ('decimal', 'integer')),
  CONSTRAINT measurement_parameters_source_check
    CHECK (source IN ('manual', 'calculated')),
  CONSTRAINT measurement_parameters_calculation_check
    CHECK (
      (source = 'manual' AND calculation_type IS NULL)
      OR
      (source = 'calculated' AND calculation_type IN ('bmi'))
    ),
  CONSTRAINT measurement_parameters_range_check
    CHECK (min_value IS NULL OR max_value IS NULL OR min_value <= max_value),
  CONSTRAINT measurement_parameters_decimal_places_check
    CHECK (decimal_places BETWEEN 0 AND 4),
  CONSTRAINT measurement_parameters_status_check
    CHECK (status IN ('active', 'inactive'))
);

CREATE INDEX measurement_parameters_studio_status_sort_idx
  ON measurement_parameters (studio_id, status, sort_order, name);

CREATE TABLE member_measurements (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  studio_id BIGINT NOT NULL REFERENCES studios(id),
  member_id BIGINT NOT NULL REFERENCES members(id),
  measured_at TIMESTAMPTZ NOT NULL,
  recorded_by_user_id BIGINT REFERENCES app_users(id) ON DELETE SET NULL,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX member_measurements_member_measured_at_idx
  ON member_measurements (studio_id, member_id, measured_at DESC);

CREATE TABLE member_measurement_values (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  measurement_id BIGINT NOT NULL REFERENCES member_measurements(id) ON DELETE CASCADE,
  parameter_id BIGINT NOT NULL REFERENCES measurement_parameters(id),
  numeric_value NUMERIC(12, 4) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT member_measurement_values_measurement_parameter_unique
    UNIQUE (measurement_id, parameter_id)
);

CREATE INDEX member_measurement_values_parameter_idx
  ON member_measurement_values (parameter_id);

COMMIT;
