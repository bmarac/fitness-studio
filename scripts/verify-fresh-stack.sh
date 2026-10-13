#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
verification_mode="${1:-full}"
if [ "$#" -gt 1 ]; then
  echo "Usage: $0 [booking-client|payment-client]" >&2
  exit 2
fi
case "$verification_mode" in
  full|booking-client|payment-client) ;;
  *)
    echo "Usage: $0 [booking-client|payment-client]" >&2
    exit 2
    ;;
esac
container_name="fitness_studio_postgres_verify_$$"
postgres_password="fitness_verify"
postgres_database="fitness_studio_verify"
api_port="${FITNESS_STUDIO_VERIFY_API_PORT:-55146}"
api_base_url="http://127.0.0.1:$api_port"
api_log=$(mktemp "${TMPDIR:-/tmp}/fitness-studio-api.XXXXXX.log")
api_pid=""

cleanup() {
  if [ -n "$api_pid" ]; then
    kill "$api_pid" 2>/dev/null || true
    wait "$api_pid" 2>/dev/null || true
  fi

  docker rm --force "$container_name" >/dev/null 2>&1 || true
  rm -f "$api_log"
}

fail() {
  echo "Verification failed: $1" >&2
  if [ -f "$api_log" ]; then
    echo "API log:" >&2
    tail -80 "$api_log" >&2
  fi
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command '$1' is missing"
}

request() {
  method="$1"
  path="$2"
  token="${3:-}"
  body="${4:-}"
  response_file=$(mktemp "${TMPDIR:-/tmp}/fitness-studio-response.XXXXXX")

  set -- --silent --show-error --output "$response_file" --write-out '%{http_code}' \
    --request "$method" "$api_base_url$path"
  if [ -n "$token" ]; then
    set -- "$@" --header "Authorization: Bearer $token"
  fi
  if [ -n "$body" ]; then
    set -- "$@" --header 'Content-Type: application/json' --data "$body"
  fi

  http_status=$(curl "$@") || {
    rm -f "$response_file"
    fail "$method $path could not be sent"
  }
  response_body=$(cat "$response_file")
  rm -f "$response_file"
}

expect_status() {
  expected="$1"
  if [ "$http_status" != "$expected" ]; then
    fail "expected HTTP $expected, received $http_status with body: $response_body"
  fi
}

login() {
  email="$1"
  request POST /api/auth/login "" "{\"email\":\"$email\",\"password\":\"Fitness123!\"}"
  expect_status 200
  account_token=$(printf '%s' "$response_body" | jq -er '.accessToken')
  studio_id=$(printf '%s' "$response_body" | jq -er '.studios[0].studioId')
  request POST "/api/account/studios/$studio_id/select" "$account_token"
  expect_status 200
  printf '%s' "$response_body" | jq -er '.accessToken'
}

trap cleanup EXIT INT TERM

require_command curl
require_command docker
require_command dotnet
require_command jq
if [ "$verification_mode" = "booking-client" ] || [ "$verification_mode" = "payment-client" ]; then
  require_command dart
fi

echo "Starting isolated PostgreSQL container..."
docker run \
  --detach \
  --name "$container_name" \
  --env "POSTGRES_USER=fitness" \
  --env "POSTGRES_PASSWORD=$postgres_password" \
  --env "POSTGRES_DB=$postgres_database" \
  --publish 127.0.0.1::5432 \
  --mount "type=bind,source=$repository_root/db,target=/fitness-studio-db,readonly" \
  --mount "type=bind,source=$repository_root/db/bootstrap.sh,target=/docker-entrypoint-initdb.d/000_bootstrap.sh,readonly" \
  postgres:16 >/dev/null

attempt=0
until docker exec "$container_name" psql \
  --username fitness \
  --dbname "$postgres_database" \
  --tuples-only \
  --no-align \
  --command "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'app_user_studios';" \
  2>/dev/null | grep -qx '1'; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ]; then
    docker logs "$container_name" >&2 || true
    fail "database bootstrap did not finish"
  fi
  sleep 1
