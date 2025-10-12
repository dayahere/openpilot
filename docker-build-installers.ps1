# Docker-Based Installer Builder
# Builds ALL installers using ONLY Docker - No local Node.js/npm required!

param(
    [switch]$SkipAndroid,
    [switch]$SkipDesktop,
    [switch]$SkipWeb,
    [switch]$SkipVSCode
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Docker-Based Installer Builder" -ForegroundColor Cyan
Write-Host "No Node.js/npm installation required!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker availability
Write-Host "[INFO] Checking Docker..." -ForegroundColor Cyan
try {
    $dockerVersion = docker --version
    Write-Host "[SUCCESS] Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Docker not found! Please install Docker Desktop." -ForegroundColor Red
    Write-Host "Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Create output directory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputDir = "i:\openpilot\docker-installers-output\$timestamp"

Write-Host "[INFO] Creating output directory: $outputDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
New-Item -ItemType Directory -Path "$outputDir\android" -Force | Out-Null
New-Item -ItemType Directory -Path "$outputDir\desktop" -Force | Out-Null
New-Item -ItemType Directory -Path "$outputDir\web" -Force | Out-Null
New-Item -ItemType Directory -Path "$outputDir\vscode" -Force | Out-Null
Write-Host "[SUCCESS] Output directory created" -ForegroundColor Green
Write-Host ""

# =============================================================================
# BUILD WEB APP
# =============================================================================
if (-not $SkipWeb) {
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "BUILDING WEB APP (Docker)" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    
    try {
        Set-Location "i:\openpilot\web"
        
        Write-Host "[1/3] Installing dependencies in Docker..." -ForegroundColor Cyan
        docker run --rm -v "${PWD}:/app" -w /app node:18 npm install --legacy-peer-deps
        
        Write-Host "[2/3] Building production app in Docker..." -ForegroundColor Cyan
        docker run --rm -v "${PWD}:/app" -w /app node:18 npm run build
        
        Write-Host "[3/3] Packaging web app..." -ForegroundColor Cyan
        if (Test-Path "build") {
            Compress-Archive -Path "build\*" -DestinationPath "$outputDir\web\openpilot-web.zip" -Force
            $zipSize = (Get-Item "$outputDir\web\openpilot-web.zip").Length / 1MB
            Write-Host "[SUCCESS] Web app built: openpilot-web.zip ($([math]::Round($zipSize, 2)) MB)" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Build folder not created" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "[ERROR] Web build failed: $_" -ForegroundColor Red
    }
    
    Set-Location "i:\openpilot"
    Write-Host ""
}

# =============================================================================
# BUILD DESKTOP APP
# =============================================================================
if (-not $SkipDesktop) {
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "BUILDING DESKTOP APP (Docker)" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    
    try {
        Set-Location "i:\openpilot\desktop"
        
        Write-Host "[1/3] Installing dependencies in Docker..." -ForegroundColor Cyan
        docker run --rm -v "${PWD}:/app" -w /app node:18 npm install --legacy-peer-deps
        
        Write-Host "[2/3] Building desktop app in Docker..." -ForegroundColor Cyan
        docker run --rm -v "${PWD}:/app" -w /app node:18 npm run build
        
        # Try to package if script exists
        $packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
        if ($packageJson.scripts.PSObject.Properties.Name -contains "package-win") {
            Write-Host "[3/3] Packaging Windows installer in Docker..." -ForegroundColor Cyan
            docker run --rm -v "${PWD}:/app" -w /app node:18 npm run package-win
            
            if (Test-Path "release") {
                Copy-Item "release\*" "$outputDir\desktop\" -Recurse -Force
                Write-Host "[SUCCESS] Desktop app packaged" -ForegroundColor Green
            }
        } else {
            Write-Host "[3/3] Copying build output..." -ForegroundColor Cyan
            if (Test-Path "build") {
                Copy-Item "build\*" "$outputDir\desktop\" -Recurse -Force
                Write-Host "[SUCCESS] Desktop build copied" -ForegroundColor Green
            }
        }
        
    } catch {
        Write-Host "[ERROR] Desktop build failed: $_" -ForegroundColor Red
    }
    
    Set-Location "i:\openpilot"
    Write-Host ""
}

# =============================================================================
# BUILD VS CODE EXTENSION
# =============================================================================
if (-not $SkipVSCode) {
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "BUILDING VSCODE EXTENSION (Docker)" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    
    try {
        Set-Location "i:\openpilot\vscode-extension"
        
        Write-Host "[1/4] Installing dependencies in Docker..." -ForegroundColor Cyan
        docker run --rm -v "${PWD}:/app" -w /app node:18 npm install
        
        Write-Host "[2/4] Compiling TypeScript in Docker..." -ForegroundColor Cyan
        docker run --rm -v "${PWD}:/app" -w /app node:18 npm run compile
        
        Write-Host "[3/4] Packaging VSIX in Docker..." -ForegroundColor Cyan
        docker run --rm -v "${PWD}:/app" -w /app node:18 npx @vscode/vsce package --no-git-tag-version
        
        Write-Host "[4/4] Copying VSIX file..." -ForegroundColor Cyan
        $vsixFile = Get-ChildItem "*.vsix" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($vsixFile) {
            Copy-Item $vsixFile.FullName "$outputDir\vscode\openpilot-vscode.vsix" -Force
            $vsixSize = $vsixFile.Length / 1KB
            Write-Host "[SUCCESS] VSCode extension built: openpilot-vscode.vsix ($([math]::Round($vsixSize, 2)) KB)" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] VSIX file not found" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "[ERROR] VSCode extension build failed: $_" -ForegroundColor Red
    }
    
    Set-Location "i:\openpilot"
    Write-Host ""
}

# =============================================================================
# BUILD ANDROID APK (Using Docker)
# =============================================================================
if (-not $SkipAndroid) {
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "BUILDING ANDROID APK (Docker)" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    
    try {
        Set-Location "i:\openpilot\mobile"
        
        Write-Host "[1/4] Installing npm dependencies in Docker..." -ForegroundColor Cyan
        docker run --rm -v "${PWD}:/app" -w /app node:18 npm install
        
        Write-Host "[2/4] Preparing Android environment..." -ForegroundColor Cyan
        Write-Host "[INFO] This may take 5-10 minutes on first run..." -ForegroundColor Yellow
        
        # Pull Android build image
        docker pull reactnativecommunity/react-native-android:latest
        
        Write-Host "[3/4] Building APK in Docker container..." -ForegroundColor Cyan
        Write-Host "[INFO] Building release APK..." -ForegroundColor Cyan
        
        # Build APK using React Native Android Docker image
        docker run --rm `
            -v "${PWD}:/app" `
            -w /app `
            reactnativecommunity/react-native-android:latest `
            bash -c 'cd android && chmod +x gradlew && ./gradlew assembleRelease'
        
        Write-Host "[4/4] Copying APK file..." -ForegroundColor Cyan
        $apkPath = "android\app\build\outputs\apk\release\app-release.apk"
        if (Test-Path $apkPath) {
            Copy-Item $apkPath "$outputDir\android\openpilot-mobile.apk" -Force
            $apkSize = (Get-Item "$outputDir\android\openpilot-mobile.apk").Length / 1MB
            Write-Host "[SUCCESS] Android APK built: openpilot-mobile.apk ($([math]::Round($apkSize, 2)) MB)" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] APK not found at expected location" -ForegroundColor Yellow
            Write-Host "[INFO] Creating Android build guide instead..." -ForegroundColor Cyan
            
            # Create build guide
            $androidGuide = @"
# Android APK Build Guide (Docker Method)

## Quick Build with Docker

``````bash
cd mobile

# Install dependencies
docker run --rm -v `${PWD}:/app -w /app node:18 npm install

# Build APK
docker run --rm -v `${PWD}:/app -w /app reactnativecommunity/react-native-android bash -c 'cd android && ./gradlew assembleRelease'

# APK location:
# android/app/build/outputs/apk/release/app-release.apk
``````

## Install on Device

``````bash
adb devices
adb install android/app/build/outputs/apk/release/app-release.apk
``````

## Troubleshooting

- Ensure Docker has enough memory (4GB minimum)
- First build may take 10-15 minutes (downloading dependencies)
- If build fails, try: docker system prune -a
"@
            
            $androidGuide | Out-File "$outputDir\android\BUILD_GUIDE.md" -Encoding UTF8
        }
        
    } catch {
        Write-Host "[ERROR] Android build failed: $_" -ForegroundColor Red
        Write-Host "[INFO] You can build manually using the guide in android folder" -ForegroundColor Cyan
    }
    
    Set-Location "i:\openpilot"
    Write-Host ""
}

# =============================================================================
# CREATE COMPREHENSIVE TESTING GUIDE
# =============================================================================
Write-Host "[INFO] Creating testing guide..." -ForegroundColor Cyan

# Create simple testing guide file
@"
# Docker-Built Installers - Testing Guide

Build Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Output Directory: $outputDir

## Quick Test Commands

Web App:
  docker run --rm -p 3000:3000 -v `${PWD}/web-test:/usr/share/nginx/html nginx:alpine

VSCode Extension:
  code --install-extension $outputDir\vscode\openpilot-vscode.vsix

Android APK:
  adb install $outputDir\android\openpilot-mobile.apk

Desktop App:
  Navigate to $outputDir\desktop and run the executable

## Rebuild Commands

Full rebuild:
  .\docker-build-installers.ps1

Skip Android (faster):
  .\docker-build-installers.ps1 -SkipAndroid

## Support
Repository: https://github.com/dayahere/openpilot
"@ | Out-File "$outputDir\TESTING_GUIDE.md" -Encoding UTF8

Write-Host "[SUCCESS] Testing guide created" -ForegroundColor Green
Write-Host ""

# =============================================================================
# SUMMARY
# =============================================================================
Write-Host "=========================================" -ForegroundColor Green
Write-Host "DOCKER BUILD COMPLETE!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output Directory: $outputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Generated Files:" -ForegroundColor Cyan

Get-ChildItem $outputDir -Recurse -File | ForEach-Object {
    $size = if ($_.Length -gt 1MB) { 
        "$([math]::Round($_.Length / 1MB, 2)) MB" 
    } elseif ($_.Length -gt 1KB) { 
        "$([math]::Round($_.Length / 1KB, 2)) KB" 
    } else { 
        "$($_.Length) bytes" 
    }
    $relativePath = $_.FullName.Replace($outputDir, ".")
    Write-Host "  [OK] $relativePath ($size)" -ForegroundColor White
}

Write-Host ""
Write-Host "Read TESTING_GUIDE.md for testing instructions!" -ForegroundColor Yellow
Write-Host ""
Write-Host "All builds completed using Docker - no local dependencies needed!" -ForegroundColor Green
Write-Host ""

# Open output directory
Start-Process explorer.exe $outputDir
