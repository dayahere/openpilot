#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Local Build and Test Script for OpenPilot
    
.DESCRIPTION
    Builds and tests OpenPilot locally, creating artifacts similar to GitHub Actions
    
.PARAMETER BuildType
    Type of build: 'all', 'core', 'tests', 'docker', 'docs'
    
.PARAMETER SkipTests
    Skip running tests
    
.PARAMETER Coverage
    Generate coverage reports
    
.PARAMETER Clean
    Clean build artifacts before building
    
.EXAMPLE
    .\build-local.ps1 -BuildType all -Coverage
    
.EXAMPLE
    .\build-local.ps1 -BuildType docker -SkipTests
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'core', 'tests', 'docker', 'docs')]
    [string]$BuildType = 'all',
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory=$false)]
    [switch]$Coverage,
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot
$buildDir = Join-Path $workspaceRoot "build-output"
$artifactsDir = Join-Path $workspaceRoot "artifacts"

# Color output functions
function Write-Success { param($message) Write-Host "[SUCCESS] $message" -ForegroundColor Green }
function Write-Info { param($message) Write-Host "[INFO] $message" -ForegroundColor Cyan }
function Write-Warn { param($message) Write-Host "[WARNING] $message" -ForegroundColor Yellow }
function Write-Fail { param($message) Write-Host "[ERROR] $message" -ForegroundColor Red }
function Write-Section { param($message) Write-Host "`n========================================" -ForegroundColor Magenta; Write-Host "  $message" -ForegroundColor Magenta; Write-Host "========================================`n" -ForegroundColor Magenta }


# Clean function
function Clean-Artifacts {
    Write-Section "Cleaning Build Artifacts"
    
    if (Test-Path $buildDir) {
        Remove-Item $buildDir -Recurse -Force
        Write-Success "Removed $buildDir"
    }
    
    if (Test-Path $artifactsDir) {
        Remove-Item $artifactsDir -Recurse -Force
        Write-Success "Removed $artifactsDir"
    }
    
    # Clean dist folders
    @("core/dist", "tests/coverage", "tests/node_modules", "core/node_modules") | ForEach-Object {
        $path = Join-Path $workspaceRoot $_
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force
            Write-Success "Removed $_"
        }
    }
}

# Build core library
function Build-Core {
    Write-Section "Building Core Library"
    
    Push-Location (Join-Path $workspaceRoot "core")
    
    try {
        Write-Info "Installing dependencies..."
        npm install
        
        Write-Info "Compiling TypeScript..."
        npm run build
        
        Write-Success "Core library built successfully"
        
        # Copy to build output
        $coreOutput = Join-Path $buildDir "core"
        New-Item -ItemType Directory -Force -Path $coreOutput | Out-Null
        Copy-Item "dist" $coreOutput -Recurse -Force
        Copy-Item "package.json" $coreOutput -Force
        
        Write-Success "Core artifacts saved to $coreOutput"
    }
    finally {
        Pop-Location
    }
}

# Run tests
function Run-Tests {
    Write-Section "Running Tests"
    
    Push-Location (Join-Path $workspaceRoot "tests")
    
    try {
        Write-Info "Installing test dependencies..."
        npm install
        
        Write-Info "Running TypeScript type check..."
        npx tsc --noEmit
        
        if ($Coverage) {
            Write-Info "Running tests with coverage..."
            npm test -- --coverage --ci
            
            # Copy coverage to artifacts
            $coverageOutput = Join-Path $artifactsDir "coverage"
            New-Item -ItemType Directory -Force -Path $coverageOutput | Out-Null
            Copy-Item "coverage" $coverageOutput -Recurse -Force
            
            Write-Success "Coverage report saved to $coverageOutput"
            
            # Display coverage summary
            if (Test-Path "coverage/coverage-summary.json") {
                Write-Info "Coverage Summary:"
                Get-Content "coverage/coverage-summary.json" | ConvertFrom-Json | 
                    Select-Object -ExpandProperty total | Format-Table
            }
        }
        else {
            Write-Info "Running tests..."
            npm test
        }
        
        Write-Success "All tests passed"
    }
    catch {
        Write-Fail "Tests failed: $_"
        
        # Run auto-fix if tests fail
        Write-Info "Attempting auto-fix..."
        python autofix.py
        
        throw
    }
    finally {
        Pop-Location
    }
}

# Build with Docker
function Build-Docker {
    Write-Section "Building with Docker"
    
    Write-Info "Building Docker test image..."
    docker-compose -f docker-compose.test.yml build test-runner
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Docker image built successfully"
    }
    else {
        Write-Fail "Docker build failed"
        throw "Docker build failed"
    }
    
    if (-not $SkipTests) {
        Write-Info "Running tests in Docker..."
        docker-compose -f docker-compose.test.yml run --rm test-runner
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker tests passed"
        }
        else {
            Write-Fail "Docker tests failed"
            
            # Try auto-fix in Docker
            Write-Info "Running auto-fix in Docker..."
            docker-compose -f docker-compose.test.yml run --rm test-autofix
        }
    }
    
    # Extract coverage from Docker if requested
    if ($Coverage) {
        Write-Info "Running coverage in Docker..."
        docker-compose -f docker-compose.test.yml run --rm test-coverage
        
        Write-Info "Extracting coverage from Docker..."
        docker create --name coverage-temp openpilot-test-runner:latest
        
        $dockerCoverageOutput = Join-Path $artifactsDir "docker-coverage"
        New-Item -ItemType Directory -Force -Path $dockerCoverageOutput | Out-Null
        
        docker cp coverage-temp:/app/tests/coverage/. $dockerCoverageOutput
        docker rm coverage-temp
        
        Write-Success "Docker coverage saved to $dockerCoverageOutput"
    }
}

