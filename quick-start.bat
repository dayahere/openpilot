@echo off
REM OpenPilot Quick Start Script for Windows
REM This script sets up and runs OpenPilot

echo ========================================
echo OpenPilot Quick Start
echo ========================================
echo.

REM Check Node.js
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js is not installed!
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check Python
where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python is not installed!
    echo Please install Python from https://www.python.org/
    pause
    exit /b 1
)

echo [OK] Node.js found
echo [OK] Python found
echo.

REM Install dependencies
echo ========================================
echo Installing Dependencies...
echo ========================================
echo.

echo Installing root dependencies...
call npm install
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to install root dependencies
    pause
    exit /b 1
)

echo Installing Python dependencies...
call pip install -r requirements.txt
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to install Python dependencies
    pause
    exit /b 1
)

echo.
echo ========================================
echo Building Projects...
echo ========================================
echo.

echo Building core library...
cd core
call npm install
call npm run build
cd ..

echo Building VS Code extension...
cd vscode-extension
call npm install
call npm run compile
cd ..

echo Building desktop app...
cd desktop
call npm install
cd ..

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo What would you like to do?
echo.
echo 1. Run Desktop App
echo 2. Open VS Code Extension (development)
echo 3. Install Ollama (local AI)
echo 4. Run Tests
echo 5. Exit
echo.

set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" (
    echo.
    echo Starting Desktop App...
    cd desktop
    start npm start
    cd ..
)

if "%choice%"=="2" (
    echo.
    echo Opening VS Code extension...
    echo Press F5 in VS Code to start the extension development host
    cd vscode-extension
    code .
    cd ..
)

if "%choice%"=="3" (
    echo.
    echo Opening Ollama download page...
    start https://ollama.ai/download
    echo.
    echo After installing Ollama, run these commands:
    echo   ollama serve
    echo   ollama pull codellama
)

if "%choice%"=="4" (
    echo.
    echo Running tests...
    call npm run test:all
)

echo.
echo ========================================
echo Quick Commands:
echo ========================================
echo.
echo Desktop App:     cd desktop ^&^& npm start
echo VS Code Ext:     cd vscode-extension ^&^& code .
echo Run Tests:       npm run test:all
echo Auto-Fix:        python scripts\auto-fix.py
echo.

pause
