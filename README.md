# PostgreSQL-Automated-Backup-Tool-Bash-Telegram-
Cкрипт для автоматизации бэкапов PostgreSQL с защитой от переполнения диска и уведомлениями в Telegram
Features
    Zero-Downtime: Горячий бэкап через pg_dump — база продолжает работать
    Security First: Пароли в .pgpass, токены в переменных окружения (никаких plaintext!)
    Smart Rotation: Автоматическое удаление старых бэкапов (>7 дней) с логированием
    Instant Alerts: Мгновенные уведомления в Telegram о успехе/ошибках
    Fail-Safe: Проверки прав доступа, детальное логирование, graceful exit
Prerequisites
bash
# Необходимые пакеты (Ubuntu/Debian)
sudo apt install postgresql-client curl gzip
# 1. Создай файл ~/.pgpass с правами 0600
echo "localhost:5432:*:ezio575:твой_пароль" > ~/.pgpass
chmod 0600 ~/.pgpass
# 2. Создай Telegram-бота у @BotFather
# Получи TG_TOKEN и свой chat_id через @userinfobot
Quick Start
  1. Сохрани скрипт
# Создай файл
nano ~/backup_postgres.sh
chmod +x ~/backup_postgres.sh
  2. Настрой переменные (лучше через .env)
# Создай .env файл
cat > ~/.backup.env << EOF
DB_NAME=my_db
DB_USER=ezio575
BACKUP_DIR=/home/ezio575/backups/postgres
TG_TOKEN=1198216242:AAG88zn0qlYEzXH2QN6lddlFwOC1NuNNZLk
TG_CHAT_ID=639493833
EOF
# Загружай в скрипте: source ~/.backup.env
  3. Добавь в crontab
crontab -e
# Запуск каждый день в 3:00 ночи
0 3 * * * /home/ezio575/backup_postgres.sh
# Или каждый час для теста: 0 * * * * /home/ezio575/backup_postgres.sh
  4. Первый запуск
source ~/.backup.env && ~/backup_postgres.sh

  **Configuration/Что изменить в конфигурации**
DB_NAME	Имя базы данных
DB_USER	Пользователь PostgreSQL
BACKUP_DIR	Папка для бэкапов
KEEP_DAYS	Хранить бэкапы N дней
TG_TOKEN	Токен Telegram бота	ОБЯЗАТЕЛЬНО!
TG_CHAT_ID	Твой chat_id	ОБЯЗАТЕЛЬНО!

**Пример уведомлений Telegram
✅ Бэкап: 12M. Удалено старых: 2. Осталось: 8
❌ ОШИБКА: Нет прав записи в /backups/postgres
❌ ОШИБКА БЭКАПА (Код: 1). База: my_db
**Security Checklist
    .pgpass имеет права 0600
    .env НЕ в git (добавь в .gitignore)
    BACKUP_DIR принадлежит пользователю cron
    Токен бота НЕ в истории bash (history -c)

**Troubleshooting**
Could not resolve host	Проверь интернет/DNS
403 Forbidden: bots can't send to bots	Проверь TG_CHAT_ID через @userinfobot
No such file or directory	mkdir -p $BACKUP_DIR
Permission denied	chown $USER:$USER $BACKUP_DIR

**Для нескольких баз:**
# Создай массив баз
DB_LIST=("db1" "db2" "critical_db")
for DB_NAME in "${DB_LIST[@]}"; do
    ./backup_postgres.sh
done

**Docker-версия:**
FROM postgres:15-alpine
COPY backup_postgres.sh /backup.sh
RUN chmod +x /backup.sh
CMD cron && tail -f /var/log/cron.log

Автор: Sergey Popov-Pogasy с ИИ-помощником
