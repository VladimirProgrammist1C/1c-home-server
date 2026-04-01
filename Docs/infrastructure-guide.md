# 🔧 Руководство по развёртыванию инфраструктуры 1С

**Версия:** 2.3  
**Дата:** 01 апреля 2026  
**Оборудование:** Geekom A9 Max (Ryzen AI 9 HX 370, 32 ГБ ОЗУ)  
**Статус:** ✅ Инфраструктура СУБД + 1С:Предприятие + Агент сервера 1С + Обновлятор готовы к работе

---

## 📊 Что РЕАЛЬНО сделано (актуальный статус)

| Этап | Задача | Статус | Дата |
|------|--------|--------|------|
| 1 | Docker-инфраструктура (PostgreSQL + Portainer + pgAdmin) | ✅ Готово | 27.03.2026 |
| 2 | Git-репозиторий с документацией | ✅ Готово | 29.03.2026 |
| 3 | README.md + документация | ✅ Готово | 29.03.2026 |
| 4 | TIMING.md (учёт времени) | ✅ Готово | 29.03.2026 |
| 5 | SUMMARY.md (ретроспектива) | ✅ Готово | 30.03.2026 |
| 6 | Tailscale VPN + удалённый доступ | ✅ Готово | 30.03.2026 |
| 7 | docker-compose.yml (оркестрация) | ✅ Готово | 30.03.2026 |
| 8 | GitHub 2FA (двухфакторная аутентификация) | ✅ Готово | 26.03.2026 |
| 9 | 1С:Предприятие на хосте | ✅ Готово | 30.03.2026 |
| 10 | Подключение 1С к PostgreSQL в Docker | ✅ Готово | 30.03.2026 |
| 11 | Первая база (DemoHRMCorpDemo_bot) | ✅ Готово | 30.03.2026 |
| 12 | Агент сервера 1С | ✅ Готово | 31.03.2026 |
| 13 | Обновлятор 1С (бэкапы) | ✅ Готово | 01.04.2026 |

---

## 🏗️ Текущая архитектура

```
┌─────────────────────────────────────────────────────────┐
│  🪟 Windows 11 Pro (Geekom A9 Max)                      │
│  IP: 192.168.0.136 | Tailscale: 100.74.x.x              │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ✅ DOCKER-ИНФРАСТРУКТУРА (WSL2):                       │
│  ├─ 🐳 PostgreSQL 18.1-2.1C :5432 (ru_RU.UTF-8)        │
│  ├─ 🐳 Portainer         :9000                          │
│  └─ 🐳 pgAdmin           :5050                          │
│                                                         │
│  ✅ 1С:ПРЕДПРИЯТИЕ (на хосте):                          │
│  ├─ Платформа 8.5.1.1150 (Windows)                      │
│  ├─ Прямое подключение к PostgreSQL                     │
│  ├─ Агент сервера 1С (порт 1540/1541)                   │
│  └─ Лицензия: developer.1c.ru (привязана к железу)      │
│                                                         │
│  ✅ ОБНОВЛЯТОР 1С (на хосте):                           │
│  ├─ GUI-приложение от Владимира Милькина                │
│  ├─ Бэкапы: E:\DEV_LOCAL\Updater_backups\               │
│  ├─ Скорость: ~1 ГБ/мин (1009.92 МБ за 1 мин 18 сек)    │
│  └─ Хранение: 2 последние копии                         │
│                                                         │
│  ✅ УДАЛЁННЫЙ ДОСТУП (Tailscale):                       │
│  ├─ RDP → хост (основной сценарий)                      │
│  ├─ Веб: 100.74.x.x:9000 (Portainer)                    │
│  └─ Веб: 100.74.x.x:5050 (pgAdmin)                      │
│                                                         │
│  ✅ ДОКУМЕНТАЦИЯ:                                       │
│  ├─ README.md                                           │
│  ├─ Docs/TIMING.md                                      │
│  ├─ Docs/SUMMARY.md                                     │
│  └─ Docs/INFRASTRUCTURE-GUIDE.md                        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Структура проекта (актуальная)

```
E:\1C_Infrastructure\
├── .env                      # ✅ Пароли (НЕ КОММИТИТЬ!)
├── .env.example              # ✅ Шаблон
├── .gitignore                # ✅ Исключения
├── docker-compose.yml        # ✅ Оркестрация (PostgreSQL + Portainer + pgAdmin)
├── README.md                 # ✅ Основная документация
├── Docs/
│   ├── INFRASTRUCTURE-GUIDE.md  # ✅ Это руководство
│   ├── TIMING.md                # ✅ Детальный учёт времени
│   └── SUMMARY.md               # ✅ Ретроспектива проекта
└── docker/
    └── postgres-1c/
        ├── Dockerfile            # ✅ Сборка образа PostgreSQL 1С
        ├── entrypoint.sh         # ✅ Инициализация БД с русской локалью
        └── postgresql_*.tar.bz2  # ⚠️ Дистрибутив 1С (НЕ КОММИТИТЬ!)
