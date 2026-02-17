#!/bin/bash
set -euo pipefail

echo "=== grit backup cleanup ==="
echo ""

BACKUPS_DIR="/backups/backups"
KEEP_LAST="${KEEP_LAST:-5}"
DRY_RUN="${DRY_RUN:-false}"

# Validate KEEP_LAST is a positive integer
if ! echo "${KEEP_LAST}" | grep -qE '^[1-9][0-9]*$'; then
    echo "ERROR: KEEP_LAST must be a positive integer. Got: ${KEEP_LAST}"
    exit 1
fi

if [ "${DRY_RUN}" = "true" ]; then
    echo "DRY RUN MODE - no backups will be deleted"
    echo ""
fi

echo "Retention policy: keep last ${KEEP_LAST} backup(s)"
echo ""

# Check if any backups exist
if [ ! -d "${BACKUPS_DIR}" ] || [ -z "$(ls -d "${BACKUPS_DIR}"/*/ 2>/dev/null)" ]; then
    echo "No backups found. Nothing to clean up."
    exit 0
fi

# Read the latest pointer
LATEST=""
if [ -f "${BACKUPS_DIR}/latest.txt" ]; then
    LATEST=$(cat "${BACKUPS_DIR}/latest.txt")
fi

# Collect all backup timestamps sorted chronologically (oldest first)
BACKUPS=()
for dir in $(ls -d "${BACKUPS_DIR}"/*/ 2>/dev/null | sort); do
    BACKUPS+=("$(basename "${dir}")")
done

TOTAL_COUNT=${#BACKUPS[@]}
echo "Found ${TOTAL_COUNT} backup(s)"

if [ "${TOTAL_COUNT}" -le "${KEEP_LAST}" ]; then
    echo ""
    echo "Nothing to clean up (${TOTAL_COUNT} <= ${KEEP_LAST})."
    exit 0
fi

# Determine which backups to keep (the most recent KEEP_LAST entries)
# The backup marked as "latest" is always protected
DELETE_COUNT=0
KEEP_COUNT=0
DELETE_LIST=()
KEEP_LIST=()

KEEP_START=$((TOTAL_COUNT - KEEP_LAST))

for i in "${!BACKUPS[@]}"; do
    TIMESTAMP="${BACKUPS[$i]}"
    if [ "$i" -ge "${KEEP_START}" ]; then
        KEEP_LIST+=("${TIMESTAMP}")
        KEEP_COUNT=$((KEEP_COUNT + 1))
    elif [ "${TIMESTAMP}" = "${LATEST}" ]; then
        KEEP_LIST+=("${TIMESTAMP}")
        KEEP_COUNT=$((KEEP_COUNT + 1))
    else
        DELETE_LIST+=("${TIMESTAMP}")
        DELETE_COUNT=$((DELETE_COUNT + 1))
    fi
done

if [ "${DELETE_COUNT}" -eq 0 ]; then
    echo ""
    echo "Nothing to clean up."
    exit 0
fi

echo ""
echo "Backups to KEEP (${KEEP_COUNT}):"
for ts in "${KEEP_LIST[@]}"; do
    LABEL=""
    if [ "${ts}" = "${LATEST}" ]; then
        LABEL=" (latest)"
    fi
    SIZE=$(du -sh "${BACKUPS_DIR}/${ts}" | cut -f1)
    echo "  ${ts}  ${SIZE}${LABEL}"
done

echo ""
echo "Backups to DELETE (${DELETE_COUNT}):"
for ts in "${DELETE_LIST[@]}"; do
    SIZE=$(du -sh "${BACKUPS_DIR}/${ts}" | cut -f1)
    echo "  ${ts}  ${SIZE}"
done

if [ "${DRY_RUN}" = "true" ]; then
    echo ""
    echo "DRY RUN complete. No backups were deleted."
    echo "Remove DRY_RUN=true to perform the actual cleanup."
    exit 0
fi

echo ""
echo "Deleting ${DELETE_COUNT} backup(s)..."

for ts in "${DELETE_LIST[@]}"; do
    rm -rf "${BACKUPS_DIR}/${ts}"
    echo "  Deleted: ${ts}"
done

# Verify remaining count
REMAINING=0
for dir in "${BACKUPS_DIR}"/*/; do
    [ -d "${dir}" ] && REMAINING=$((REMAINING + 1))
done

echo ""
echo "Cleanup complete. ${DELETE_COUNT} backup(s) deleted, ${REMAINING} remaining."
