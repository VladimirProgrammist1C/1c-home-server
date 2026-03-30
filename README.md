# 🏠 1C Home Server Infrastructure

Домашний сервер 1С на базе Geekom A9 Max (Ryzen AI 9 HX 370, 32 ГБ ОЗУ, Windows 11 Pro)

**Статус:** ✅ Инфраструктура СУБД готова к работе  
**Версия:** 2.0  
**Последнее обновление:** 30 марта 2026

---

## 📦 Компоненты

| Компонент | Версия | Назначение |
|-----------|--------|------------|
| **PostgreSQL** | 18.1-2.1C (Ubuntu 22.04) | СУБД для 1С:Предприятие |
| **Portainer CE** | latest | Управление Docker-контейнерами |
| **pgAdmin 4** | latest | Веб-интерфейс для PostgreSQL |
| **Tailscale** | latest | VPN для безопасного удалённого доступа |
| **1С:Предприятие** | 8.5.1.1150 | Платформа на хосте (Windows) |

---

## 🚀 Быстрый старт

### Требования

| Требование | Значение |
|------------|----------|
| **ОС** | Windows 10/11 Pro |
| **Docker** | Docker Desktop с WSL2 |
| **ОЗУ** | 32+ ГБ (рекомендуется 64 ГБ) |
| **SSD** | 500+ ГБ |
| **Дистрибутив PostgreSQL 1С** | Скачать с ИТС |

### Установка

```powershell
# 1. Клонировать репозиторий
git clone https://github.com/VladimirProgrammist1C/1c-infrastructure.git
cd 1c-infrastructure

# 2. Создать .env из шаблона
Copy-Item .env.example .env

# 3. Заполнить пароли в .env
code .env

# 4. Скачать PostgreSQL 1C с ИТС
# https://releases.1c.ru/project/Platform88
# Файл: postgresql_18.1_2_ubuntu_22.04_x86_64_package.tar.bz2
# Разместить в: ./docker/postgres-1c/

# 5. Собрать образ PostgreSQL
docker build -t postgres:18.1-2.1C-ubuntu2204 ./docker/postgres-1c --no-cache

# 6. Запустить все сервисы
docker-compose up -d

# 7. Проверить статус
docker-compose ps
```

---

## 🔗 Доступ к сервисам

| Сервис | URL (локально) | URL (Tailscale) | Логин | Пароль |
|--------|----------------|-----------------|-------|--------|
| **PostgreSQL** | `localhost:5432` | `100.74.x.x:5432` | `postgres` | из `.env` |
| **Portainer** | `http://localhost:9000` | `http://100.74.x.x:9000` | `admin` | из `.env` |
| **pgAdmin** | `http://localhost:5050` | `http://100.74.x.x:5050` | `admin@example.com` | из `.env` |

> 💡 **Tailscale IP:** Узнайте через `tailscale ip` на мини-ПК

---

## 🔐 Доступ через Tailscale

Порты настроены на `0.0.0.0` для безопасного доступа извне:

```powershell
# Узнать IP в сети Tailscale
tailscale ip
# Пример: 100.74.115.111

# Доступ к сервисам из любой точки мира:
# - Portainer: http://100.74.115.111:9000
# - pgAdmin: http://100.74.115.111:5050
# - PostgreSQL: 100.74.115.111:5432 (для 1С:Сервер)
```

> ⚠️ **Безопасно**, потому что Tailscale шифрует трафик (WireGuard) и доступ есть только у авторизованных устройств.

---

## ⚙️ Настройка Portainer

1. Откройте `http://localhost:9000` (или через Tailscale)
2. Создайте пользователя `admin` (пароль мин. 12 символов)
3. Выберите **Docker Standalone** → **API**
4. **Docker API URL:** `host.docker.internal:2375`
5. **TLS:** выключено
6. Нажмите **Connect**

> ⚠️ **Важно:** В Docker Desktop должен быть включён TCP API (порт 2375):  
> **Settings** → **General** → ✅ **Expose daemon on tcp://localhost:2375 without TLS**

---

## 📊 Настройка pgAdmin

### Добавление сервера PostgreSQL:

1. Откройте `http://localhost:5050`
2. Войдите (`admin@example.com` / пароль из `.env`)
3. Правый клик на **Servers** → **Register** → **Server**

**Вкладка General:**
| Поле | Значение |
|------|----------|
| **Name** | `PostgreSQL 1C` |

**Вкладка Connection:**
| Поле | Значение | Важно! |
|------|----------|---------|
| **Host name/address** | `postgres` | ← Имя сервиса из docker-compose.yml! |
| **Port** | `5432` | |
| **Maintenance database** | `template1c` | Или `postgres` |
| **Username** | `postgres` | |
| **Password** | (из `.env`) | Обычно `ChangeMe123!` |
| **Save password?** | ✅ Поставьте галочку | |

4. Нажмите **Save**

> ✅ Если всё правильно — появится зелёный кружок и сервер подключится!

---

## 📁 Создание базы данных для 1С с русской локалью

```powershell
# 1. Войти в psql
docker-compose exec postgres psql -U postgres

# 2. Создать базу с русской локалью (ВАЖНО!)
CREATE DATABASE "DemoHRMCorpDemo_bot" WITH 
  LC_COLLATE='ru_RU.UTF-8' 
  LC_CTYPE='ru_RU.UTF-8' 
  TEMPLATE=template0 
  ENCODING='UTF8';

# 3. Проверить локаль
SELECT datname, datcollate, datctype FROM pg_database 
WHERE datname = 'DemoHRMCorpDemo_bot';

# 4. Изменить пароль (если нужно)
ALTER USER postgres WITH PASSWORD '123';

# 5. Выйти
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

---

## 🔧 Основные команды

```powershell
# Просмотр логов
docker-compose logs postgres --tail 50
docker-compose logs portainer --tail 50

