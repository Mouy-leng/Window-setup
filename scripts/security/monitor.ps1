# Security Monitor for Agent and User Protection
# Monitors system activities and enforces security policies

param(
    [switch]$LocalMode = $true,
    [switch]$BrowserMode = $false,
    [int]$MonitorInterval = 60,
    [string]$LogPath = "$env:TEMP\security-monitor.log"
)

function Write-SecurityLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] - $Message" | Out-File -Append -FilePath $LogPath
    
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host $Message -ForegroundColor $color
}

function Test-ProcessSecurity {
    Write-SecurityLog "Checking running processes for security threats..."
    
    # List of suspicious process names
    $suspiciousProcesses = @(
        "mimikatz", "nc", "netcat", "psexec", "procdump"
    )
    
    $runningProcesses = Get-Process | Select-Object -ExpandProperty ProcessName
    $threats = $runningProcesses | Where-Object { $suspiciousProcesses -contains $_.ToLower() }
    
    if ($threats) {
        Write-SecurityLog "WARNING: Suspicious processes detected: $($threats -join ', ')" "WARNING"
        return $false
    }
    
    Write-SecurityLog "No suspicious processes detected" "SUCCESS"
    return $true
}

function Test-NetworkConnections {
    Write-SecurityLog "Monitoring network connections..."
    
    # Check for unexpected outbound connections
    $connections = Get-NetTCPConnection -State Established | 
        Where-Object { $_.LocalAddress -ne "127.0.0.1" -and $_.LocalAddress -ne "::1" }
    
    foreach ($conn in $connections) {
        $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        if ($process) {
            Write-SecurityLog "Active connection: $($process.ProcessName) -> $($conn.RemoteAddress):$($conn.RemotePort)"
        }
    }
    
    return $true
}

function Test-FileIntegrity {
    Write-SecurityLog "Checking file integrity in critical directories..."
    
    # Define critical paths to monitor
    $criticalPaths = @(
        "$env:USERPROFILE\.agent-secure",
        "$env:APPDATA\MetaQuotes"
    )
    
    foreach ($path in $criticalPaths) {
        if (Test-Path $path) {
            $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue
            Write-SecurityLog "Monitoring $($files.Count) files in $path"
            
            # Check for recently modified files
            $recentlyModified = $files | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) }
            if ($recentlyModified) {
                Write-SecurityLog "Recently modified files in $path : $($recentlyModified.Count)" "WARNING"
            }
        }
    }
    
    return $true
}

function Test-BrowserSecurity {
    Write-SecurityLog "Checking browser security settings..."
    
    # Check if browser processes are running in secure mode
    $browserProcesses = @("chrome", "firefox", "msedge", "brave")
    $activeBrowsers = Get-Process | Where-Object { $browserProcesses -contains $_.ProcessName }
    
    if ($activeBrowsers) {
        Write-SecurityLog "Active browsers detected: $($activeBrowsers.ProcessName -join ', ')"
        Write-SecurityLog "Ensure browsers are running with appropriate security extensions"
    }
    
    return $true
}

function Test-AgentActivity {
    Write-SecurityLog "Monitoring agent activity..."
    
    $agentPath = "$env:USERPROFILE\.agent-secure"
    if (Test-Path $agentPath) {
        # Check agent log files
        $logFiles = Get-ChildItem -Path $agentPath -Filter "*.log" -ErrorAction SilentlyContinue
        
        foreach ($log in $logFiles) {
            $size = [math]::Round($log.Length / 1MB, 2)
            if ($size -gt 100) {
                Write-SecurityLog "Large agent log detected: $($log.Name) - ${size}MB" "WARNING"
            }
        }
        
        Write-SecurityLog "Agent directory monitored successfully" "SUCCESS"
    } else {
        Write-SecurityLog "Agent secure directory not found" "WARNING"
    }
    
    return $true
}

function Start-SecurityMonitoring {
    Write-SecurityLog "=== Security Monitoring Started ===" "SUCCESS"
    Write-SecurityLog "Mode: $(if($LocalMode){'Local'}else{'Remote'}), Browser Mode: $BrowserMode"
    Write-SecurityLog "Monitor Interval: $MonitorInterval seconds"
    
    $iteration = 0
    while ($true) {
        $iteration++
        Write-SecurityLog "`n--- Security Check Iteration $iteration ---"
        
        # Run security checks
        Test-ProcessSecurity
        Test-NetworkConnections
        Test-FileIntegrity
        Test-AgentActivity
        
        if ($BrowserMode) {
            Test-BrowserSecurity
        }
        
        Write-SecurityLog "Sleeping for $MonitorInterval seconds..."
        Start-Sleep -Seconds $MonitorInterval
    }
}

# Main execution
Write-SecurityLog "Initializing Security Monitor..." "SUCCESS"
Write-SecurityLog "Log Path: $LogPath"

# Create secure directory if it doesn't exist
$securePath = "$env:USERPROFILE\.agent-secure"
if (-not (Test-Path $securePath)) {
    New-Item -ItemType Directory -Path $securePath -Force | Out-Null
    Write-SecurityLog "Created secure directory: $securePath" "SUCCESS"
}

# Start monitoring
Start-SecurityMonitoring
