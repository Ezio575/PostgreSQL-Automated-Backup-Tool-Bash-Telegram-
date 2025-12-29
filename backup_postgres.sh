#!/bin/bash

# --- Настройки ---
DB_NAME=${DB_NAME:-"my_db"}
DB_USER=${DB_USER:-"my_username"}
BACKUP_DIR=${BACKUP_DIR:-"/my/dir/here/postgres"}
KEEP_DAYS=5
TG_TOKEN="12345:ASDFG...."
TG_CHAT_ID="987654321"

DATE=$(date +%Y-%m-%d_%H-%M-%S)
FILENAME="$DB_NAME-$DATE.sql.gz"
FULL_PATH="$BACKUP_DIR/$FILENAME"
LOG_FILE="$BACKUP_DIR/backup.log"

#Send
send_tg() {
    local MESSAGE="$1"
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
         --data-urlencode "chat_id=${TG_CHAT_ID}" \
         --data-urlencode "text=${MESSAGE}" > /dev/null
}

#Time Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Проверка прав
mkdir -p "$BACKUP_DIR"
if [ ! -w "$BACKUP_DIR" ]; then
    MSG="❌ ОШИБКА: Нет прав записи в $BACKUP_DIR"
    echo "$MSG" | tee -a "$LOG_FILE"
    send_tg "$MSG"
    exit 1
fi
log "✅ Директория $BACKUP_DIR готова для записи"

# СОЗДАНИЕ ДАМПА
log "Начинаем создание бэкапа: $FILENAME"
pg_dump -h localhost -U "$DB_USER" "$DB_NAME" | gzip > "$FULL_PATH"
EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -ne 0 ]; then
    MSG="❌ ОШИБКА БЭКАПА (Код: $EXIT_CODE). База: $DB_NAME"
    log "$MSG"
    send_tg "$MSG"
    exit 1
fi

SIZE=$(du -sh "$FULL_PATH" | cut -f1)
log "✅ Дамп создан: $FULL_PATH ($SIZE)"

# 2. Ротация
OLD_FILES=$(find "$BACKUP_DIR" -maxdepth 1 -name "*.sql.gz" -mtime +$KEEP_DAYS -print0 2>/dev/null)
OLD_COUNT=$(echo "$OLD_FILES" | tr '\0' '\n' | grep -c .)

if [ "$OLD_COUNT" -gt 0 ]; then
    log "🔄 Ротация: удаляем $OLD_COUNT старых файлов (> $KEEP_DAYS дней)"
    echo "$OLD_FILES" | xargs -0 -r rm -v 2>/dev/null | while read DELETED; do
        log "🗑️  Удалён: $DELETED"
    done
    NEW_COUNT=$(find "$BACKUP_DIR" -maxdepth 1 -name "*.sql.gz" | wc -l)
    MSG="✅ Бэкап: $SIZE. Удалено старых: $OLD_COUNT. Осталось: $NEW_COUNT"
else
    NEW_COUNT=$(find "$BACKUP_DIR" -maxdepth 1 -name "*.sql.gz" | wc -l)
    MSG="✅ Бэкап: $SIZE. Ротация пропущена (нет старых файлов). Всего: $NEW_COUNT"
fi

# 3. ОТПРАВКА
send_tg "$MSG"
log "$MSG"
