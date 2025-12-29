FROM postgres:15-alpine

# Устанавливаем curl (он не всегда есть в alpine образах базы) и cron
RUN apk add --no-cache curl dcron

# Копируем скрипт
COPY backup_postgres.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

# Создаем папку для бэкапов и логов
RUN mkdir -p /backups/postgres && \
    touch /var/log/cron.log

# Настраиваем CRON: запускать скрипт каждый день в 3:00
# Важный момент: передаем переменные окружения в скрипт, иначе cron их не увидит
RUN echo "0 3 * * * . /env_vars.sh && /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1" > /etc/crontabs/root

# Скрипт-обертка для сохранения ENV переменных перед запуском cron
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'printenv | grep -v "no_proxy" >> /env_vars.sh' >> /entrypoint.sh && \
    echo 'crond -f -l 2' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
