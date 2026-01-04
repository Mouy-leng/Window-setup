# Autonomous Operation Quick Start Guide

This guide will help you get started with the autonomous agent orchestration system.

## Prerequisites

- Windows 11 Home Single Language 25H2 or later
- PowerShell 5.1 or later
- Administrator privileges
- Git installed and configured
- GitHub Desktop (optional)

## Quick Start (3 Steps)

### Step 1: Set Up Security (Run as Administrator)

```powershell
# Configure C: drive security and firewall
.\setup-c-drive-security.ps1
```

**What it does:**
- Configures Windows Firewall for critical applications
- Sets up Windows Defender with proper exclusions
- Enables Controlled Folder Access
- Creates system restore point
- Runs security audit

**Expected output:**
- Security report saved to `C-DRIVE-SECURITY-REPORT.md`
- All firewall rules configured
- Windows Defender properly configured

### Step 2: Manage Branches and Repositories

```powershell
# Update, merge, and cleanup all branches
.\manage-branches-and-repos.ps1
```

**What it does:**
- Fetches updates from all remotes
- Merges changes into current branch
- Deletes obsolete merged branches
- Resolves conflicts automatically (keeping local changes)
- Pushes to all configured remotes
- Scans all drives for repositories
- Generates tree mapping and maintenance notebook

**Expected output:**
- `REPOSITORY-TREE-MAP.md` - Repository structure documentation
- `MAINTENANCE-NOTEBOOK.md` - Maintenance schedule and tasks
- All branches synchronized across remotes

### Step 3: Start Autonomous Operation (Run as Administrator)

```powershell
# Start the autonomous agent orchestrator
.\autonomous-agent-orchestrator.ps1
```

**What it does:**
- Initializes multi-agent coordination
- Runs repository management
- Runs security checks
- Starts trading system (if configured)
- Sets up continuous monitoring
- Generates agent status report

**Expected output:**
- `AGENT-STATUS.md` - Real-time agent status
- `autonomous-operation.log` - Operation logs
- System enters autonomous mode

## All-in-One Quick Start

For a complete automated setup, run all three scripts in sequence:

```powershell
# Run as Administrator
.\setup-c-drive-security.ps1
.\manage-branches-and-repos.ps1
.\autonomous-agent-orchestrator.ps1
```

## Monitoring and Maintenance

### View Current Status

```powershell
# Check agent status
Get-Content AGENT-STATUS.md

# Check repository structure
Get-Content REPOSITORY-TREE-MAP.md

# Check maintenance schedule
Get-Content MAINTENANCE-NOTEBOOK.md

# Check security report
Get-Content C-DRIVE-SECURITY-REPORT.md

# View operation logs
Get-Content autonomous-operation.log
```

### Manual Branch Management

```powershell
# View all branches
git branch -a

# Switch to a different branch
git checkout <branch-name>

# View repository status
git status

# View remotes
git remote -v
```

### Security Commands

```powershell
# Check firewall status
Get-NetFirewallProfile | Select-Object Name, Enabled

# Check Windows Defender status
Get-MpComputerStatus

# List firewall rules
Get-NetFirewallRule | Where-Object {$_.Enabled -eq 'True'}

# Run security check
.\run-security-check.ps1
```

## Autonomous Operation Features

### What Runs Automatically

1. **Repository Management** (Every hour)
   - Branch synchronization
   - Conflict resolution
   - Push to all remotes

2. **Security Monitoring** (Every 2 hours)
   - Security checks
   - Firewall verification
   - Defender status

3. **Trading System** (Continuous)
   - MT5 Terminal monitoring
   - Trade placement
   - System health checks

### Agent Coordination

The system coordinates five AI agents:

1. **GitHub Copilot** - Code generation and repository management
2. **Cursor AI** - Code editing and workspace management
3. **Jules** - Task coordination and workflow management
4. **Qodo** - Code quality and testing
5. **Kombai** - Design to code conversion

All agents work together without user intervention.

## Troubleshooting

### Scripts Require Administrator

If you see "This script requires Administrator privileges":

1. Right-click PowerShell
2. Select "Run as Administrator"
3. Navigate to the workspace directory
4. Run the script again

### Git Authentication Issues

If push fails due to authentication:

1. Check `git-credentials.txt` exists (gitignored)
2. Verify GitHub token is valid
3. Run `git config --list` to check configuration
4. Try `git push` manually to test credentials

### Firewall Rules Not Created

If firewall rules aren't created:

1. Ensure you're running as Administrator
2. Check if the application paths exist
3. Verify Windows Firewall service is running
4. Review the security report for details

### Trading System Not Starting

If trading system doesn't start:

1. Verify MT5 is installed at default location
2. Check if `auto-start-vps-admin.ps1` exists
3. Ensure you're running as Administrator
4. Check `autonomous-operation.log` for errors

## Advanced Configuration

### Customize Monitoring Intervals

Edit `autonomous-agent-orchestrator.ps1` and modify:

```powershell
$monitoringTasks = @(
    @{
        Name = "Repository Sync"
        Interval = 3600  # Change this (in seconds)
    },
    @{
        Name = "Security Check"
        Interval = 7200  # Change this (in seconds)
    }
)
```

### Add Additional Firewall Rules

Edit `setup-c-drive-security.ps1` and add to `$firewallRules`:

```powershell
@{
    Name = "Your Application Name"
    Program = "C:\Path\To\Application.exe"
    Direction = "Outbound"
    Action = "Allow"
}
```

### Add Repository Remotes

```powershell
# Add a new remote
git remote add <remote-name> <remote-url>

# Verify remotes
git remote -v

# Fetch from new remote
git fetch <remote-name>
```

## Best Practices

1. **Run security setup first** before any other operations
2. **Create a backup** before making major changes
3. **Review generated reports** after each run
4. **Monitor logs** in `autonomous-operation.log`
5. **Keep Windows updated** for security patches
6. **Verify trading system** before going live

## Getting Help

### Check Documentation

- `README.md` - Main project documentation
- `AUTOMATION-RULES.md` - Automation patterns
- `DEVICE-SKELETON.md` - Device structure
- `PROJECT-BLUEPRINTS.md` - Project details

### Review Reports

- `AGENT-STATUS.md` - Agent collaboration status
- `REPOSITORY-TREE-MAP.md` - Repository structure
- `MAINTENANCE-NOTEBOOK.md` - Maintenance tasks
- `C-DRIVE-SECURITY-REPORT.md` - Security audit

### Check Logs

- `autonomous-operation.log` - Operation logs
- Windows Event Viewer - System logs
- Git logs: `git log --oneline -20`

## Next Steps

After completing the quick start:

1. Review all generated reports
2. Verify trading system is ready
3. Monitor autonomous operation for 24 hours
4. Check logs for any errors or warnings
5. Adjust configuration as needed

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review generated reports and logs
3. Verify all prerequisites are met
4. Ensure scripts are run with Administrator privileges

---

**Note:** This system is designed for autonomous operation. Once started, it will run without user intervention. Monitor the logs and status reports to ensure everything is working correctly.