done

seed_count=$(docker exec "$container_name" psql \
  --username fitness \
  --dbname "$postgres_database" \
  --tuples-only \
  --no-align \
  --command "SELECT COUNT(*) FROM members WHERE studio_id = 1;")
[ "$seed_count" = "8" ] || fail "expected 8 seeded members, found $seed_count"

echo "Verifying migration of existing multi-studio accounts..."
docker exec "$container_name" createdb \
  --username fitness fitness_studio_migration_verify
docker exec "$container_name" psql \
  --set ON_ERROR_STOP=1 \
  --username fitness \
  --dbname fitness_studio_migration_verify \
  --file /fitness-studio-db/schema/001_initial_schema.sql >/dev/null
for migration in \
  002_multi_studio_scheduling.sql \
  003_authentication.sql \
  004_studio_scoped_unique_constraints.sql \
  005_membership_plan_pricing.sql \
  006_multi_role_users.sql \
  007_remove_rooms.sql \
  008_member_measurements.sql \
  009_membership_billing.sql \
  010_recurring_schedule_lifecycle.sql \
  011_membership_billing_start.sql; do
  docker exec "$container_name" psql \
    --set ON_ERROR_STOP=1 \
    --username fitness \
    --dbname fitness_studio_migration_verify \
    --file "/fitness-studio-db/migrations/$migration" >/dev/null
done
docker exec "$container_name" psql \
  --set ON_ERROR_STOP=1 \
  --username fitness \
  --dbname fitness_studio_migration_verify \
  --command "INSERT INTO studios (name, timezone, status) VALUES ('Second studio', 'Europe/Zagreb', 'active'); INSERT INTO app_users (studio_id, email, password_hash, status) VALUES (1, 'shared@example.test', 'first-hash', 'active'), (2, 'SHARED@example.test', 'second-hash', 'active'); INSERT INTO app_user_roles (app_user_id, role) SELECT id, CASE studio_id WHEN 1 THEN 'member' ELSE 'admin' END FROM app_users;" \
  >/dev/null
docker exec "$container_name" psql \
  --set ON_ERROR_STOP=1 \
  --username fitness \
  --dbname fitness_studio_migration_verify \
  --file /fitness-studio-db/migrations/012_global_accounts.sql >/dev/null
migrated_accounts=$(docker exec "$container_name" psql \
  --username fitness \
  --dbname fitness_studio_migration_verify \
  --tuples-only \
  --no-align \
  --command "SELECT COUNT(*) || ':' || (SELECT COUNT(*) FROM app_user_studios) || ':' || (SELECT COUNT(*) FROM app_user_studio_roles) FROM app_users WHERE email = 'shared@example.test';")
[ "$migrated_accounts" = "1:2:2" ] \
  || fail "global account migration did not preserve both studio memberships and roles: $migrated_accounts"

docker exec "$container_name" psql \
  --set ON_ERROR_STOP=1 \
  --username fitness \
  --dbname "$postgres_database" \
  --command "INSERT INTO studios (name, timezone, status) VALUES ('Isolation verification', 'Europe/Zagreb', 'active'); INSERT INTO studio_settings (studio_id, setting, value, value_type) SELECT id, 'join_code', 'ISOLATION', 'string' FROM studios WHERE name = 'Isolation verification'; INSERT INTO members (studio_id, first_name, last_name, email, status) SELECT id, 'Other', 'Studio', 'other.studio@example.test', 'active' FROM studios WHERE name = 'Isolation verification';" \
  >/dev/null

postgres_port=$(docker port "$container_name" 5432/tcp | sed -n '1s/.*://p')
[ -n "$postgres_port" ] || fail "could not determine PostgreSQL port"

