#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
coverage_root="$repository_root/artifacts/coverage"
backend_results="$coverage_root/backend/test-results"
backend_lcov="$coverage_root/backend/lcov.info"
flutter_lcov="$coverage_root/flutter/lcov.info"
summary="$coverage_root/summary.md"
update_baseline=false

if [ "${1:-}" = "--update-baseline" ]; then
  update_baseline=true
  shift
fi

if [ "$#" -ne 0 ]; then
  echo "Usage: ./scripts/check-coverage.sh [--update-baseline]" >&2
  exit 2
fi

rm -rf "$coverage_root"
mkdir -p "$backend_results" "$(dirname "$flutter_lcov")"

dotnet test \
  "$repository_root/api/FitnessStudio.Api.Tests/FitnessStudio.Api.Tests.csproj" \
  --collect:"XPlat Code Coverage" \
  --settings "$repository_root/api/coverage.runsettings" \
  --results-directory "$backend_results"

generated_backend_lcov=$(find "$backend_results" -name 'coverage.info' -print -quit)
if [ -z "$generated_backend_lcov" ]; then
  echo "Backend LCOV report was not generated." >&2
  exit 1
fi
cp "$generated_backend_lcov" "$backend_lcov"

(
  cd "$repository_root/mobile/fitness_studio_mobile"
  flutter pub get
  flutter test --coverage --coverage-path="$flutter_lcov"
)

set -- \
  --backend "$backend_lcov" \
  --flutter "$flutter_lcov" \
  --baseline "$repository_root/tool/coverage_baseline.json" \
  --summary "$summary"

if [ -n "${COVERAGE_BASE_REF:-}" ]; then
  set -- "$@" --base-ref "$COVERAGE_BASE_REF"
fi
if [ "$update_baseline" = true ]; then
  set -- "$@" --update-baseline
fi

dart run "$repository_root/tool/coverage_gate.dart" "$@"
