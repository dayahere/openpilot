# Generate Actual Installers Script
# This script builds actual installer files (.vsix, .zip, .apk) using Docker

$ErrorActionPreference = "Continue"
$OutputDir = "i:\openpilot\installers\20251012-104611"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "OPENPILOT INSTALLER GENERATOR" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Create output directories
New-Item -ItemType Directory -Force -Path "$OutputDir\vscode" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputDir\web" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputDir\desktop" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputDir\android" | Out-Null

# ========================================
# 1. BUILD VSCODE EXTENSION (.vsix)
# ========================================
Write-Host "[1/4] Building VSCode Extension..." -ForegroundColor Yellow
Write-Host "      Expected time: 2-3 minutes" -ForegroundColor Gray

Push-Location "i:\openpilot\vscode-extension"

# Build in Docker
docker run --rm -v "${PWD}:/workspace" -w /workspace node:20 bash -c "npm install --legacy-peer-deps --no-audit --no-fund && npm run compile && npx @vscode/vsce package --allow-star-activation --no-git-tag-version"

if ($LASTEXITCODE -eq 0) {
    $vsixFile = Get-ChildItem -Filter "*.vsix" | Select-Object -First 1
    if ($vsixFile) {
        Copy-Item $vsixFile.FullName "$OutputDir\vscode\openpilot-vscode.vsix" -Force
        Write-Host "      [SUCCESS] $($vsixFile.Name) created!" -ForegroundColor Green
        Write-Host "      Location: $OutputDir\vscode\openpilot-vscode.vsix" -ForegroundColor Green
    } else {
        Write-Host "      [WARNING] No .vsix file found after build" -ForegroundColor Red
    }
} else {
    Write-Host "      [FAILED] VSCode build failed (Exit code: $LASTEXITCODE)" -ForegroundColor Red
}

Pop-Location

# ========================================
# 2. BUILD WEB APP (production ZIP)
# ========================================
Write-Host "`n[2/4] Building Web App..." -ForegroundColor Yellow
Write-Host "      Expected time: 3-5 minutes" -ForegroundColor Gray

Push-Location "i:\openpilot\web"

# Build in Docker  
docker run --rm -v "${PWD}:/workspace" -w /workspace node:20 bash -c "npm install --legacy-peer-deps --no-audit --no-fund && npm run build"

if ($LASTEXITCODE -eq 0 -and (Test-Path "build")) {
    # Create ZIP of build folder
    Compress-Archive -Path "build\*" -DestinationPath "$OutputDir\web\openpilot-web.zip" -Force
    $zipSize = [math]::Round((Get-Item "$OutputDir\web\openpilot-web.zip").Length / 1MB, 2)
    Write-Host "      [SUCCESS] Web app built and packaged!" -ForegroundColor Green
    Write-Host "      Location: $OutputDir\web\openpilot-web.zip ($zipSize MB)" -ForegroundColor Green
} else {
    Write-Host "      [FAILED] Web build failed or build folder not created" -ForegroundColor Red
}

Pop-Location

# ========================================
# 3. BUILD DESKTOP APP
# ========================================
Write-Host "`n[3/4] Building Desktop App..." -ForegroundColor Yellow
Write-Host "      Expected time: 5-10 minutes" -ForegroundColor Gray

Push-Location "i:\openpilot\desktop"

# Build in Docker
docker run --rm -v "${PWD}:/workspace" -w /workspace node:20 bash -c "npm install --legacy-peer-deps --no-audit --no-fund && npm run build"

if ($LASTEXITCODE -eq 0 -and (Test-Path "build")) {
    # Copy build folder
    Copy-Item -Path "build\*" -Destination "$OutputDir\desktop\" -Recurse -Force
    $fileCount = (Get-ChildItem "$OutputDir\desktop" -Recurse -File).Count
    Write-Host "      [SUCCESS] Desktop app built!" -ForegroundColor Green
    Write-Host "      Location: $OutputDir\desktop\ ($fileCount files)" -ForegroundColor Green
} else {
    Write-Host "      [FAILED] Desktop build failed or build folder not created" -ForegroundColor Red
}

Pop-Location

