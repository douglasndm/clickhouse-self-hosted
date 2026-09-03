#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
backup_dir="${project_dir}/backups"
retention_days="${BACKUP_RETENTION_DAYS:-7}"
backup_name="full-$(date -u +%Y%m%dT%H%M%SZ)"

case "${retention_days}" in
  ''|*[!0-9]*)
    printf 'BACKUP_RETENTION_DAYS must be a non-negative integer.\n' >&2
    exit 1
    ;;
esac

cd "${project_dir}"
BACKUP_NAME="${backup_name}" sh scripts/backup.sh

# Remove only completed backup directories older than the retention period.
find "${backup_dir}" -mindepth 1 -maxdepth 1 -type d -name 'full-*' \
  -mtime "+${retention_days}" -exec rm -rf -- {} +

printf 'Backups older than %s days removed.\n' "${retention_days}"
