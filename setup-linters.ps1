# PowerShell script to setup linters for the project

Write-Host "Setting up linters for locustgrafanastream project..." -ForegroundColor Green

# Check if Python is available
try {
    $pythonVersion = python --version
    Write-Host "Found Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Python is not installed or not in PATH. Please install Python first." -ForegroundColor Red
    exit 1
}

# Check if Node.js is available
try {
    $nodeVersion = node --version
    Write-Host "Found Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "Node.js is not installed. Installing Node.js with winget..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS
    Write-Host "Please restart your PowerShell session after Node.js installation." -ForegroundColor Yellow
}

# Install Python linters
Write-Host "Installing Python linters..." -ForegroundColor Yellow
pip install --upgrade pip
pip install black flake8 isort mypy bandit yamllint pre-commit

# Install Node.js linters (if Node.js is available)
try {
    Write-Host "Installing Node.js linters..." -ForegroundColor Yellow
    npm install -g markdownlint-cli jsonlint yaml-lint
} catch {
    Write-Host "Skipping Node.js linters installation. Install Node.js and run again." -ForegroundColor Yellow
}

# Install pre-commit hooks
Write-Host "Installing pre-commit hooks..." -ForegroundColor Yellow
pre-commit install

Write-Host "✅ Linters setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Available commands:" -ForegroundColor Cyan
Write-Host "  make lint          - Run all linters" -ForegroundColor White
Write-Host "  make format        - Format all code" -ForegroundColor White
Write-Host "  make lint-python   - Lint only Python files" -ForegroundColor White
Write-Host "  make lint-yaml     - Lint only YAML files" -ForegroundColor White
Write-Host "  make lint-json     - Lint only JSON files" -ForegroundColor White
Write-Host "  make lint-md       - Lint only Markdown files" -ForegroundColor White
Write-Host "  pre-commit run --all-files - Run pre-commit on all files" -ForegroundColor White
Write-Host ""
Write-Host "Configuration files created:" -ForegroundColor Cyan
Write-Host "  .flake8           - Python linting config" -ForegroundColor White
Write-Host "  pyproject.toml    - Black, isort, mypy config" -ForegroundColor White
Write-Host "  .yamllint         - YAML linting config" -ForegroundColor White
Write-Host "  .markdownlint.json - Markdown linting config" -ForegroundColor White
Write-Host "  .pre-commit-config.yaml - Pre-commit hooks config" -ForegroundColor White
Write-Host "  Makefile          - Easy linting commands" -ForegroundColor White
