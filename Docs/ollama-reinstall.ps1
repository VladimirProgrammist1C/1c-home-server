# E:\1C_Infrastructure\AI\ollama-reinstall.ps1
# Запускать ОТ ИМЕНИ АДМИНИСТРАТОРА

$ErrorActionPreference = "Stop"
Write-Host "=== OLLAMA CLEAN REINSTALL ===" -ForegroundColor Cyan
Write-Host "Target: E:\1C_Infrastructure\AI\Ollama" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 1. ОСТАНОВИТЬ СЛУЖБУ И ПРОЦЕССЫ
# ============================================
Write-Host "[1/8] Остановка службы Ollama..." -ForegroundColor Yellow
try {
    Stop-Service ollama -Force -ErrorAction SilentlyContinue
    Get-Process ollama -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "✓ Служба остановлена" -ForegroundColor Green
} catch {
    Write-Host "⚠ Служба не найдена или уже остановлена" -ForegroundColor Gray
}

# ============================================
# 2. УДАЛИТЬ ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ
# ============================================
Write-Host "[2/8] Очистка переменных окружения..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", $null, "User")
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", $null, "Machine")
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", $null, "User")
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", $null, "Machine")
$env:OLLAMA_MODELS = $null
$env:OLLAMA_HOST = $null
Write-Host "✓ Переменные очищены" -ForegroundColor Green

# ============================================
# 3. УДАЛИТЬ СТАРЫЕ ФАЙЛЫ
# ============================================
Write-Host "[3/8] Удаление старых файлов..." -ForegroundColor Yellow

# Бинарники (стандартное расположение)
$oldBinPath = "$env:LOCALAPPDATA\Programs\Ollama"
if (Test-Path $oldBinPath) {
    Remove-Item $oldBinPath -Recurse -Force
    Write-Host "  ✓ Удалено: $oldBinPath" -ForegroundColor Gray
}

# Данные пользователя (модели, конфиги)
$oldDataPath = "$env:USERPROFILE\.ollama"
if (Test-Path $oldDataPath) {
    Remove-Item $oldDataPath -Recurse -Force
    Write-Host "  ✓ Удалено: $oldDataPath" -ForegroundColor Gray
}

# Кэш и логи
$cachePaths = @(
    "$env:LOCALAPPDATA\Ollama",
    "$env:TEMP\ollama"
)
foreach ($path in $cachePaths) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force
        Write-Host "  ✓ Удалено: $path" -ForegroundColor Gray
    }
}

# ============================================
# 4. ОЧИСТКА РЕЕСТРА
# ============================================
Write-Host "[4/8] Очистка реестра..." -ForegroundColor Yellow
$regPaths = @(
    "HKCU:\Software\Ollama",
    "HKLM:\Software\Ollama",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Ollama"
)
foreach ($path in $regPaths) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Удалено: $path" -ForegroundColor Gray
    }
}

# ============================================
# 5. СОЗДАТЬ НОВУЮ СТРУКТУРУ КАТАЛОГОВ
# ============================================
Write-Host "[5/8] Создание новой структуры..." -ForegroundColor Yellow
$ollamaRoot = "E:\1C_Infrastructure\AI\Ollama"
$directories = @(
    "$ollamaRoot\bin",
    "$ollamaRoot\models",
    "$ollamaRoot\logs",
    "$ollamaRoot\config"
)
foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Write-Host "✓ Структура создана: $ollamaRoot" -ForegroundColor Green

# ============================================
# 6. СКАЧАТЬ И УСТАНОВИТЬ БИНАРНИКИ
# ============================================
Write-Host "[6/8] Скачивание бинарников..." -ForegroundColor Yellow
$version = "v0.5.12"  # Проверьте актуальную на github.com/ollama/ollama/releases
$downloadUrl = "https://github.com/ollama/ollama/releases/download/$version/ollama-windows-amd64.zip"
$zipPath = "$env:TEMP\ollama-$version.zip"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath "$ollamaRoot\bin" -Force
    Remove-Item $zipPath -Force
    Write-Host "✓ Бинарники установлены" -ForegroundColor Green
} catch {
    Write-Host "✗ Ошибка загрузки: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# 7. НАСТРОИТЬ ПЕРЕМЕННЫЕ И СЛУЖБУ
# ============================================
Write-Host "[7/8] Настройка переменных и службы..." -ForegroundColor Yellow

# Переменная окружения (путь к моделям)
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", "$ollamaRoot\models", "User")
$env:OLLAMA_MODELS = "$ollamaRoot\models"

# Скрипт запуска службы
$startScript = @"
`$env:OLLAMA_MODELS = "E:\1C_Infrastructure\AI\Ollama\models"
`$env:OLLAMA_HOST = "0.0.0.0:11434"
`$logFile = "E:\1C_Infrastructure\AI\Ollama\logs\ollama-`(Get-Date -Format 'yyyyMMdd').log"

Start-Transcript -Path `$logFile -Append
Write-Host "Starting Ollama service...`n"
& "E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe" serve
Stop-Transcript
"@
$startScript | Out-File "$ollamaRoot\start-ollama.ps1" -Encoding UTF8

# Создать задачу в Task Scheduler (автозапуск при входе)
$taskName = "Ollama Service"
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"E:\1C_Infrastructure\AI\Ollama\start-ollama.ps1`""
$trigger = New-ScheduledTaskTrigger -AtLogon
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType S4U -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
    -Principal $principal -Force | Out-Null

Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 3
Write-Host "✓ Служба настроена и запущена" -ForegroundColor Green

# ============================================
# 8. ПРОВЕРКА И ТЕСТ
# ============================================
Write-Host "[8/8] Проверка установки..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $version = & "$ollamaRoot\bin\ollama.exe" --version
    Write-Host "✓ Версия: $version" -ForegroundColor Green
} catch {
    Write-Host "✗ Ошибка проверки версии: $_" -ForegroundColor Red
}

# Подождать, пока служба полностью запустится
Write-Host "⏳ Ожидание запуска службы (10 сек)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/version" -UseBasicParsing
    Write-Host "✓ API доступен: $($response.Content)" -ForegroundColor Green
} catch {
    Write-Host "⚠ API ещё не доступен (службе нужно время)" -ForegroundColor Yellow
}

# ============================================
# ИТОГИ
# ============================================
Write-Host ""
Write-Host "=== УСТАНОВКА ЗАВЕРШЕНА ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 Путь установки: $ollamaRoot" -ForegroundColor White
Write-Host "📦 Модели будут в: $ollamaRoot\models" -ForegroundColor White
Write-Host "📝 Логи: $ollamaRoot\logs" -ForegroundColor White
Write-Host ""
Write-Host "📥 Для установки модели выполните:" -ForegroundColor Yellow
Write-Host "   & `"E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe`" pull qwen2.5:7b" -ForegroundColor Cyan
Write-Host ""
Write-Host " Для проверки:" -ForegroundColor Yellow
Write-Host "   & `"E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe`" list" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  Перезагрузите компьютер для применения всех изменений!" -ForegroundColor Red
Write-Host ""