#Requires -Version 5.1
<#
.SYNOPSIS
    Run All Quick Start Scripts from USB and Manage Output
.DESCRIPTION
    Executes all quick start scripts from USB deployment package
    Manages and controls output for monitoring and logging
#>

param(
    [string]$USBDrive = "",
    [string]$OutputLog = ""
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  USB Quick Start Executor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Detect USB deployment
function Find-USBDeployment {
    param([string]$PreferredDrive = "")
    
    $usbDrives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
    
    if ($PreferredDrive) {
        $preferred = $usbDrives | Where-Object { $_.DeviceID -eq $PreferredDrive.TrimEnd(':') }
        if ($preferred) {
            $deployPath = Join-Path $preferred.DeviceID "Trading-System-Deployment"
            if (Test-Path $deployPath) {
                return $deployPath
            }
        }
    }
    
    foreach ($drive in $usbDrives) {
        $deployPath = Join-Path $drive.DeviceID "Trading-System-Deployment"
        if (Test-Path $deployPath) {
            return $deployPath
        }
    }
    
    return $null
}

# Find USB deployment
Write-Host "[1/5] Locating USB deployment..." -ForegroundColor Yellow
$usbDeployPath = Find-USBDeployment -PreferredDrive $USBDrive

if (-not $usbDeployPath) {
    Write-Host "[ERROR] USB deployment not found!" -ForegroundColor Red
    Write-Host "[INFO] Please ensure USB drive with deployment package is connected" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Found deployment at: $usbDeployPath" -ForegroundColor Green

# Set up logging
if ([string]::IsNullOrEmpty($OutputLog)) {
    $OutputLog = Join-Path $usbDeployPath "execution-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
}

$logDir = Split-Path $OutputLog -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $OutputLog -Value $logMessage -ErrorAction SilentlyContinue
    
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host $logMessage -ForegroundColor $color
}

Write-Log "USB Quick Start Execution Started" "INFO"
Write-Log "Deployment Path: $usbDeployPath" "INFO"
Write-Log "Output Log: $OutputLog" "INFO"

# Scripts to run in order
$scriptsToRun = @(
    @{
        Name = "Disk Monitor Setup"
        Path = "QUICK-SETUP-DISK-MONITOR.bat"
        Type = "Batch"
        Required = $true
    },
    @{
        Name = "Trading Status Check"
        Path = "check-trading-status.ps1"
        Type = "PowerShell"
        Required = $true
    },
    @{
        Name = "Trading System Start"
        Path = "QUICK-START-TRADING-SYSTEM.ps1"
        Type = "PowerShell"
        Required = $true
    }
)

$scriptsPath = Join-Path $usbDeployPath "Scripts"

Write-Host "[2/5] Verifying scripts..." -ForegroundColor Yellow
$allScriptsExist = $true
foreach ($script in $scriptsToRun) {
    $scriptPath = Join-Path $scriptsPath $script.Path
    if (Test-Path $scriptPath) {
        Write-Host "  [OK] $($script.Name)" -ForegroundColor Green
        Write-Log "Script verified: $($script.Name)" "SUCCESS"
    } else {
        Write-Host "  [ERROR] $($script.Name) not found" -ForegroundColor Red
        Write-Log "Script not found: $($script.Name)" "ERROR"
        if ($script.Required) {
            $allScriptsExist = $false
        }
    }
}

if (-not $allScriptsExist) {
    Write-Log "Required scripts missing, aborting" "ERROR"
    exit 1
}

Write-Host "[3/5] Executing scripts..." -ForegroundColor Yellow
Write-Host ""

$executionResults = @()

foreach ($script in $scriptsToRun) {
    $scriptPath = Join-Path $scriptsPath $script.Path
    $scriptName = $script.Name
    
    Write-Log "Starting: $scriptName" "INFO"
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Executing: $scriptName" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    
    $startTime = Get-Date
    $success = $false
    $errorMessage = ""
    
    try {
        if ($script.Type -eq "Batch") {
            $process = Start-Process -FilePath $scriptPath -Wait -NoNewWindow -PassThru -ErrorAction Stop
            $success = ($process.ExitCode -eq 0)
            if (-not $success) {
                $errorMessage = "Exit code: $($process.ExitCode)"
            }
        } else {
            $output = & powershell.exe -ExecutionPolicy Bypass -File $scriptPath 2>&1
            $success = ($LASTEXITCODE -eq 0)
            if ($output) {
                Write-Host $output
                Add-Content -Path $OutputLog -Value "Output: $output" -ErrorAction SilentlyContinue
            }
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        if ($success) {
            Write-Log "$scriptName completed successfully (Duration: $([math]::Round($duration, 2))s)" "SUCCESS"
            Write-Host "[OK] $scriptName completed" -ForegroundColor Green
        } else {
            Write-Log "$scriptName failed: $errorMessage (Duration: $([math]::Round($duration, 2))s)" "ERROR"
            Write-Host "[ERROR] $scriptName failed: $errorMessage" -ForegroundColor Red
        }
        
        $executionResults += @{
            Name = $scriptName
            Success = $success
            Duration = $duration
            Error = $errorMessage
        }
        
    } catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        $errorMessage = $_.Exception.Message
        Write-Log "$scriptName exception: $errorMessage (Duration: $([math]::Round($duration, 2))s)" "ERROR"
        Write-Host "[ERROR] Exception in $scriptName : $_" -ForegroundColor Red
        
        $executionResults += @{
            Name = $scriptName
            Success = $false
            Duration = $duration
            Error = $errorMessage
        }
    }
    
    Write-Host ""
    Start-Sleep -Seconds 2
}

Write-Host "[4/5] Execution Summary" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Cyan

$successCount = ($executionResults | Where-Object { $_.Success }).Count
$totalCount = $executionResults.Count

foreach ($result in $executionResults) {
    $status = if ($result.Success) { "[OK]" } else { "[FAILED]" }
    $color = if ($result.Success) { "Green" } else { "Red" }
    Write-Host "$status $($result.Name) ($([math]::Round($result.Duration, 2))s)" -ForegroundColor $color
    if (-not $result.Success -and $result.Error) {
        Write-Host "    Error: $($result.Error)" -ForegroundColor Yellow
    }
}

Write-Log "Execution Summary: $successCount/$totalCount scripts succeeded" $(if ($successCount -eq $totalCount) { "SUCCESS" } else { "WARNING" })

Write-Host ""
Write-Host "[5/5] Final Status" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Cyan

if ($successCount -eq $totalCount) {
    Write-Host "[SUCCESS] All scripts executed successfully!" -ForegroundColor Green
    Write-Log "All scripts completed successfully" "SUCCESS"
} else {
    Write-Host "[WARNING] Some scripts failed. Check log for details." -ForegroundColor Yellow
    Write-Log "Some scripts failed - review log for details" "WARNING"
}

Write-Host ""
Write-Host "Execution log saved to:" -ForegroundColor Cyan
Write-Host "  $OutputLog" -ForegroundColor White
Write-Host ""

Write-Log "USB Quick Start Execution Completed" "INFO"

# Open log file
$openLog = Read-Host "Open execution log? (Y/N)"
if ($openLog -eq 'Y' -or $openLog -eq 'y') {
    Start-Process notepad.exe -ArgumentList $OutputLog
}

