<#
.SYNOPSIS
    Интерактивный полный бэкап инфраструктуры 1С с логированием.
.DESCRIPTION
    Четыре этапа с интерактивным выбором:
    1. Конфиги проекта (robocopy)
    2. Не-1С базы PostgreSQL (pg_dump + gzip)
    3. Конфиги PostgreSQL (postgresql.conf, pg_hba.conf)
    4. Docker volumes и bind mounts (tar.gz)
    
    1С-ные базы бэкапятся через Обновлятор 1С!
.PARAMETER Test
    Режим прогона - показать, что будет сохранено, без реального бэкапа.
.EXAMPLE
    & "E:\1C_Infrastructure\_Private\backup-scripts\full-backup-rus.ps1" -Test
    & "E:\1C_Infrastructure\_Private\backup-scripts\full-backup-rus.ps1"
#>

param([switch]$Test)

# =============================================================================
# НАСТРОЙКИ
# =============================================================================
$ProjectRoot = "E:\1C_Infrastructure"
$BackupRoot = "D:\Docker_Backups"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$BackupFolder = Join-Path $BackupRoot "Backup_$Timestamp"
$ContainerName = "postgres-1c"
$ExcludeDirs = @("_Private", "AI", "Git", ".git")

# Создаём папку бэкапа и файл лога
New-Item -ItemType Directory -Force -Path $BackupFolder | Out-Null
$LogFile = Join-Path $BackupFolder "backup.log"

# Список volumes и bind mounts для бэкапа
$AllVolumes = @(
    @{ Name = "1c_infrastructure_postgres-data";        Service = "PostgreSQL" }
    @{ Name = "1c_infrastructure_pgadmin-data";         Service = "pgAdmin" }
    @{ Name = "1c_infrastructure_grafana-data";         Service = "Grafana" }
    @{ Name = "1c_infrastructure_prometheus-data";      Service = "Prometheus" }
    @{ Name = "1c_infrastructure_portainer-data";       Service = "Portainer" }
    @{ Name = "1c_infrastructure_gitea-data";           Service = "Gitea (репозитории)" }
    @{ Name = "1c_infrastructure_vocechat-notify-data"; Service = "VoceChat-Notify" }
    @{ Name = "1c_infrastructure_analytics-data";       Service = "Аналитика" }
    @{ Name = "bind:vocechat";                          Service = "VoceChat (семейный)"; Type = "bind"; Source = "E:\vocechat\data" }
)

# Хранение результатов
$script:Results = @{
    Project     = $null
    Databases   = [System.Collections.ArrayList]::new()
    PgConfigs   = $null
    Volumes     = [System.Collections.ArrayList]::new()
    StartTime   = Get-Date
}

# =============================================================================
# ЛОГИРОВАНИЕ
# =============================================================================
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Пишем в файл (UTF-8)
    Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
    
    # Выводим в консоль с цветом
    $color = switch ($Level) {
        "INFO"    { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        "TEST"    { "Magenta" }
        default   { "White" }
    }
    Write-Host $logEntry -ForegroundColor $color
}

# =============================================================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# =============================================================================
function Write-Header {
    param([string]$Text, [string]$Color = "Cyan")
    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host " $Text" -ForegroundColor $Color
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Log "=== $Text ===" "INFO"
}

function Get-VolumeSize {
    param([string]$VolumeName)
    try {
        $sizeOutput = docker run --rm -v "${VolumeName}:/data" alpine du -sb /data 2>$null
        $bytes = ($sizeOutput -split '\s+')[0]
        if ([long]::TryParse($bytes, [ref]$null)) {
            return [long]$bytes
        }
    } catch {}
    return 0
}

function Format-Size {
    param([long]$Bytes)
    if ($Bytes -gt 1GB) { return "$([math]::Round($Bytes/1GB, 2)) ГБ" }
    if ($Bytes -gt 1MB) { return "$([math]::Round($Bytes/1MB, 2)) МБ" }
    if ($Bytes -gt 1KB) { return "$([math]::Round($Bytes/1KB, 2)) КБ" }
    return "$Bytes Б"
}

function Ask-YesNo {
    param([string]$Question, [string]$Default = "Y")
    $prompt = if ($Default -eq "Y") { "(Y/N)" } else { "(y/N)" }
    $response = Read-Host "$Question $prompt"
    if ([string]::IsNullOrWhiteSpace($response)) { $response = $Default }
    return ($response -eq 'Y' -or $response -eq 'y')
}

function Test-GzipIntegrity {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $false }
    $parentFolder = Split-Path $FilePath -Parent
    $fileName = Split-Path $FilePath -Leaf
    
    # Используем Start-Process вместо docker run ... 2>&1
    $errorLog = Join-Path $env:TEMP "gzip_test_error.log"
    $process = Start-Process -FilePath "docker" `
        -ArgumentList "run", "--rm", "-v", "${parentFolder}:/backup", "alpine", "gzip", "-t", "/backup/$fileName" `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardError $errorLog
    
    # Удаляем временный лог
    if (Test-Path $errorLog) {
        Remove-Item $errorLog -Force -ErrorAction SilentlyContinue
    }
    
    return ($process.ExitCode -eq 0)
}

# =============================================================================
# ЭТАП 1: КОНФИГИ ПРОЕКТА
# =============================================================================
function Backup-ProjectConfigs {
    Write-Header "ЭТАП 1: КОНФИГИ ПРОЕКТА" "Cyan"
    Write-Log "Начало копирования конфигов проекта" "INFO"
    
    Write-Host "ЧТО ДЕЛАЕТ:" -ForegroundColor Yellow
    Write-Host "  Копирует все файлы проекта (docker-compose.yml, .env, monitoring/, scripts/)" -ForegroundColor White
    Write-Host "  из $ProjectRoot в папку бэкапа с помощью robocopy." -ForegroundColor White
    Write-Host ""
    Write-Host "ОЖИДАЕМЫЙ РЕЗУЛЬТАТ:" -ForegroundColor Yellow
    Write-Host "  Полная копия структуры проекта (кроме _Private, AI, Git, .git)" -ForegroundColor White
    Write-Host "  Можно восстановить на любую машину через robocopy." -ForegroundColor White
    Write-Host ""

    if (-not (Test-Path $ProjectRoot)) {
        Write-Log "Папка проекта не найдена: $ProjectRoot" "ERROR"
        return $false
    }

    # Подсчёт файлов
    $allFiles = Get-ChildItem $ProjectRoot -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
        $exclude = $false
        foreach ($ex in $ExcludeDirs) {
            if ($_.FullName -like "*\$ex\*" -or $_.FullName -like "*\$ex") {
                $exclude = $true; break
            }
        }
        -not $exclude -and -not $_.PSIsContainer
    }
    $totalFiles = $allFiles.Count
    $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum

    Write-Host "БУДЕТ СОХРАНЕНО:" -ForegroundColor Yellow
    Write-Host "  Источник: $ProjectRoot" -ForegroundColor White
    Write-Host "  Файлов: $totalFiles" -ForegroundColor White
    Write-Host "  Размер: $(Format-Size $totalSize)" -ForegroundColor Green
    Write-Host "  Исключено: $($ExcludeDirs -join ', ')" -ForegroundColor White
    Write-Host ""

    if ($Test) {
        Write-Log "[ТЕСТ] Режим прогона — ничего не копируется" "TEST"
        $script:Results.Project = @{
            Success = $true
            Folder  = $null
            Size    = $totalSize
            Files   = $totalFiles
        }
        return $true
    }

    $destFolder = Join-Path $BackupFolder "Project"
    New-Item -ItemType Directory -Force -Path $destFolder | Out-Null

    $robocopyArgs = @($ProjectRoot, $destFolder, "/E", "/Z", "/R:3", "/W:5", "/XD") + $ExcludeDirs
    
    Write-Log "Запуск robocopy..." "INFO"
    Write-Progress -Activity "Копирование файлов проекта" -Status "Подготовка..." -PercentComplete 0
    
    $process = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -NoNewWindow -Wait -PassThru
    
    Write-Progress -Activity "Копирование файлов проекта" -Completed
    
    if ($process.ExitCode -lt 8) {
        Write-Log "Конфиги проекта скопированы (код: $($process.ExitCode))" "SUCCESS"
        $script:Results.Project = @{
            Success = $true
            Folder  = $destFolder
            Size    = $totalSize
            Files   = $totalFiles
        }
        return $true
    } else {
        Write-Log "Robocopy завершился с кодом: $($process.ExitCode)" "ERROR"
        return $false
    }
}

