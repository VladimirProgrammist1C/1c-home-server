<#
.SYNOPSIS
    Бэкап конфигураций инфраструктуры (без PostgreSQL)
#>

# === НАСТРОЙКИ ===
$DatePart = Get-Date -Format "yyyy-MM-dd"
$DateStamp = "$DatePart-stable"

$ProjectRoot = "E:\1C_Infrastructure"
$BackupRoot = "E:\_BACKUPS"
$ProjectBackup = "$ProjectRoot\Backups"

$TodayBackup = "$BackupRoot\$DateStamp"
$TodayProjectBackup = "$ProjectBackup\$DateStamp"

Write-Host "Backup configurations: $DateStamp" -ForegroundColor Cyan

# Создаём папки
New-Item -Path $TodayBackup, $TodayProjectBackup -ItemType Directory -Force | Out-Null

# Файлы для бэкапа
$Files = @(
    "docker-compose.yml",
    ".env",
    "README.md",
    "COMMANDS.md",
    "monitoring/prometheus.yml",
    "monitoring/prometheus/alerts.yml",
    "monitoring/blackbox.yml",
    "Docs/infrastructure-guide.md",
    "Docs/TIMING.md",
    "Docs/SUMMARY.md"
)

foreach ($File in $Files) {
    $Src = Join-Path $ProjectRoot $File
    if (Test-Path $Src) {
        # Создаём подпапку в основном бэкапе
        $DestDir1 = Split-Path "$TodayBackup\$File" -Parent
        if ($DestDir1 -and !(Test-Path $DestDir1)) {
            New-Item -Path $DestDir1 -ItemType Directory -Force | Out-Null
        }
        Copy-Item $Src -Destination "$TodayBackup\$File" -Force
        
        # Создаём подпапку в проектном бэкапе
        $DestDir2 = Split-Path "$TodayProjectBackup\$File" -Parent
        if ($DestDir2 -and !(Test-Path $DestDir2)) {
            New-Item -Path $DestDir2 -ItemType Directory -Force | Out-Null
        }
        Copy-Item $Src -Destination "$TodayProjectBackup\$File" -Force
        
        Write-Host "   OK: $File" -ForegroundColor Green
    }
}

Write-Host "`nBackup completed!" -ForegroundColor Green
Write-Host "   $TodayBackup"
Write-Host "   $TodayProjectBackup"