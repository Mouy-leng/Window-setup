# Windows Security Setup Automation Script
# Run this script as Administrator

param(
    [switch]$CheckOnly,
    [switch]$SkipUpdates,
    [switch]$Verbose
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Windows Security Setup Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to check Windows Defender status
function Test-WindowsDefender {
    Write-Host "Checking Windows Defender status..." -ForegroundColor Yellow
    try {
        $status = Get-MpComputerStatus
        if ($status.AntivirusEnabled) {
            Write-Host "[OK] Windows Defender is enabled" -ForegroundColor Green
            Write-Host "    Real-time protection: $($status.RealTimeProtectionEnabled)" -ForegroundColor Gray
            Write-Host "    Last quick scan: $($status.QuickScanEndTime)" -ForegroundColor Gray
        } else {
            Write-Host "[WARNING] Windows Defender is not enabled" -ForegroundColor Red
        }
    } catch {
        Write-Host "[ERROR] Could not check Windows Defender status: $_" -ForegroundColor Red
    }
}

# Function to check and update Windows Defender
function Update-WindowsDefender {
    Write-Host "Updating Windows Defender signatures..." -ForegroundColor Yellow
    try {
        Update-MpSignature
        Write-Host "[OK] Windows Defender signatures updated" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to update Windows Defender: $($_.Message)" -ForegroundColor Red
    }
}

# Function to check firewall status
function Test-Firewall {
    Write-Host "Checking Windows Firewall status..." -ForegroundColor Yellow
    try {
        $profiles = Get-NetFirewallProfile | Select-Object Name, Enabled
        foreach ($profile in $profiles) {
            if ($profile.Enabled) {
                Write-Host "[OK] Firewall $($profile.Name) profile is enabled" -ForegroundColor Green
            } else {
                Write-Host "[WARNING] Firewall $($profile.Name) profile is disabled" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "[ERROR] Could not check firewall status: $($_.Message)" -ForegroundColor Red
    }
}

# Function to enable firewall
function Enable-WindowsFirewall {
    Write-Host "Enabling Windows Firewall..." -ForegroundColor Yellow
    try {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
        Write-Host "[OK] Windows Firewall enabled for all profiles" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to enable firewall: $_" -ForegroundColor Red
    }
}

# Function to check BitLocker status
function Test-BitLocker {
    Write-Host "Checking BitLocker status..." -ForegroundColor Yellow
    try {
        $volumes = Get-BitLockerVolume
        foreach ($volume in $volumes) {
            $status = $volume.ProtectionStatus
            if ($status -eq "On") {
                Write-Host "[OK] BitLocker is enabled on $($volume.MountPoint)" -ForegroundColor Green
            } else {
                Write-Host "[INFO] BitLocker is not enabled on $($volume.MountPoint)" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "[INFO] BitLocker check not available or failed: $_" -ForegroundColor Yellow
    }
}

# Function to check SSH directory
function Test-SSHSetup {
    Write-Host "Checking SSH setup..." -ForegroundColor Yellow
    $sshPath = "$env:USERPROFILE\.ssh"
    
    if (Test-Path $sshPath) {
        Write-Host "[OK] SSH directory exists at $sshPath" -ForegroundColor Green
        
        $keyFiles = Get-ChildItem -Path $sshPath -Filter "id_*" -File
        if ($keyFiles.Count -gt 0) {
            Write-Host "[OK] Found SSH keys:" -ForegroundColor Green
            foreach ($key in $keyFiles) {
                Write-Host "    - $($key.Name)" -ForegroundColor Gray
            }
        } else {
            Write-Host "[INFO] No SSH keys found. Run setup-github-ssh.ps1 to create them." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] SSH directory does not exist. Run setup-github-ssh.ps1 to create it." -ForegroundColor Yellow
    }
}

# Function to check Git configuration
function Test-GitConfig {
    Write-Host "Checking Git configuration..." -ForegroundColor Yellow
    
    # Check if Git is installed
    try {
        $gitVersion = git --version
        Write-Host "[OK] Git is installed: $gitVersion" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Git is not installed or not in PATH" -ForegroundColor Red
        return
    }
    
    # Check user name
    $userName = git config --global user.name
    if ($userName) {
        Write-Host "[OK] Git user.name is set: $userName" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Git user.name is not set" -ForegroundColor Yellow
    }
    
    # Check user email
    $userEmail = git config --global user.email
    if ($userEmail) {
        Write-Host "[OK] Git user.email is set: $userEmail" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Git user.email is not set" -ForegroundColor Yellow
    }
    
    # Check GPG signing
    $signingKey = git config --global user.signingkey
    if ($signingKey) {
        Write-Host "[OK] Git signing key is set: $signingKey" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Git signing key is not set" -ForegroundColor Yellow
    }
    
    # Check commit signing
    $commitSign = git config --global commit.gpgsign
    if ($commitSign -eq "true") {
        Write-Host "[OK] Commit signing is enabled" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Commit signing is not enabled" -ForegroundColor Yellow
    }
}

# Function to check VSCode installation
function Test-VSCode {
    Write-Host "Checking VSCode installation..." -ForegroundColor Yellow
    
    $vscodePath = Get-Command code -ErrorAction SilentlyContinue
    if ($vscodePath) {
        Write-Host "[OK] VSCode is installed and in PATH" -ForegroundColor Green
    } else {
        Write-Host "[INFO] VSCode command not found in PATH" -ForegroundColor Yellow
    }
}

# Function to check GPG installation
function Test-GPG {
    Write-Host "Checking GPG installation..." -ForegroundColor Yellow
    
    try {
        $gpgVersion = gpg --version | Select-Object -First 1
        Write-Host "[OK] GPG is installed: $gpgVersion" -ForegroundColor Green
        
        # List GPG keys
        $keys = gpg --list-secret-keys --keyid-format=long 2>&1
        if ($keys -match "sec") {
            Write-Host "[OK] GPG secret keys found" -ForegroundColor Green
        } else {
            Write-Host "[INFO] No GPG secret keys found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[INFO] GPG is not installed or not in PATH" -ForegroundColor Yellow
    }
}

# Main execution
Write-Host ""

if (-not (Test-Administrator)) {
    Write-Host "[WARNING] This script is not running as Administrator" -ForegroundColor Red
    Write-Host "Some checks and actions require Administrator privileges" -ForegroundColor Yellow
    Write-Host ""
}

# Run checks
Test-WindowsDefender
Test-Firewall
Test-BitLocker
Test-SSHSetup
Test-GitConfig
Test-GPG
Test-VSCode

# If not check-only mode, perform setup actions
if (-not $CheckOnly) {
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "Performing Security Setup..." -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (Test-Administrator) {
        Update-WindowsDefender
        Enable-WindowsFirewall
        
        if (-not $SkipUpdates) {
            Write-Host "Checking for Windows updates..." -ForegroundColor Yellow
            Write-Host "[INFO] Please use Windows Update from Settings to install updates" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[WARNING] Administrator privileges required for automated setup" -ForegroundColor Red
        Write-Host "Please run this script as Administrator for full setup" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Security Check Complete" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run .\setup-github-ssh.ps1 to configure GitHub SSH" -ForegroundColor Gray
Write-Host "2. Run .\setup-github-gpg.ps1 to configure GPG signing" -ForegroundColor Gray
Write-Host "3. Review SECURITY_SETUP.md for detailed instructions" -ForegroundColor Gray
Write-Host ""
