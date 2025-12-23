# Sync GitHub and GitHub Desktop
# This script syncs local repository with GitHub and ensures GitHub Desktop is configured

$repoPath = "C:\Users\USER\OneDrive"
Set-Location $repoPath

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub & GitHub Desktop Sync" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Git Repository Status
Write-Host "[1] Checking Git repository status..." -ForegroundColor Yellow

if (-not (Test-Path ".git")) {
    Write-Host "    [ERROR] Not a git repository" -ForegroundColor Red
    Write-Host "    [INFO] Run git-setup.ps1 first to initialize repository" -ForegroundColor Cyan
    exit 1
}

# Check remote configuration
$remotes = git remote -v 2>&1
if (-not ($remotes -match "origin")) {
    Write-Host "    [WARNING] No remote 'origin' configured" -ForegroundColor Yellow
    Write-Host "    [INFO] Adding remote origin..." -ForegroundColor Cyan
    git remote add origin "https://github.com/Mouy-leng/Window-setup.git" 2>&1 | Out-Null
    Write-Host "    [OK] Remote added" -ForegroundColor Green
} else {
    Write-Host "    [OK] Remote configured" -ForegroundColor Green
}

# Ensure branch is main
$currentBranch = git branch --show-current 2>&1
if ($currentBranch -ne "main") {
    Write-Host "    [INFO] Setting branch to main..." -ForegroundColor Cyan
    git branch -M main 2>&1 | Out-Null
    Write-Host "    [OK] Branch set to main" -ForegroundColor Green
} else {
    Write-Host "    [OK] On main branch" -ForegroundColor Green
}

Write-Host ""

# Step 2: Configure Git User (if not set)
Write-Host "[2] Configuring Git user..." -ForegroundColor Yellow

$gitUser = git config user.name 2>&1
$gitEmail = git config user.email 2>&1

if (-not $gitUser -or $gitUser -match "error") {
    git config user.name "Mouy-leng" 2>&1 | Out-Null
    Write-Host "    [OK] Git user name set" -ForegroundColor Green
} else {
    Write-Host "    [OK] Git user: $gitUser" -ForegroundColor Green
}

if (-not $gitEmail -or $gitEmail -match "error") {
    git config user.email "Mouy-leng@users.noreply.github.com" 2>&1 | Out-Null
    Write-Host "    [OK] Git email set" -ForegroundColor Green
} else {
    Write-Host "    [OK] Git email: $gitEmail" -ForegroundColor Green
}

Write-Host ""

# Step 3: Fetch latest changes from remote
Write-Host "[3] Fetching latest changes from GitHub..." -ForegroundColor Yellow

try {
    # Use timeout to prevent hanging
    $job = Start-Job -ScriptBlock { git fetch origin main 2>&1 }
    $completed = Wait-Job -Job $job -Timeout 30
    
    if ($completed) {
        Receive-Job -Job $job | Out-Null
        Remove-Job -Job $job
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Fetched latest changes" -ForegroundColor Green
        } else {
            Write-Host "    [WARNING] Fetch completed with warnings" -ForegroundColor Yellow
        }
    } else {
        Stop-Job -Job $job
        Remove-Job -Job $job
        Write-Host "    [WARNING] Fetch timed out (skipping)" -ForegroundColor Yellow
        Write-Host "    [INFO] Will proceed with push/pull operations" -ForegroundColor Cyan
    }
} catch {
    Write-Host "    [WARNING] Could not fetch: ${_}" -ForegroundColor Yellow
    Write-Host "    [INFO] Will proceed with push/pull operations" -ForegroundColor Cyan
}

Write-Host ""

# Step 4: Check for local changes
Write-Host "[4] Checking for local changes..." -ForegroundColor Yellow

$status = git status --porcelain 2>&1
$hasChanges = $status -and ($status.Count -gt 0)

