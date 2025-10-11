@echo off
REM ========================================
REM OpenPilot Quick Test Runner
REM ========================================

echo.
echo ========================================
echo   Running OpenPilot Tests
echo ========================================
echo.

REM Get the script directory
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

REM Check if tests directory exists
if not exist tests (
    echo [ERROR] Tests directory not found
    echo Please run setup-tests.bat first
    pause
    exit /b 1
)

REM Check if node_modules exists in tests
if not exist tests\node_modules (
    echo [ERROR] Test dependencies not installed
    echo Please run setup-tests.bat first
    pause
    exit /b 1
)

echo ========================================
echo Running Jest Tests
echo ========================================
cd tests
call npm test
set TEST_RESULT=%ERRORLEVEL%
cd ..

echo.
if %TEST_RESULT% EQU 0 (
    echo ========================================
    echo   ALL TESTS PASSED! ✅
    echo ========================================
) else (
    echo ========================================
    echo   SOME TESTS FAILED ❌
    echo ========================================
    echo.
    echo Check the output above for details
)
echo.

echo To run with coverage:
echo   cd tests ^&^& npm run test:coverage
echo.
echo To run integration tests only:
echo   cd tests ^&^& npm run test:integration
echo.

pause
exit /b %TEST_RESULT%
