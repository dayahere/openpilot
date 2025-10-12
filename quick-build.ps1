# Quick Build Script - Installs Node.js and builds all installers
# Run this to generate actual testable installers

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "OpenPilot Quick Build Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Node.js is installed
Write-Host "[1/6] Checking Node.js installation..." -ForegroundColor Yellow
$nodeInstalled = Get-Command node -ErrorAction SilentlyContinue

if (-not $nodeInstalled) {
    Write-Host "Node.js not found. Installing via Chocolatey..." -ForegroundColor Yellow
    
    # Check if Chocolatey is installed
    $chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
    
    if (-not $chocoInstalled) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
    
    Write-Host "Installing Node.js LTS..." -ForegroundColor Yellow
    choco install nodejs-lts -y
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "[SUCCESS] Node.js installed!" -ForegroundColor Green
} else {
    $nodeVersion = node --version
    Write-Host "[SUCCESS] Node.js already installed: $nodeVersion" -ForegroundColor Green
}

Write-Host ""

# Create output directory
$outputDir = "i:\openpilot\quick-build-output"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$buildDir = "$outputDir\$timestamp"

Write-Host "[2/6] Creating output directory: $buildDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
Write-Host "[SUCCESS] Output directory created" -ForegroundColor Green
Write-Host ""

# Build Web App
Write-Host "[3/6] Building Web Application..." -ForegroundColor Yellow
try {
    Set-Location "i:\openpilot\web"
    
    Write-Host "  Installing dependencies..." -ForegroundColor Cyan
    npm install --legacy-peer-deps 2>&1 | Out-Null
    
    Write-Host "  Building production app..." -ForegroundColor Cyan
    npm run build 2>&1 | Out-Null
    
    if (Test-Path "build") {
        Write-Host "  Creating ZIP archive..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Path "$buildDir\web" -Force | Out-Null
        Compress-Archive -Path "build\*" -DestinationPath "$buildDir\web\openpilot-web.zip" -Force
        Write-Host "[SUCCESS] Web app built: openpilot-web.zip" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Web build folder not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] Web build failed: $_" -ForegroundColor Red
}

Set-Location "i:\openpilot"
Write-Host ""

# Build Desktop App
Write-Host "[4/6] Building Desktop Application..." -ForegroundColor Yellow
try {
    Set-Location "i:\openpilot\desktop"
    
    Write-Host "  Installing dependencies..." -ForegroundColor Cyan
    npm install --legacy-peer-deps 2>&1 | Out-Null
    
    Write-Host "  Building application..." -ForegroundColor Cyan
    npm run build 2>&1 | Out-Null
    
    # Check if package script exists
    $packageJson = Get-Content "package.json" | ConvertFrom-Json
    if ($packageJson.scripts."package-win") {
        Write-Host "  Packaging Windows installer..." -ForegroundColor Cyan
        npm run package-win 2>&1 | Out-Null
        
        # Copy installer if it exists
        if (Test-Path "release") {
            New-Item -ItemType Directory -Path "$buildDir\desktop" -Force | Out-Null
            Copy-Item "release\*" "$buildDir\desktop\" -Recurse -Force
            Write-Host "[SUCCESS] Desktop app packaged" -ForegroundColor Green
        }
    } else {
        Write-Host "[INFO] Desktop build created (packaging script not configured)" -ForegroundColor Cyan
        if (Test-Path "build") {
            New-Item -ItemType Directory -Path "$buildDir\desktop" -Force | Out-Null
            Copy-Item "build\*" "$buildDir\desktop\" -Recurse -Force
        }
    }
} catch {
    Write-Host "[ERROR] Desktop build failed: $_" -ForegroundColor Red
}

Set-Location "i:\openpilot"
Write-Host ""

