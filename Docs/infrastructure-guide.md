# 📘 1C Infrastructure — Подробное руководство
<a name="содержание"></a>

Полное руководство по развёртыванию и настройке инфраструктуры для 1С-разработки.

**Версия:** 2.5 (мониторинг + алерты + уведомления)  
**Последнее обновление:** 16.04.2026  
**Автор:** Vladimir Bessonov (bessonov_1989@list.ru)

---

## 📋 Содержание <a name="-содержание-"></a>
1. [Введение](#-введение-)
2. [Требования](#-требования-)
3. [Установка](#-установка-)
4. [Настройка](#-настройка-)
5. [Мониторинг](#-мониторинг-)
6. [Управление сервисами](#-управление-сервисами-)
7. [Диагностика](#-диагностика-)
8. [Часто задаваемые вопросы](#-часто-задаваемые-вопросы-)
9. [Полезные ресурсы](#-полезные-ресурсы-)
10. [Changelog](#-changelog-)
11. [Поддержка](#-поддержка-)

[🔝 Наверх](#содержание)

---

## Введение <a name="-введение-"></a>

Эта инфраструктура предназначена для:

✅ **Изолированной 1С-разработки** — отдельные контуры dev/test/prod  
✅ **Мониторинга в реальном времени** — Prometheus + Grafana + Blackbox  
✅ **Автоматических уведомлений** — VoceChat + Email fallback  
✅ **Безопасного удалённого доступа** — Tailscale VPN (WireGuard)  
✅ **Автоматических бэкапов** — Обновлятор 1С + pg_dump

> 💡 **Цель:** Максимально приблизить домашнюю среду к продакшену без потери удобства разработки.

**Основное оборудование:** Geekom A9 Max (Ryzen AI 9 HX 370, Windows 11 Pro)  
**Время развёртывания:** ~30 минут (при наличии готовых конфигов)

[🔝 Наверх](#содержание)

---

## Требования <a name="-требования-"></a>

### Аппаратные

| Компонент | Минимум | Рекомендуется |
|-----------|---------|---------------|
| **CPU** | 8 ядер | 12+ ядер (Ryzen AI 9 HX 370) |
| **RAM** | 32 ГБ | 64–128 ГБ |
| **Диск** | 500 ГБ SSD | 1 ТБ NVMe (отдельный том для данных) |
| **Сеть** | 1 Гбит/с | 2.5 Гбит/с + Wi-Fi 6 |
| **ОС** | Windows 10/11 Pro | Windows 11 Pro x64 |

### Программные

| Компонент | Версия | Примечание |
|-----------|--------|------------|
| **Docker Desktop** | 4.25+ | С включённым WSL2 backend |
| **Git** | 2.40+ | Для работы с репозиторием |
| **PowerShell** | 7.0+ | Встроен в Windows 11 |
| **Tailscale** | 1.95+ | Для защищённого доступа |
| **1С:Предприятие** | 8.3.20 (или новее) | Клиент-серверный режим |

[🔝 Наверх](#содержание)

---

## Установка <a name="-установка-"></a>

### Шаг 1: Установка Docker Desktop
```powershell
# 1. Скачайте с официального сайта
#    https://www.docker.com/products/docker-desktop

# 2. Установите с настройками по умолчанию
# 3. Перезагрузите компьютер
# 4. Запустите Docker Desktop

# 5. Проверьте установку
docker --version
docker-compose --version
```
**Время:** 30 минут | **Статус:** ✅

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

### Шаг 3: Настройка переменных окружения (`.env`)
```powershell
# Скопируйте пример
Copy-Item .env.example .env

# Отредактируйте .env
notepad .env
```

**Обязательно измените пароли:**
```env
# ─────────────────────────────────────────────────────────────
# PostgreSQL
# ─────────────────────────────────────────────────────────────
POSTGRES_USER=postgres
POSTGRES_PASSWORD=YourStrongPassword123!
POSTGRES_DB=template1c

# ─────────────────────────────────────────────────────────────
# pgAdmin
# ─────────────────────────────────────────────────────────────
PGADMIN_DEFAULT_EMAIL=admin@local
PGADMIN_DEFAULT_PASSWORD=AdminPass123!

# ─────────────────────────────────────────────────────────────
# Grafana
# ─────────────────────────────────────────────────────────────
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=GrafanaPass123!

# ─────────────────────────────────────────────────────────────
# VoceChat Notify (webhook для уведомлений)
# ─────────────────────────────────────────────────────────────
VOCECHAT_WEBHOOK_URL=http://host.docker.internal:3001/api/webhook/prometheus

# ─────────────────────────────────────────────────────────────
# Email fallback (резервные уведомления при падении VoceChat)
# ─────────────────────────────────────────────────────────────
SMTP_HOST=smtp.yandex.ru
SMTP_PORT=587
SMTP_USER=alerts@yourdomain.ru
SMTP_PASS=AppPassword123!
```

> ⚠️ **Важно:** Файл `.env` добавлен в `.gitignore`. **Никогда не коммитьте его в репозиторий!**

[🔝 Наверх](#содержание)

### Шаг 4: Запуск инфраструктуры
```powershell
# Запустите все сервисы
docker-compose up -d

# Проверьте статус
docker-compose ps
# Все сервисы должны быть "Up (healthy)"
```

### Шаг 5: Проверка доступа
```
🔗 Локально:
├─ Grafana:      http://localhost:3002   (admin / из .env)
├─ Portainer:    http://localhost:9000
├─ pgAdmin:      http://localhost:5050   (admin@local / из .env)
├─ Prometheus:   http://localhost:9090
├─ VoceChat-N:   http://localhost:3001
```

[🔝 Наверх](#содержание)

---

## Настройка <a name="-настройка-"></a>

### 🔷 PostgreSQL

**Подключение:**

| Параметр | Значение |
|----------|----------|
| Host | `localhost` или `postgres` (в Docker) |
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
   - **Email:** `admin@local`
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
4. **Настройка дашборда по умолчанию:**
   - Создайте дашборд "1C Infrastructure Overview"
   - Кликните по **иконке пользователя** (справа вверху) → **Profile** (или перейдите в профиль через левое меню)
   - В разделе **Preferences** найдите поле **Home Dashboard**
   - В выпадающем списке выберите "Dashboards/1C Infrastructure Overview"
   - Нажмите **Save preferences** внизу страницы

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

> 🔐 **Tailscale** обеспечивает **безопасный защищённый доступ** через зашифрованный туннель (WireGuard).  
> 🖥️ **RDP** используется для удалённого подключения, но весь трафик идёт через защищённый туннель Tailscale.

⚠️ **Важно:** Порты `0.0.0.0` в `docker-compose.yml` безопасны **только при использовании VPN**!

[🔝 Наверх](#содержание)

### 🔷 Email-уведомления (grafana.ini)

**Важно:** Для отправки email-уведомлений необходимо создать файл `grafana.ini` в корне проекта.

**Создайте файл `grafana.ini`:**
```ini
[smtp]
enabled = true
host = smtp.your-provider.ru:465
user = alerts@yourdomain.ru
password = YourAppPassword
from_address = alerts@yourdomain.ru
skip_verify = false
```

**Примеры SMTP-настроек для популярных провайдеров:**

| Провайдер | SMTP хост | Порт | TLS |
|-----------|-----------|------|-----|
| **Yandex 360** | `smtp.yandex.ru` | 465 (SSL) / 587 (STARTTLS) | ✅ |
| **Mail.ru** | `smtp.mail.ru` | 465 (SSL) / 587 (STARTTLS) | ✅ |
| **Gmail/Google Workspace** | `smtp.gmail.com` | 465 (SSL) / 587 (STARTTLS) | ✅ |
| **Reg.ru / Timeweb** | `mail.hosting.reg.ru` | 465 (SSL) | ✅ |
| **Beget** | `smtp.beget.com` | 2525 (STARTTLS) | ✅ |

> 💡 **Совет:** Уточните SMTP-настройки у вашего почтового хостинг-провайдера. Обычно это раздел «Почта» → «Настройки» → «SMTP-сервер».

**Перезапустите Grafana:**
```powershell
docker-compose restart grafana
```

> ⚠️ **Важно:** Файл `grafana.ini` добавлен в `.gitignore` — не коммитьте пароли!

[🔝 Наверх](#содержание)

### 🔷 Настройка алертов (Grafana Unified Alerting)

Вся система алертов настраивается **через интерфейс Grafana**. Файлы конфигурации Alertmanager не используются.

#### 📝 Как создать алерт
1. Перейдите: `Alerting` → `Alert rules` → `New alert rule`
2. **Шаг 1 (Query):** Выберите Prometheus и введите PromQL-запрос (см. таблицу ниже)
3. **Шаг 2 (Condition):** Установите порог (например, `IS ABOVE 0`)
4. **Шаг 3 (Labels):** Добавьте `severity: critical` или `severity: warning`
5. **Шаг 4 (Annotations):** Заполните `summary` и `description`
6. **Шаг 5 (Eval):** Интервал проверки (например, `30s`) и `Pending period` (например, `2m`)

#### 📋 Таблица настроек (12 алертов)

Используйте эти запросы при создании алертов в Grafana.

##### 🏗️ Инфраструктура (9 правил)
| Алерт | Критичность | PromQL Запрос (Условие) | Описание |
|-------|-------------|-------------------------|----------|
| PostgreSQLDown | 🔴 Critical | `pg_up == 0` | Экспортер PostgreSQL не отвечает |
| PortainerDown | 🔴 Critical | `probe_success{job="blackbox-portainer"} == 0` | HTTP проверка Portainer не пройдена (200 OK) |
| pgAdminDown | 🔴 Critical | `probe_success{job="blackbox-pgadmin"} == 0` | HTTP проверка pgAdmin не пройдена (401/200) |
| GrafanaDown | 🔴 Critical | `probe_success{job="blackbox-grafana"} == 0` | HTTP проверка Grafana не пройдена |
| PrometheusDown | 🔴 Critical | `up{job="prometheus"} == 0` | Сам Prometheus недоступен |
| VoceChatNotifyDown | 🔴 Critical | `probe_success{job="blackbox-vocechat"} == 0` | HTTP проверка VoceChat не пройдена |
| cAdvisorDown | 🔴 Critical | `up{job="cadvisor"} == 0` | Экспортер метрик контейнеров недоступен |
| HighCPUUsage | 🟡 Warning | `rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100 > 80` | Загрузка CPU выше 80% (среднее за 5 мин) |
| HighMemoryUsage | 🟡 Warning | `container_memory_usage_bytes{name!=""} / 1000000 > 1024` | Потребление RAM контейнером > 1 ГБ |

##### 📊 Бизнес-метрики 1С (3 правила)
| Алерт | Критичность | PromQL Запрос (Условие) | Описание |
|-------|-------------|-------------------------|----------|
| HighDatabaseSize | 🟡 Warning | `onec_database_size_gb_gigabytes{database="имя-вашей-базы"} > 5` | Размер базы 1С превысил 5 ГБ |
| High1CConnections | 🟡 Warning | `onec_total_connections > 10` | Общее количество подключений к 1С > 10 |
| HighUserConnections | 🟡 Warning | `onec_user_connections > 2` | Активных сессий одного пользователя > 2 |

[🔝 Наверх](#содержание)

### 🔷 Настройка шаблонов уведомлений (Grafana)

Шаблоны уведомлений настраиваются **в интерфейсе Grafana** (отдельные `.tmpl` файлы не создаются):

1. Перейдите: `Alerting` → `Contact points` → `Templates`
2. Создайте шаблон `vocechat.message`:
   ```gotmpl
   {{ define "vocechat.message" }}
   {{- if eq .Status "firing" }}🚨 *СРАБОТАЛИ АЛЕРТЫ* 🚨{{- end }}
   {{- if eq .Status "resolved" }}✅ *ВОССТАНОВЛЕНО* ✅{{- end }}
   ━━━━━━━━━━━━━━━━━━━━
   {{- range .Alerts }}
   • {{ .Labels.alertname }}
   {{ .Annotations.description }}
   {{- if .StartsAt }}⏰ {{ .StartsAt | since }}{{- end }}
   {{- end }}
   ━━━━━━━━━━━━━━━━━━━━
   📊 Total: {{ len .Alerts.Firing }} firing, {{ len .Alerts.Resolved }} resolved
   {{ end }}
   ```
3. Привяжите шаблон к Contact Point `VoceChat`.

> 💡 **Важно:** Текст уведомлений формируется из полей `annotations.summary` и `annotations.description`, которые вы задаёте при создании алерта в Grafana UI.

[🔝 Наверх](#содержание)

### 🔷 Email-уведомления (резервный канал)

**Важно:** Email используется **только** как резервный канал для критического случая — падения VoceChat (`VoceChatNotifyDown`).

#### 📋 Что нужно настроить:

**1. SMTP-настройки (grafana.ini)**

Файл `grafana.ini` уже содержит настройки SMTP для отправки писем:

```ini
[smtp]
enabled = true
host = mail.hosting.reg.ru:465
user = grafana-alerts@servicedesk1c.ru
password = MQfk7h4JeA6pq7a
from_address = grafana-alerts@servicedesk1c.ru
skip_verify = false
```

**2. Contact Point в Grafana UI**

1. Откройте: **Alerting** → **Contact points** → **+ Add contact point**
2. **Name:** `Email Critical`
3. **Integration:** `Email`
4. **Addresses:** `bessonov_1989@list.ru` (ваш email)
5. **Optional Email settings** (раскройте):
   - **Template:** выберите существующий `vocechat.simple.message` (или создайте свой)
   - **Subject** (ОБЯЗАТЕЛЬНО!): 
     ```
     [{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] {{ .CommonLabels.alertname }}
     ```
     *Без этой настройки в теме письма будет ТЕЛО уведомления!*
6. **Save & Test**

**3. Маршрутизация (Notification policies)**

1. Откройте: **Alerting** → **Notification policies**
2. Найдите или создайте правило для `alertname = VoceChatNotifyDown`
3. Добавьте `Email Critical` как второй Contact Point (или создайте дочернюю политику)
4. **Group wait:** `30s` (для критичных алертов)
5. **Save**

> ✅ **Логика:** Все алерты идут в VoceChat. **Только** при падении VoceChat (`VoceChatNotifyDown`) уведомление дублируется на email.

[🔝 Наверх](#содержание)

---

## Мониторинг <a name="-мониторинг-"></a>

### 🏗️ Архитектура
```
┌─────────────────┐
│  Сервисы (9)    │
└────────────────
         │
    ┌────▼─────┐
    │ Prometheus│ ← Сбор метрик каждые 30 сек
    └────┬─────
         │
    ┌────▼─────┐
    │  Grafana │ ← Алерты, дашборды, Alertmanager
    └────┬─────┘
         │
    ┌────▼──────┐
    │ VoceChat  │ ← Уведомления (основной канал)
    └───────────┘
         │
    ┌────▼──────┐
    │   Email   │ ← Резервный канал (только при падении VoceChat)
    └───────────┘
```

[🔝 Наверх](#содержание)

### 📦 Компоненты мониторинга

| Компонент | Назначение | Порт |
|-----------|------------|------|
| Prometheus | Сбор и хранение метрик (time-series DB) | 9090 |
| cAdvisor | Метрики контейнеров (CPU, RAM) | 8080 |
| postgres-exporter | Метрики PostgreSQL | 9187 |
| Blackbox Exporter | HTTP-проверки доступности | 9115 |
| Grafana | Визуализация, алерты, уведомления, Alertmanager | 3002 |

[🔝 Наверх](#содержание)

### 🔔 Алерты (Обзор архитектуры)

Здесь приведён список всех активных алертов инфраструктуры. Подробные запросы и инструкции по настройке находятся в разделе [Настройка](#-настройка-).

#### 🏗️ Инфраструктура (9 правил)
| Алерт | Критичность | Назначение |
|-------|-------------|---------|
| PostgreSQLDown | 🔴 Critical | Контроль доступности СУБД |
| PortainerDown | 🔴 Critical | Контроль доступности оркестратора |
| pgAdminDown | 🔴 Critical | Контроль доступности админки БД |
| GrafanaDown | 🔴 Critical | Контроль доступности панели мониторинга |
| PrometheusDown | 🔴 Critical | Контроль доступности сборщика метрик |
| VoceChatNotifyDown | 🔴 Critical | Контроль доступности канала уведомлений |
| cAdvisorDown | 🔴 Critical | Контроль доступности метрик контейнеров |
| HighCPUUsage | 🟡 Warning | Предупреждение о высокой нагрузке CPU |
| HighMemoryUsage | 🟡 Warning | Предупреждение о высоком потреблении RAM |

#### 📊 Бизнес-метрики 1С (3 правила)
| Алерт | Критичность | Назначение |
|-------|-------------|---------|
| HighDatabaseSize | 🟡 Warning | Контроль роста базы данных (лимит 5 ГБ) |
| High1CConnections | 🟡 Warning | Контроль общей нагрузки на сервер 1С |
| HighUserConnections | 🟡 Warning | Контроль аномальной активности пользователя |

[🔝 Наверх](#содержание)

### 📨 Уведомления

| Канал | Назначение | Когда приходит |
|-------|-----------|----------------|
| 💬 **VoceChat-Notify** | Основной канал (`#alerts`) | Все алерты (через 2 мин после срабатывания + при восстановлении) |
| 📧 **Email** | Резервный канал | **Только** при недоступности VoceChat (`VoceChatNotifyDown`) |

**Формат:** читаемый текст на русском с эмодзи и порогами.

[🔝 Наверх](#содержание)

---

## Управление сервисами <a name="-управление-сервисами-"></a>

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

# Пересоздание контейнера (с сохранением volumes)
docker-compose up -d --force-recreate <service_name>
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

**Основные действия (кнопки вверху):**
- ▶️ **Start** — запустить
- ⏹️ **Stop** — остановить
- 💀 **Kill** — принудительно остановить
- 🔄 **Restart** — перезапустить
- ⏸️ **Pause** — приостановить
- ▶️ **Resume** — возобновить
- 🗑️ **Remove** — удалить (осторожно!)

**Быстрые действия (Quick Actions):**
- 📋 **Logs** — просмотр логов
- 💻 **Console** — терминал внутри контейнера
- 📊 **Stats** — статистика ресурсов
- ⚙️ **Inspect** — подробная информация

**Массовые операции:**
- Выделите контейнеры чекбоксами
- Используйте кнопки вверху для групповых действий

[🔝 Наверх](#содержание)

### 🔄 Обновление образов Docker
```powershell
# Скачайте новые образы
docker-compose pull

# Пересоздайте контейнеры
docker-compose up -d --force-recreate
```

[🔝 Наверх](#содержание)

---

## Диагностика <a name="-диагностика-"></a>

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
4. Проверьте Notification policies: [http://localhost:3002/alerting/routes](http://localhost:3002/alerting/routes)
5. Проверьте логи Grafana: `docker-compose logs grafana --tail 100`

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

### 🔴 Уведомления не приходят в VoceChat
```powershell
# 1. Проверьте статус VoceChat-Notify
curl http://localhost:3001/api/health

# 2. Проверьте логи
docker-compose logs vocechat-notify --tail 50

# 3. Протестируйте вебхук вручную
curl -X POST http://localhost:3001/api/webhook/prometheus \
  -H "Content-Type: application/json" \
  -d '{"status":"firing","alerts":[{"labels":{"alertname":"Test"}}]}'
```

[🔝 Наверх](#содержание)

---

## Часто задаваемые вопросы <a name="-часто-задаваемые-вопросы-"></a>

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

### ❓ Как добавить новый алерт?
1. Откройте Grafana: [http://localhost:3002/alerting/list](http://localhost:3002/alerting/list)
2. Нажмите **New alert rule**
3. Настройте Query, Condition, Labels, Annotations
4. Сохраните

[🔝 Наверх](#содержание)

### ❓ Почему порты `0.0.0.0` в docker-compose.yml безопасны?
Потому что доступ возможен **только через Tailscale VPN**. Без подключённого туннеля порты не видны из публичного интернета.

[🔝 Наверх](#содержание)

---

## Полезные ресурсы <a name="-полезные-ресурсы-"></a>

### 📚 Официальная документация
- [1С:ИТС releases](https://releases.1c.ru)
- [PostgreSQL docs](https://postgrespro.ru/docs)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Prometheus](https://prometheus.io)
- [Grafana](https://grafana.com)
- [Blackbox Exporter](https://github.com/prometheus/blackbox_exporter)

[🔝 Наверх](#содержание)

### 🛠️ Инструменты
- [Tailscale VPN](https://tailscale.com)
- [Portainer](https://docs.portainer.io)
- [Обновлятор 1С](https://helpme1s.ru/obnovlyator-1s-gruppovoe-paketnoe-obnovlenie-vsex-baz-za-odin-raz)

[🔝 Наверх](#содержание)

### 🌐 Ресурсы автора
- 📘 [InfoStart профиль](https://infostart.ru/profile/348559/)
- 💬 [ВКонтакте: "Автоматизация бизнес-процессов"](https://vk.com/club230942526)
- 🎥 [Rutube плейлисты](https://rutube.ru/plst/889148?r=wd)
- 🔗 [GitHub репозиторий](https://github.com/VladimirProgrammist1C/1c-home-server)

[🔝 Наверх](#содержание)

### 📄 Документация проекта
| Файл | Описание |
|------|----------|
| [📘 infrastructure-guide.md](infrastructure-guide.md) | Полное руководство (этот файл) |
| [⚡ COMMANDS.md](COMMANDS.md) | Шпаргалка по командам |
| [🏠 README.md](../README.md) | Быстрый старт |

> 💡 **Полная история проекта** (тайминг, проблемы, инсайты, статистика):  
> Опубликована в статье на InfoStart:  
> 🔗 [DevOps для 1С на практике: как я развернул домашний сервер за 14 дней и 32 часа](https://infostart.ru/1c/articles/2658161/)

[🔝 Наверх](#содержание)

---

## 📝 Changelog <a name="-changelog-"></a>

### 2026-04-16 (v2.5)
- ✅ Добавлены 3 бизнес-алерта 1С (размер БД, подключения, сессии)
- ✅ Добавлен email-fallback для уведомлений (только для VoceChatNotifyDown)
- ✅ Обновлены шаблоны уведомлений
- ✅ Актуализировано время разработки: ~50 часов за 26 дней
- ✅ Добавлена инструкция по дашборду по умолчанию
- ✅ Добавлена настройка SMTP через grafana.ini

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

## 📞 Поддержка <a name="-поддержка-"></a>

При возникновении проблем:

1. Проверьте [⚡ COMMANDS.md](COMMANDS.md) — шпаргалка по командам
2. Изучите раздел [Диагностика](#-диагностика-)
3. Проверьте логи сервисов: `docker-compose logs <service> --tail 100`
4. Проверьте статус алертов в Grafana: [http://localhost:3002/alerting/list](http://localhost:3002/alerting/list)
5. Проверьте targets в Prometheus: [http://localhost:9090/targets](http://localhost:9090/targets)

[🔝 Наверх](#содержание)