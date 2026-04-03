# 🏠 1C Infrastructure

Домашний сервер для 1С-разработки на базе **Geekom A9 Max** (Ryzen AI 9 HX 370, Windows 11 Pro).

> **Цель:** Изолированная среда для 1С + мониторинг + автоматические бэкапы.

---

## 🧩 Сервисы

| Сервис | Порт | Статус |
|--------|------|--------|
| PostgreSQL 1С | 5432 | ✅ UP |
| pgAdmin | 5050 | ✅ UP |
| Portainer | 9000 | ✅ UP |
| Grafana | 3002 | ✅ UP |
| Prometheus | 9090 | ✅ UP |
| VoceChat | 3001 | ✅ UP |
| Blackbox Exporter | 9115 | ✅ UP |
| postgres-exporter | 9187 | ✅ UP |
| cAdvisor | 8080 | ✅ UP |

**Доступ:** `localhost` или `100.x.x.x` через **Tailscale VPN**.

---

## 🚀 Быстрый старт

```powershell
# 1. Клонировать
git clone <repo-url>
cd 1C_Infrastructure

# 2. Настроить пароли
copy .env.example .env
notepad .env  # ← изменить пароли!

# 3. Запустить
docker-compose up -d

# 4. Проверить
docker-compose ps  # все должны быть "Up (healthy)"
```

---

## 📊 Мониторинг

- **Дашборд:** [Grafana](http://localhost:3002) (открывается по умолчанию)
- **Алерты:** 9 правил, уведомления в VoceChat
- **Проверки:** HTTP, CPU, RAM, PostgreSQL

**Счётчик проблем:** `count(ALERTS{alertstate="firing"}) or vector(0)`

---

## 📚 Документация

| Файл | Описание |
|------|----------|
| [infrastructure-guide.md](Docs/infrastructure-guide.md) | 📘 Полное руководство |
| [COMMANDS.md](COMMANDS.md) | ⚡ Шпаргалка по командам |
| [TIMING.md](Docs/TIMING.md) | ⏱️ Учёт времени |
| [SUMMARY.md](Docs/SUMMARY.md) | 📋 Итоги проекта |

---

## 🔐 Безопасность

- ✅ Пароли в `.env` (в `.gitignore`)
- ✅ Tailscale VPN (WireGuard)
- ✅ GitHub 2FA
- ✅ Нет открытых портов в интернет

> ⚠️ Порты `0.0.0.0` безопасны **только с VPN**!

---

## 🛠️ Диагностика

```powershell
# Логи сервиса
docker-compose logs <service> --tail 50

# Перезапустить
docker-compose restart <service>

# Проверить алерты
# → Grafana: http://localhost:3002/alerting/list
# → Prometheus: http://localhost:9090/targets
```

---

## 📈 Статус проекта

| Показатель | Значение |
|------------|----------|
| Версия | 2.4 (стабильная) |
| Сервисов | 10 |
| Алертов | 9/9 работают |
| Время разработки | **~32 часа** за 13 дней |
| Последнее обновление | 04.04.2026 |

---

## 👤 Автор и контакты

**Vladimir Bessonov**  
📧 bessonov_1989@list.ru  
🔗 [GitHub](https://github.com/VladimirProgrammist1C/1c-home-server)  
📄 Лицензия: MIT

### 🌐 Полезные ресурсы

| Площадка | Ссылка | Описание |
|----------|--------|----------|
| **InfoStart** | [Профиль](https://infostart.ru/profile/348559/) | Статьи и материалы по 1С |
| **ВКонтакте** | [Сообщество](https://vk.com/club230942526) | "Автоматизация бизнес-процессов" |
| **Rutube** | [Автоматизация процессов](https://rutube.ru/plst/889148?r=wd) | Плейлист |
| **Rutube** | [Автоматизация разработки в 1С](https://rutube.ru/plst/858490?r=wd) | Плейлист |
| **Rutube** | [Автоматизация администрирования](https://rutube.ru/plst/1269695?r=wd) | Плейлист |
| **Rutube** | [1С:Аналитика](https://rutube.ru/plst/858486?r=wd) | Плейлист |
| **Rutube** | [Безопасность в 1С](https://rutube.ru/plst/858489?r=wd) | Плейлист |

---

[🔝 Наверх](#-1c-infrastructure)