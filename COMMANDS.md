# 📋 1C Infrastructure - Шпаргалка по командам

## 🔌 Управление сервисами

### Все сервисы

```powershell
# Запустить все
docker-compose up -d

# Остановить все
docker-compose down

# Перезапустить все
docker-compose restart

# Просмотр логов всех сервисов
docker-compose logs --tail 100

# Статус всех сервисов
docker-compose ps
```

### PostgreSQL (СУБД)

```powershell
# Остановить
docker-compose stop postgres

# Запустить
docker-compose start postgres

# Перезапустить
docker-compose restart postgres

# Просмотр логов
docker-compose logs postgres --tail 50

# Подключиться к БД
docker exec -it postgres-1c psql -U postgres -d template1c

# Проверить список БД
docker exec -it postgres-1c psql -U postgres -c "\l"
```

### pgAdmin (веб-интерфейс PostgreSQL)

```powershell
# Остановить
docker-compose stop pgadmin

# Запустить
docker-compose start pgadmin

# Перезапустить
docker-compose restart pgadmin

# Просмотр логов
docker-compose logs pgadmin --tail 50
```

### Prometheus (сбор метрик)

```powershell
# Остановить
docker-compose stop prometheus

# Запустить
docker-compose start prometheus

# Перезапустить
docker-compose restart prometheus

# Просмотр логов
docker-compose logs prometheus --tail 50
```

### Grafana (дашборды и алерты)

```powershell
# Остановить
docker-compose stop grafana

# Запустить
docker-compose start grafana

# Перезапустить
docker-compose restart grafana

# Просмотр логов
docker-compose logs grafana --tail 50
```

### Blackbox Exporter (HTTP проверки)

```powershell
# Перезапустить
docker-compose restart blackbox-exporter

# Просмотр логов
docker-compose logs blackbox-exporter --tail 50
```

### cAdvisor (мониторинг контейнеров)

```powershell
# Перезапустить
docker-compose restart cadvisor

# Просмотр логов
docker-compose logs cadvisor --tail 50
```

### VoceChat Notifications

```powershell
# Перезапустить
docker-compose restart vocechat-notifications

# Просмотр логов
docker-compose logs vocechat-notifications --tail 50
```

---

## 🔗 Полезные URL

| Сервис | URL | Логин/Пароль |
|--------|-----|--------------|
| **Grafana** | http://localhost:3002 | admin / GrafanaMe123! |
| **Prometheus** | http://localhost:9090 | - |
| **pgAdmin** | http://localhost:5050 | admin / admin |
| **Portainer** | http://localhost:9000 | admin / (из .env) |
| **cAdvisor** | http://localhost:8080 | - |
| **VoceChat** | http://localhost:3001 | - |
| **Blackbox Exporter** | http://localhost:9115 | - |

---

## 📊 Prometheus Queries

### Проверка доступности сервисов

```promql
# Все сервисы
up

# PostgreSQL
pg_up

# Конкретный сервис
up{job="prometheus"}
up{job="cadvisor"}
up{job="postgres-exporter"}

# HTTP доступность (Blackbox)
probe_success{job="blackbox-http"}

# Конкретный HTTP endpoint
probe_success{instance="http://grafana:3000/api/health"}
probe_success{instance="http://pgadmin4:80"}
probe_success{instance="http://portainer:9000"}
```

### Метрики контейнеров (cAdvisor)

```promql
# CPU использование (в процентах)
rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100

# Использование памяти (в байтах)
container_memory_usage_bytes{name!=""}

# Использование памяти (в MB)
container_memory_usage_bytes{name!=""} / 1000000

# Last seen контейнера (проверка активности)
container_last_seen{name="grafana"}
```

### Метрики PostgreSQL

```promql
# Версия PostgreSQL
pg_static

# Количество транзакций
pg_stat_database_xact_commit

# Размер БД
pg_database_size_bytes
```

---

## 🚨 Алерты

### Список алертов

| Алерт | Query | Порог | Описание |
|-------|-------|-------|----------|
| **PostgreSQL is DOWN** | `pg_up` | `IS EQUAL TO 0` | PostgreSQL недоступен |
| **Portainer Down** | `probe_success{instance="http://portainer:9000"}` | `IS BELOW 1` | Portainer недоступен |
| **pgAdmin Down** | `probe_success{instance="http://pgadmin4:80"}` | `IS BELOW 1` | pgAdmin недоступен |
| **Grafana is DOWN** | `probe_success{instance="http://grafana:3000/api/health"}` | `IS BELOW 1` | Grafana недоступна |
| **Prometheus is DOWN** | `up{job="prometheus"}` | `IS BELOW 1` | Prometheus недоступен |
| **VoceChat Notifications** | `probe_success{instance="http://vocechat-notifications:3000"}` | `IS BELOW 1` | VoceChat недоступен |
| **cAdvisor is DOWN** | `up{job="cadvisor"}` | `IS BELOW 1` | cAdvisor недоступен |
| **High CPU Usage** | `rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100` | `IS ABOVE 80` | CPU > 80% |
| **High Memory Usage** | `container_memory_usage_bytes{name!=""}` | `IS ABOVE 1000000000` | RAM > 1GB |
| **High Disk Usage** | - | - | ⚠️ Не работает на Docker Desktop |

### Тестирование алертов

```powershell
# Остановить сервис → подождать 2-3 минуты → проверить VoceChat
docker-compose stop pgadmin

# Запустить обратно
docker-compose start pgadmin
```

---

## 🐛 Диагностика

### Проверка логов

```powershell
# Логи конкретного сервиса
docker-compose logs <service_name> --tail 100 -f

# Логи за последние 10 минут
docker-compose logs <service_name> --since 10m
```

### Проверка сети

```powershell
# Проверить network
docker network ls
docker network inspect 1c-infrastructure_1c-infrastructure

# Проверить DNS resolution
docker exec prometheus nslookup postgres
docker exec prometheus nslookup grafana
```

### Проверка volumes

```powershell
# Список volumes
docker volume ls

# Инспекция volume
docker volume inspect 1c-infrastructure_postgres-data
```

---

## 🔧 Конфигурация

### Основные файлы

| Файл | Путь |
|------|------|
| **docker-compose.yml** | `E:\1C_Infrastructure\docker-compose.yml` |
| **Prometheus config** | `E:\1C_Infrastructure\monitoring\prometheus.yml` |
| **Blackbox config** | `E:\1C_Infrastructure\monitoring\blackbox.yml` |
| **Environment** | `E:\1C_Infrastructure\.env` |
| **Grafana templates** | `E:\1C_Infrastructure\grafana\provisioning\alerting\` |

### Перезагрузка конфигурации

```powershell
# Prometheus (после изменения prometheus.yml)
docker-compose restart prometheus

# Grafana (после изменения алертов)
docker-compose restart grafana

# Blackbox (после изменения blackbox.yml)
docker-compose restart blackbox-exporter
```

---

## 📝 Полезные команды Docker

```powershell
# Очистка stopped контейнеров
docker container prune

# Очистка unused volumes
docker volume prune

# Очистка unused networks
docker network prune

# Просмотр использования диска
docker system df

# Полная очистка (осторожно!)
docker system prune -a --volumes
```

---

## 🔐 Переменные окружения

Основные пароли хранятся в `.env`

---

## 📞 Поддержка

При проблемах:
1. Проверить логи: `docker-compose logs --tail 100`
2. Проверить статус: `docker-compose ps`
3. Перезапустить сервис: `docker-compose restart <service>`
4. Проверить алерты: http://localhost:3002/alerting/list
5. Проверить Prometheus targets: http://localhost:9090/targets