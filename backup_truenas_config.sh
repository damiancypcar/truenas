#!/bin/sh
# backup TrueNAS config by copying /data/freenas-v1.db after stopping middlewared

# restore backup
# 1. Stop middlewared
# 2. cp -vf $BACKUP_DIR/freenas-v1_YYYYmmdd_HHMMSS.db /data/freenas-v1.db
# 3. Start middlewared

# cron setup - every Wednesday at 3:00 AM
# 0 3 * * 3 /mnt/ssd1/HOME/user/work/truenas/backup_truenas_config.sh >> /var/log/backup_truenas.log 2>&1

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo; echo "Error: This script must be run as root." >&2
  exit 1
fi

echo; echo "> Backup script started at: $(date)"

BACKUP_DIR="/mnt/hdd1/backups/truenas-config"
mkdir -p "$BACKUP_DIR"

# Backup file name with date and time
BACKUP_FILE="$BACKUP_DIR/freenas-v1_$(date +%Y%m%d_%H%M%S).db"

# Download configuration and decode from base64
echo "- Start backup of TrueNAS config"
echo "--- Stopping middlewared to ensure consistent backup..."
if ! systemctl stop middlewared; then
    echo "Failed to stop middlewared, aborting backup."
    exit 1
fi

echo "--- Starting backup of TrueNAS config..."
if cp /data/freenas-v1.db "$BACKUP_FILE"; then
    echo "Backup saved to $BACKUP_FILE"
else
    echo "Failed to copy config file, restarting middlewared..."
    systemctl restart middlewared
    exit 1
fi

echo "--- Starting middlewared again..."
if ! systemctl start middlewared; then
    echo "Warning: failed to start middlewared after backup."
fi

# Delete backups older than 7 days
echo "- Delete backups older than 30 days from $BACKUP_DIR/"
find "$BACKUP_DIR" -type f -name "freenas-v1_*.db" -mtime +30 -print -exec rm {} \;

echo "> Backup script finished at: $(date)"; echo
