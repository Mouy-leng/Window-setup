#Requires -Version 5.1
<#
.SYNOPSIS
    Real-Time Disk Performance Monitor for Trading System Stability
.DESCRIPTION
    Continuously monitors Disk 0 (Patriot P410 SSD) performance metrics:
    - Active time (alerts if > 90%)
    - Read/Write speeds
    - Average response time (alerts if > 50ms)
    - Automatically optimizes disk I/O when critical thresholds are exceeded
    - Ensures trading operations have priority access
.PARAMETER Interval
    Monitoring interval in seconds (default: 5)
.PARAMETER CriticalActiveTime
    Critical active time threshold percentage (default: 90)
.PARAMETER CriticalResponseTime
    Critical response time threshold in milliseconds (default: 50)
.PARAMETER LogFile
    Path to log file (default: OneDrive\disk-performance-monitor.log)
.PARAMETER EnableOptimization
    Enable automatic disk I/O optimization when thresholds exceeded (default: true)
#>

param(
    [int]$Interval = 5,
    [int]$CriticalActiveTime = 90,
    [int]$CriticalResponseTime = 50,
    [string]$LogFile = "",
    [switch]$EnableOptimization = $true
)

$ErrorActionPreference = "Continue"

# Set log file path
if ([string]::IsNullOrEmpty($LogFile)) {
    $LogFile = Join-Path $env:USERPROFILE "OneDrive\disk-performance-monitor.log"
}

# Create log directory if needed
$logDir = Split-Path $LogFile -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
    
    $color = switch ($Level) {
        "CRITICAL" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        "OPTIMIZE" { "Magenta" }
        default { "White" }
    }
    Write-Host $logMessage -ForegroundColor $color
}

function Get-DiskPerformance {
    param([int]$DiskNumber = 0)
    
    try {
        # Get physical disk
        $physicalDisk = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq $DiskNumber }
        if (-not $physicalDisk) {
            return $null
        }
        
        # Get performance counters for Disk 0
        $counters = @(
            "\PhysicalDisk(0 C: D:)\% Disk Time",
            "\PhysicalDisk(0 C: D:)\Avg. Disk sec/Read",
            "\PhysicalDisk(0 C: D:)\Avg. Disk sec/Write",
            "\PhysicalDisk(0 C: D:)\Disk Reads/sec",
            "\PhysicalDisk(0 C: D:)\Disk Writes/sec",
            "\PhysicalDisk(0 C: D:)\Disk Read Bytes/sec",
            "\PhysicalDisk(0 C: D:)\Disk Write Bytes/sec"
        )
        
        $perfData = Get-Counter -Counter $counters -ErrorAction SilentlyContinue
        
        if (-not $perfData) {
            # Fallback: Try individual drive letters
            $cDriveCounter = Get-Counter "\PhysicalDisk(0 C:)\% Disk Time" -ErrorAction SilentlyContinue
            if ($cDriveCounter) {
                $perfData = $cDriveCounter
            }
        }
        
        if ($perfData) {
            $samples = $perfData.CounterSamples
            
            # Extract metrics
            $diskTime = 0
            $avgReadTime = 0
            $avgWriteTime = 0
            $readSpeed = 0
            $writeSpeed = 0
            $readBytes = 0
            $writeBytes = 0
            
            foreach ($sample in $samples) {
                $path = $sample.Path
                $value = $sample.CookedValue
                
                if ($path -like "*% Disk Time*") {
                    $diskTime = [math]::Round($value, 1)
                } elseif ($path -like "*Avg. Disk sec/Read*") {
                    $avgReadTime = [math]::Round($value * 1000, 2)  # Convert to ms
                } elseif ($path -like "*Avg. Disk sec/Write*") {
                    $avgWriteTime = [math]::Round($value * 1000, 2)  # Convert to ms
                } elseif ($path -like "*Disk Read Bytes/sec*") {
                    $readBytes = $value
                    $readSpeed = [math]::Round($value / 1MB, 2)  # MB/s
                } elseif ($path -like "*Disk Write Bytes/sec*") {
                    $writeBytes = $value
                    $writeSpeed = [math]::Round($value / 1KB, 2)  # KB/s
                }
            }
            
            # Calculate average response time
            $avgResponseTime = [math]::Round(($avgReadTime + $avgWriteTime) / 2, 1)
            
            return @{
                ActiveTime = $diskTime
                ReadSpeed = $readSpeed
                WriteSpeed = $writeSpeed
                AvgResponseTime = $avgResponseTime
                ReadBytes = $readBytes
                WriteBytes = $writeBytes
                Timestamp = Get-Date
            }
        }
    } catch {
        Write-Log "Error getting disk performance: $_" "WARNING"
    }
    
    return $null
}

