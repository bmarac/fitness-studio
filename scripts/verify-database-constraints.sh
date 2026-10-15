#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
container_name="fitness_studio_database_tests_$$"
postgres_password="fitness_database_tests"
postgres_database="fitness_studio_database_tests"

cleanup() {
  docker rm --force "$container_name" >/dev/null 2>&1 || true
}

fail() {
  echo "Database constraint verification failed: $1" >&2
  docker logs "$container_name" >&2 || true
  exit 1
}

trap cleanup EXIT INT TERM

command -v docker >/dev/null 2>&1 || fail "Docker is required"

echo "Starting isolated PostgreSQL database test container..."
docker run \
  --detach \
  --name "$container_name" \
  --env "POSTGRES_USER=fitness" \
  --env "POSTGRES_PASSWORD=$postgres_password" \
  --env "POSTGRES_DB=$postgres_database" \
  --mount "type=bind,source=$repository_root/db,target=/fitness-studio-db,readonly" \
  --mount "type=bind,source=$repository_root/db/bootstrap.sh,target=/docker-entrypoint-initdb.d/000_bootstrap.sh,readonly" \
  postgres:16 >/dev/null

attempt=0
until docker exec "$container_name" psql \
  --username fitness \
  --dbname "$postgres_database" \
  --tuples-only \
  --no-align \
  --command "SELECT to_regclass('public.app_user_studios') IS NOT NULL;" \
  2>/dev/null | grep -qx 't'; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ]; then
    fail "database bootstrap did not finish"
  fi
  sleep 1
done

docker exec "$container_name" psql \
  --username fitness \
  --dbname "$postgres_database" \
  --file /fitness-studio-db/tests/constraints.sql \
  || fail "constraint assertions failed"

echo "Database constraint verification passed."
