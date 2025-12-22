# Trading System Debug Script
$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Trading System Debug" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Python processes
Write-Host "[1/5] Checking Python processes..." -ForegroundColor Yellow
$pythonProcesses = Get-Process python -ErrorAction SilentlyContinue
if ($pythonProcesses) {
    Write-Host "    Found $($pythonProcesses.Count) Python process(es)" -ForegroundColor Green
    foreach ($proc in $pythonProcesses) {
        Write-Host "    - PID: $($proc.Id) | Memory: $([math]::Round($proc.WS/1MB, 2)) MB" -ForegroundColor White
    }
} else {
    Write-Host "    No Python processes found" -ForegroundColor Yellow
}
Write-Host ""

# Check logs
Write-Host "[2/5] Checking log files..." -ForegroundColor Yellow
$logsPath = "C:\Users\USER\OneDrive\trading-bridge\logs"
if (Test-Path $logsPath) {
    $logFiles = Get-ChildItem -Path $logsPath -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    if ($logFiles) {
        Write-Host "    Found $($logFiles.Count) log file(s)" -ForegroundColor Green
        foreach ($log in $logFiles) {
            Write-Host "    - $($log.Name) ($($log.LastWriteTime))" -ForegroundColor White
        }
        
        # Show latest bridge log
        $bridgeLog = Get-ChildItem -Path $logsPath -Filter "mql5_bridge_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($bridgeLog) {
            Write-Host ""
            Write-Host "    Latest bridge log ($($bridgeLog.Name)):" -ForegroundColor Cyan
            Get-Content $bridgeLog.FullName -Tail 15 | ForEach-Object {
                Write-Host "    $_" -ForegroundColor Gray
            }
        }
        
        # Show latest service log
        $serviceLog = Get-ChildItem -Path $logsPath -Filter "trading_service_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($serviceLog) {
            Write-Host ""
            Write-Host "    Latest service log ($($serviceLog.Name)):" -ForegroundColor Cyan
            Get-Content $serviceLog.FullName -Tail 15 | ForEach-Object {
                Write-Host "    $_" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "    No log files found" -ForegroundColor Yellow
    }
} else {
    Write-Host "    Logs directory not found" -ForegroundColor Yellow
}
Write-Host ""

# Check configuration files
Write-Host "[3/5] Checking configuration files..." -ForegroundColor Yellow
$configPath = "C:\Users\USER\OneDrive\trading-bridge\config"
$brokersConfig = Join-Path $configPath "brokers.json"
$symbolsConfig = Join-Path $configPath "symbols.json"

if (Test-Path $brokersConfig) {
    Write-Host "    ✓ brokers.json exists" -ForegroundColor Green
    $brokers = Get-Content $brokersConfig | ConvertFrom-Json
    $exness = $brokers.brokers | Where-Object { $_.name -eq "EXNESS" }
    if ($exness) {
        $hasPlaceholders = ($exness.account_id -like "*YOUR_*") -or ($exness.api_key -like "*YOUR_*")
        if ($hasPlaceholders) {
            Write-Host "    ⚠ brokers.json contains placeholders" -ForegroundColor Yellow
        } else {
            Write-Host "    ✓ brokers.json has real credentials" -ForegroundColor Green
        }
    }
} else {
    Write-Host "    ✗ brokers.json not found" -ForegroundColor Red
}

if (Test-Path $symbolsConfig) {
    Write-Host "    ✓ symbols.json exists" -ForegroundColor Green
    $symbols = Get-Content $symbolsConfig | ConvertFrom-Json
    $weekdayCount = ($symbols.symbols | Where-Object { $_.trading_days -contains "monday" }).Count
    $weekendCount = ($symbols.symbols | Where-Object { $_.trading_days -contains "saturday" }).Count
    Write-Host "    - Weekday symbols: $weekdayCount" -ForegroundColor White
    Write-Host "    - Weekend symbols: $weekendCount" -ForegroundColor White
} else {
    Write-Host "    ✗ symbols.json not found" -ForegroundColor Red
}
Write-Host ""

# Check MT5 EA files
Write-Host "[4/5] Checking MT5 EA files..." -ForegroundColor Yellow
$mt5Path = "C:\Users\USER\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5"
$eaFile = Join-Path $mt5Path "Experts\PythonBridgeEA.mq5"
$includeFile = Join-Path $mt5Path "Include\PythonBridge.mqh"

if (Test-Path $eaFile) {
    Write-Host "    ✓ PythonBridgeEA.mq5 exists" -ForegroundColor Green
    $compiled = Join-Path $mt5Path "Experts\PythonBridgeEA.ex5"
    if (Test-Path $compiled) {
        Write-Host "    ✓ PythonBridgeEA.ex5 (compiled) exists" -ForegroundColor Green
    } else {
        Write-Host "    ⚠ PythonBridgeEA.ex5 not found - needs compilation" -ForegroundColor Yellow
    }
} else {
    Write-Host "    ✗ PythonBridgeEA.mq5 not found" -ForegroundColor Red
}

if (Test-Path $includeFile) {
    Write-Host "    ✓ PythonBridge.mqh exists" -ForegroundColor Green
} else {
    Write-Host "    ✗ PythonBridge.mqh not found" -ForegroundColor Red
}
Write-Host ""

# Check port availability
Write-Host "[5/5] Checking port 5555..." -ForegroundColor Yellow
try {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 5555)
    $listener.Start()
    $listener.Stop()
    Write-Host "    ✓ Port 5555 is available" -ForegroundColor Green
} catch {
    Write-Host "    ⚠ Port 5555 may be in use: $_" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Debug Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$warnings = @()

if (-not (Test-Path $brokersConfig)) {
    $issues += "brokers.json not found"
}
if (-not (Test-Path $symbolsConfig)) {
    $issues += "symbols.json not found"
}
if (-not (Test-Path $eaFile)) {
    $issues += "PythonBridgeEA.mq5 not in MT5"
}
if (-not (Test-Path $includeFile)) {
    $issues += "PythonBridge.mqh not in MT5"
}

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✅ All checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "System appears to be configured correctly." -ForegroundColor Green
    Write-Host "Check logs above for any runtime errors." -ForegroundColor Cyan
} else {
    if ($issues.Count -gt 0) {
        Write-Host "❌ Issues found:" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "   - $issue" -ForegroundColor Red
        }
        Write-Host ""
    }
    if ($warnings.Count -gt 0) {
        Write-Host "⚠️  Warnings:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "   - $warning" -ForegroundColor Yellow
        }
        Write-Host ""
    }
}

Write-Host ""

