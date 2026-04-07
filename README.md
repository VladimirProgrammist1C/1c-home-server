# 🏠 1C Infrastructure

<a name="top"></a>

Домашний сервер для 1С-разработки на базе Geekom A9 Max (Ryzen AI 9 HX 370, Windows 11 Pro).

![InfoStart Logo](https://infostart.ru/bitrix/templates/sandbox_empty/assets/tpl/abo/img/logo.svg)

Цель: Изолированная среда для 1С + мониторинг + автоматические бэкапы + безопасный доступ.

## 📋 Содержание

- [🏠 1C Infrastructure](#-1c-infrastructure)
  - [📋 Содержание](#-содержание)
  - [🧩 Сервисы ](#-сервисы-)
  - [🚀 Быстрый старт ](#-быстрый-старт-)
  - [📊 Мониторинг ](#-мониторинг-)
  - [📚 Документация ](#-документация-)
  - [🔗 Опубликовано на InfoStart ](#-опубликовано-на-infostart-)
  - [🔐 Безопасность ](#-безопасность-)
  - [🛠️ Диагностика ](#️-диагностика-)
  - [📈 Статус проекта ](#-статус-проекта-)
  - [👤 Автор и контакты ](#-автор-и-контакты-)
  - [🌐 Полезные ресурсы ](#-полезные-ресурсы-)

[🔝 Наверх](#top)

---

## 🧩 Сервисы <a name="services"></a>

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

Доступ: `localhost` или `100.x.x.x` через Tailscale VPN.

[🔝 Наверх](#top)

---

## 🚀 Быстрый старт <a name="quick-start"></a>

```powershell
# 1. Клонировать репозиторий
git clone <repo-url>
cd 1C_Infrastructure

# 2. Настроить пароли (обязательно!)
copy .env.example .env
notepad .env  # ← изменить пароли!

# 3. Запустить все сервисы
docker-compose up -d

# 4. Проверить статус
docker-compose ps  # все должны быть "Up (healthy)"
```

[🔝 Наверх](#top)

---

## 📊 Мониторинг <a name="monitoring"></a>

Дашборд: [Grafana](http://localhost:3002) (открывается по умолчанию)

Алерты: 9 правил, уведомления в VoceChat

Проверки: HTTP, CPU, RAM, PostgreSQL

Счётчик проблем: `count(ALERTS{alertstate="firing"}) or vector(0)`

Подробнее: [📘 Руководство по мониторингу](Docs/infrastructure-guide.md#monitoring)

[🔝 Наверх](#top)

---

## 📚 Документация <a name="documentation"></a>

| Файл | Описание |
|------|----------|
| [📘 infrastructure-guide.md](Docs/infrastructure-guide.md) | Полное руководство по развёртыванию и настройке |
| [⚡ COMMANDS.md](Docs/COMMANDS.md) | Шпаргалка по командам (Docker, PowerShell, Prometheus) |

💡 **Полная история проекта** (тайминг, проблемы, инсайты, статистика) опубликована в статье на InfoStart → [см. ниже](#-опубликовано-на-infostart)

[🔝 Наверх](#top)

---

## 🔗 Опубликовано на InfoStart <a name="infostart-article"></a>

![InfoStart Logo](https://infostart.ru/bitrix/templates/sandbox_empty/assets/tpl/abo/img/logo.svg)

📰 **[DevOps для 1С на практике: как я развернул домашний сервер за 14 дней и 32 часа](https://infostart.ru/1c/articles/2658161/)**

Практический гайд по применению DevOps-практик в 1С-инфраструктуре: контейнеризация СУБД, инфраструктура как код, мониторинг с алертами, автоматические бэкапы. Разбираю подводные камни и делюсь готовыми конфигами.

[🔝 Наверх](#top)

---

## 🔐 Безопасность <a name="security"></a>

✅ **Что сделано:**
- Пароли хранятся в `.env` (файл добавлен в `.gitignore`)
- Именованные Docker volumes (не bind mounts)
- Healthcheck для PostgreSQL
- Private GitHub репозиторий + 2FA
- Tailscale VPN (шифрование WireGuard)
- Нет открытых портов в публичный интернет

⚠️ **Важно:** Порты `0.0.0.0` в `docker-compose.yml` безопасны только при использовании VPN (Tailscale)!

[🔝 Наверх](#top)

---

## 🛠️ Диагностика <a name="troubleshooting"></a>

```powershell
# Логи конкретного сервиса
docker-compose logs <service_name> --tail 50

# Перезапустить сервис
docker-compose restart <service_name>

# Проверить алерты
# → Grafana: http://localhost:3002/alerting/list
# → Prometheus: http://localhost:9090/targets

# Проверить статус всех сервисов
docker-compose ps
```

Подробнее: [🔍 Раздел диагностики](Docs/infrastructure-guide.md#troubleshooting)

[🔝 Наверх](#top)

---

## 📈 Статус проекта <a name="project-status"></a>

| Показатель | Значение |
|------------|----------|
| Версия | 2.4 (стабильная) |
| Сервисов | 10 |
| Алертов | 9/9 работают |
| Время разработки | ~32 часа за 14 дней |
| Последнее обновление | 04.04.2026 |

📊 Полная статистика и инсайты — в статье на InfoStart: [🔗 Читать статью](https://infostart.ru/1c/articles/2658161/)

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