#!/usr/bin/env bash
set -euo pipefail

# Restore script for Sprint 4
# Restores DB and media files from backups created by backup.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

# Load environment variables from .env if present
if [ -f .env ]; then
  set -o allexport
  # shellcheck disable=SC1091
  . .env
  set +o allexport
fi

BACKUP_BASE="backups"
DB_DIR="$BACKUP_BASE/data"
MEDIA_BACKUP_DIR="$BACKUP_BASE/media"
MEDIA_DIR="${MEDIA_DIR:-uploads}"
MEDIA_DIR_PATH="$REPO_ROOT/$MEDIA_DIR"

SQL_FILE="${1:-}"
MEDIA_ARCHIVE="${2:-}"

if [ -z "$SQL_FILE" ]; then
  SQL_FILE=$(ls -t "$DB_DIR"/db_backup_*.sql 2>/dev/null | head -n1 || true)
fi
if [ -z "$MEDIA_ARCHIVE" ]; then
  MEDIA_ARCHIVE=$(ls -t "$MEDIA_BACKUP_DIR"/media_*.tar.gz 2>/dev/null | head -n1 || true)
fi

if [ -z "$SQL_FILE" ]; then
  echo "[restore] No SQL backup found in $DB_DIR"
  exit 1
fi

echo "[restore] SQL file to restore: $SQL_FILE"
echo "[restore] Media archive: ${MEDIA_ARCHIVE:-<none>}"

read -p "This will DROP ALL DATA in database '${DB_NAME:-postgres}'. Continue? [y/N] " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "[restore] Aborted by user"
  exit 2
fi

echo "[restore] Dropping public schema and recreating it"
PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DB_HOST:-localhost}" -p "${DB_PORT:-5432}" -U "${DB_USER:-postgres}" -d "${DB_NAME:-postgres}" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

echo "[restore] Restoring SQL from $SQL_FILE"
PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DB_HOST:-localhost}" -p "${DB_PORT:-5432}" -U "${DB_USER:-postgres}" -d "${DB_NAME:-postgres}" -f "$SQL_FILE"

if [ -n "${MEDIA_ARCHIVE:-}" ] && [ -f "$MEDIA_ARCHIVE" ]; then
  echo "[restore] Restoring media into $MEDIA_DIR_PATH"
  rm -rf "$MEDIA_DIR_PATH"
  mkdir -p "$(dirname "$MEDIA_DIR_PATH")"
  tar -xzf "$MEDIA_ARCHIVE" -C "$(dirname "$MEDIA_DIR_PATH")"
else
  echo "[restore] No media archive found or provided - skipping media restore"
fi

echo "[restore] Restore complete"

exit 0
