# git-init.ps1
# Инициализация Git репозитория

Write-Host "=== GIT INIT ===" -ForegroundColor Cyan

# 1. Инициализация
Write-Host "`n[1/4] Initializing repository..." -ForegroundColor Yellow
git init

# 2. Настройка пользователя
Write-Host "[2/4] Configuring user..." -ForegroundColor Yellow
git config --global user.name "Vladimir"
git config --global user.email "bessonov_1989@list.ru"

# 3. Добавить все файлы
Write-Host "[3/4] Adding files..." -ForegroundColor Yellow
git add .

# 4. Показать, что добавлено
Write-Host "`nFiles to commit:" -ForegroundColor Cyan
git status --short

# 5. Первый коммит
Write-Host "`n[4/4] Creating first commit..." -ForegroundColor Yellow
git commit -m "v1.0: Initial infrastructure setup"

# 6. Создать тег
git tag v1.0

# 7. Показать историю
Write-Host "`n=== HISTORY ===" -ForegroundColor Cyan
git log --oneline
git tag

Write-Host "`n✓ Git initialized successfully!" -ForegroundColor Green