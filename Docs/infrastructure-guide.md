# 📘 1C Infrastructure — Подробное руководство

Полное руководство по развёртыванию и настройке инфраструктуры для 1С-разработки.

**Версия:** 2.4 (с мониторингом)  
**Последнее обновление:** 04.04.2026  
**Автор:** Vladimir Bessonov (bessonov_1989@list.ru)

---

## 📋 Содержание

1. [Введение](#введение)
2. [Требования](#требования)
3. [Установка](#установка)
4. [Настройка](#настройка)
5. [Мониторинг](#мониторинг)
6. [Управление сервисами](#управление-сервисами)
7. [Диагностика](#диагностика)
8. [Часто задаваемые вопросы](#часто-задаваемые-вопросы)
9. [Полезные ресурсы](#полезные-ресурсы)

[🔝 Наверх](#содержание)

---

## Введение

Эта инфраструктура предназначена для:

- ✅ Изолированной разработки и тестирования 1С
- ✅ Приближения к продакшен-среде
- ✅ Автоматического мониторинга и уведомлений
- ✅ Упрощения развёртывания через Docker Compose

**Основное оборудование:** Geekom A9 Max (Ryzen AI 9 HX 370, Windows 11 Pro)

**Время развёртывания:** ~30 минут (при наличии готовых конфигов)

[🔝 Наверх](#содержание)

---

## Требования

### Аппаратные

| Компонент | Минимум | Рекомендуется |
|-----------|---------|---------------|
| CPU | 8 ядер | 12+ ядер |
| RAM | 32 ГБ | 64–128 ГБ |
| Disk | 500 ГБ SSD | 1 ТБ NVMe |
| OS | Windows 10/11 Pro | Windows 11 Pro |

### Программные

- ✅ Docker Desktop (последняя версия)
- ✅ Git (для клонирования репозитория)
- ✅ PowerShell (встроен в Windows)
- ✅ Tailscale (для безопасного удалённого доступа)

[🔝 Наверх](#содержание)

---

## Установка

### Шаг 1: Установка Docker Desktop

1. Скачайте с [официального сайта](https://www.docker.com/products/docker-desktop)
2. Установите с настройками по умолчанию
3. Перезагрузите компьютер
4. Запустите Docker Desktop

**Время:** 30 минут  
**Проблем:** нет ✅

[🔝 Наверх](#содержание)

### Шаг 2: Клонирование репозитория

```powershell
# Создайте папку для проекта
mkdir E:\1C_Infrastructure
cd E:\1C_Infrastructure

# Клонируйте репозиторий
git clone <repository-url> .
```

[🔝 Наверх](#содержание)

### Шаг 3: Настройка переменных окружения

```powershell
# Скопируйте пример
copy .env.example .env

# Отредактируйте .env
notepad .env
```

**Обязательно измените:**

```env
DB_PASSWORD=ваш_сложный_пароль
GRAFANA_ADMIN_PASSWORD=ваш_пароль
PGADMIN_PASSWORD=ваш_пароль
```

⚠️ **Важно:** Файл `.env` добавлен в `.gitignore` — не коммитьте его в репозиторий!

[🔝 Наверх](#содержание)

### Шаг 4: Запуск инфраструктуры

```powershell
# Запустите все сервисы
docker-compose up -d

# Проверьте статус
docker-compose ps
```

✅ **Все сервисы должны быть в статусе `Up (healthy)`**

[🔝 Наверх](#содержание)

---

## Настройка

### 🔷 PostgreSQL

**Подключение:**

| Параметр | Значение |
|----------|----------|
| Host | `localhost` |
| Port | `5432` |
| Database | `template1c` (или создайте свою) |
| Username | `postgres` |
| Password | из `.env` |

**Создание базы для 1С:**

```powershell
# Подключитесь к PostgreSQL
docker exec -it postgres-1c psql -U postgres

# Создайте базу для 1С
CREATE DATABASE "DemoHRMCorpDemo_bot";

# Выйдите
\q
```

⚠️ **Критично:** Кластер PostgreSQL должен быть инициализирован с русской локалью (`ru_RU.UTF-8`). Без этого 1С не сможет создавать базы!

**Решение в `entrypoint.sh`:**

```bash
export LANG=ru_RU.UTF-8
export LC_COLLATE=ru_RU.UTF-8
export LC_CTYPE=ru_RU.UTF-8
```

[🔝 Наверх](#содержание)

### 🔷 pgAdmin

1. Откройте [http://localhost:5050](http://localhost:5050)
2. Войдите:
   - **Email:** `admin@admin.com`
   - **Password:** из `.env`
3. Добавьте сервер PostgreSQL:
   - **Host:** `postgres`
   - **Port:** `5432`
   - **Username:** `postgres`
   - **Password:** из `.env`

[🔝 Наверх](#содержание)

### 🔷 Grafana

1. Откройте [http://localhost:3002](http://localhost:3002)
2. Войдите:
   - **Username:** `admin`
   - **Password:** из `.env`
3. Смените пароль при первом входе
4. Дашборд "1C Infrastructure Overview" открывается по умолчанию

**Алерты уже настроены! Проверьте:**

- Список алертов: [http://localhost:3002/alerting/list](http://localhost:3002/alerting/list)
- Contact Points: [http://localhost:3002/alerting/notifications](http://localhost:3002/alerting/notifications)

[🔝 Наверх](#содержание)

### 🔷 Portainer

1. Откройте [http://localhost:9000](http://localhost:9000)
2. Создайте аккаунт при первом входе
3. Подключение к Docker настроено автоматически

[🔝 Наверх](#содержание)

### 🔷 Tailscale VPN

1. Установите Tailscale на сервер и клиентские устройства
2. Войдите под одним аккаунтом
3. Получите IP-адрес устройства (например, `100.74.x.x`)
4. Подключайтесь к сервисам по этому IP

⚠️ **Важно:** Порты `0.0.0.0` в `docker-compose.yml` безопасны **только при использовании VPN**!

[🔝 Наверх](#содержание)

---

## Мониторинг

### 🏗️ Архитектура

```
┌─────────────────┐
│  Сервисы (10)   │
└────────────────┘
         │
    ┌────▼─────┐
    │ Prometheus│ ← Сбор метрик каждые 30 сек
    └────┬─────┘
         │
    ┌────▼─────┐
    │  Grafana │ ← Алерты и дашборды
    └────┬─────┘
         │
    ┌────▼─────┐
    │ VoceChat │ ← Уведомления
    └──────────┘
```

[🔝 Наверх](#содержание)

### 📦 Компоненты мониторинга

| Компонент | Назначение | Порт |
|-----------|------------|------|
| Prometheus | Сбор и хранение метрик (time-series DB) | 9090 |
| cAdvisor | Метрики контейнеров (CPU, RAM) | 8080 |
| postgres-exporter | Метрики PostgreSQL | 9187 |
| Blackbox Exporter | HTTP-проверки доступности | 9115 |
| Grafana | Визуализация, алерты, уведомления | 3002 |

[🔝 Наверх](#содержание)

### 🔔 Алерты

#### Критические (🔴)

| Алерт | Условие | Описание |
|-------|---------|----------|
| PostgreSQL is DOWN | `pg_up == 0` | PostgreSQL недоступен |
| Portainer Down | HTTP проверка не прошла | Portainer недоступен |
| pgAdmin Down | HTTP проверка не прошла | pgAdmin недоступен |
| Grafana is DOWN | HTTP проверка не прошла | Grafana недоступна |
| Prometheus is DOWN | `up{job="prometheus"} == 0` | Prometheus недоступен |
| VoceChat Notifications | HTTP проверка не прошла | VoceChat недоступен |
| cAdvisor is DOWN | `up{job="cadvisor"} == 0` | cAdvisor недоступен |

#### Предупреждения (🟡)

| Алерт | Условие | Описание |
|-------|---------|----------|
| High CPU Usage | CPU > 80% (5 min average) | Высокая загрузка CPU |
| High Memory Usage | RAM > 1 GB | Высокое потребление памяти |

[🔝 Наверх](#содержание)

### 📨 Уведомления

**Куда приходят:**

- ✅ VoceChat (локальный чат)
- 📍 Канал: `#alerts`

**Когда приходят:**

- ⏱️ Через 2 минуты после срабатывания алерта (pending period)
- ✅ При восстановлении сервиса (resolved)

**Пример уведомления (FIRING):**

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

**Пример уведомления (RESOLVED):**

```
✅ RESOLVED ALERTS
━━━━━━━━━━━━━━━━━━━━
🟢 *RESOLVED:*
• pgAdmin Down
  🟠 pgAdmin Down
⏰ Duration: 3 min 45 sec
⏰ Resolved: 11:29:55

━━━━━━━━━━━━━━━━━━━━
📊 Total: 0 firing, 1 resolved
```

[🔝 Наверх](#содержание)

### 🔍 Prometheus Queries

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

# Счётчик firing алертов (для дашборда)
count(ALERTS{alertstate="firing"}) or vector(0)
```

Подробнее: [⚡ COMMANDS.md](COMMANDS.md#-prometheus-queries)

[🔝 Наверх](#содержание)

---

## Управление сервисами

### 🎛️ Основные команды

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

[🔝 Наверх](#содержание)

### 🧪 Тестирование алертов

```powershell
# 1. Остановите сервис (например, pgAdmin)
docker-compose stop pgadmin

# 2. Подождите 2-3 минуты

# 3. Проверьте VoceChat — должно прийти уведомление
#    http://localhost:3001

# 4. Запустите сервис обратно
docker-compose start pgadmin

# 5. Проверьте VoceChat — должно прийти RESOLVED
```

[🔝 Наверх](#содержание)

### 📱 Управление через Portainer

1. Откройте [http://localhost:9000](http://localhost:9000)
2. Перейдите: **Containers**
3. Для каждого контейнера доступны:
   - ✅ **Start** — запустить
   - ⏹️ **Stop** — остановить
   - 🔄 **Restart** — перезапустить
   - 🗑️ **Delete** — удалить (осторожно!)
   - 📋 **Logs** — просмотр логов
   - 💻 **Console** — терминал внутри контейнера

[🔝 Наверх](#содержание)

---

## Диагностика

### 🔴 Сервис не запускается

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

[🔝 Наверх](#содержание)

### 🔴 Алерты не приходят

1. Проверьте статус алертов в Grafana: [http://localhost:3002/alerting/list](http://localhost:3002/alerting/list)
2. Проверьте Contact Point: [http://localhost:3002/alerting/notifications](http://localhost:3002/alerting/notifications)
3. Проверьте шаблоны: [http://localhost:3002/alerting/notifications/templates](http://localhost:3002/alerting/notifications/templates)
4. Проверьте логи Grafana: `docker-compose logs grafana --tail 100`

[🔝 Наверх](#содержание)

### 🔴 Prometheus не видит метрики

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

[🔝 Наверх](#содержание)

### 🔴 Blackbox не проверяет HTTP

```powershell
# 1. Проверьте логи Blackbox
docker-compose logs blackbox-exporter --tail 50

# 2. Проверьте конфигурацию
cat monitoring/blackbox.yml

# 3. Проверьте targets в Prometheus
#    http://localhost:9090/targets
#    Найдите blackbox-http
```

[🔝 Наверх](#содержание)

### 🔴 PostgreSQL не подключается

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

## Часто задаваемые вопросы

### ❓ Как добавить новую базу данных для 1С?

```powershell
docker exec -it postgres-1c psql -U postgres

CREATE DATABASE "YourDatabaseName";
\q
```

[🔝 Наверх](#содержание)

### ❓ Как изменить пароль PostgreSQL?

⚠️ **Внимание:** Это удалит все данные!

```powershell
# 1. Остановите PostgreSQL
docker-compose stop postgres

# 2. Измените POSTGRES_PASSWORD в .env

# 3. Удалите volume (данные удалятся!)
docker volume rm 1c-infrastructure_postgres-data

# 4. Запустите заново
docker-compose up -d postgres
```

[🔝 Наверх](#содержание)

### ❓ Как изменить порты сервисов?

Отредактируйте `docker-compose.yml`:

```yaml
ports:
  - "3003:3002"  # Вместо 3002:3002
```

[🔝 Наверх](#содержание)

### ❓ Как обновить образы Docker?

```powershell
# Скачайте новые образы
docker-compose pull

# Пересоздайте контейнеры
docker-compose up -d --force-recreate
```

[🔝 Наверх](#содержание)

### ❓ Где хранятся данные?

| Сервис | Хранилище |
|--------|-----------|
| PostgreSQL | Docker volume `1c-infrastructure_postgres-data` |
| Grafana | `./grafana-data` |
| Prometheus | `./prometheus-data` |
| pgAdmin | Docker volume `1c-infrastructure_pgadmin-data` |

[🔝 Наверх](#содержание)

### ❓ Как сделать бэкап PostgreSQL?

```powershell
docker exec postgres-1c pg_dump -U postgres template1c > backup.sql
```

**Рекомендация:** Используйте **Обновлятор 1С** (Владимир Милькин, helpme1s.ru) — готовое решение с планировщиком заданий Windows.

[🔝 Наверх](#содержание)

### ❓ Как восстановить PostgreSQL из бэкапа?

```powershell
cat backup.sql | docker exec -i postgres-1c psql -U postgres
```

[🔝 Наверх](#содержание)

### ❓ Как очистить неиспользуемые ресурсы Docker?

```powershell
# Очистить stopped контейнеры
docker container prune

# Очистить unused volumes (осторожно!)
docker volume prune

# Полная очистка
docker system prune -a --volumes
```

[🔝 Наверх](#содержание)

### ❓ Как сделать бэкап конфигураций?

```powershell
# Запустите скрипт бэкапа
.\Scripts\backup-configs.ps1

# Бэкапы сохраняются в:
# E:\_BACKUPS\yyyy-MM-dd-stable\
# E:\1C_Infrastructure\Backups\yyyy-MM-dd-stable\
```

[🔝 Наверх](#содержание)

---

## Полезные ресурсы

### 📚 Официальная документация

- [Docker Documentation](https://docs.docker.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PostgreSQL Documentation](https://postgrespro.ru/docs)
- [1С:Предприятие Documentation](https://users.v8.1c.ru/)
- [Blackbox Exporter](https://github.com/prometheus/blackbox_exporter)

[🔝 Наверх](#содержание)

### 🛠️ Инструменты

- [Tailscale VPN](https://tailscale.com)
- [Portainer](https://docs.portainer.io)
- [Обновлятор 1С](https://helpme1s.ru/obnovlyator-1s-gruppovoe-paketnoe-obnovlenie-vsex-baz-za-odin-raz)

[🔝 Наверх](#содержание)

### 🌐 Ресурсы автора

- **InfoStart:** [Профиль](https://infostart.ru/profile/348559/) — статьи и материалы по 1С
- **ВКонтакте:** [Сообщество](https://vk.com/club230942526) — "Автоматизация бизнес-процессов"
- **Rutube:**
  - [🔧 Автоматизация процессов](https://rutube.ru/plst/889148?r=wd)
  - [💻 Автоматизация разработки в 1С](https://rutube.ru/plst/858490?r=wd)
  - [⚙️ Автоматизация администрирования](https://rutube.ru/plst/1269695?r=wd)
  - [📊 1С:Аналитика](https://rutube.ru/plst/858486?r=wd)
  - [🔐 Безопасность в 1С](https://rutube.ru/plst/858489?r=wd)
- **GitHub:** [1c-home-server](https://github.com/VladimirProgrammist1C/1c-home-server)

[🔝 Наверх](#содержание)

### 📄 Документация проекта

| Файл | Описание |
|------|----------|
| [📘 infrastructure-guide.md](infrastructure-guide.md) | Полное руководство (этот файл) |
| [⚡ COMMANDS.md](COMMANDS.md) | Шпаргалка по командам |
| [🏠 README.md](../README.md) | Быстрый старт |

> 💡 **Полная история проекта** (тайминг, проблемы, инсайты, статистика):  
> Опубликована в статье на InfoStart:  
> 🔗 *[DevOps для 1С на практике: как я развёртывал домашний сервер за 14 дней и 32 часа](ссылка-на-статью)*

[🔝 Наверх](#содержание)

---

## 📝 Changelog

### 2026-04-03 (v2.4)

- ✅ Добавлен мониторинг (Grafana + Prometheus)
- ✅ Добавлен Blackbox Exporter для HTTP-проверок
- ✅ Добавлен postgres-exporter для метрик PostgreSQL
- ✅ Настроены алерты с уведомлениями в VoceChat
- ✅ Обновлена документация

### 2026-03-30 (v2.3)

- ✅ Tailscale VPN для безопасного удалённого доступа
- ✅ Финальный docker-compose.yml с оркестрацией
- ✅ Подключение 1С:Предприятие к PostgreSQL в Docker

### 2026-03-27 (v2.2)

- ✅ Финализация СУБД (PostgreSQL + Portainer + pgAdmin)
- ✅ Healthcheck для PostgreSQL
- ✅ Именованные volumes для переносимости

[🔝 Наверх](#содержание)

---

## 📞 Поддержка

При возникновении проблем:

1. Проверьте [⚡ COMMANDS.md](COMMANDS.md) — шпаргалка по командам
2. Изучите раздел [Диагностика](#диагностика)
3. Проверьте логи сервисов
4. Проверьте статус алертов в Grafana

[🔝 Наверх](#содержание)