```

---

## 🚀 Как развёрнуть (инструкция для нового места)

### Шаг 1: Клонировать репозиторий

```powershell
git clone https://github.com/VladimirProgrammist1C/1c-infrastructure.git
cd E:\1C_Infrastructure
```

### Шаг 2: Настроить переменные окружения

```powershell
Copy-Item .env.example .env
code .env  # Заполнить пароли
```

### Шаг 3: Скачать PostgreSQL 1С

```powershell
# С ИТС: https://releases.1c.ru/project/Platform88
# Файл: postgresql_18.1_2_ubuntu_22.04_x86_64_package.tar.bz2
# Разместить в: .\docker\postgres-1c\
```

### Шаг 4: Собрать образ

```powershell
docker build -t postgres:18.1-2.1C-ubuntu2204 .\docker\postgres-1c\ --no-cache
```

### Шаг 5: Запустить сервисы

```powershell
docker-compose up -d
```

### Шаг 6: Проверить

```powershell
docker-compose ps
# Должно быть:
# postgres-1c   Up (healthy)
# portainer     Up
# pgadmin4      Up
```

### Шаг 7: Настроить Tailscale (удалённый доступ)

```powershell
# Установить Tailscale
winget install Tailscale.Tailscale

# Авторизоваться
tailscale up

# Узнать IP
tailscale ip
# Пример: 100.74.115.111

# Проверить доступность портов
netstat -an | findstr ":9000 :5050"
# Должно быть: 0.0.0.0:9000, 0.0.0.0:5050
```

**Доступ через Tailscale:**
- Portainer: `http://100.74.x.x:9000`
- pgAdmin: `http://100.74.x.x:5050`

### Шаг 8: Настроить Portainer (первый вход)

1. Открыть: `http://localhost:9000` (или через Tailscale)
2. Создать пользователя `admin` (пароль ≥12 символов)
3. Выбрать: **Docker Standalone** → **API**
4. **Docker API URL:** `host.docker.internal:2375`
5. **TLS:** выключено
6. **Connect** ✅

> ⚠️ **Важно:** В Docker Desktop должен быть включён TCP API:  
> **Settings** → **General** → ✅ **Expose daemon on tcp://localhost:2375 without TLS**

### Шаг 9: Настроить pgAdmin

1. Открыть: `http://localhost:5050`
2. Войти: `admin@example.com` / пароль из `.env`
3. **Servers** → **Register** → **Server**

**Вкладка General:**
| Поле | Значение |
|------|----------|
| **Name** | `PostgreSQL 1C` |

**Вкладка Connection:**
| Поле | Значение | Важно! |
|------|----------|--------|
| **Host name/address** | `postgres` | ← Имя сервиса из docker-compose! |
| **Port** | `5432` | |
| **Maintenance database** | `template1c` | Или `postgres` |
| **Username** | `postgres` | |
| **Password** | из `.env` | Обычно `ChangeMe123!` |
| **Save password?** | ✅ Поставьте галочку | |

4. **Save** ✅

---

## ⚠️ Важно о локали PostgreSQL для 1С

**Критично:** Для работы 1С:Предприятие с PostgreSQL **требуется русская локаль** (`ru_RU.UTF-8`) в кластере PostgreSQL. Без этого базы не создадутся ни через консоль администрирования, ни через ярлык, ни через Обновлятор!

### Почему это важно?

