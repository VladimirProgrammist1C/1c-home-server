# ==============================================================================
# backup-postgres-host.ps1
# Бэкап PostgreSQL с хоста (версия 16) перед миграцией на Docker
# Версия: 1.5 (исправлена передача пароля)
# ==============================================================================

#================= НАСТРОЙКИ =================
$pgDumpPath = "E:\DEV_LOCAL\INSTALLED\PostgreSQL 1C\16\bin\pg_dump.exe"
$pgDumpAllPath = "E:\DEV_LOCAL\INSTALLED\PostgreSQL 1C\16\bin\pg_dumpall.exe"
$psqlPath = "E:\DEV_LOCAL\INSTALLED\PostgreSQL 1C\16\bin\psql.exe"
$backupRoot = "E:\_BACKUPS\PostgreSQL"
$pgHost = "localhost"
$pgPort = "5432"
$pgUser = "postgres"
$pgPassword = "123"
$pgDatabase = "DemoHRMCorpDemo_bot"
#=============================================

Write-Host "=== БЕЗОПАСНЫЙ БЕКАП POSTGRESQL ===" -ForegroundColor Cyan
Write-Host ""

# 1. Проверка утилит
Write-Host "Проверка утилит..." -ForegroundColor Yellow
if (-not (Test-Path $pgDumpPath)) {
    Write-Host "ERROR: pg_dump not found: $pgDumpPath" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Utilities found" -ForegroundColor Green
Write-Host ""

# 2. Создание папки для бэкапа
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupPath = "$backupRoot\host_v16_backup_$timestamp"
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
Write-Host "Backup folder: $backupPath" -ForegroundColor Yellow
Write-Host ""

# 3. Проверка подключения через psql (надёжнее!)
Write-Host "Checking PostgreSQL connection..." -ForegroundColor Yellow
$checkResult = & $psqlPath -U $pgUser -h $pgHost -p $pgPort -d $pgDatabase -c "SELECT 1;" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: PostgreSQL available (${pgHost}:${pgPort})" -ForegroundColor Green
} else {
    Write-Host "ERROR: Cannot connect to PostgreSQL" -ForegroundColor Red
    Write-Host "   Output: $checkResult" -ForegroundColor Gray
    exit 1
}
Write-Host ""

# 4. Создание бэкапа (.dump формат)
Write-Host "Creating backup of database '$pgDatabase'..." -ForegroundColor Cyan
$dumpFile = "$backupPath\$($pgDatabase)_backup.dump"
$env:PGPASSWORD = $pgPassword
& $pgDumpPath -U $pgUser -h $pgHost -p $pgPort -d $pgDatabase -F c -f $dumpFile
$dumpExitCode = $LASTEXITCODE
$env:PGPASSWORD = $null

if ($dumpExitCode -eq 0) {
    $size = (Get-Item $dumpFile).Length / 1MB
    Write-Host "OK: Backup created: $dumpFile" -ForegroundColor Green
    Write-Host "   Size: $([math]::Round($size, 2)) MB" -ForegroundColor Gray
} else {
    Write-Host "ERROR: Backup creation failed!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 5. Полный бэкап (.sql формат)
Write-Host "Creating full backup of all databases..." -ForegroundColor Cyan
$sqlFile = "$backupPath\full_backup.sql"
$env:PGPASSWORD = $pgPassword
& $pgDumpAllPath -U $pgUser -h $pgHost -p $pgPort > $sqlFile
$fullExitCode = $LASTEXITCODE
$env:PGPASSWORD = $null

if ($fullExitCode -eq 0) {
    $size = (Get-Item $sqlFile).Length / 1MB
    Write-Host "OK: Full backup created: $sqlFile" -ForegroundColor Green
    Write-Host "   Size: $([math]::Round($size, 2)) MB" -ForegroundColor Gray
} else {
    Write-Host "WARNING: Full backup not created" -ForegroundColor Yellow
}
Write-Host ""

# 6. Итог
Write-Host "=== BACKUP COMPLETED ===" -ForegroundColor Cyan
Write-Host "Path: $backupPath" -ForegroundColor Green
Write-Host ""