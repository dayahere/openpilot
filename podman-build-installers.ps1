# Podman-Based Installer Builder
# Alternative to Docker - uses Podman instead
# Builds ALL installers using ONLY Podman - No local Node.js/npm required!

param(
    [switch]$SkipAndroid,
    [switch]$SkipDesktop,
    [switch]$SkipWeb,
    [switch]$SkipVSCode
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Podman-Based Installer Builder" -ForegroundColor Cyan
Write-Host "No Node.js/npm installation required!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check Podman availability
Write-Host "[INFO] Checking Podman..." -ForegroundColor Cyan
$podmanInstalled = Get-Command podman -ErrorAction SilentlyContinue

if (-not $podmanInstalled) {
    Write-Host "[WARNING] Podman not found. Installing via Chocolatey..." -ForegroundColor Yellow
    
    # Check Chocolatey
    $chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
    if (-not $chocoInstalled) {
        Write-Host "[INFO] Installing Chocolatey first..." -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
    
    Write-Host "[INFO] Installing Podman..." -ForegroundColor Cyan
    choco install podman-desktop -y
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "[SUCCESS] Podman installed!" -ForegroundColor Green
}

try {
    $podmanVersion = podman --version
    Write-Host "[SUCCESS] Podman found: $podmanVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Podman not available after installation." -ForegroundColor Red
    Write-Host "[INFO] Falling back to Docker..." -ForegroundColor Yellow
    
    # Try Docker instead
    $dockerVersion = docker --version
    Write-Host "[SUCCESS] Using Docker instead: $dockerVersion" -ForegroundColor Green
    $useDocker = $true
}

# Determine command to use
$containerCmd = if ($useDocker) { "docker" } else { "podman" }
Write-Host "[INFO] Using: $containerCmd" -ForegroundColor Cyan
Write-Host ""

# Create output directory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputDir = "i:\openpilot\podman-installers-output\$timestamp"

Write-Host "[INFO] Creating output directory: $outputDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
New-Item -ItemType Directory -Path "$outputDir\android" -Force | Out-Null
New-Item -ItemType Directory -Path "$outputDir\desktop" -Force | Out-Null
New-Item -ItemType Directory -Path "$outputDir\web" -Force | Out-Null
New-Item -ItemType Directory -Path "$outputDir\vscode" -Force | Out-Null
Write-Host "[SUCCESS] Output directory created" -ForegroundColor Green
Write-Host ""

# Web App Build
if (-not $SkipWeb) {
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "BUILDING WEB APP ($containerCmd)" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    
    try {
        Set-Location "i:\openpilot\web"
        
        Write-Host "[1/3] Installing dependencies..." -ForegroundColor Cyan
        & $containerCmd run --rm -v "${PWD}:/app" -w /app node:18 npm install --legacy-peer-deps
        
        Write-Host "[2/3] Building production app..." -ForegroundColor Cyan
        & $containerCmd run --rm -v "${PWD}:/app" -w /app node:18 npm run build
        
        Write-Host "[3/3] Packaging..." -ForegroundColor Cyan
        if (Test-Path "build") {
            Compress-Archive -Path "build\*" -DestinationPath "$outputDir\web\openpilot-web.zip" -Force
            $zipSize = (Get-Item "$outputDir\web\openpilot-web.zip").Length / 1MB
            Write-Host "[SUCCESS] Web app built: $([math]::Round($zipSize, 2)) MB" -ForegroundColor Green
        }
    } catch {
        Write-Host "[ERROR] Web build failed: $_" -ForegroundColor Red
    }
    
    Set-Location "i:\openpilot"
    Write-Host ""
}

# Desktop App Build
if (-not $SkipDesktop) {
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "BUILDING DESKTOP APP ($containerCmd)" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    
    try {
        Set-Location "i:\openpilot\desktop"
        
        Write-Host "[1/2] Installing dependencies..." -ForegroundColor Cyan
        & $containerCmd run --rm -v "${PWD}:/app" -w /app node:18 npm install --legacy-peer-deps
        
        Write-Host "[2/2] Building..." -ForegroundColor Cyan
        & $containerCmd run --rm -v "${PWD}:/app" -w /app node:18 npm run build
        
        if (Test-Path "build") {
            Copy-Item "build\*" "$outputDir\desktop\" -Recurse -Force
            Write-Host "[SUCCESS] Desktop build completed" -ForegroundColor Green
        }
    } catch {
        Write-Host "[ERROR] Desktop build failed: $_" -ForegroundColor Red
    }
    
    Set-Location "i:\openpilot"
    Write-Host ""
}

# VSCode Extension Build
if (-not $SkipVSCode) {
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "BUILDING VSCODE EXTENSION ($containerCmd)" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    
    try {
        Set-Location "i:\openpilot\vscode-extension"
        
        Write-Host "[1/3] Installing dependencies..." -ForegroundColor Cyan
        & $containerCmd run --rm -v "${PWD}:/app" -w /app node:18 npm install
        
        Write-Host "[2/3] Compiling..." -ForegroundColor Cyan
        & $containerCmd run --rm -v "${PWD}:/app" -w /app node:18 npm run compile
        
        Write-Host "[3/3] Packaging VSIX..." -ForegroundColor Cyan
        & $containerCmd run --rm -v "${PWD}:/app" -w /app node:18 npx @vscode/vsce package --no-git-tag-version
        
        $vsixFile = Get-ChildItem "*.vsix" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($vsixFile) {
            Copy-Item $vsixFile.FullName "$outputDir\vscode\openpilot-vscode.vsix" -Force
            Write-Host "[SUCCESS] VSCode extension built" -ForegroundColor Green
        }
    } catch {
        Write-Host "[ERROR] VSCode build failed: $_" -ForegroundColor Red
    }
    
    Set-Location "i:\openpilot"
    Write-Host ""
}

# Android APK Build
if (-not $SkipAndroid) {
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "BUILDING ANDROID APK ($containerCmd)" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    
    try {
        Set-Location "i:\openpilot\mobile"
        
        Write-Host "[1/3] Installing npm dependencies..." -ForegroundColor Cyan
        & $containerCmd run --rm -v "${PWD}:/app" -w /app node:18 npm install
        
        Write-Host "[2/3] Pulling Android build image..." -ForegroundColor Cyan
        & $containerCmd pull reactnativecommunity/react-native-android:latest
        
        Write-Host "[3/3] Building APK (this may take 10+ minutes)..." -ForegroundColor Cyan
        & $containerCmd run --rm -v "${PWD}:/app" -w /app reactnativecommunity/react-native-android bash -c 'cd android && chmod +x gradlew && ./gradlew assembleRelease'
        
        $apkPath = "android\app\build\outputs\apk\release\app-release.apk"
        if (Test-Path $apkPath) {
            Copy-Item $apkPath "$outputDir\android\openpilot-mobile.apk" -Force
            $apkSize = (Get-Item "$outputDir\android\openpilot-mobile.apk").Length / 1MB
            Write-Host "[SUCCESS] Android APK built: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] APK not generated - see BUILD_GUIDE.md" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[ERROR] Android build failed: $_" -ForegroundColor Red
    }
    
    Set-Location "i:\openpilot"
    Write-Host ""
}

# Summary
Write-Host "=========================================" -ForegroundColor Green
Write-Host "BUILD COMPLETE!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Container Tool Used: $containerCmd" -ForegroundColor Cyan
Write-Host "Output Directory: $outputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Generated Files:" -ForegroundColor Cyan
Get-ChildItem $outputDir -Recurse -File | ForEach-Object {
    $size = if ($_.Length -gt 1MB) { "$([math]::Round($_.Length / 1MB, 2)) MB" } else { "$([math]::Round($_.Length / 1KB, 2)) KB" }
    Write-Host "  ✓ $($_.Name) ($size)" -ForegroundColor White
}

Write-Host ""
Start-Process explorer.exe $outputDir
