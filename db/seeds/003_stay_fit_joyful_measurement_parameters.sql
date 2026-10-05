INSERT INTO measurement_parameters (
  studio_id,
  code,
  name,
  unit,
  value_type,
  source,
  calculation_type,
  min_value,
  max_value,
  decimal_places,
  sort_order,
  status
)
SELECT
  studios.id,
  parameters.code,
  parameters.name,
  parameters.unit,
  parameters.value_type,
  parameters.source,
  parameters.calculation_type,
  parameters.min_value,
  parameters.max_value,
  parameters.decimal_places,
  parameters.sort_order,
  'active'
FROM studios
CROSS JOIN (
  VALUES
    ('height_cm', 'Visina', 'cm', 'decimal', 'manual', NULL, 50.0, 250.0, 1, 10),
    ('weight_kg', 'Tezina', 'kg', 'decimal', 'manual', NULL, 20.0, 350.0, 1, 20),
    ('bmi', 'BMI', NULL, 'decimal', 'calculated', 'bmi', 5.0, 100.0, 1, 30),
    ('waist_cm', 'Opseg struka', 'cm', 'decimal', 'manual', NULL, 20.0, 300.0, 1, 40),
    ('upper_arm_cm', 'Opseg ruke', 'cm', 'decimal', 'manual', NULL, 10.0, 100.0, 1, 50),
    ('chest_cm', 'Opseg prsa', 'cm', 'decimal', 'manual', NULL, 30.0, 300.0, 1, 60),
    ('body_fat_pct', 'Masno tkivo', '%', 'decimal', 'manual', NULL, 1.0, 75.0, 1, 70)
) AS parameters(
  code,
  name,
  unit,
  value_type,
  source,
  calculation_type,
  min_value,
  max_value,
  decimal_places,
  sort_order
)
WHERE studios.name = 'Stay Fit & Joyful'
ON CONFLICT (studio_id, code) DO UPDATE SET
  name = EXCLUDED.name,
  unit = EXCLUDED.unit,
  value_type = EXCLUDED.value_type,
  source = EXCLUDED.source,
  calculation_type = EXCLUDED.calculation_type,
  min_value = EXCLUDED.min_value,
  max_value = EXCLUDED.max_value,
  decimal_places = EXCLUDED.decimal_places,
  sort_order = EXCLUDED.sort_order,
  status = EXCLUDED.status,
  updated_at = now();