if ($hasChanges) {
    Write-Host "    [INFO] Found local changes" -ForegroundColor Cyan
    Write-Host "    [INFO] Staging changes..." -ForegroundColor Cyan
    git add . 2>&1 | Out-Null
    Write-Host "    [OK] Changes staged" -ForegroundColor Green
    
    # Check if there are commits to push
    $ahead = git rev-list --count HEAD..origin/main 2>&1
    if ($ahead -and $ahead -gt 0) {
        Write-Host "    [INFO] Local commits ahead of remote" -ForegroundColor Cyan
    }
} else {
    Write-Host "    [OK] No local changes" -ForegroundColor Green
}

Write-Host ""

# Step 5: Check if local branch is behind remote
Write-Host "[5] Checking if local branch is behind remote..." -ForegroundColor Yellow

try {
    $behind = git rev-list --count origin/main..HEAD 2>&1
    $ahead = git rev-list --count HEAD..origin/main 2>&1
    
    if ($behind -and [int]$behind -gt 0) {
        Write-Host "    [INFO] Local branch is $behind commits behind remote" -ForegroundColor Yellow
        Write-Host "    [INFO] Pulling changes from remote..." -ForegroundColor Cyan
        
        # Try to pull
        git pull origin main --no-edit 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Successfully pulled changes" -ForegroundColor Green
        } else {
            Write-Host "    [WARNING] Pull completed with warnings" -ForegroundColor Yellow
            Write-Host "    [INFO] You may need to resolve conflicts manually" -ForegroundColor Cyan
        }
    } else {
        Write-Host "    [OK] Local branch is up to date with remote" -ForegroundColor Green
    }
    
    if ($ahead -and [int]$ahead -gt 0) {
        Write-Host "    [INFO] Local branch is $ahead commits ahead of remote" -ForegroundColor Cyan
    }
} catch {
    Write-Host "    [WARNING] Could not check branch status: ${_}" -ForegroundColor Yellow
}

Write-Host ""

