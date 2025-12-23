# Quick verification script for GitHub setup
$repoPath = "C:\Users\USER\OneDrive"
Set-Location $repoPath

Write-Host "GitHub Repository Setup Verification" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check git initialization
if (Test-Path ".git") {
    Write-Host "[OK] Git repository initialized" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Git repository not initialized" -ForegroundColor Red
}

# Check git config
Write-Host ""
Write-Host "Git Configuration:" -ForegroundColor Yellow
$userName = git config user.name 2>$null
$userEmail = git config user.email 2>$null

if ($userName) {
    Write-Host "  User: $userName" -ForegroundColor Green
} else {
    Write-Host "  User: [NOT SET]" -ForegroundColor Red
}

if ($userEmail) {
    Write-Host "  Email: $userEmail" -ForegroundColor Green
} else {
    Write-Host "  Email: [NOT SET]" -ForegroundColor Red
}

# Check remote
Write-Host ""
Write-Host "Remote Configuration:" -ForegroundColor Yellow
$remotes = git remote -v 2>&1
if ($remotes) {
    Write-Host "  $remotes" -ForegroundColor Green
} else {
    Write-Host "  [NO REMOTE CONFIGURED]" -ForegroundColor Red
}

# Check branch
Write-Host ""
Write-Host "Branch:" -ForegroundColor Yellow
$branch = git branch --show-current 2>$null
if ($branch) {
    Write-Host "  Current branch: $branch" -ForegroundColor Green
} else {
    Write-Host "  [NO BRANCH]" -ForegroundColor Yellow
}

Write-Host ""