| Способ создания базы | Требуется ли русская локаль в кластере? |
|---------------------|----------------------------------------|
| Консоль администрирования 1С | ✅ **ДА** (иначе ошибка при создании) |
| Ярлык "Добавить базу" | ✅ **ДА** (иначе ошибка при создании) |
| Обновлятор 1С | ✅ **ДА** (иначе ошибка при создании) |
| Ручное создание через SQL | ✅ **ДА** (с `TEMPLATE=template0`) |

### Решение: Настройка `entrypoint.sh`

Добавьте русскую локаль в `docker/postgres-1c/entrypoint.sh`:

```bash
#!/bin/bash
set -e

# Русская локаль для 1С:Предприятие
export LANG=ru_RU.UTF-8
export LC_COLLATE=ru_RU.UTF-8
export LC_CTYPE=ru_RU.UTF-8

# Остальная инициализация...
exec "$@"
```

### Проверка локали кластера

```sql
-- Посмотреть локаль шаблонов
SELECT datname, datcollate, datctype 
FROM pg_database 
WHERE datname IN ('template0', 'template1');
```

**Ожидаемый результат:**
```
  datname  | datcollate  | datctype  
-----------+-------------+-----------
 template0 | ru_RU.UTF-8 | ru_RU.UTF-8
 template1 | ru_RU.UTF-8 | ru_RU.UTF-8
```

### Если локаль неверная

**Пересоберите контейнер с правильным `entrypoint.sh`:**

```powershell
# Остановить текущий контейнер
docker-compose down -v

# Пересобрать образ
docker build -t postgres:18.1-2.1C-ubuntu2204 ./docker/postgres-1c --no-cache

# Запустить заново
docker-compose up -d
```

---

## 📁 Создание базы данных для 1С с русской локалью

### Шаг 1: Войти в psql

```powershell
docker-compose exec postgres psql -U postgres
```

### Шаг 2: Создать базу с русской локалью (если кластер не настроен)

```sql
CREATE DATABASE "DemoHRMCorpDemo_bot" WITH 
  LC_COLLATE='ru_RU.UTF-8' 
  LC_CTYPE='ru_RU.UTF-8' 
  TEMPLATE=template0 
  ENCODING='UTF8';
```

### Шаг 3: Проверить локаль

```sql
SELECT datname, datcollate, datctype FROM pg_database 
WHERE datname = 'DemoHRMCorpDemo_bot';
```

**Ожидаемый результат:**
```
       datname        | datcollate  | datctype  
----------------------+-------------+-----------
 DemoHRMCorpDemo_bot  | ru_RU.UTF-8 | ru_RU.UTF-8
```

### Шаг 4: Изменить пароль (если нужно)

```sql
ALTER USER postgres WITH PASSWORD '123';
```

### Шаг 5: Выйти

```sql
\q
```

---

## 🔧 Подключение 1С:Предприятие

### В Консоли администрирования 1С:

| Поле | Значение |
|------|----------|
| **Имя** | `DemoHRMCorpDemo_bot` |
| **Сервер баз данных** | `localhost` |
| **Тип СУБД** | `PostgreSQL` |
| **База данных** | `DemoHRMCorpDemo_bot` |
| **Пользователь сервера БД** | `postgres` |
| **Пароль сервера БД** | `123` (или из `.env`) |
| **Язык (Страна)** | `русский (Россия)` ✅ |
| **✓ Создать базу данных...** | `☐` **НЕ СТАВЬТЕ!** |

### Открыть в 1С:Конфигуратор

1. Запустить **1С:Конфигуратор**
2. Выбрать базу: `DemoHRMCorpDemo_bot`
3. **Открыть**

**Готово!** ✅

---

## 🖥️ Агент сервера 1С - настройка и проверка

### Установка 1С:Сервер

1. **Панель управления** → **Программы и компоненты**
2. **1С:Предприятие 8** → **Изменить**
3. Выбрать **"Изменить"** → **Далее**
4. Отметить компоненты:
   - ✅ **Сервер 1С:Предприятия 8**
   - ✅ **Администрирование сервера 1С:Предприятия**
5. **Далее** → **Установить**

### Проверка службы

```powershell
# Проверить состояние службы
Get-Service -Name "1C:Enterprise 8.5 Server Agent*" | 
  Select-Object Name, Status, StartType

# Ожидаемый результат:
# Name                                     Status StartType
# ----                                     ------ ---------
# 1C:Enterprise 8.5 Server Agent (x86-64) Running Automatic
```

