# Quick Sync Status Check
# Shows current sync status between local repository and GitHub

$repoPath = "C:\Users\USER\OneDrive"
Set-Location $repoPath

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Sync Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check repository status
Write-Host "Repository Status:" -ForegroundColor Yellow
$status = git status -sb 2>&1
Write-Host "  $status" -ForegroundColor White
Write-Host ""

# Check local commits
Write-Host "Local Commits (last 3):" -ForegroundColor Yellow
git log --oneline -3 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
Write-Host ""

# Check remote commits
Write-Host "Remote Commits (last 3):" -ForegroundColor Yellow
try {
    git fetch origin main --quiet 2>&1 | Out-Null
    git log --oneline origin/main -3 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
} catch {
    Write-Host "  [WARNING] Could not fetch remote status" -ForegroundColor Yellow
}
Write-Host ""

# Check if ahead/behind
try {
    $ahead = git rev-list --count HEAD..origin/main 2>&1
    $behind = git rev-list --count origin/main..HEAD 2>&1
    
    if ($ahead -and [int]$ahead -gt 0) {
        Write-Host "  [INFO] Local is $ahead commits behind remote" -ForegroundColor Yellow
    }
    if ($behind -and [int]$behind -gt 0) {
        Write-Host "  [INFO] Local is $behind commits ahead of remote" -ForegroundColor Cyan
    }
    if ((-not $ahead -or [int]$ahead -eq 0) -and (-not $behind -or [int]$behind -eq 0)) {
        Write-Host "  [OK] Local and remote are in sync" -ForegroundColor Green
    }
} catch {
    Write-Host "  [WARNING] Could not compare branches" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Status Check Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To sync: Run .\sync-github-desktop.ps1" -ForegroundColor Cyan
Write-Host ""

