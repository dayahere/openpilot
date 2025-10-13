# OpenPilot - Local Container Build Script
# Builds all platforms (VSCode Extension, Web, Desktop, Android) locally using Docker/Podman
# No npm/Node.js installation required on host machine!

param(
    [switch]$UsePodman,
    [switch]$SkipTests,
    [switch]$SkipAndroid,
    [switch]$SkipDesktop,
    [switch]$SkipWeb,
    [switch]$SkipVSCode,
    [switch]$Clean,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Determine which container tool to use
$containerTool = if ($UsePodman) { "podman" } else { "docker" }

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " OpenPilot - Local Container Build Script" -ForegroundColor Cyan
Write-Host " Using: $containerTool" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if container tool is available
Write-Host "[1/10] Checking $containerTool availability..." -ForegroundColor Yellow
try {
    $version = & $containerTool --version
    Write-Host "[OK] $containerTool is available: $version" -ForegroundColor Green
} catch {
    Write-Host "[X] ${containerTool} is not installed or not in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install ${containerTool}:" -ForegroundColor Yellow
    if ($UsePodman) {
        Write-Host "  Download from https://podman.io/getting-started/installation" -ForegroundColor White
    } else {
        Write-Host "  Download from https://www.docker.com/products/docker-desktop" -ForegroundColor White
    }
    exit 1
}
Write-Host ""

# Create timestamp and output directory
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputDir = "artifacts-local/$timestamp"

# Clean old artifacts if requested
if ($Clean) {
    Write-Host "[2/10] Cleaning old artifacts..." -ForegroundColor Yellow
    if (Test-Path "artifacts-local") {
        Remove-Item -Recurse -Force "artifacts-local"
    }
    Write-Host "[OK] Cleaned" -ForegroundColor Green
    Write-Host ""
}

# Create artifacts directory structure
Write-Host "[2/10] Creating artifact directories..." -ForegroundColor Yellow
$dirs = @(
    $outputDir,
    "$outputDir/vscode",
    "$outputDir/web",
    "$outputDir/desktop",
    "$outputDir/android",
    "$outputDir/logs"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}
Write-Host "[OK] Directories created" -ForegroundColor Green
Write-Host ""

# Function to log build output
function Write-BuildLog {
    param($Message, $LogFile)
    $timestamp = Get-Date -Format "HH:mm:ss"
    "[$timestamp] $Message" | Out-File -Append -FilePath "$outputDir/logs/$LogFile"
}

# Run tests first (if not skipped)
if (-not $SkipTests) {
    Write-Host "[3/10] Running tests in container..." -ForegroundColor Yellow
    Write-Host "       This will take 2-3 minutes (installing dependencies)..." -ForegroundColor Cyan
    Write-Host ""
    
    $testLog = "test-results.log"
    Write-BuildLog "Starting test suite" $testLog
    
    try {
        Write-Host "       Building test environment..." -ForegroundColor Cyan
        
        # Create temporary Dockerfile
        $dockerfileContent = @"
FROM node:20-alpine
WORKDIR /workspace
RUN apk add --no-cache git bash
COPY package*.json ./
COPY core/package*.json ./core/
COPY tests/package*.json ./tests/
RUN npm install --workspaces --legacy-peer-deps
COPY . .
RUN cd core && npm run build
CMD ["npm", "test", "--prefix", "tests"]
"@
        $tempDockerfile = "Dockerfile.test.tmp"
        $dockerfileContent | Out-File -FilePath $tempDockerfile -Encoding UTF8
        
        $testBuildOutput = & $containerTool build -t openpilot-test -f $tempDockerfile . 2>&1
        ($testBuildOutput | Out-String) | Out-File -Append -FilePath "$outputDir/logs/$testLog"
        Remove-Item $tempDockerfile -ErrorAction SilentlyContinue
        
        # Check if build failed by looking for error indicators
        $buildFailed = $testBuildOutput | Select-String -Pattern "^ERROR|failed to solve|error building|ERROR:.*failed" -Quiet
        if ($buildFailed) {
            Write-Host "[X] Test environment build failed" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "       Running test suite..." -ForegroundColor Cyan
        $testOutput = & $containerTool run --rm openpilot-test 2>&1
        ($testOutput | Out-String) | Out-File -Append -FilePath "$outputDir/logs/$testLog"
        
        # Check for test failures
        $testsFailed = $testOutput | Select-String -Pattern "FAIL|Error:|failing" -Quiet
        if ($testsFailed) {
            Write-Host "[X] Tests failed" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "[OK] Tests passed" -ForegroundColor Green
        Write-BuildLog "All tests passed" $testLog
    } catch {
        Write-Host "[X] Test execution error: $_" -ForegroundColor Red
        Write-BuildLog "Test error: $_" $testLog
        exit 1
    }
    Write-Host ""
} else {
    Write-Host "[3/10] Skipping tests (--SkipTests flag)" -ForegroundColor Gray
    Write-Host ""
}

# Build Core Library (required by all other builds)
Write-Host "[4/10] Building Core library..." -ForegroundColor Yellow
Write-Host "       This provides shared AI/context functionality..." -ForegroundColor Cyan
Write-Host ""

$coreLog = "core-build.log"
Write-BuildLog "Starting core build" $coreLog

# Create temporary Dockerfile
$dockerfileContent = @"
FROM node:20-alpine
WORKDIR /workspace
RUN apk add --no-cache git bash
COPY package*.json ./
COPY core/package*.json ./core/
RUN cd core && npm install --legacy-peer-deps
COPY core/ ./core/
RUN cd core && npm run build
"@
$tempDockerfile = "Dockerfile.core.tmp"
$dockerfileContent | Out-File -FilePath $tempDockerfile -Encoding UTF8

$ErrorActionPreference = 'Continue'
$buildOutput = & $containerTool build -t openpilot-core -f $tempDockerfile . 2>&1
$ErrorActionPreference = 'Stop'
($buildOutput | Out-String) | Out-File -Append -FilePath "$outputDir/logs/$coreLog"
Remove-Item $tempDockerfile -ErrorAction SilentlyContinue

    # Check if build actually failed by looking for error indicators
    $buildFailed = $buildOutput | Select-String -Pattern "^ERROR|failed to solve|error building|ERROR:.*failed" -Quiet
    if ($buildFailed) {
        Write-Host "[X] Core build failed" -ForegroundColor Red
        Write-BuildLog "Core build failed" $coreLog
        exit 1
    }# Verify the image was created
$imageExists = docker images openpilot-core -q
if (-not $imageExists) {
    Write-Host "[X] Core image not created" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Core library built" -ForegroundColor Green
Write-BuildLog "Core build successful" $coreLog
Write-Host ""

# Build VSCode Extension
if (-not $SkipVSCode) {
    Write-Host "[5/10] Building VSCode Extension..." -ForegroundColor Yellow
    Write-Host "       Creating .vsix installer package..." -ForegroundColor Cyan
    Write-Host "       This will take 3-5 minutes..." -ForegroundColor Cyan
    Write-Host ""
    
    $vscodeLog = "vscode-build.log"
    Write-BuildLog "Starting VSCode extension build" $vscodeLog
    
    Write-Host "       Building extension image..." -ForegroundColor Cyan
    
    # Create temporary Dockerfile
    $dockerfileContent = @"
FROM node:20-alpine
WORKDIR /workspace
RUN apk add --no-cache git bash python3 make g++
COPY package*.json ./
COPY core/ ./core/
COPY vscode-extension/package*.json ./vscode-extension/
RUN cd core && npm install --legacy-peer-deps && npm run build
RUN cd vscode-extension && npm install --legacy-peer-deps && npm install --save-dev webpack webpack-cli
COPY vscode-extension/ ./vscode-extension/
RUN cd vscode-extension && npm run compile
# Bundle everything with webpack to include all dependencies in a single file
RUN cd vscode-extension && npx webpack --mode production
# Verify dist was created
RUN ls -la vscode-extension/ && echo "=== DIST CONTENTS ===" && ls -la vscode-extension/dist/ || echo "DIST NOT FOUND"
# Package the bundled extension (node_modules excluded via .vscodeignore)
RUN cd vscode-extension && npx @vscode/vsce package --out /tmp/openpilot.vsix --allow-missing-repository --skip-license || echo "Packaging completed"
CMD ["sh", "-c", "cp /tmp/openpilot.vsix /output/ 2>/dev/null || cp vscode-extension/*.vsix /output/ 2>/dev/null || echo 'No .vsix found'"]
"@
    $tempDockerfile = "Dockerfile.vscode.tmp"
    $dockerfileContent | Out-File -FilePath $tempDockerfile -Encoding UTF8
    
    $ErrorActionPreference = 'Continue'
    $vscodeBuildOutput = & $containerTool build -t openpilot-vscode -f $tempDockerfile . 2>&1
    $ErrorActionPreference = 'Stop'
    ($vscodeBuildOutput | Out-String) | Out-File -Append -FilePath "$outputDir/logs/$vscodeLog"
    Remove-Item $tempDockerfile -ErrorAction SilentlyContinue

    # Check if build failed
    $buildFailed = $vscodeBuildOutput | Select-String -Pattern "^ERROR|failed to solve|error building|ERROR:.*failed" -Quiet
    if ($buildFailed) {
        Write-Host "[X] VSCode build failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "       Extracting .vsix installer..." -ForegroundColor Cyan
    
    # Find and copy the .vsix file from the container
    $vsixFile = & $containerTool run --rm openpilot-vscode sh -c "find /workspace/vscode-extension -name '*.vsix' -print -quit"
    
    if ($vsixFile) {
        $vsixFile = $vsixFile.Trim()
        $containerId = & $containerTool create openpilot-vscode
        & $containerTool cp "${containerId}:$vsixFile" "$outputDir/vscode/" 2>&1 | Out-Null
        & $containerTool rm $containerId | Out-Null
        
        # Rename to standard format
        $vsixFiles = Get-ChildItem "$outputDir/vscode" -Filter "*.vsix" -ErrorAction SilentlyContinue
        if ($vsixFiles) {
            $finalName = "openpilot-vscode_$timestamp.vsix"
            Move-Item $vsixFiles[0].FullName "$outputDir/vscode/$finalName" -Force
            Write-Host "[OK] VSCode extension: $finalName" -ForegroundColor Green
            Write-BuildLog "VSCode extension created: $finalName" $vscodeLog
        } else {
            Write-Host "[!] Could not extract .vsix file" -ForegroundColor Yellow
            Write-BuildLog "Failed to extract .vsix file" $vscodeLog
        }
    } else {
        Write-Host "[!] No .vsix file found in container" -ForegroundColor Yellow
        Write-BuildLog "No .vsix file found after build" $vscodeLog
    }
    Write-Host ""
} else {
    Write-Host "[5/10] Skipping VSCode Extension (--SkipVSCode flag)" -ForegroundColor Gray
    Write-Host ""
}

# Build Web Application
if (-not $SkipWeb) {
    Write-Host "[6/10] Building Web Application..." -ForegroundColor Yellow
    Write-Host "       Creating production web build..." -ForegroundColor Cyan
    Write-Host "       This will take 2-4 minutes..." -ForegroundColor Cyan
    Write-Host ""
    
    $webLog = "web-build.log"
    Write-BuildLog "Starting web build" $webLog
    
    Write-Host "       Building web image..." -ForegroundColor Cyan
    
    # Create temporary Dockerfile
    $dockerfileContent = @"
FROM node:20-alpine
WORKDIR /workspace
RUN apk add --no-cache git bash
COPY package*.json ./
COPY core/ ./core/
COPY web/package*.json ./web/
RUN cd core && npm install --legacy-peer-deps && npm run build
RUN cd web && npm install --legacy-peer-deps
COPY web/ ./web/
RUN cd web && npm run build
RUN cd web/build && tar -czf /tmp/web-build.tar.gz .
CMD ["sh", "-c", "cp /tmp/web-build.tar.gz /output/"]
"@
    $tempDockerfile = "Dockerfile.web.tmp"
    $dockerfileContent | Out-File -FilePath $tempDockerfile -Encoding UTF8
    
    $ErrorActionPreference = 'Continue'
    $webBuildOutput = & $containerTool build -t openpilot-web -f $tempDockerfile . 2>&1
    $ErrorActionPreference = 'Stop'
    ($webBuildOutput | Out-String) | Out-File -Append -FilePath "$outputDir/logs/$webLog"
    Remove-Item $tempDockerfile -ErrorAction SilentlyContinue

    # Check if build failed
    $buildFailed = $webBuildOutput | Select-String -Pattern "^ERROR|failed to solve|error building|ERROR:.*failed" -Quiet
    if ($buildFailed) {
        Write-Host "[X] Web build failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "       Extracting web artifacts..." -ForegroundColor Cyan
    $containerId = & $containerTool create openpilot-web
    & $containerTool cp "${containerId}:/tmp/web-build.tar.gz" "$outputDir/web/openpilot-web_$timestamp.tar.gz"
    & $containerTool rm $containerId | Out-Null
    
    Write-Host "[OK] Web application: openpilot-web_$timestamp.tar.gz" -ForegroundColor Green
    Write-BuildLog "Web build successful" $webLog
    Write-Host ""
} else {
    Write-Host "[6/10] Skipping Web Application (--SkipWeb flag)" -ForegroundColor Gray
    Write-Host ""
}

# Build Desktop Application
if (-not $SkipDesktop) {
    Write-Host "[7/10] Building Desktop Application..." -ForegroundColor Yellow
    Write-Host "       Creating Electron desktop app..." -ForegroundColor Cyan
    Write-Host "       This will take 3-5 minutes..." -ForegroundColor Cyan
    Write-Host ""
    
    $desktopLog = "desktop-build.log"
    Write-BuildLog "Starting desktop build" $desktopLog
    
    Write-Host "       Building desktop image..." -ForegroundColor Cyan
    
    # Create temporary Dockerfile
    $dockerfileContent = @"
FROM node:20-alpine
WORKDIR /workspace
RUN apk add --no-cache git bash python3 make g++
COPY package*.json ./
COPY core/ ./core/
COPY desktop/package*.json ./desktop/
RUN cd core && npm install --legacy-peer-deps && npm run build
RUN cd desktop && npm install --legacy-peer-deps
COPY desktop/ ./desktop/
RUN cd desktop && npm run build
RUN cd desktop/build && tar -czf /tmp/desktop-build.tar.gz .
CMD ["sh", "-c", "cp /tmp/desktop-build.tar.gz /output/"]
"@
    $tempDockerfile = "Dockerfile.desktop.tmp"
    $dockerfileContent | Out-File -FilePath $tempDockerfile -Encoding UTF8
    
    $ErrorActionPreference = 'Continue'
    $desktopBuildOutput = & $containerTool build -t openpilot-desktop -f $tempDockerfile . 2>&1
    $ErrorActionPreference = 'Stop'
    ($desktopBuildOutput | Out-String) | Out-File -Append -FilePath "$outputDir/logs/$desktopLog"
    Remove-Item $tempDockerfile -ErrorAction SilentlyContinue

    # Check if build failed
    $buildFailed = $desktopBuildOutput | Select-String -Pattern "^ERROR|failed to solve|error building|ERROR:.*failed" -Quiet
    if ($buildFailed) {
        Write-Host "[X] Desktop build failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "       Extracting desktop artifacts..." -ForegroundColor Cyan
    $containerId = & $containerTool create openpilot-desktop
    & $containerTool cp "${containerId}:/tmp/desktop-build.tar.gz" "$outputDir/desktop/openpilot-desktop_$timestamp.tar.gz"
    & $containerTool rm $containerId | Out-Null
    
    Write-Host "[OK] Desktop application: openpilot-desktop_$timestamp.tar.gz" -ForegroundColor Green
    Write-BuildLog "Desktop build successful" $desktopLog
    Write-Host ""
} else {
    Write-Host "[7/10] Skipping Desktop Application (--SkipDesktop flag)" -ForegroundColor Gray
    Write-Host ""
}

# Build Android APK
if (-not $SkipAndroid) {
    Write-Host "[8/10] Building Android Application..." -ForegroundColor Yellow
    Write-Host "       Creating Android APK..." -ForegroundColor Cyan
    Write-Host "       This will take 5-10 minutes (downloading Android SDK)..." -ForegroundColor Cyan
    Write-Host ""
    
    $androidLog = "android-build.log"
    Write-BuildLog "Starting Android build" $androidLog
    
    # Check if mobile directory exists
    if (-not (Test-Path "mobile")) {
        Write-Host "[!] Mobile directory not found - creating basic structure..." -ForegroundColor Yellow
        Write-Host "    (Android support requires Capacitor/React Native setup)" -ForegroundColor Gray
        Write-BuildLog "Mobile directory not found, skipping Android build" $androidLog
    } else {
        try {
            Write-Host "       Building Android image with SDK..." -ForegroundColor Cyan
            
            # Create temporary Dockerfile
            $dockerfileContent = @"
FROM node:20
WORKDIR /workspace

# Install Android SDK dependencies
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and install Android SDK
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=`$PATH:`$ANDROID_HOME/cmdline-tools/latest/bin:`$ANDROID_HOME/platform-tools
RUN mkdir -p `$ANDROID_HOME/cmdline-tools && \
    cd `$ANDROID_HOME/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip -q commandlinetools-linux-9477386_latest.zip && \
    mv cmdline-tools latest && \
    rm commandlinetools-linux-9477386_latest.zip

# Accept licenses and install required packages
RUN yes | sdkmanager --licenses || true
RUN sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Copy and build
COPY package*.json ./
COPY core/ ./core/
COPY mobile/ ./mobile/
RUN cd core && npm install --legacy-peer-deps && npm run build
RUN cd mobile && npm install --legacy-peer-deps
RUN cd mobile && npm run build:android || echo "Android build attempted"

# Package APK
CMD ["sh", "-c", "find /workspace/mobile -name '*.apk' -exec cp {} /output/ \\; || echo 'No APK found'"]
"@
            $tempDockerfile = "Dockerfile.android.tmp"
            $dockerfileContent | Out-File -FilePath $tempDockerfile -Encoding UTF8
            
            $androidBuildOutput = & $containerTool build -t openpilot-android -f $tempDockerfile . 2>&1
            ($androidBuildOutput | Out-String) | Out-File -Append -FilePath "$outputDir/logs/$androidLog"
            Remove-Item $tempDockerfile -ErrorAction SilentlyContinue

            # Check if build failed
            $buildFailed = $androidBuildOutput | Select-String -Pattern "^ERROR|failed to solve|error building|ERROR:.*failed" -Quiet
            if ($buildFailed) {
                Write-Host "[!] Android build had issues, checking for APK..." -ForegroundColor Yellow
            }
            
            Write-Host "       Extracting APK..." -ForegroundColor Cyan
            $containerId = & $containerTool create openpilot-android
            
            # Try to find and copy any APK files
            $apkFound = $false
            try {
                & $containerTool cp "${containerId}:/workspace/mobile/android/app/build/outputs/apk/release/app-release.apk" "$outputDir/android/openpilot-android_$timestamp.apk" 2>$null
                if ($?) { $apkFound = $true }
            } catch {}
            
            & $containerTool rm $containerId | Out-Null
            
            if ($apkFound -or (Test-Path "$outputDir/android/*.apk")) {
                Write-Host "[OK] Android APK: openpilot-android_$timestamp.apk" -ForegroundColor Green
                Write-BuildLog "Android APK created successfully" $androidLog
            } else {
                Write-Host "[!] Android APK not found (mobile app may need Capacitor setup)" -ForegroundColor Yellow
                Write-BuildLog "Android APK not extracted - may need Capacitor configuration" $androidLog
            }
        } catch {
            Write-Host "[X] Android build error: $_" -ForegroundColor Red
            Write-BuildLog "Android build error: $_" $androidLog
        }
    }
    Write-Host ""
} else {
    Write-Host "[8/10] Skipping Android Application (--SkipAndroid flag)" -ForegroundColor Gray
    Write-Host ""
}

# Create README for artifacts
Write-Host "[9/10] Creating documentation..." -ForegroundColor Yellow

$readmeContent = @"
# OpenPilot Build Artifacts
Build Date: $(Get-Date -Format "yyyy-MM-DD HH:mm:ss")
Build ID: $timestamp

## Artifacts Included

$(if (Test-Path "$outputDir/vscode/*.vsix") { "### VSCode Extension
- Installation: Open VSCode, go to Extensions, click '...' menu, select 'Install from VSIX'
- File: $(Get-ChildItem "$outputDir/vscode" -Filter "*.vsix" | Select-Object -First 1 -ExpandProperty Name)
" } else { "" })

$(if (Test-Path "$outputDir/web/*.tar.gz") { "### Web Application
- Extract: tar -xzf openpilot-web_$timestamp.tar.gz
- Serve: Use any HTTP server (e.g., 'python -m http.server 8080')
- File: openpilot-web_$timestamp.tar.gz
" } else { "" })

$(if (Test-Path "$outputDir/desktop/*.tar.gz") { "### Desktop Application
- Extract: tar -xzf openpilot-desktop_$timestamp.tar.gz
- Run: Requires Electron runtime
- File: openpilot-desktop_$timestamp.tar.gz
" } else { "" })

$(if (Test-Path "$outputDir/android/*.apk") { "### Android Application
- Installation: Enable 'Install from Unknown Sources' in Android settings
- Transfer APK to device and tap to install
- File: openpilot-android_$timestamp.apk
" } else { "" })

## Build Logs
Check the logs directory for detailed build information:
- test-results.log
- core-build.log
- vscode-build.log
- web-build.log
- desktop-build.log
- android-build.log

## Next Steps

1. Test each artifact individually
2. Report any issues to the development team
3. For production deployment, use official release builds

## Build Command Used
PowerShell: .\local-container-build.ps1$(if ($SkipTests) { " -SkipTests" })$(if ($SkipAndroid) { " -SkipAndroid" })$(if ($SkipDesktop) { " -SkipDesktop" })$(if ($SkipWeb) { " -SkipWeb" })$(if ($SkipVSCode) { " -SkipVSCode" })

Generated by OpenPilot Local Container Build Script
"@

$readmeContent | Out-File -FilePath "$outputDir/README.md" -Encoding UTF8
Write-Host "[OK] Documentation created" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "[10/10] Build Summary" -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "     BUILD COMPLETED!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Build ID: $timestamp" -ForegroundColor White
Write-Host "Output Directory: $(Resolve-Path $outputDir)" -ForegroundColor White
Write-Host ""
Write-Host "Artifacts Generated:" -ForegroundColor Cyan

$totalSize = 0
Get-ChildItem -Path $outputDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Extension -in '.vsix', '.apk', '.tar.gz', '.zip'
} | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 2)
    $totalSize += $size
    $relativePath = $_.FullName.Replace("$(Resolve-Path $outputDir)\", "")
    Write-Host "  [*] $relativePath ($size MB)" -ForegroundColor White
}

Write-Host ""
Write-Host "Total Size: $totalSize MB" -ForegroundColor Yellow
Write-Host ""

# Testing instructions
Write-Host "Testing Instructions:" -ForegroundColor Cyan
Write-Host ""

if (Test-Path "$outputDir/vscode/*.vsix") {
    Write-Host "  VSCode Extension:" -ForegroundColor Yellow
    Write-Host "    1. Open VSCode" -ForegroundColor White
    Write-Host "    2. Go to Extensions (Ctrl+Shift+X)" -ForegroundColor White
    Write-Host "    3. Click '...' menu → Install from VSIX" -ForegroundColor White
    Write-Host "    4. Select the .vsix file" -ForegroundColor White
    Write-Host ""
}

if (Test-Path "$outputDir/web/*.tar.gz") {
    Write-Host "  Web Application:" -ForegroundColor Yellow
    Write-Host "    1. Extract: tar -xzf openpilot-web_$timestamp.tar.gz" -ForegroundColor White
    Write-Host "    2. Serve: cd extracted_folder && python -m http.server 8080" -ForegroundColor White
    Write-Host "    3. Open: http://localhost:8080" -ForegroundColor White
    Write-Host ""
}

if (Test-Path "$outputDir/desktop/*.tar.gz") {
    Write-Host "  Desktop Application:" -ForegroundColor Yellow
    Write-Host "    1. Extract: tar -xzf openpilot-desktop_$timestamp.tar.gz" -ForegroundColor White
    Write-Host "    2. Run with Electron (requires Electron installed)" -ForegroundColor White
    Write-Host ""
}

if (Test-Path "$outputDir/android/*.apk") {
    Write-Host "  Android Application:" -ForegroundColor Yellow
    Write-Host "    1. Transfer APK to Android device" -ForegroundColor White
    Write-Host "    2. Enable 'Unknown Sources' in Settings" -ForegroundColor White
    Write-Host "    3. Tap APK file to install" -ForegroundColor White
    Write-Host ""
}

Write-Host "Build logs available in: $outputDir\logs" -ForegroundColor Gray
Write-Host ""
Write-Host "Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\local-container-build.ps1                  # Build everything" -ForegroundColor White
Write-Host "  .\local-container-build.ps1 -SkipTests       # Skip tests" -ForegroundColor White
Write-Host "  .\local-container-build.ps1 -SkipAndroid     # Skip Android" -ForegroundColor White
Write-Host "  .\local-container-build.ps1 -UsePodman       # Use Podman instead of Docker" -ForegroundColor White
Write-Host "  .\local-container-build.ps1 -Clean           # Clean and rebuild" -ForegroundColor White
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
