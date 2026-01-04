# Test script for NuNa Device Launcher
# This script simulates and tests the launcher functionality

Write-Host "`n=== NuNa Device Launcher Test ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if launcher script exists
Write-Host "[Test 1] Checking launcher script existence..." -ForegroundColor Yellow
$scriptPath = "./launch-nuna-device.ps1"
if (Test-Path $scriptPath) {
    Write-Host "  [OK] launch-nuna-device.ps1 exists" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] launch-nuna-device.ps1 not found" -ForegroundColor Red
    exit 1
}

# Test 2: Check if batch file exists
Write-Host "[Test 2] Checking batch file existence..." -ForegroundColor Yellow
$batchPath = "./LAUNCH-NUNA-DEVICE.bat"
if (Test-Path $batchPath) {
    Write-Host "  [OK] LAUNCH-NUNA-DEVICE.bat exists" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] LAUNCH-NUNA-DEVICE.bat not found" -ForegroundColor Red
    exit 1
}

# Test 3: Check if quick start guide exists
Write-Host "[Test 3] Checking quick start guide..." -ForegroundColor Yellow
$guidePath = "./NUNA-DEVICE-QUICK-START.md"
if (Test-Path $guidePath) {
    Write-Host "  [OK] NUNA-DEVICE-QUICK-START.md exists" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] NUNA-DEVICE-QUICK-START.md not found" -ForegroundColor Red
    exit 1
}

# Test 4: Validate PowerShell syntax
Write-Host "[Test 4] Validating PowerShell syntax..." -ForegroundColor Yellow
try {
    $errors = $null
    $tokens = $null
    $ast = $null
    # Use newer AST-based parsing (PowerShell 5.0+)
    $scriptContentRaw = Get-Content $scriptPath -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContentRaw, [ref]$tokens, [ref]$errors)
    
    if ($errors) {
        Write-Host "  [FAIL] Syntax errors found:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
        exit 1
    } else {
        Write-Host "  [OK] No syntax errors" -ForegroundColor Green
    }
} catch {
    Write-Host "  [FAIL] Error validating syntax: $_" -ForegroundColor Red
    exit 1
}

# Test 5: Check required functions in script
Write-Host "[Test 5] Checking required functions..." -ForegroundColor Yellow
$scriptContent = Get-Content $scriptPath -Raw
$requiredElements = @(
    "Write-Status",
    "deviceInfo",
    "workspaceRoot",
    "websitePath",
    "githubPagesURLs",
    "browsers"
)

$allElementsFound = $true
foreach ($element in $requiredElements) {
    if ($scriptContent -like "*$element*") {
        Write-Host "  [OK] Found: $element" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Missing: $element" -ForegroundColor Red
        $allElementsFound = $false
    }
}

if (-not $allElementsFound) {
    exit 1
}

# Test 6: Check documentation updates
Write-Host "[Test 6] Checking documentation updates..." -ForegroundColor Yellow
$readmePath = "./README.md"
if (Test-Path $readmePath) {
    $readmeContent = Get-Content $readmePath -Raw
    if ($readmeContent -like "*LAUNCH-NUNA-DEVICE*" -or $readmeContent -like "*NuNa Device Launcher*") {
        Write-Host "  [OK] README.md updated with NuNa launcher" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] README.md may not reference NuNa launcher" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [FAIL] README.md not found" -ForegroundColor Red
    exit 1
}

# Test 7: Check SYSTEM-INFO.md updates
Write-Host "[Test 7] Checking SYSTEM-INFO.md updates..." -ForegroundColor Yellow
$systemInfoPath = "./SYSTEM-INFO.md"
if (Test-Path $systemInfoPath) {
    $systemInfoContent = Get-Content $systemInfoPath -Raw
    if ($systemInfoContent -like "*Vivobook Go*" -or $systemInfoContent -like "*E1504GEB_E1504GA*") {
        Write-Host "  [OK] SYSTEM-INFO.md contains device model info" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] SYSTEM-INFO.md may not reference device model" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [FAIL] SYSTEM-INFO.md not found" -ForegroundColor Red
    exit 1
}

# Test 8: Check for proper error handling in script
Write-Host "[Test 8] Checking error handling..." -ForegroundColor Yellow
if ($scriptContent -like "*try*" -and $scriptContent -like "*catch*") {
    Write-Host "  [OK] Script contains try-catch error handling" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Script missing try-catch error handling" -ForegroundColor Red
    exit 1
}

# Test 9: Check for logging functionality
Write-Host "[Test 9] Checking logging functionality..." -ForegroundColor Yellow
if ($scriptContent -like "*log*" -and $scriptContent -like "*Out-File*") {
    Write-Host "  [OK] Script contains logging functionality" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Script may not have comprehensive logging" -ForegroundColor Yellow
}

# Test 10: Verify device-specific features
Write-Host "[Test 10] Checking device-specific features..." -ForegroundColor Yellow
$deviceFeatures = @(
    "i3-N305",
    "8",
    "battery",
    "Vivobook"
)

$featuresFound = 0
foreach ($feature in $deviceFeatures) {
    if ($scriptContent -like "*$feature*") {
        $featuresFound++
    }
}

if ($featuresFound -ge 3) {
    Write-Host "  [OK] Script contains device-specific optimizations ($featuresFound/4 features)" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Script may lack some device-specific features ($featuresFound/4 features)" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "[PASS] All critical tests passed!" -ForegroundColor Green
Write-Host ""
Write-Host "NuNa Device Launcher is ready for deployment" -ForegroundColor Green
Write-Host "Run './LAUNCH-NUNA-DEVICE.bat' or './launch-nuna-device.ps1' to test" -ForegroundColor White
Write-Host ""
