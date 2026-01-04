# NuNa Device Quick Start Guide

Complete setup and launch guide for the NuNa device (Vivobook Go E1504GEB_E1504GA).

## Device Specifications

- **Device Name**: NuNa
- **Model**: Vivobook Go E1504GEB_E1504GA
- **Processor**: Intel(R) Core(TM) i3-N305 (1.80 GHz)
- **RAM**: 8.00 GB (7.63 GB usable)
- **OS**: Windows 11 Home Single Language 25H2 (Build 26220.7344)
- **Architecture**: 64-bit x64-based processor

## Quick Launch Options

### Option 1: Launch with Batch File (Easiest)

Double-click the batch file:
```
LAUNCH-NUNA-DEVICE.bat
```

This will:
- ✅ Validate NuNa device configuration
- ✅ Set up workspace
- ✅ Clone/update website repository
- ✅ Launch website in browser
- ✅ Start local web server (if Python installed)
- ✅ Apply device-specific optimizations

### Option 2: Launch with PowerShell

Run in PowerShell:
```powershell
.\launch-nuna-device.ps1
```

### Option 3: Launch Full VPS System

For 24/7 automated trading and services:
```
AUTO-START-VPS.bat
```
or
```powershell
.\auto-start-vps-admin.ps1
```

## What Gets Launched

### 1. Website Repository
- **Repository**: ZOLO-A6-9VxNUNA
- **Location**: `C:\Users\USER\OneDrive\ZOLO-A6-9VxNUNA`
- **URLs**:
  - GitHub Pages: https://mouy-leng.github.io/ZOLO-A6-9VxNUNA-/
  - GitHub Repo: https://github.com/Mouy-leng/ZOLO-A6-9VxNUNA-

### 2. Browser Launch
The launcher will automatically find and use:
- Microsoft Edge (preferred)
- Google Chrome
- Mozilla Firefox

### 3. Optional Local Server
If Python is installed, a local web server starts at:
- http://localhost:8000

## Device-Specific Features

### Optimizations for Vivobook Go
The launcher includes optimizations for the Vivobook Go E1504GEB_E1504GA:

1. **Battery Monitoring**
   - Displays battery status
   - Warns if battery is below 20%

2. **Power Management**
   - Checks power plan (Balanced recommended)
   - Optimized for Intel i3-N305 processor

3. **Memory Management**
   - Optimized for 8GB RAM
   - Efficient resource usage

## Prerequisites

### Required
- ✅ Windows 11 Home Single Language 25H2
- ✅ PowerShell 5.1+ (included in Windows 11)
- ✅ Git installed
- ✅ Internet connection

### Optional
- Python 3.x (for local web server)
- Web browser (Edge, Chrome, or Firefox)

## Troubleshooting

### Issue: "launch-nuna-device.ps1 not found"
**Solution**: Ensure you're running the batch file from the correct directory:
```
C:\Users\USER\OneDrive\
```

### Issue: "Script execution is disabled"
**Solution**: The batch file automatically handles this with `-ExecutionPolicy Bypass`

If running PowerShell directly, use:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: "Website not launching"
**Solution**: 
1. Check internet connection
2. Ensure a browser is installed
3. Check the log file: `nuna-device-launch.log`

### Issue: "Git clone failed"
**Solution**: 
1. Ensure Git is installed
2. Check GitHub credentials
3. Verify internet connection

## Log Files

The launcher creates log files for troubleshooting:
- **Main Log**: `C:\Users\USER\OneDrive\nuna-device-launch.log`
- **VPS Logs**: `C:\Users\USER\OneDrive\vps-logs\`

## Advanced Usage

### Auto-Start on Boot

To automatically launch on system startup:
```powershell
.\setup-auto-startup-admin.ps1
```

Then add `LAUNCH-NUNA-DEVICE.bat` to the startup configuration.

### Custom Website URL

Edit `launch-nuna-device.ps1` and modify the `$githubPagesURLs` array:
```powershell
$githubPagesURLs = @(
    "https://your-custom-url.com",
    "https://mouy-leng.github.io/ZOLO-A6-9VxNUNA-/"
)
```

## Integration with Other Systems

### Trading System
Launch with trading system:
```
LAUNCH-EXNESS-TRADING.bat
```

### Complete Windows Setup
Full system setup:
```
RUN-COMPLETE-SETUP.bat
```

### VPS Services
Full VPS 24/7 system:
```
AUTO-START-VPS.bat
```

## Performance Tips for Vivobook Go

### 1. Battery Life
- Use balanced power plan for best performance/battery ratio
- Close unused applications
- Consider dimming screen brightness

### 2. Memory Management (8GB RAM)
- Close browser tabs when not needed
- Use Task Manager to monitor memory usage
- Consider using Edge (more memory efficient than Chrome)

### 3. Processor Optimization (i3-N305)
- Let Windows handle thermal management
- Avoid running too many background services
- Use the launcher's device optimizations

## Next Steps

After successful launch:

1. **Verify Website**: Check that the website opened in your browser
2. **Check Repository**: Navigate to `C:\Users\USER\OneDrive\ZOLO-A6-9VxNUNA`
3. **Review Logs**: Check `nuna-device-launch.log` for any warnings
4. **Explore Features**: Try other launch options (VPS, Trading, etc.)

## Support

For issues or questions:
- Review log files in `C:\Users\USER\OneDrive\`
- Check device specifications match expected values
- Ensure all prerequisites are installed

## Related Documentation

- **README.md** - Main project documentation
- **SYSTEM-INFO.md** - Detailed system specifications
- **DEVICE-SKELETON.md** - Complete device structure
- **VPS-SETUP-GUIDE.md** - VPS system guide
- **AUTOMATION-RULES.md** - Automation patterns

---

**Device**: NuNa (Vivobook Go E1504GEB_E1504GA)  
**Last Updated**: 2026-01-04  
**Version**: 1.0
