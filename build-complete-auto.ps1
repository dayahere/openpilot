#!/usr/bin/env pwsh
#Requires -Version 5.1

<#
.SYNOPSIS
    Complete automated build with auto-fix, retry logic, and comprehensive artifact generation
.DESCRIPTION
    Builds all platforms (Core, VSCode, Web, Desktop, Android) with automatic issue detection and fixing
.PARAMETER MaxRetries
    Maximum retry attempts per platform (default: 3)
.PARAMETER SkipAndroid
    Skip Android APK build
.PARAMETER OutputDir
    Custom output directory for installers
#>

param(
    [int]$MaxRetries = 3,
    [switch]$SkipAndroid,
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$buildDir = if ($OutputDir) { $OutputDir } else { "installers/build-$timestamp" }
$logFile = "build-complete-$timestamp.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $colors = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "ERROR" = "Red"
        "WARNING" = "Yellow"
        "FIX" = "Magenta"
    }
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logMsg = "[$timestamp] [$Level] $Message"
    Write-Host $logMsg -ForegroundColor $colors[$Level]
    Add-Content -Path $logFile -Value $logMsg
}

function Test-BuildSuccess {
    param([string]$Platform, [string]$ArtifactPath)
    
    if (Test-Path $ArtifactPath) {
        $size = (Get-Item $ArtifactPath).Length
        if ($size -gt 1KB) {
            Write-Log "$Platform artifact created successfully: $ArtifactPath" "SUCCESS"
            return $true
        }
    }
    return $false
}

# Initialize
Write-Log "========================================" "INFO"
Write-Log "AUTOMATED BUILD SYSTEM v2.0" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Build Directory: $buildDir" "INFO"
Write-Log "Log File: $logFile" "INFO"
Write-Log "Max Retries: $MaxRetries" "INFO"

# Create output directories
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
New-Item -ItemType Directory -Force -Path "$buildDir/logs" | Out-Null

# Build tracking
$script:BuildResults = @{
    Core = @{ Status = "PENDING"; Attempts = 0; ArtifactPath = "" }
    VSCode = @{ Status = "PENDING"; Attempts = 0; ArtifactPath = "" }
    Web = @{ Status = "PENDING"; Attempts = 0; ArtifactPath = "" }
    Desktop = @{ Status = "PENDING"; Attempts = 0; ArtifactPath = "" }
    Android = @{ Status = "PENDING"; Attempts = 0; ArtifactPath = "" }
}

#region Auto-Fix Functions

