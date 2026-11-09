#!/usr/bin/env bash
# Backup PostgreSQL của TripFlow, giữ 7 bản gần nhất.
# Dùng trong cron:
#   0 2 * * * BACKUP_DIR=/backup /opt/tripflow/tools/backup_postgres.sh >> /var/log/tripflow-backup.log 2>&1
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/backup}"
CONTAINER="${CONTAINER:-tripflow_postgres_db}"
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-tripflow}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

mkdir -p "$BACKUP_DIR"
STAMP="$(date +%F_%H%M%S)"
TARGET="$BACKUP_DIR/tripflow-$STAMP.sql.gz"

echo "[$(date -Iseconds)] Backup $DB_NAME -> $TARGET"
docker exec "$CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$TARGET"

# Kiểm tra file không rỗng trước khi xoá bản cũ.
if [ ! -s "$TARGET" ]; then
  echo "Backup rỗng, huỷ bỏ." >&2
  rm -f "$TARGET"
  exit 1
fi

find "$BACKUP_DIR" -name 'tripflow-*.sql.gz' -type f -mtime +"$RETENTION_DAYS" -delete
echo "[$(date -Iseconds)] Xong. $(ls -1 "$BACKUP_DIR"/tripflow-*.sql.gz | wc -l) bản backup."
