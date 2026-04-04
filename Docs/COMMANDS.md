# ⚡ Шпаргалка по командам

Быстрый справочник по основным командам для управления инфраструктурой 1C Home Server.

---

## 📋 Содержание

- [Docker Compose](#docker-compose)
- [Docker](#docker)
- [PowerShell](#powershell)
- [PostgreSQL](#postgresql)
- [Prometheus Queries](#prometheus-queries)
- [Grafana](#grafana)
- [Диагностика](#диагностика)
- [Бэкапы](#бэкапы)
- [Быстрые ссылки](#быстрые-ссылки)

[🔝 Наверх](#-шпаргалка-по-командам)

---

<a name="docker-compose"></a>
## 🐳 Docker Compose

### Управление сервисами

```powershell
# Запустить все сервисы
docker-compose up -d

# Остановить все сервисы
docker-compose down

# Перезапустить конкретный сервис
docker-compose restart <service_name>

# Остановить сервис (без удаления)
docker-compose stop <service_name>

# Запустить остановленный сервис
docker-compose start <service_name>

# Пересоздать контейнер
docker-compose up -d --force-recreate <service_name>

# Пересобрать образ
docker-compose build <service_name>

# Просмотреть логи
docker-compose logs <service_name> --tail 100

# Просмотреть логи в реальном времени
docker-compose logs -f <service_name>

# Проверить статус всех сервисов
docker-compose ps

# Проверить статус конкретного сервиса
docker-compose ps <service_name>

# Проверить конфигурацию (валидация)
docker-compose config
```

### Сервисы (имена из docker-compose.yml)

| Имя сервиса | Описание |
|-------------|----------|
| `postgres` | PostgreSQL 1С |
| `pgadmin` | Веб-интерфейс для управления БД |
| `portainer` | Управление контейнерами |
| `grafana` | Дашборды и алерты |
| `prometheus` | Сбор метрик |
| `blackbox-exporter` | HTTP-проверки |
| `postgres-exporter` | Метрики PostgreSQL |
| `cadvisor` | Метрики контейнеров |
| `vocechat-notifications` | Уведомления в чат |

[🔝 Наверх](#-шпаргалка-по-командам)

---

<a name="docker"></a>
## 🐳 Docker

### Контейнеры

```powershell
# Список всех контейнеров
docker ps -a

# Список только запущенных
docker ps

# Остановить контейнер
docker stop <container_name>

# Запустить контейнер
docker start <container_name>

# Перезапустить контейнер
docker restart <container_name>

# Удалить контейнер
docker rm <container_name>

# Удалить все остановленные контейнеры
docker container prune

# Войти в контейнер (bash)
docker exec -it <container_name> /bin/bash

# Войти в контейнер (sh)
docker exec -it <container_name> /bin/sh

# Выполнить команду в контейнере
docker exec <container_name> <command>
```

### Образы

```powershell
# Список образов
docker images

# Скачать образ
docker pull <image_name>

# Удалить образ
docker rmi <image_name>

# Удалить неиспользуемые образы
docker image prune

# Полная очистка unused образов
docker image prune -a
```

### Volumes

```powershell
# Список volumes
docker volume ls

# Инспектировать volume
docker volume inspect <volume_name>

# Удалить volume
docker volume rm <volume_name>

# Удалить неиспользуемые volumes
docker volume prune
```

### Сети

```powershell
# Список сетей
docker network ls

# Инспектировать сеть
docker network inspect <network_name>
```

### Очистка

```powershell
# Очистить всё (осторожно!)
docker system prune -a --volumes

# Проверить использование диска
docker system df
```

[🔝 Наверх](#-шпаргалка-по-командам)

---

<a name="powershell"></a>
## 💻 PowerShell

### Файлы и папки

```powershell
# Перейти в папку
cd E:\1C_Infrastructure

# Список файлов
Get-ChildItem
ls
dir

# Создать папку
mkdir NewFolder

# Скопировать файл
Copy-Item source.txt destination.txt

# Переместить файл
Move-Item source.txt destination\

# Удалить файл
Remove-Item file.txt

# Удалить папку
Remove-Item -Recurse -Force FolderName
```

### Git

```powershell
# Статус репозитория
git status

# Добавить файлы
git add .
git add filename.md

# Создать коммит
git commit -m "feat: описание изменений"

# Отправить на GitHub
git push origin master

# Создать тег
git tag -a v2.5-stable -m "Описание версии"
git push origin v2.5-stable

# Посмотреть историю
git log --oneline
git log -10
```

### Сеть

```powershell
# Проверить порты
netstat -ano | findstr ":5432"

# Проверить доступность хоста
Test-Connection 100.74.115.111

# Проверить порт
Test-NetConnection 100.74.115.111 -Port 5432
```

[🔝 Наверх](#-шпаргалка-по-командам)

---

<a name="postgresql"></a>
## 🐘 PostgreSQL

### Подключение

```powershell
# Через Docker exec
docker exec -it postgres-1c psql -U postgres

# С указанием базы данных
docker exec -it postgres-1c psql -U postgres -d template1c
```

### Базы данных

```sql
-- Список баз данных
\l

-- Создать базу
CREATE DATABASE "MyDatabase";

-- Удалить базу
DROP DATABASE "MyDatabase";

-- Подключиться к базе
\c MyDatabase

-- Размер базы
SELECT pg_size_pretty(pg_database_size('MyDatabase'));
```

### Пользователи

```sql
-- Список пользователей
\du

-- Создать пользователя
CREATE USER myuser WITH PASSWORD 'mypassword';

-- Дать права
GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;

-- Изменить пароль
ALTER USER myuser WITH PASSWORD 'newpassword';
```

### Таблицы и данные

```sql
-- Список таблиц
\dt

-- Описание таблицы
\d table_name

-- Количество записей
SELECT COUNT(*) FROM table_name;

-- Экспорт в SQL
\o backup.sql
-- ... ваши команды ...
\o

-- Импорт из SQL
\i backup.sql
```

### pg_dump / pg_restore

```powershell
# Бэкап базы
docker exec postgres-1c pg_dump -U postgres MyDatabase > backup.sql

# Бэкап в сжатом формате
docker exec postgres-1c pg_dump -U postgres -Fc MyDatabase > backup.dump

# Восстановление
cat backup.sql | docker exec -i postgres-1c psql -U postgres

# Восстановление из dump
docker exec -i postgres-1c pg_restore -U postgres -d MyDatabase < backup.dump
```

[🔝 Наверх](#-шпаргалка-по-командам)

---

<a name="prometheus-queries"></a>
## 📊 Prometheus Queries

### Базовые метрики

```promql
# Статус всех сервисов (1 = up, 0 = down)
up

# Статус PostgreSQL
pg_up

# Количество контейнеров
count(container_last_seen{name!=""})

# CPU использование (проценты, 5 мин среднее)
rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100

# RAM использование (MB)
container_memory_usage_bytes{name!=""} / 1000000

# RAM использование (проценты)
container_memory_usage_bytes{name!=""} / 1000000000 * 100
```

### Blackbox HTTP-проверки

```promql
# Доступность по HTTP (1 = success)
probe_success{job="blackbox-http"}

# Время ответа (секунды)
probe_duration_seconds{job="blackbox-http"}

# Статус код
probe_http_status_code{job="blackbox-http"}
```

### Алерты

```promql
# Счётчик firing алертов
count(ALERTS{alertstate="firing"}) or vector(0)

# Список активных алертов
ALERTS{alertstate="firing"}

# Алерты по имени
ALERTS{alertname="PostgreSQL_is_DOWN", alertstate="firing"}
```

### PostgreSQL метрики

```promql
# Количество подключений
pg_stat_activity_count

# Размер базы (байты)
pg_database_size_bytes{datname="template1c"}

# Транзакции в секунду
rate(pg_stat_database_xact_commit[5m])

# Блокировки
pg_locks_count
```

[🔝 Наверх](#-шпаргалка-по-командам)

---

<a name="grafana"></a>
## 📈 Grafana

### URL для быстрого доступа

```
# Дашборды
http://localhost:3002/dashboards

# Алерты
http://localhost:3002/alerting/list

# Уведомления
http://localhost:3002/alerting/notifications

# Data sources
http://localhost:3002/connections/datasources

# Пользователи
http://localhost:3002/admin/users
```

### Полезные запросы для панелей

```promql
# CPU по контейнерам (график)
sum by (name) (rate(container_cpu_usage_seconds_total{name!=""}[5m])) * 100

# RAM по контейнерам (столбцы)
sort_desc(sum by (name) (container_memory_usage_bytes{name!=""}) / 1000000)

# Статус сервисов (статус-индикаторы)
up{job=~"postgres|prometheus|grafana"}

# HTTP доступность (таблица)
probe_success{job="blackbox-http"}
```

[🔝 Наверх](#-шпаргалка-по-командам)

---

<a name="диагностика"></a>
## 🔍 Диагностика

### Быстрые проверки

```powershell
# Все сервисы UP?
docker-compose ps

# PostgreSQL healthy?
docker-compose ps postgres

# Prometheus видит targets?
# → http://localhost:9090/targets

# Алерты в Grafana?
# → http://localhost:3002/alerting/list

# VoceChat получает уведомления?
# → http://localhost:3001
```

### Если сервис не запускается

```powershell
# 1. Проверить логи
docker-compose logs <service> --tail 100

# 2. Проверить переменные окружения
cat .env

# 3. Проверить порты
netstat -ano | findstr ":<port>"

# 4. Пересоздать контейнер
docker-compose up -d --force-recreate <service>

# 5. Проверить volume
docker volume inspect <volume_name>
```

### Если алерты не срабатывают

```powershell
# 1. Проверить Prometheus targets
#    http://localhost:9090/targets

# 2. Проверить queries в Grafana
#    Explore → вставить query → Run

# 3. Проверить Contact Point
#    http://localhost:3002/alerting/notifications

# 4. Проверить логи Grafana
docker-compose logs grafana --tail 50
```

### Если уведомления не приходят

```powershell
# 1. Проверить VoceChat
#    http://localhost:3001

# 2. Проверить webhook в Grafana
#    Alerting → Contact points → VoceChat → Test

# 3. Проверить шаблоны
#    Alerting → Notification templates

# 4. Проверить Content-Type
#    Должен быть text/plain, не application/json
```

[🔝 Наверх](#-шпаргалка-по-командам)

---

<a name="бэкапы"></a>
## 💾 Бэкапы

### Конфигурации

```powershell
# Запустить скрипт бэкапа
.\Scripts\backup-configs.ps1

# Бэкапы сохраняются в:
# E:\_BACKUPS\yyyy-MM-dd-stable\
# E:\1C_Infrastructure\Backups\yyyy-MM-dd-stable\
```

### Базы данных (ручной способ)

```powershell
# Бэкап
docker exec postgres-1c pg_dump -U postgres template1c > backup.sql

# Восстановление
cat backup.sql | docker exec -i postgres-1c psql -U postgres
```

### Volumes

```powershell
# Бэкап volume
docker run --rm `
  -v 1c-infrastructure_postgres-data:/source `
  -v E:\_BACKUPS:/backup `
  alpine tar -czf /backup/postgres-backup-$(Get-Date -Format 'yyyy-MM-dd').tar.gz -C /source .

# Восстановление
docker run --rm `
  -v 1c-infrastructure_postgres-data:/target `
  -v E:\_BACKUPS:/backup `
  alpine tar -xzf /backup/postgres-backup-2026-04-04.tar.gz -C /target
```

### Обновлятор 1С (автоматический)

- Запускается через Планировщик заданий Windows
- Путь к архивам: `E:\DEV_LOCAL\Updater_backups\`
- Настройка: через интерфейс Обновлятора

[🔝 Наверх](#-шпаргалка-по-командам)

---

<a name="быстрые-ссылки"></a>
## 🎯 Быстрые ссылки

| Задача | Команда / Ссылка |
|--------|-----------------|
| Запустить всё | `docker-compose up -d` |
| Остановить всё | `docker-compose down` |
| Логи сервиса | `docker-compose logs <name> --tail 100` |
| Статус сервисов | `docker-compose ps` |
| Grafana дашборд | [http://localhost:3002](http://localhost:3002) |
| Prometheus targets | [http://localhost:9090/targets](http://localhost:9090/targets) |
| pgAdmin | [http://localhost:5050](http://localhost:5050) |
| Portainer | [http://localhost:9000](http://localhost:9000) |
| VoceChat | [http://localhost:3001](http://localhost:3001) |

[🔝 Наверх](#-шпаргалка-по-командам)