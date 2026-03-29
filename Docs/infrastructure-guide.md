# 🔧 Руководство по развёртыванию инфраструктуры 1С

**Версия:** 2.0  
**Дата:** 30 марта 2026  
**Оборудование:** Geekom A9 Max (Ryzen AI 9 HX 370, 32 ГБ ОЗУ)  
**Статус:** ✅ Инфраструктура СУБД готова

---

## 📊 Что РЕАЛЬНО сделано (актуальный статус)

| Этап | Задача | Статус | Дата |
|------|--------|--------|------|
| **1** | Docker-инфраструктура (PostgreSQL + Portainer + pgAdmin) | ✅ **Готово** | 27.03.2026 |
| **2** | Git-репозиторий с документацией | ✅ **Готово** | 29.03.2026 |
| **3** | README.md + PDF с page-breaks | ✅ **Готово** | 29.03.2026 |
| **4** | TIMING.md (учёт времени) | ✅ **Готово** | 29.03.2026 |
| **5** | SUMMARY.md (ретроспектива) | ✅ **Готово** | 30.03.2026 |
| **6** | Tailscale VPN + удалённый доступ | ✅ **Готово** | 30.03.2026 |
| **7** | docker-compose.yml (оркестрация) | ✅ **Готово** | 30.03.2026 |
| **8** | GitHub 2FA (двухфакторная аутентификация) | ✅ **Готово** | 26.03.2026 |
| **9** | 1С:Предприятие на хосте | ⏳ **В плане** | - |
| **10** | 1С:Сервер (агент) | ⏳ **В плане** | - |
| **11** | Бэкапы PostgreSQL (Обновлятор 1С) | ⏳ **В плане** | - |

---

## 🏗️ Текущая архитектура

```
┌─────────────────────────────────────────┐
│  🪟 Windows 11 Pro (Geekom A9 Max)      │
│  Tailscale IP: 100.74.x.x               │
├─────────────────────────────────────────┤
│                                         │
│  ✅ DOCKER-ИНФРАСТРУКТУРА (WSL2):      │
│  ├─ 🐳 PostgreSQL 18.1-2.1C :5432      │
│  ├─ 🐳 Portainer         :9000         │
│  └─  pgAdmin           :5050         │
│                                         │
│  ✅ УДАЛЁННЫЙ ДОСТУП (Tailscale):      │
│  ├─ RDP → хост (основной сценарий)     │
│  ├─ Веб: 100.74.x.x:9000 (Portainer)   │
│  └─ Веб: 100.74.x.x:5050 (pgAdmin)     │
│                                         │
│  ✅ ДОКУМЕНТАЦИЯ:                       │
│  ├─ README.md + README.pdf             │
│  ├─ docs/TIMING.md                     │
│  ├─ docs/SUMMARY.md                    │
│  └─ docs/INFRASTRUCTURE-GUIDE.md       │
│                                         │
└─────────────────────────────────────────┘
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
├── docs/
│   ├── INFRASTRUCTURE-GUIDE.md  # ✅ Это руководство
│   ├── TIMING.md                # ✅ Детальный учёт времени
│   └── SUMMARY.md               # ✅ Ретроспектива проекта
└── docker/
    └── postgres-1c/
        ├── Dockerfile            # ✅ Сборка образа PostgreSQL 1С
        ├── entrypoint.sh         # ✅ Инициализация БД
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

### Шаг 3: Скачать PostgreSQL 1C

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
2. Создать пользователя admin (пароль ≥12 символов)
3. Выбрать: **Docker Standalone** → **API**
4. Docker API URL: `host.docker.internal:2375`
5. TLS: **выключено**
6. Connect ✅

> ⚠️ **Важно:** В Docker Desktop должен быть включён TCP API:  
> Settings → General → ✅ Expose daemon on tcp://localhost:2375 without TLS

### Шаг 9: Настроить pgAdmin

1. Открыть: `http://localhost:5050`
2. Войти: admin@example.com / пароль из .env
3. Servers → Register → Server
4. **General:**
   - Name: `PostgreSQL 1C`
5. **Connection:**
   - Host: `postgres` ← имя сервиса из docker-compose!
   - Port: `5432`
   - Maintenance database: `template1c`
   - Username: `postgres`
   - Password: из .env
   - ✅ Save password
