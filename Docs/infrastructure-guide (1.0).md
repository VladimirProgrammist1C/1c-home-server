Отлично! Рад, что помогли! 🎉

Вот структурированное руководство на основе нашего опыта:

---

# 📚 Руководство по развёртыванию инфраструктуры 1С на локальном сервере

## Содержание
1. [Подготовка структуры каталогов](#1-подготовка-структуры-каталогов)
2. [Установка платформы 1С (ручная)](#2-установка-платформы-1С-ручная)
3. [Настройка символических ссылок](#3-настройка-символических-ссылок)
4. [Создание ярлыков 1С](#4-создание-ярлыков-1С)
5. [Настройка Ollama для AI-задач](#5-настройка-ollama-dlя-ai-задач)
6. [Диагностика проблем](#6-диагностика-проблем)

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

# 3. Создание символической ссылки
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
```

---

## 5. Настройка Ollama для AI-задач

### Полная переустановка Ollama на E:

```powershell
# См. полный скрипт в диалоге выше
# Ключевые моменты:
$ollamaRoot = "E:\1C_Infrastructure\AI\Ollama"

# 1. Остановить службу
Stop-Service ollama -Force

# 2. Удалить старые данные
Remove-Item "$env:LOCALAPPDATA\Programs\Ollama" -Recurse -Force
Remove-Item "$env:USERPROFILE\.ollama" -Recurse -Force

# 3. Скачать бинарники
Invoke-WebRequest -Uri "https://github.com/ollama/ollama/releases/download/v0.5.12/ollama-windows-amd64.zip" -OutFile "$env:TEMP\ollama.zip"
Expand-Archive -Path "$env:TEMP\ollama.zip" -DestinationPath "$ollamaRoot\bin"

# 4. Настроить переменные окружения
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", "$ollamaRoot\models", "User")

# 5. Создать службу (Task Scheduler)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ollamaRoot\start-ollama.ps1`""
$trigger = New-ScheduledTaskTrigger -AtLogon
Register-ScheduledTask -TaskName "Ollama Service" -Action $action -Trigger $trigger -RunLevel Highest -Force
```

### Рекомендуемые модели для 1С-разработки:

```powershell
# Баланс скорости и качества:
& "E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe" pull qwen2.5:7b

# Более точная (требует больше ОЗУ):
& "E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe" pull qwen2.5:14b

# Быстрая, но слабее в русском:
& "E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe" pull llama3.2:3b
```

---

## 6. Диагностика проблем

### Проблема: Mini-AI-1C не находит платформу 1С

**Симптомы:**
```
HELP_STATUS:unavailable:1C Platform not found in standard paths
```

**Решение:**

1. **Проверить символическую ссылку:**
   ```powershell
   Get-Item "C:\Program Files\1cv8" | Select-Object Target
   Test-Path "C:\Program Files\1cv8\bin\1cv8.exe"
   ```

2. **Проверить реестр:**
   ```powershell
   Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\1C\1Cv8" | 
       Select-Object InstallPath, Version
   ```

3. **Если реестр пустой — добавить запись:**
   ```powershell
   $regPath = "HKLM:\SOFTWARE\WOW6432Node\1C\1Cv8"
   New-ItemProperty -Path $regPath -Name "InstallPath" -Value "E:\DEV_LOCAL\INSTALLED\1cv8\8.5.1.1150" -Force
   New-ItemProperty -Path $regPath -Name "Version" -Value "8.5.1.1150" -Force
   ```

4. **Перезапустить Mini-AI-1C**

5. **Если не помогло — создать Issue на GitHub**

---

### Проблема: Ярлыки 1С не работают

**Диагностика:**
```powershell
$shortcuts = Get-ChildItem -Path "$env:USERPROFILE\Desktop" -Filter "*1C*.lnk"
foreach ($sc in $shortcuts) {
    $shell = New-Object -ComObject WScript.Shell
    $link = $shell.CreateShortcut($sc.FullName)
    Write-Host "$($sc.Name): $($link.TargetPath)"
    Test-Path $link.TargetPath  # Должно быть True
}
```

**Решение:** Пересоздать ярлыки (см. раздел 4)

---

### Проблема: Ollama не определяется путь к моделям

**Проверка:**
```powershell
echo $env:OLLAMA_MODELS
# Должно вывести: E:\1C_Infrastructure\AI\Ollama\models
```

**Решение:**
```powershell
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", "E:\1C_Infrastructure\AI\Ollama\models", "User")
# Перезапустить службу Ollama
```

---

## 📋 Чек-лист развёртывания

```
[ ] 1. Создать структуру каталогов на E:
[ ] 2. Установить платформу 1С (в E:\DEV_LOCAL\INSTALLED\1cv8\)
[ ] 3. Создать символическую ссылку C:\Program Files\1cv8
[ ] 4. Создать ярлыки 1С на рабочем столе
[ ] 5. Установить Ollama на E:\1C_Infrastructure\AI\Ollama
[ ] 6. Скачать модели (qwen2.5:7b)
[ ] 7. Установить Mini-AI-1C
[ ] 8. Настроить PostgreSQL (Docker/VM)
[ ] 9. Настроить Tailscale для удалённого доступа
[ ] 10. Протестировать всю инфраструктуру
```

---

## 🔐 Безопасность

- **Бэкапы:** Всегда делайте бэкап перед созданием символических ссылок
- **Пароли:** Используйте менеджер паролей (KeePassXC, Bitwarden)
- **Tailscale:** Включите 2FA для аккаунта
- **Доступ:** Ограничьте доступ к папкам с данными 1С

---

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи в `%APPDATA%\mini-ai-1c\logs`
2. Изучите Issues на GitHub репозитория
3. Создайте новый Issue с подробным описанием проблемы

---

**Версия руководства:** 1.0  
**Дата:** 28.03.2026  
**Автор:** На основе практического опыта развёртывания на Geekom A9 Max
