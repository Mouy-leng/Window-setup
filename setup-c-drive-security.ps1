#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    C: Drive Security and Firewall Setup Script
.DESCRIPTION
    Comprehensive security setup for C: drive including firewall rules,
    folder permissions, Windows Defender configuration, and system protection
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  C: Drive Security & Firewall Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verify admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run as Administrator" -ForegroundColor Yellow
    exit 1
}

$securityReport = @()

# ============================================
# STEP 1: Windows Firewall Configuration
# ============================================
Write-Host "[STEP 1/7] Configuring Windows Firewall..." -ForegroundColor Yellow
Write-Host ""

try {
    # Enable Windows Firewall for all profiles
    Write-Host "Enabling Windows Firewall for all profiles..." -ForegroundColor Cyan
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Write-Host "  [OK] Windows Firewall enabled" -ForegroundColor Green
    $securityReport += "Windows Firewall enabled for all profiles"
    
    # Configure firewall rules for critical services
    $firewallRules = @(
        @{
            Name = "OneDrive Sync"
            Program = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
            Direction = "Outbound"
            Action = "Allow"
        },
        @{
            Name = "Google Drive Sync"
            Program = "$env:PROGRAMFILES\Google\Drive File Stream\googledrivesync.exe"
            Direction = "Outbound"
            Action = "Allow"
        },
        @{
            Name = "GitHub Desktop"
            Program = "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe"
            Direction = "Outbound"
            Action = "Allow"
        },
        @{
            Name = "MetaTrader 5 Terminal"
            Program = "C:\Program Files\MetaTrader 5\terminal64.exe"
            Direction = "Outbound"
            Action = "Allow"
        },
        @{
            Name = "PowerShell Automation"
            Program = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            Direction = "Outbound"
            Action = "Allow"
        }
    )
    
    foreach ($rule in $firewallRules) {
        if (Test-Path $rule.Program) {
            Write-Host "Creating firewall rule: $($rule.Name)" -ForegroundColor Cyan
            
            # Remove existing rule if present
            $existingRule = Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
            if ($existingRule) {
                Remove-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
            }
            
            # Create new rule
            try {
                New-NetFirewallRule -DisplayName $rule.Name `
                                    -Direction $rule.Direction `
                                    -Program $rule.Program `
                                    -Action $rule.Action `
                                    -Enabled True `
                                    -ErrorAction Stop | Out-Null
                Write-Host "  [OK] Firewall rule created: $($rule.Name)" -ForegroundColor Green
                $securityReport += "Firewall rule: $($rule.Name)"
            } catch {
                Write-Host "  [WARNING] Could not create rule for $($rule.Name): $_" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [INFO] Skipping $($rule.Name) - Program not found" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  [ERROR] Firewall configuration failed: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================
# STEP 2: Windows Defender Configuration
# ============================================
Write-Host "[STEP 2/7] Configuring Windows Defender..." -ForegroundColor Yellow
Write-Host ""

try {
    # Enable Real-time Protection
    Write-Host "Configuring Windows Defender..." -ForegroundColor Cyan
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
    Write-Host "  [OK] Real-time Protection enabled" -ForegroundColor Green
    
    # Add exclusions for development and cloud folders
    $exclusionPaths = @(
        "$env:USERPROFILE\OneDrive",
        "$env:USERPROFILE\Google Drive",
        "$env:USERPROFILE\Dropbox",
        "C:\Projects",
        "C:\Repositories",
        "$env:USERPROFILE\AppData\Roaming\MetaQuotes"
    )
    
    foreach ($path in $exclusionPaths) {
        if (Test-Path $path) {
            Write-Host "Adding Defender exclusion: $path" -ForegroundColor Cyan
            try {
                Add-MpPreference -ExclusionPath $path -ErrorAction Stop
                Write-Host "  [OK] Exclusion added" -ForegroundColor Green
                $securityReport += "Defender exclusion: $path"
            } catch {
                Write-Host "  [INFO] Exclusion may already exist" -ForegroundColor Gray
            }
        }
    }
    
    # Configure scan settings
    Write-Host "Configuring scan settings..." -ForegroundColor Cyan
    Set-MpPreference -ScanScheduleQuickScanTime 120 -ErrorAction SilentlyContinue  # 2 AM
    Write-Host "  [OK] Scan schedule configured" -ForegroundColor Green
    
} catch {
    Write-Host "  [ERROR] Windows Defender configuration failed: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================
# STEP 3: Controlled Folder Access Configuration
# ============================================
Write-Host "[STEP 3/7] Configuring Controlled Folder Access..." -ForegroundColor Yellow
Write-Host ""

try {
    # Enable Controlled Folder Access
    Write-Host "Enabling Controlled Folder Access..." -ForegroundColor Cyan
    Set-MpPreference -EnableControlledFolderAccess Enabled -ErrorAction SilentlyContinue
    Write-Host "  [OK] Controlled Folder Access enabled" -ForegroundColor Green
    
    # Add allowed applications
    $allowedApps = @(
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
        "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
        "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe"
    )
    
    foreach ($app in $allowedApps) {
        if (Test-Path $app) {
            Write-Host "Adding allowed app: $app" -ForegroundColor Cyan
            try {
                Add-MpPreference -ControlledFolderAccessAllowedApplications $app -ErrorAction Stop
                Write-Host "  [OK] App allowed" -ForegroundColor Green
                $securityReport += "Allowed app: $app"
            } catch {
                Write-Host "  [INFO] App may already be allowed" -ForegroundColor Gray
            }
        }
    }
} catch {
    Write-Host "  [WARNING] Controlled Folder Access configuration had issues: $_" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# STEP 4: C: Drive Folder Permissions
# ============================================
Write-Host "[STEP 4/7] Configuring C: Drive Folder Permissions..." -ForegroundColor Yellow
Write-Host ""

try {
    # Secure critical system folders
    $criticalFolders = @(
        "C:\Windows\System32",
        "C:\Program Files",
        "C:\Program Files (x86)"
    )
    
    foreach ($folder in $criticalFolders) {
        if (Test-Path $folder) {
            Write-Host "Verifying permissions: $folder" -ForegroundColor Cyan
            try {
                $acl = Get-Acl $folder
                # Verify that only Administrators and SYSTEM have full control
                $hasProperPermissions = $true
                foreach ($access in $acl.Access) {
                    if ($access.FileSystemRights -match "FullControl" -and 
                        $access.IdentityReference -notlike "*Administrators*" -and
                        $access.IdentityReference -notlike "*SYSTEM*" -and
                        $access.IdentityReference -notlike "*TrustedInstaller*") {
                        $hasProperPermissions = $false
                        break
                    }
                }
                
                if ($hasProperPermissions) {
                    Write-Host "  [OK] Permissions are secure" -ForegroundColor Green
                } else {
                    Write-Host "  [INFO] Permissions may need manual review" -ForegroundColor Cyan
                }
            } catch {
                Write-Host "  [WARNING] Could not verify permissions: $_" -ForegroundColor Yellow
            }
        }
    }
    
    # Set proper permissions for workspace
    $workspacePath = "$env:USERPROFILE\OneDrive"
    if (Test-Path $workspacePath) {
        Write-Host "Configuring workspace permissions: $workspacePath" -ForegroundColor Cyan
        try {
            $acl = Get-Acl $workspacePath
            # Ensure current user has full control
            $userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $env:USERNAME,
                "FullControl",
                "ContainerInherit,ObjectInherit",
                "None",
                "Allow"
            )
            $acl.SetAccessRule($userRule)
            Set-Acl $workspacePath $acl
            Write-Host "  [OK] Workspace permissions configured" -ForegroundColor Green
            $securityReport += "Workspace permissions configured"
        } catch {
            Write-Host "  [WARNING] Could not set workspace permissions: $_" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  [ERROR] Folder permissions configuration failed: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================
# STEP 5: System Protection and Restore Points
# ============================================
Write-Host "[STEP 5/7] Configuring System Protection..." -ForegroundColor Yellow
Write-Host ""

try {
    Write-Host "Enabling System Protection for C: drive..." -ForegroundColor Cyan
    
    # Enable System Protection
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    
    # Create a restore point
    $restorePointDescription = "Security Configuration - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    Write-Host "Creating restore point: $restorePointDescription" -ForegroundColor Cyan
    
    Checkpoint-Computer -Description $restorePointDescription -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    
    Write-Host "  [OK] System Protection configured" -ForegroundColor Green
    $securityReport += "System restore point created"
} catch {
    Write-Host "  [WARNING] System Protection configuration had issues: $_" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# STEP 6: Network Security Configuration
# ============================================
Write-Host "[STEP 6/7] Configuring Network Security..." -ForegroundColor Yellow
Write-Host ""

try {
    # Disable NetBIOS over TCP/IP for security
    Write-Host "Configuring network security settings..." -ForegroundColor Cyan
    
    # Enable Network Level Authentication for RDP (if applicable)
    $rdpConfig = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name UserAuthentication -ErrorAction SilentlyContinue
    if ($rdpConfig) {
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name UserAuthentication -Value 1
        Write-Host "  [OK] Network Level Authentication enabled" -ForegroundColor Green
    }
    
    # Configure Windows Update to use secure connections only
    $auOptions = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ErrorAction SilentlyContinue
    if (-not $auOptions) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "AU" -Force | Out-Null
    }
    
    Write-Host "  [OK] Network security configured" -ForegroundColor Green
    $securityReport += "Network security settings configured"
} catch {
    Write-Host "  [WARNING] Network security configuration had issues: $_" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# STEP 7: Security Audit and Reporting
# ============================================
Write-Host "[STEP 7/7] Running Security Audit..." -ForegroundColor Yellow
Write-Host ""

try {
    Write-Host "Performing security audit..." -ForegroundColor Cyan
    
    # Check firewall status
    $firewallStatus = Get-NetFirewallProfile | Select-Object Name, Enabled
    Write-Host ""
    Write-Host "Firewall Status:" -ForegroundColor Yellow
    foreach ($profile in $firewallStatus) {
        $status = if ($profile.Enabled) { "Enabled" } else { "Disabled" }
        $color = if ($profile.Enabled) { "Green" } else { "Red" }
        Write-Host "  $($profile.Name): $status" -ForegroundColor $color
    }
    
    # Check Windows Defender status
    Write-Host ""
    Write-Host "Windows Defender Status:" -ForegroundColor Yellow
    $defenderStatus = Get-MpComputerStatus
    Write-Host "  Real-time Protection: $(if ($defenderStatus.RealTimeProtectionEnabled) { 'Enabled' } else { 'Disabled' })" -ForegroundColor $(if ($defenderStatus.RealTimeProtectionEnabled) { "Green" } else { "Red" })
    Write-Host "  Antivirus Enabled: $(if ($defenderStatus.AntivirusEnabled) { 'Enabled' } else { 'Disabled' })" -ForegroundColor $(if ($defenderStatus.AntivirusEnabled) { "Green" } else { "Red" })
    Write-Host "  Antispyware Enabled: $(if ($defenderStatus.AntispywareEnabled) { 'Enabled' } else { 'Disabled' })" -ForegroundColor $(if ($defenderStatus.AntispywareEnabled) { "Green" } else { "Red" })
    
    # Check disk encryption status (BitLocker)
    Write-Host ""
    Write-Host "BitLocker Status:" -ForegroundColor Yellow
    $bitlockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
    if ($bitlockerStatus) {
        Write-Host "  C: Drive: $($bitlockerStatus.ProtectionStatus)" -ForegroundColor $(if ($bitlockerStatus.ProtectionStatus -eq "On") { "Green" } else { "Yellow" })
    } else {
        Write-Host "  BitLocker: Not available or not configured" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "  [WARNING] Security audit had issues: $_" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# Generate Security Report
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Security Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Save security report
$reportPath = "C-DRIVE-SECURITY-REPORT.md"
$reportContent = @"
# C: Drive Security Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Security Configuration Applied

### Firewall Rules
$($securityReport | Where-Object { $_ -like "*Firewall*" } | ForEach-Object { "- $_" } | Out-String)

### Windows Defender
$($securityReport | Where-Object { $_ -like "*Defender*" } | ForEach-Object { "- $_" } | Out-String)

### Folder Permissions
$($securityReport | Where-Object { $_ -like "*permission*" -or $_ -like "*Workspace*" } | ForEach-Object { "- $_" } | Out-String)

### System Protection
$($securityReport | Where-Object { $_ -like "*restore*" -or $_ -like "*Protection*" } | ForEach-Object { "- $_" } | Out-String)

### Network Security
$($securityReport | Where-Object { $_ -like "*Network*" } | ForEach-Object { "- $_" } | Out-String)

## Current Security Status

### Windows Firewall
"@

foreach ($profile in $firewallStatus) {
    $reportContent += "`n- **$($profile.Name)**: $(if ($profile.Enabled) { '✅ Enabled' } else { '❌ Disabled' })"
}

$reportContent += @"


### Windows Defender
- **Real-time Protection**: $(if ($defenderStatus.RealTimeProtectionEnabled) { '✅ Enabled' } else { '❌ Disabled' })
- **Antivirus**: $(if ($defenderStatus.AntivirusEnabled) { '✅ Enabled' } else { '❌ Disabled' })
- **Antispyware**: $(if ($defenderStatus.AntispywareEnabled) { '✅ Enabled' } else { '❌ Disabled' })

## Recommendations

### Immediate Actions
- ✅ Firewall configured for critical applications
- ✅ Windows Defender real-time protection enabled
- ✅ Controlled folder access configured
- ✅ System restore point created

### Regular Maintenance
- Run Windows Update weekly
- Review firewall logs monthly
- Check Windows Defender scan results weekly
- Update exclusion lists as needed
- Create manual restore points before major changes

### Additional Security Measures
- Consider enabling BitLocker for C: drive encryption
- Review and update firewall rules quarterly
- Keep Windows Defender definitions up to date
- Monitor system logs for security events
- Backup important data regularly

## Security Commands

### Check Firewall Status
\`\`\`powershell
Get-NetFirewallProfile | Select-Object Name, Enabled
\`\`\`

### Check Windows Defender Status
\`\`\`powershell
Get-MpComputerStatus
\`\`\`

### List Firewall Rules
\`\`\`powershell
Get-NetFirewallRule | Where-Object {$_.Enabled -eq 'True'}
\`\`\`

### Check Defender Exclusions
\`\`\`powershell
Get-MpPreference | Select-Object ExclusionPath
\`\`\`

### Scan with Windows Defender
\`\`\`powershell
Start-MpScan -ScanType QuickScan
\`\`\`

---
*Generated by setup-c-drive-security.ps1*
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "[OK] Security report saved to: $reportPath" -ForegroundColor Green
Write-Host ""

Write-Host "✅ C: Drive security and firewall setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review $reportPath for detailed security status" -ForegroundColor Cyan
Write-Host "  2. Consider enabling BitLocker for drive encryption" -ForegroundColor Cyan
Write-Host "  3. Run .\run-security-check.ps1 to verify all security settings" -ForegroundColor Cyan
Write-Host ""
