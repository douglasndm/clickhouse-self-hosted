# ClickHouse backups

This project uses ClickHouse's native `BACKUP`/`RESTORE` SQL commands. The
configured `backups` disk is mounted at `/backups` in the container and maps to
the host directory `./backups`, separate from the data directory `./data`.

## How native backup works

ClickHouse creates a consistent backup of table metadata and data parts while
the server remains online. The backup is written to a configured destination
(`Disk`, `File`, or `S3`). A backup is not a replica and does not protect
against loss of the host or the backup volume, so production backups should be
copied to independent object storage.

## Create a backup

Start the service and run:

```sh
docker compose up -d
sh scripts/backup.sh
```

To choose a stable name, which is useful for automation:

```sh
BACKUP_NAME=full-2026-09-03 sh scripts/backup.sh
```

## Daily backup and retention

The scheduled wrapper creates a UTC-named full backup and removes completed
`full-*` backup directories older than 7 days. Install this line in the host
user's crontab with `crontab -e`:

```cron
0 2 * * * /Users/douglasndm/Projects/services/clickhouse/scripts/backup-daily.sh >> /Users/douglasndm/Projects/services/clickhouse/logs/backup-cron.log 2>&1
```

Adjust the project path if necessary. The schedule runs daily at 02:00 in the
host's local timezone. To change retention:

```cron
0 2 * * * BACKUP_RETENTION_DAYS=7 /Users/douglasndm/Projects/services/clickhouse/scripts/backup-daily.sh >> /Users/douglasndm/Projects/services/clickhouse/logs/backup-cron.log 2>&1
```

Cron does not load the interactive shell environment. The script intentionally
uses the container's local `clickhouse-client`, so it does not depend on
`CLICKHOUSE_USER` or `CLICKHOUSE_PASSWORD` being exported by the host shell.
Keep the ClickHouse container running before the scheduled time.

Check recent operations from `system.backups`:

```sh
docker compose exec clickhouse clickhouse-client \
  --query "SELECT name, status, start_time, end_time, num_files, uncompressed_size FROM system.backups ORDER BY start_time DESC LIMIT 10"
```

## Restore a backup

Restore into a disposable or empty environment first. The command asks for
confirmation because restoring can conflict with existing tables.

```sh
BACKUP_NAME=full-2026-09-03 sh scripts/restore.sh
```

After restoring, validate row counts and application queries before switching
traffic to the restored instance.

## Production operation

The local destination is suitable for development and as a staging target.
For production, configure an S3-compatible destination (AWS S3, MinIO, or
equivalent), keep credentials in ClickHouse's named collections or a secrets
mechanism, and schedule backups from an external scheduler. Define retention
and test restores regularly. Incremental backups can use the native
`base_backup` setting after a full backup; retain the full backup and every
dependent incremental backup as one chain.
