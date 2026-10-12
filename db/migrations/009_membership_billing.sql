BEGIN;

ALTER TABLE membership_plans
  ADD COLUMN billing_period_months INTEGER NOT NULL DEFAULT 1,
  DROP COLUMN duration_days,
  ADD CONSTRAINT membership_plans_billing_period_months_check
    CHECK (billing_period_months = 1),
  ADD CONSTRAINT membership_plans_eur_billing_check
    CHECK (currency = 'EUR');

ALTER TABLE member_memberships
  ALTER COLUMN ends_on DROP NOT NULL,
  ADD COLUMN next_billing_on DATE,
  DROP COLUMN status;

CREATE TABLE membership_payment_obligations (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  studio_id BIGINT NOT NULL REFERENCES studios(id),
  member_membership_id BIGINT NOT NULL REFERENCES member_memberships(id),
  period_starts_on DATE NOT NULL,
  period_ends_on DATE NOT NULL,
  due_on DATE NOT NULL,
  plan_name VARCHAR(120) NOT NULL,
  full_amount NUMERIC(10, 2) NOT NULL,
  amount_due NUMERIC(10, 2) NOT NULL,
  currency VARCHAR(3) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'pending',
  recipient_name VARCHAR(100) NOT NULL,
  iban VARCHAR(34) NOT NULL,
  payment_model VARCHAR(4) NOT NULL,
  payment_reference VARCHAR(22) NOT NULL,
  payment_description VARCHAR(35) NOT NULL,
  reported_at TIMESTAMPTZ,
  reported_by_user_id BIGINT REFERENCES app_users(id),
  confirmed_at TIMESTAMPTZ,
  confirmed_by_user_id BIGINT REFERENCES app_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT membership_payment_obligations_period_check
    CHECK (period_ends_on > period_starts_on),
  CONSTRAINT membership_payment_obligations_amount_check
    CHECK (full_amount >= 0 AND amount_due >= 0 AND amount_due <= full_amount),
  CONSTRAINT membership_payment_obligations_currency_check
    CHECK (currency = 'EUR'),
  CONSTRAINT membership_payment_obligations_status_check
    CHECK (status IN ('pending', 'reported', 'paid')),
  CONSTRAINT membership_payment_obligations_reported_check
    CHECK ((status <> 'reported') OR (reported_at IS NOT NULL AND reported_by_user_id IS NOT NULL)),
  CONSTRAINT membership_payment_obligations_paid_check
    CHECK ((status <> 'paid') OR (confirmed_at IS NOT NULL AND confirmed_by_user_id IS NOT NULL)),
  CONSTRAINT membership_payment_obligations_membership_period_unique
    UNIQUE (member_membership_id, period_starts_on)
);

CREATE INDEX membership_payment_obligations_studio_due_idx
  ON membership_payment_obligations (studio_id, due_on);
CREATE INDEX membership_payment_obligations_studio_status_idx
  ON membership_payment_obligations (studio_id, status);

CREATE TABLE app_notifications (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  studio_id BIGINT NOT NULL REFERENCES studios(id),
  app_user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  payment_obligation_id BIGINT REFERENCES membership_payment_obligations(id) ON DELETE CASCADE,
  notification_type VARCHAR(50) NOT NULL,
  day_offset INTEGER,
  title VARCHAR(160) NOT NULL,
  body TEXT NOT NULL,
  read_at TIMESTAMPTZ,
  pushed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX app_notifications_payment_delivery_unique
  ON app_notifications (app_user_id, payment_obligation_id, notification_type, day_offset)
  WHERE payment_obligation_id IS NOT NULL;
CREATE INDEX app_notifications_user_created_idx
  ON app_notifications (app_user_id, created_at DESC);

CREATE TABLE app_user_device_tokens (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  app_user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform VARCHAR(20) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT app_user_device_tokens_platform_check
    CHECK (platform IN ('android', 'ios'))
);

COMMIT;
