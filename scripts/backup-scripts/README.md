# Интерактивный полный бэкап инфраструктуры 1С

Интерактивный скрипт для создания выборочного бэкапа инфраструктуры 1С на базе Docker.

**Версия:** 1.0  
**Автор:** Vladimir Bessonov  
**Дата:** 14.06.2026

---

## Возможности

- 4-этапный бэкап с интерактивным выбором
- Whitelist не-1С баз (защита от бэкапа рабочих 1С баз)
- Start-Process вместо docker run (без зависаний)
- Проверка целостности gzip-архивов
- Прогресс-бар и логирование в backup.log
- Маркеры: [W] (whitelist), [B] (bind mount), [SKIP] (пропущено)
- Интерактивные команды: 1-4, a, s, q

---
---

## 🎥 Видеодемонстрации

Смотрите подробные видео работы скрипта:

### 📹 Тестовый режим

[▶️ **Демонстрация тестового режима**](../../Docs/videos/backup-test-demo.md)

*Запуск скрипта с флагом `-Test` — проверка без фактического сохранения*

- **Длительность:** ~3 минуты
- **Размер:** 2.86 МБ
- **Показано:** интерактивное меню, выбор этапов, whitelist, тестовый прогон

---

### 📹 Полный бэкап (боевой режим)

[▶️ **Демонстрация полного бэкапа**](../../Docs/videos/backup-full-demo.md)

*Все 4 этапа бэкапа инфраструктуры с архивацией Docker volumes*

- **Длительность:** ~10 минут
- **Размер:** 22 МБ
- **Показано:** 
  - Этап 1: Конфиги проекта (1.61 ГБ)
  - Этап 2: Не-1С базы PostgreSQL
  - Этап 3: Конфиги PostgreSQL
  - Этап 4: Docker volumes (9 томов, 6.83 ГБ)
  - Итоговая статистика

---

## Требования

| Компонент | Версия | Назначение |
|-----------|--------|------------|
| Windows | 10/11 Pro | Хост-система |
| Docker Desktop | 4.x+ | Оркестрация контейнеров |
| PowerShell | 5.1+ | Запуск скрипта |
| Контейнер postgres-1c | запущен | СУБД для 1С |

---

## Структура файлов

```
scripts/backup-scripts/
├── full-backup-rus.ps1          <- Основной скрипт
├── non-1c-databases.txt         <- Whitelist не-1С баз
├── logs.txt                     <- Пример лога работы
└── README.md                    <- Это руководство
```

---

## Быстрый старт

### 1. Подготовка whitelist

Создай файл `non-1c-databases.txt` рядом со скриптом:

```
# ============================================================
# Whitelist НЕ-1С баз данных для бэкапа
# ============================================================
# Формат: одна база на строку
# Комментарии начинаются с #
# Пустые строки игнорируются

# 1С-ные базы (DemoHRMCorpDemo_bot, ERP_DEMO, zup_test_update,
# test_restore и др.) бэкапятся через Обновлятор 1С!
# ============================================================

# Системная база PostgreSQL
postgres

# Gitea (репозитории кода)
gitea

# Уведомления VoceChat
vocechat_notify

# Аналитика 1С
analytics

# Grafana (дашборды мониторинга)
grafana
```

**Важно:** Без этого файла скрипт не сможет определить 1С-ные базы. При отсутствии файла бэкап не-1С баз будет пропущен с предупреждением.

### 2. Запуск скрипта

```powershell
cd E:\1C_Infrastructure\scripts\backup-scripts
.\full-backup-rus.ps1
```

---

## Интерактивное меню

После запуска скрипт покажет меню:

```
----------------------------------------
 ИНТЕРАКТИВНЫЙ БЭКАП
----------------------------------------

Скрипт для создания выборочного бэкапа инфраструктуры 1С.
1С-ные базы бэкапятся через Обновлятор 1С!
Можно сохранить отдельные этапы или все сразу.
[2026-06-14 16:30:24] [INFO] Запуск в боевом режиме

ВЫБЕРИТЕ ЭТАП ДЛЯ ВЫПОЛНЕНИЯ:

  [1] ЭТАП 1: КОНФИГИ ПРОЕКТА
      Копирует файлы проекта (docker-compose.yml, .env, monitoring/)
      Результат: Полная копия проекта, восстанавливается через robocopy

  [2] ЭТАП 2: НЕ-1С БАЗЫ POSTGRESQL
      Создаёт отдельный pg_dump для каждой не-1С базы
      Результат: Отдельные файлы .sql.gz (~10x сжатие)

  [3] ЭТАП 3: КОНФИГИ POSTGRESQL
      Копирует postgresql.conf, pg_hba.conf, pg_ident.conf
      Результат: ~20 КБ настроек сервера для восстановления ручной настройки

  [4] ЭТАП 4: VOLUMES И BIND MOUNTS
      Создаёт tar.gz архив для каждого Docker volume и bind mount
      Результат: Побайтовая копия (самый медленный, самый объёмный)

  [a] Выполнить все 4 этапа последовательно
  [s] Показать итоги и завершить
  [q] Выйти без сохранения

Введите значение (1-4, a, s или q):
```

