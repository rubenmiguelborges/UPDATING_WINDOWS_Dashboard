#!/bin/bash
# Validation script for Windows Update Monitor Dashboard
# Tests file structure and code syntax

set -e

echo "=================================="
echo "Windows Update Monitor - Validation"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

# Function to print test result
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Test 1: Check required files exist
echo "1. Checking file structure..."
files=(
    "electron/main.js"
    "electron/preload.js"
    "src/renderer/index.html"
    "src/renderer/styles/main.css"
    "src/renderer/js/main.js"
    "src/renderer/js/dataLoader.js"
    "src/renderer/js/charts.js"
    "src/renderer/js/phaseDetector.js"
    "package.json"
    "README.md"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        pass "$file exists"
    else
        fail "$file missing"
    fi
done
echo ""

# Test 2: Check JavaScript syntax
echo "2. Checking JavaScript syntax..."
js_files=(
    "electron/main.js"
    "electron/preload.js"
    "src/renderer/js/dataLoader.js"
    "src/renderer/js/charts.js"
    "src/renderer/js/phaseDetector.js"
    "src/renderer/js/main.js"
)

for file in "${js_files[@]}"; do
    if node --check "$file" 2>/dev/null; then
        pass "$file - No syntax errors"
    else
        fail "$file - Syntax error detected"
    fi
done
echo ""

# Test 3: Check package.json validity
echo "3. Validating package.json..."
if node -e "JSON.parse(require('fs').readFileSync('package.json', 'utf8'))" 2>/dev/null; then
    pass "package.json is valid JSON"
else
    fail "package.json is invalid"
fi

if grep -q "\"main\": \"electron/main.js\"" package.json; then
    pass "Main entry point correctly set"
else
    fail "Main entry point not set to electron/main.js"
fi

if grep -q "\"start\":" package.json; then
    pass "npm start script defined"
else
    fail "npm start script not found"
fi
echo ""

# Test 4: Check dependencies
echo "4. Checking dependencies..."
if [ -d "node_modules" ]; then
    pass "node_modules directory exists"
else
    warn "node_modules not found - run 'npm install'"
fi

deps=("electron" "chart.js" "chokidar" "electron-store" "date-fns")
for dep in "${deps[@]}"; do
    if [ -d "node_modules/$dep" ]; then
        pass "$dep installed"
    else
        warn "$dep not installed"
    fi
done
echo ""

# Test 5: Check HTML structure
echo "5. Validating HTML..."
if grep -q "<!DOCTYPE html>" src/renderer/index.html; then
    pass "Valid HTML5 DOCTYPE"
fi

required_ids=("cpu-value" "mem-value" "disk-value" "net-value" "current-phase" "cpu-chart" "mem-chart" "disk-chart" "net-chart")
for id in "${required_ids[@]}"; do
    if grep -q "id=\"$id\"" src/renderer/index.html; then
        pass "Element #$id found"
    else
        fail "Element #$id missing"
    fi
done
echo ""

# Test 6: Check for common issues
echo "6. Code quality checks..."

# Check for console.log in production code
if grep -r "console.log" src/renderer/js/*.js electron/*.js | grep -v "console.warn" | grep -v "console.error" | grep -v "console.log('Dashboard initialized" >/dev/null 2>&1; then
    warn "console.log statements found (consider removing for production)"
else
    pass "No debug console.log statements"
fi

# Check for TODO comments
if grep -r "TODO" src/ electron/ >/dev/null 2>&1; then
    warn "TODO comments found in code"
else
    pass "No TODO comments"
fi
echo ""

# Test 7: Check directory structure
echo "7. Checking directory structure..."
dirs=("electron" "src/renderer" "src/renderer/js" "src/renderer/styles" "assets/icons" "src/monitor")
for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        pass "$dir/ exists"
    else
        fail "$dir/ missing"
    fi
done
echo ""

# Summary
echo "=================================="
echo "Test Summary"
echo "=================================="
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${RED}Failed:${NC} $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Implement src/monitor/Monitor.ps1"
    echo "2. Add icon at assets/icons/icon.png"
    echo "3. Test on Windows with: npm run dev"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please fix the issues above.${NC}"
    exit 1
fi
