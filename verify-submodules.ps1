# Verify Git Submodules Integration
# This script verifies that the git submodules are properly integrated

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Git Submodules Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errors = @()
$warnings = @()

# Check 1: .gitmodules file exists
Write-Host "[1/5] Checking .gitmodules file..." -ForegroundColor Yellow
if (Test-Path ".gitmodules") {
    Write-Host "    [OK] .gitmodules file exists" -ForegroundColor Green
    Get-Content ".gitmodules" | Write-Host -ForegroundColor Gray
} else {
    $errors += ".gitmodules file not found"
    Write-Host "    [ERROR] .gitmodules file not found" -ForegroundColor Red
}

Write-Host ""

# Check 2: my-drive-projects submodule
Write-Host "[2/5] Checking my-drive-projects submodule..." -ForegroundColor Yellow
if (Test-Path "my-drive-projects") {
    $fileCount = (Get-ChildItem -Path "my-drive-projects" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
    if ($fileCount -gt 0) {
        Write-Host "    [OK] my-drive-projects directory exists with $fileCount files" -ForegroundColor Green
        
        # Check if it's a git repository
        if (Test-Path "my-drive-projects/.git") {
            Write-Host "    [OK] my-drive-projects is a git repository" -ForegroundColor Green
        } else {
            $warnings += "my-drive-projects is not a git repository"
            Write-Host "    [WARNING] my-drive-projects is not a git repository" -ForegroundColor Yellow
        }
    } else {
        $warnings += "my-drive-projects directory is empty"
        Write-Host "    [WARNING] my-drive-projects directory is empty" -ForegroundColor Yellow
    }
} else {
    $errors += "my-drive-projects directory not found"
    Write-Host "    [ERROR] my-drive-projects directory not found" -ForegroundColor Red
}

Write-Host ""

# Check 3: OS-Twin directory
Write-Host "[3/5] Checking OS-Twin directory..." -ForegroundColor Yellow
if (Test-Path "OS-Twin") {
    Write-Host "    [OK] OS-Twin directory exists" -ForegroundColor Green
    
    if (Test-Path "OS-Twin/README.md") {
        Write-Host "    [OK] OS-Twin placeholder README exists" -ForegroundColor Green
    } else {
        $warnings += "OS-Twin README not found"
        Write-Host "    [WARNING] OS-Twin README not found" -ForegroundColor Yellow
    }
} else {
    $errors += "OS-Twin directory not found"
    Write-Host "    [ERROR] OS-Twin directory not found" -ForegroundColor Red
}

Write-Host ""

# Check 4: Documentation updated
Write-Host "[4/5] Checking documentation..." -ForegroundColor Yellow
$readmeContent = Get-Content "README.md" -Raw -ErrorAction SilentlyContinue
if ($readmeContent -like "*my-drive-projects*" -and $readmeContent -like "*OS-Twin*") {
    Write-Host "    [OK] README.md documents both repositories" -ForegroundColor Green
} else {
    $warnings += "README.md may not fully document the submodules"
    Write-Host "    [WARNING] README.md may not fully document the submodules" -ForegroundColor Yellow
}

Write-Host ""

# Check 5: Git submodule status
Write-Host "[5/5] Checking git submodule status..." -ForegroundColor Yellow
try {
    $submoduleStatus = git submodule status 2>&1
    $submoduleExitCode = $LASTEXITCODE
    if ($submoduleExitCode -eq 0) {
        Write-Host "    [OK] Git submodule command successful" -ForegroundColor Green
        $submoduleStatus | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    } else {
        $warnings += "Git submodule status had issues"
        Write-Host "    [WARNING] Git submodule status had issues" -ForegroundColor Yellow
        $submoduleStatus | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    }
} catch {
    $warnings += "Error checking git submodule status: $_"
    Write-Host "    [WARNING] Error checking git submodule status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "[SUCCESS] All checks passed!" -ForegroundColor Green
} elseif ($errors.Count -eq 0) {
    Write-Host "[PARTIAL] Verification completed with warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
} else {
    Write-Host "[FAILED] Verification failed with errors:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
    if ($warnings.Count -gt 0) {
        Write-Host "Warnings:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
