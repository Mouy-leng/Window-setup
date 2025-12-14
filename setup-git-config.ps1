# Git Configuration Script
# Helps configure Git for secure development

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Git Configuration Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if Git is installed
try {
    $gitVersion = git --version
    Write-Host "[OK] Git is installed: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Git is not installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download and install Git from:" -ForegroundColor Yellow
    Write-Host "https://git-scm.com/download/win" -ForegroundColor Cyan
    exit 1
}

Write-Host ""

# Get current configuration
Write-Host "Current Git Configuration:" -ForegroundColor Yellow
Write-Host ""

$userName = git config --global user.name
$userEmail = git config --global user.email
$signingKey = git config --global user.signingkey
$commitSign = git config --global commit.gpgsign
$defaultBranch = git config --global init.defaultBranch

if ($userName) {
    Write-Host "User Name: $userName" -ForegroundColor Gray
} else {
    Write-Host "User Name: Not set" -ForegroundColor Yellow
}

if ($userEmail) {
    Write-Host "User Email: $userEmail" -ForegroundColor Gray
} else {
    Write-Host "User Email: Not set" -ForegroundColor Yellow
}

if ($signingKey) {
    Write-Host "Signing Key: $signingKey" -ForegroundColor Gray
} else {
    Write-Host "Signing Key: Not set" -ForegroundColor Yellow
}

if ($commitSign) {
    Write-Host "Commit Signing: $commitSign" -ForegroundColor Gray
} else {
    Write-Host "Commit Signing: Not enabled" -ForegroundColor Yellow
}

if ($defaultBranch) {
    Write-Host "Default Branch: $defaultBranch" -ForegroundColor Gray
} else {
    Write-Host "Default Branch: Not set (will use 'master')" -ForegroundColor Yellow
}

Write-Host ""

# Ask if user wants to configure
$configure = Read-Host "Do you want to configure Git settings? (yes/no)"

if ($configure -ne "yes") {
    Write-Host "[INFO] Configuration cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Git Configuration" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Configure user name
if (-not $userName) {
    $newName = Read-Host "Enter your full name"
    if (-not [string]::IsNullOrWhiteSpace($newName)) {
        git config --global user.name $newName
        Write-Host "[OK] User name set to: $newName" -ForegroundColor Green
    }
} else {
    $changeName = Read-Host "Change user name from '$userName'? (yes/no)"
    if ($changeName -eq "yes") {
        $newName = Read-Host "Enter your full name"
        if (-not [string]::IsNullOrWhiteSpace($newName)) {
            git config --global user.name $newName
            Write-Host "[OK] User name updated to: $newName" -ForegroundColor Green
        }
    }
}

# Configure user email
Write-Host ""
if (-not $userEmail) {
    $newEmail = Read-Host "Enter your email address (use your GitHub email)"
    if (-not [string]::IsNullOrWhiteSpace($newEmail)) {
        git config --global user.email $newEmail
        Write-Host "[OK] User email set to: $newEmail" -ForegroundColor Green
    }
} else {
    $changeEmail = Read-Host "Change email from '$userEmail'? (yes/no)"
    if ($changeEmail -eq "yes") {
        $newEmail = Read-Host "Enter your email address (use your GitHub email)"
        if (-not [string]::IsNullOrWhiteSpace($newEmail)) {
            git config --global user.email $newEmail
            Write-Host "[OK] User email updated to: $newEmail" -ForegroundColor Green
        }
    }
}

# Configure default branch
Write-Host ""
if (-not $defaultBranch) {
    $branchName = Read-Host "Enter default branch name (press Enter for 'main')"
    if ([string]::IsNullOrWhiteSpace($branchName)) {
        $branchName = "main"
    }
    git config --global init.defaultBranch $branchName
    Write-Host "[OK] Default branch set to: $branchName" -ForegroundColor Green
}

# Configure credential helper
Write-Host ""
Write-Host "Configuring credential helper..." -ForegroundColor Yellow

# Check Git version and available credential helpers
$gitVersion = git --version
$helperSet = $false

# Try to use Git Credential Manager (modern approach)
try {
    # Test if manager credential helper is available
    $testResult = git credential-manager --version 2>&1
    if ($LASTEXITCODE -eq 0 -or $testResult -match "credential") {
        git config --global credential.helper manager
        Write-Host "[OK] Credential helper set to Git Credential Manager" -ForegroundColor Green
        $helperSet = $true
    }
} catch {
    # Git Credential Manager not available
}

# Fallback to wincred if manager is not available
if (-not $helperSet) {
    try {
        git config --global credential.helper wincred
        Write-Host "[OK] Credential helper set to Windows Credential Manager (wincred)" -ForegroundColor Green
        Write-Host "[INFO] Consider installing Git Credential Manager for enhanced security" -ForegroundColor Yellow
    } catch {
        Write-Host "[WARNING] Could not configure credential helper" -ForegroundColor Yellow
    }
}

# Configure line endings
Write-Host ""
Write-Host "Configuring line endings for Windows..." -ForegroundColor Yellow
git config --global core.autocrlf true
Write-Host "[OK] Line ending conversion enabled" -ForegroundColor Green

# Configure pull strategy
Write-Host ""
Write-Host "Configuring pull strategy..." -ForegroundColor Yellow
git config --global pull.rebase false
Write-Host "[OK] Pull strategy set to merge" -ForegroundColor Green

# Additional security settings
Write-Host ""
Write-Host "Applying security settings..." -ForegroundColor Yellow

# Disable pager for short output
git config --global core.pager "less -F -X"

# Enable push safety
git config --global push.default simple

Write-Host "[OK] Security settings applied" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Configuration Summary" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "User Name: $(git config --global user.name)" -ForegroundColor Green
Write-Host "User Email: $(git config --global user.email)" -ForegroundColor Green
Write-Host "Default Branch: $(git config --global init.defaultBranch)" -ForegroundColor Green
Write-Host "Credential Helper: $(git config --global credential.helper)" -ForegroundColor Green

$currentSigningKey = git config --global user.signingkey
if ($currentSigningKey) {
    Write-Host "Signing Key: $currentSigningKey" -ForegroundColor Green
    Write-Host "Commit Signing: $(git config --global commit.gpgsign)" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[INFO] GPG signing not configured" -ForegroundColor Yellow
    Write-Host "Run .\setup-github-gpg.ps1 to set up commit signing" -ForegroundColor Gray
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Git Configuration Complete!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Next steps
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run .\setup-github-ssh.ps1 to configure SSH (if not done)" -ForegroundColor Gray
Write-Host "2. Run .\setup-github-gpg.ps1 to configure GPG signing (recommended)" -ForegroundColor Gray
Write-Host "3. Test Git: git clone git@github.com:username/repo.git" -ForegroundColor Gray
Write-Host ""
