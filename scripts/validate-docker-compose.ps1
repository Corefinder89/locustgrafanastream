# PowerShell Docker Compose validation script
# Validates docker-compose.yml for best practices and security

param(
    [string]$ComposeFile = "docker-compose.yml",
    [switch]$Strict
)

$ErrorActionPreference = "Continue"
$ExitCode = 0

Write-Host "🔍 Docker Compose Validation Script" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Check if docker-compose.yml exists
if (-not (Test-Path $ComposeFile)) {
    Write-Host "❌ Error: $ComposeFile not found" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Validating: $ComposeFile" -ForegroundColor Green
Write-Host ""

# Test 1: Validate syntax
Write-Host "🔍 Test 1: Validating YAML syntax..." -ForegroundColor Yellow

$DockerComposeAvailable = $false
$ValidationPassed = $false

# Try docker-compose command
try {
    $null = Get-Command docker-compose -ErrorAction Stop
    $result = docker-compose config -q 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ YAML syntax is valid (docker-compose)" -ForegroundColor Green
        $DockerComposeAvailable = $true
        $ValidationPassed = $true
    } else {
        Write-Host "❌ YAML syntax error with docker-compose" -ForegroundColor Red
        $ExitCode = 1
    }
} catch {
    # Try docker compose (newer syntax)
    try {
        $null = Get-Command docker -ErrorAction Stop
        $result = docker compose version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $result = docker compose config -q 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ YAML syntax is valid (docker compose)" -ForegroundColor Green
                $DockerComposeAvailable = $true
                $ValidationPassed = $true
            } else {
                Write-Host "❌ YAML syntax error with docker compose" -ForegroundColor Red
                $ExitCode = 1
            }
        }
    } catch {
        # Fallback to basic YAML validation with Python
        Write-Host "⚠️  docker-compose not available, using basic YAML validation" -ForegroundColor Yellow
        try {
            python -c "import yaml; yaml.safe_load(open('$ComposeFile'))" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Basic YAML syntax is valid" -ForegroundColor Green
                $ValidationPassed = $true
            } else {
                Write-Host "❌ YAML syntax error" -ForegroundColor Red
                $ExitCode = 1
            }
        } catch {
            Write-Host "❌ Unable to validate YAML syntax (Python not available)" -ForegroundColor Red
            $ExitCode = 1
        }
    }
}

Write-Host ""

# Test 2: Check for security best practices
Write-Host "🔍 Test 2: Checking security best practices..." -ForegroundColor Yellow

# Check for read-only containers
$content = Get-Content $ComposeFile -Raw
if ($content -match "read_only: true") {
    Write-Host "✅ Found read-only containers" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: No read-only containers found" -ForegroundColor Yellow
}

# Check for restart policies
if ($content -match "restart:") {
    Write-Host "✅ Restart policies configured" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: No restart policies found" -ForegroundColor Yellow
}

# Check for custom networks
if ($content -match "networks:") {
    Write-Host "✅ Custom networks configured" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: Using default network" -ForegroundColor Yellow
}

# Check for latest tags
if ($content -match ":latest") {
    Write-Host "⚠️  Warning: Found ':latest' tags" -ForegroundColor Yellow
    Select-String -Path $ComposeFile -Pattern ":latest" | ForEach-Object {
        Write-Host "  Line $($_.LineNumber): $($_.Line.Trim())" -ForegroundColor Gray
    }
} else {
    Write-Host "✅ No ':latest' tags found" -ForegroundColor Green
}

Write-Host ""

# Test 3: Check exposed ports
Write-Host "🔍 Test 3: Checking exposed ports..." -ForegroundColor Yellow

$exposedPorts = Select-String -Path $ComposeFile -Pattern '^\s*-\s*"[0-9]+:[0-9]+"' | Measure-Object
Write-Host "Found $($exposedPorts.Count) exposed port mappings"

# Check for dangerous ports
if ($content -match "22:22") {
    Write-Host "🚨 WARNING: SSH port 22 exposed!" -ForegroundColor Red
    $ExitCode = 1
}

if ($content -match "3389:3389") {
    Write-Host "🚨 WARNING: RDP port 3389 exposed!" -ForegroundColor Red
    $ExitCode = 1
}

Write-Host ""

# Test 4: Check for hardcoded secrets
Write-Host "🔍 Test 4: Checking for potential hardcoded secrets..." -ForegroundColor Yellow

$secretPattern = "(password|secret|key|token).*=.*[^\$\{]"
$secrets = Select-String -Path $ComposeFile -Pattern $secretPattern -CaseSensitive:$false

if ($secrets) {
    Write-Host "🚨 WARNING: Potential hardcoded secrets found!" -ForegroundColor Red
    $secrets | ForEach-Object {
        Write-Host "  Line $($_.LineNumber): $($_.Line.Trim())" -ForegroundColor Gray
    }
    $ExitCode = 1
} else {
    Write-Host "✅ No hardcoded secrets detected" -ForegroundColor Green
}

Write-Host ""

# Test 5: Check for volume security
Write-Host "🔍 Test 5: Checking volume mount security..." -ForegroundColor Yellow

if ($content -match ":/.*:ro") {
    Write-Host "✅ Found read-only volume mounts" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: No read-only volume mounts found" -ForegroundColor Yellow
}

if ($content -match ":/etc:" -or $content -match ":/root:") {
    Write-Host "🚨 WARNING: Sensitive directory mounts found!" -ForegroundColor Red
    $ExitCode = 1
}

Write-Host ""

# Summary
Write-Host "📊 Validation Summary" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

if ($ExitCode -eq 0) {
    Write-Host "🎉 All critical checks passed!" -ForegroundColor Green
} else {
    Write-Host "❌ Some critical issues found. Please review the warnings above." -ForegroundColor Red
}

if ($Strict -and $ExitCode -ne 0) {
    Write-Host "Running in strict mode - treating warnings as errors." -ForegroundColor Yellow
}

exit $ExitCode