echo "Starting API against the isolated database..."
(
  cd "$repository_root/api/FitnessStudio.Api"
  ASPNETCORE_ENVIRONMENT=Development \
  ASPNETCORE_URLS="$api_base_url" \
  ConnectionStrings__DefaultConnection="Host=127.0.0.1;Port=$postgres_port;Database=$postgres_database;Username=fitness;Password=$postgres_password" \
  Jwt__Issuer=FitnessStudio.Verify \
  Jwt__Audience=FitnessStudio.Verify \
  Jwt__SigningKey='fitness-studio-verification-signing-key-2026' \
  Jwt__ExpirationMinutes=30 \
  DevelopmentSeedUser__Enabled=true \
  DevelopmentSeedUser__Accounts__0__StudioId=1 \
  DevelopmentSeedUser__Accounts__0__Email='filip.saric@stayfitjoyful.demo' \
  DevelopmentSeedUser__Accounts__0__Password='Fitness123!' \
  DevelopmentSeedUser__Accounts__0__Roles__0=trainer \
  DevelopmentSeedUser__Accounts__0__Roles__1=admin \
  DevelopmentSeedUser__Accounts__1__StudioId=1 \
  DevelopmentSeedUser__Accounts__1__Email='kristina.lisec@stayfitjoyful.demo' \
  DevelopmentSeedUser__Accounts__1__Password='Fitness123!' \
  DevelopmentSeedUser__Accounts__1__Roles__0=trainer \
  DevelopmentSeedUser__Accounts__1__Roles__1=admin \
  DevelopmentSeedUser__Accounts__2__StudioId=1 \
  DevelopmentSeedUser__Accounts__2__Email='ana.horvat@stayfitjoyful.demo' \
  DevelopmentSeedUser__Accounts__2__Password='Fitness123!' \
  DevelopmentSeedUser__Accounts__2__Roles__0=member \
  dotnet run --no-launch-profile
) >"$api_log" 2>&1 &
api_pid=$!

attempt=0
until curl \
  --silent \
  --fail \
  --header 'Content-Type: application/json' \
  --data '{"email":"ana.horvat@stayfitjoyful.demo","password":"Fitness123!"}' \
  "$api_base_url/api/auth/login" >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ] || ! kill -0 "$api_pid" 2>/dev/null; then
    fail "API did not become ready"
  fi
  sleep 1
done

if [ "$verification_mode" = "booking-client" ]; then
  echo "Verifying the Flutter booking client against the fresh stack..."
  (
    cd "$repository_root/mobile/fitness_studio_mobile"
    FITNESS_STUDIO_TEST_API_BASE_URL="$api_base_url" \
      dart test integration_test/booking_stack_test.dart
  ) || fail "Flutter booking client verification failed"

  echo "Fresh-stack booking client verification passed."
  exit 0
fi

if [ "$verification_mode" = "payment-client" ]; then
  echo "Verifying the Flutter payment client against the fresh stack..."
  (
    cd "$repository_root/mobile/fitness_studio_mobile"
    FITNESS_STUDIO_TEST_API_BASE_URL="$api_base_url" \
      dart test integration_test/payment_stack_test.dart
  ) || fail "Flutter payment client verification failed"

  echo "Fresh-stack payment client verification passed."
  exit 0
fi

echo "Verifying demo accounts and studio isolation..."
filip_token=$(login 'filip.saric@stayfitjoyful.demo')
kristina_token=$(login 'kristina.lisec@stayfitjoyful.demo')
ana_token=$(login 'ana.horvat@stayfitjoyful.demo')
[ -n "$kristina_token" ] || fail "Kristina login did not return a token"

request GET /api/profile "$filip_token"
expect_status 200
[ "$(printf '%s' "$response_body" | jq -r '.studio.id')" = "1" ] || fail "Filip profile crossed the studio boundary"

request GET /api/members "$filip_token"
expect_status 200
printf '%s' "$response_body" | jq -e 'length == 8 and all(.[]; .email != "other.studio@example.test")' >/dev/null \
  || fail "member listing is not studio-scoped"

