#Requires -Version 5.1
<#
.SYNOPSIS
    NuNa Device Launcher - Vivobook Go E1504GEB_E1504GA
.DESCRIPTION
    Launch script optimized for NuNa device (Vivobook Go E1504GEB_E1504GA)
    Launches website and initializes device-specific automation
.NOTES
    Device: NuNa
    Model: Vivobook Go E1504GEB_E1504GA
    OS: Windows 11 Home Single Language 25H2
    Processor: Intel(R) Core(TM) i3-N305 (1.80 GHz)
    RAM: 8.00 GB
#>

$ErrorActionPreference = "Continue"

# Color scheme for output
function Write-Status {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    $timestamp = Get-Date -Format "HH:mm:ss"
    switch ($Type) {
        "INFO"    { Write-Host "[$timestamp] [INFO]    $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "[$timestamp] [OK]      $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "[$timestamp] [WARNING] $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "[$timestamp] [ERROR]   $Message" -ForegroundColor Red }
    }
}

# Header
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "   NuNa Device Launcher" -ForegroundColor Magenta
Write-Host "   Vivobook Go E1504GEB_E1504GA" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# Device validation
Write-Status "Validating NuNa device configuration..."

$deviceInfo = @{
    ExpectedProcessor = "Intel(R) Core(TM) i3-N305"
    ExpectedRAM = 8
    ExpectedOS = "Windows 11"
}

try {
    $processor = (Get-WmiObject Win32_Processor).Name
    $ram = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    $os = (Get-WmiObject Win32_OperatingSystem).Caption
    
    if ($processor -like "*$($deviceInfo.ExpectedProcessor)*") {
        Write-Status "Processor: $processor" "SUCCESS"
    } else {
        Write-Status "Processor: $processor (Expected: $($deviceInfo.ExpectedProcessor))" "WARNING"
    }
    
    if ($ram -eq $deviceInfo.ExpectedRAM) {
        Write-Status "RAM: ${ram}GB" "SUCCESS"
    } else {
        Write-Status "RAM: ${ram}GB (Expected: $($deviceInfo.ExpectedRAM)GB)" "WARNING"
    }
    
    if ($os -like "*$($deviceInfo.ExpectedOS)*") {
        Write-Status "OS: $os" "SUCCESS"
    } else {
        Write-Status "OS: $os (Expected: $($deviceInfo.ExpectedOS))" "WARNING"
    }
} catch {
    Write-Status "Could not validate device specifications: $_" "WARNING"
}

Write-Host ""

# Workspace setup
$workspaceRoot = "C:\Users\USER\OneDrive"
$logPath = Join-Path $workspaceRoot "nuna-device-launch.log"

Write-Status "Setting up workspace..."

if (Test-Path $workspaceRoot) {
    Set-Location $workspaceRoot
    Write-Status "Workspace: $workspaceRoot" "SUCCESS"
} else {
    Write-Status "Workspace not found: $workspaceRoot" "ERROR"
    exit 1
}

Write-Host ""

# Launch Website
Write-Status "Launching repository website..."

$websitePath = Join-Path $workspaceRoot "ZOLO-A6-9VxNUNA"
$websiteURL = "https://github.com/Mouy-leng/ZOLO-A6-9VxNUNA-.git"

# Clone or update website repository
if (-not (Test-Path $websitePath)) {
    Write-Status "Cloning website repository..."
    try {
        git clone $websiteURL $websitePath 2>&1 | Out-File -Append $logPath
        if (Test-Path $websitePath) {
            Write-Status "Website repository cloned" "SUCCESS"
        } else {
            Write-Status "Failed to clone website repository" "ERROR"
        }
    } catch {
        Write-Status "Error cloning repository: $_" "ERROR"
    }
} else {
    Write-Status "Updating website repository..."
    try {
        Set-Location $websitePath
        git pull origin main 2>&1 | Out-File -Append $logPath
        Write-Status "Website repository updated" "SUCCESS"
    } catch {
        Write-Status "Error updating repository: $_" "WARNING"
    }
}

Write-Host ""

# Find and launch browser
Write-Status "Launching website in browser..."

$browsers = @(
    @{
        Name = "Microsoft Edge"
        Paths = @(
            "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
            "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
        )
        Args = "--new-window"
    },
    @{
        Name = "Google Chrome"
        Paths = @(
            "C:\Program Files\Google\Chrome\Application\chrome.exe",
            "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        )
        Args = "--new-window"
    },
    @{
        Name = "Mozilla Firefox"
        Paths = @(
            "C:\Program Files\Mozilla Firefox\firefox.exe",
            "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
        )
        Args = "-new-window"
    }
)

$browserFound = $false
$launchedURL = $null

# Try to launch with GitHub Pages URL if repository has one
$githubPagesURLs = @(
    "https://mouy-leng.github.io/ZOLO-A6-9VxNUNA-/",
    "https://mouy-leng.github.io/Window-setup/",
    "https://github.com/Mouy-leng/ZOLO-A6-9VxNUNA-"
)

foreach ($browser in $browsers) {
    if ($browserFound) { break }
    
    foreach ($path in $browser.Paths) {
        if (Test-Path $path) {
            Write-Status "Found $($browser.Name)" "SUCCESS"
            
            # Try to launch GitHub Pages first, then GitHub repo
            foreach ($url in $githubPagesURLs) {
                try {
                    Start-Process -FilePath $path -ArgumentList "$($browser.Args) $url" -WindowStyle Normal
                    $launchedURL = $url
                    $browserFound = $true
                    Write-Status "Launched: $url" "SUCCESS"
                    break
                } catch {
                    Write-Status "Failed to launch $url in $($browser.Name)" "WARNING"
                }
            }
            break
        }
    }
}

if (-not $browserFound) {
    Write-Status "No browser found. Please install Microsoft Edge, Chrome, or Firefox" "ERROR"
    Write-Status "Repository location: $websitePath" "INFO"
}

Write-Host ""

# Check for Python web server (optional local server)
$pythonPath = Get-Command python -ErrorAction SilentlyContinue

if ($pythonPath -and (Test-Path $websitePath)) {
    Write-Status "Starting local web server (optional)..."
    try {
        Set-Location $websitePath
        
        # Check if server is already running
        $existingServer = Get-Process python -ErrorAction SilentlyContinue | 
            Where-Object { $_.CommandLine -like "*http.server*" }
        
        if (-not $existingServer) {
            # Start Python HTTP server in background
            $serverProcess = Start-Process python -ArgumentList "-m", "http.server", "8000" `
                -WindowStyle Hidden -PassThru
            Start-Sleep -Seconds 2
            
            if ($serverProcess -and !$serverProcess.HasExited) {
                Write-Status "Local server started at http://localhost:8000" "SUCCESS"
                Write-Status "You can also access the site locally in your browser" "INFO"
            }
        } else {
            Write-Status "Local server already running" "INFO"
        }
    } catch {
        Write-Status "Could not start local server: $_" "WARNING"
    }
}

Write-Host ""

# Device-specific optimizations for NuNa (Vivobook Go)
Write-Status "Applying NuNa device optimizations..."

try {
    # Set power plan to balanced for better performance/battery balance
    $powerPlan = powercfg /list | Select-String "Balanced"
    if ($powerPlan) {
        Write-Status "Power plan: Balanced (Recommended for Vivobook Go)" "SUCCESS"
    }
    
    # Check battery status
    $battery = Get-WmiObject Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        $batteryPercent = $battery.EstimatedChargeRemaining
        if ($batteryPercent -gt 20) {
            Write-Status "Battery: ${batteryPercent}%" "SUCCESS"
        } else {
            Write-Status "Battery: ${batteryPercent}% - Consider charging" "WARNING"
        }
    }
} catch {
    Write-Status "Could not check device optimizations" "WARNING"
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "   Launch Summary" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

Write-Status "Device: NuNa (Vivobook Go E1504GEB_E1504GA)" "INFO"
Write-Status "Workspace: $workspaceRoot" "INFO"
Write-Status "Website Repository: $websitePath" "INFO"

if ($launchedURL) {
    Write-Status "Website URL: $launchedURL" "SUCCESS"
} else {
    Write-Status "Website: Not launched (no browser found)" "WARNING"
}

Write-Status "Log file: $logPath" "INFO"

Write-Host ""
Write-Host "NuNa device launcher completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
