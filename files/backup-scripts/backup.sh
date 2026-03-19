#!/bin/bash

set -e

DATE=$(date +%F)

INFRA_DIR="/opt/infra"
APP_DIR="/opt/app"
BACKUP_DIR="/opt/backups"
LOG_FILE="/opt/backups/backup.log"
RETENTION_DAYS=7

echo "=== BACKUP START $DATE ===" | tee -a $LOG_FILE

mkdir -p "$BACKUP_DIR"

echo "Backup INFRA..." | tee -a $LOG_FILE
tar -czf "$BACKUP_DIR/infra-backup-$DATE.tar.gz" "$INFRA_DIR"

echo "Backup APP..." | tee -a $LOG_FILE
tar -czf "$BACKUP_DIR/app-backup-$DATE.tar.gz" "$APP_DIR"

echo "Backup Grafana volume..." | tee -a $LOG_FILE
docker run --rm \
  -v monitoring_grafana_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czf "/backup/grafana-backup-$DATE.tar.gz" -C /data .

echo "Backup Prometheus volume..." | tee -a $LOG_FILE
docker run --rm \
  -v monitoring_prometheus_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czf "/backup/prometheus-backup-$DATE.tar.gz" -C /data .

echo "Backup Loki volume..." | tee -a $LOG_FILE
docker run --rm \
  -v monitoring_loki_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czf "/backup/loki-backup-$DATE.tar.gz" -C /data .

echo "Usuwanie backupów starszych niż $RETENTION_DAYS dni..." | tee -a $LOG_FILE
find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.tar.gz" -mtime +$RETENTION_DAYS -print -delete | tee -a $LOG_FILE

echo "=== BACKUP FINISHED ===" | tee -a $LOG_FILE
ls -lh "$BACKUP_DIR" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