function Optimize-DiskIO {
    Write-Log "Starting disk I/O optimization..." "OPTIMIZE"
    
    try {
        # 1. Stop unnecessary Windows services temporarily
        $servicesToStop = @(
            "SysMain",  # Superfetch (can cause high disk usage)
            "WSearch"   # Windows Search (can cause high disk usage)
        )
        
        foreach ($serviceName in $servicesToStop) {
            try {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service -and $service.Status -eq "Running") {
                    Write-Log "Stopping service: $serviceName" "OPTIMIZE"
                    Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Milliseconds 500
                }
            } catch {
                # Service may not exist or may not be stoppable
            }
        }
        
        # 2. Clear Windows temporary files (non-blocking)
        Write-Log "Clearing temporary files..." "OPTIMIZE"
        $tempPaths = @(
            "$env:TEMP\*",
            "$env:LOCALAPPDATA\Temp\*"
        )
        
        foreach ($tempPath in $tempPaths) {
            try {
                if (Test-Path $tempPath) {
                    Get-ChildItem -Path $tempPath -Recurse -ErrorAction SilentlyContinue | 
                        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
                        Remove-Item -Force -ErrorAction SilentlyContinue
                }
            } catch {
                # Continue if cleanup fails
            }
        }
        
        # 3. Set process priorities for trading processes
        Write-Log "Optimizing trading process priorities..." "OPTIMIZE"
        $tradingProcesses = @(
            "python",
            "terminal64",
            "mt5"
        )
        
        foreach ($procName in $tradingProcesses) {
            try {
                $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
                foreach ($proc in $procs) {
                    try {
                        $proc.PriorityClass = "High"
                        Write-Log "Set $procName (PID: $($proc.Id)) to High priority" "OPTIMIZE"
                    } catch {
                        # May require admin rights
                    }
                }
            } catch {
                # Process may not be running
            }
        }
        
        # 4. Flush file system cache (requires admin)
        try {
            $fsutil = Get-Command fsutil -ErrorAction SilentlyContinue
            if ($fsutil) {
                Write-Log "Flushing file system cache..." "OPTIMIZE"
                Start-Process -FilePath "fsutil" -ArgumentList "behavior", "set", "DisableDeleteNotify", "0" -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {
            # May require admin rights
        }
        
        Write-Log "Disk I/O optimization completed" "SUCCESS"
        
    } catch {
        Write-Log "Error during disk optimization: $_" "WARNING"
    }
}

function Test-TradingSystemHealth {
    # Check if trading processes are running and responsive
    $tradingHealthy = $true
    $issues = @()
    
    try {
        # Check Python trading bridge
        $pythonProcs = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
            $_.CommandLine -like "*trading*" -or $_.CommandLine -like "*bridge*"
        }
        
        if (-not $pythonProcs) {
            $tradingHealthy = $false
            $issues += "Python trading bridge not running"
        }
        
        # Check MQL5 terminal
        $mt5Procs = Get-Process -Name "terminal64" -ErrorAction SilentlyContinue
        if (-not $mt5Procs) {
            $issues += "MQL5 terminal not running (optional)"
        }
        
    } catch {
        Write-Log "Error checking trading system health: $_" "WARNING"
    }
    
    return @{
        Healthy = $tradingHealthy
        Issues = $issues
    }
}