# Step 6: Commit local changes if any
if ($hasChanges) {
    Write-Host "[6] Committing local changes..." -ForegroundColor Yellow
    
    $commitMessage = "Auto-sync: Update repository files"
    
    try {
        git commit -m $commitMessage 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Changes committed" -ForegroundColor Green
        } else {
            Write-Host "    [INFO] No new changes to commit" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "    [WARNING] Could not commit: ${_}" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Step 7: Push local changes to GitHub
Write-Host "[7] Pushing changes to GitHub..." -ForegroundColor Yellow

# Load credentials for push
$credFile = Join-Path $PSScriptRoot "git-credentials.txt"
$githubToken = $null
$githubUser = $null

if (Test-Path $credFile) {
    try {
        $credentials = Get-Content $credFile | Where-Object { $_ -match "^GITHUB_TOKEN=" }
        if ($credentials) {
            $githubToken = ($credentials[0] -split "=")[1].Trim()
        }
        
        $userLine = Get-Content $credFile | Where-Object { $_ -match "^GITHUB_USER=" }
        if ($userLine) {
            $githubUser = ($userLine[0] -split "=")[1].Trim()
        }
    } catch {
        Write-Host "    [WARNING] Could not read credentials file" -ForegroundColor Yellow
    }
}

if ($githubToken -and $githubUser) {
    # Configure remote URL with token for push
    $remoteUrl = "https://${githubUser}:${githubToken}@github.com/Mouy-leng/Window-setup.git"
    git remote set-url origin $remoteUrl 2>&1 | Out-Null
    
    try {
        $pushResult = git push origin main 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Successfully pushed to GitHub" -ForegroundColor Green
            
            # Reset remote URL to remove token
            git remote set-url origin "https://github.com/Mouy-leng/Window-setup.git" 2>&1 | Out-Null
            
            # Store credentials in Windows Credential Manager
            cmdkey /generic:git:https://github.com /user:$githubUser /pass:$githubToken 2>&1 | Out-Null
        } else {
            Write-Host "    [WARNING] Push completed with warnings" -ForegroundColor Yellow
            Write-Host "    [INFO] Check output: $pushResult" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "    [WARNING] Could not push: ${_}" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [INFO] Using existing credentials from Windows Credential Manager" -ForegroundColor Cyan
    try {
        $pushResult = git push origin main 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Successfully pushed to GitHub" -ForegroundColor Green
        } else {
            Write-Host "    [WARNING] Push may require authentication" -ForegroundColor Yellow
            Write-Host "    [INFO] Run git-setup.ps1 to configure credentials" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "    [WARNING] Could not push: ${_}" -ForegroundColor Yellow
    }
}

Write-Host ""

# Step 8: Check and configure GitHub Desktop
Write-Host "[8] Checking GitHub Desktop..." -ForegroundColor Yellow

$desktopPaths = @(
    "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe",
    "$env:PROGRAMFILES\GitHub Desktop\GitHubDesktop.exe"
)

# Add ProgramFiles(x86) path if it exists
try {
    $programFilesX86 = (Get-Item "Env:ProgramFiles(x86)").Value
    if ($programFilesX86) {
        $desktopPaths += "$programFilesX86\GitHub Desktop\GitHubDesktop.exe"
    }
}
catch {
    # ProgramFiles(x86) may not exist on 64-bit only systems
}

$desktopInstalled = $false

foreach ($path in $desktopPaths) {
    if (Test-Path $path) {
        $desktopInstalled = $true
        Write-Host "    [OK] GitHub Desktop found" -ForegroundColor Green
        Write-Host "    [INFO] Path: $path" -ForegroundColor Cyan
        
        # Get version if possible
        try {
            $versionInfo = (Get-Item $path).VersionInfo
            if ($versionInfo.FileVersion) {
                Write-Host "    [INFO] Version: $($versionInfo.FileVersion)" -ForegroundColor Cyan
            }
        } catch {
            # Version info not critical
        }
        break
    }
}

if (-not $desktopInstalled) {
    Write-Host "    [WARNING] GitHub Desktop not found" -ForegroundColor Yellow
    Write-Host "    [INFO] Download from: https://desktop.github.com/" -ForegroundColor Cyan
    Write-Host "    [INFO] After installation, run github-desktop-setup.ps1" -ForegroundColor Cyan
} else {
    # Configure GitHub Desktop settings
    $settingsPath = "$env:APPDATA\GitHub Desktop\settings.json"
    
    if (Test-Path $settingsPath) {
        try {
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
            
            # Ensure git settings match
            if (-not $settings.git) {
                $settings | Add-Member -MemberType NoteProperty -Name "git" -Value @{} -Force
            }
            
            if (-not $settings.git.userName) {
                $settings.git.userName = "Mouy-leng"
            }
            if (-not $settings.git.userEmail) {
                $settings.git.userEmail = "Mouy-leng@users.noreply.github.com"
            }
            
            # Save settings
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
            Write-Host "    [OK] GitHub Desktop settings configured" -ForegroundColor Green
        } catch {
            Write-Host "    [WARNING] Could not update GitHub Desktop settings" -ForegroundColor Yellow
            Write-Host "    [INFO] Close GitHub Desktop and try again" -ForegroundColor Cyan
        }
    } else {
        Write-Host "    [INFO] GitHub Desktop settings will be created on first launch" -ForegroundColor Cyan
    }
    
    Write-Host "    [INFO] GitHub Desktop will automatically detect repository changes" -ForegroundColor Cyan
    Write-Host "    [INFO] Refresh GitHub Desktop to see latest sync status" -ForegroundColor Cyan
}

Write-Host ""

# Step 9: Show final status
Write-Host "[9] Final repository status..." -ForegroundColor Yellow

try {
    $branchStatus = git status -sb 2>&1
    Write-Host "    $branchStatus" -ForegroundColor White
} catch {
    Write-Host "    [INFO] Could not get detailed status" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Sync Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  - Local repository synced with GitHub" -ForegroundColor White
Write-Host "  - GitHub Desktop configured (if installed)" -ForegroundColor White
Write-Host "  - Repository: https://github.com/Mouy-leng/Window-setup.git" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open GitHub Desktop to view changes" -ForegroundColor White
Write-Host "  2. Verify sync status in GitHub Desktop" -ForegroundColor White
Write-Host "  3. Check repository on GitHub.com" -ForegroundColor White
Write-Host ""

