# 1. Остановить PostgreSQL
Stop-Service "postgresql-1c-16" -Force

# 2. Временно разрешить вход без пароля
# Отредактировать: E:\DEV_LOCAL\INSTALLED\PostgreSQL 1C\16\data\pg_hba.conf
# Найти строку:
# host    all             all             127.0.0.1/32            scram-sha-256
# Заменить на:
# host    all             all             127.0.0.1/32            trust

# 3. Запустить PostgreSQL
Start-Service "postgresql-1c-16"

# 4. Сменить пароль
& "E:\DEV_LOCAL\INSTALLED\PostgreSQL 1C\16\bin\psql.exe" -U postgres -c "ALTER USER postgres WITH PASSWORD '123';"

# 5. Вернуть pg_hba.conf обратно
# 6. Перезапустить PostgreSQL