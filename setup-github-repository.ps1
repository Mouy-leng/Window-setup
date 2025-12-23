#Requires -Version 5.1
<#
.SYNOPSIS
    Complete GitHub Repository Setup
.DESCRIPTION
    This script performs a complete setup for the GitHub repository:
    1. Initializes git repository (if needed)
    2. Configures git user and email
    3. Sets up remote repository
    4. Configures GitHub Desktop
    5. Sets up credentials (if available)
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Complete GitHub Repository Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$repoPath = "C:\Users\USER\OneDrive"
$repoUrl = "https://github.com/Mouy-leng/Window-setup.git"
$githubUser = "Mouy-leng"
$githubEmail = "Mouy-leng@users.noreply.github.com"

Set-Location $repoPath

# Step 1: Initialize Git Repository
Write-Host "[1/6] Initializing Git Repository..." -ForegroundColor Yellow
if (-not (Test-Path ".git")) {
    Write-Host "    Initializing git repository..." -ForegroundColor Cyan
    git init
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] Git repository initialized" -ForegroundColor Green
    } else {
        Write-Host "    [ERROR] Failed to initialize git repository" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "    [OK] Git repository already initialized" -ForegroundColor Green
}

# Step 2: Configure Git User
Write-Host ""
Write-Host "[2/6] Configuring Git User..." -ForegroundColor Yellow
try {
    $currentUser = git config user.name 2>$null
    $currentEmail = git config user.email 2>$null
    
    if ($currentUser -ne $githubUser) {
        git config user.name $githubUser
        Write-Host "    [OK] Git user.name set to: $githubUser" -ForegroundColor Green
    } else {
        Write-Host "    [OK] Git user.name already configured: $currentUser" -ForegroundColor Green
    }
    
    if ($currentEmail -ne $githubEmail) {
        git config user.email $githubEmail
        Write-Host "    [OK] Git user.email set to: $githubEmail" -ForegroundColor Green
    } else {
        Write-Host "    [OK] Git user.email already configured: $currentEmail" -ForegroundColor Green
    }
} catch {
    Write-Host "    [WARNING] Could not configure git user: $_" -ForegroundColor Yellow
}

# Step 3: Configure Remote Repository
Write-Host ""
Write-Host "[3/6] Configuring Remote Repository..." -ForegroundColor Yellow
try {
    $remotes = git remote -v 2>&1
    if ($remotes -match "origin") {
        Write-Host "    Remote 'origin' already exists" -ForegroundColor Cyan
        git remote set-url origin $repoUrl
        Write-Host "    [OK] Remote URL updated: $repoUrl" -ForegroundColor Green
    } else {
        git remote add origin $repoUrl
        Write-Host "    [OK] Remote 'origin' added: $repoUrl" -ForegroundColor Green
    }
    
    # Verify remote
    Write-Host "    Verifying remotes..." -ForegroundColor Cyan
    git remote -v
} catch {
    Write-Host "    [WARNING] Could not configure remote: $_" -ForegroundColor Yellow
}

# Step 4: Set Branch to Main
Write-Host ""
Write-Host "[4/6] Setting Branch to Main..." -ForegroundColor Yellow
try {
    $currentBranch = git branch --show-current 2>$null
    if ($currentBranch -and $currentBranch -ne "main") {
        git branch -M main 2>&1 | Out-Null
        Write-Host "    [OK] Branch renamed to 'main'" -ForegroundColor Green
    } elseif (-not $currentBranch) {
        git branch -M main 2>&1 | Out-Null
        Write-Host "    [OK] Branch set to 'main'" -ForegroundColor Green
    } else {
        Write-Host "    [OK] Already on 'main' branch" -ForegroundColor Green
    }
} catch {
    Write-Host "    [WARNING] Could not set branch: $_" -ForegroundColor Yellow
}

# Step 5: Setup Credentials (if available)
Write-Host ""
Write-Host "[5/6] Setting up Credentials..." -ForegroundColor Yellow

# Check multiple credential file locations
$credFilePaths = @(
    Join-Path $repoPath "git-credentials.txt",
    Join-Path $repoPath "Config\git-credentials.txt"
)

$credFile = $null
$githubToken = $null

