#!/bin/bash
# ========================================
# OpenPilot Universal Test Runner (Linux/Mac)
# Automatically detects npm or Docker
# ========================================

set -e

echo ""
echo "========================================"
echo "  OpenPilot Universal Test Runner"
echo "========================================"
echo ""
echo "Detecting environment..."
echo ""

# Check if npm is available
if command -v npm &> /dev/null; then
    echo "[OK] npm found - Running tests locally"
    echo ""
    
    # Check if dependencies are installed
    if [ ! -d "tests/node_modules" ]; then
        echo "Installing dependencies..."
        bash setup-tests.sh
        if [ $? -ne 0 ]; then
            echo "[ERROR] Setup failed"
            exit 1
        fi
    fi
    
    echo "Running tests..."
    bash run-tests.sh
    TEST_RESULT=$?
else
    echo "[INFO] npm not found - Checking for Docker"
    echo ""
    
    # Check if Docker is available
    if command -v docker &> /dev/null; then
        echo "[OK] Docker found - Running tests in Docker"
        echo ""
        bash test-docker.sh
        TEST_RESULT=$?
    else
        echo "[ERROR] Neither npm nor Docker found"
        echo ""
        echo "Please install one of the following:"
        echo "  1. Node.js (includes npm): https://nodejs.org/"
        echo "  2. Docker: https://www.docker.com/products/docker-desktop"
        echo ""
        exit 1
    fi
fi

echo ""
if [ $TEST_RESULT -eq 0 ]; then
    echo "========================================"
    echo "  ALL TESTS PASSED! ✅"
    echo "========================================"
else
    echo "========================================"
    echo "  SOME TESTS FAILED ❌"
    echo "========================================"
fi
echo ""

exit $TEST_RESULT
