# Windows Setup Script for MQL5 Trading Environment
# Security-focused setup for user and agent protection

param(
    [switch]$SecurityMode = $true,
    [switch]$InstallMQL5 = $false,
    [string]$LogPath = "$env:TEMP\windows-setup.log"
)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -Append -FilePath $LogPath
    Write-Host $Message
}

function Set-SecurityDefaults {
    Write-Log "Configuring Windows security defaults..."
    
    # Enable Windows Defender Real-time Protection
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false
        Write-Log "Windows Defender real-time protection enabled"
    } catch {
        Write-Log "Warning: Could not configure Windows Defender - $_"
    }
    
    # Configure User Account Control (UAC)
    Write-Log "Ensuring UAC is enabled..."
    $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    Set-ItemProperty -Path $uacPath -Name "EnableLUA" -Value 1 -ErrorAction SilentlyContinue
    
    # Configure Windows Firewall
    Write-Log "Enabling Windows Firewall..."
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction SilentlyContinue
}

function Set-AgentSecurity {
    Write-Log "Configuring agent security settings..."
    
    # Create secure folder for agent operations
    $agentPath = "$env:USERPROFILE\.agent-secure"
    if (-not (Test-Path $agentPath)) {
        New-Item -ItemType Directory -Path $agentPath -Force | Out-Null
        Write-Log "Created secure agent folder: $agentPath"
    }
    
    # Set folder permissions (restrict to current user)
    $acl = Get-Acl $agentPath
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
    )
    $acl.AddAccessRule($rule)
    Set-Acl -Path $agentPath -AclObject $acl
    Write-Log "Configured secure permissions for agent folder"
}

function Install-MQL5Environment {
    Write-Log "Setting up MQL5 environment..."
    
    # Create MQL5 configuration directory
    $mql5Path = "$env:APPDATA\MetaQuotes\Terminal"
    if (-not (Test-Path $mql5Path)) {
        New-Item -ItemType Directory -Path $mql5Path -Force | Out-Null
        Write-Log "Created MQL5 configuration directory"
    }
    
    # Copy security configurations
    $securityConfig = @"
; MQL5 Security Configuration
[Security]
EnableExpertAdvisors=true
AllowDllImports=false
AllowWebRequests=true
AllowedURLs=https://trusted-sources-only.com
EnableAutomatedTrading=true
MaxPositions=10
"@
    
    $configPath = Join-Path $mql5Path "security.ini"
    $securityConfig | Out-File -FilePath $configPath -Encoding UTF8
    Write-Log "MQL5 security configuration created at: $configPath"
}

function Set-NetworkSecurity {
    Write-Log "Configuring network security..."
    
    # Enable Network Level Authentication
    $rdpPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
    if (Test-Path $rdpPath) {
        Set-ItemProperty -Path $rdpPath -Name "UserAuthentication" -Value 1 -ErrorAction SilentlyContinue
        Write-Log "Network Level Authentication enabled for RDP"
    }
    
    # Disable SMBv1 for security
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue
        Write-Log "SMBv1 disabled for security"
    } catch {
        Write-Log "Warning: Could not disable SMBv1 - $_"
    }
}

# Main execution
Write-Log "=== Windows Setup Script Started ==="
Write-Log "Security Mode: $SecurityMode"
Write-Log "Install MQL5: $InstallMQL5"

if ($SecurityMode) {
    Set-SecurityDefaults
    Set-AgentSecurity
    Set-NetworkSecurity
}

if ($InstallMQL5) {
    Install-MQL5Environment
}

Write-Log "=== Windows Setup Script Completed ==="
Write-Host "`nSetup completed. Log file: $LogPath"
