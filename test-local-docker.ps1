# OpenPilot - Complete Local Docker Testing
# This script runs all tests that GitHub Actions runs, locally in Docker

# Colors for output
$ErrorActionPreference = "Stop"
$SuccessColor = "Green"
$ErrorColor = "Red"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "========================================" $InfoColor
    Write-ColorOutput "  $Title" $InfoColor
    Write-ColorOutput "========================================" $InfoColor
    Write-Host ""
}

function Test-DockerAvailable {
    Write-ColorOutput "[CHECK] Verifying Docker is available..." $InfoColor
    try {
        $dockerVersion = docker --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Docker command failed"
        }
        Write-ColorOutput "[OK] Docker is installed: $dockerVersion" $SuccessColor
        
        # Check if Docker daemon is running
        docker ps 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker daemon is not running"
        }
        Write-ColorOutput "[OK] Docker daemon is running" $SuccessColor
        return $true
    }
    catch {
        Write-ColorOutput "[ERROR] Docker is not available: $_" $ErrorColor
        Write-ColorOutput "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" $WarningColor
        return $false
    }
}

function Build-TestImage {
    Write-Section "Building Test Docker Image"
    
    Write-ColorOutput "[BUILD] Building openpilot-test-runner image..." $InfoColor
    docker build -f Dockerfile.test -t openpilot-test-runner:latest . 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "[OK] Test image built successfully" $SuccessColor
        return $true
    }
    else {
        Write-ColorOutput "[ERROR] Failed to build test image" $ErrorColor
        return $false
    }
}

function Test-CoreBuild {
    Write-Section "Test: Core TypeScript Build"
    
    Write-ColorOutput "[TEST] Building @openpilot/core..." $InfoColor
    docker run --rm `
        -v "${PWD}/core:/app/core" `
        openpilot-test-runner:latest `
        sh -c "cd /app/core; npm install; npm run build" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "[PASS] Core build successful ✓" $SuccessColor
        return $true
    }
    else {
        Write-ColorOutput "[FAIL] Core build failed ✗" $ErrorColor
        return $false
    }
}

function Test-CoreUnit {
    Write-Section "Test: Core Unit Tests"
    
    Write-ColorOutput "[TEST] Running core unit tests..." $InfoColor
    docker run --rm `
        -v "${PWD}/core:/app/core" `
        -e NODE_ENV=test `
        openpilot-test-runner:latest `
        sh -c "cd /app/core && npm install && npm test" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "[PASS] Core tests passed ✓" $SuccessColor
        return $true
    }
    else {
        Write-ColorOutput "[FAIL] Core tests failed ✗" $ErrorColor
        return $false
    }
}

function Test-VscodeExtensionBuild {
    Write-Section "Test: VSCode Extension Build & Package"
    
    Write-ColorOutput "[TEST] Building VSCode extension..." $InfoColor
    
    # First build core and create tarball
    docker run --rm `
        -v "${PWD}/core:/app/core" `
        -v "${PWD}/vscode-extension:/app/vscode-extension" `
        openpilot-test-runner:latest `
        sh -c "cd /app/core; npm install; npm run build; npm pack; cp openpilot-core-*.tgz /app/vscode-extension/openpilot-core.tgz; cd /app/vscode-extension; npm install --include=dev; npm run compile" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "[PASS] VSCode extension compiled successfully ✓" $SuccessColor
        
        # Try to package with vsce
        Write-ColorOutput "[TEST] Packaging VSIX..." $InfoColor
        docker run --rm `
            -v "${PWD}/vscode-extension:/app/vscode-extension" `
            openpilot-test-runner:latest `
            sh -c "cd /app/vscode-extension; npm install -g @vscode/vsce; rm -rf node_modules; npm install openpilot-core.tgz; npm install --production; vsce package --out /app/vscode-extension/openpilot.vsix" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "[PASS] VSIX package created successfully ✓" $SuccessColor
            if (Test-Path "vscode-extension/openpilot.vsix") {
                $vsixSize = (Get-Item "vscode-extension/openpilot.vsix").Length / 1MB
                Write-ColorOutput "[INFO] VSIX size: $([math]::Round($vsixSize, 2)) MB" $InfoColor
            }
            return $true
        }
        else {
            Write-ColorOutput "[FAIL] VSIX packaging failed ✗" $ErrorColor
            return $false
        }
    }
    else {
        Write-ColorOutput "[FAIL] VSCode extension build failed ✗" $ErrorColor
        return $false
    }
}