### Команды

| Команда | Действие |
|---------|----------|
| 1 | Только этап 1 — конфиги проекта |
| 2 | Только этап 2 — не-1С базы PostgreSQL |
| 3 | Только этап 3 — конфиги PostgreSQL |
| 4 | Только этап 4 — volumes и bind mounts |
| a | Запустить все этапы последовательно |
| s | Показать итоги и завершить |
| q | Выйти без сохранения |

---

## Этапы бэкапа

### Этап 1: Конфиги проекта

**Что бэкапит:**
- docker-compose.yml
- .env
- monitoring/prometheus.yml
- monitoring/prometheus/alerts.yml

**Метод:** Robocopy (полная копия структуры папок)  
**Результат:** Полная копия проекта  
**Размер:** ~5-50 КБ

### Этап 2: Не-1С базы PostgreSQL

**Что бэкапит:**
- Только базы из non-1c-databases.txt
- Базы 1С (определяются по таблицам _InfoRg*) пропускаются

**Метод:** pg_dump + gzip (сжатие ~10x)  
**Результат:** Отдельные файлы .sql.gz  
**Маркеры:** [W] — из whitelist, [SKIP] — 1С база  
**Размер:** ~1-50 МБ на базу

### Этап 3: Конфиги PostgreSQL

**Что бэкапит:**
- postgresql.conf
- pg_hba.conf
- pg_ident.conf

**Метод:** Копирование из контейнера  
**Результат:** ~20 КБ настроек  
**Размер:** ~10-50 КБ

### Этап 4: Volumes и bind mounts

**Что бэкапит:**
- Docker volumes (postgres-data, pgadmin-data, prometheus-data)
- Bind mounts (привязанные папки хоста)

**Метод:** tar.gz (побайтовая копия)  
**Результат:** Побайтовая копия  
**Маркер:** [B] — bind mount  
**Размер:** ~100 МБ - 10 ГБ+

---

## Пример вывода

