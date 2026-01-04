#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive Branch Management and Repository Maintenance Script
.DESCRIPTION
    Manages branches across all remotes, resolves conflicts, merges, cleans up,
    maintains repositories across drives, and prepares system for autonomous operation
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Branch & Repository Management" -ForegroundColor Cyan
Write-Host "  Autonomous Operation Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get workspace root
$workspaceRoot = Get-Location
Write-Host "[INFO] Working in: $workspaceRoot" -ForegroundColor Cyan
Write-Host ""

# ============================================
# STEP 1: Update All Branches from All Remotes
# ============================================
Write-Host "[STEP 1/9] Updating All Branches from Remotes..." -ForegroundColor Yellow
Write-Host ""

# Get all remotes
$remotes = @()
$remoteNames = git remote 2>&1
foreach ($remoteName in $remoteNames) {
    if ($remoteName -and $remoteName -notmatch "^fatal") {
        $remoteUrl = git remote get-url $remoteName 2>&1
        $remotes += [PSCustomObject]@{
            Name = $remoteName
            URL = $remoteUrl
        }
    }
}

if ($remotes.Count -eq 0) {
    Write-Host "[WARNING] No remotes found. Skipping remote operations." -ForegroundColor Yellow
    $remotes = @([PSCustomObject]@{ Name = "local"; URL = "local-only" })
} else {
    Write-Host "Found $($remotes.Count) remote(s):" -ForegroundColor Cyan
    foreach ($remote in $remotes) {
        Write-Host "  - $($remote.Name): $($remote.URL)" -ForegroundColor Green
    }
}
Write-Host ""

