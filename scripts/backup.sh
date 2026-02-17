#!/bin/bash
set -euo pipefail

echo "=== grit backup ==="
echo ""

TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
BACKUP_DIR="/backups/backups/${TIMESTAMP}"

echo "Creating backup: ${TIMESTAMP}"
echo ""

mkdir -p "${BACKUP_DIR}"

echo "Backing up database..."
pg_dump -h db -U "${POSTGRES_USER}" "${GRIT_DATABASE}" | gzip > "${BACKUP_DIR}/database.sql.gz"
DB_SIZE=$(du -h "${BACKUP_DIR}/database.sql.gz" | cut -f1)
echo "  database.sql.gz (${DB_SIZE})"

echo "Backing up file storage..."
tar czf "${BACKUP_DIR}/file_storage.tar.gz" -C /file_storage .
FS_SIZE=$(du -h "${BACKUP_DIR}/file_storage.tar.gz" | cut -f1)
echo "  file_storage.tar.gz (${FS_SIZE})"

echo "Generating checksums..."
cd "${BACKUP_DIR}"
sha256sum database.sql.gz file_storage.tar.gz > checksums.sha256

echo "${TIMESTAMP}" > /backups/backups/latest.txt

echo ""
echo "Backup complete: grit-backups/backups/${TIMESTAMP}/"
