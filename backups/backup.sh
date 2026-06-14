#!/usr/bin/env bash
set -euo pipefail

# Backup script for Sprint 4
# Creates a SQL dump of PostgreSQL database and archives the media uploads directory.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

# Load environment variables from .env if present
if [ -f .env ]; then
  set -o allexport
  # shellcheck disable=SC1091
  . .env
  set +o allexport
fi

TIMESTAMP=$(date +"%Y_%m_%d_%H%M%S")
BACKUP_BASE="backups"
DB_DIR="$BACKUP_BASE/data"
MEDIA_DIR="${MEDIA_DIR:-uploads}"
MEDIA_DIR_PATH="$REPO_ROOT/$MEDIA_DIR"
MEDIA_BACKUP_DIR="$BACKUP_BASE/media"

mkdir -p "$DB_DIR" "$MEDIA_BACKUP_DIR"

BACKUP_FILE="$DB_DIR/db_backup_${TIMESTAMP}.sql"
MEDIA_ARCHIVE="$MEDIA_BACKUP_DIR/media_${TIMESTAMP}.tar.gz"

echo "[backup] Starting backup: $TIMESTAMP"

echo "[backup] Creating DB backup to $BACKUP_FILE"
if [ -n "${POSTGRES_CONTAINER:-}" ]; then
  # If PostgreSQL runs in Docker, allow specifying POSTGRES_CONTAINER in .env
  docker exec "$POSTGRES_CONTAINER" pg_dump -U "${DB_USER:-postgres}" -h "${DB_HOST:-localhost}" "${DB_NAME:-postgres}" > "$BACKUP_FILE"
else
  PGPASSWORD="${DB_PASSWORD:-}" pg_dump -h "${DB_HOST:-localhost}" -p "${DB_PORT:-5432}" -U "${DB_USER:-postgres}" -F p -f "$BACKUP_FILE" "${DB_NAME:-postgres}"
fi

echo "[backup] Archiving media from $MEDIA_DIR to $MEDIA_ARCHIVE"
if [ -d "$MEDIA_DIR_PATH" ]; then
  tar -czf "$MEDIA_ARCHIVE" -C "$(dirname "$MEDIA_DIR_PATH")" "$(basename "$MEDIA_DIR_PATH")"
else
  echo "[backup] Warning: media dir $MEDIA_DIR_PATH not found, skipping media backup"
fi

echo "[backup] Backup complete. Files:"
echo "  - $BACKUP_FILE"
echo "  - $MEDIA_ARCHIVE"

exit 0
