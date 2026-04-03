# 📘 1C Infrastructure - Подробное руководство

Полное руководство по развёртыванию и настройке инфраструктуры для 1С-разработки.

---

## 📋 <a id="содержание"></a>Содержание

1. [Введение](#введение)
2. [Требования](#требования)
3. [Установка](#установка)
4. [Настройка](#настройка)
5. [Мониторинг](#мониторинг)
6. [Управление сервисами](#управление-сервисами)
7. [Диагностика](#диагностика)
8. [Часто задаваемые вопросы](#часто-задаваемые-вопросы)

[🔝 Наверх](#содержание)

---

## <a id="введение"></a>Введение

Эта инфраструктура предназначена для:
- ✅ Изолированной разработки и тестирования 1С
- ✅ Приближения к продакшен-среде
- ✅ Автоматического мониторинга и уведомлений
- ✅ Упрощения развёртывания через Docker Compose

**Основное оборудование:** Geekom A9 Max (Ryzen AI 9 HX 370, Windows 11 Pro)

[🔝 Наверх](#содержание)

---

## <a id="требования"></a>Требования

### Аппаратные

- **CPU:** 8+ ядер (рекомендуется 12+)
- **RAM:** 32+ ГБ (рекомендуется 64 ГБ)
- **Disk:** 500+ ГБ SSD
- **OS:** Windows 11 Pro / Windows 10 Pro

### Программные

- **Docker Desktop** (последняя версия)
- **Git** (для клонирования репозитория)
- **PowerShell** (встроен в Windows)

[🔝 Наверх](#содержание)

---

## <a id="установка"></a>Установка

### Шаг 1: Установка Docker Desktop

1. Скачайте с [официального сайта](https://www.docker.com/products/docker-desktop)
2. Установите с настройками по умолчанию
3. Перезагрузите компьютер
4. Запустите Docker Desktop

### Шаг 2: Клонирование репозитория

```powershell
# Создайте папку для проекта
mkdir C:\1C_Infrastructure
cd C:\1C_Infrastructure

# Клонируйте репозиторий
git clone <repository-url> .
```

### Шаг 3: Настройка переменных окружения

```powershell
# Скопируйте пример
copy .env.example .env

# Отредактируйте .env
notepad .env
```

**Обязательно измените:**
```bash
DB_PASSWORD=ваш_сложный_пароль
GRAFANA_ADMIN_PASSWORD=ваш_пароль
PGADMIN_PASSWORD=ваш_пароль
```

### Шаг 4: Запуск инфраструктуры

```powershell
# Запустите все сервисы
docker-compose up -d

# Проверьте статус
docker-compose ps
```

**Все сервисы должны быть в статусе `Up (healthy)`**

[🔝 Наверх](#содержание)

---

## <a id="настройка"></a>Настройка

### PostgreSQL

**Подключение:**
- **Host:** localhost
- **Port:** 5432
- **Database:** template1c (или создайте свою)
- **Username:** postgres
- **Password:** из `.env`

**Создание базы для 1С:**

```powershell
# Подключитесь к PostgreSQL
docker exec -it postgres-1c psql -U postgres

# Создайте базу для 1С
CREATE DATABASE "DemoHRMCorpDemo_bot";

# Выйдите
\q
```

### pgAdmin

1. Откройте http://localhost:5050
2. Войдите:
   - **Email:** admin@admin.com
   - **Password:** admin
3. Добавьте сервер PostgreSQL:
   - **Host:** postgres
   - **Port:** 5432
   - **Username:** postgres
   - **Password:** из `.env`

### Grafana

1. Откройте http://localhost:3002
2. Войдите:
   - **Username:** admin
   - **Password:** из `.env`
3. Смените пароль при первом входе

**Алерты уже настроены!** Проверьте:
- Список алертов: http://localhost:3002/alerting/list
- Contact Points: http://localhost:3002/alerting/notifications

[🔝 Наверх](#содержание)

---

## <a id="мониторинг"></a>Мониторинг

### Архитектура

```
┌─────────────────┐
│  Сервисы (10)   │
└────────┬────────┘
         │
    ┌────▼─────┐
    │ Prometheus│ ← Сбор метрик каждые 15-30 сек
    └────┬─────┘
         │
    ┌────▼─────┐
    │  Grafana │ ← Алерты и дашборды
    └────┬─────┘
         │
    ┌────▼─────┐
    │ VoceChat │ ← Уведомления
    └──────────
```

### Компоненты мониторинга

| Компонент | Назначение |
|-----------|------------|
| **Prometheus** | Сбор и хранение метрик (time-series database) |
| **cAdvisor** | Метрики контейнеров (CPU, RAM, network) |
| **postgres-exporter** | Метрики PostgreSQL |
| **Blackbox Exporter** | HTTP-проверки доступности |
| **Grafana** | Визуализация, алерты, уведомления |

### Алерты

#### Критические (🔴)

| Алерт | Условие | Описание |
|-------|---------|----------|
| **PostgreSQL is DOWN** | `pg_up == 0` | PostgreSQL недоступен |
| **Portainer Down** | HTTP проверка не прошла | Portainer недоступен |
| **pgAdmin Down** | HTTP проверка не прошла | pgAdmin недоступен |
| **Grafana is DOWN** | HTTP проверка не прошла | Grafana недоступна |
| **Prometheus is DOWN** | `up{job="prometheus"} < 1` | Prometheus недоступен |
| **VoceChat Notifications** | HTTP проверка не прошла | VoceChat недоступен |
| **cAdvisor is DOWN** | `up{job="cadvisor"} < 1` | cAdvisor недоступен |

#### Предупреждения (🟡)

| Алерт | Условие | Описание |
|-------|---------|----------|
| **High CPU Usage** | CPU > 80% (5 min average) | Высокая загрузка CPU |
| **High Memory Usage** | RAM > 1 GB | Высокое потребление памяти |
| **High Disk Usage** | Disk > 85% | ⚠️ Не работает на Docker Desktop |

### Уведомления

**Куда приходят:**
- VoceChat (локальный чат)
- Канал: `#alerts`

**Когда приходят:**
- Через 2 минуты после срабатывания алерта (pending period)
- При восстановлении сервиса (resolved)

**Пример уведомления:**
```
🚨 FIRING ALERTS
━━━━━━━━━━━━━━━━━━━━
🔴 *FIRING:*
• pgAdmin Down
  🟠 pgAdmin Down
⏰ Started: 11:26:10

━━━━━━━━━━━━━━━━━━━━
📊 Total: 1 firing, 0 resolved
```

### Prometheus Queries

**Полезные запросы:**

```promql
# Статус всех сервисов
up

# Статус PostgreSQL
pg_up

# CPU использование (проценты)
rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100

# RAM использование (MB)
container_memory_usage_bytes{name!=""} / 1000000

# HTTP доступность
probe_success{job="blackbox-http"}

# Количество контейнеров
count(container_last_seen{name!=""})
```

Подробнее в [`COMMANDS.md`](../COMMANDS.md#-prometheus-queries)

[🔝 Наверх](#содержание)

---

## <a id="управление-сервисами"></a>Управление сервисами

### Основные команды

```powershell
# Запустить все
docker-compose up -d

# Остановить все
docker-compose down

# Перезапустить сервис
docker-compose restart <service_name>

# Остановить сервис
docker-compose stop <service_name>

# Запустить сервис
docker-compose start <service_name>

# Просмотр логов
docker-compose logs <service_name> --tail 100

# Статус всех сервисов
docker-compose ps
```

### Тестирование алертов

```powershell
# 1. Остановите сервис
docker-compose stop pgadmin

# 2. Подождите 2-3 минуты

# 3. Проверьте VoceChat - должно прийти уведомление

# 4. Запустите сервис обратно
docker-compose start pgadmin

# 5. Проверьте VoceChat - должно прийти RESOLVED
```

[🔝 Наверх](#содержание)

---

## <a id="диагностика"></a>Диагностика

### Сервис не запускается

```powershell
# 1. Проверьте логи
docker-compose logs <service_name> --tail 100

# 2. Проверьте статус
docker-compose ps

# 3. Пересоздайте контейнер
docker-compose up -d --force-recreate <service_name>

# 4. Проверьте переменные окружения
cat .env
```

### Алерты не приходят

```powershell
# 1. Проверьте статус алертов в Grafana
#    http://localhost:3002/alerting/list

# 2. Проверьте Contact Point
#    http://localhost:3002/alerting/notifications

# 3. Проверьте шаблоны
#    http://localhost:3002/alerting/notifications/templates

# 4. Проверьте логи Grafana
docker-compose logs grafana --tail 100
```

### Prometheus не видит метрики

```powershell
# 1. Проверьте targets
#    http://localhost:9090/targets

# 2. Проверьте конфигурацию Prometheus
cat monitoring/prometheus.yml

# 3. Перезапустите Prometheus
docker-compose restart prometheus

# 4. Проверьте логи Prometheus
docker-compose logs prometheus --tail 50
```

### Blackbox не проверяет HTTP

```powershell
# 1. Проверьте логи Blackbox
docker-compose logs blackbox-exporter --tail 50

# 2. Проверьте конфигурацию
cat monitoring/blackbox.yml

# 3. Проверьте targets в Prometheus
#    http://localhost:9090/targets
#    Найдите blackbox-http
```

### PostgreSQL не подключается

```powershell
# 1. Проверьте статус PostgreSQL
docker-compose ps postgres

# 2. Проверьте логи
docker-compose logs postgres --tail 50

# 3. Проверьте пароль
docker exec -it postgres-1c psql -U postgres -c "SELECT 1"

# 4. Проверьте список БД
docker exec -it postgres-1c psql -U postgres -c "\l"
```

[🔝 Наверх](#содержание)

---

## <a id="часто-задаваемые-вопросы"></a>Часто задаваемые вопросы

### Q: Как добавить новую базу данных для 1С?

```powershell
docker exec -it postgres-1c psql -U postgres

CREATE DATABASE "YourDatabaseName";
\q
```

### Q: Как изменить пароль PostgreSQL?

1. Остановите PostgreSQL:
   ```powershell
   docker-compose stop postgres
   ```

2. Измените `POSTGRES_PASSWORD` в `.env`

3. Удалите volume (данные удалятся!):
   ```powershell
   docker volume rm 1c-infrastructure_postgres-data
   ```

4. Запустите заново:
   ```powershell
   docker-compose up -d postgres
   ```

### Q: Как изменить порты сервисов?

Отредактируйте `docker-compose.yml`:

```yaml
ports:
  - "3003:3002"  # Вместо 3002:3002
```

### Q: Как обновить образы Docker?

```powershell
# Скачайте новые образы
docker-compose pull

# Пересоздайте контейнеры
docker-compose up -d --force-recreate
```

### Q: Где хранятся данные?

- **PostgreSQL:** Docker volume `1c-infrastructure_postgres-data`
- **Grafana:** `./grafana/data`
- **Prometheus:** `./prometheus/data`

### Q: Как сделать бэкап PostgreSQL?

```powershell
docker exec postgres-1c pg_dump -U postgres template1c > backup.sql
```

### Q: Как восстановить PostgreSQL из бэкапа?

```powershell
cat backup.sql | docker exec -i postgres-1c psql -U postgres
```

### Q: Как очистить неиспользуемые ресурсы Docker?

```powershell
# Очистить stopped контейнеры
docker container prune

# Очистить unused volumes (осторожно!)
docker volume prune

# Полная очистка
docker system prune -a --volumes
```

[🔝 Наверх](#содержание)

---

## 📞 Поддержка

При возникновении проблем:

1. Проверьте [`COMMANDS.md`](../COMMANDS.md) - шпаргалка по командам
2. Изучите раздел [Диагностика](#диагностика)
3. Проверьте логи сервисов
4. Проверьте статус алертов в Grafana

[🔝 Наверх](#содержание)

---

## 📝 Changelog

### 2026-04-03
- ✅ Добавлен мониторинг (Grafana + Prometheus)
- ✅ Добавлен Blackbox Exporter для HTTP проверок
- ✅ Добавлен postgres-exporter для метрик PostgreSQL
- ✅ Настроены алерты с уведомлениями в VoceChat
- ✅ Добавлена документация (COMMANDS.md, TIMING.md, SUMMARY.md)

[🔝 Наверх](#содержание)

---

## 🔗 Ссылки

- [Официальная документация Docker](https://docs.docker.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [1С:Предприятие Documentation](https://users.v8.1c.ru/)

[🔝 Наверх](#содержание)