echo "Verifying recurring schedule lifecycle..."
request GET /api/recurring-class-schedules "$filip_token"
expect_status 200
class_type_id=$(printf '%s' "$response_body" | jq -er '.[0].classTypeId')
trainer_id=$(printf '%s' "$response_body" | jq -er '.[0].trainerId')
today=$(date '+%Y-%m-%d')
schedule_body=$(jq -nc \
  --argjson classTypeId "$class_type_id" \
  --argjson trainerId "$trainer_id" \
  --arg validFrom "$today" \
  '{classTypeId:$classTypeId,trainerId:$trainerId,dayOfWeek:7,startsAtTime:"23:00:00",durationMinutes:45,capacity:5,validFrom:$validFrom,status:"active"}')
request POST /api/recurring-class-schedules "$filip_token" "$schedule_body"
expect_status 201
schedule_id=$(printf '%s' "$response_body" | jq -er '.id')
request PATCH "/api/recurring-class-schedules/$schedule_id/pause" "$filip_token" "{\"effectiveFrom\":\"$today\"}"
expect_status 204
request PATCH "/api/recurring-class-schedules/$schedule_id/resume" "$filip_token" "{\"effectiveFrom\":\"$today\"}"
expect_status 204

echo "Verifying registration, code join, admin notification and studio selection..."
request GET /api/membership-plans "$filip_token"
expect_status 200
pilot_plan_id=$(printf '%s' "$response_body" | jq -er '.[0].id')
request POST /api/auth/register "" '{"email":"pilot.member@example.test","password":"PilotPass123!"}'
expect_status 201
pilot_account_token=$(printf '%s' "$response_body" | jq -er '.accessToken')
[ "$(printf '%s' "$response_body" | jq -r '.studios | length')" = "0" ] \
  || fail "new account unexpectedly belongs to a studio"

request POST /api/account/studios/lookup "$pilot_account_token" '{"code":"stayfit"}'
expect_status 200
[ "$(printf '%s' "$response_body" | jq -r '.requiresProfileDetails')" = "true" ] \
  || fail "new account did not request profile details"

request POST /api/account/studios/join "$pilot_account_token" \
  '{"code":"STAYFIT","firstName":"Pilot","lastName":"Member"}'
expect_status 200
pilot_studio_id=$(printf '%s' "$response_body" | jq -er '.studioId')
pilot_member_id=$(printf '%s' "$response_body" | jq -er '.memberId')
request POST /api/account/studios/join "$pilot_account_token" '{"code":"STAYFIT"}'
expect_status 200
request GET /api/notifications "$filip_token"
expect_status 200
printf '%s' "$response_body" | jq -e 'any(.[]; .type == "member_joined")' >/dev/null \
  || fail "admin did not receive member_joined notification"
request POST "/api/account/studios/$pilot_studio_id/select" "$pilot_account_token"
expect_status 200
pilot_token=$(printf '%s' "$response_body" | jq -er '.accessToken')
request GET /api/profile "$pilot_token"
expect_status 200
request POST /api/member-memberships "$filip_token" \
  "{\"memberId\":$pilot_member_id,\"membershipPlanId\":$pilot_plan_id,\"startsOn\":\"$today\"}"
expect_status 201
request GET /api/class-sessions "$pilot_token"
expect_status 200
now_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
pilot_session_id=$(printf '%s' "$response_body" | jq -er \
  --arg now "$now_utc" \
  '[.[] | select(.status == "scheduled" and .bookedCount < .capacity and .startsAt > $now)][0].id')
request POST /api/bookings "$pilot_token" "{\"memberId\":$pilot_member_id,\"classSessionId\":$pilot_session_id}"
expect_status 201

