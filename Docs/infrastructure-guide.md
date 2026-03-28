#  Руководство по развёртыванию инфраструктуры 1С на локальном сервере

**Версия:** 1.0  
**Дата:** 28.03.2026  
**Оборудование:** Geekom A9 Max (Ryzen AI 9 HX 370, Windows 11 Pro)  
**Файл:** `E:\1C_Infrastructure\docs\infrastructure-guide.md`

---

## Содержание

1. [Подготовка структуры каталогов](#1-подготовка-структуры-каталогов)
2. [Установка платформы 1С (ручная)](#2-установка-платформы-1С-ручная)
3. [Настройка символических ссылок](#3-настройка-символических-ссылок)
4. [Создание ярлыков 1С](#4-создание-ярлыков-1С)
5. [Настройка Ollama для AI-задач](#5-настройка-ollama-для-ai-задач)
6. [Система контроля версий (Git)](#6-система-контроля-версий-git)
7. [Диагностика проблем](#7-диагностика-проблем)
8. [Приложения](#приложения)

---

## 1. Подготовка структуры каталогов

### Рекомендуемая структура на диске E:

```
E:\
├── 1C_Infrastructure\           # Основная инфраструктура
│   ├── AI\                       # AI-модули
│   │   └── Ollama\              # Локальные LLM
│   │       ├── bin\             # Бинарники
│   │       ├── models\          # Модели
│   │       ├── logs\            # Логи
│   │       └── config\          # Конфигурации
│   ├── Mini AI 1C\              # AI-ассистент для 1С
│   ├── docs\                    # Документация
│   │   └── infrastructure-guide.md
│   ├── scripts\                 # Скрипты автоматизации
│   └── docker-compose.yml       # Контейнеры (PostgreSQL и др.)
│
├── DEV_LOCAL\                    # Локальная разработка
│   └── INSTALLED\
│       └── 1cv8\                # Платформа 1С
│           └── 8.5.1.1150\      # Версия платформы
│               └── bin\
│
└── _BACKUPS\                     # Резервные копии
    └── 1cv8_C_drive_backup_...
```

### Скрипт создания структуры:

```powershell
$directories = @(
    "E:\1C_Infrastructure\AI\Ollama\bin",
    "E:\1C_Infrastructure\AI\Ollama\models",
    "E:\1C_Infrastructure\AI\Ollama\logs",
    "E:\1C_Infrastructure\AI\Ollama\config",
    "E:\1C_Infrastructure\Mini AI 1C",
    "E:\1C_Infrastructure\docs",
    "E:\1C_Infrastructure\scripts",
    "E:\DEV_LOCAL\INSTALLED\1cv8",
    "E:\_BACKUPS"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
```

---

## 2. Установка платформы 1С (ручная)

### Вариант А: Ручная установка (без setup.exe)

Если нужно быстро развернуть платформу без официальной установки:

1. Скопируйте файлы платформы в:
   ```
   E:\DEV_LOCAL\INSTALLED\1cv8\8.5.1.1150\
   ```

2. Проверьте наличие:
   ```
   E:\DEV_LOCAL\INSTALLED\1cv8\8.5.1.1150\bin\1cv8.exe
   E:\DEV_LOCAL\INSTALLED\1cv8\8.5.1.1150\bin\1cv8c.exe
   ```

### Вариант Б: Официальная установка

При установке через `setup.exe`:
- Укажите путь: `E:\DEV_LOCAL\INSTALLED\1cv8\8.5.1.1150`
- Установщик автоматически создаст записи в реестре

---

## 3. Настройка символических ссылок

### Зачем это нужно?

- Некоторые приложения (Mini-AI-1C, сторонние инструменты) ищут 1С только в стандартных путях
- Символическая ссылка позволяет хранить файлы на E:, но «обмануть» приложения

### Скрипт создания ссылки (с бэкапом):

```powershell
# ================= НАСТРОЙКИ =================
$PLATFORM_PATH = "E:\DEV_LOCAL\INSTALLED\1cv8\8.5.1.1150"
$LINK_PATH = "C:\Program Files\1cv8"
$BACKUP_ROOT = "E:\_BACKUPS"
$BACKUP_PATH = "$BACKUP_ROOT\1cv8_C_drive_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
# =============================================

Write-Host "=== БЕЗОПАСНОЕ СОЗДАНИЕ ССЫЛКИ ===" -ForegroundColor Cyan

# 1. Проверка исходного пути
if (-not (Test-Path $PLATFORM_PATH)) {
    Write-Host "✗ Платформа не найдена: $PLATFORM_PATH" -ForegroundColor Red
    exit
}

# 2. Бэкап существующей папки (если есть)
if (Test-Path $LINK_PATH) {
    New-Item -ItemType Directory -Path $BACKUP_PATH -Force | Out-Null
    Copy-Item "$LINK_PATH\*" -Destination $BACKUP_PATH -Recurse -Force
    Remove-Item $LINK_PATH -Recurse -Force
    Write-Host "✓ Бэкап создан: $BACKUP_PATH" -ForegroundColor Green
}

# 3. Создание символической ссылки (PowerShell от Администратора!)
New-Item -ItemType SymbolicLink -Path $LINK_PATH -Target $PLATFORM_PATH -Force

# 4. Проверка
if (Test-Path "$LINK_PATH\bin\1cv8.exe") {
    Write-Host "✓ Ссылка создана и работает!" -ForegroundColor Green
} else {
    Write-Host "✗ Ошибка создания ссылки" -ForegroundColor Red
}
```

### Проверка ссылки:

```powershell
$link = Get-Item "C:\Program Files\1cv8"
Write-Host "Ссылка: $($link.Target)"
Test-Path "C:\Program Files\1cv8\bin\1cv8.exe"  # Должно вернуть True
```

### Важные замечания:

- ⚠️ **Запустите PowerShell от имени Администратора**
- ⚠️ **Остановите все процессы 1С перед созданием ссылки**
- ✅ Бэкап автоматически создаётся в `E:\_BACKUPS\`

---

## 4. Создание ярлыков 1С

### Скрипт создания ярлыков:

```powershell
$WshShell = New-Object -ComObject WScript.Shell
$platformPath = "C:\Program Files\1cv8\bin"

# Ярлык Конфигуратора
$shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\1C Конфигуратор.lnk")
$shortcut.TargetPath = "$platformPath\1cv8c.exe"
$shortcut.WorkingDirectory = $platformPath
$shortcut.IconLocation = "$platformPath\1cv8c.exe,0"
$shortcut.Description = "1С:Предприятие 8.3 - Конфигуратор"
$shortcut.Save()

# Ярлык Предприятия
$shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\1C Предприятие.lnk")
$shortcut.TargetPath = "$platformPath\1cv8.exe"
$shortcut.WorkingDirectory = $platformPath
$shortcut.IconLocation = "$platformPath\1cv8.exe,0"
$shortcut.Description = "1С:Предприятие 8.3 - Клиент"
$shortcut.Save()

# Ярлыки в меню Пуск
$startMenuPath = "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\1C"
New-Item -ItemType Directory -Path $startMenuPath -Force | Out-Null

$shortcut = $WshShell.CreateShortcut("$startMenuPath\1C Конфигуратор.lnk")
$shortcut.TargetPath = "$platformPath\1cv8c.exe"
$shortcut.WorkingDirectory = $platformPath
$shortcut.Save()

$shortcut = $WshShell.CreateShortcut("$startMenuPath\1C Предприятие.lnk")
$shortcut.TargetPath = "$platformPath\1cv8.exe"
$shortcut.WorkingDirectory = $platformPath
$shortcut.Save()

Write-Host "✓ Ярлыки созданы!" -ForegroundColor Green
```

---

## 5. Настройка Ollama для AI-задач

### Полная переустановка Ollama на E:

```powershell
# 1. Остановить службу
Stop-Service ollama -Force
Get-Process ollama -ErrorAction SilentlyContinue | Stop-Process -Force

# 2. Удалить старые данные
Remove-Item "$env:LOCALAPPDATA\Programs\Ollama" -Recurse -Force
Remove-Item "$env:USERPROFILE\.ollama" -Recurse -Force

# 3. Очистить переменные окружения
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", $null, "User")
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", $null, "User")

# 4. Создать новую структуру
$ollamaRoot = "E:\1C_Infrastructure\AI\Ollama"
New-Item -ItemType Directory -Path "$ollamaRoot\bin", "$ollamaRoot\models", "$ollamaRoot\logs" -Force

# 5. Скачать бинарники
$version = "v0.5.12"
Invoke-WebRequest -Uri "https://github.com/ollama/ollama/releases/download/$version/ollama-windows-amd64.zip" -OutFile "$env:TEMP\ollama.zip"
Expand-Archive -Path "$env:TEMP\ollama.zip" -DestinationPath "$ollamaRoot\bin" -Force

# 6. Настроить переменные окружения
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", "$ollamaRoot\models", "User")

# 7. Создать службу (Task Scheduler)
$startScript = @"
`$env:OLLAMA_MODELS = "E:\1C_Infrastructure\AI\Ollama\models"
& "E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe" serve
"@
$startScript | Out-File "$ollamaRoot\start-ollama.ps1" -Encoding UTF8

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ollamaRoot\start-ollama.ps1`""
$trigger = New-ScheduledTaskTrigger -AtLogon
Register-ScheduledTask -TaskName "Ollama Service" -Action $action -Trigger $trigger -RunLevel Highest -Force
Start-ScheduledTask -TaskName "Ollama Service"
```

### Рекомендуемые модели для 1С-разработки:

```powershell
# Баланс скорости и качества (рекомендуется):
& "E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe" pull qwen2.5:7b

# Более точная (требует больше ОЗУ):
& "E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe" pull qwen2.5:14b

# Быстрая, но слабее в русском:
& "E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe" pull llama3.2:3b
```

### Проверка работы:

```powershell
& "E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe" --version
& "E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe" list
& "E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe" run qwen2.5:7b "Привет!"
```

---

## 6. Система контроля версий (Git)

### 6.1. Зачем Git для инфраструктуры?

| Проблема без Git | Решение с Git |
|------------------|---------------|
| Ручное копирование версий | Автоматическое версионирование через `git tag` |
| «Что я менял?» | `git log` покажет историю |
| «Я что-то сломал» | `git restore` или `git checkout v1.0` |
| Риск потерять всё | Push на GitHub = бэкап |

> ⚠️ **НЕ коммитьте:** модели Ollama, логи, бэкапы, базы данных, файлы с паролями

### 6.2. Установка и настройка

```powershell
# Проверка
git --version

# Настройка пользователя (один раз)
git config --global user.name "Ваше Имя"
git config --global user.email "ваш@email.com"

# Инициализация
cd E:\1C_Infrastructure
git init
```

### 6.3. Создание .gitignore

```powershell
@"
# Модели Ollama
AI/Ollama/models/
*.bin
*.gguf

# Логи
*.log
logs/

# Переменные окружения
.env
.env.local

# Резервные копии
BACKUPS/
*.bak

# Временные файлы
Thumbs.db
.DS_Store

# 1С файлы
*.cf
*.cfu
*.dt
1Cv8.1CD
1Cv8.Log

# IDE
.vscode/
.idea/
"@ | Out-File ".gitignore" -Encoding UTF8
```

### 6.4. Первый коммит

```powershell
git add .
git commit -m "v1.0: Initial setup - 1C Platform + Ollama + Documentation"
git tag v1.0
git log --oneline
```

### 6.5. Внесение изменений

```powershell
# При каждом изменении:
git status
git add docs/ scripts/
git commit -m "v1.1: Описание изменений"
git tag v1.1
```

### 6.6. Отправка на GitHub (опционально)

```powershell
git remote add origin https://github.com/ВАШ_НИК/home-lab-infra.git
git push -u origin main
git push origin --tags
```

### 6.7. Откат к версии

```powershell
git tag                     # Показать версии
git checkout v1.0           # Просмотр версии
git checkout main           # Вернуться к последней
git reset --soft HEAD~1     # Отменить коммит
```

---

## 7. Диагностика проблем

### 7.1. Mini-AI-1C не находит платформу 1С

**Симптомы:**
```
HELP_STATUS:unavailable:1C Platform not found in standard paths
```

**Решение:**

```powershell
# 1. Проверить символическую ссылку
Get-Item "C:\Program Files\1cv8" | Select-Object Target
Test-Path "C:\Program Files\1cv8\bin\1cv8.exe"

# 2. Проверить реестр
Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\1C\1Cv8"

# 3. Добавить запись в реестр (если нужно)
$regPath = "HKLM:\SOFTWARE\WOW6432Node\1C\1Cv8"
New-ItemProperty -Path $regPath -Name "InstallPath" -Value "E:\DEV_LOCAL\INSTALLED\1cv8\8.5.1.1150" -Force
New-ItemProperty -Path $regPath -Name "Version" -Value "8.5.1.1150" -Force

# 4. Перезапустить Mini-AI-1C
```

### 7.2. Ярлыки 1С не работают

**Диагностика:**
```powershell
$shortcuts = Get-ChildItem -Path "$env:USERPROFILE\Desktop" -Filter "*1C*.lnk"
foreach ($sc in $shortcuts) {
    $shell = New-Object -ComObject WScript.Shell
    $link = $shell.CreateShortcut($sc.FullName)
    Write-Host "$($sc.Name): $($link.TargetPath)"
    Test-Path $link.TargetPath
}
```

**Решение:** Пересоздать ярлыки (см. раздел 4)

### 7.3. Ollama не определяется путь к моделям

```powershell
# Проверка
echo $env:OLLAMA_MODELS

# Решение
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", "E:\1C_Infrastructure\AI\Ollama\models", "User")
Restart-Service ollama -Force
```

### 7.4. Символическая ссылка не работает

```powershell
# Удалить старую
Remove-Item "C:\Program Files\1cv8" -Force

# Создать новую
New-Item -ItemType SymbolicLink -Path "C:\Program Files\1cv8" -Target "E:\DEV_LOCAL\INSTALLED\1cv8\8.5.1.1150" -Force

# Проверить
Test-Path "C:\Program Files\1cv8\bin\1cv8.exe"
```

---

## Приложения

### Приложение A: Быстрые команды Git

```powershell
# Инициализация
git init
git config --global user.name "Имя"
git config --global user.email "email"

# Ежедневная работа
git status          # Что изменилось
git add .           # Добавить всё
git commit -m "..." # Закоммитить
git tag v1.X        # Пометить версию
git log --oneline   # История

# GitHub
git remote add origin <url>
git push -u origin main
git push origin --tags

# Откат
git checkout v1.0   # Просмотр версии
git checkout main   # Вернуться к последней
git reset --soft HEAD~1  # Отменить коммит
```

### Приложение B: Контрольный список развёртывания

```
[ ] 1. Создать структуру каталогов на E:
[ ] 2. Установить платформу 1С (в E:\DEV_LOCAL\INSTALLED\1cv8\)
[ ] 3. Создать символическую ссылку C:\Program Files\1cv8
[ ] 4. Создать ярлыки 1С на рабочем столе
[ ] 5. Установить Ollama на E:\1C_Infrastructure\AI\Ollama
[ ] 6. Скачать модели (qwen2.5:7b)
[ ] 7. Установить Mini-AI-1C
[ ] 8. Настроить Git-репозиторий
[ ] 9. Создать .gitignore
[ ] 10. Сделать первый коммит (v1.0)
[ ] 11. Настроить PostgreSQL (Docker/VM)
[ ] 12. Настроить Tailscale для удалённого доступа
[ ] 13. Протестировать всю инфраструктуру
```

### Приложение C: Шаблон CHANGELOG.md

```markdown
# История изменений инфраструктуры

## [1.0] - 2026-03-28
### Добавлено
- Базовая структура каталогов на E:
- Установка платформы 1С (ручная)
- Символические ссылки для совместимости
- Ярлыки 1С на рабочем столе
- Настройка Ollama (локальные LLM)
- Git-репозиторий для версионирования

### Известные проблемы
- Mini-AI-1C не находит платформу без записей в реестре
- Требуется ответ от разработчика Mini-AI-1C

### Исправлено
- Нерабочие ярлыки 1С (пересозданы)
```

---

## 📋 Статус проекта

| Этап | Задача | Статус |
|------|--------|--------|
| **1** | Платформа 1С + символические ссылки | ✅ Готово |
| **2** | Ярлыки 1С | ✅ Готово |
| **3** | Git-репозиторий | ✅ Готово |
| **4** | Ollama (локальные LLM) | ⏳ Частично |
| **5** | Mini-AI-1C интеграция | ⏸️ Ждём ответ разработчика |
| **6** | PostgreSQL в Docker/VM | 📅 Следующий шаг |
| **7** | 1С Server в ВМ (dev/test/prod) | 📅 После PostgreSQL |
| **8** | Portainer (веб-панель) | 📅 Параллельно с Docker |
| **9** | Tailscale (удалённый доступ) | ✅ Настроено |
| **10** | Бэкапы и мониторинг | 📅 Финальный этап |