# =============================================================================
# ЭТАП 2: НЕ-1С БАЗЫ POSTGRESQL
# =============================================================================
function Backup-Databases {
    Write-Header "ЭТАП 2: НЕ-1С БАЗЫ POSTGRESQL" "Cyan"
    Write-Log "Начало бэкапа не-1С баз данных" "INFO"
    
    Write-Host "ЧТО ДЕЛАЕТ:" -ForegroundColor Yellow
    Write-Host "  Создаёт дампы только для не-1С баз (Gitea, системные и др.)" -ForegroundColor White
    Write-Host "  1С-ные базы бэкапятся через Обновлятор 1С!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "ОЖИДАЕМЫЙ РЕЗУЛЬТАТ:" -ForegroundColor Yellow
    Write-Host "  Отдельный файл .sql.gz для каждой не-1С базы." -ForegroundColor White
    Write-Host ""

    $containerStatus = docker ps --filter "name=$ContainerName" --format "{{.Status}}"
    if (-not $containerStatus) {
        Write-Log "Контейнер $ContainerName не запущен" "ERROR"
        return $false
    }

    # ============================================
    # ПРОВЕРКА WHITELIST ФАЙЛА
    # ============================================
    $whitelistPath = Join-Path $PSScriptRoot "non-1c-databases.txt"
    $useWhitelist = $false
    $whitelistDatabases = @()

    if (Test-Path $whitelistPath) {
        $whitelistDatabases = Get-Content $whitelistPath -Encoding UTF8 | 
            Where-Object { $_ -and $_.Trim() -and $_.Trim() -notlike "#*" } |
            ForEach-Object { $_.Trim() }
        
        if ($whitelistDatabases.Count -gt 0) {
            Write-Log "Whitelist найден: $($whitelistDatabases.Count) баз" "SUCCESS"
            Write-Host "[OK] Найден whitelist: $($whitelistDatabases.Count) баз" -ForegroundColor Green
            Write-Host "     Файл: $whitelistPath" -ForegroundColor Gray
            $useWhitelist = $true
        } else {
            Write-Log "Whitelist пустой" "WARNING"
        }
    } else {
        Write-Log "Whitelist не найден: $whitelistPath" "WARNING"
    }

    # Если whitelist не найден — предупреждение и выбор действия
    if (-not $useWhitelist) {
        Write-Host ""
        Write-Host "════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host " ⚠️  ВНИМАНИЕ: Файл whitelist не найден!" -ForegroundColor Yellow
        Write-Host "════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   Путь: $whitelistPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   Без этого файла скрипт не может определить," -ForegroundColor White
        Write-Host "   какие базы являются 1С-ными, а какие нет." -ForegroundColor White
        Write-Host ""
        Write-Host "   РЕКОМЕНДАЦИЯ: Создайте файл non-1c-databases.txt" -ForegroundColor Cyan
        Write-Host "   со списком не-1С баз (по одной на строку)." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   Пример содержимого файла:" -ForegroundColor Gray
        Write-Host "   # Не-1С базы для бэкапа" -ForegroundColor DarkGray
        Write-Host "   postgres" -ForegroundColor DarkGray
        Write-Host "   gitea" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   Все базы, НЕ указанные в файле, будут считаться 1С-ными" -ForegroundColor White
        Write-Host "   и пропускаться при бэкапе." -ForegroundColor White
        Write-Host ""
        Write-Host "════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [c] Вернуться в главное меню (рекомендуется)" -ForegroundColor Cyan
        Write-Host "  [q] Завершить скрипт" -ForegroundColor Red
        Write-Host ""
        
        $response = Read-Host "Введите значение"
        
        if ($response -eq 'q' -or $response -eq 'Q' -or $response -eq 'й' -or $response -eq 'Й') {
            Write-Log "Пользователь завершил скрипт из-за отсутствия whitelist" "WARNING"
            Write-Host ""
            Write-Host "[ЗАВЕРШЕНИЕ] Скрипт завершён пользователем" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "[НАЖМИТЕ] Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 0
        }
        
        # Любое другое значение (включая 'c') — возврат в главное меню
        Write-Log "Возврат в главное меню для создания whitelist" "INFO"
        return
    }

    # ============================================
    # ФИЛЬТРУЕМ БАЗЫ
    # ============================================
    $allDbs = docker exec $ContainerName psql -U postgres -t -c "
        SELECT datname FROM pg_database 
        WHERE datistemplate = false 
        ORDER BY datname
    " 2>$null | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

    if ($allDbs.Count -eq 0) {
        Write-Log "Базы не найдены" "WARNING"
        return $false
    }

    $non1cDbs = [System.Collections.ArrayList]::new()

    Write-Log "Используем whitelist: $($whitelistDatabases -join ', ')" "INFO"
    
    foreach ($dbName in $whitelistDatabases) {
        if ($dbName -in $allDbs) {
            $sizeResult = docker exec $ContainerName psql -U postgres -t -c "SELECT pg_database_size('$dbName')" 2>$null
            $sizeBytes = $sizeResult.Trim() -replace '\s', ''
            
            $sizeLong = 0
            [long]::TryParse($sizeBytes, [ref]$sizeLong) | Out-Null
            
            $dbObj = @{
                Index    = $non1cDbs.Count + 1
                Name     = $dbName
                Size     = $sizeLong
                SizeText = Format-Size $sizeLong
                BackedUp = $false
                Source   = "whitelist"
            }
            [void]$non1cDbs.Add($dbObj)
            
            Write-Log "  ✓ Добавлена из whitelist: $dbName ($(Format-Size $sizeLong))" "INFO"
        } else {
            Write-Log "  ⚠️  База из whitelist не найдена в СУБД: $dbName" "WARNING"
        }
    }
    
    if ($non1cDbs.Count -eq 0) {
        Write-Log "Ни одна база из whitelist не найдена в СУБД" "ERROR"
        Write-Host "[ОШИБКА] Ни одна база из whitelist не найдена!" -ForegroundColor Red
        Write-Host "  Проверьте имена баз в файле: $whitelistPath" -ForegroundColor Gray
        return $false
    }

    Write-Log "Найдено $($non1cDbs.Count) не-1С база(ы)" "SUCCESS"

    $backupDbFolder = Join-Path $BackupFolder "Databases"
    if (-not $Test) {
        New-Item -ItemType Directory -Force -Path $backupDbFolder | Out-Null
    }

    # ============================================
    # МЕНЮ ВЫБОРА БАЗ
    # ============================================
    while ($true) {
        Write-Host "ВЫБЕРИТЕ НЕ-1С БАЗУ ДЛЯ СОХРАНЕНИЯ:" -ForegroundColor Yellow
        Write-Host "  (номер, a=all, r=remaining, c=continue, x=summary)" -ForegroundColor White
        Write-Host ""

        $remaining = $non1cDbs | Where-Object { -not $_.BackedUp }

        for ($i = 0; $i -lt $non1cDbs.Count; $i++) {
            $db = $non1cDbs[$i]
            $status = if ($db.BackedUp) { "[ВЫПОЛНЕНО]" } else { "[$($db.Index)]" }
            $color = if ($db.BackedUp) { "DarkGray" } else { "White" }
            $source = if ($db.Source -eq "whitelist") { " [W]" } else { "" }
            Write-Host "  $status $($db.Name)$source ($($db.SizeText))" -ForegroundColor $color
        }

        Write-Host ""
        Write-Host "  a  - сохранить все не-1С базы" -ForegroundColor Cyan
        if ($remaining.Count -gt 1) {
            Write-Host "  r  - сохранить оставшиеся ($($remaining.Count) баз)" -ForegroundColor Cyan
        }
        Write-Host "  c  - вернуться в главное меню" -ForegroundColor Cyan
        Write-Host "  x  - показать итоги и завершить" -ForegroundColor Green
        Write-Host ""
        Write-Host "  [W] = база из whitelist" -ForegroundColor Gray
        Write-Host ""

        $selection = Read-Host "Введите значение"

        if ($selection -eq 'c' -or $selection -eq 'C') { $selection = 'continue' }
        elseif ($selection -eq 'r' -or $selection -eq 'R') { $selection = 'remaining' }
        elseif ($selection -eq 'a' -or $selection -eq 'A') { $selection = 'all' }
        elseif ($selection -eq 'x' -or $selection -eq 'X') { $selection = 'summary' }

        if ($selection -eq 'summary' -or $selection -eq 'Summary' -or $selection -eq 'SUMMARY') {
            Write-Log "Пользователь запросил итоги" "INFO"
            Show-Summary
            Write-Host ""
            Write-Host "[НАЖМИТЕ] Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 0
        }
        elseif ($selection -eq 'continue' -or $selection -eq 'Continue' -or $selection -eq 'CONTINUE') {
            Write-Log "Возврат в главное меню" "INFO"
            return
        }
        elseif ($selection -eq 'all' -or $selection -eq 'All' -or $selection -eq 'ALL') {
            Write-Log "Сохранение всех не-1С баз" "INFO"
            $totalDbs = $non1cDbs.Count
            $currentDb = 0
            foreach ($db in $non1cDbs) {
                if (-not $db.BackedUp) {
                    $currentDb++
                    Write-Progress -Activity "Бэкап не-1С баз" -Status "База $currentDb из ${totalDbs}: $($db.Name)" -PercentComplete (($currentDb / $totalDbs) * 100)
                    Backup-SingleDatabase -Db $db -DestFolder $backupDbFolder
                }
            }
            Write-Progress -Activity "Бэкап не-1С баз" -Completed
            Write-Log "Все не-1С базы сохранены" "SUCCESS"
            return
        }
        elseif ($selection -eq 'remaining' -or $selection -eq 'Remaining') {
            Write-Log "Сохранение оставшихся не-1С баз: $($remaining.Count)" "INFO"
            $totalRemaining = $remaining.Count
            $currentDb = 0
            foreach ($db in $remaining) {
                $currentDb++
                Write-Progress -Activity "Бэкап оставшихся не-1С баз" -Status "База $currentDb из ${totalRemaining}: $($db.Name)" -PercentComplete (($currentDb / $totalRemaining) * 100)
                Backup-SingleDatabase -Db $db -DestFolder $backupDbFolder
            }
            Write-Progress -Activity "Бэкап оставшихся не-1С баз" -Completed
            Write-Log "Все оставшиеся не-1С базы сохранены" "SUCCESS"
            return
        }
        else {
            $idx = 0
            if ([int]::TryParse($selection, [ref]$idx)) {
                $db = $non1cDbs | Where-Object { $_.Index -eq $idx }
                if ($db) {
                    if ($db.BackedUp) {
                        Write-Log "База '$($db.Name)' уже сохранена" "WARNING"
                    } else {
                        Write-Progress -Activity "Бэкап не-1С базы" -Status "Сохранение: $($db.Name)" -PercentComplete 0
                        Backup-SingleDatabase -Db $db -DestFolder $backupDbFolder
                        Write-Progress -Activity "Бэкап не-1С базы" -Completed
                    }
                } else {
                    Write-Log "Неверный номер: $idx" "ERROR"
                }
            } else {
                Write-Log "Неверный ввод: $selection" "ERROR"
            }
        }
        Write-Host ""
    }
}

