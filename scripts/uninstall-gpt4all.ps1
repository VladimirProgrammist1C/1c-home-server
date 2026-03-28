# E:\1C_Infrastructure\scripts\uninstall-gpt4all.ps1
$ErrorActionPreference = "Stop"
Write-Host "=== УДАЛЕНИЕ GPT4ALL ===" -ForegroundColor Cyan

# 1. Остановить процессы
Write-Host "`n[1/4] Остановка процессов..." -ForegroundColor Yellow
Get-Process -Name "*gpt4all*", "*nomic*" -ErrorAction SilentlyContinue | Stop-Process -Force

# 2. Удалить файлы программы
$installPaths = @(
    "$env:LOCALAPPDATA\Programs\gpt4all",
    "$env:PROGRAMFILES\gpt4all",
    "$env:PROGRAMFILES (x86)\gpt4all"
)
foreach ($path in $installPaths) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force
        Write-Host "✓ Удалено: $path" -ForegroundColor Green
    }
}

# 3. Удалить данные пользователя (модели, конфиги)
# ⚠️ Это освободит много места (10-50 ГБ)
$userDataPaths = @(
    "$env:USERPROFILE\gpt4all",
    "$env:USERPROFILE\Nomic AI",
    "$env:LOCALAPPDATA\gpt4all",
    "$env:APPDATA\gpt4all"
)
foreach ($path in $userDataPaths) {
    if (Test-Path $path) {
        $size = (Get-ChildItem $path -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB
        Write-Host "⚠️  Удаляется: $path (~$([math]::Round($size,2)) ГБ)" -ForegroundColor Yellow
        Remove-Item $path -Recurse -Force
    }
}

# 4. Очистить переменные окружения
[Environment]::SetEnvironmentVariable("GPT4ALL_MODEL_DIR", $null, "User")

# 5. Очистить реестр
$regPaths = @(
    "HKCU:\Software\Nomic AI",
    "HKCU:\Software\gpt4all"
)
foreach ($path in $regPaths) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n✓ GPT4All полностью удалён" -ForegroundColor Green