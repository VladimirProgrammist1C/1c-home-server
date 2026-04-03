# 🏠 1C Infrastructure

Домашний сервер для 1С-разработки и тестирования на базе **Geekom A9 Max** (Ryzen AI 9 HX 370, Windows 11 Pro).

> **Цель:** Создание изолированной среды для 1С-разработки с приближением к продакшену.

---

## 🧩 Компоненты

### Основные сервисы

| Сервис | Назначение | Порт |
|--------|------------|------|
| PostgreSQL | СУБД для 1С:Предприятие | 5432 |
| pgAdmin | Веб-интерфейс PostgreSQL | 5050 |
| 1С:Предприятие | Сервер 1С (dev / test / prod) | — |

### Инфраструктура и мониторинг

| Сервис | Назначение | Порт |
|--------|------------|------|
| Portainer | Управление Docker-контейнерами | 9000 |
| Grafana | Дашборды и алерты | 3002 |
| Prometheus | Сбор и хранение метрик | 9090 |
| cAdvisor | Мониторинг ресурсов контейнеров | 8080 |
| Blackbox Exporter | HTTP-проверки доступности | 9115 |
| postgres-exporter | Метрики PostgreSQL | 9187 |
| VoceChat | Уведомления об инцидентах | 3001 |

---

## 📚 Документация

| Файл | Описание |
|------|----------|
| [`infrastructure-guide.md`](Docs/infrastructure-guide.md) | 📘 Подробное руководство по развёртыванию и настройке |
| [`COMMANDS.md`](COMMANDS.md) | ⚡ Шпаргалка с основными командами управления |
| [`TIMING.md`](Docs/TIMING.md) | ⏱️ Хронология работ и принятых решений |
| [`SUMMARY.md`](Docs/SUMMARY.md) | 📋 Краткое резюме проекта |

---

## 🚀 Быстрый старт

```powershell
# 1. Клонировать репозиторий
git clone <repository-url>
cd 1C_Infrastructure

# 2. Настроить переменные окружения
#    (отредактируйте .env, установите пароли)

# 3. Запустить все сервисы
docker-compose up -d

# 4. Проверить статус
docker-compose ps
```

> Все команды и сценарии использования — в [`COMMANDS.md`](COMMANDS.md)

---

## 📊 Мониторинг

Система автоматически отслеживает:

- 🔴 **Доступность сервисов:** PostgreSQL, Grafana, pgAdmin, Portainer, VoceChat
- 🟡 **Ресурсы:** CPU, RAM контейнеров
- 🔔 **Уведомления:** отправляются в локальный чат VoceChat

**Полезные ссылки:**

- Графана: http://localhost:3002
- Prometheus: http://localhost:9090
- Алерты: http://localhost:3002/alerting/list

Детали настройки мониторинга — в [`infrastructure-guide.md`](Docs/infrastructure-guide.md)

---

## 🔐 Безопасность

- Все пароли хранятся в `.env` — **не коммитьте этот файл!**
- Сервисы доступны только на `localhost`
- Для внешнего доступа используйте VPN

---

## 📁 Структура проекта

```
1C_Infrastructure/
├── docker-compose.yml          # Конфигурация Docker
├── .env                        # Переменные окружения (игнорируется Git)
├── README.md                   # Этот файл
├── infrastructure-guide.md     # Подробное руководство
├── COMMANDS.md                 # Шпаргалка по командам
├── TIMING.md                   # Хронология работ
├── SUMMARY.md                  # Краткое резюме
├── monitoring/
│   ├── prometheus.yml          # Настройки Prometheus
│   └── blackbox.yml            # Настройки Blackbox Exporter
└── grafana/
    └── provisioning/           # Автоконфигурация дашбордов и алертов
```

---

## 📝 Лицензия

MIT License