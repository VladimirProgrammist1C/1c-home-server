# create-gitignore.ps1
$ErrorActionPreference = "Stop"

Write-Host "=== CREATING .GITIGNORE ===" -ForegroundColor Cyan

$basePath = "E:\1C_Infrastructure"
$gitignorePath = Join-Path $basePath ".gitignore"

$gitignoreContent = @"
# =============================================================================
# .gitignore для 1C Home Server Infrastructure
# =============================================================================

# === УСТАНОВЛЕННЫЕ ПРОГРАММЫ (НЕ КОММИТИТЬ) ===
Git/
Mini AI 1C/
Tools/
VPN/
inetpub/

# === OLLAMA ===
AI/Ollama/bin/
AI/Ollama/models/
AI/Ollama/logs/

# === МЕДИА И ОБРАЗЫ ===
*.mp4
*.avi
*.mkv
*.iso
*.vhdx
*.vhd

# === ТЯЖЁЛЫЕ ФАЙЛЫ ===
*.exe
*.msi
*.zip
*.7z
*.gguf
*.bin

# === ЛОГИ И ВРЕМЕННЫЕ ===
*.log
logs/
BACKUPS/
*.bak

# === СЕКРЕТЫ ===
.env
.env.local

# === 1С ФАЙЛЫ ===
*.cf
*.cfu
*.dt
1Cv8.1CD
1Cv8.Log

# === IDE ===
.vscode/
.idea/

# === WINDOWS ===
Thumbs.db
.DS_Store
desktop.ini
"@

# Создаём файл с правильной кодировкой (UTF-8 без BOM)
[System.IO.File]::WriteAllText($gitignorePath, $gitignoreContent, [System.Text.UTF8Encoding]::new($false))

Write-Host "OK: .gitignore created" -ForegroundColor Green
Write-Host "Path: $gitignorePath" -ForegroundColor Gray
Write-Host "Encoding: UTF-8 without BOM" -ForegroundColor Gray