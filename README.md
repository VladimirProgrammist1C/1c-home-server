
# 🏠 1C Home Server Infrastructure

Домашний сервер 1С на базе **Geekom A9 Max** (Ryzen AI 9 HX 370, 32 ГБ ОЗУ)

## 📦 Компоненты

- **PostgreSQL 18.1-2.1C** (официальный дистрибутив 1С для 1С:Предприятие)
- **Portainer CE 2.39.1** (управление Docker-контейнерами)
- **pgAdmin 4** (веб-интерфейс для администрирования PostgreSQL)

## 🚀 Быстрый старт

### Требования

- Windows 10/11 Pro
- Docker Desktop с WSL2
- 32+ ГБ ОЗУ (рекомендуется 64 ГБ)
- SSD 500+ ГБ

### Установка

```powershell
# 1. Клонировать репозиторий
git clone https://github.com/USERNAME/1c-infrastructure.git
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

<div style="page-break-before: always;"></div>

## 🔗 Доступ к сервисам

| Сервис | URL | Логин | Пароль |
|--------|-----|-------|--------|
| **PostgreSQL** | `localhost:5432` | postgres | из `.env` |
| **Portainer** | `http://localhost:9000` | admin | из `.env` |
| **pgAdmin** | `http://localhost:5050` | admin@example.com | из `.env` |

## ⚙️ Настройка Portainer

1. Откройте `http://localhost:9000`
2. Создайте пользователя admin (пароль мин. 12 символов)
3. Выберите **Docker Standalone** → **API**
4. **Docker API URL:** `host.docker.internal:2375`
5. **TLS:** выключено
6. Нажмите **Connect**

> ⚠️ **Важно:** В Docker Desktop должен быть включён TCP API (порт 2375):  
> Settings → General → ✅ Expose daemon on tcp://localhost:2375 without TLS

## 📊 Настройка pgAdmin

### Добавление сервера PostgreSQL:

1. Откройте `http://localhost:5050`
2. Войдите (admin@example.com / пароль из `.env`)
3. **Правый клик на Servers** → **Register** → **Server**
4. **Вкладка General:**
   - Name: `PostgreSQL 1C`
5. **Вкладка Connection:**

| Поле | Значение | Важно! |
|------|----------|--------|
| **Host name/address** | `postgres` | ← Имя сервиса из docker-compose.yml! |
| **Port** | `5432` | |
| **Maintenance database** | `template1c` | Или `postgres` |
| **Username** | `postgres` | |
| **Password** | (из `.env`) | Обычно `ChangeMe123!` |
| **Save password?** | ✅ Поставьте галочку | |

6. Нажмите **Save**

**Если всё правильно** — появится зелёный кружок ✅ и сервер подключится!

<div style="page-break-before: always;"></div>

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
```

## 📁 Структура проекта

```
1c-infrastructure/
├── .env                      # Переменные окружения (НЕ КОММИТИТЬ!)
├── .env.example              # Шаблон переменных
├── .gitignore                # Исключения для Git
├── docker-compose.yml        # Оркестрация сервисов
├── README.md                 # Документация
└── docker/
    └── postgres-1c/
        ├── Dockerfile        # Инструкция сборки образа
        ├── entrypoint.sh     # Скрипт инициализации БД
        └── postgresql_*.tar.bz2  # Дистрибутив 1С (НЕ КОММИТИТЬ!)
```

<div style="page-break-before: always;"></div>

## 🔐 Безопасность

- ✅ Пароли хранятся в `.env` (добавлен в `.gitignore`)
- ✅ Использованы именованные volumes (не bind mounts)
- ✅ Healthcheck для PostgreSQL
- ⚠️ TCP API без TLS (только для локальной разработки!)

### Для продакшена:

```yaml
# docker-compose.yml
services:
  postgres:
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}  # Из .env
    # Добавить SSL сертификаты
```

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

<div style="page-break-before: always;"></div>

## 📈 Планы развития

- [ ] Настройка 1С:Сервер в Docker
- [ ] Добавление 1С:Предприятие (веб-клиент)
- [ ] Настройка резервного копирования
- [ ] Мониторинг (Prometheus + Grafana)
- [ ] CI/CD для 1С-кода

## 📄 Лицензия

MIT

## 👤 Автор

Vladimir Bessonov (bessonov_1989@list.ru)

---

**Время развёртывания:** ~30 минут  
**Последнее обновление:** Март 2026

<div style="page-break-before: always;"></div>

## 🎯 Ближайшие шаги (рекомендую):

### 1. Установите 1С:Предприятие на хост (Windows)

```powershell
# Скачайте с ИТС:
# https://releases.1c.ru/project/Platform88
# Файл: 1C_Enterprise_8.3.25.xxx.exe

# Установите:
# ✅ 1С:Предприятие (клиент)
# ✅ 1С:Конфигуратор
```

### 2. Создайте базу 1С на PostgreSQL

1. Запустите **1С:Конфигуратор**
2. **Добавить** → **Создать новую информационную базу**
3. Имя: `dev_1c_base`
4. **На сервере 1С:Предприятия** (пока без сервера — просто файловая)
5. **СУБД:** PostgreSQL
6. **Сервер БД:** `localhost`
7. **Имя БД:** `template1c`
8. **Пользователь БД:** `postgres`
9. **Пароль БД:** `ChangeMe123!`

### 3. Проверьте подключение

```sql
-- В pgAdmin выполните:
SELECT datname FROM pg_database WHERE datname = 'template1c';

-- Должна вернуться ваша база
```

## 💡 Полезные ссылки

- 📦 **1С:ИТС releases:** https://releases.1c.ru
- 📚 **Документация PostgreSQL:** https://postgrespro.ru/docs
- 🐳 **Docker Desktop:** https://www.docker.com/products/docker-desktop
- 📊 **Portainer docs:** https://docs.portainer.io

---

**Готово к работе!** 🎉
