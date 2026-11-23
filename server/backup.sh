#!/bin/sh
# Günlük yedek: her gün BACKUP_HOUR_UTC'de pg_dump (özel biçim) -> /backups/qrpro-YYYYmmdd-HHMMSS.dump.
# BACKUP_KEEP_DAYS günden eski yedekler silinir. Açılışta son 24 saatte yedek yoksa hemen bir tane alınır.
# Bağlantı PGHOST/PGUSER/PGDATABASE/PGPASSWORD ortam değişkenlerinden gelir (docker-compose.yml).
set -u

KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"
HOUR="${BACKUP_HOUR_UTC:-3}"
DIR=/backups

log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*"; }

backup() {
    ts=$(date -u +%Y%m%d-%H%M%S)
    part="$DIR/.qrpro-$ts.dump.part"
    if pg_dump --format=custom --no-owner --file="$part"; then
        mv "$part" "$DIR/qrpro-$ts.dump"
        log "yedek alındı: qrpro-$ts.dump ($(du -h "$DIR/qrpro-$ts.dump" | cut -f1))"
    else
        rm -f "$part"
        log "HATA: yedek alınamadı" >&2
    fi
    find "$DIR" -name 'qrpro-*.dump' -type f -mtime +$((KEEP_DAYS - 1)) -print -delete | sed 's/^/silindi: /'
}

# docker stop beklemesin.
trap 'exit 0' TERM INT

if [ -z "$(find "$DIR" -name 'qrpro-*.dump' -type f -mtime -1)" ]; then
    backup
fi

while true; do
    now=$(date -u +%s)
    next=$(date -u -d "$(date -u +%Y-%m-%d) $(printf '%02d' "$HOUR"):00:00" +%s)
    if [ "$next" -le "$now" ]; then
        next=$((next + 86400))
    fi
    log "sonraki yedek: $(date -u -d "@$next" +%Y-%m-%dT%H:%M:%SZ)"
    sleep $((next - now)) &
    wait $!
    backup
done