6. Save ✅

---

## 🐳 Оркестрация: docker-compose

### Структура docker-compose.yml

```yaml
version: "3.9"
services:
  postgres:    # PostgreSQL 1C (СУБД)
  portainer:   # Управление Docker (веб)
  pgadmin:     # Администрирование БД (веб)
```

### Ключевые настройки

| Параметр | Значение | Почему |
|----------|----------|--------|
| `ports: 0.0.0.0:9000` | Все интерфейсы | Доступ через Tailscale |
| `volumes: named` | postgres-data | Переносимость, бэкапы |
| `healthcheck` | pg_isready | Авто-перезапуск при сбое |
| `restart: unless-stopped` | Авто-старт | После перезагрузки ПК |

### Переменные окружения (.env)

```env
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

### Диагностика

```powershell
# Проверить конфигурацию
docker-compose config

# Проверить логи
docker-compose logs postgres --tail 20

# Проверить healthcheck
docker inspect postgres-1c --format='{{.State.Health.Status}}'
# Должно вернуть: healthy
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
```

---

## 🔐 Безопасность

### ✅ Что уже сделано:

- ✅ Пароли в `.env` (добавлен в `.gitignore`)
- ✅ Именованные volumes (не bind mounts)
- ✅ Healthcheck для PostgreSQL
- ✅ Private GitHub репозиторий
- ✅ GitHub 2FA включена
- ✅ Tailscale VPN (шифрование WireGuard)
- ✅ Доступ только у авторизованных устройств

### ⚠️ Что нужно сделать:

- [ ] Настроить автоматические бэкапы БД (Обновлятор 1С)
- [ ] Добавить мониторинг (cAdvisor/Grafana)
- [ ] Настроить Tailscale с 2FA (опционально)

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

---

## 📈 Планы развития (приоритеты)

### 🔥 Высокий приоритет (эта неделя):

1. **Установить 1С:Предприятие на хост** (~30 мин)
   - Скачать с ИТС: `1C_Enterprise_8.3.25.xxx.exe`
   - Установить: Клиент + Конфигуратор

2. **Подключить 1С к PostgreSQL** (~15 мин)
   - Создать ИБ в Конфигураторе
   - СУБД: PostgreSQL
   - Сервер БД: `localhost`
   - Имя БД: `template1c`

3. **Настроить Обновлятор 1С** (~30 мин)
   - Установить в `E:\1C_Infrastructure\Tools\Updater1C\`
   - Настроить бэкапы PostgreSQL + конфигураций

### ⚡ Средний приоритет (следующая неделя):

4. **1С:Сервер (агент) на хосте** (~2-3 часа)
   - Установить и настроить
   - Подключить лицензию developer.1c.ru

5. **Терминальный сервер в ВМ** (~2 часа)
   - Hyper-V + Windows 11
   - Для удалённой разработки

### 📝 Низкий приоритет (когда будет время):

6. **Мониторинг** (cAdvisor + Grafana)
7. **Статья на Habr/VC** с этим таймингом
8. **CI/CD для 1С-кода**

---

## 💡 Полезные ссылки

- 📦 **1С:ИТС releases:** https://releases.1c.ru
- 📚 **PostgreSQL docs:** https://postgrespro.ru/docs
- 🐳 **Docker Desktop:** https://www.docker.com/products/docker-desktop
- 📊 **Portainer docs:** https://docs.portainer.io
- 🔒 **Tailscale:** https://tailscale.com
- 🔐 **GitHub 2FA:** https://github.com/settings/security

---

## 👤 Автор и поддержка

**Автор:** Vladimir Bessonov (bessonov_1989@list.ru)  
**Репозиторий:** https://github.com/VladimirProgrammist1C/1c-infrastructure  
**Лицензия:** MIT

**Время развёртывания:** ~30 минут (при наличии дистрибутива PostgreSQL 1С)  
**Последнее обновление:** 30 марта 2026  
**Версия:** 2.0

---

> 💡 **Совет:** При возникновении проблем смотрите `docker-compose logs <service>` и проверяйте `docker-compose ps`