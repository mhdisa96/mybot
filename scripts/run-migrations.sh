#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
: "${DATABASE_URL:?DATABASE_URL is required}"
for f in "$ROOT"/database/migrations/*.sql; do echo "Applying $f"; psql "$DATABASE_URL" -f "$f"; done
