# Complete ASUS PC Setup Script
# Runs all setup components in sequence

param(
    [switch]$DryRun,
    [switch]$SkipCleanup,
    [switch]$SkipRegistry,
    [switch]$SkipDriveRoles,
    [switch]$SkipCursor
)

# Requires Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    exit 1
}

$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ASUS PC Complete Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Drive Cleanup
if (-not $SkipCleanup) {
    Write-Host "Step 1: Cleaning up all drives..." -ForegroundColor Yellow
    $cleanupScript = Join-Path $scriptDir "cleanup-all-drives.ps1"
    if (Test-Path $cleanupScript) {
        & $cleanupScript -DryRun:$DryRun
    } else {
        Write-Host "  ⚠ Cleanup script not found: $cleanupScript" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Step 2: Apply Drive Roles
if (-not $SkipDriveRoles) {
    Write-Host "Step 2: Applying drive roles and permissions..." -ForegroundColor Yellow
    $driveRolesScript = Join-Path $scriptDir "apply-drive-roles.ps1"
    if (Test-Path $driveRolesScript) {
        & $driveRolesScript -DryRun:$DryRun
    } else {
        Write-Host "  ⚠ Drive roles script not found: $driveRolesScript" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Step 3: Registry Settings
if (-not $SkipRegistry) {
    Write-Host "Step 3: Applying registry settings..." -ForegroundColor Yellow
    $registryScript = Join-Path $scriptDir "apply-registry-settings.ps1"
    if (Test-Path $registryScript) {
        & $registryScript -DryRun:$DryRun
    } else {
        Write-Host "  ⚠ Registry script not found: $registryScript" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Step 4: Cursor Configuration
if (-not $SkipCursor) {
    Write-Host "Step 4: Configuring Cursor IDE..." -ForegroundColor Yellow
    $cursorSettings = Join-Path $scriptDir "cursor-settings.json"
    $cursorTarget = "$env:APPDATA\Cursor\User\settings.json"
    
    if (Test-Path $cursorSettings) {
        try {
            if (-not $DryRun) {
                # Backup existing settings
                if (Test-Path $cursorTarget) {
                    Copy-Item $cursorTarget "$cursorTarget.backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')" -ErrorAction SilentlyContinue
                }
                
                # Create directory if it doesn't exist
                $cursorDir = Split-Path $cursorTarget
                if (-not (Test-Path $cursorDir)) {
                    New-Item -ItemType Directory -Path $cursorDir -Force | Out-Null
                }
                
                # Copy settings
                Copy-Item $cursorSettings $cursorTarget -Force
                Write-Host "  ✓ Cursor settings applied" -ForegroundColor Green
            } else {
                Write-Host "  [DRY RUN] Would copy settings to: $cursorTarget" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  ✗ Failed to apply Cursor settings: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  ⚠ Cursor settings file not found: $cursorSettings" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Step 5: MCP Configuration
Write-Host "Step 5: Configuring MCP..." -ForegroundColor Yellow
$mcpConfig = Join-Path $scriptDir "mcp-config.json"
$mcpTarget = "$env:APPDATA\Cursor\User\globalStorage\mcp.json"

if (Test-Path $mcpConfig) {
    try {
        if (-not $DryRun) {
            # Create directory if it doesn't exist
            $mcpDir = Split-Path $mcpTarget
            if (-not (Test-Path $mcpDir)) {
                New-Item -ItemType Directory -Path $mcpDir -Force | Out-Null
            }
            
            # Copy MCP config
            Copy-Item $mcpConfig $mcpTarget -Force
            Write-Host "  ✓ MCP configuration applied" -ForegroundColor Green
            Write-Host "  ⚠ Remember to add your GitHub token in: $mcpTarget" -ForegroundColor Yellow
        } else {
            Write-Host "  [DRY RUN] Would copy MCP config to: $mcpTarget" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ✗ Failed to apply MCP config: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  ⚠ MCP config file not found: $mcpConfig" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "⚠️ DRY RUN MODE - No changes were made" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes`n" -ForegroundColor Yellow
}

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review ASUS-PC-SETUP.md for detailed documentation" -ForegroundColor White
Write-Host "  2. Add GitHub token to MCP config if using GitHub integration" -ForegroundColor White
Write-Host "  3. Restart Cursor IDE to apply settings" -ForegroundColor White
Write-Host "  4. Test the project scanner: cd D:\my-drive-projects\project-scanner && .\run-all-projects.ps1" -ForegroundColor White
Write-Host ""