# Build documentation
function Build-Docs {
    Write-Section "Building Documentation"
    
    $docsOutput = Join-Path $artifactsDir "docs"
    New-Item -ItemType Directory -Force -Path $docsOutput | Out-Null
    
    # Copy documentation files
    if (Test-Path "docs") {
        Copy-Item "docs/*" $docsOutput -Recurse -Force
    }
    
    # Copy README and guides
    Copy-Item "README.md" (Join-Path $docsOutput "README.md") -Force
    Copy-Item "tests/TESTING_SYSTEM_GUIDE.md" (Join-Path $docsOutput "TESTING.md") -Force
    
    # Generate TypeDoc (if TypeDoc is available)
    Push-Location (Join-Path $workspaceRoot "core")
    try {
        Write-Info "Generating API documentation..."
        npx typedoc --out (Join-Path $docsOutput "api") src/index.ts
        Write-Success "API documentation generated"
    }
    catch {
        Write-Warn "TypeDoc generation failed (may not be installed)"
    }
    finally {
        Pop-Location
    }
    
    # Copy coverage to docs if it exists
    if (Test-Path (Join-Path $artifactsDir "coverage")) {
        Copy-Item (Join-Path $artifactsDir "coverage") (Join-Path $docsOutput "coverage") -Recurse -Force
    }
    
    Write-Success "Documentation saved to $docsOutput"
    
    # Create index.html
    $indexHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>OpenPilot Documentation</title>
    <style>
        body `{ font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; `}
        h1 `{ color: #333; `}
        .link-box `{ background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; `}
        a `{ color: #0066cc; text-decoration: none; `}
        a:hover `{ text-decoration: underline; `}
    </style>
</head>
<body>
    <h1>OpenPilot Documentation</h1>
    <div class="link-box">
        <h2><a href="README.html">📘 Main Documentation</a></h2>
        <p>Project overview and getting started guide</p>
    </div>
    <div class="link-box">
        <h2><a href="TESTING.html">🧪 Testing System Guide</a></h2>
        <p>Comprehensive testing documentation</p>
    </div>
    <div class="link-box">
        <h2><a href="api/index.html">📚 API Documentation</a></h2>
        <p>TypeDoc generated API reference</p>
    </div>
    <div class="link-box">
        <h2><a href="coverage/lcov-report/index.html">📊 Test Coverage Report</a></h2>
        <p>Code coverage analysis</p>
    </div>
</body>
</html>
"@
    
    Set-Content (Join-Path $docsOutput "index.html") $indexHtml
}

# Create release archive
function Create-ReleaseArchive {
    Write-Section "Creating Release Archive"
    
    $version = "v1.0.0" # TODO: Read from package.json
    $archiveName = "openpilot-$version-$(Get-Date -Format 'yyyyMMdd')"
    $archivePath = Join-Path $artifactsDir "$archiveName.zip"
    
    # Compress artifacts
    Compress-Archive -Path "$buildDir/*" -DestinationPath $archivePath -Force
    
    Write-Success "Release archive created: $archivePath"
    
    # Show archive contents
    Write-Info "Archive contents:"
    Get-ChildItem $buildDir -Recurse | Select-Object -ExpandProperty FullName | ForEach-Object {
        Write-Host "  $_"
    }
}

# Main execution
try {
    Write-Host @"
╔════════════════════════════════════════════════╗
║                                                ║
║        OpenPilot Local Build System            ║
║                                                ║
╚════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    Write-Info "Build Type: $BuildType"
    Write-Info "Skip Tests: $SkipTests"
    Write-Info "Coverage: $Coverage"
    Write-Info "Clean: $Clean"
    Write-Info "Workspace: $workspaceRoot"
    
    # Create directories
    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
    New-Item -ItemType Directory -Force -Path $artifactsDir | Out-Null
    
    if ($Clean) {
        Clean-Artifacts
    }
    
    $startTime = Get-Date
    
    # Execute build steps
    switch ($BuildType) {
        'all' {
            Build-Core
            if (-not $SkipTests) { Run-Tests }
            Build-Docker
            Build-Docs
            Create-ReleaseArchive
        }
        'core' {
            Build-Core
        }
        'tests' {
            Build-Core
            Run-Tests
        }
        'docker' {
            Build-Docker
        }
        'docs' {
            Build-Docs
        }
    }
    
    $duration = (Get-Date) - $startTime
    
    Write-Section "Build Summary"
    Write-Success "Build completed successfully!"
    Write-Info "Duration: $($duration.ToString('mm\:ss'))"
    Write-Info "Build output: $buildDir"
    Write-Info "Artifacts: $artifactsDir"
    
    # Open artifacts directory
    if (Test-Path $artifactsDir) {
        Write-Info "Opening artifacts directory..."
        Start-Process explorer.exe $artifactsDir
    }
}
catch {
    Write-Host "❌ Build failed: $_" -ForegroundColor Red
    Write-Host "❌ $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