function Backup-SingleDatabase {
    param($Db, $DestFolder)

    Write-Host ""
    Write-Log "Начало сохранения базы: $($Db.Name) ($($Db.SizeText))" "INFO"
    Write-Host "  Сохранение: $($Db.Name) ($($Db.SizeText))..." -ForegroundColor Cyan

    $tempFile = Join-Path $DestFolder "temp_$($Db.Name).sql"
    $gzFile = Join-Path $DestFolder "$($Db.Name).sql.gz"

    if ($Test) {
        Write-Log "[ТЕСТ] Будет сохранено в $gzFile" "TEST"
        $Db.BackedUp = $true
        $Db.BackupSize = $Db.Size
        $Db.BackupFile = $gzFile
        
        $alreadyAdded = $script:Results.Databases | Where-Object { $_.Name -eq $Db.Name }
        if (-not $alreadyAdded) {
            [void]$script:Results.Databases.Add($Db)
        }
        return
    }

    $startTime = Get-Date

    try {
        # ШАГ 1: Создаём дамп
        Write-Log "Создание дампа базы: $($Db.Name)" "INFO"
        Write-Progress -Activity "Бэкап базы $($Db.Name)" -Status "Создание дампа..." -PercentComplete 0
        
        docker exec $ContainerName pg_dump -U postgres $Db.Name > $tempFile 2>$null
        
        if (-not (Test-Path $tempFile)) {
            Write-Log "Файл дампа не создан: $tempFile" "ERROR"
            Write-Progress -Activity "Бэкап базы $($Db.Name)" -Completed
            return
        }
        
        $dumpSize = (Get-Item $tempFile).Length
        Write-Log "Дамп создан: $(Format-Size $dumpSize)" "INFO"
        
        if ($dumpSize -lt 100) {
            Write-Log "Дамп слишком мал ($dumpSize байт). Возможно, база пуста или ошибка pg_dump." "WARNING"
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            Write-Progress -Activity "Бэкап базы $($Db.Name)" -Completed
            return
        }
        
        # ШАГ 2: Сжимаем дамп с мониторингом прогресса
        Write-Log "Сжатие дампа (это может занять несколько минут)..." "INFO"
        Write-Progress -Activity "Бэкап базы $($Db.Name)" -Status "Сжатие дампа..." -PercentComplete 50
        
        $gzipJob = Start-Job -ScriptBlock {
            param($DestFolder, $DbName)
            docker run --rm -v "${DestFolder}:/backup" alpine gzip -6 "/backup/temp_${DbName}.sql" 2>&1
        } -ArgumentList $DestFolder, $Db.Name
        
        $lastSize = 0
        $noChangeCount = 0
        
        while ($gzipJob.State -eq 'Running') {
            $tempGzFile = Join-Path $DestFolder "temp_$($Db.Name).sql.gz"
            
            if (Test-Path $tempGzFile) {
                $currentSize = (Get-Item $tempGzFile).Length
                
                $percent = [math]::Round(($currentSize / $dumpSize) * 100, 1)
                Write-Progress -Activity "Бэкап базы $($Db.Name)" `
                    -Status "Сжатие: $(Format-Size $currentSize) из $(Format-Size $dumpSize)" `
                    -PercentComplete $percent `
                    -CurrentOperation "Сжато: $(Format-Size $currentSize)"
                
                if ($currentSize -eq $lastSize) {
                    $noChangeCount++
                    if ($noChangeCount -gt 30) {
                        Write-Log "⚠️  Предупреждение: размер файла не меняется уже 30 секунд" "WARNING"
                    }
                } else {
                    $noChangeCount = 0
                }
                
                $lastSize = $currentSize
            }
            
            Start-Sleep -Seconds 1
        }
        
        $null = Receive-Job -Job $gzipJob
        Remove-Job -Job $gzipJob
        
        $tempGzFile = Join-Path $DestFolder "temp_$($Db.Name).sql.gz"
        
        if (Test-Path $tempGzFile) {
            Move-Item -Path $tempGzFile -Destination $gzFile -Force
            Write-Log "Архив переименован: temp_$($Db.Name).sql.gz → $($Db.Name).sql.gz" "INFO"
        } else {
            Write-Log "Файл архива не создан" "ERROR"
            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
            Write-Progress -Activity "Бэкап базы $($Db.Name)" -Completed
            return
        }
        
        $gzSize = (Get-Item $gzFile).Length
        Write-Log "Архив создан: $(Format-Size $gzSize)" "INFO"
        
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        
        # ШАГ 3: Проверяем целостность
        Write-Log "Проверка целостности архива..." "INFO"
        Write-Progress -Activity "Бэкап базы $($Db.Name)" -Status "Проверка целостности..." -PercentComplete 90
        
        if (Test-GzipIntegrity -FilePath $gzFile) {
            $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 0)
            $compressionRatio = if ($Db.Size -gt 0) { [math]::Round(($Db.Size / $gzSize), 1) } else { 0 }
            Write-Log "База $($Db.Name) сохранена: $(Format-Size $gzSize) (сжатие ${compressionRatio}x, время: ${elapsed}с)" "SUCCESS"
            
            $Db.BackedUp = $true
            $Db.BackupFile = $gzFile
            $Db.BackupSize = $gzSize
            
            $alreadyAdded = $script:Results.Databases | Where-Object { $_.Name -eq $Db.Name }
            if (-not $alreadyAdded) {
                [void]$script:Results.Databases.Add($Db)
            }
        } else {
            Write-Log "Архив повреждён: $($Db.Name)" "ERROR"
            Remove-Item $gzFile -Force -ErrorAction SilentlyContinue
        }
        
        Write-Progress -Activity "Бэкап базы $($Db.Name)" -Completed
    } catch {
        Write-Log "Ошибка при сохранении базы $($Db.Name): $_" "ERROR"
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
        if (Test-Path $gzFile) { Remove-Item $gzFile -Force -ErrorAction SilentlyContinue }
        Write-Progress -Activity "Бэкап базы $($Db.Name)" -Completed
    }
}

# =============================================================================
# ЭТАП 3: КОНФИГИ POSTGRESQL
# =============================================================================
function Backup-PgConfigs {
    Write-Header "ЭТАП 3: КОНФИГИ POSTGRESQL" "Cyan"
    Write-Log "Начало бэкапа конфигов PostgreSQL" "INFO"
    
    Write-Host "ЧТО ДЕЛАЕТ:" -ForegroundColor Yellow
    Write-Host "  Копирует файлы конфигурации PostgreSQL из контейнера:" -ForegroundColor White
    Write-Host "    - postgresql.conf (настройки сервера: shared_buffers, max_connections и т.д.)" -ForegroundColor White
    Write-Host "    - pg_hba.conf (правила аутентификации)" -ForegroundColor White
    Write-Host "    - pg_ident.conf (маппинг имён пользователей)" -ForegroundColor White
    Write-Host "    - PG_VERSION (маркер версии PostgreSQL)" -ForegroundColor White
    Write-Host ""
    Write-Host "ОЖИДАЕМЫЙ РЕЗУЛЬТАТ:" -ForegroundColor Yellow
    Write-Host "  ~20 КБ файлов конфигурации. Критично для восстановления ручной настройки." -ForegroundColor White
    Write-Host "  Позволяет восстановить кастомные настройки PostgreSQL на новом сервере." -ForegroundColor White
    Write-Host ""

    $containerStatus = docker ps --filter "name=$ContainerName" --format "{{.Status}}"
    if (-not $containerStatus) {
        Write-Log "Контейнер $ContainerName не запущен" "ERROR"
        return $false
    }

    $configFiles = @("postgresql.conf", "pg_hba.conf", "pg_ident.conf", "PG_VERSION")
    $configFolder = Join-Path $BackupFolder "PgConfigs"

    if ($Test) {
        Write-Log "[ТЕСТ] Будет сохранено:" "TEST"
        foreach ($cf in $configFiles) {
            Write-Log "  - /var/lib/postgresql/data/$cf" "TEST"
        }
        $script:Results.PgConfigs = @{
            Success = $true
            Folder  = $null
            Files   = $configFiles.Count
            Size    = 20KB
        }
        return $true
    }

    New-Item -ItemType Directory -Force -Path $configFolder | Out-Null

    $successCount = 0
    $totalSize = 0
    $totalFiles = $configFiles.Count
    
    Write-Progress -Activity "Копирование конфигов PostgreSQL" -Status "Подготовка..." -PercentComplete 0
    
    for ($i = 0; $i -lt $configFiles.Count; $i++) {
        $cf = $configFiles[$i]
        $srcPath = "/var/lib/postgresql/data/$cf"
        $dstPath = Join-Path $configFolder $cf
        
        Write-Progress -Activity "Копирование конфигов PostgreSQL" -Status "Копирование $cf..." -PercentComplete (($i / $totalFiles) * 100)
        Write-Log "Копирование $cf..." "INFO"
        
        try {
            docker cp "${ContainerName}:${srcPath}" $dstPath 2>$null
            if (Test-Path $dstPath) {
                $size = (Get-Item $dstPath).Length
                $totalSize += $size
                Write-Log "  OK ($(Format-Size $size))" "SUCCESS"
                $successCount++
            } else {
                Write-Log "  ПРОВАЛ (файл не найден в контейнере)" "WARNING"
            }
        } catch {
            Write-Log "  ОШИБКА: $_" "ERROR"
        }
    }

    Write-Progress -Activity "Копирование конфигов PostgreSQL" -Completed

    if ($successCount -gt 0) {
        Write-Log "Скопировано $successCount из $totalFiles файлов конфигурации ($(Format-Size $totalSize))" "SUCCESS"
        $script:Results.PgConfigs = @{
            Success = $true
            Folder  = $configFolder
            Files   = $successCount
            Size    = $totalSize
        }
        return $true
    } else {
        Write-Log "Файлы конфигурации не скопированы" "ERROR"
        return $false
    }
}

# =============================================================================
# ЭТАП 4: DOCKER VOLUMES И BIND MOUNTS
# =============================================================================
function Backup-Volumes {
    Write-Header "ЭТАП 4: DOCKER VOLUMES И BIND MOUNTS" "Cyan"
    Write-Log "Начало бэкапа Docker volumes и bind mounts" "INFO"
    
    Write-Host "ЧТО ДЕЛАЕТ:" -ForegroundColor Yellow
    Write-Host "  Создаёт tar.gz архив для каждого Docker volume." -ForegroundColor White
    Write-Host "  Bind mounts (например, VoceChat) архивируются напрямую." -ForegroundColor White
    Write-Host "  Содержит ВСЕ данные: базы, конфиги, логи, всё." -ForegroundColor White
    Write-Host ""
    Write-Host "ОЖИДАЕМЫЙ РЕЗУЛЬТАТ:" -ForegroundColor Yellow
    Write-Host "  Побайтовая копия каждого volume." -ForegroundColor White
    Write-Host "  Можно восстановить полное состояние сервиса (не только данные)." -ForegroundColor White
    Write-Host "  ВНИМАНИЕ: Это самый медленный и объёмный этап!" -ForegroundColor Yellow
    Write-Host ""

    $existingVolumes = docker volume ls -q
    $availableVolumes = [System.Collections.ArrayList]::new()

    Write-Progress -Activity "Проверка volumes" -Status "Получение списка..." -PercentComplete 0
    
    foreach ($vol in $AllVolumes) {
        # Обработка bind mounts
        if ($vol.Type -eq "bind") {
            if (Test-Path $vol.Source) {
                $dirSize = (Get-ChildItem $vol.Source -Recurse -File -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum
                
                # Пропускаем пустые bind mounts
                if ($dirSize -lt 1KB) {
                    Write-Log "  $($vol.Service): пропущен (пустой, $(Format-Size $dirSize))" "WARNING"
                    continue
                }
                
                Write-Log "  $($vol.Service) (bind): $(Format-Size $dirSize)" "INFO"
                $volObj = @{
                    Name     = $vol.Name
                    Service  = $vol.Service
                    Size     = $dirSize
                    SizeText = Format-Size $dirSize
                    BackedUp = $false
                    Type     = "bind"
                    Source   = $vol.Source
                }
                [void]$availableVolumes.Add($volObj)
            } else {
                Write-Log "  $($vol.Service): путь не найден ($($vol.Source))" "WARNING"
            }
            continue
        }
        
        # Обработка Docker volumes
        if ($existingVolumes -contains $vol.Name) {
            Write-Progress -Activity "Проверка volumes" -Status "Проверка размера $($vol.Service)..."
            $sizeBytes = Get-VolumeSize -VolumeName $vol.Name
            
            # Пропускаем пустые volumes (< 1 КБ)
            if ($sizeBytes -lt 1KB) {
                Write-Log "  $($vol.Service): пропущен (пустой, $(Format-Size $sizeBytes))" "WARNING"
                continue
            }
            
            Write-Log "  $($vol.Service): $(Format-Size $sizeBytes)" "INFO"
            $volObj = @{
                Name     = $vol.Name
                Service  = $vol.Service
                Size     = $sizeBytes
                SizeText = Format-Size $sizeBytes
                BackedUp = $false
                Type     = "volume"
            }
            [void]$availableVolumes.Add($volObj)
        }
    }

    Write-Progress -Activity "Проверка volumes" -Completed

    if ($availableVolumes.Count -eq 0) {
        Write-Log "Volumes не найдены" "WARNING"
        return $false
    }

    Write-Log "Найдено $($availableVolumes.Count) volume(s)/bind mount(s)" "SUCCESS"

    $backupVolFolder = Join-Path $BackupFolder "Volumes"
    if (-not $Test) {
        New-Item -ItemType Directory -Force -Path $backupVolFolder | Out-Null
    }

    while ($true) {
        Write-Host ""
        Write-Host "ВЫБЕРИТЕ VOLUME ДЛЯ АРХИВАЦИИ:" -ForegroundColor Yellow
        Write-Host "  (номер, a=all, r=remaining, c=continue, x=summary)" -ForegroundColor White
        Write-Host ""

        $remaining = $availableVolumes | Where-Object { -not $_.BackedUp }

        for ($i = 0; $i -lt $availableVolumes.Count; $i++) {
            $vol = $availableVolumes[$i]
            $status = if ($vol.BackedUp) { "[ВЫПОЛНЕНО]" } else { "[$($i+1)]" }
            $color = if ($vol.BackedUp) { "DarkGray" } else { "White" }
            $typeMark = if ($vol.Type -eq "bind") { " [B]" } else { "" }
            Write-Host "  $status $($vol.Service)$typeMark - $($vol.Name) ($($vol.SizeText))" -ForegroundColor $color
        }

        Write-Host ""
        Write-Host "  a  - заархивировать все" -ForegroundColor Cyan
        if ($remaining.Count -gt 1) {
            Write-Host "  r  - заархивировать оставшиеся ($($remaining.Count))" -ForegroundColor Cyan
        }
        Write-Host "  c  - вернуться в главное меню" -ForegroundColor Cyan
        Write-Host "  x  - показать итоги и завершить" -ForegroundColor Green
        Write-Host ""
        Write-Host "  [B] = bind mount (папка на хосте)" -ForegroundColor Gray
        Write-Host ""

        $selection = Read-Host "Введите значение"

        if ($selection -eq 'c' -or $selection -eq 'C') { $selection = 'continue' }
        elseif ($selection -eq 'r' -or $selection -eq 'R') { $selection = 'remaining' }
        elseif ($selection -eq 'a' -or $selection -eq 'A') { $selection = 'all' }
        elseif ($selection -eq 'x' -or $selection -eq 'X') { $selection = 'summary' }

        if ($selection -eq 'summary' -or $selection -eq 'Summary' -or $selection -eq 'SUMMARY') {
            Write-Log "Пользователь запросил итоги" "INFO"
            Show-Summary
            Write-Host ""
            Write-Host "[НАЖМИТЕ] Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 0
        }
        elseif ($selection -eq 'continue' -or $selection -eq 'Continue' -or $selection -eq 'CONTINUE') {
            Write-Log "Возврат в главное меню" "INFO"
            return
        }
        elseif ($selection -eq 'all' -or $selection -eq 'All' -or $selection -eq 'ALL') {
            Write-Log "Архивация всех volumes" "INFO"
            $totalVols = $availableVolumes.Count
            $currentVol = 0
            for ($i = 0; $i -lt $availableVolumes.Count; $i++) {
                $vol = $availableVolumes[$i]
                if (-not $vol.BackedUp) {
                    $currentVol++
                    Write-Progress -Activity "Архивация volumes" -Status "Volume $currentVol из ${totalVols}: $($vol.Service)" -PercentComplete (($currentVol / $totalVols) * 100)
                    Backup-SingleVolume -Vol $vol -Index $currentVol -Total $totalVols -DestFolder $backupVolFolder
                }
            }
            Write-Progress -Activity "Архивация volumes" -Completed
            Write-Log "Все volumes заархивированы" "SUCCESS"
            return
        }
        elseif ($selection -eq 'remaining' -or $selection -eq 'Remaining') {
            Write-Log "Архивация оставшихся volumes: $($remaining.Count)" "INFO"
            $totalRemaining = $remaining.Count
            $currentVol = 0
            foreach ($vol in $remaining) {
                $currentVol++
                Write-Progress -Activity "Архивация оставшихся volumes" -Status "Volume $currentVol из ${totalRemaining}: $($vol.Service)" -PercentComplete (($currentVol / $totalRemaining) * 100)
                Backup-SingleVolume -Vol $vol -Index $currentVol -Total $totalRemaining -DestFolder $backupVolFolder
            }
            Write-Progress -Activity "Архивация оставшихся volumes" -Completed
            Write-Log "Все оставшиеся volumes заархивированы" "SUCCESS"
            return
        }
        else {
            $num = 0
            if ([int]::TryParse($selection, [ref]$num)) {
                if ($num -ge 1 -and $num -le $availableVolumes.Count) {
                    $vol = $availableVolumes[$num - 1]
                    if ($vol.BackedUp) {
                        Write-Log "Volume '$($vol.Name)' уже заархивирован" "WARNING"
                    } else {
                        Write-Progress -Activity "Архивация volume" -Status "Архивация: $($vol.Service)" -PercentComplete 0
                        Backup-SingleVolume -Vol $vol -Index $num -Total $availableVolumes.Count -DestFolder $backupVolFolder
                        Write-Progress -Activity "Архивация volume" -Completed
                    }
                } else {
                    Write-Log "Неверный номер: $num" "ERROR"
                }
            } else {
                Write-Log "Неверный ввод: $selection" "ERROR"
            }
        }
        Write-Host ""
    }
}

function Backup-SingleVolume {
    param($Vol, $Index, $Total, $DestFolder)

    Write-Host ""
    Write-Log "Начало архивации: $($Vol.Service) ($($Vol.SizeText)) [$Index/$Total]" "INFO"
    Write-Host "  [$Index/$Total] Архивация: $($Vol.Service) ($($Vol.SizeText))..." -ForegroundColor Cyan

    # Заменяем : на - для имени файла (чтобы PowerShell корректно работал)
    $SafeVolName = $Vol.Name -replace ':', '-'
    $tarFile = Join-Path $DestFolder "$SafeVolName.tar.gz"
    $directCopyFolder = Join-Path $DestFolder $SafeVolName

    if ($Test) {
        Write-Log "[ТЕСТ] Будет заархивировано в $tarFile" "TEST"
        $Vol.BackedUp = $true
        $Vol.BackupSize = $Vol.Size
        $Vol.BackupFile = $tarFile
        
        $alreadyAdded = $script:Results.Volumes | Where-Object { $_.Name -eq $Vol.Name }
        if (-not $alreadyAdded) {
            [void]$script:Results.Volumes.Add($Vol)
        }
        return
    }

    $startTime = Get-Date
    $MIN_VOLUME_SIZE = 10KB

    try {
        # Для очень маленьких volumes просто копируем файлы
        if ($Vol.Size -lt $MIN_VOLUME_SIZE) {
            Write-Log "Volume слишком мал ($(Format-Size $Vol.Size)), копирую без сжатия" "INFO"
            Write-Progress -Activity "Копирование volume" -Status "Копирование: $($Vol.Service)" -PercentComplete 0
            
            if ($Vol.Type -eq "bind") {
                # Bind mount — копируем папку через robocopy
                robocopy $Vol.Source $directCopyFolder /E /Z /R:3 /W:5 /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
            } else {
                # Docker volume — копируем через docker
                docker run --rm -v "$($Vol.Name):/source" -v "${DestFolder}:/backup" alpine sh -c "cp -r /source/. /backup/$SafeVolName" 2>$null
            }
            
            if (Test-Path $directCopyFolder) {
                $dirSize = (Get-ChildItem $directCopyFolder -Recurse -File -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum
                Write-Log "Volume $($Vol.Service) скопирован: $(Format-Size $dirSize) (без сжатия)" "SUCCESS"
                
                $Vol.BackedUp = $true
                $Vol.BackupFile = $directCopyFolder
                $Vol.BackupSize = $dirSize
                
                $alreadyAdded = $script:Results.Volumes | Where-Object { $_.Name -eq $Vol.Name }
                if (-not $alreadyAdded) {
                    [void]$script:Results.Volumes.Add($Vol)
                }
            } else {
                Write-Log "Не удалось скопировать volume: $($Vol.Service)" "ERROR"
            }
            
            Write-Progress -Activity "Копирование volume" -Completed
            return
        }

        # =====================================================================
        # Для больших volumes — архивация через Start-Process
        # =====================================================================
        Write-Log "Создание архива: $SafeVolName" "INFO"
        Write-Progress -Activity "Архивация volume" -Status "Создание архива: $($Vol.Service)" -PercentComplete 50
        
        # Формируем аргументы для docker
        if ($Vol.Type -eq "bind") {
            # Для bind mount монтируем Source (путь на хосте)
            Write-Log "Тип: bind mount, путь: $($Vol.Source)" "INFO"
            $dockerArgs = @(
                "run", "--rm",
                "-v", "$($Vol.Source):/source",
                "-v", "${DestFolder}:/backup",
                "alpine", "tar", "czf", "/backup/$SafeVolName.tar.gz", "-C", "/source", "."
            )
        } else {
            # Для Docker volume монтируем volume
            Write-Log "Тип: Docker volume, имя: $($Vol.Name)" "INFO"
            $dockerArgs = @(
                "run", "--rm",
                "-v", "$($Vol.Name):/volume",
                "-v", "${DestFolder}:/backup",
                "alpine", "tar", "czf", "/backup/$SafeVolName.tar.gz", "-C", "/volume", "."
            )
        }
        
        # Логируем команду для отладки
        Write-Log "Команда: docker $($dockerArgs -join ' ')" "INFO"
        
        # Запускаем через Start-Process — НЕ ЖДЁТ stdin!
        $process = Start-Process -FilePath "docker" `
            -ArgumentList $dockerArgs `
            -NoNewWindow -Wait -PassThru
        
        # Проверяем код выхода
        if ($process.ExitCode -ne 0) {
            Write-Log "Docker завершился с кодом: $($process.ExitCode)" "ERROR"
        }
        
        Write-Progress -Activity "Архивация volume" -Status "Проверка: $($Vol.Service)" -PercentComplete 90
        
        # Проверяем, создан ли файл
        if (Test-Path $tarFile) {
            $tarSize = (Get-Item $tarFile).Length
            Write-Log "Архив создан: $(Format-Size $tarSize)" "INFO"
            
            if ($tarSize -lt 100 -and $Vol.Size -gt 10KB) {
                Write-Log "Архив подозрительно мал ($tarSize байт) при исходном размере $(Format-Size $Vol.Size)" "WARNING"
                Remove-Item $tarFile -Force -ErrorAction SilentlyContinue
                Write-Progress -Activity "Архивация volume" -Completed
                return
            }
            
            if ($tarSize -gt 100) {
                Write-Log "Проверка целостности архива..." "INFO"
                
                # Проверка целостности
                $integrityArgs = @(
                    "run", "--rm",
                    "-v", "${DestFolder}:/backup",
                    "alpine", "gzip", "-t", "/backup/$SafeVolName.tar.gz"
                )
                $integrityProcess = Start-Process -FilePath "docker" `
                    -ArgumentList $integrityArgs `
                    -NoNewWindow -Wait -PassThru
                
                if ($integrityProcess.ExitCode -eq 0) {
                    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 0)
                    Write-Log "Volume $($Vol.Service) заархивирован: $(Format-Size $tarSize) (время: ${elapsed}с)" "SUCCESS"
                    
                    $Vol.BackedUp = $true
                    $Vol.BackupFile = $tarFile
                    $Vol.BackupSize = $tarSize
                    
                    $alreadyAdded = $script:Results.Volumes | Where-Object { $_.Name -eq $Vol.Name }
                    if (-not $alreadyAdded) {
                        [void]$script:Results.Volumes.Add($Vol)
                    }
                } else {
                    Write-Log "Архив повреждён: $($Vol.Service)" "ERROR"
                    Remove-Item $tarFile -Force -ErrorAction SilentlyContinue
                }
            } else {
                $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 0)
                Write-Log "Volume $($Vol.Service) заархивирован: $(Format-Size $tarSize) (время: ${elapsed}с, проверка пропущена)" "SUCCESS"
                
                $Vol.BackedUp = $true
                $Vol.BackupFile = $tarFile
                $Vol.BackupSize = $tarSize
                
                $alreadyAdded = $script:Results.Volumes | Where-Object { $_.Name -eq $Vol.Name }
                if (-not $alreadyAdded) {
                    [void]$script:Results.Volumes.Add($Vol)
                }
            }
        } else {
            Write-Log "Архив не создан: $($Vol.Service)" "ERROR"
            Write-Log "Ожидался файл: $tarFile" "ERROR"
        }
        
        Write-Progress -Activity "Архивация volume" -Completed
    } catch {
        Write-Log "Ошибка при архивации volume $($Vol.Service): $_" "ERROR"
        Write-Progress -Activity "Архивация volume" -Completed
    }
}

# =============================================================================
# ФИНАЛЬНОЕ РЕЗЮМЕ
# =============================================================================
function Show-Summary {
    $endTime = Get-Date
    $duration = $endTime - $script:Results.StartTime

    Write-Host ""
    Write-Log "=== ИТОГИ БЭКАПА ===" "INFO"
    
    $titleText = " БЭКАП ЗАВЕРШЁН "
    $borderLength = $titleText.Length
    Write-Host ("-" * $borderLength) -ForegroundColor DarkGray
    Write-Host $titleText -ForegroundColor Green
    Write-Host ("-" * $borderLength) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Расположение: $BackupFolder" -ForegroundColor White
    Write-Host "Длительность: $([math]::Round($duration.TotalMinutes, 2)) минут" -ForegroundColor White
    Write-Host "Лог: $LogFile" -ForegroundColor Gray
    Write-Host ""

    Write-Host "ЭТАП 1 - КОНФИГИ ПРОЕКТА:" -ForegroundColor Cyan
    if ($script:Results.Project) {
        Write-Host "  [OK] Файлов: $($script:Results.Project.Files), Размер: $(Format-Size $script:Results.Project.Size)" -ForegroundColor Green
        Write-Log "Этап 1: $($script:Results.Project.Files) файлов, $(Format-Size $script:Results.Project.Size)" "SUCCESS"
    } else {
        Write-Host "  [ПРОПУСК] Не выполнено" -ForegroundColor Yellow
        Write-Log "Этап 1: пропущен" "WARNING"
    }

    Write-Host ""
    Write-Host "ЭТАП 2 - НЕ-1С БАЗЫ ДАННЫХ:" -ForegroundColor Cyan
    if ($script:Results.Databases.Count -gt 0) {
        foreach ($db in $script:Results.Databases) {
            $displaySize = if ($db.BackupSize) { $db.BackupSize } else { $db.Size }
            Write-Host "  [OK] $($db.Name) - $(Format-Size $displaySize)" -ForegroundColor Green
            Write-Log "  База $($db.Name): $(Format-Size $displaySize)" "SUCCESS"
        }
    } else {
        Write-Host "  [ПРОПУСК] Не выполнено" -ForegroundColor Yellow
        Write-Log "Этап 2: пропущен" "WARNING"
    }

    Write-Host ""
    Write-Host "ЭТАП 3 - КОНФИГИ PG:" -ForegroundColor Cyan
    if ($script:Results.PgConfigs) {
        Write-Host "  [OK] Файлов: $($script:Results.PgConfigs.Files)" -ForegroundColor Green
        if ($script:Results.PgConfigs.Size) {
            Write-Host "      Размер: $(Format-Size $script:Results.PgConfigs.Size)" -ForegroundColor Green
            Write-Log "Этап 3: $($script:Results.PgConfigs.Files) файлов, $(Format-Size $script:Results.PgConfigs.Size)" "SUCCESS"
        }
    } else {
        Write-Host "  [ПРОПУСК] Не выполнено" -ForegroundColor Yellow
        Write-Log "Этап 3: пропущен" "WARNING"
    }

    Write-Host ""
    Write-Host "ЭТАП 4 - VOLUMES И BIND MOUNTS:" -ForegroundColor Cyan
    if ($script:Results.Volumes.Count -gt 0) {
        foreach ($vol in $script:Results.Volumes) {
            $displaySize = if ($vol.BackupSize) { $vol.BackupSize } else { $vol.Size }
            Write-Host "  [OK] $($vol.Service) - $(Format-Size $displaySize)" -ForegroundColor Green
            Write-Log "  Volume $($vol.Service): $(Format-Size $displaySize)" "SUCCESS"
        }
    } else {
        Write-Host "  [ПРОПУСК] Не выполнено" -ForegroundColor Yellow
        Write-Log "Этап 4: пропущен" "WARNING"
    }

    $totalSize = 0
    if ($script:Results.Project) { $totalSize += $script:Results.Project.Size }
    foreach ($db in $script:Results.Databases) { 
        $totalSize += if ($db.BackupSize) { $db.BackupSize } else { $db.Size }
    }
    if ($script:Results.PgConfigs -and $script:Results.PgConfigs.Size) { 
        $totalSize += $script:Results.PgConfigs.Size 
    }
    foreach ($vol in $script:Results.Volumes) { 
        $totalSize += if ($vol.BackupSize) { $vol.BackupSize } else { $vol.Size }
    }

    Write-Host ""
    $totalText = "ОБЩИЙ РАЗМЕР: $(Format-Size $totalSize)"
    $borderLength = $totalText.Length
    Write-Host $totalText -ForegroundColor Green
    Write-Host ("-" * $borderLength) -ForegroundColor DarkGray
    Write-Log "Общий размер бэкапа: $(Format-Size $totalSize)" "SUCCESS"
    Write-Log "=== БЭКАП ЗАВЕРШЁН ===" "INFO"
}

# =============================================================================
# ГЛАВНОЕ МЕНЮ
# =============================================================================
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host " ИНТЕРАКТИВНЫЙ БЭКАП" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Скрипт для создания выборочного бэкапа инфраструктуры 1С." -ForegroundColor White
Write-Host "1С-ные базы бэкапятся через Обновлятор 1С!" -ForegroundColor Cyan
Write-Host "Можно сохранить отдельные этапы или все сразу." -ForegroundColor White

if ($Test) {
    Write-Host ""
    $testMessage = " [ТЕСТ] РЕЖИМ ПРОГОНА — Ничего не будет сохранено!"
    $border = "═" * $testMessage.Length
    Write-Host $border -ForegroundColor Yellow
    Write-Host $testMessage -ForegroundColor Yellow
    Write-Host $border -ForegroundColor Yellow
    Write-Log "Запуск в тестовом режиме" "TEST"
} else {
    Write-Log "Запуск в боевом режиме" "INFO"
}

while ($true) {
    Write-Host ""
    Write-Host "ВЫБЕРИТЕ ЭТАП ДЛЯ ВЫПОЛНЕНИЯ:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] ЭТАП 1: КОНФИГИ ПРОЕКТА" -ForegroundColor Cyan
    Write-Host "      Копирует файлы проекта (docker-compose.yml, .env, monitoring/)" -ForegroundColor White
    Write-Host "      Результат: Полная копия проекта, восстанавливается через robocopy" -ForegroundColor White
    Write-Host ""
    Write-Host "  [2] ЭТАП 2: НЕ-1С БАЗЫ POSTGRESQL" -ForegroundColor Cyan
    Write-Host "      Создаёт отдельный pg_dump для каждой не-1С базы" -ForegroundColor White
    Write-Host "      Результат: Отдельные файлы .sql.gz (~10x сжатие)" -ForegroundColor White
    Write-Host ""
    Write-Host "  [3] ЭТАП 3: КОНФИГИ POSTGRESQL" -ForegroundColor Cyan
    Write-Host "      Копирует postgresql.conf, pg_hba.conf, pg_ident.conf" -ForegroundColor White
    Write-Host "      Результат: ~20 КБ настроек сервера для восстановления ручной настройки" -ForegroundColor White
    Write-Host ""
    Write-Host "  [4] ЭТАП 4: VOLUMES И BIND MOUNTS" -ForegroundColor Cyan
    Write-Host "      Создаёт tar.gz архив для каждого Docker volume и bind mount" -ForegroundColor White
    Write-Host "      Результат: Побайтовая копия (самый медленный, самый объёмный)" -ForegroundColor White
    Write-Host ""
    Write-Host "  [a] Выполнить все 4 этапа последовательно" -ForegroundColor Green
    Write-Host "  [s] Показать итоги и завершить" -ForegroundColor Green
    Write-Host "  [q] Выйти без сохранения" -ForegroundColor Red
    Write-Host ""

    $stageSelection = Read-Host "Введите значение (1-4, a, s или q)"

    if ($stageSelection -eq 'q' -or $stageSelection -eq 'Q') { $stageSelection = 'quit' }
    if ($stageSelection -eq 'a' -or $stageSelection -eq 'A') { $stageSelection = 'all' }
    if ($stageSelection -eq 's' -or $stageSelection -eq 'S') { $stageSelection = 'summary' }

    if ($stageSelection -eq 'summary' -or $stageSelection -eq 'Summary' -or $stageSelection -eq 'SUMMARY') {
        Write-Log "Пользователь запросил итоги" "INFO"
        Show-Summary
        Write-Host ""
        Write-Host "[НАЖМИТЕ] Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
    elseif ($stageSelection -eq 'quit' -or $stageSelection -eq 'Quit' -or $stageSelection -eq 'QUIT') {
        Write-Log "Бэкап отменён пользователем" "WARNING"
        Write-Host ""
        Write-Host "[ОТМЕНА] Бэкап отменён пользователем" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "[НАЖМИТЕ] Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
    elseif ($stageSelection -eq 'all' -or $stageSelection -eq 'All' -or $stageSelection -eq 'ALL') {
        Write-Log "Выполнение всех этапов" "INFO"
        $null = Backup-ProjectConfigs
        $null = Backup-Databases
        $null = Backup-PgConfigs
        $null = Backup-Volumes
        break
    }
    elseif ($stageSelection -eq '1') {
        $null = Backup-ProjectConfigs
        if (Ask-YesNo "Перейти к следующему этапу?") { continue } else { break }
    }
    elseif ($stageSelection -eq '2') {
        $null = Backup-Databases
        continue
    }
    elseif ($stageSelection -eq '3') {
        $null = Backup-PgConfigs
        if (Ask-YesNo "Перейти к следующему этапу?") { continue } else { break }
    }
    elseif ($stageSelection -eq '4') {
        $null = Backup-Volumes
        continue
    }
    else {
        Write-Log "Неверный выбор: $stageSelection" "ERROR"
        Write-Host "[ОШИБКА] Неверный выбор. Используйте 1-4, a, s или q" -ForegroundColor Red
    }
}

Show-Summary

Write-Host ""
Write-Host "[НАЖМИТЕ] Нажмите любую клавишу для выхода..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")