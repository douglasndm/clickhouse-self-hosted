#!/bin/sh
set -eu

backup_name="${BACKUP_NAME:?BACKUP_NAME is required}"

case "${backup_name}" in
  ''|*[!A-Za-z0-9._-]*)
    printf 'BACKUP_NAME may contain only letters, numbers, dot, underscore, and hyphen.\n' >&2
    exit 1
    ;;
esac

printf 'Restoring backup %s. This can overwrite existing data. Continue? [y/N] ' "${backup_name}"
read -r answer
case "${answer}" in
  y|Y|yes|YES) ;;
  *) printf 'Restore cancelled.\n'; exit 1 ;;
esac

docker compose exec -T clickhouse clickhouse-client \
  --query "RESTORE ALL FROM Disk('backups', '${backup_name}')"

printf 'Restore completed: %s\n' "${backup_name}"