```
----------------------------------------
 ЭТАП 4: DOCKER VOLUMES И BIND MOUNTS
----------------------------------------

[2026-06-14 16:34:15] [INFO] === ЭТАП 4: DOCKER VOLUMES И BIND MOUNTS ===
[2026-06-14 16:34:15] [INFO] Начало бэкапа Docker volumes и bind mounts
ЧТО ДЕЛАЕТ:
  Создаёт tar.gz архив для каждого Docker volume.
  Bind mounts (например, VoceChat) архивируются напрямую.
  Содержит ВСЕ данные: базы, конфиги, логи, всё.

ОЖИДАЕМЫЙ РЕЗУЛЬТАТ:
  Побайтовая копия каждого volume.
  Можно восстановить полное состояние сервиса (не только данные).
  ВНИМАНИЕ: Это самый медленный и объёмный этап!

[2026-06-14 16:34:16] [INFO]   PostgreSQL: 10.19 ГБ
[2026-06-14 16:34:17] [INFO]   pgAdmin: 3.04 МБ
[2026-06-14 16:34:17] [INFO]   Grafana: 53.04 МБ
[2026-06-14 16:34:18] [INFO]   Prometheus: 271.07 МБ
[2026-06-14 16:34:19] [INFO]   Portainer: 541.74 КБ
[2026-06-14 16:34:20] [INFO]   Gitea (репозитории): 528.04 КБ
[2026-06-14 16:34:20] [INFO]   VoceChat-Notify: 35.44 МБ
[2026-06-14 16:34:21] [INFO]   Аналитика: 143.88 МБ
[2026-06-14 16:34:21] [INFO]   VoceChat (семейный) (bind): 73.96 МБ
[2026-06-14 16:34:21] [SUCCESS] Найдено 9 volume(s)/bind mount(s)

ВЫБЕРИТЕ VOLUME ДЛЯ АРХИВАЦИИ:
  (номер, a=all, r=remaining, c=continue, x=summary)

  [1] PostgreSQL - 1c_infrastructure_postgres-data (10.19 ГБ)
  [2] pgAdmin - 1c_infrastructure_pgadmin-data (3.04 МБ)
  [3] Grafana - 1c_infrastructure_grafana-data (53.04 МБ)
  [4] Prometheus - 1c_infrastructure_prometheus-data (271.07 МБ)
  [5] Portainer - 1c_infrastructure_portainer-data (541.74 КБ)
  [6] Gitea (репозитории) - 1c_infrastructure_gitea-data (528.04 КБ)
  [7] VoceChat-Notify - 1c_infrastructure_vocechat-notify-data (35.44 МБ)
  [8] Аналитика - 1c_infrastructure_analytics-data (143.88 МБ)
  [9] VoceChat (семейный) [B] - bind:vocechat (73.96 МБ)

  a  - заархивировать все
  r  - заархивировать оставшиеся (9)
  c  - вернуться в главное меню
  x  - показать итоги и завершить

  [B] = bind mount (папка на хосте)

Введите значение: 9

[2026-06-14 16:34:24] [INFO] Начало архивации: VoceChat (семейный) (73.96 МБ) [9/9]
  [9/9] Архивация: VoceChat (семейный) (73.96 МБ)...
[2026-06-14 16:34:24] [INFO] Создание архива: bind-vocechat
[2026-06-14 16:34:24] [INFO] Тип: bind mount, путь: E:\vocechat\data
[2026-06-14 16:34:24] [INFO] Команда: docker run --rm -v E:\vocechat\data:/source -v F:\Docker_Backups\Backup_2026-06-14_16-34-13\Volumes:/backup alpine tar czf /backup/bind-vocechat.tar.gz -C /source .
[2026-06-14 16:34:29] [INFO] Архив создан: 64.14 МБ
[2026-06-14 16:34:29] [INFO] Проверка целостности архива...
[2026-06-14 16:34:31] [SUCCESS] Volume VoceChat (семейный) заархивирован: 64.14 МБ (время: 7с)

ВЫБЕРИТЕ VOLUME ДЛЯ АРХИВАЦИИ:
  (номер, a=all, r=remaining, c=continue, x=summary)

  [1] PostgreSQL - 1c_infrastructure_postgres-data (10.19 ГБ)
  [2] pgAdmin - 1c_infrastructure_pgadmin-data (3.04 МБ)
  [3] Grafana - 1c_infrastructure_grafana-data (53.04 МБ)
  [4] Prometheus - 1c_infrastructure_prometheus-data (271.07 МБ)
  [5] Portainer - 1c_infrastructure_portainer-data (541.74 КБ)
  [6] Gitea (репозитории) - 1c_infrastructure_gitea-data (528.04 КБ)
  [7] VoceChat-Notify - 1c_infrastructure_vocechat-notify-data (35.44 МБ)
  [8] Аналитика - 1c_infrastructure_analytics-data (143.88 МБ)
  [ВЫПОЛНЕНО] VoceChat (семейный) [B] - bind:vocechat (73.96 МБ)

  a  - заархивировать все
  r  - заархивировать оставшиеся (8)
  c  - вернуться в главное меню
  x  - показать итоги и завершить

  [B] = bind mount (папка на хосте)

Введите значение: x
[2026-06-14 16:34:38] [INFO] Пользователь запросил итоги

[2026-06-14 16:34:38] [INFO] === ИТОГИ БЭКАПА ===
----------------
 БЭКАП ЗАВЕРШЁН
----------------

Расположение: F:\Docker_Backups\Backup_2026-06-14_16-34-13
Длительность: 0.42 минут
Лог: F:\Docker_Backups\Backup_2026-06-14_16-34-13\backup.log

ЭТАП 1 - КОНФИГИ ПРОЕКТА:
  [ПРОПУСК] Не выполнено
[2026-06-14 16:34:38] [WARNING] Этап 1: пропущен

ЭТАП 2 - НЕ-1С БАЗЫ ДАННЫХ:
  [ПРОПУСК] Не выполнено
[2026-06-14 16:34:38] [WARNING] Этап 2: пропущен

ЭТАП 3 - КОНФИГИ PG:
  [ПРОПУСК] Не выполнено
[2026-06-14 16:34:38] [WARNING] Этап 3: пропущен

ЭТАП 4 - VOLUMES И BIND MOUNTS:
  [OK] VoceChat (семейный) - 64.14 МБ
[2026-06-14 16:34:38] [SUCCESS]   Volume VoceChat (семейный): 64.14 МБ

ОБЩИЙ РАЗМЕР: 64.14 МБ
----------------------
[2026-06-14 16:34:38] [SUCCESS] Общий размер бэкапа: 64.14 МБ
[2026-06-14 16:34:38] [INFO] === БЭКАП ЗАВЕРШЁН ===

[НАЖМИТЕ] Нажмите любую клавишу для выхода...
```

---

## Пример лога

