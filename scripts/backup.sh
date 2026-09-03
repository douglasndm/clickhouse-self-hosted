#!/bin/sh
set -eu

backup_name="${BACKUP_NAME:-full-$(date -u +%Y%m%dT%H%M%SZ)}"

case "${backup_name}" in
  ''|*[!A-Za-z0-9._-]*)
    printf 'BACKUP_NAME may contain only letters, numbers, dot, underscore, and hyphen.\n' >&2
    exit 1
    ;;
esac

docker compose exec -T clickhouse clickhouse-client \
  --query "BACKUP ALL TO Disk('backups', '${backup_name}')"

printf 'Backup completed: %s\n' "${backup_name}"
