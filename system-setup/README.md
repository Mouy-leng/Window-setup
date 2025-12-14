# System Setup Suite
**Complete ASUS PC Configuration & Optimization**

## 📋 Overview

This suite provides comprehensive setup scripts and documentation for:
- Drive cleanup and optimization
- Drive role assignment and permissions
- Registry optimizations
- Cursor IDE configuration
- MCP (Model Context Protocol) setup
- ASUS-specific optimizations

## 🚀 Quick Start

### Complete Setup (Recommended)

```powershell
# Run as Administrator
cd D:\my-drive-projects\system-setup
.\complete-setup.ps1
```

### Individual Components

#### 1. Cleanup All Drives
```powershell
.\cleanup-all-drives.ps1
# Or dry run first:
.\cleanup-all-drives.ps1 -DryRun
```

#### 2. Apply Drive Roles
```powershell
.\apply-drive-roles.ps1
```

#### 3. Apply Registry Settings
```powershell
.\apply-registry-settings.ps1
```

## 📁 Files

| File | Purpose |
|------|---------|
| `complete-setup.ps1` | Main orchestrator - runs all setup steps |
| `cleanup-all-drives.ps1` | Cleans temp files, logs, cache across all drives |
| `apply-drive-roles.ps1` | Sets drive permissions and labels |
| `apply-registry-settings.ps1` | Applies Windows registry optimizations |
| `cursor-settings.json` | Cursor IDE configuration |
| `mcp-config.json` | MCP server configuration |
| `ASUS-PC-SETUP.md` | Comprehensive documentation |

## 🔧 Drive Roles

| Drive | Role | Permissions |
|-------|------|-------------|
| C: | OS & System | Admin Only |
| D: | Projects & Development | Users: Full Control |
| F: | Code Workspace | Users: Full Control |
| G: | Domain Controller | Admin: Full Control |
| I: | Backup & Storage | Users: Read/Write |

## ⚙️ Configuration

### Cursor IDE

Settings are automatically copied to:
- `%APPDATA%\Cursor\User\settings.json`

### MCP Configuration

MCP config is copied to:
- `%APPDATA%\Cursor\User\globalStorage\mcp.json`

**Important**: Add your GitHub Personal Access Token to the MCP config if using GitHub integration.

## 📝 Usage Examples

### Dry Run (Preview Changes)
```powershell
.\complete-setup.ps1 -DryRun
```

### Skip Specific Steps
```powershell
.\complete-setup.ps1 -SkipCleanup -SkipCursor
```

### Cleanup Only
```powershell
.\cleanup-all-drives.ps1 -Verbose
```

## 🔒 Security Notes

- All scripts require Administrator privileges
- Drive permission changes are permanent - review before applying
- Registry changes can affect system stability - backup first
- Always test with `-DryRun` first

## 📚 Documentation

See `ASUS-PC-SETUP.md` for:
- Detailed setup instructions
- Registry settings explained
- MCP setup guide
- Cursor configuration details
- ASUS-specific optimizations

## 🐛 Troubleshooting

### Permission Denied
- Ensure you're running PowerShell as Administrator
- Check User Account Control (UAC) settings

### Drive Not Found
- Verify drive letters match your system
- Update drive roles in `apply-drive-roles.ps1` if needed

### Registry Errors
- Some registry paths may not exist on all systems
- Errors are logged but don't stop the script

## 🔗 Related

- **Project Scanner**: `../project-scanner/`
- **Storage Management**: `../storage-management/`
- **Main Repository**: `../README.md`

---

**Last Updated**: November 27, 2025  
**System**: ASUS Device with Windows 11

