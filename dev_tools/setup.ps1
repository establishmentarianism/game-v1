
$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

# Определяем пути относительно скрипта
$ScriptDir = $PSScriptRoot
$ProjectRoot = Split-Path -Parent $ScriptDir
$VenvPath = Join-Path $ProjectRoot ".venv"
$ReqFile = Join-Path $ScriptDir "requirements.txt"

Write-Host "🛠️  Начинаем настройку окружения..." -ForegroundColor Cyan

# 1. Поиск Python (пробуем py, затем python)
if (Get-Command py -ErrorAction SilentlyContinue) {
    $PyCmd = "py"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $PyCmd = "python"
} else {
    Write-Error "❌ Python не найден! Установите Python 3.10+ и добавьте его в PATH."
    exit 1
}

# Проверка версии
$PyVer = & $PyCmd --version 2>&1
Write-Host "✅ Используется: $PyVer" -ForegroundColor Green

# 2. Создание виртуального окружения
if (-not (Test-Path $VenvPath)) {
    Write-Host "📦 Создаем виртуальное окружение (.venv)..." -ForegroundColor Yellow
    try {
        & $PyCmd -m venv $VenvPath
    } catch {
        Write-Error "❌ Не удалось создать venv. Проверьте установку Python."
        exit 1
    }
} else {
    Write-Host "ℹ️  Виртуальное окружение уже существует." -ForegroundColor Gray
}

# Путь к pip внутри venv
$VenvPython = Join-Path $VenvPath "Scripts\python.exe"
if (-not (Test-Path $VenvPython)) {
    # Fallback для Linux/Mac
    $VenvPython = Join-Path $VenvPath "bin/python"
}

# 3. Установка зависимостей
Write-Host "⬇️  Установка зависимостей в .venv..." -ForegroundColor Yellow
try {
    # ВАЖНО: Добавлено setuptools, так как gdtoolkit требует pkg_resources, которого нет в чистом Python 3.12
    & $VenvPython -m pip install --upgrade pip setuptools
    & $VenvPython -m pip install -r $ReqFile
} catch {
    Write-Error "❌ Ошибка установки зависимостей."
    exit 1
}

# 4. Установка Git Hooks
Write-Host "⚓ Установка Pre-commit хуков..." -ForegroundColor Cyan
try {
    # Запускаем pre-commit из venv
    $PreCommit = Join-Path $VenvPath "Scripts\pre-commit.exe"
    if (Test-Path $PreCommit) {
        Set-Location $ProjectRoot
        & $PreCommit install
    } else {
        Write-Warning "⚠️ pre-commit.exe не найден в Scripts."
    }
} catch {
    Write-Warning "⚠️ Не удалось установить хуки (возможно, нет папки .git)."
}

Write-Host "🎉 Готово! Окружение настроено." -ForegroundColor Green
