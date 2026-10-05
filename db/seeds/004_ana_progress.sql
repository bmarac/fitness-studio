BEGIN;

DELETE FROM member_measurements
WHERE member_id = (
  SELECT id
  FROM members
  WHERE email = 'ana.horvat@stayfitjoyful.demo'
    AND studio_id = (SELECT id FROM studios WHERE name = 'Stay Fit & Joyful')
);

WITH measurement_data(measurement_key, measured_at, note) AS (
  VALUES
    ('m1', now() - INTERVAL '90 days', 'Pocetno mjerenje'),
    ('m2', now() - INTERVAL '60 days', 'Mjesecna kontrola'),
    ('m3', now() - INTERVAL '30 days', 'Mjesecna kontrola'),
    ('m4', now() - INTERVAL '1 day', 'Trenutno stanje')
),
inserted_measurements AS (
  INSERT INTO member_measurements (
    studio_id,
    member_id,
    measured_at,
    recorded_by_user_id,
    note
  )
  SELECT
    members.studio_id,
    members.id,
    measurement_data.measured_at,
    app_users.id,
    measurement_data.note
  FROM measurement_data
  JOIN members
    ON members.email = 'ana.horvat@stayfitjoyful.demo'
    AND members.studio_id = (SELECT id FROM studios WHERE name = 'Stay Fit & Joyful')
  LEFT JOIN app_users
    ON app_users.studio_id = members.studio_id
    AND app_users.email = 'filip.saric@stayfitjoyful.demo'
  RETURNING id, measured_at
),
measurement_numbered AS (
  SELECT
    id,
    row_number() OVER (ORDER BY measured_at) AS measurement_number
  FROM inserted_measurements
),
value_data(measurement_number, parameter_code, numeric_value) AS (
  VALUES
    (1, 'height_cm', 170.0),
    (1, 'weight_kg', 74.8),
    (1, 'waist_cm', 86.0),
    (1, 'upper_arm_cm', 29.5),
    (1, 'chest_cm', 94.0),
    (1, 'body_fat_pct', 30.5),
    (2, 'height_cm', 170.0),
    (2, 'weight_kg', 72.9),
    (2, 'waist_cm', 83.5),
    (2, 'upper_arm_cm', 30.0),
    (2, 'chest_cm', 93.0),
    (2, 'body_fat_pct', 29.2),
    (3, 'height_cm', 170.0),
    (3, 'weight_kg', 70.5),
    (3, 'waist_cm', 81.0),
    (3, 'upper_arm_cm', 30.5),
    (3, 'chest_cm', 92.0),
    (3, 'body_fat_pct', 27.8),
    (4, 'height_cm', 170.0),
    (4, 'weight_kg', 68.4),
    (4, 'waist_cm', 78.5),
    (4, 'upper_arm_cm', 31.0),
    (4, 'chest_cm', 91.0),
    (4, 'body_fat_pct', 26.4)
)
INSERT INTO member_measurement_values (
  measurement_id,
  parameter_id,
  numeric_value
)
SELECT
  measurement_numbered.id,
  parameters.id,
  value_data.numeric_value
FROM value_data
JOIN measurement_numbered
  ON measurement_numbered.measurement_number = value_data.measurement_number
JOIN measurement_parameters AS parameters
  ON parameters.studio_id = (SELECT id FROM studios WHERE name = 'Stay Fit & Joyful')
  AND parameters.code = value_data.parameter_code;

COMMIT;
