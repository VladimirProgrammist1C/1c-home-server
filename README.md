# 🏠 1C Infrastructure
<a name="top"></a>

Домашний сервер для 1С-разработки на базе **Geekom A9 Max** (Ryzen AI 9 HX 370, Windows 11 Pro).

![InfoStart Logo](https://infostart.ru/bitrix/templates/sandbox_empty/assets/tpl/abo/img/logo.svg)

> **Цель:** Изолированная среда для 1С + мониторинг + автоматические бэкапы + безопасный доступ.

---

## 📋 Содержание <a name="table-of-contents"></a>
- [🧩 Сервисы](#services)
- [🚀 Быстрый старт](#quick-start)
- [🌐 Доступ к сервисам](#access)
- [📊 Мониторинг и алерты](#monitoring)
- [📚 Документация](#documentation)
- [🔗 Опубликовано на InfoStart](#infostart-article)
- [🔐 Безопасность](#security)
- [🛠️ Диагностика](#diagnostics)
- [📈 Статус проекта](#status)
- [👤 Автор и контакты](#author)
- [🌐 Полезные ресурсы](#resources)

[🔝 Наверх](#top)

---

## 🧩 Сервисы <a name="services"></a>

| Сервис | Порт | Назначение | Статус |
|--------|------|-----------|--------|
| 🐘 PostgreSQL 1C | `5432` | СУБД для 1С:Предприятие | ✅ |
| 🗄️ pgAdmin | `5050` | Управление базами данных | ✅ |
| 🐳 Portainer | `9000` | Оркестрация Docker | ✅ |
| 📊 Prometheus | `9090` | Сбор метрик | ✅ |
| 📈 Grafana | `3002` | Дашборды и алерты | ✅ |
| 🔍 Blackbox Exporter | `9115` | HTTP-проверки доступности | ✅ |
| 📦 postgres-exporter | `9187` | Метрики PostgreSQL | ✅ |
| 💻 cAdvisor | `8080` | Метрики хоста | ✅ |
| 🔔 VoceChat-Notify | `3001` | Канал для системных уведомлений (`#alerts`) | ✅ |

[🔝 Наверх](#top)

---

## 🚀 Быстрый старт <a name="quick-start"></a>

### Предварительные требования
- ✅ Windows 11 Pro x64
- ✅ Docker Desktop + WSL2
- ✅ Git
- ✅ Tailscale (для защищённого доступа)

### Установка за 5 минут

```powershell
# 1. Клонировать репозиторий
git clone <repository-url> E:\1C_Infrastructure
cd E:\1C_Infrastructure

# 2. Настроить пароли
Copy-Item .env.example .env
notepad .env  # ← изменить пароли!

# 3. Запустить инфраструктуру
docker-compose up -d

# 4. Проверить статус
docker-compose ps  # все сервисы должны быть "Up (healthy)"
```

[🔝 Наверх](#top)

---

## 🌐 Доступ к сервисам <a name="access"></a>

**Локально:** `localhost` или `127.0.0.1`  
**Удалённо (безопасно):** `100.x.x.x` через **Tailscale VPN**

> 🔐 **Tailscale** обеспечивает **безопасный защищённый доступ** через зашифрованный туннель (WireGuard). Проброс портов не требуется.  
> 🖥️ **RDP** используется непосредственно для удалённого подключения, но весь трафик идёт через защищённый туннель Tailscale.

[🔝 Наверх](#top)

---

## 📊 Мониторинг и алерты <a name="monitoring"></a>

**Grafana:** [http://localhost:3002](http://localhost:3002) (открывается по умолчанию)

### Алерты (12 правил)

#### 🏗️ Инфраструктура (9 правил)
| Алерт | Критичность | Условие |
|-------|-------------|---------|
| 🔴 PostgreSQL is DOWN | Critical | `pg_up == 0` |
| 🔴 Portainer Down | Critical | HTTP проверка не прошла |
| 🔴 pgAdmin Down | Critical | HTTP проверка не прошла |
| 🔴 Grafana is DOWN | Critical | HTTP проверка не прошла |
| 🔴 Prometheus is DOWN | Critical | `up{job="prometheus"} == 0` |
| 🔴 VoceChat-Notify is DOWN | Critical | HTTP проверка не прошла |
| 🔴 cAdvisor is DOWN | Critical | `up{job="cadvisor"} == 0` |
| 🟡 High CPU Usage | Warning | `> 80%` (5 min avg) |
| 🟡 High Memory Usage | Warning | `> 1 GB` |

#### 📊 Бизнес-метрики 1С (3 правила)
| Алерт | Критичность | Условие |
|-------|-------------|---------|
| 🟡 High Database Size | Warning | База > 5 ГБ |
| 🟡 High 1C Connections | Warning | Всего подключений > 10 |
| 🟡 High User Connections | Warning | Подключений юзера > 2 |

### 📨 Уведомления
| Канал | Назначение | Когда приходит |
|-------|-----------|----------------|
| 💬 **VoceChat-Notify** | Основной канал (`#alerts`) | Через 2 мин после срабатывания + при восстановлении |
| 📧 **Email** | Резервный канал | Только при недоступности VoceChat-Notify (`VoceChatNotifyDown`) |

**Формат:** читаемый текст на русском с эмодзи и порогами.

[🔝 Наверх](#top)

---

## 📚 Документация <a name="documentation"></a>

| Файл | Описание |
|------|----------|
| [📘 infrastructure-guide.md](Docs/infrastructure-guide.md) | Полное руководство по развёртыванию |
| [⚡ COMMANDS.md](Docs/COMMANDS.md) | Шпаргалка по командам (Docker, PowerShell, Prometheus) |

💡 **Полная история проекта** (тайминг, проблемы, инсайты, статистика):  
Опубликована в статье на InfoStart → [см. ниже](#infostart-article)

[🔝 Наверх](#top)

---

## 🔗 Опубликовано на InfoStart <a name="infostart-article"></a>

![InfoStart Logo](https://infostart.ru/bitrix/templates/sandbox_empty/assets/tpl/abo/img/logo.svg)

📰 **DevOps для 1С на практике: как я развернул домашний сервер за 14 дней и 32 часа**  
Практический гайд по применению DevOps-практик в 1С-инфраструктуре: контейнеризация СУБД, инфраструктура как код, мониторинг с алертами, автоматические бэкапы. Разбираю подводные камни и делюсь готовыми конфигами.

🔗 [Читать статью на InfoStart](https://infostart.ru/1c/articles/2658161/)

[🔝 Наверх](#top)

---

## 🔐 Безопасность <a name="security"></a>

- ✅ Пароли хранятся в `.env` (добавлен в `.gitignore`)
- ✅ Именованные Docker volumes вместо bind mounts
- ✅ **Tailscale VPN** для **безопасного защищённого доступа** (шифрование WireGuard)
- ✅ GitHub 2FA включена
- ✅ Нет открытых портов в публичный интернет

> ⚠️ **Никогда не коммитьте**: `.env`, файлы с паролями, бэкапы, модели ИИ, базы данных.

[🔝 Наверх](#top)

---

## 🛠️ Диагностика <a name="diagnostics"></a>

### Сервис не запускается?
```powershell
# 1. Проверить логи
docker-compose logs <service_name> --tail 100
# 2. Проверить статус
docker-compose ps
# 3. Пересоздать контейнер
docker-compose up -d --force-recreate <service_name>
```

### Алерты не срабатывают?
```powershell
# 1. Проверить targets в Prometheus
# → http://localhost:9090/targets
# 2. Перезапустить Prometheus
docker-compose restart prometheus
```

Подробнее: [🔍 Раздел диагностики](Docs/infrastructure-guide.md#troubleshooting)

[🔝 Наверх](#top)

---

## 📈 Статус проекта <a name="status"></a>

| Показатель | Значение |
|------------|----------|
| Версия | 2.5 (стабильная) |
| Сервисов | 9 |
| Алертов | 12/12 работают |
| Время разработки | ~55 часов за 26 дней |
| Последнее обновление | 16.04.2026 |

📊 **Полная статистика и инсайты** — в статье на InfoStart 🔗 [[ссылка выше](#infostart-article)]

[🔝 Наверх](#top)

---

## 👤 Автор и контакты <a name="author"></a>

**Vladimir Bessonov**  
📧 bessonov_1989@list.ru  
🔗 [GitHub](https://github.com/VladimirProgrammist1C/1c-home-server)  
📄 Лицензия: MIT

[🔝 Наверх](#top)

---

## 🌐 Полезные ресурсы <a name="resources"></a>

📚 **Публикации и статьи:**
- [InfoStart: Статья проекта](https://infostart.ru/1c/articles/2658161/) — DevOps для 1С на практике
- [InfoStart: Профиль автора](https://infostart.ru/profile/348559/) — другие статьи и материалы по 1С

💬 **Сообщества:**
- [ВКонтакте: "Автоматизация бизнес-процессов"](https://vk.com/club230942526)

🎥 **Rutube плейлисты:**
- [🔧 Автоматизация процессов](https://rutube.ru/plst/889148?r=wd)
- [💻 Автоматизация разработки в 1С](https://rutube.ru/plst/858490?r=wd)
- [⚙️ Автоматизация администрирования](https://rutube.ru/plst/1269695?r=wd)
- [📊 1С:Аналитика](https://rutube.ru/plst/858486?r=wd)
- [🔐 Безопасность при работе в 1С](https://rutube.ru/plst/858489?r=wd)

🔗 **Официальная документация:**
- [1С:ИТС releases](https://releases.1c.ru)
- [PostgreSQL docs](https://postgrespro.ru/docs)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Prometheus](https://prometheus.io)
- [Grafana](https://grafana.com)
- [Blackbox Exporter](https://github.com/prometheus/blackbox_exporter)

[🔝 Наверх](#top)