function Test-VscodeExtensionUnit {
    Write-Section "Test: VSCode Extension Unit Tests"
    
    Write-ColorOutput "[TEST] Running VSCode extension tests..." $InfoColor
    docker run --rm `
        -v "${PWD}/core:/app/core" `
        -v "${PWD}/vscode-extension:/app/vscode-extension" `
        -e NODE_ENV=test `
        openpilot-test-runner:latest `
        sh -c "cd /app/core; npm install; npm run build; cd /app/vscode-extension; npm install --include=dev; npm test -- --coverage --testPathIgnorePatterns='/e2e/' --testPathIgnorePatterns='/integration/'" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "[PASS] VSCode extension tests passed ✓" $SuccessColor
        return $true
    }
    else {
        Write-ColorOutput "[FAIL] VSCode extension tests failed ✗" $ErrorColor
        return $false
    }
}

function Test-IntegrationTests {
    Write-Section "Test: Integration Tests"
    
    Write-ColorOutput "[TEST] Running integration tests..." $InfoColor
    docker run --rm `
        -v "${PWD}:/app" `
        -e NODE_ENV=test `
        openpilot-test-runner:latest `
        sh -c "cd /app/tests && npm install && npm run test:integration" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "[PASS] Integration tests passed ✓" $SuccessColor
        return $true
    }
    else {
        Write-ColorOutput "[FAIL] Integration tests failed ✗" $ErrorColor
        return $false
    }
}

function Test-Coverage {
    Write-Section "Test: Coverage Analysis"
    
    Write-ColorOutput "[TEST] Running tests with coverage..." $InfoColor
    docker run --rm `
        -v "${PWD}:/app" `
        -v "${PWD}/coverage:/app/coverage" `
        -e NODE_ENV=test `
        openpilot-test-runner:latest `
        sh -c "cd /app/tests && npm install && npm test -- --coverage" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "[PASS] Coverage analysis completed ✓" $SuccessColor
        
        # Show coverage summary if available
        if (Test-Path "coverage/coverage-summary.json") {
            Write-ColorOutput "[INFO] Coverage summary:" $InfoColor
            Get-Content "coverage/coverage-summary.json" | ConvertFrom-Json | Format-List
        }
        return $true
    }
    else {
        Write-ColorOutput "[FAIL] Coverage analysis failed ✗" $ErrorColor
        return $false
    }
}

# Main execution
Write-Section "OpenPilot - Complete Local Docker Test Suite"
Write-ColorOutput "This script will run ALL tests that GitHub Actions runs" $InfoColor
Write-ColorOutput "Using Docker to ensure consistent environment" $InfoColor

# Track results
$results = @{
    DockerCheck = $false
    ImageBuild = $false
    CoreBuild = $false
    CoreTests = $false
    VscodeExtensionBuild = $false
    VscodeExtensionTests = $false
    IntegrationTests = $false
    Coverage = $false
}

# Step 1: Check Docker
$results.DockerCheck = Test-DockerAvailable
if (-not $results.DockerCheck) {
    Write-ColorOutput "`n[ABORT] Cannot proceed without Docker" $ErrorColor
    exit 1
}

# Step 2: Build test image
$results.ImageBuild = Build-TestImage
if (-not $results.ImageBuild) {
    Write-ColorOutput "`n[ABORT] Cannot proceed without test image" $ErrorColor
    exit 1
}

# Step 3: Run all tests
$results.CoreBuild = Test-CoreBuild
$results.CoreTests = Test-CoreUnit
$results.VscodeExtensionBuild = Test-VscodeExtensionBuild
$results.VscodeExtensionTests = Test-VscodeExtensionUnit
$results.IntegrationTests = Test-IntegrationTests
$results.Coverage = Test-Coverage

# Final summary
Write-Section "Test Results Summary"

$allPassed = $true
foreach ($test in $results.Keys) {
    $status = if ($results[$test]) { "✓ PASS" } else { "✗ FAIL"; $allPassed = $false }
    $color = if ($results[$test]) { $SuccessColor } else { $ErrorColor }
    Write-ColorOutput ("{0,-30} {1}" -f $test, $status) $color
}

Write-Host ""
if ($allPassed) {
    Write-ColorOutput "========================================" $SuccessColor
    Write-ColorOutput "  ALL TESTS PASSED! ✓✓✓" $SuccessColor
    Write-ColorOutput "  Safe to push to GitHub" $SuccessColor
    Write-ColorOutput "========================================" $SuccessColor
    exit 0
}
else {
    Write-ColorOutput "========================================" $ErrorColor
    Write-ColorOutput "  SOME TESTS FAILED ✗" $ErrorColor
    Write-ColorOutput "  Fix issues before pushing" $ErrorColor
    Write-ColorOutput "========================================" $ErrorColor
    exit 1
}
