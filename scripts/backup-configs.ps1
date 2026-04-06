<#
.SYNOPSIS
Бэкап конфигураций инфраструктуры 1C Home Server
.DESCRIPTION
Создаёт резервные копии конфигурационных файлов в двух локациях.
Поддерживает несколько бэкапов в день (не перезаписывает существующие).
.NOTES
Автор: Vladimir Bessonov
Версия: 2.2
Дата: 04.04.2026
#>

# ========================================
# 1. НАСТРОЙКИ
# ========================================
$DatePart = Get-Date -Format "yyyy-MM-dd"
$TimePart = Get-Date -Format "HHmmss"
$DateStamp = "$DatePart-stable-$TimePart"
$ProjectRoot = "E:\1C_Infrastructure"
$BackupRoot = "E:\_BACKUPS"
$ProjectBackup = "$ProjectRoot\Backups"
$TodayBackup = "$BackupRoot\$DateStamp"
$TodayProjectBackup = "$ProjectBackup\$DateStamp"

# Файлы для бэкапа (относительно $ProjectRoot)
$Files = @(
    "docker-compose.yml",
    ".env",
    ".env.example",
    ".gitignore",
    "README.md",
    "Docs/infrastructure-guide.md",
    "Docs/COMMANDS.md",
    "_Private/TIMING.md",
    "_Private/SUMMARY.md",
    "monitoring/prometheus.yml",
    "monitoring/prometheus/alerts.yml",
    "monitoring/blackbox.yml",
    "Scripts/backup-configs.ps1"
)

# ========================================
# 2. ФУНКЦИИ
# ========================================

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
}

function Write-Success {
    param([string]$Text)
    Write-Host "   ✅ $Text" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Text)
    Write-Host "   ⚠️  $Text" -ForegroundColor Yellow
}

function Copy-BackupFile {
    param(
        [string]$SourceFile,
        [string]$DestDir1,
        [string]$DestDir2
    )
    
    $Src = Join-Path $ProjectRoot $SourceFile
    
    if (Test-Path $Src) {
        # Копия 1: E:\_BACKUPS
        $Dest1 = Join-Path $DestDir1 $SourceFile
        $DestDir1_Parent = Split-Path $Dest1 -Parent
        if ($DestDir1_Parent -and !(Test-Path $DestDir1_Parent)) {
            New-Item -Path $DestDir1_Parent -ItemType Directory -Force | Out-Null
        }
        Copy-Item $Src -Destination $Dest1 -Force
        
        # Копия 2: E:\1C_Infrastructure\Backups
        $Dest2 = Join-Path $DestDir2 $SourceFile
        $DestDir2_Parent = Split-Path $Dest2 -Parent
        if ($DestDir2_Parent -and !(Test-Path $DestDir2_Parent)) {
            New-Item -Path $DestDir2_Parent -ItemType Directory -Force | Out-Null
        }
        Copy-Item $Src -Destination $Dest2 -Force
        
        Write-Success "$SourceFile"
        return $true
    }
    else {
        Write-Warning "Не найден: $SourceFile"
        return $false
    }
}

# ========================================
# 3. ПРОВЕРКА СУЩЕСТВУЮЩИХ БЭКАПОВ
# ========================================

# Проверяем, сколько бэкапов уже сделано сегодня
$ExistingBackups1 = Get-ChildItem "$BackupRoot\$DatePart-stable-*" -ErrorAction SilentlyContinue
$ExistingBackups2 = Get-ChildItem "$ProjectBackup\$DatePart-stable-*" -ErrorAction SilentlyContinue
$BackupCount = $ExistingBackups1.Count

if ($BackupCount -gt 0) {
    Write-Host ""
    Write-Host "📊 Найдено существующих бэкапов за сегодня: $BackupCount" -ForegroundColor Yellow
    Write-Host "   Последний: $($ExistingBackups1[-1].Name)" -ForegroundColor Gray
    Write-Host ""
}

# ========================================
# 4. ОСНОВНАЯ ЛОГИКА
# ========================================

Write-Header "Бэкап конфигураций: $DateStamp"

# Создаём папки для бэкапа (с временной меткой)
New-Item -Path $TodayBackup, $TodayProjectBackup -ItemType Directory -Force | Out-Null
Write-Success "Папки бэкапа созданы"

# Счётчики
$TotalFiles = $Files.Count
$CopiedFiles = 0
$SkippedFiles = 0

# Копируем файлы
Write-Host ""
Write-Host "📋 Копирование файлов..." -ForegroundColor Yellow
Write-Host ""

foreach ($File in $Files) {
    if (Copy-BackupFile -SourceFile $File -DestDir1 $TodayBackup -DestDir2 $TodayProjectBackup) {
        $CopiedFiles++
    }
    else {
        $SkippedFiles++
    }
}

# ========================================
# 5. РЕЗУЛЬТАТ
# ========================================

Write-Header "Результат"

# Считаем размер
$Size1 = (Get-ChildItem $TodayBackup -Recurse | Measure-Object -Property Length -Sum).Sum
$SizeKB = [math]::Round($Size1 / 1KB, 2)

Write-Host ""
Write-Host "📁 Путь 1: $TodayBackup" -ForegroundColor Cyan
Write-Host "📁 Путь 2: $TodayProjectBackup" -ForegroundColor Cyan
Write-Host "📊 Размер: $SizeKB KB" -ForegroundColor Cyan
Write-Host "📅 Дата: $DateStamp" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Успешно: $CopiedFiles из $TotalFiles файлов" -ForegroundColor Green

if ($SkippedFiles -gt 0) {
    Write-Host "⚠️  Пропущено: $SkippedFiles файлов" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host " Бэкап завершён!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

# ========================================
# 6. ПРЕДУПРЕЖДЕНИЕ БЕЗОПАСНОСТИ
# ========================================
Write-Host "⚠️  ВАЖНО: Бэкап содержит чувствительные данные!" -ForegroundColor Red
Write-Host "   - .env (пароли от СУБД, Grafana, pgAdmin)" -ForegroundColor Yellow
Write-Host "   - _Private/TIMING.md (приватный опыт)" -ForegroundColor Yellow
Write-Host "   - _Private/SUMMARY.md (приватный опыт)" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Не передавайте эти файлы третьим лицам!" -ForegroundColor Red
Write-Host "   Не коммитьте .env, TIMING.md, SUMMARY.md в Git!" -ForegroundColor Red
Write-Host ""

# ========================================
# 7. СПИСОК ВСЕХ БЭКАПОВ
# ========================================
Write-Host "📦 Все бэкапы за сегодня:" -ForegroundColor Cyan
Get-ChildItem "$BackupRoot\$DatePart-stable-*" | 
    Select-Object Name, @{Name='SizeKB';Expression={[math]::Round($_.Length / 1KB, 2)}}, LastWriteTime | 
    Format-Table -AutoSize
Write-Host ""