function Fix-VSCodeIssues {
    Write-Log "Applying VSCode auto-fixes..." "FIX"
    
    # Ensure .vscodeignore exists
    $vscodeignore = @"
.vscode/**
.vscode-test/**
src/**
.gitignore
vsc-extension-quickstart.md
**/tsconfig.json
**/.eslintrc.json
**/*.map
**/*.ts
**/__tests__/**
**/*.test.js
../**/node_modules/**
../core/**
../web/**
../desktop/**
../backend/**
../mobile/**
"@
    Set-Content -Path "vscode-extension\.vscodeignore" -Value $vscodeignore -Force
    Write-Log "Created .vscodeignore" "SUCCESS"
}

function Fix-WebIssues {
    Write-Log "Applying Web auto-fixes..." "FIX"
    
    # Ensure all required CSS files exist
    if (-not (Test-Path "web\src\index.css")) {
        $indexCss = @"
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
"@
        Set-Content -Path "web\src\index.css" -Value $indexCss -Force
        Write-Log "Created index.css" "SUCCESS"
    }
}

function Fix-DesktopIssues {
    Write-Log "Applying Desktop auto-fixes..." "FIX"
    
    # Ensure Desktop has required files (similar to Web)
    if (-not (Test-Path "desktop\src\index.css")) {
        Copy-Item "web\src\index.css" "desktop\src\index.css" -Force -ErrorAction SilentlyContinue
        Write-Log "Created Desktop index.css" "SUCCESS"
    }
}

#endregion

#region Build Functions

function Build-Core {
    Write-Log "Building Core package..." "INFO"
    $script:BuildResults.Core.Attempts++
    
    $output = docker run --rm -v "${PWD}:/workspace" -w /workspace/core node:20 sh -c "npm install --legacy-peer-deps && npm run build" 2>&1
    Add-Content -Path "$buildDir/logs/core.log" -Value $output
    
    if (Test-Path "core\dist\index.js") {
        $script:BuildResults.Core.Status = "SUCCESS"
        $script:BuildResults.Core.ArtifactPath = "core\dist\index.js"
        Write-Log "Core build completed" "SUCCESS"
        return $true
    }
    
    Write-Log "Core build failed" "ERROR"
    return $false
}

function Build-VSCode {
    Write-Log "Building VSCode Extension..." "INFO"
    $script:BuildResults.VSCode.Attempts++
    
    # Apply fixes
    Fix-VSCodeIssues
    
    # Build with workspace context (Core dependency)
    Write-Log "Compiling TypeScript..." "INFO"
    $compileOutput = docker run --rm -v "${PWD}:/workspace" -w /workspace node:20 sh -c "cd core && npm install --legacy-peer-deps && npm run build && cd ../vscode-extension && npm install --legacy-peer-deps && npm run compile" 2>&1
    Add-Content -Path "$buildDir/logs/vscode-compile.log" -Value $compileOutput
    
    if (-not (Test-Path "vscode-extension\out\extension.js")) {
        Write-Log "VSCode compilation failed" "ERROR"
        return $false
    }
    
    Write-Log "Packaging extension..." "INFO"
    $packageOutput = docker run --rm -v "${PWD}:/workspace" -w /workspace/vscode-extension node:20 sh -c "npm install -g @vscode/vsce && vsce package --no-dependencies --allow-missing-repository --out ." 2>&1
    Add-Content -Path "$buildDir/logs/vscode-package.log" -Value $packageOutput
    
    $vsix = Get-ChildItem "vscode-extension\*.vsix" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($vsix) {
        Copy-Item $vsix.FullName "$buildDir\openpilot-vscode-1.0.0.vsix" -Force
        $script:BuildResults.VSCode.Status = "SUCCESS"
        $script:BuildResults.VSCode.ArtifactPath = "$buildDir\openpilot-vscode-1.0.0.vsix"
        Write-Log "VSCode extension packaged: $($vsix.Name)" "SUCCESS"
        return $true
    }
    
    Write-Log "VSCode packaging failed" "ERROR"
    return $false
}

function Build-Web {
    Write-Log "Building Web Application..." "INFO"
    $script:BuildResults.Web.Attempts++
    
    # Apply fixes
    Fix-WebIssues
    
    $output = docker run --rm -v "${PWD}:/workspace" -w /workspace/web node:20 sh -c "npm install --legacy-peer-deps && npm run build" 2>&1
    Add-Content -Path "$buildDir/logs/web.log" -Value $output
    
    if (Test-Path "web\build\index.html") {
        # Create zip
        Write-Log "Creating Web zip archive..." "INFO"
        Compress-Archive -Path "web\build\*" -DestinationPath "$buildDir\openpilot-web.zip" -Force
        
        $script:BuildResults.Web.Status = "SUCCESS"
        $script:BuildResults.Web.ArtifactPath = "$buildDir\openpilot-web.zip"
        Write-Log "Web application built and zipped" "SUCCESS"
        return $true
    }
    
    Write-Log "Web build failed" "ERROR"
    return $false
}

function Build-Desktop {
    Write-Log "Building Desktop Application..." "INFO"
    $script:BuildResults.Desktop.Attempts++
    
    # Apply fixes
    Fix-DesktopIssues
    
    $output = docker run --rm -v "${PWD}:/workspace" -w /workspace/desktop node:20 sh -c "npm install --legacy-peer-deps && npm run build" 2>&1
    Add-Content -Path "$buildDir/logs/desktop.log" -Value $output
    
    if (Test-Path "desktop\build\index.html") {
        # Create zip
        Write-Log "Creating Desktop zip archive..." "INFO"
        Compress-Archive -Path "desktop\build\*" -DestinationPath "$buildDir\openpilot-desktop.zip" -Force
        
        $script:BuildResults.Desktop.Status = "SUCCESS"
        $script:BuildResults.Desktop.ArtifactPath = "$buildDir\openpilot-desktop.zip"
        Write-Log "Desktop application built and zipped" "SUCCESS"
        return $true
    }
    
    Write-Log "Desktop build failed" "ERROR"
    return $false
}

function Build-Android {
    if ($SkipAndroid) {
        Write-Log "Android build skipped (--SkipAndroid flag)" "WARNING"
        $script:BuildResults.Android.Status = "SKIPPED"
        return $true
    }
    
    Write-Log "Building Android APK..." "INFO"
    $script:BuildResults.Android.Attempts++
    
    # Check if mobile directory exists and has gradle
    if (-not (Test-Path "mobile\android\build.gradle")) {
        Write-Log "Android project not found or incomplete" "WARNING"
        $script:BuildResults.Android.Status = "SKIPPED"
        return $true
    }
    
    $output = docker run --rm -v "${PWD}/mobile:/app" -w /app/android gradle:8.5-jdk17 sh -c "chmod +x gradlew && ./gradlew assembleRelease" 2>&1
    Add-Content -Path "$buildDir/logs/android.log" -Value $output
    
    $apk = Get-ChildItem "mobile\android\app\build\outputs\apk\release\*.apk" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($apk) {
        Copy-Item $apk.FullName "$buildDir\openpilot-android.apk" -Force
        $script:BuildResults.Android.Status = "SUCCESS"
        $script:BuildResults.Android.ArtifactPath = "$buildDir\openpilot-android.apk"
        Write-Log "Android APK built: $($apk.Name)" "SUCCESS"
        return $true
    }
    
    Write-Log "Android build failed" "ERROR"
    return $false
}

#endregion

#region Build Execution with Retry

function Invoke-BuildWithRetry {
    param(
        [string]$Platform,
        [scriptblock]$BuildFunction
    )
    
    Write-Log "========================================" "INFO"
    Write-Log "BUILDING: $Platform" "INFO"
    Write-Log "========================================" "INFO"
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        Write-Log "Attempt $i of $MaxRetries for $Platform..." "INFO"
        
        $success = & $BuildFunction
        
        if ($success) {
            Write-Log "$Platform build successful on attempt $i" "SUCCESS"
            return $true
        }
        
        if ($i -lt $MaxRetries) {
            Write-Log "Retrying $Platform build..." "WARNING"
            Start-Sleep -Seconds 2
        }
    }
    
    Write-Log "$Platform build failed after $MaxRetries attempts" "ERROR"
    $script:BuildResults.$Platform.Status = "FAILED"
    return $false
}

#endregion

#region Main Execution

Write-Log "Starting build process..." "INFO"
$buildStartTime = Get-Date

# Build sequence
$platforms = @(
    @{ Name = "Core"; Function = ${function:Build-Core} },
    @{ Name = "VSCode"; Function = ${function:Build-VSCode} },
    @{ Name = "Web"; Function = ${function:Build-Web} },
    @{ Name = "Desktop"; Function = ${function:Build-Desktop} },
    @{ Name = "Android"; Function = ${function:Build-Android} }
)

foreach ($platform in $platforms) {
    Invoke-BuildWithRetry -Platform $platform.Name -BuildFunction $platform.Function
}

$buildEndTime = Get-Date
$buildDuration = $buildEndTime - $buildStartTime

#endregion

#region Final Report

Write-Log "" "INFO"
Write-Log "========================================" "INFO"
Write-Log "BUILD SUMMARY" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Total Duration: $($buildDuration.ToString('hh\:mm\:ss'))" "INFO"
Write-Log "" "INFO"

$successCount = 0
$failCount = 0
$skipCount = 0

foreach ($platform in $script:BuildResults.Keys) {
    $result = $script:BuildResults[$platform]
    $status = $result.Status
    $attempts = $result.Attempts
    
    $color = switch ($status) {
        "SUCCESS" { "SUCCESS"; $successCount++; break }
        "FAILED" { "ERROR"; $failCount++; break }
        "SKIPPED" { "WARNING"; $skipCount++; break }
        default { "INFO" }
    }
    
    Write-Log "$platform : $status (Attempts: $attempts)" $color
    
    if ($result.ArtifactPath -and (Test-Path $result.ArtifactPath)) {
        $size = [math]::Round((Get-Item $result.ArtifactPath).Length / 1MB, 2)
        Write-Log "  Artifact: $($result.ArtifactPath) ($size MB)" "INFO"
    }
}

Write-Log "" "INFO"
Write-Log "Results: $successCount Success, $failCount Failed, $skipCount Skipped" "INFO"
Write-Log "Output Directory: $buildDir" "INFO"
Write-Log "Log File: $logFile" "INFO"

# List all installers
Write-Log "" "INFO"
Write-Log "Generated Installers:" "INFO"
$installers = Get-ChildItem $buildDir -File -Include "*.vsix","*.zip","*.apk" -ErrorAction SilentlyContinue
if ($installers) {
    foreach ($installer in $installers) {
        $size = [math]::Round($installer.Length / 1MB, 2)
        Write-Log "  $($installer.Name) ($size MB)" "SUCCESS"
    }
} else {
    Write-Log "  No installers generated" "WARNING"
}

Write-Log "========================================" "INFO"

#endregion

# Exit code
if ($failCount -eq 0) {
    Write-Log "BUILD COMPLETED SUCCESSFULLY!" "SUCCESS"
    exit 0
} else {
    Write-Log "BUILD COMPLETED WITH ERRORS" "ERROR"
    exit 1
}