# Перезапуск сервисов
docker-compose restart postgres
docker-compose restart

# Остановка
docker-compose down

# Остановка с удалением volumes (⚠️ все данные удалятся!)
docker-compose down -v

# Подключение к PostgreSQL
docker-compose exec postgres psql -U postgres -d template1c

# Проверка версии PostgreSQL
docker-compose exec postgres psql -U postgres -c "SELECT version();"

# Проверка статуса
docker-compose ps

# Проверка локали базы
docker-compose exec postgres psql -U postgres -c "SELECT datname, datcollate, datctype FROM pg_database;"

# Создать бэкап
docker-compose exec postgres pg_dump -U postgres -d "MyBase" -F c -f /tmp/backup.dump
docker-compose cp postgres:/tmp/backup.dump .\backup.dump

# Восстановить из бэкапа
docker cp .\backup.dump postgres-1c:/tmp/backup.dump
docker-compose exec -T postgres pg_restore -U postgres -d "MyBase" /tmp/backup.dump
```

---

## 📁 Структура проекта

```
1c-infrastructure/
├── .env                      # Переменные окружения (НЕ КОММИТИТЬ!)
├── .env.example              # Шаблон переменных
├── .gitignore                # Исключения для Git
├── docker-compose.yml        # Оркестрация сервисов
├── README.md                 # Документация
├── docs/
│   ├── INFRASTRUCTURE-GUIDE.md  # Руководство по развёртыванию
│   ├── TIMING.md                # Учёт времени
│   └── SUMMARY.md               # Ретроспектива проекта
└── docker/
    └── postgres-1c/
        ├── Dockerfile        # Инструкция сборки образа
        ├── entrypoint.sh     # Скрипт инициализации БД
        └── postgresql_*.tar.bz2  # Дистрибутив 1С (НЕ КОММИТИТЬ!)
```

---

## 🔐 Безопасность

### ✅ Что сделано:

- [x] Пароли хранятся в `.env` (добавлен в `.gitignore`)
- [x] Использованы именованные volumes (не bind mounts)
- [x] Healthcheck для PostgreSQL
- [x] Tailscale шифрует весь трафик (WireGuard)
- [x] GitHub 2FA включена
- [x] Private репозиторий

### ⚠️ Важно:

- TCP API без TLS (только для локальной разработки + Tailscale!)
- Не используйте `0.0.0.0` без VPN!

---

## 🛠️ Устранение проблем

### Portainer не подключается к Docker

```powershell
# Проверьте, включён ли TCP API
# Docker Desktop → Settings → General → 
# ✅ Expose daemon on tcp://localhost:2375 without TLS

# Проверьте доступность API
curl http://localhost:2375/version
```

### PostgreSQL не запускается

```powershell
# Посмотрите логи
docker-compose logs postgres

# Пересоздайте контейнер
docker-compose down -v
docker-compose up -d
```

### Ошибки прав доступа

```powershell
# Перезапустите с пересозданием
docker-compose up -d --force-recreate
```

### Нет доступа через Tailscale

```powershell
# 1. Проверьте, что Tailscale запущен
tailscale status

# 2. Проверьте IP
tailscale ip

# 3. Проверьте порты
netstat -an | findstr ":9000 :5050"
# Должно быть: 0.0.0.0:9000, 0.0.0.0:5050

# 4. Проверьте брандмауэр Windows
# Разрешите порты 9000 и 5050 для входящих подключений
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

---

## 📈 Планы развития

### 🔥 Высокий приоритет (эта неделя):

- [x] ~~Установить 1С:Предприятие на хост~~ ✅ **Готово**
- [x] ~~Подключить 1С к PostgreSQL~~ ✅ **Готово**
- [x] ~~Создать первую информационную базу~~ ✅ **Готово**
- [ ] Настроить Обновлятор 1С для бэкапов (~30 мин)

### ⚡ Средний приоритет (следующая неделя):

- [ ] 1С:Сервер (агент) на хосте (~2-3 часа)
  - ✅ **Лицензия developer.1c.ru поддерживает клиент-серверный режим (до 5 подключений)**
  - ✅ **Лицензирование не изменилось** — платформа на хосте, СУБД в Docker не влияет
  - Требуется, если: фоновые задания, несколько разработчиков, продвинутый мониторинг
- [ ] Терминальный сервер в ВМ (Hyper-V + Windows 11) (~2 часа)
- [ ] Мониторинг (cAdvisor + Grafana) (~1.5 часа)

### 📝 Низкий приоритет (когда будет время):

- [ ] Статья на Habr/VC с этим таймингом
- [ ] CI/CD для 1С-кода (GitLab CI/GitHub Actions)
- [ ] Резервное копирование в облако

---

## 📄 Лицензия

**MIT**

---

## 👤 Автор

**Vladimir Bessonov**  
📧 bessonov_1989@list.ru  
🔗 https://github.com/VladimirProgrammist1C/1c-infrastructure

---

**Время развёртывания:** ~30 минут (при наличии дистрибутива PostgreSQL 1С)  
**Последнее обновление:** 30 марта 2026  
**Версия инфраструктуры:** 2.0

---

## 💡 Полезные ссылки

- 📦 [1С:ИТС releases](https://releases.1c.ru)
- 📚 [Документация PostgreSQL](https://postgrespro.ru/docs)
- 🐳 [Docker Desktop](https://www.docker.com/products/docker-desktop)
- 📊 [Portainer docs](https://docs.portainer.io)
- 🔐 [Tailscale](https://tailscale.com)
- 🔐 [GitHub 2FA](https://github.com/settings/security)
- 🦙 [Ollama](https://ollama.com)