### Проверка портов

```powershell
# Проверить порты 1540/1541
netstat -ano | findstr ":1540 :1541"

# Ожидаемый результат:
# TCP    0.0.0.0:1540    0.0.0.0:0    LISTENING
# TCP    0.0.0.0:1541    0.0.0.0:0    LISTENING
```

### Консоль администрирования

**Запуск:**
```
Пуск → 1С Предприятие 8 (x86-64) → Дополнительно → 
Администрирование серверов 1С Предприятия x86-64
```

**Или через MMC:**
```powershell
mmc.exe "E:\DEV_LOCAL\INSTALLED\1cv8\8.5.1.1150\bin\rsadmin.dll"
```

### Проверка многопользовательского режима

1. **Открыть базу в первом окне** (1С:Предприятие)
2. **Открыть базу во втором окне** (другой пользователь)
3. **Проверить в консоли кластера:**
   - Локальный кластер → Сеансы
   - Должно быть: 2 активных сеанса

**✅ Успех:** Оба пользователя работают одновременно!

---

## 🔄 Обновлятор 1С (бэкапы)

### Установка и настройка

1. **Скачать Обновлятор 1С** от Владимира Милькина:  
   https://helpme1s.ru/obnovlyator-1s-gruppovoe-paketnoe-obnovlenie-vsex-baz-za-odin-raz

2. **Установить** (GUI-приложение на .NET Framework)

3. **Настроить подключение к СУБД:**

| Поле | Значение |
|------|----------|
| **Путь к папке bin PostgreSQL** | `E:\DEV_LOCAL\INSTALLED\pgAdmin 4\runtime` |
| **Тип СУБД** | `PostgreSQL` |
| **Адрес для операций** | `localhost` |
| **Адрес для новой базы** | `localhost` |
| **Администратор** | `postgres` |
| **Его пароль** | из `.env` |

4. **Настроить базу для архивации:**

