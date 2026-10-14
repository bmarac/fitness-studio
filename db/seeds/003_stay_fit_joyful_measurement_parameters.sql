INSERT INTO measurement_parameters (
  studio_id,
  code,
  name,
  unit,
  sort_order,
  status
)
SELECT
  studios.id,
  parameters.code,
  parameters.name,
  parameters.unit,
  parameters.sort_order,
  'active'
FROM studios
CROSS JOIN (
  VALUES
    ('height_cm', 'Visina', 'cm', 10),
    ('weight_kg', 'Tezina', 'kg', 20),
    ('bmi', 'BMI', NULL, 30),
    ('waist_cm', 'Opseg struka', 'cm', 40),
    ('upper_arm_cm', 'Opseg ruke', 'cm', 50),
    ('chest_cm', 'Opseg prsa', 'cm', 60),
    ('body_fat_pct', 'Masno tkivo', '%', 70)
) AS parameters(
  code,
  name,
  unit,
  sort_order
)
WHERE studios.name = 'Stay Fit & Joyful'
ON CONFLICT (studio_id, code) DO UPDATE SET
  name = EXCLUDED.name,
  unit = EXCLUDED.unit,
  sort_order = EXCLUDED.sort_order,
  status = EXCLUDED.status,
  updated_at = now();
