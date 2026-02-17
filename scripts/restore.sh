#!/bin/bash
set -euo pipefail

echo "=== grit restore ==="
echo ""

if [ -z "${BACKUP_TIMESTAMP:-}" ] || [ "${BACKUP_TIMESTAMP}" = "latest" ]; then
    if [ ! -f /backups/backups/latest.txt ]; then
        echo "ERROR: No backups found. Run a backup first."
        exit 1
    fi
    BACKUP_TIMESTAMP=$(cat /backups/backups/latest.txt)
    echo "Restoring latest backup: ${BACKUP_TIMESTAMP}"
else
    echo "Restoring backup: ${BACKUP_TIMESTAMP}"
fi

BACKUP_DIR="/backups/backups/${BACKUP_TIMESTAMP}"

if [ ! -d "${BACKUP_DIR}" ]; then
    echo "ERROR: Backup not found: ${BACKUP_DIR}"
    echo ""
    echo "Available backups:"
    ls -1 /backups/backups/ 2>/dev/null | grep -v latest.txt || echo "  (none)"
    exit 1
fi

echo ""
echo "Verifying backup integrity..."
cd "${BACKUP_DIR}"
if ! sha256sum -c checksums.sha256; then
    echo ""
    echo "ERROR: Checksum verification failed. Backup may be corrupted."
    exit 1
fi
echo ""

echo "Restoring database..."
psql -h db -U "${POSTGRES_USER}" -d postgres -c "
    SELECT pg_terminate_backend(pg_stat_activity.pid)
    FROM pg_stat_activity
    WHERE pg_stat_activity.datname = '${GRIT_DATABASE}'
    AND pid <> pg_backend_pid();
" > /dev/null 2>&1 || true

psql -h db -U "${POSTGRES_USER}" -d postgres -c "DROP DATABASE IF EXISTS \"${GRIT_DATABASE}\";"
psql -h db -U "${POSTGRES_USER}" -d postgres -c "CREATE DATABASE \"${GRIT_DATABASE}\";"
gunzip < "${BACKUP_DIR}/database.sql.gz" | psql -h db -U "${POSTGRES_USER}" "${GRIT_DATABASE}" > /dev/null
echo "  Database restored"

echo "Restoring file storage..."
rm -rf /file_storage/*
tar xzf "${BACKUP_DIR}/file_storage.tar.gz" -C /file_storage
echo "  File storage restored"

echo ""
echo "Restore complete from backup: ${BACKUP_TIMESTAMP}"