# ========================================
# 4. BUILD ANDROID APK
# ========================================
Write-Host "`n[4/4] Building Android APK..." -ForegroundColor Yellow
Write-Host "      Expected time: 15-25 minutes (first time)" -ForegroundColor Gray
Write-Host "      Note: This downloads ~2GB of Android SDK and dependencies" -ForegroundColor Gray

$buildAndroid = Read-Host "`n      Build Android APK now? This will take 15-25 minutes. (y/N)"

if ($buildAndroid -eq 'y' -or $buildAndroid -eq 'Y') {
    Push-Location "i:\openpilot\mobile"

    # Install Node dependencies first
    docker run --rm -v "${PWD}:/workspace" -w /workspace node:20 bash -c "npm install --legacy-peer-deps --no-audit --no-fund"

    # Build Android APK
    docker run --rm -v "${PWD}:/workspace" -w /workspace reactnativecommunity/react-native-android:latest bash -c "cd android && chmod +x gradlew && ./gradlew assembleRelease --no-daemon --warning-mode all"

    $apkPath = "android\app\build\outputs\apk\release\app-release.apk"
    if (Test-Path $apkPath) {
        Copy-Item $apkPath "$OutputDir\android\openpilot-mobile.apk" -Force
        $apkSize = [math]::Round((Get-Item "$OutputDir\android\openpilot-mobile.apk").Length / 1MB, 2)
        Write-Host "      [SUCCESS] Android APK built!" -ForegroundColor Green
        Write-Host "      Location: $OutputDir\android\openpilot-mobile.apk ($apkSize MB)" -ForegroundColor Green
    } else {
        Write-Host "      [FAILED] APK not found at $apkPath" -ForegroundColor Red
    }

    Pop-Location
} else {
    Write-Host "      [SKIPPED] Android build skipped by user" -ForegroundColor Yellow
}

# ========================================
# SUMMARY
# ========================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "BUILD SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$installers = @(
    @{Name="VSCode Extension"; Path="$OutputDir\vscode\openpilot-vscode.vsix"},
    @{Name="Web App"; Path="$OutputDir\web\openpilot-web.zip"},
    @{Name="Desktop App"; Path="$OutputDir\desktop\index.html"},
    @{Name="Android APK"; Path="$OutputDir\android\openpilot-mobile.apk"}
)

$successCount = 0
foreach ($installer in $installers) {
    if (Test-Path $installer.Path) {
        $size = if ((Get-Item $installer.Path).PSIsContainer) { 
            "Directory" 
        } else { 
            "$([math]::Round((Get-Item $installer.Path).Length / 1KB, 2)) KB"
        }
        Write-Host "[FOUND] $($installer.Name): $size" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "[MISSING] $($installer.Name)" -ForegroundColor Red
    }
}

Write-Host "`nTotal installers created: $successCount / 4" -ForegroundColor Cyan
Write-Host "Output directory: $OutputDir" -ForegroundColor Cyan

# Open output directory
Write-Host "`nOpening output directory..." -ForegroundColor Gray
Start-Process explorer.exe -ArgumentList $OutputDir

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TESTING INSTRUCTIONS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "VSCode Extension:" -ForegroundColor Yellow
Write-Host "  code --install-extension `"$OutputDir\vscode\openpilot-vscode.vsix`"" -ForegroundColor Gray

Write-Host "`nWeb App:" -ForegroundColor Yellow
Write-Host "  cd `"$OutputDir\web`"" -ForegroundColor Gray
Write-Host "  Expand-Archive openpilot-web.zip -DestinationPath extracted" -ForegroundColor Gray
Write-Host "  docker run --rm -p 3000:3000 -v `"`${PWD}/extracted:/usr/share/nginx/html`" nginx:alpine" -ForegroundColor Gray
Write-Host "  Then open: http://localhost:3000" -ForegroundColor Gray

Write-Host "`nDesktop App:" -ForegroundColor Yellow
Write-Host "  start `"$OutputDir\desktop\index.html`"" -ForegroundColor Gray

Write-Host "`nAndroid APK:" -ForegroundColor Yellow
Write-Host "  adb install `"$OutputDir\android\openpilot-mobile.apk`"" -ForegroundColor Gray

Write-Host "`n========================================`n" -ForegroundColor Cyan
