@echo off
REM ========================================
REM OpenPilot Docker Test Runner
REM ========================================

echo.
echo ========================================
echo   OpenPilot Docker Test Suite
echo ========================================
echo.

REM Check if Docker is installed
docker --version >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker is not installed or not in PATH
    echo.
    echo Please install Docker Desktop from:
    echo https://www.docker.com/products/docker-desktop
    echo.
    echo Then re-run this script
    pause
    exit /b 1
)

echo [OK] Docker found
docker --version
echo.

REM Check Docker daemon is running
docker ps >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker daemon is not running
    echo.
    echo Please start Docker Desktop and try again
    pause
    exit /b 1
)

echo [OK] Docker daemon is running
echo.

REM Get the script directory
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

echo ========================================
echo Building Test Container
echo ========================================
echo This may take a few minutes on first run...
echo.

docker-compose -f docker-compose.test.yml build test-runner
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to build test container
    pause
    exit /b 1
)

echo.
echo [OK] Test container built successfully
echo.

echo ========================================
echo Running Tests in Docker
echo ========================================
echo.

docker-compose -f docker-compose.test.yml run --rm test-runner
set TEST_RESULT=%ERRORLEVEL%

echo.
if %TEST_RESULT% EQU 0 (
    echo ========================================
    echo   ALL TESTS PASSED IN DOCKER! ✅
    echo ========================================
) else (
    echo ========================================
    echo   SOME TESTS FAILED ❌
    echo ========================================
)
echo.

echo Other Docker test commands:
echo   - Coverage:      docker-compose -f docker-compose.test.yml run --rm test-coverage
echo   - Integration:   docker-compose -f docker-compose.test.yml run --rm test-integration
echo   - Auto-fix:      docker-compose -f docker-compose.test.yml run --rm test-autofix
echo.

pause
exit /b %TEST_RESULT%