echo "Verifying booking cancellation and membership limit..."
request GET /api/profile "$ana_token"
expect_status 200
ana_member_id=$(printf '%s' "$response_body" | jq -er '.member.id')
membership_id=$(printf '%s' "$response_body" | jq -er '.membership.id')

request GET /api/bookings "$ana_token"
expect_status 200
cancel_booking_id=$(printf '%s' "$response_body" | jq -er '[.[] | select(.status == "booked")][0].id')
cancel_session_id=$(printf '%s' "$response_body" | jq -er --argjson id "$cancel_booking_id" '.[] | select(.id == $id) | .classSessionId')
cancel_session_date=$(printf '%s' "$response_body" | jq -er --argjson id "$cancel_booking_id" '.[] | select(.id == $id) | .classSessionStartsAt[0:10]')
request DELETE "/api/bookings/$cancel_booking_id" "$ana_token"
expect_status 204

request GET /api/class-sessions "$ana_token"
expect_status 200
replacement_session_id=$(printf '%s' "$response_body" | jq -er \
  --argjson excluded "$cancel_session_id" \
  --arg sessionDate "$cancel_session_date" \
  '[.[] | select(.status == "scheduled" and .id != $excluded and (.startsAt | startswith($sessionDate)))][0].id')
limit_session_id=$(printf '%s' "$response_body" | jq -er \
  --argjson cancelled "$cancel_session_id" \
  --argjson replacement "$replacement_session_id" \
  --arg sessionDate "$cancel_session_date" \
  '[.[] | select(.status == "scheduled" and .id != $cancelled and .id != $replacement and (.startsAt | startswith($sessionDate)))][0].id')
request POST /api/bookings "$ana_token" "{\"memberId\":$ana_member_id,\"classSessionId\":$replacement_session_id}"
expect_status 201
replacement_booking_id=$(printf '%s' "$response_body" | jq -er '.id')
request POST /api/bookings "$ana_token" "{\"memberId\":$ana_member_id,\"classSessionId\":$limit_session_id}"
expect_status 409
request DELETE "/api/bookings/$replacement_booking_id" "$ana_token"
expect_status 204

echo "Verifying billing, HUB3 and payment transitions..."
settings_body='{"recipientName":"Stay Fit & Joyful","iban":"HR1723600001101234565","paymentModel":"HR00","paymentReference":"12345","paymentDescription":"Clanarina","memberReminderDays":[0,1],"adminReminderDays":[2],"notificationTime":"09:00:00"}'
request PUT /api/payment-settings "$filip_token" "$settings_body"
expect_status 200
request GET /api/member-memberships "$filip_token"
expect_status 200
billing_membership_id=$(printf '%s' "$response_body" | jq -er \
  '[.[] | select(.billingStartsOn == null)][0].id')
request PUT "/api/member-memberships/$billing_membership_id/billing" "$filip_token" "{\"firstBillingOn\":\"$today\"}"
expect_status 200
[ "$(printf '%s' "$response_body" | jq -r '.createdObligations')" -ge 1 ] || fail "billing did not create an obligation"

request GET /api/membership-payments/mine "$ana_token"
expect_status 200
payment_id=$(printf '%s' "$response_body" | jq -er '[.[] | select(.status == "pending")][0].id')
request GET "/api/membership-payments/$payment_id/barcode" "$ana_token"
expect_status 200
printf '%s' "$response_body" | grep -q '<svg' || fail "HUB3 endpoint did not return SVG"
request POST "/api/membership-payments/$payment_id/report" "$ana_token"
expect_status 204
request POST "/api/membership-payments/$payment_id/confirm" "$filip_token"
expect_status 204

tomorrow=$(date -v+1d '+%Y-%m-%d' 2>/dev/null || date -d '+1 day' '+%Y-%m-%d')
request PUT "/api/member-memberships/$membership_id/end" "$ana_token" "{\"endsOn\":\"$tomorrow\"}"
expect_status 204

echo "Fresh-stack verification passed."
