# dev_tools/setup.ps1
Write-Host "🚀 Настройка окружения..." -ForegroundColor Cyan

# 1. Проверяем Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Python не найден! Установите Python 3.10+."
    exit 1
}

# 2. Бутстраппинг UV (ставим, если нет)
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Устанавливаем uv..." -ForegroundColor Yellow
    pip install uv
}

# 3. Синхронизация (создаст .venv и поставит gdtoolkit)
Write-Host "♻️ Синхронизация зависимостей..." -ForegroundColor Cyan
uv sync

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Готово!" -ForegroundColor Green
} else {
    Write-Error "❌ Ошибка синхронизации."
    exit 1
}