```
[2026-06-14 16:34:13] [INFO] Запуск в боевом режиме
[2026-06-14 16:34:15] [INFO] === ЭТАП 4: DOCKER VOLUMES И BIND MOUNTS ===
[2026-06-14 16:34:15] [INFO] Начало бэкапа Docker volumes и bind mounts
[2026-06-14 16:34:16] [INFO]   PostgreSQL: 10.19 ГБ
[2026-06-14 16:34:17] [INFO]   pgAdmin: 3.04 МБ
[2026-06-14 16:34:17] [INFO]   Grafana: 53.04 МБ
[2026-06-14 16:34:18] [INFO]   Prometheus: 271.07 МБ
[2026-06-14 16:34:19] [INFO]   Portainer: 541.74 КБ
[2026-06-14 16:34:20] [INFO]   Gitea (репозитории): 528.04 КБ
[2026-06-14 16:34:20] [INFO]   VoceChat-Notify: 35.44 МБ
[2026-06-14 16:34:21] [INFO]   Аналитика: 143.88 МБ
[2026-06-14 16:34:21] [INFO]   VoceChat (семейный) (bind): 73.96 МБ
[2026-06-14 16:34:21] [SUCCESS] Найдено 9 volume(s)/bind mount(s)
[2026-06-14 16:34:24] [INFO] Начало архивации: VoceChat (семейный) (73.96 МБ) [9/9]
[2026-06-14 16:34:24] [INFO] Создание архива: bind-vocechat
[2026-06-14 16:34:24] [INFO] Тип: bind mount, путь: E:\vocechat\data
[2026-06-14 16:34:24] [INFO] Команда: docker run --rm -v E:\vocechat\data:/source -v F:\Docker_Backups\Backup_2026-06-14_16-34-13\Volumes:/backup alpine tar czf /backup/bind-vocechat.tar.gz -C /source .
[2026-06-14 16:34:29] [INFO] Архив создан: 64.14 МБ
[2026-06-14 16:34:29] [INFO] Проверка целостности архива...
[2026-06-14 16:34:31] [SUCCESS] Volume VoceChat (семейный) заархивирован: 64.14 МБ (время: 7с)
[2026-06-14 16:34:38] [INFO] Пользователь запросил итоги
[2026-06-14 16:34:38] [INFO] === ИТОГИ БЭКАПА ===
[2026-06-14 16:34:38] [WARNING] Этап 1: пропущен
[2026-06-14 16:34:38] [WARNING] Этап 2: пропущен
[2026-06-14 16:34:38] [WARNING] Этап 3: пропущен
[2026-06-14 16:34:38] [SUCCESS]   Volume VoceChat (семейный): 64.14 МБ
[2026-06-14 16:34:38] [SUCCESS] Общий размер бэкапа: 64.14 МБ
[2026-06-14 16:34:38] [INFO] === БЭКАП ЗАВЕРШЁН ===
```

---

## Восстановление

### База PostgreSQL

```powershell
docker cp F:\Docker_Backups\2026-06-14\databases\postgres.dump postgres-1c:/tmp/
docker exec -it postgres-1c pg_restore -U postgres -d postgres /tmp/postgres.dump
docker exec -it postgres-1c rm /tmp/postgres.dump
```

### Конфиги проекта

```powershell
tar -xzf F:\Docker_Backups\2026-06-14\configs_2026-06-14.tar.gz -C E:\1C_Infrastructure\
docker-compose down && docker-compose up -d
```

### Volumes

```powershell
docker-compose down
docker run --rm -v postgres-data:/target -v F:\Docker_Backups\2026-06-14:/backup alpine tar -xzf /backup/volumes_2026-06-14.tar.gz -C /target
docker-compose up -d
```

---

## Troubleshooting (Устранение неисправностей)

### Контейнер postgres-1c не запущен

```powershell
docker ps -a | findstr postgres-1c
docker start postgres-1c
```

### Файл whitelist не найден

```powershell
Test-Path ".\non-1c-databases.txt"
```

### Архив повреждён

Скрипт автоматически проверяет целостность gzip. Если проверка не прошла — удали архив и запусти бэкап повторно.

### Скрипт зависает на бэкапе базы

Нажми `q` для выхода, затем проверь:
- Размер базы (большие бэкапятся дольше)
- Свободное место на диске
- `docker logs postgres-1c --tail 50`

---

## Связанные файлы

- [../backup-configs.ps1](../backup-configs.ps1) — бэкап только конфигов
- [../backup-postgres-host.ps1](../backup-postgres-host.ps1) — бэкап PostgreSQL с хоста
- [../../README.md](../../README.md) — общее руководство

---

## Changelog

### v1.0 (2026-06-14)
- Первый релиз
- 4-этапный бэкап с интерактивным выбором
- Whitelist не-1С баз
- Команды 1-4, a, s, q
- Проверка целостности gzip
- Логирование в backup.log
- Маркеры [W], [B], [SKIP]
- Start-Process вместо docker run