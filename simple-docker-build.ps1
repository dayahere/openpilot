# Simple Docker Installer Builder
# Generates all installers using Docker - NO local Node.js needed!

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "OpenPilot Docker Installer Builder" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Create output directory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputRoot = "i:\openpilot\installers"
$outputDir = "$outputRoot\$timestamp"

Write-Host "[INFO] Creating output directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "$outputDir\android" -Force | Out-Null
New-Item -ItemType Directory -Path "$outputDir\ios" -Force | Out-Null
New-Item -ItemType Directory -Path "$outputDir\desktop" -Force | Out-Null
New-Item -ItemType Directory -Path "$outputDir\web" -Force | Out-Null
New-Item -ItemType Directory -Path "$outputDir\vscode" -Force | Out-Null
Write-Host "[OK] Output: $outputDir" -ForegroundColor Green
Write-Host ""

# =============================================================================
# WEB APP
# =============================================================================
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "BUILDING WEB APP" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Set-Location "i:\openpilot\web"

Write-Host "[1/3] Installing dependencies..." -ForegroundColor Yellow
docker run --rm -v "${PWD}:/app" -w /app node:18 bash -c "npm install --legacy-peer-deps 2>&1 | tail -20"

Write-Host "[2/3] Building production bundle..." -ForegroundColor Yellow
docker run --rm -v "${PWD}:/app" -w /app node:18 bash -c "npm run build 2>&1 | tail -20"

Write-Host "[3/3] Packaging..." -ForegroundColor Yellow
if (Test-Path "build") {
    Compress-Archive -Path "build\*" -DestinationPath "$outputDir\web\openpilot-web.zip" -Force
    $size = [math]::Round((Get-Item "$outputDir\web\openpilot-web.zip").Length / 1MB, 2)
    Write-Host "[SUCCESS] Web: openpilot-web.zip ($size MB)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Web build folder not found" -ForegroundColor Red
}
Write-Host ""

# =============================================================================
# DESKTOP APP
# =============================================================================
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "BUILDING DESKTOP APP" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Set-Location "i:\openpilot\desktop"

Write-Host "[1/2] Installing dependencies..." -ForegroundColor Yellow
docker run --rm -v "${PWD}:/app" -w /app node:18 bash -c "npm install --legacy-peer-deps 2>&1 | tail -20"

Write-Host "[2/2] Building..." -ForegroundColor Yellow
docker run --rm -v "${PWD}:/app" -w /app node:18 bash -c "npm run build 2>&1 | tail -20"

if (Test-Path "build") {
    Copy-Item "build\*" "$outputDir\desktop\" -Recurse -Force
    Write-Host "[SUCCESS] Desktop app built" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Desktop build folder not found" -ForegroundColor Red
}
Write-Host ""

# =============================================================================
# VSCODE EXTENSION
# =============================================================================
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "BUILDING VSCODE EXTENSION" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Set-Location "i:\openpilot\vscode-extension"

Write-Host "[1/3] Installing dependencies..." -ForegroundColor Yellow
docker run --rm -v "${PWD}:/app" -w /app node:18 bash -c "npm install 2>&1 | tail -20"

Write-Host "[2/3] Compiling TypeScript..." -ForegroundColor Yellow
docker run --rm -v "${PWD}:/app" -w /app node:18 bash -c "npm run compile 2>&1 | tail -20"

Write-Host "[3/3] Packaging VSIX..." -ForegroundColor Yellow
docker run --rm -v "${PWD}:/app" -w /app node:18 bash -c "npx @vscode/vsce package --no-git-tag-version --allow-star-activation 2>&1 | tail -20"

$vsixFile = Get-ChildItem "*.vsix" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($vsixFile) {
    Copy-Item $vsixFile.FullName "$outputDir\vscode\openpilot-vscode.vsix" -Force
    $size = [math]::Round($vsixFile.Length / 1KB, 2)
    Write-Host "[SUCCESS] VSCode: openpilot-vscode.vsix ($size KB)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] VSIX file not generated" -ForegroundColor Red
}
Write-Host ""

# =============================================================================
# ANDROID APK
# =============================================================================
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "BUILDING ANDROID APK" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Set-Location "i:\openpilot\mobile"

Write-Host "[1/3] Installing npm dependencies..." -ForegroundColor Yellow
docker run --rm -v "${PWD}:/app" -w /app node:18 bash -c "npm install 2>&1 | tail -20"

Write-Host "[2/3] Building APK (this takes 10-15 minutes)..." -ForegroundColor Yellow
Write-Host "[INFO] Please be patient - downloading Android SDK..." -ForegroundColor Cyan

docker run --rm -v "${PWD}:/app" -w /app reactnativecommunity/react-native-android:latest bash -c "cd android && chmod +x gradlew && ./gradlew assembleRelease 2>&1 | tail -30"