| Поле | Значение |
|------|----------|
| **Имя базы** | `DemoHRMCorpDemo_bot` |
| **Кластер 1С** | `localhost` |
| **Путь к архивам** | `E:\DEV_LOCAL\Updater_backups\` |
| **Хранить копий** | `2` |

### 🔧 Требования к клиентским утилитам PostgreSQL

**💡 Важно:** Для работы Обновлятора 1С с PostgreSQL в Docker требуются клиентские утилиты PostgreSQL (`pg_dump`, `psql`, `pg_restore`).

**Что нужно знать:**

| Компонент | Назначение | Нужно ли устанавливать? |
|-----------|------------|-------------------------|
| **PostgreSQL Server** | Сервер СУБД | ❌ **НЕТ** (уже работает в Docker) |
| **pg_dump, psql, pg_restore** | Консольные утилиты для бэкапов | ✅ **ДА** (требуются Обновлятору) |
| **pgAdmin (GUI)** | Веб-интерфейс для управления | ⚠️ Опционально (не требуется Обновлятору) |

**Рекомендуемый вариант (наш случай):**

При установке **pgAdmin 4 для Windows** в папке `runtime` **автоматически устанавливаются** все необходимые клиентские утилиты PostgreSQL!

```
Путь к утилитам: E:\DEV_LOCAL\INSTALLED\pgAdmin 4\runtime
```

**Что входит в runtime:**
- ✅ `pg_dump.exe` — создание резервных копий
- ✅ `psql.exe` — выполнение SQL-запросов
- ✅ `pg_restore.exe` — восстановление из бэкапа
- ✅ Другие вспомогательные утилиты

**Альтернативный вариант (если pgAdmin не установлен):**

Можно установить **только PostgreSQL Client** (минимальная установка ~50-100 MB):
1. Скачать с [официального сайта](https://www.postgresql.org/download/windows/)
2. При установке выбрать **только "Command Line Tools"**
3. Указать путь к папке `bin` (например: `C:\Program Files\PostgreSQL\18\bin`)

> ⚠️ **Не устанавливайте полный PostgreSQL Server** на хост, если он уже работает в Docker! Это создаст конфликт портов и займёт лишние ресурсы.

### Проверка работы

1. **Запустить архивацию** (кнопка "Архивировать базы")
2. **Проверить отчёт:**
   - ✅ Архив создан
   - ✅ Размер: ~1009.92 МБ
   - ✅ Время: ~1 мин 18 сек
3. **Проверить файл бэкапа:**
   ```
   E:\DEV_LOCAL\Updater_backups\DemoHRMCorpDemo_bot {...}\
   ```

### Автоматизация (встроенный планировщик)

**💡 Важно:** Обновлятор 1С имеет **встроенный механизм регламентных заданий** и автоматически встраивается в Планировщик заданий Windows при настройке расписания через интерфейс программы.

**Настройка расписания:**

1. Откройте Обновлятор 1С
2. Перейдите: **Настройки программы** → **Расписание** (кнопка "Секундочку...")
3. Нажмите **"Добавить задачу"** (кнопка "+")
4. Выберите операцию из списка:
   - **АРХИВАЦИЯ** — создание резервных копий
   - **ОБНОВЛЕНИЕ** — обновление конфигураций
   - **ПРОВЕРКА АРХИВОВ** — проверка целостности бэкапов
   - **ТОЛЬКО СКАЧИВАНИЕ ОБНОВЛЕНИЙ**
   - **ТЕСТИРОВАНИЕ И ИСПРАВЛЕНИЕ**
   - **ЗАПУСК СКРИПТА**
   - **ТОЛЬКО ОБНОВЛЕНИЕ БАЗЫ ДАННЫХ**
   - **ТОЛЬКО УСТАНОВКА ИСПРАВЛЕНИЙ**
   - **СБОР ОТЧЁТОВ ПО ОПЕРАЦИЯМ ЗА ПЕРИОД**
   - **ОЧИСТКА ВРЕМЕННЫХ ФАЙЛОВ**
   - **СКАЧИВАНИЕ ОЗНАКОМИТЕЛЬНЫХ ОБНОВЛЕНИЙ**
   - **УДАЛИТЬ ПОМЕЧЕННЫЕ НА УДАЛЕНИЕ ОБЪЕКТЫ**
   - **ПРОВЕРКА НАСТРОЕК**
   - **ПРОВЕРКА ОБНОВЛЕНИЙ**
   - **СКАЧИВАНИЕ ИСПРАВЛЕНИЙ В КЭШ**
   - **СБОР ИНФОРМАЦИИ О ПОЛЬЗОВАТЕЛЯХ**
   - **ВЫПОЛНЕНИЕ ДЕЙСТВИЙ НАД ПОЛЬЗОВАТЕЛЯМИ**

5. Настройте параметры:
   - **Периодичность:** Однократно, Ежедневно, Еженедельно, Ежемесячно, При входе в систему, Ручной запуск
   - **Дни недели** (для еженедельного)
   - **Время запуска**
   - **Дополнительные параметры** (выполнять с правами админа, экономить ресурсы и т.д.)

6. **Сохраните настройки**

**Проверка в Планировщике Windows:**

```powershell
# Открыть планировщик заданий
taskschd.msc

# Или найти задачи Обновлятора
Get-ScheduledTask | Where-Object {$_.TaskName -like "*1C*" -or $_.TaskName -like "*Updater*"}
```

**Преимущества встроенного планировщика:**
- ✅ Автоматическая регистрация задач при настройке
- ✅ Гибкая настройка расписания через GUI
- ✅ Логирование выполнения в интерфейсе Обновлятора
- ✅ Уведомления о результатах
- ✅ Не требует ручных PowerShell-команд

**📚 Подробная инструкция:**  
https://helpme1s.ru/obnovlyator-1s-kak-nastroit-zapusk-po-raspisaniyu-v3

### Преимущества Обновлятора

| Возможность | Описание |
|-------------|----------|
| **Пакетное обновление** | Все базы за один раз |
| **Архивация** | Полные бэкапы с проверкой |
| **Восстановление** | Из архива в один клик |
| **Работа с хранилищами** | Поддержка конфигураций с хранилищем |
| **Отраслевые решения** | Поддержка нетиповых конфигураций |
| **Отчёты** | Детальные логи каждой операции |
| **Встроенный планировщик** | Автоматизация без ручных скриптов |

---

## 🐳 Оркестрация: docker-compose

### Структура docker-compose.yml

```yaml
services:
  postgres:    # PostgreSQL 1С (СУБД)
  portainer:   # Управление Docker (веб)
  pgadmin:     # Администрирование БД (веб)
