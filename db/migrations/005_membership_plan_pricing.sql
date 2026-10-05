BEGIN;

ALTER TABLE membership_plans
  ADD COLUMN price_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
  ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
  ADD CONSTRAINT membership_plans_price_amount_check
    CHECK (price_amount >= 0),
  ADD CONSTRAINT membership_plans_currency_check
    CHECK (currency = upper(currency) AND char_length(currency) = 3);

COMMIT;