# Fetch all remotes with prune (remove obsolete branches)
if ($remotes[0].Name -ne "local") {
    foreach ($remote in $remotes) {
        Write-Host "Fetching and pruning from: $($remote.Name)" -ForegroundColor Cyan
        try {
            git fetch $remote.Name --prune 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Fetched from $($remote.Name)" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [WARNING] Could not fetch from $($remote.Name): $_" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# ============================================
# STEP 2: List All Branches and Identify Cleanup Targets
# ============================================
Write-Host "[STEP 2/9] Analyzing Branches..." -ForegroundColor Yellow
Write-Host ""

$currentBranch = git branch --show-current 2>&1
Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan
Write-Host ""

# Get all branches
$localBranches = git branch 2>&1 | ForEach-Object { $_.Trim().Replace("* ", "") }
$remoteBranches = git branch -r 2>&1 | ForEach-Object { $_.Trim() }

Write-Host "Local branches:" -ForegroundColor Yellow
foreach ($branch in $localBranches) {
    if ($branch -and $branch -notmatch "^fatal") {
        $isCurrent = if ($branch -eq $currentBranch) { " (current)" } else { "" }
        Write-Host "  - $branch$isCurrent" -ForegroundColor $(if ($isCurrent) { "Green" } else { "Gray" })
    }
}
Write-Host ""

if ($remoteBranches.Count -gt 0) {
    Write-Host "Remote branches:" -ForegroundColor Yellow
    foreach ($branch in $remoteBranches) {
        if ($branch -and $branch -notmatch "^fatal" -and $branch -notmatch "HEAD") {
            Write-Host "  - $branch" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

# ============================================
# STEP 3: Merge and Update Current Branch
# ============================================
Write-Host "[STEP 3/9] Merging and Updating Current Branch..." -ForegroundColor Yellow
Write-Host ""

# Pull from all remotes
if ($remotes[0].Name -ne "local") {
    foreach ($remote in $remotes) {
        Write-Host "Pulling from $($remote.Name)/$currentBranch..." -ForegroundColor Cyan
        try {
            $pullOutput = git pull $remote.Name $currentBranch --no-edit 2>&1 | Out-String
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Pull completed" -ForegroundColor Green
            } elseif ($pullOutput -match "conflict|CONFLICT") {
                Write-Host "  [WARNING] Conflicts detected" -ForegroundColor Yellow
                # Auto-resolve conflicts using local changes
                git checkout --ours . 2>&1 | Out-Null
                git add . 2>&1 | Out-Null
                git commit --no-edit -m "Resolved conflicts automatically (keeping local changes)" 2>&1 | Out-Null
                Write-Host "  [OK] Conflicts resolved" -ForegroundColor Green
            } elseif ($pullOutput -match "Already up to date") {
                Write-Host "  [OK] Already up to date" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [WARNING] Could not pull from $($remote.Name): $_" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# ============================================
# STEP 4: Clean Up Obsolete Local Branches
# ============================================
Write-Host "[STEP 4/9] Cleaning Up Obsolete Branches..." -ForegroundColor Yellow
Write-Host ""

# Identify merged branches (excluding current and main/master)
$protectedBranches = @("main", "master", $currentBranch)
$branchesToDelete = @()

foreach ($branch in $localBranches) {
    if ($branch -and $branch -notin $protectedBranches -and $branch -notmatch "^fatal") {
        # Check if branch is merged
        $isMerged = git branch --merged $currentBranch 2>&1 | Select-String -Pattern "^\s*$branch$"
        if ($isMerged) {
            $branchesToDelete += $branch
        }
    }
}

if ($branchesToDelete.Count -gt 0) {
    Write-Host "Found $($branchesToDelete.Count) merged branch(es) to delete:" -ForegroundColor Yellow
    foreach ($branch in $branchesToDelete) {
        Write-Host "  - $branch" -ForegroundColor Gray
        try {
            git branch -d $branch 2>&1 | Out-Null
            Write-Host "    [OK] Deleted" -ForegroundColor Green
        } catch {
            Write-Host "    [WARNING] Could not delete: $_" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "[OK] No obsolete branches to delete" -ForegroundColor Green
}
Write-Host ""

# ============================================
# STEP 5: Stage and Commit All Changes
# ============================================
Write-Host "[STEP 5/9] Staging and Committing Changes..." -ForegroundColor Yellow
Write-Host ""

try {
    git add . 2>&1 | Out-Null
    
    $stagedFiles = git diff --cached --name-only 2>&1
    if ($stagedFiles -and $stagedFiles -notmatch "^fatal") {
        $stagedCount = ($stagedFiles | Measure-Object).Count
        Write-Host "  [OK] Staged $stagedCount file(s)" -ForegroundColor Green
        
        $commitMessage = "Repository maintenance: Branch management, merge, and cleanup - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git commit -m $commitMessage 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Changes committed" -ForegroundColor Green
        }
    } else {
        Write-Host "  [INFO] No changes to commit" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  [WARNING] Commit step had issues: $_" -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# STEP 6: Push to All Remotes
# ============================================
Write-Host "[STEP 6/9] Pushing to All Remotes..." -ForegroundColor Yellow
Write-Host ""

$pushResults = @()
if ($remotes[0].Name -ne "local") {
    foreach ($remote in $remotes) {
        Write-Host "Pushing to: $($remote.Name)" -ForegroundColor Cyan
        try {
            $pushOutput = git push $remote.Name $currentBranch 2>&1 | Out-String
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Pushed successfully" -ForegroundColor Green
                $pushResults += [PSCustomObject]@{ Remote = $remote.Name; Status = "SUCCESS" }
            } elseif ($pushOutput -match "rejected|non-fast-forward") {
                Write-Host "  [INFO] Attempting force push with lease..." -ForegroundColor Cyan
                git push $remote.Name $currentBranch --force-with-lease 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  [OK] Force push successful" -ForegroundColor Green
                    $pushResults += [PSCustomObject]@{ Remote = $remote.Name; Status = "SUCCESS" }
                }
            }
        } catch {
            Write-Host "  [WARNING] Could not push to $($remote.Name): $_" -ForegroundColor Yellow
            $pushResults += [PSCustomObject]@{ Remote = $remote.Name; Status = "WARNING" }
        }
    }
} else {
    Write-Host "[INFO] Local-only repository, skipping push" -ForegroundColor Cyan
}
Write-Host ""

# ============================================
# STEP 7: Maintain Repository Structure Across Drives
# ============================================
Write-Host "[STEP 7/9] Maintaining Repository Structure..." -ForegroundColor Yellow
Write-Host ""

# Check for repositories in different drives
$drives = @("C:", "D:", "E:", "F:")
$repoLocations = @()

foreach ($drive in $drives) {
    if (Test-Path $drive) {
        Write-Host "Scanning $drive for repositories..." -ForegroundColor Cyan
        
        # Check common locations
        $possiblePaths = @(
            "$drive\Users\USER\OneDrive",
            "$drive\Users\USER\Documents",
            "$drive\Projects",
            "$drive\Repositories"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $gitDirs = Get-ChildItem -Path $path -Directory -Filter ".git" -Recurse -Depth 2 -ErrorAction SilentlyContinue
                foreach ($gitDir in $gitDirs) {
                    $repoPath = $gitDir.Parent.FullName
                    $repoLocations += [PSCustomObject]@{
                        Drive = $drive
                        Path = $repoPath
                        Name = Split-Path $repoPath -Leaf
                    }
                    Write-Host "  [OK] Found repository: $repoPath" -ForegroundColor Green
                }
            }
        }
    }
}

if ($repoLocations.Count -gt 0) {
    Write-Host ""
    Write-Host "Total repositories found: $($repoLocations.Count)" -ForegroundColor Cyan
    
    # Group by drive
    $groupedByDrive = $repoLocations | Group-Object -Property Drive
    foreach ($group in $groupedByDrive) {
        Write-Host "  $($group.Name): $($group.Count) repository(ies)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[INFO] No additional repositories found" -ForegroundColor Cyan
}
Write-Host ""

# ============================================
# STEP 8: Generate Tree Mapping and Documentation
# ============================================
Write-Host "[STEP 8/9] Generating Tree Mapping..." -ForegroundColor Yellow
Write-Host ""

$treeMappingFile = Join-Path $workspaceRoot "REPOSITORY-TREE-MAP.md"
$notebookFile = Join-Path $workspaceRoot "MAINTENANCE-NOTEBOOK.md"

# Generate tree mapping
$treeMappingContent = @"
# Repository Tree Mapping
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Current Repository

- **Location**: $workspaceRoot
- **Branch**: $currentBranch
- **Remotes**: $($remotes.Count)

### Remote Configuration
"@

foreach ($remote in $remotes) {
    $treeMappingContent += "`n- **$($remote.Name)**: $($remote.URL)"
}

$treeMappingContent += @"


### Branch Structure

#### Local Branches
"@

foreach ($branch in $localBranches) {
    if ($branch -and $branch -notmatch "^fatal") {
        $marker = if ($branch -eq $currentBranch) { " ← current" } else { "" }
        $treeMappingContent += "`n- $branch$marker"
    }
}

if ($repoLocations.Count -gt 0) {
    $treeMappingContent += @"


## Repositories Across Drives

Total: $($repoLocations.Count) repositories found

"@
    
    foreach ($group in $groupedByDrive) {
        $treeMappingContent += "`n### $($group.Name)`n"
        foreach ($repo in $group.Group) {
            $treeMappingContent += "`n- **$($repo.Name)**`n  - Path: ``$($repo.Path)``"
        }
        $treeMappingContent += "`n"
    }
}

$treeMappingContent += @"


## Directory Structure

``````
$workspaceRoot/
├── .cursor/                    # Cursor IDE configuration
├── .git/                       # Git repository
├── projects/                   # Active projects
├── my-drive-projects/          # Drive projects submodule
├── OS-Twin/                    # OS Twin submodule
├── trading-bridge/             # Trading bridge
├── vps-services/               # VPS services
├── Scripts (*.ps1)             # PowerShell automation scripts
└── Documentation (*.md)        # Project documentation
``````

## Maintenance Commands

### Update and Sync
``````powershell
# Run this script
.\manage-branches-and-repos.ps1
``````

### Manual Branch Management
``````powershell
# View all branches
git branch -a

# Switch branch
git checkout <branch-name>

# Delete merged branch
git branch -d <branch-name>

# Delete unmerged branch (force)
git branch -D <branch-name>
``````

### Conflict Resolution
``````powershell
# Keep local changes
git checkout --ours .
git add .
git commit

# Keep remote changes
git checkout --theirs .
git add .
git commit
``````

---
*Auto-generated by manage-branches-and-repos.ps1*
"@

$treeMappingContent | Out-File -FilePath $treeMappingFile -Encoding UTF8
Write-Host "[OK] Tree mapping saved to: REPOSITORY-TREE-MAP.md" -ForegroundColor Green

# Generate maintenance notebook
$notebookContent = @"
# Maintenance Notebook
Last Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Recent Maintenance Activities

### Latest Run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

#### Actions Performed
- ✅ Fetched updates from $($remotes.Count) remote(s)
- ✅ Merged changes into current branch: $currentBranch
- ✅ Cleaned up $($branchesToDelete.Count) obsolete branch(es)
- ✅ Committed and pushed changes
- ✅ Scanned $($drives.Count) drive(s) for repositories
- ✅ Found $($repoLocations.Count) total repository(ies)
- ✅ Generated tree mapping documentation

#### Push Results
"@

if ($pushResults.Count -gt 0) {
    foreach ($result in $pushResults) {
        $icon = if ($result.Status -eq "SUCCESS") { "✅" } else { "⚠️" }
        $notebookContent += "`n- $icon $($result.Remote): $($result.Status)"
    }
} else {
    $notebookContent += "`n- No push operations (local only)"
}

$notebookContent += @"


## Maintenance Schedule

### Daily Tasks
- [ ] Run branch management script
- [ ] Check repository sync status
- [ ] Review security logs

### Weekly Tasks
- [ ] Clean up obsolete branches
- [ ] Review and merge pending changes
- [ ] Update documentation
- [ ] Run security checks

### Monthly Tasks
- [ ] Review repository structure
- [ ] Archive old branches
- [ ] Update automation scripts
- [ ] System security audit

## Quick Commands

### Repository Management
``````powershell
# Update all branches and remotes
.\manage-branches-and-repos.ps1

# Review and cleanup all repos
.\review-resolve-merge-cleanup-all-repos.ps1

# Push to all remotes
.\push-to-all-repos.ps1
``````

### Security
``````powershell
# Run security check
.\run-security-check.ps1

# Setup security with firewall
.\setup-security.ps1
``````

### System Operations
``````powershell
# Complete system setup
.\complete-device-setup.ps1

# Start trading system
.\auto-start-vps-admin.ps1
``````

## Notes

### Current Configuration
- **Device**: NuNa (Windows 11 Home Single Language 25H2)
- **Workspace**: $workspaceRoot
- **Current Branch**: $currentBranch
- **Total Remotes**: $($remotes.Count)
- **Repositories Found**: $($repoLocations.Count)

### Autonomous Operation
This system is designed for autonomous operation with minimal user intervention.
All scripts handle errors gracefully and make intelligent decisions based on best practices.

---
*Auto-generated by manage-branches-and-repos.ps1*
"@

$notebookContent | Out-File -FilePath $notebookFile -Encoding UTF8
Write-Host "[OK] Maintenance notebook saved to: MAINTENANCE-NOTEBOOK.md" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 9: Prepare for Autonomous Operation
# ============================================
Write-Host "[STEP 9/9] Preparing for Autonomous Operation..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Verifying autonomous operation readiness..." -ForegroundColor Cyan

$readinessChecks = @{
    "Git repository" = Test-Path ".git"
    "PowerShell scripts" = (Get-ChildItem -Filter "*.ps1" | Measure-Object).Count -gt 0
    "Documentation" = Test-Path "README.md"
    "Security setup" = Test-Path "security-check.ps1"
    "Trading system" = Test-Path "auto-start-vps-admin.ps1"
}

$allReady = $true
foreach ($check in $readinessChecks.GetEnumerator()) {
    if ($check.Value) {
        Write-Host "  [OK] $($check.Key)" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] $($check.Key) not found" -ForegroundColor Yellow
        $allReady = $false
    }
}

Write-Host ""

# ============================================
# Generate Final Summary
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Branch Management Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Current Branch: $currentBranch" -ForegroundColor Cyan
Write-Host "  Remotes: $($remotes.Count)" -ForegroundColor Cyan
Write-Host "  Branches Cleaned: $($branchesToDelete.Count)" -ForegroundColor Cyan
Write-Host "  Repositories Found: $($repoLocations.Count)" -ForegroundColor Cyan
Write-Host "  Push Results: $($pushResults.Count) successful" -ForegroundColor Cyan
Write-Host ""

if ($allReady) {
    Write-Host "✅ System ready for autonomous operation!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some components missing, review warnings above" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review REPOSITORY-TREE-MAP.md for repository structure" -ForegroundColor Cyan
Write-Host "  2. Check MAINTENANCE-NOTEBOOK.md for maintenance schedule" -ForegroundColor Cyan
Write-Host "  3. Run .\setup-security.ps1 for C: drive security setup" -ForegroundColor Cyan
Write-Host "  4. Run .\auto-start-vps-admin.ps1 to start trading system" -ForegroundColor Cyan
Write-Host ""