```

### Ключевые настройки

| Параметр | Значение | Почему |
|----------|----------|--------|
| `ports: 0.0.0.0:9000` | Все интерфейсы | Доступ через Tailscale |
| `volumes: named` | `postgres-data` | Переносимость, бэкапы |
| `healthcheck` | `pg_isready` | Авто-перезапуск при сбое |
| `restart: unless-stopped` | Авто-старт | После перезагрузки ПК |

### Переменные окружения (.env)

```bash
# Пароли и настройки (НЕ КОММИТИТЬ!)
DB_PASSWORD=ChangeMe123!
PGADMIN_EMAIL=admin@example.com
PGADMIN_PASSWORD=admin
```

**Создание из шаблона:**
```powershell
Copy-Item .env.example .env
code .env  # Заполнить пароли
```

---

## 🔍 Диагностика

```powershell
# Проверить конфигурацию
docker-compose config

# Проверить логи
docker-compose logs postgres --tail 20

# Проверить healthcheck
docker inspect postgres-1c --format='{{.State.Health.Status}}'
# Должно вернуть: healthy

# Проверить локаль базы
docker-compose exec postgres psql -U postgres -c "SELECT datname, datcollate, datctype FROM pg_database;"

# Проверить размер базы
docker-compose exec postgres psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('DemoHRMCorpDemo_bot'));"

# Проверить количество таблиц
docker-compose exec postgres psql -U postgres -d "DemoHRMCorpDemo_bot" -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public';"

# Проверить Агент сервера 1С
Get-Service -Name "1C:Enterprise*Server*" | Select-Object Name, Status
netstat -ano | findstr ":1540 :1541"
```

---

## 🔧 Основные команды

```powershell
# Просмотр логов
docker-compose logs postgres --tail 50
docker-compose logs portainer --tail 50

# Перезапуск
docker-compose restart postgres

# Остановка
docker-compose down

# Остановка с удалением данных (⚠ осторожно!)
docker-compose down -v

# Подключение к PostgreSQL
docker-compose exec postgres psql -U postgres -d template1c

# Проверка версии
docker-compose exec postgres psql -U postgres -c "SELECT version();"

# Статус
docker-compose ps

# Создать бэкап
docker-compose exec postgres pg_dump -U postgres -d "MyBase" -F c -f /tmp/backup.dump
docker-compose cp postgres:/tmp/backup.dump .\backup.dump

# Восстановить из бэкапа
docker cp .\backup.dump postgres-1c:/tmp/backup.dump
docker-compose exec -T postgres pg_restore -U postgres -d "MyBase" /tmp/backup.dump
```

---

## 🔐 Безопасность

### ✅ Что уже сделано:

- [x] Пароли в `.env` (добавлен в `.gitignore`)
- [x] Именованные volumes (не bind mounts)
- [x] Healthcheck для PostgreSQL
- [x] Private GitHub репозиторий
- [x] GitHub 2FA включена
- [x] Tailscale VPN (шифрование WireGuard)
- [x] Доступ только у авторизованных устройств
- [x] Нет открытых портов в публичный интернет
- [x] Обновлятор 1С настроен (автоматические бэкапы)

### ⚠️ Что нужно сделать:

- [ ] Добавить мониторинг (cAdvisor/Grafana)
- [ ] Настроить Tailscale с 2FA (опционально)
- [ ] Включить 2FA на всех связанных аккаунтах
- [ ] Резервное копирование в облако

---

## 🛠️ Устранение проблем

### Portainer не подключается

```powershell
# Проверить TCP API
curl http://localhost:2375/version

# Перезапустить Portainer
docker-compose restart portainer
```

### PostgreSQL не запускается

```powershell
# Посмотреть логи
docker-compose logs postgres

# Пересоздать
docker-compose down -v
docker-compose up -d
```

### Забыли пароль от pgAdmin

```powershell
# Сбросить через docker
docker-compose exec pgadmin4 pgadmin4-cli reset-password admin@example.com
```

### Нет доступа через Tailscale

```powershell
# 1. Проверить Tailscale
tailscale status

