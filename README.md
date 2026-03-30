# 🏠 1C Home Server Infrastructure

**Домашний сервер 1С на базе Geekom A9 Max** (Ryzen AI 9 HX 370, 32 ГБ ОЗУ, Windows 11 Pro)

| Статус | Версия | Обновлено |
|--------|--------|-----------|
| ✅ СУБД + 1С:Предприятие + Агент сервера 1С готовы | 2.2 | 31.03.2026 |

---

## 🚀 Быстрый старт (30 секунд)

```powershell
# 1. Клонировать репозиторий
git clone https://github.com/VladimirProgrammist1C/1c-infrastructure.git
cd 1c-infrastructure

# 2. Настроить переменные окружения
Copy-Item .env.example .env
code .env  # заполнить пароли

# 3. Запустить все сервисы
docker-compose up -d

# 4. Проверить статус
docker-compose ps
```

> ⚠️ **Первый запуск:** Скачать PostgreSQL 1С с [ИТС](https://releases.1c.ru) и собрать образ:
> ```powershell
> docker build -t postgres:18.1-2.1C-ubuntu2204 ./docker/postgres-1c --no-cache
> ```

---

## 🔗 Доступ к сервисам

| Сервис | Локально | Tailscale | Логин | Пароль |
|--------|----------|-----------|-------|--------|
| **PostgreSQL** | `localhost:5432` | `100.74.x.x:5432` | `postgres` | из `.env` |
| **Portainer** | `http://localhost:9000` | `http://100.74.x.x:9000` | `admin` | из `.env` |
| **pgAdmin** | `http://localhost:5050` | `http://100.74.x.x:5050` | `admin@example.com` | из `.env` |
| **Агент сервера 1С** | `localhost` | — | — | — |

> 💡 **Tailscale IP:** `tailscale ip` на мини-ПК  
> ⚠️ **Порты 1540/1541** — внутренние (кластер), клиент 1С подключается просто к `localhost`

---

## 📚 Документация

| Файл | Назначение |
|------|-----------|
| 📖 [`docs/INFRASTRUCTURE-GUIDE.md`](docs/INFRASTRUCTURE-GUIDE.md) | Полное руководство по развёртыванию |
| ⏱️ [`docs/TIMING.md`](docs/TIMING.md) | Детальный учёт времени |
| 📋 [`docs/SUMMARY.md`](docs/SUMMARY.md) | Ретроспектива проекта |

---

## 🔧 Основные команды

```powershell
# Статус и логи
docker-compose ps
docker-compose logs postgres --tail 20

# Перезапуск / остановка
docker-compose restart postgres
docker-compose down

# Подключение к PostgreSQL
docker-compose exec postgres psql -U postgres -d template1c

# Бэкап / восстановление
docker-compose exec postgres pg_dump -U postgres -d "MyBase" -F c -f /tmp/backup.dump
docker-compose cp postgres:/tmp/backup.dump .\backup.dump

# Проверка агента сервера 1С
Get-Service -Name "1C:Enterprise*Server*"
netstat -ano | findstr ":1540 :1541"
```

---

## 📦 Компоненты

| Компонент | Версия | Статус | Назначение |
|-----------|--------|--------|------------|
| PostgreSQL | 18.1-2.1C | ✅ Работает | СУБД для 1С:Предприятие |
| Portainer | latest | ✅ Работает | Управление Docker |
| pgAdmin | latest | ✅ Работает | Администрирование PostgreSQL |
| Tailscale | latest | ✅ Настроено | VPN для удалённого доступа |
| 1С:Предприятие | 8.5.1.1150 | ✅ Работает | Платформа на хосте (Windows) |
| Агент сервера 1С | 8.5.1.1150 | ✅ Протестирован | Клиент-серверный режим, многопользовательский доступ |

---

## ✅ Что работает

### Инфраструктура:
- ✅ PostgreSQL в Docker с русской локалью (`ru_RU.UTF-8`)
- ✅ Portainer для управления контейнерами
- ✅ pgAdmin для администрирования БД
- ✅ Tailscale VPN (шифрование WireGuard)

### 1С:Предприятие:
- ✅ Платформа на хосте (Windows 11 Pro)
- ✅ Подключение к PostgreSQL в Docker
- ✅ База `DemoHRMCorpDemo_bot` (2226 MB, 10,378 таблиц)
- ✅ Лицензия developer.1c.ru (привязана к железу)

### Агент сервера 1С:
- ✅ Служба запущена (порт 1540/1541)
- ✅ Консоль администрирования работает
- ✅ Многопользовательский режим (несколько сеансов одновременно)
- ✅ Конфигуратор + Предприятие параллельно

---

## 🔐 Безопасность

- ✅ Пароли в `.env` (добавлен в `.gitignore`)
- ✅ Tailscale шифрует трафик (WireGuard)
- ✅ GitHub 2FA включена
- ⚠️ Порты `0.0.0.0` — **не использовать без VPN!**

---

## 📈 Планы развития

### 🔥 Высокий приоритет:
- [ ] Обновлятор 1С для автоматических бэкапов (~30 мин)

### ⚡ Средний приоритет:
- [ ] Терминальный сервер в ВМ (Hyper-V + Windows 11/Server) (~2 часа)
- [ ] Мониторинг (cAdvisor + Grafana) (~1.5 часа)

### 📝 Низкий приоритет:
- [ ] Статья на Habr/VC с таймингом
- [ ] CI/CD для 1С-кода
- [ ] Резервное копирование в облако

---

## 👤 Автор

**Vladimir Bessonov**  
📧 bessonov_1989@list.ru  
🔗 https://github.com/VladimirProgrammist1C/1c-infrastructure

**Лицензия:** MIT | **Время развёртывания:** ~30 минут