# Installation and Setup Guide

## Overview

This guide provides step-by-step instructions for setting up a secure Windows/Linux environment for MQL5 trading with enhanced security features for user and agent protection.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Windows Installation](#windows-installation)
3. [Linux Installation](#linux-installation)
4. [MQL5 Setup](#mql5-setup)
5. [Browser Mode Setup](#browser-mode-setup)
6. [Security Configuration](#security-configuration)
7. [Verification](#verification)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### For Windows

- Windows 10/11 (64-bit recommended)
- PowerShell 5.1 or higher
- Administrator privileges
- 4GB RAM minimum (8GB recommended)
- 10GB free disk space

### For Linux

- Ubuntu 20.04/22.04, Debian 11+, or compatible distribution
- Bash shell
- sudo access
- 4GB RAM minimum (8GB recommended)
- 10GB free disk space

### For MQL5 Trading

- MetaTrader 5 platform
- Trading account (demo or real)
- Internet connection
- Valid broker connection

## Windows Installation

### Step 1: Clone the Repository

```powershell
# Open PowerShell as Administrator
git clone https://github.com/Mouy-leng/Window-setup.git
cd Window-setup
```

### Step 2: Run the Setup Script

```powershell
# Enable script execution (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run the setup script
.\scripts\windows\setup.ps1 -SecurityMode -InstallMQL5

# Or run without MQL5 installation
.\scripts\windows\setup.ps1 -SecurityMode
```

### Step 3: Verify Installation

```powershell
# Check if security features are enabled
Get-MpPreference | Select-Object DisableRealtimeMonitoring

# Verify firewall status
Get-NetFirewallProfile | Select-Object Name, Enabled

# Check agent directory
Test-Path "$env:USERPROFILE\.agent-secure"
```

### Step 4: Configure Windows Defender Exclusions (Optional)

If you experience performance issues with MetaTrader:

```powershell
# Add MetaTrader to exclusions
Add-MpPreference -ExclusionPath "C:\Program Files\MetaTrader 5"
Add-MpPreference -ExclusionProcess "terminal64.exe"
```

## Linux Installation

### Step 1: Clone the Repository

```bash
# Open terminal
git clone https://github.com/Mouy-leng/Window-setup.git
cd Window-setup
```

### Step 2: Make Scripts Executable

```bash
# Make all scripts executable
chmod +x scripts/linux/*.sh
chmod +x scripts/security/*.sh
```

### Step 3: Run the Setup Script

```bash
# Run with sudo for system-level changes
sudo ./scripts/linux/setup.sh --install-mql5

# Or run without MQL5 installation
sudo ./scripts/linux/setup.sh
```

### Step 4: Verify Installation

```bash
# Check firewall status
sudo ufw status

# Verify Wine installation (if MQL5 was installed)
wine --version

# Check agent directory
ls -la ~/.agent-secure
```

### Step 5: Configure Wine for MQL5 (if needed)

```bash
# Set Wine prefix
export WINEPREFIX="$HOME/.wine-mql5"

# Configure Wine
winecfg

# Install additional components if needed
winetricks corefonts vcrun2019
```

## MQL5 Setup

### Step 1: Install MetaTrader 5

#### Windows

1. Download MT5 from your broker's website
2. Run the installer
3. Complete the installation wizard
4. Launch MetaTrader 5

#### Linux (Wine)

```bash
# Download MT5 installer (replace URL with your broker's)
wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe

# Install with Wine
export WINEPREFIX="$HOME/.wine-mql5"
wine mt5setup.exe
```

### Step 2: Copy Security Configuration

#### Windows

```powershell
# Copy security configuration
$mtPath = "$env:APPDATA\MetaQuotes\Terminal"
Copy-Item "mql5\configs\security.ini" -Destination "$mtPath\security.ini"
```

#### Linux

```bash
# Copy security configuration
MT_PATH="$HOME/.wine-mql5/drive_c/users/$USER/AppData/Roaming/MetaQuotes/Terminal"
mkdir -p "$MT_PATH"
cp mql5/configs/security.ini "$MT_PATH/security.ini"
```

### Step 3: Install Secure Trading EA

1. Open MetaTrader 5
2. Go to File → Open Data Folder
3. Navigate to MQL5 → Experts
4. Copy `mql5/security/SecureTrading.mq5` to this folder
5. In MT5, go to Tools → MetaQuotes Language Editor
6. Open `SecureTrading.mq5` and compile it (F7)

### Step 4: Configure EA Settings

1. In MT5 Navigator, find "SecureTrading" under Expert Advisors
2. Right-click → Properties
3. Configure security settings:
   - Enable Security: true
   - Max Risk Per Trade: 0.02 (2%)
   - Max Daily Trades: 50
   - Log All Operations: true
4. Enable AutoTrading in MT5 (top toolbar)

## Browser Mode Setup

### Step 1: Open the Dashboard

#### Direct File Access

```bash
# Windows
start browser-support\dashboard.html

# Linux
xdg-open browser-support/dashboard.html

# macOS
open browser-support/dashboard.html
```

#### Using Local Server (Recommended)

**Python:**
```bash
cd browser-support
python -m http.server 8080
```

**Node.js:**
```bash
cd browser-support
npx http-server -p 8080
```

Then navigate to: `http://localhost:8080/dashboard.html`

### Step 2: Start Monitoring

1. Click "Start Monitoring" button
2. Verify the connection status turns green
3. Check the activity log for updates

### Step 3: Configure Browser Security

Recommended browser extensions:
- uBlock Origin (ad blocking)
- HTTPS Everywhere (force HTTPS)
- Privacy Badger (tracker blocking)

## Security Configuration

### Agent Security Setup

#### Windows

```powershell
# Create agent configuration
$agentPath = "$env:USERPROFILE\.agent-secure"
$config = @"
[Security]
SandboxEnabled=true
MaxMemoryMB=512
MaxCPUPercent=50
AllowedDomains=localhost,api.tradingview.com
"@
$config | Out-File -FilePath "$agentPath\config.ini" -Encoding UTF8
```

#### Linux

```bash
# Create agent configuration
cat > ~/.agent-secure/config.ini <<EOF
[Security]
SandboxEnabled=true
MaxMemoryMB=512
MaxCPUPercent=50
AllowedDomains=localhost,api.tradingview.com
EOF
chmod 600 ~/.agent-secure/config.ini
```

### Start Security Monitoring

#### Windows

```powershell
# Start monitoring in new window
Start-Process powershell -ArgumentList "-File scripts\security\monitor.ps1 -LocalMode -BrowserMode"
```

#### Linux

```bash
# Start monitoring in background
./scripts/security/monitor.sh --browser-mode --interval 60 &
```

## Verification

### Test Checklist

Run through this checklist to verify your installation:

#### Security Features

- [ ] Windows Defender / Antivirus is running
- [ ] Firewall is enabled
- [ ] UAC is enabled (Windows)
- [ ] Agent secure directory exists with proper permissions
- [ ] Security monitoring script runs without errors

#### MQL5 Setup

- [ ] MetaTrader 5 is installed and running
- [ ] Security configuration is in place
- [ ] SecureTrading EA compiles without errors
- [ ] EA loads on chart successfully
- [ ] AutoTrading is enabled

#### Browser Mode

- [ ] Dashboard opens in browser
- [ ] Monitoring can be started/stopped
- [ ] Security checks run successfully
- [ ] Logs are being recorded

### Verification Commands

#### Windows

```powershell
# Verify security features
.\scripts\windows\setup.ps1 -Verify

# Check agent status
Test-Path "$env:USERPROFILE\.agent-secure"
Get-ChildItem "$env:USERPROFILE\.agent-secure"

# Check MQL5 configuration
Get-Content "$env:APPDATA\MetaQuotes\Terminal\security.ini"
```

#### Linux

```bash
# Verify security features
./scripts/linux/setup.sh --verify

# Check agent status
ls -la ~/.agent-secure

# Check MQL5 configuration
cat "$HOME/.wine-mql5/drive_c/users/$USER/AppData/Roaming/MetaQuotes/Terminal/security.ini"
```

## Troubleshooting

### Common Issues

#### Issue: PowerShell Script Won't Run

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Issue: Linux Script Permission Denied

**Solution:**
```bash
chmod +x scripts/linux/setup.sh
chmod +x scripts/security/monitor.sh
```

#### Issue: MetaTrader Won't Start in Wine

**Solution:**
```bash
# Install additional Wine dependencies
winetricks vcrun2019 corefonts

# Update Wine to latest version
sudo apt update
sudo apt upgrade wine
```

#### Issue: Security Monitor Not Logging

**Solution:**
Check log file permissions and location:
```bash
# Windows
$env:TEMP\security-monitor.log

# Linux
/tmp/security-monitor.log
```

#### Issue: Browser Dashboard Not Loading

**Solution:**
1. Check browser console for errors (F12)
2. Ensure Content Security Policy allows local scripts
3. Try using a local HTTP server instead of file:// protocol

#### Issue: EA Not Trading

**Checklist:**
1. AutoTrading is enabled in MT5 (button should be green)
2. EA is attached to a chart
3. EA inputs are configured correctly
4. Check Expert Advisors tab for error messages
5. Verify account allows automated trading

### Getting Help

If you encounter issues not covered here:

1. Check the [Security Guide](SECURITY.md)
2. Review log files for error messages
3. Search for similar issues on GitHub
4. Create a new issue with:
   - Operating system version
   - Steps to reproduce
   - Error messages
   - Log files (redact sensitive information)

## Next Steps

After successful installation:

1. Read the [Security Best Practices Guide](SECURITY.md)
2. Test on a demo account first
3. Configure your trading strategy
4. Set up regular backups
5. Schedule security audits

## Support

For additional support:

- GitHub Issues: [https://github.com/Mouy-leng/Window-setup/issues](https://github.com/Mouy-leng/Window-setup/issues)
- Documentation: Check the `docs/` directory
- MQL5 Community: [https://www.mql5.com](https://www.mql5.com)

## License

This setup is provided as-is for educational and personal use. Always verify security configurations and test thoroughly before using in production.
