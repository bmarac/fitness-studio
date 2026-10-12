BEGIN;

ALTER TABLE member_memberships
  ADD COLUMN billing_starts_on DATE;

UPDATE member_memberships
SET billing_starts_on = next_billing_on
WHERE next_billing_on IS NOT NULL;

ALTER TABLE member_memberships
  ADD CONSTRAINT member_memberships_billing_start_check
    CHECK (billing_starts_on IS NULL OR billing_starts_on >= starts_on),
  ADD CONSTRAINT member_memberships_billing_end_check
    CHECK (billing_starts_on IS NULL OR ends_on IS NULL OR billing_starts_on < ends_on);

COMMIT;
