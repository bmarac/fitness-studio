#!/bin/sh

set -eu

database_root="${FITNESS_STUDIO_DB_ROOT:-/fitness-studio-db}"

apply_sql_directory() {
  directory="$1"

  for sql_file in "$directory"/*.sql; do
    if [ ! -f "$sql_file" ]; then
      continue
    fi

    echo "Applying ${sql_file##*/}"
    psql \
      --set ON_ERROR_STOP=1 \
      --username "$POSTGRES_USER" \
      --dbname "$POSTGRES_DB" \
      --file "$sql_file"
  done
}

apply_sql_directory "$database_root/schema"
apply_sql_directory "$database_root/migrations"
apply_sql_directory "$database_root/seeds"
