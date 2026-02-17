#!/bin/bash
set -euo pipefail

echo "=== grit backup list ==="
echo ""

BACKUPS_DIR="/backups/backups"

# Check if any backups exist
if [ ! -d "${BACKUPS_DIR}" ] || [ -z "$(ls -d "${BACKUPS_DIR}"/*/ 2>/dev/null)" ]; then
    echo "No backups found."
    echo ""
    echo "Create one with: docker compose run --rm backup"
    exit 0
fi

# Read the latest pointer
LATEST=""
if [ -f "${BACKUPS_DIR}/latest.txt" ]; then
    LATEST=$(cat "${BACKUPS_DIR}/latest.txt")
fi

# Count backups
BACKUP_COUNT=0
for dir in "${BACKUPS_DIR}"/*/; do
    [ -d "${dir}" ] && BACKUP_COUNT=$((BACKUP_COUNT + 1))
done

echo "Found ${BACKUP_COUNT} backup(s):"
echo ""

# Print header
printf "  %-21s  %-10s  %-10s  %-10s  %-10s  %s\n" \
    "TIMESTAMP" "DATABASE" "FILES" "TOTAL" "CHECKSUM" ""
printf "  %-21s  %-10s  %-10s  %-10s  %-10s  %s\n" \
    "---------------------" "----------" "----------" "----------" "----------" ""

# Iterate over backup directories in chronological order
for dir in $(ls -d "${BACKUPS_DIR}"/*/ 2>/dev/null | sort); do
    TIMESTAMP=$(basename "${dir}")

    # Get file sizes
    if [ -f "${dir}/database.sql.gz" ]; then
        DB_SIZE=$(du -h "${dir}/database.sql.gz" | cut -f1)
    else
        DB_SIZE="missing"
    fi

    if [ -f "${dir}/file_storage.tar.gz" ]; then
        FS_SIZE=$(du -h "${dir}/file_storage.tar.gz" | cut -f1)
    else
        FS_SIZE="missing"
    fi

    # Calculate total size of the backup directory
    TOTAL_SIZE=$(du -sh "${dir}" | cut -f1)

    # Verify checksums
    if [ -f "${dir}/checksums.sha256" ]; then
        cd "${dir}"
        if sha256sum -c checksums.sha256 > /dev/null 2>&1; then
            CHECKSUM="OK"
        else
            CHECKSUM="FAILED"
        fi
    else
        CHECKSUM="missing"
    fi

    # Mark latest
    LABEL=""
    if [ "${TIMESTAMP}" = "${LATEST}" ]; then
        LABEL="<- latest"
    fi

    printf "  %-21s  %-10s  %-10s  %-10s  %-10s  %s\n" \
        "${TIMESTAMP}" "${DB_SIZE}" "${FS_SIZE}" "${TOTAL_SIZE}" "${CHECKSUM}" "${LABEL}"
done

echo ""
echo "Restore a backup with: docker compose run --rm restore"
echo "Restore a specific backup: BACKUP_TIMESTAMP=<timestamp> docker compose run --rm restore"
