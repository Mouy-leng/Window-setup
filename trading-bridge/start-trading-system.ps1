#Requires -Version 5.1
<#
.SYNOPSIS
    Start Trading System - Complete Setup and Launch
.DESCRIPTION
    Sets up and starts the complete trading system with weekday/weekend symbol filtering
#>

$ErrorActionPreference = "Continue"

$workspaceRoot = "C:\Users\USER\OneDrive"
$tradingBridgePath = Join-Path $workspaceRoot "trading-bridge"
$pythonServicePath = Join-Path $tradingBridgePath "python\services\background_service.py"
$logsPath = Join-Path $tradingBridgePath "logs"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Trading System Startup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Create logs directory
if (-not (Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
    Write-Host "[OK] Created logs directory" -ForegroundColor Green
}

# Check if Python is installed
Write-Host "[1/5] Checking Python installation..." -ForegroundColor Yellow
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "[ERROR] Python not found!" -ForegroundColor Red
    Write-Host "Please install Python and add it to PATH" -ForegroundColor Yellow
    exit 1
}
Write-Host "    [OK] Python found: $($python.Version)" -ForegroundColor Green

# Check if service script exists
Write-Host "[2/5] Checking service files..." -ForegroundColor Yellow
if (-not (Test-Path $pythonServicePath)) {
    Write-Host "[ERROR] Service script not found: $pythonServicePath" -ForegroundColor Red
    exit 1
}
Write-Host "    [OK] Service script found" -ForegroundColor Green

# Check configuration files
Write-Host "[3/5] Checking configuration..." -ForegroundColor Yellow
$symbolsConfig = Join-Path $tradingBridgePath "config\symbols.json"
$brokersConfig = Join-Path $tradingBridgePath "config\brokers.json"

if (-not (Test-Path $symbolsConfig)) {
    Write-Host "[WARNING] symbols.json not found - using defaults" -ForegroundColor Yellow
} else {
    Write-Host "    [OK] symbols.json found" -ForegroundColor Green
}

if (-not (Test-Path $brokersConfig)) {
    Write-Host "[WARNING] brokers.json not found - broker API may not work" -ForegroundColor Yellow
} else {
    Write-Host "    [OK] brokers.json found" -ForegroundColor Green
}

# Check if service is already running
Write-Host "[4/5] Checking for existing service..." -ForegroundColor Yellow
$existingProcess = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    try {
        $_.CommandLine -like "*background_service.py*"
    } catch {
        $false
    }
}

if ($existingProcess) {
    Write-Host "    [INFO] Service is already running (PID: $($existingProcess.Id))" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Service Status: RUNNING" -ForegroundColor Green
    Write-Host "To stop: Stop-Process -Id $($existingProcess.Id)" -ForegroundColor Cyan
    exit 0
}

# Get current day and active symbols
Write-Host "[5/5] Starting trading service..." -ForegroundColor Yellow
$currentDay = (Get-Date).DayOfWeek
Write-Host "    Today is: $currentDay" -ForegroundColor Cyan

# Start Python service
try {
    Write-Host "    Starting background service..." -ForegroundColor Yellow
    
    $process = Start-Process python -ArgumentList $pythonServicePath `
        -WindowStyle Hidden `
        -PassThru `
        -ErrorAction Stop
    
    Start-Sleep -Seconds 3
    
    # Verify process is running
    $verifyProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
    if ($verifyProcess -and -not $verifyProcess.HasExited) {
        Write-Host "    [OK] Service started (PID: $($process.Id))" -ForegroundColor Green
    } else {
        Write-Host "    [ERROR] Service failed to start or exited immediately" -ForegroundColor Red
        Write-Host "    Check logs in: $logsPath" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "    [ERROR] Failed to start service: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Trading System Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Status: RUNNING" -ForegroundColor Green
Write-Host "Process ID: $($process.Id)" -ForegroundColor White
Write-Host "Day: $currentDay" -ForegroundColor White
Write-Host "Logs: $logsPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Active Symbols:" -ForegroundColor Yellow
if ($currentDay -eq "Saturday" -or $currentDay -eq "Sunday") {
    Write-Host "  - BTCUSD (Weekend)" -ForegroundColor Green
    Write-Host "  - ETHUSD (Weekend)" -ForegroundColor Green
    Write-Host "  - XAUUSD (Weekend)" -ForegroundColor Green
} else {
    Write-Host "  - EURUSD (Weekday)" -ForegroundColor Green
    Write-Host "  - GBPUSD (Weekday)" -ForegroundColor Green
    Write-Host "  - USDJPY (Weekday)" -ForegroundColor Green
    Write-Host "  - AUDUSD (Weekday)" -ForegroundColor Green
    Write-Host "  - USDCAD (Weekday)" -ForegroundColor Green
    Write-Host "  - EURJPY (Weekday)" -ForegroundColor Green
    Write-Host "  - GBPJPY (Weekday)" -ForegroundColor Green
}
Write-Host ""
Write-Host "To stop: Stop-Process -Id $($process.Id)" -ForegroundColor Cyan
Write-Host "To view logs: Get-Content $logsPath\trading_service_*.log -Tail 50" -ForegroundColor Cyan
Write-Host ""

