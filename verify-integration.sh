#!/bin/bash
echo "========================================"
echo "  Git Submodules Verification"
echo "========================================"
echo ""

errors=0
warnings=0

# Check 1: .gitmodules file exists
echo "[1/5] Checking .gitmodules file..."
if [ -f ".gitmodules" ]; then
    echo "    [OK] .gitmodules file exists"
    cat .gitmodules | sed 's/^/    /'
else
    echo "    [ERROR] .gitmodules file not found"
    ((errors++))
fi
echo ""

# Check 2: my-drive-projects submodule
echo "[2/5] Checking my-drive-projects submodule..."
if [ -d "my-drive-projects" ]; then
    file_count=$(find my-drive-projects -type f 2>/dev/null | wc -l)
    if [ "$file_count" -gt 0 ]; then
        echo "    [OK] my-drive-projects directory exists with $file_count files"
        
        if [ -e "my-drive-projects/.git" ]; then
            echo "    [OK] my-drive-projects is a git repository"
        else
            echo "    [WARNING] my-drive-projects is not a git repository"
            ((warnings++))
        fi
    else
        echo "    [WARNING] my-drive-projects directory is empty"
        ((warnings++))
    fi
else
    echo "    [ERROR] my-drive-projects directory not found"
    ((errors++))
fi
echo ""

# Check 3: OS-Twin directory
echo "[3/5] Checking OS-Twin directory..."
if [ -d "OS-Twin" ]; then
    echo "    [OK] OS-Twin directory exists"
    
    if [ -f "OS-Twin/README.md" ]; then
        echo "    [OK] OS-Twin placeholder README exists"
    else
        echo "    [WARNING] OS-Twin README not found"
        ((warnings++))
    fi
else
    echo "    [ERROR] OS-Twin directory not found"
    ((errors++))
fi
echo ""

# Check 4: Documentation updated
echo "[4/5] Checking documentation..."
if grep -q "my-drive-projects" README.md && grep -q "OS-Twin" README.md; then
    echo "    [OK] README.md documents both repositories"
else
    echo "    [WARNING] README.md may not fully document the submodules"
    ((warnings++))
fi
echo ""

# Check 5: Git submodule status
echo "[5/5] Checking git submodule status..."
submodule_output=$(git submodule status 2>&1)
submodule_exit_code=$?
if [ $submodule_exit_code -eq 0 ]; then
    echo "    [OK] Git submodule command successful"
    echo "$submodule_output" | sed 's/^/    /'
else
    echo "    [WARNING] Git submodule status had issues"
    echo "$submodule_output" | sed 's/^/    /'
    ((warnings++))
fi
echo ""

echo "========================================"
echo "  Summary"
echo "========================================"

if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo "[SUCCESS] All checks passed!"
elif [ $errors -eq 0 ]; then
    echo "[PARTIAL] Verification completed with $warnings warning(s)"
else
    echo "[FAILED] Verification failed with $errors error(s) and $warnings warning(s)"
fi
echo ""