# Main monitoring loop
Write-Log "========================================"
Write-Log "Disk Performance Monitor Started" "SUCCESS"
Write-Log "Monitoring Disk 0 (Patriot P410 1TB SSD)" "INFO"
Write-Log "Interval: $Interval seconds" "INFO"
Write-Log "Critical Active Time: $CriticalActiveTime%" "INFO"
Write-Log "Critical Response Time: ${CriticalResponseTime}ms" "INFO"
Write-Log "Optimization: $EnableOptimization" "INFO"
Write-Log "========================================"

$consecutiveCriticalCount = 0
$lastOptimizationTime = $null
$optimizationCooldown = 300  # 5 minutes between optimizations

while ($true) {
    try {
        $perf = Get-DiskPerformance -DiskNumber 0
        
        if ($perf) {
            $activeTime = $perf.ActiveTime
            $responseTime = $perf.AvgResponseTime
            $readSpeed = $perf.ReadSpeed
            $writeSpeed = $perf.WriteSpeed
            
            # Check for critical conditions
            $isCritical = $false
            $criticalReason = @()
            
            if ($activeTime -ge $CriticalActiveTime) {
                $isCritical = $true
                $criticalReason += "Active time: ${activeTime}%"
                $consecutiveCriticalCount++
            } else {
                $consecutiveCriticalCount = 0
            }
            
            if ($responseTime -ge $CriticalResponseTime) {
                $isCritical = $true
                $criticalReason += "Response time: ${responseTime}ms"
            }
            
            # Log current status
            if ($isCritical) {
                Write-Log "CRITICAL: Disk performance degraded - $($criticalReason -join ', ')" "CRITICAL"
                Write-Log "  Read: ${readSpeed} MB/s | Write: ${writeSpeed} KB/s" "CRITICAL"
                
                # Check trading system health
                $tradingHealth = Test-TradingSystemHealth
                if (-not $tradingHealth.Healthy) {
                    Write-Log "WARNING: Trading system may be affected by disk I/O issues" "WARNING"
                    foreach ($issue in $tradingHealth.Issues) {
                        Write-Log "  - $issue" "WARNING"
                    }
                }
                
                # Trigger optimization if enabled and cooldown expired
                if ($EnableOptimization) {
                    $shouldOptimize = $false
                    
                    if ($null -eq $lastOptimizationTime) {
                        $shouldOptimize = $true
                    } else {
                        $timeSinceLastOptimization = (Get-Date) - $lastOptimizationTime
                        if ($timeSinceLastOptimization.TotalSeconds -ge $optimizationCooldown) {
                            $shouldOptimize = $true
                        }
                    }
                    
                    # Optimize if critical for 3+ consecutive checks
                    if ($shouldOptimize -and $consecutiveCriticalCount -ge 3) {
                        Write-Log "Triggering automatic disk optimization..." "OPTIMIZE"
                        Optimize-DiskIO
                        $lastOptimizationTime = Get-Date
                        $consecutiveCriticalCount = 0
                    }
                }
            } else {
                # Normal operation
                if ($activeTime -gt 50) {
                    Write-Log "Disk active: ${activeTime}% | Response: ${responseTime}ms | Read: ${readSpeed} MB/s | Write: ${writeSpeed} KB/s" "INFO"
                } else {
                    # Only log every 12 checks (1 minute at 5s interval) when healthy
                    if ((Get-Date).Second % 60 -lt $Interval) {
                        Write-Log "Disk healthy: ${activeTime}% active | ${responseTime}ms response | Read: ${readSpeed} MB/s | Write: ${writeSpeed} KB/s" "SUCCESS"
                    }
                }
            }
        } else {
            Write-Log "Could not retrieve disk performance data" "WARNING"
        }
        
    } catch {
        Write-Log "Error in monitoring loop: $_" "WARNING"
    }
    
    Start-Sleep -Seconds $Interval
}