# Find credentials file
foreach ($path in $credFilePaths) {
    if (Test-Path $path) {
        $credFile = $path
        Write-Host "    [OK] Found credentials file: $path" -ForegroundColor Green
        break
    }
}

# Check Windows Credential Manager
$credManager = cmdkey /list 2>&1 | Select-String "git:https://github.com"
if ($credManager) {
    Write-Host "    [OK] Credentials found in Windows Credential Manager" -ForegroundColor Green
    Write-Host "    [INFO] Git operations will use stored credentials" -ForegroundColor Cyan
}

if ($credFile) {
    try {
        $credentials = Get-Content $credFile | Where-Object { $_ -match "^GITHUB_TOKEN=" }
        if ($credentials) {
            $githubToken = ($credentials[0] -split "=")[1].Trim()
            Write-Host "    [OK] GitHub token found in file" -ForegroundColor Green
            
            # Store credentials in Windows Credential Manager if not already stored
            if (-not $credManager) {
                $credUser = $githubUser
                if ($githubToken) {
                    cmdkey /generic:git:https://github.com /user:$credUser /pass:$githubToken 2>&1 | Out-Null
                    Write-Host "    [OK] Credentials saved to Windows Credential Manager" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "    [INFO] No token found in credentials file" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    [WARNING] Could not read credentials file: $_" -ForegroundColor Yellow
    }
} else {
    if (-not $credManager) {
        Write-Host "    [INFO] Credentials file not found" -ForegroundColor Yellow
        Write-Host "    [INFO] Checked: git-credentials.txt, Config\git-credentials.txt" -ForegroundColor Cyan
        Write-Host "    [INFO] You can create it with format: GITHUB_TOKEN=your_token_here" -ForegroundColor Cyan
    }
}

# Step 6: Configure GitHub Desktop
Write-Host ""
Write-Host "[6/6] Configuring GitHub Desktop..." -ForegroundColor Yellow
try {
    $desktopPaths = @(
        "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe",
        "$env:PROGRAMFILES\GitHub Desktop\GitHubDesktop.exe"
    )
    
    $desktopInstalled = $false
    foreach ($path in $desktopPaths) {
        if (Test-Path $path) {
            $desktopInstalled = $true
            Write-Host "    [OK] GitHub Desktop found at: $path" -ForegroundColor Green
            break
        }
    }
    
    if ($desktopInstalled) {
        # Configure GitHub Desktop settings
        $settingsPath = "$env:APPDATA\GitHub Desktop\settings.json"
        if (Test-Path $settingsPath) {
            try {
                $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
                
                # Configure git settings
                if (-not $settings.git) {
                    $settings | Add-Member -MemberType NoteProperty -Name "git" -Value @{} -Force
                }
                
                if (-not $settings.git.userName) {
                    $settings.git.userName = $githubUser
                }
                if (-not $settings.git.userEmail) {
                    $settings.git.userEmail = $githubEmail
                }
                
                # Save settings
                $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
                Write-Host "    [OK] GitHub Desktop settings configured" -ForegroundColor Green
            } catch {
                Write-Host "    [WARNING] Could not modify GitHub Desktop settings: $_" -ForegroundColor Yellow
            }
        } else {
            Write-Host "    [INFO] GitHub Desktop settings file not found (will be created on first launch)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "    [INFO] GitHub Desktop not installed" -ForegroundColor Yellow
        Write-Host "    [INFO] Download from: https://desktop.github.com/" -ForegroundColor Cyan
    }
} catch {
    Write-Host "    [WARNING] Could not configure GitHub Desktop: $_" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Repository Configuration:" -ForegroundColor Yellow
Write-Host "  Path: $repoPath" -ForegroundColor White
Write-Host "  Remote: $repoUrl" -ForegroundColor White
Write-Host "  User: $githubUser" -ForegroundColor White
Write-Host "  Email: $githubEmail" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Add files: git add ." -ForegroundColor White
Write-Host "  2. Commit: git commit -m 'Initial commit'" -ForegroundColor White
if ($githubToken) {
    Write-Host "  3. Push: git push -u origin main" -ForegroundColor White
} else {
    Write-Host "  3. Push: git push -u origin main (requires credentials)" -ForegroundColor White
}
Write-Host "  4. Open GitHub Desktop and add this repository" -ForegroundColor White
Write-Host ""