# Build VS Code Extension
Write-Host "[5/6] Building VS Code Extension..." -ForegroundColor Yellow
try {
    Set-Location "i:\openpilot\vscode-extension"
    
    Write-Host "  Installing dependencies..." -ForegroundColor Cyan
    npm install 2>&1 | Out-Null
    
    Write-Host "  Compiling extension..." -ForegroundColor Cyan
    npm run compile 2>&1 | Out-Null
    
    Write-Host "  Packaging VSIX..." -ForegroundColor Cyan
    npx @vscode/vsce package --no-git-tag-version 2>&1 | Out-Null
    
    # Copy VSIX file
    $vsixFile = Get-ChildItem "*.vsix" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($vsixFile) {
        New-Item -ItemType Directory -Path "$buildDir\vscode" -Force | Out-Null
        Copy-Item $vsixFile.FullName "$buildDir\vscode\openpilot-vscode.vsix" -Force
        Write-Host "[SUCCESS] VS Code extension packaged: openpilot-vscode.vsix" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] VSIX file not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] VS Code extension build failed: $_" -ForegroundColor Red
}

Set-Location "i:\openpilot"
Write-Host ""

# Create Testing Guide
Write-Host "[6/6] Creating testing documentation..." -ForegroundColor Yellow

$testGuide = @"
# Quick Testing Guide
**Build Date:** $(Get-Date -Format "MMMM dd, yyyy HH:mm:ss")
**Build Directory:** $buildDir

## Generated Installers

$(if (Test-Path "$buildDir\web\openpilot-web.zip") { "✅ Web App: $buildDir\web\openpilot-web.zip" } else { "❌ Web App: Build failed" })
$(if (Test-Path "$buildDir\desktop") { "✅ Desktop App: $buildDir\desktop\" } else { "❌ Desktop App: Build failed" })
$(if (Test-Path "$buildDir\vscode\openpilot-vscode.vsix") { "✅ VSCode Extension: $buildDir\vscode\openpilot-vscode.vsix" } else { "❌ VSCode Extension: Build failed" })

## How to Test

### Test Web App
1. Extract openpilot-web.zip
2. Run: ``npx serve -s {extracted-folder}``
3. Open: http://localhost:3000

### Test Desktop App
1. Navigate to: $buildDir\desktop\
2. Run the executable file

### Test VS Code Extension
1. Open VS Code
2. Press Ctrl+Shift+X
3. Click '...' menu
4. Select 'Install from VSIX...'
5. Choose: $buildDir\vscode\openpilot-vscode.vsix

## Android APK Build

Android builds require Android Studio. Follow these steps:

``````bash
# Navigate to mobile project
cd i:\openpilot\mobile

# Install dependencies
npm install

# Build APK
cd android
.\gradlew assembleRelease

# APK location:
# mobile\android\app\build\outputs\apk\release\app-release.apk

# Install on device
adb install android\app\build\outputs\apk\release\app-release.apk
``````

## iOS Build

iOS builds require macOS with Xcode:

``````bash
cd mobile
npm install
cd ios
pod install
open OpenPilot.xcworkspace
# Use Xcode to build and archive
``````

## Troubleshooting

### Web App Issues
- Check if build folder was created
- Verify npm install completed successfully
- Try: npm install --legacy-peer-deps

### Desktop App Issues  
- Check if Electron is configured in package.json
- Verify build scripts exist
- Run: npm run dev (for development mode)

### VSCode Extension Issues
- Check Node.js version (must be 18+)
- Verify @vscode/vsce is installed
- Try: npm install -g @vscode/vsce

## Next Steps

1. Test each installer on target platform
2. Report any issues to: https://github.com/dayahere/openpilot/issues
3. Review documentation in each build folder
4. Run unit tests: npm test (in each project folder)

## Support

- Repository: https://github.com/dayahere/openpilot
- Issues: https://github.com/dayahere/openpilot/issues
- Documentation: i:\openpilot\docs\
"@

$testGuide | Out-File "$buildDir\TESTING_GUIDE.md" -Encoding UTF8
Write-Host "[SUCCESS] Testing guide created" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "=========================================" -ForegroundColor Green
Write-Host "BUILD COMPLETE!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output Directory: $buildDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Generated Files:" -ForegroundColor Cyan
Get-ChildItem $buildDir -Recurse -File | ForEach-Object {
    $size = if ($_.Length -gt 1MB) { "{0:N2} MB" -f ($_.Length / 1MB) } else { "{0:N2} KB" -f ($_.Length / 1KB) }
    Write-Host "  - $($_.FullName.Replace($buildDir, '.')): $size" -ForegroundColor White
}

Write-Host ""
Write-Host "Read TESTING_GUIDE.md for testing instructions!" -ForegroundColor Yellow
Write-Host ""

# Open output directory
explorer.exe $buildDir
