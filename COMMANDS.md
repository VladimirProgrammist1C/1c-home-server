# 📋 1C Infrastructure — Шпаргалка по командам
<a name="top"></a>

**Версия:** 2.5 (Email + 1C Metrics)  
**Последнее обновление:** 16.04.2026  
**Алертов:** 12/12 работают (9 инфра + 3 бизнес-метрики 1С)  
**Период:** 22.03–16.04.2026 (26 дней)

[🔝 Наверх](#top)

---

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

### Отдельные сервисы
```powershell
# PostgreSQL (СУБД для 1С)
docker-compose stop postgres-1c
docker-compose start postgres-1c
docker-compose restart postgres-1c
docker-compose logs postgres-1c --tail 50

# pgAdmin (веб-интерфейс БД)
docker-compose restart pgadmin
docker-compose logs pgadmin --tail 50

# Portainer (оркестрация)
docker-compose restart portainer
docker-compose logs portainer --tail 50

# Prometheus (сбор метрик)
docker-compose restart prometheus
docker-compose logs prometheus --tail 50

# Grafana (дашборды + алерты)
docker-compose restart grafana
docker-compose logs grafana --tail 50

# Blackbox Exporter (HTTP-проверки)
docker-compose restart blackbox-exporter
docker-compose logs blackbox-exporter --tail 50

# postgres-exporter (метрики СУБД)
docker-compose restart postgres-exporter
docker-compose logs postgres-exporter --tail 50

# cAdvisor (метрики контейнеров)
docker-compose restart cadvisor
docker-compose logs cadvisor --tail 50

# VoceChat-Notify (уведомления)
docker-compose restart vocechat-notify
docker-compose logs vocechat-notify --tail 50
```

[🔝 Наверх](#top)

---

## 🔍 Prometheus Queries

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
probe_success{instance="http://grafana:3002/api/health"}
probe_success{instance="http://pgadmin:5050"}
probe_success{instance="http://portainer:9000"}
```

### Метрики контейнеров
```promql
# CPU использование (в процентах)
rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100

# Использование памяти (в байтах)
container_memory_usage_bytes{name!=""}

# Использование памяти (в МБ)
container_memory_usage_bytes{name!=""} / 1000000

# Last seen контейнера (проверка активности)
container_last_seen{name="grafana"}
```

### PostgreSQL метрики
```promql
# Версия PostgreSQL
pg_static

# Количество транзакций
pg_stat_database_xact_commit

# Размер БД (в байтах)
pg_database_size_bytes

# Статус подключения
pg_up
```

### 📊 Бизнес-метрики 1С
```promql
# Размер базы 1С (ГБ)
onec_database_size_gb_gigabytes{database="DemoHRMCorpDemo_bot"}

# Общее количество подключений к 1С
onec_total_connections

# Активных сессий одного пользователя
onec_user_connections
```

[🔝 Наверх](#top)

---

## 🚨 Алерты (12 правил)

### 🏗️ Инфраструктура (9 правил)
| Алерт | Query | Порог | Описание |
|-------|-------|-------|----------|
| PostgreSQLDown | `pg_up` | `== 0` | Экспортер PostgreSQL не отвечает |
| PortainerDown | `probe_success{job="blackbox-portainer"}` | `== 0` | HTTP проверка Portainer не пройдена |
| pgAdminDown | `probe_success{job="blackbox-pgadmin"}` | `== 0` | HTTP проверка pgAdmin не пройдена |
| GrafanaDown | `probe_success{job="blackbox-grafana"}` | `== 0` | HTTP проверка Grafana не пройдена |
| PrometheusDown | `up{job="prometheus"}` | `== 0` | Сам Prometheus недоступен |
| VoceChatNotifyDown | `probe_success{job="blackbox-vocechat"}` | `== 0` | HTTP проверка VoceChat не пройдена |
| cAdvisorDown | `up{job="cadvisor"}` | `== 0` | Экспортер метрик контейнеров недоступен |
| HighCPUUsage | `rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100` | `> 80` | Загрузка CPU выше 80% (среднее за 5 мин) |
| HighMemoryUsage | `container_memory_usage_bytes{name!=""} / 1000000` | `> 1024` | Потребление RAM контейнером > 1 ГБ |

### 📊 Бизнес-метрики 1С (3 правила)
| Алерт | Query | Порог | Описание |
|-------|-------|-------|----------|
| HighDatabaseSize | `onec_database_size_gb_gigabytes{database="DemoHRMCorpDemo_bot"}` | `> 5` | Размер базы 1С превысил 5 ГБ |
| High1CConnections | `onec_total_connections` | `> 10` | Общее количество подключений к 1С > 10 |
| HighUserConnections | `onec_user_connections` | `> 2` | Активных сессий одного пользователя > 2 |

### Тестирование алертов
```powershell
# Остановить сервис → подождать 2-3 минуты → проверить VoceChat
docker-compose stop pgadmin

# Запустить обратно
docker-compose start pgadmin

# Проверить алерты в Grafana
# → http://localhost:3002/alerting/list
```

[🔝 Наверх](#top)

---

## 📧 Email Fallback

Email используется **только** при падении VoceChat (`VoceChatNotifyDown`).

```powershell
# Проверить настройки SMTP
cat grafana.ini

# Перезапустить Grafana для применения настроек SMTP
docker-compose restart grafana

# Протестировать отправку письма (через Grafana UI)
# → Alerting → Contact points → Email Critical → Test
```

> ⚠️ **Важно:** Файл `grafana.ini` добавлен в `.gitignore` — не коммитьте пароли!

[🔝 Наверх](#top)

---

## 🔧 Диагностика

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

### Очистка (осторожно!)
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

[🔝 Наверх](#top)

---

## 🔐 Переменные окружения

Основные пароли хранятся в `.env`:

```powershell
# Скопировать пример
Copy-Item .env.example .env

# Редактировать
notepad .env

# Проверить, что .env в .gitignore
git check-ignore .env
```

> ⚠️ **Никогда не коммитьте `.env`!**

[🔝 Наверх](#top)

---

## 📁 Основные файлы

| Файл | Путь |
|------|------|
| `docker-compose.yml` | `E:\1C_Infrastructure\docker-compose.yml` |
| `prometheus.yml` | `E:\1C_Infrastructure\monitoring\prometheus.yml` |
| `blackbox.yml` | `E:\1C_Infrastructure\monitoring\blackbox.yml` |
| `alerts.yml` | `E:\1C_Infrastructure\monitoring\prometheus\alerts.yml` |
| `grafana.ini` | `E:\1C_Infrastructure\grafana.ini` |
| `.env` | `E:\1C_Infrastructure\.env` |
| `.gitignore` | `E:\1C_Infrastructure\.gitignore` |

### Перезагрузка конфигурации
```powershell
# Prometheus (после изменения prometheus.yml)
docker-compose restart prometheus

# Grafana (после изменения алертов)
docker-compose restart grafana

# Blackbox (после изменения blackbox.yml)
docker-compose restart blackbox-exporter
```

[🔝 Наверх](#top)

---

## 🔗 Полезные URL

| Сервис | URL | Логин/Пароль |
|--------|-----|--------------|
| Grafana | [http://localhost:3002](http://localhost:3002) | admin / из `.env` |
| Prometheus | [http://localhost:9090](http://localhost:9090) | — |
| pgAdmin | [http://localhost:5050](http://localhost:5050) | admin@local / из `.env` |
| Portainer | [http://localhost:9000](http://localhost:9000) | admin / из `.env` |
| cAdvisor | [http://localhost:8080](http://localhost:8080) | — |
| VoceChat-Notify | [http://localhost:3001](http://localhost:3001) | — |
| Blackbox Exporter | [http://localhost:9115](http://localhost:9115) | — |

[🔝 Наверх](#top)

---

## 📚 Документация проекта

| Файл | Описание |
|------|----------|
| [📘 infrastructure-guide.md](infrastructure-guide.md) | Полное руководство по развёртыванию |
| [🏠 README.md](../README.md) | Быстрый старт (титульная страница) |
| **TIMING.md** | Детальный учёт времени (в `_Private/`) |
| **SUMMARY.md** | Ретроспектива проекта (в `_Private/`) |

> 💡 **Полная история проекта** (тайминг, проблемы, инсайты):  
> Опубликована в статье на InfoStart:  
> 🔗 [DevOps для 1С на практике](https://infostart.ru/1c/articles/2658161/)

[🔝 Наверх](#top)

---

## 📊 Статистика проекта

- **Период:** 22.03–16.04.2026 (26 дней)
- **Общее время:** ~73 часа 20 мин (включая эксперимент с HTTP-сервисом)
- **Публичное время:** ~55 часов (без эксперимента)
- **Сервисов:** 9
- **Алертов:** 12/12 (9 инфра + 3 бизнес-метрики 1С)
- **Статья:** [InfoStart](https://infostart.ru/1c/articles/2658161/)

[🔝 Наверх](#top)

---

## 📞 Поддержка

При проблемах:

1. Проверить логи: `docker-compose logs <service> --tail 100`
2. Проверить статус: `docker-compose ps`
3. Перезапустить сервис: `docker-compose restart <service>`
4. Проверить алерты: [http://localhost:3002/alerting/list](http://localhost:3002/alerting/list)
5. Проверить Prometheus targets: [http://localhost:9090/targets](http://localhost:9090/targets)

[🔝 Наверх](#top)