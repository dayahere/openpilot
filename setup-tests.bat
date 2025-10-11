@echo off
REM ========================================
REM OpenPilot Complete Test Setup Script
REM ========================================

echo.
echo ========================================
echo   OpenPilot Test Suite Setup
echo ========================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js is not installed or not in PATH
    echo.
    echo Please install Node.js from: https://nodejs.org/
    echo Then re-run this script
    pause
    exit /b 1
)

REM Check if npm is installed
where npm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] npm is not installed or not in PATH
    echo.
    echo Please ensure Node.js is properly installed
    pause
    exit /b 1
)

echo [OK] Node.js and npm found
node --version
npm --version
echo.

REM Get the script directory
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

echo ========================================
echo Step 1: Installing Root Dependencies
echo ========================================
if exist package.json (
    echo Installing root dependencies...
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to install root dependencies
        pause
        exit /b 1
    )
    echo [OK] Root dependencies installed
) else (
    echo [SKIP] No package.json found
)
echo.

echo ========================================
echo Step 2: Building Core Library
echo ========================================
if exist core (
    cd core
    echo Installing core dependencies...
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to install core dependencies
        cd ..
        pause
        exit /b 1
    )
    
    echo Building core library...
    call npm run build
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to build core library
        cd ..
        pause
        exit /b 1
    )
    
    echo [OK] Core library built successfully
    cd ..
) else (
    echo [ERROR] Core directory not found
    pause
    exit /b 1
)
echo.

echo ========================================
echo Step 3: Installing Test Dependencies
echo ========================================
if exist tests (
    cd tests
    echo Installing test dependencies...
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to install test dependencies
        cd ..
        pause
        exit /b 1
    )
    
    echo [OK] Test dependencies installed
    cd ..
) else (
    echo [ERROR] Tests directory not found
    pause
    exit /b 1
)
echo.

echo ========================================
echo Step 4: Installing Extension Dependencies
echo ========================================
if exist vscode-extension (
    cd vscode-extension
    echo Installing VS Code extension dependencies...
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo [WARNING] Failed to install extension dependencies
        cd ..
    ) else (
        echo [OK] Extension dependencies installed
        cd ..
    )
) else (
    echo [SKIP] VS Code extension directory not found
)
echo.

echo ========================================
echo Step 5: Installing Web App Dependencies
echo ========================================
if exist web (
    cd web
    echo Installing web app dependencies...
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo [WARNING] Failed to install web dependencies
        cd ..
    ) else (
        echo [OK] Web dependencies installed
        cd ..
    )
) else (
    echo [SKIP] Web directory not found
)
echo.

echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo All dependencies installed successfully.
echo.
echo Next Steps:
echo   1. Run tests:        cd tests ^&^& npm test
echo   2. Check coverage:   cd tests ^&^& npm run test:coverage
echo   3. Run auto-fix:     python scripts\run-tests.py
echo.
echo For E2E tests, start the web app first:
echo   cd web ^&^& npm start
echo.
pause
