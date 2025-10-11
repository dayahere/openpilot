#!/bin/bash
# ========================================
# OpenPilot Docker Test Runner (Linux/Mac)
# ========================================

set -e

echo ""
echo "========================================"
echo "  OpenPilot Docker Test Suite"
echo "========================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "[ERROR] Docker is not installed"
    echo ""
    echo "Please install Docker from:"
    echo "https://www.docker.com/products/docker-desktop"
    exit 1
fi

echo "[OK] Docker found"
docker --version
echo ""

# Check if Docker daemon is running
if ! docker ps &> /dev/null; then
    echo "[ERROR] Docker daemon is not running"
    echo ""
    echo "Please start Docker and try again"
    exit 1
fi

echo "[OK] Docker daemon is running"
echo ""

# Change to script directory
cd "$(dirname "$0")"

echo "========================================"
echo "Building Test Container"
echo "========================================"
echo "This may take a few minutes on first run..."
echo ""

docker-compose -f docker-compose.test.yml build test-runner

echo ""
echo "[OK] Test container built successfully"
echo ""

echo "========================================"
echo "Running Tests in Docker"
echo "========================================"
echo ""

docker-compose -f docker-compose.test.yml run --rm test-runner
TEST_RESULT=$?

echo ""
if [ $TEST_RESULT -eq 0 ]; then
    echo "========================================"
    echo "  ALL TESTS PASSED IN DOCKER! ✅"
    echo "========================================"
else
    echo "========================================"
    echo "  SOME TESTS FAILED ❌"
    echo "========================================"
fi
echo ""

echo "Other Docker test commands:"
echo "  - Coverage:      docker-compose -f docker-compose.test.yml run --rm test-coverage"
echo "  - Integration:   docker-compose -f docker-compose.test.yml run --rm test-integration"
echo "  - Auto-fix:      docker-compose -f docker-compose.test.yml run --rm test-autofix"
echo ""

exit $TEST_RESULT
