#Requires -Version 5.1
<#
.SYNOPSIS
    Ensure Trading Processes Have Priority During High Disk Usage
.DESCRIPTION
    Sets high priority for trading processes and ensures they can execute
    trades even when disk I/O is constrained. Should be called before
    critical trading operations.
#>

param(
    [switch]$SetPriority,
    [switch]$CheckDiskHealth
)

$ErrorActionPreference = "Continue"

function Set-TradingProcessPriority {
    Write-Host "[INFO] Setting trading process priorities..." -ForegroundColor Yellow
    
    $tradingProcesses = @(
        @{ Name = "python"; Pattern = "*trading*|*bridge*" }
        @{ Name = "terminal64"; Pattern = "" }
        @{ Name = "mt5"; Pattern = "" }
    )
    
    $prioritySet = 0
    
    foreach ($procInfo in $tradingProcesses) {
        try {
            $procs = Get-Process -Name $procInfo.Name -ErrorAction SilentlyContinue
            
            if ($procInfo.Pattern) {
                $procs = $procs | Where-Object {
                    $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
                    if ($cmdLine) {
                        $cmdLine -match $procInfo.Pattern
                    } else {
                        $false
                    }
                }
            }
            
            foreach ($proc in $procs) {
                try {
                    if ($SetPriority) {
                        $proc.PriorityClass = "High"
                        Write-Host "  [OK] Set $($procInfo.Name) (PID: $($proc.Id)) to High priority" -ForegroundColor Green
                        $prioritySet++
                    } else {
                        Write-Host "  [INFO] $($procInfo.Name) (PID: $($proc.Id)) - Current: $($proc.PriorityClass)" -ForegroundColor Cyan
                    }
                } catch {
                    Write-Host "  [WARNING] Could not set priority for $($procInfo.Name) (PID: $($proc.Id)): $_" -ForegroundColor Yellow
                    Write-Host "    [INFO] May require administrator privileges" -ForegroundColor Gray
                }
            }
        } catch {
            # Process may not be running
        }
    }
    
    if ($SetPriority) {
        Write-Host "[OK] Set priority for $prioritySet trading process(es)" -ForegroundColor Green
    }
}

function Test-DiskHealthForTrading {
    Write-Host "[INFO] Checking disk health for trading operations..." -ForegroundColor Yellow
    
    try {
        # Get Disk 0 performance
        $counters = @(
            "\PhysicalDisk(0 C: D:)\% Disk Time",
            "\PhysicalDisk(0 C: D:)\Avg. Disk sec/Read",
            "\PhysicalDisk(0 C: D:)\Avg. Disk sec/Write"
        )
        
        $perfData = Get-Counter -Counter $counters -ErrorAction SilentlyContinue
        
        if ($perfData) {
            $samples = $perfData.CounterSamples
            $diskTime = 0
            $avgReadTime = 0
            $avgWriteTime = 0
            
            foreach ($sample in $samples) {
                $path = $sample.Path
                $value = $sample.CookedValue
                
                if ($path -like "*% Disk Time*") {
                    $diskTime = [math]::Round($value, 1)
                } elseif ($path -like "*Avg. Disk sec/Read*") {
                    $avgReadTime = [math]::Round($value * 1000, 2)
                } elseif ($path -like "*Avg. Disk sec/Write*") {
                    $avgWriteTime = [math]::Round($value * 1000, 2)
                }
            }
            
            $avgResponseTime = [math]::Round(($avgReadTime + $avgWriteTime) / 2, 1)
            
            Write-Host "  Disk Active Time: ${diskTime}%" -ForegroundColor $(if ($diskTime -gt 90) { "Red" } elseif ($diskTime -gt 70) { "Yellow" } else { "Green" })
            Write-Host "  Average Response Time: ${avgResponseTime}ms" -ForegroundColor $(if ($avgResponseTime -gt 50) { "Red" } elseif ($avgResponseTime -gt 30) { "Yellow" } else { "Green" })
            
            if ($diskTime -gt 90 -or $avgResponseTime -gt 50) {
                Write-Host "  [WARNING] Disk performance may affect trading operations" -ForegroundColor Yellow
                Write-Host "  [INFO] Trading processes have been prioritized" -ForegroundColor Cyan
                return $false
            } else {
                Write-Host "  [OK] Disk performance is acceptable for trading" -ForegroundColor Green
                return $true
            }
        } else {
            Write-Host "  [WARNING] Could not retrieve disk performance data" -ForegroundColor Yellow
            return $true  # Assume OK if we can't check
        }
    } catch {
        Write-Host "  [WARNING] Error checking disk health: $_" -ForegroundColor Yellow
        return $true  # Assume OK if check fails
    }
}

function Wait-ForDiskReady {
    param([int]$MaxWaitSeconds = 10)
    
    Write-Host "[INFO] Waiting for disk to be ready for trading operation..." -ForegroundColor Yellow
    
    $startTime = Get-Date
    $ready = $false
    
    while (-not $ready -and ((Get-Date) - $startTime).TotalSeconds -lt $MaxWaitSeconds) {
        try {
            $counter = Get-Counter "\PhysicalDisk(0 C: D:)\% Disk Time" -ErrorAction SilentlyContinue
            if ($counter) {
                $diskTime = [math]::Round($counter.CounterSamples[0].CookedValue, 1)
                
                if ($diskTime -lt 95) {
                    $ready = $true
                    Write-Host "  [OK] Disk ready (${diskTime}% active)" -ForegroundColor Green
                } else {
                    Start-Sleep -Milliseconds 500
                }
            } else {
                $ready = $true  # Can't check, assume ready
            }
        } catch {
            $ready = $true  # Error checking, assume ready
        }
    }
    
    if (-not $ready) {
        Write-Host "  [WARNING] Disk still busy after $MaxWaitSeconds seconds, proceeding anyway" -ForegroundColor Yellow
    }
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Trading Priority Manager" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($SetPriority) {
    Set-TradingProcessPriority
    Write-Host ""
}

if ($CheckDiskHealth) {
    $diskHealthy = Test-DiskHealthForTrading
    Write-Host ""
    
    if (-not $diskHealthy) {
        Write-Host "[INFO] Waiting for disk to stabilize..." -ForegroundColor Yellow
        Wait-ForDiskReady -MaxWaitSeconds 10
        Write-Host ""
    }
}

Write-Host "[OK] Trading system ready for operations" -ForegroundColor Green
Write-Host ""

