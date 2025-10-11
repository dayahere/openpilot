@echo off
REM ========================================
REM OpenPilot Universal Test Runner
REM Automatically detects npm or Docker
REM ========================================

echo.
echo ========================================
echo   OpenPilot Universal Test Runner
echo ========================================
echo.
echo Detecting environment...
echo.

REM Check if npm is available
where npm >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] npm found - Running tests locally
    echo.
    goto LOCAL_TESTS
)

echo [INFO] npm not found - Checking for Docker
echo.

REM Check if Docker is available
docker --version >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Docker found - Running tests in Docker
    echo.
    goto DOCKER_TESTS
)

echo [ERROR] Neither npm nor Docker found
echo.
echo Please install one of the following:
echo   1. Node.js (includes npm): https://nodejs.org/
echo   2. Docker Desktop: https://www.docker.com/products/docker-desktop
echo.
pause
exit /b 1

:LOCAL_TESTS
echo ========================================
echo Running Local Tests (npm)
echo ========================================
echo.

REM Check if dependencies are installed
if not exist tests\node_modules (
    echo Installing dependencies...
    call setup-tests.bat
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Setup failed
        pause
        exit /b 1
    )
)

echo Running tests...
call run-tests.bat
set TEST_RESULT=%ERRORLEVEL%
goto END

:DOCKER_TESTS
echo ========================================
echo Running Docker Tests
echo ========================================
echo.

call test-docker.bat
set TEST_RESULT=%ERRORLEVEL%
goto END

:END
echo.
if %TEST_RESULT% EQU 0 (
    echo ========================================
    echo   ALL TESTS PASSED! ✅
    echo ========================================
) else (
    echo ========================================
    echo   SOME TESTS FAILED ❌
    echo ========================================
)
echo.
pause
exit /b %TEST_RESULT%