$apkPath = "android\app\build\outputs\apk\release\app-release.apk"
if (Test-Path $apkPath) {
    Copy-Item $apkPath "$outputDir\android\openpilot-mobile.apk" -Force
    $size = [math]::Round((Get-Item "$outputDir\android\openpilot-mobile.apk").Length / 1MB, 2)
    Write-Host "[SUCCESS] Android: openpilot-mobile.apk ($size MB)" -ForegroundColor Green
} else {
    Write-Host "[WARN] APK not built - creating build guide instead" -ForegroundColor Yellow
    
    @"
# Android APK Build Guide

## Quick Build with Docker

``bash
cd i:\openpilot\mobile
docker run --rm -v `${PWD}:/app -w /app node:18 npm install
docker run --rm -v `${PWD}:/app -w /app reactnativecommunity/react-native-android bash -c 'cd android && ./gradlew assembleRelease'
``

## Install APK
``bash
adb install android/app/build/outputs/apk/release/app-release.apk
``
"@ | Out-File "$outputDir\android\BUILD_GUIDE.md" -Encoding UTF8
    Write-Host "[INFO] Build guide created: android\BUILD_GUIDE.md" -ForegroundColor Cyan
}
Write-Host ""

# =============================================================================
# iOS BUILD GUIDE
# =============================================================================
Write-Host "[INFO] Creating iOS build guide (requires macOS)..." -ForegroundColor Yellow

@"
# iOS Build Guide

iOS builds require macOS with Xcode.

## Prerequisites
- macOS Ventura or later
- Xcode 14+
- CocoaPods
- Apple Developer Account

## Build Steps

1. Install dependencies:
``bash
cd i:\openpilot\mobile
npm install
cd ios
pod install
``

2. Open in Xcode:
``bash
open ios/OpenPilot.xcworkspace
``

3. Build and Archive:
- Select your team in Signing & Capabilities
- Choose 'Any iOS Device' as target
- Product → Archive
- Follow distribution wizard

## Quick Test (Simulator)
``bash
npx react-native run-ios
``
"@ | Out-File "$outputDir\ios\BUILD_GUIDE.md" -Encoding UTF8

Write-Host "[OK] iOS build guide created" -ForegroundColor Green
Write-Host ""

# =============================================================================
# CREATE TESTING GUIDE
# =============================================================================
Write-Host "[INFO] Creating testing guide..." -ForegroundColor Yellow

@"
# Installer Testing Guide

Build Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Output: $outputDir

## Generated Installers

Web App: $(if (Test-Path "$outputDir\web\openpilot-web.zip") { "OK - openpilot-web.zip" } else { "FAILED" })
Desktop: $(if (Test-Path "$outputDir\desktop") { "OK - build folder" } else { "FAILED" })
VSCode: $(if (Test-Path "$outputDir\vscode\openpilot-vscode.vsix") { "OK - openpilot-vscode.vsix" } else { "FAILED" })
Android: $(if (Test-Path "$outputDir\android\openpilot-mobile.apk") { "OK - openpilot-mobile.apk" } else { "See BUILD_GUIDE.md" })
iOS: See BUILD_GUIDE.md (requires macOS)

## Quick Test Commands

### Test Web App
``powershell
# Extract and serve
Expand-Archive $outputDir\web\openpilot-web.zip -DestinationPath web-test
docker run --rm -p 3000:3000 -v `${PWD}/web-test:/usr/share/nginx/html nginx:alpine
# Open: http://localhost:3000
``

### Test Desktop App
``powershell
cd $outputDir\desktop
# Run the index.html or executable
``

### Test VSCode Extension
``powershell
code --install-extension $outputDir\vscode\openpilot-vscode.vsix
``

### Test Android APK
``powershell
adb devices
adb install $outputDir\android\openpilot-mobile.apk
``

## Rebuild

To rebuild everything:
``powershell
cd i:\openpilot
.\simple-docker-build.ps1
``

## Support
Repository: https://github.com/dayahere/openpilot
Issues: https://github.com/dayahere/openpilot/issues
"@ | Out-File "$outputDir\TESTING_GUIDE.md" -Encoding UTF8

Write-Host "[OK] Testing guide created" -ForegroundColor Green
Write-Host ""

# =============================================================================
# SUMMARY
# =============================================================================
Set-Location "i:\openpilot"

Write-Host "================================================" -ForegroundColor Green
Write-Host "BUILD COMPLETE!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output Directory:" -ForegroundColor Cyan
Write-Host "  $outputDir" -ForegroundColor White
Write-Host ""
Write-Host "Generated Files:" -ForegroundColor Cyan

$allFiles = Get-ChildItem $outputDir -Recurse -File
foreach ($file in $allFiles) {
    $size = if ($file.Length -gt 1MB) { 
        "$([math]::Round($file.Length / 1MB, 2)) MB" 
    } else { 
        "$([math]::Round($file.Length / 1KB, 2)) KB" 
    }
    $relativePath = $file.FullName.Replace($outputDir, ".")
    Write-Host "  $relativePath - $size" -ForegroundColor White
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Read: $outputDir\TESTING_GUIDE.md" -ForegroundColor White
Write-Host "  2. Test each installer on target platform" -ForegroundColor White
Write-Host "  3. Report issues to GitHub" -ForegroundColor White
Write-Host ""

# Open output folder
Start-Process explorer.exe $outputDir
