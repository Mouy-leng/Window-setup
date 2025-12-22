# Quick verification script
$ErrorActionPreference = "Continue"

Write-Host "Checking Trading System Status..." -ForegroundColor Cyan
Write-Host ""

# Check Python processes
$pythonProcesses = Get-Process python -ErrorAction SilentlyContinue
if ($pythonProcesses) {
    Write-Host "[OK] Python processes running: $($pythonProcesses.Count)" -ForegroundColor Green
    foreach ($proc in $pythonProcesses) {
        Write-Host "  PID: $($proc.Id) - Memory: $([math]::Round($proc.WS/1MB, 2)) MB" -ForegroundColor White
    }
} else {
    Write-Host "[INFO] No Python processes found" -ForegroundColor Yellow
}

Write-Host ""

# Check logs
$logsPath = "C:\Users\USER\OneDrive\trading-bridge\logs"
if (Test-Path $logsPath) {
    $logFiles = Get-ChildItem -Path $logsPath -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 3
    if ($logFiles) {
        Write-Host "[OK] Log files found:" -ForegroundColor Green
        foreach ($log in $logFiles) {
            Write-Host "  $($log.Name) - $($log.LastWriteTime)" -ForegroundColor White
        }
    }
}

Write-Host ""
Write-Host "Current Day: $((Get-Date).DayOfWeek)" -ForegroundColor Cyan
Write-Host ""