# 2. Проверить IP
tailscale ip

# 3. Проверить порты
netstat -an | findstr ":9000 :5050"

# 4. Проверить брандмауэр
# Разрешить порты 9000 и 5050
```

### Ошибка "Порядок сортировки не поддерживается базой данных"

**Решение:** Создавайте базу с русской локалью:

```sql
CREATE DATABASE "MyBase" WITH 
  LC_COLLATE='ru_RU.UTF-8' 
  LC_CTYPE='ru_RU.UTF-8' 
  TEMPLATE=template0 
  ENCODING='UTF8';
```

### Пароль PostgreSQL не меняется после рестарта

**Решение:** Используйте `ALTER USER`:

```sql
ALTER USER postgres WITH PASSWORD '123';
```

### Агент сервера 1С не запускается

```powershell
# Проверить службу
Get-Service -Name "1C:Enterprise*Server*"

# Перезапустить
Restart-Service "1C:Enterprise 8.5 Server Agent" -Force

# Проверить логи
Get-EventLog -LogName Application -Source "1C*" -Newest 20
```

### Консоль администрирования не открывается

**Решение:** Переустановите компонент:
1. Панель управления → Программы и компоненты
2. 1С:Предприятие → Изменить
3. Отметить "Администрирование сервера" → Далее

### Обновлятор 1С не подключается к PostgreSQL

**Решение:**
1. Проверьте путь к `pgAdmin 4\runtime`
2. Убедитесь, что `psql.exe` и `pg_dump.exe` существуют
3. Проверьте пароль пользователя `postgres` (из `.env`)
4. Проверьте, что Docker-контейнер запущен (`docker-compose ps`)

---

## 📈 Планы развития (приоритеты)

### 🔥 Высокий приоритет (эта неделя):

- [x] ~~Установить 1С:Предприятие на хост~~ ✅ **Готово**
- [x] ~~Подключить 1С к PostgreSQL~~ ✅ **Готово**
- [x] ~~Создать первую информационную базу~~ ✅ **Готово**
- [x] ~~Агент сервера 1С~~ ✅ **Готово** (протестирован)
- [x] ~~Обновлятор 1С для бэкапов~~ ✅ **Готово** (01.04.2026)

### ⚡ Средний приоритет (следующая неделя):

- [ ] Терминальный сервер в ВМ (Hyper-V + Windows 11 / Server) (~2 часа)
- [ ] Мониторинг (cAdvisor + Grafana) (~1.5 часа)

### 📝 Низкий приоритет (когда будет время):

- [ ] Статья на Habr/VC с этим таймингом
- [ ] CI/CD для 1С-кода (GitLab CI/GitHub Actions)
- [ ] Резервное копирование в облако

---

## 💡 Полезные ссылки

- 📦 [1С:ИТС releases](https://releases.1c.ru)
- 📚 [PostgreSQL docs](https://postgrespro.ru/docs)
- 🐳 [Docker Desktop](https://www.docker.com/products/docker-desktop)
- 📊 [Portainer docs](https://docs.portainer.io)
- 🔒 [Tailscale](https://tailscale.com)
- 🔐 [GitHub 2FA](https://github.com/settings/security)
- 🦙 [Ollama](https://ollama.com)
- 🔄 [Обновлятор 1С](https://helpme1s.ru/obnovlyator-1s-gruppovoe-paketnoe-obnovlenie-vsex-baz-za-odin-raz)
- 📅 [Настройка расписания в Обновляторе](https://helpme1s.ru/obnovlyator-1s-kak-nastroit-zapusk-po-raspisaniyu-v3)

---

## 👤 Автор и поддержка

**Автор:** Vladimir Bessonov  
**Email:** bessonov_1989@list.ru  
**Репозиторий:** https://github.com/VladimirProgrammist1C/1c-infrastructure  
**Лицензия:** MIT

**Время развёртывания:** ~30 минут (при наличии дистрибутива PostgreSQL 1С)  
**Последнее обновление:** 01 апреля 2026  
**Версия:** 2.3

> 💡 **Совет:** При возникновении проблем смотрите `docker-compose logs <service>` и проверяйте `docker-compose ps`