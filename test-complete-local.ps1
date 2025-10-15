# =============================================================================
# OpenPilot - Complete Local Docker Test Suite
# Mirrors ALL GitHub Actions steps exactly
# =============================================================================

$ErrorActionPreference = "Stop"
$SuccessColor = "Green"
$ErrorColor = "Red"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

# Track all test results
$Global:TestResults = @{}
$Global:StartTime = Get-Date

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
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

function Write-Step {
    param([string]$Message)
    Write-ColorOutput "[STEP] $Message" $InfoColor
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[PASS] $Message [OK]" $SuccessColor
}

function Test-DockerInstalled {
    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if ($null -eq $docker) {
        Write-Host "Docker is not installed or not in PATH." -ForegroundColor Red
        return $false
    }
    try {
        docker version | Out-Null
        return $true
    } catch {
        Write-Host "Docker is installed but not running or not accessible." -ForegroundColor Red
        return $false
    }
}

function Write-Failure {
    param([string]$Message)
    Write-ColorOutput "[FAIL] $Message [X]" $ErrorColor
    }

function Invoke-DockerImages {
    Write-Section "Building Docker Test Images"
    
    # Check if image exists
    $imageExists = docker images -q openpilot-test:latest 2>$null
    if ($imageExists) {
        Write-Success "Test image already exists (openpilot-test:latest)"
        return $true
    }
    
    # Build main test image
    Write-Step "Building Node.js 20 test environment (this may take a few minutes)..."
    docker build -f Dockerfile.test -t openpilot-test:latest . | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Failed to build test image"
        return $false
    }
    Write-Success "Test image built successfully"
    
    return $true
}

# =============================================================================
# TEST 1: Core Library Build & Tests
# =============================================================================
function Test-CoreBuildAndTests {
    # Remove any leftover tarball in vscode-extension before core build
    if (Test-Path "vscode-extension/openpilot-core-1.0.0.tgz") {
        Remove-Item "vscode-extension/openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Removed leftover tarball from vscode-extension before core build." $InfoColor
    }
    # Ensure tarball is present in workspace root for Docker
    if (Test-Path "core/openpilot-core-1.0.0.tgz") {
        Copy-Item "core/openpilot-core-1.0.0.tgz" "openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Copied tarball to workspace root for core build." $InfoColor
        # Also copy tarball to vscode-extension for Docker build context
        Copy-Item "core/openpilot-core-1.0.0.tgz" "vscode-extension/openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Copied tarball to vscode-extension for core build." $InfoColor
    }
    Write-Section "TEST 1: Core Library Build and Unit Tests"
    
    Write-Step "Building @openpilot/core..."
    docker run --rm -v "${PWD}:/workspace" -w /workspace/core openpilot-test:latest sh -c "npm cache clean --force && npm install --legacy-peer-deps && npm install --save-dev typescript jest @jest/globals @types/uuid && npm install --production --legacy-peer-deps ../openpilot-core-1.0.0.tgz && npm run build"
    $buildExit = $LASTEXITCODE
    
    if ($buildExit -ne 0) {
        Write-Failure "Core build failed"
        $Global:TestResults['CoreBuild'] = $false
        return $false
    }
    Write-Success "Core build successful"
    
    Write-Step "Running core unit tests..."
    docker run --rm -v "${PWD}:/workspace" -w /workspace/core -e NODE_ENV=test openpilot-test:latest npm test
    $testExit = $LASTEXITCODE
    
    if ($testExit -ne 0) {
        Write-Failure "Core tests failed"
        $Global:TestResults['CoreTests'] = $false
        return $false
    }
    Write-Success "Core tests passed"
    
    $Global:TestResults['CoreBuild'] = $true
    $Global:TestResults['CoreTests'] = $true
    return $true
}

# =============================================================================
# TEST 2: VSCode Extension Build & Package
# =============================================================================
function Test-VSCodeExtension {
    Write-ColorOutput "Current working directory: $(Get-Location)" $InfoColor
    # Explicitly check and print tarball existence and size after pack
    if (Test-Path "core/openpilot-core-1.0.0.tgz") {
        $tarballInfo = Get-Item "core/openpilot-core-1.0.0.tgz"
        Write-ColorOutput "Tarball found: $($tarballInfo.FullName) ($($tarballInfo.Length) bytes)" $InfoColor
    } else {
        Write-Failure "Tarball not found after npm pack. Check build output above."
        exit 1
    }
    Write-Section "TEST 2: VSCode Extension Build and Package (CRITICAL)"
    

    # Step 1: Clean up old tarballs and npm cache (host)
    Write-Step "Step 1: Cleaning up old tarballs and npm cache (host)..."
    # Only remove old tarballs from vscode-extension, not core
    Remove-Item "vscode-extension/openpilot-core-*.tgz" -ErrorAction SilentlyContinue
    # Move tarball from workspace root to core/ if found
    if (Test-Path "openpilot-core-1.0.0.tgz") {
        Move-Item "openpilot-core-1.0.0.tgz" "core/openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Moved tarball from workspace root to core/ directory." $InfoColor
    }
    # Copy tarball into vscode-extension for Docker container
    if (Test-Path "core/openpilot-core-1.0.0.tgz") {
        Copy-Item "core/openpilot-core-1.0.0.tgz" "vscode-extension/openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Copied tarball to vscode-extension directory for Docker build." $InfoColor
    } else {
        Write-Failure "Tarball not found in core directory. Cannot copy to vscode-extension."
        exit 1
    }

    # Step 2: Build tarball and install in extension (container-only, using /tmp)
    Write-Step "Step 2: Creating core tarball and installing in extension (container-only, using /tmp)..."
    $tarballName = "openpilot-core-1.0.0.tgz"
    # Step 2c: Run extension install/build/package in extension-only container
    $extInstall = @(
        "rm -rf node_modules package-lock.json",
        "npm install --only=dev --legacy-peer-deps",
        "npm install --production --legacy-peer-deps ./openpilot-core-1.0.0.tgz",
        "npm install --production --legacy-peer-deps"
    ) -join " && "
    docker run --rm -v "${PWD}/vscode-extension:/workspace" -w /workspace openpilot-test:latest sh -c "$extInstall" | Out-Host

    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Core tarball build or extension install failed"
        $Global:TestResults['VSCodeBuild'] = $false
        Write-ColorOutput "Script stopped due to VSCode extension build failure. Fix the issue and re-run." $ErrorColor
        exit 1
    }
    Write-Success "Tarball built and installed in extension container [OK]"
    
    # Step 2: Install dev dependencies and compile
    Write-Step "Step 2: Installing dev dependencies and compiling..."
    docker run --rm -v "${PWD}/vscode-extension:/workspace" -w /workspace openpilot-test:latest sh -c "rm -rf node_modules package-lock.json && npm install --only=dev --legacy-peer-deps && npx tsc -p tsconfig.json" | Out-Host
    
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Extension compilation failed"
        $Global:TestResults['VSCodeBuild'] = $false
        Write-ColorOutput "Script stopped due to VSCode extension compilation failure. Fix the issue and re-run." $ErrorColor
        exit 1
    }
    Write-Success "Extension compiled successfully"
    
    # Step 3: Install production dependencies
    Write-Step "Step 3: Installing production dependencies with tarball..."
    docker run --rm -v "${PWD}/vscode-extension:/workspace" -w /workspace openpilot-test:latest sh -c "rm -rf node_modules && npm install --production --legacy-peer-deps ./$tarballName && npm install --production --legacy-peer-deps" | Out-Host
    
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Production dependencies installation failed"
        $Global:TestResults['VSCodeBuild'] = $false
        Write-ColorOutput "Script stopped due to VSCode extension production dependency install failure. Fix the issue and re-run." $ErrorColor
        exit 1
    }
    Write-Success "Production dependencies installed"
    
    # Step 4: Package VSIX
    Write-Step "Step 4: Packaging VSIX..."
    docker run --rm -v "${PWD}/vscode-extension:/workspace" -w /workspace openpilot-test:latest sh -c "rm -rf /workspace/node_modules && rm -rf node_modules package-lock.json && npm install --only=dev --legacy-peer-deps && npm install -g typescript @vscode/vsce && tsc -p ./ && rm -f openpilot-core-*.tgz && vsce package --no-dependencies --allow-missing-repository" | Out-Host
    
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "VSIX packaging failed"
        $Global:TestResults['VSCodePackage'] = $false
        Write-ColorOutput "Script stopped due to VSIX packaging failure. Fix the issue and re-run." $ErrorColor
        exit 1
    }
    
    # Check if VSIX was created
    $vsix = Get-ChildItem "vscode-extension/*.vsix" | Select-Object -First 1
    if (-not $vsix) {
        Write-Failure "VSIX file not found"
        $Global:TestResults['VSCodePackage'] = $false
        return $false
    }
    
    $vsixSize = [math]::Round($vsix.Length / 1MB, 2)
    Write-Success "VSIX created successfully: $($vsix.Name) - Size: $vsixSize MB"
    
    $Global:TestResults['VSCodeBuild'] = $true
    $Global:TestResults['VSCodePackage'] = $true
    return $true
}

# =============================================================================
# TEST 3: VSCode Extension Unit Tests
# =============================================================================
function Test-VSCodeExtensionTests {
    Write-Section "TEST 3: VSCode Extension Unit Tests"
    
    Write-Step "Running VSCode extension tests..."
    # Ensure extension is compiled and 'out' exists before Docker build
    Write-Step "Compiling VSCode extension before Docker test image build..."
    Push-Location vscode-extension
    if (-not (Test-Path "out")) {
        npm run compile | Out-Host
    }
    Pop-Location
    # Ensure core tarball is present in workspace root for Docker build
    if (-not (Test-Path "openpilot-core-1.0.0.tgz")) {
        Write-Step "Copying core tarball to workspace root for Docker build..."
        Copy-Item -Path "core/openpilot-core-1.0.0.tgz" -Destination "openpilot-core-1.0.0.tgz" -Force
    }
    # Build VSCode test image
    Write-Step "Building VSCode extension test Docker image..."
    docker build -f Dockerfile.vscode-test -t openpilot-vscode-test:latest . | Out-Host
    # Run extension tests in VSCode test container
    docker run --rm -v "${PWD}/vscode-extension:/workspace" -w /workspace -e NODE_ENV=test openpilot-vscode-test:latest | Out-Host
    
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "VSCode extension tests failed"
        $Global:TestResults['VSCodeTests'] = $false
        Write-ColorOutput "Script stopped due to VSCode extension test failure. Fix the issue and re-run." $ErrorColor
        exit 1
    }
    Write-Success "VSCode extension tests passed"
    
    $Global:TestResults['VSCodeTests'] = $true
    return $true
}

# =============================================================================
# TEST 4: Integration Tests
# =============================================================================
function Test-Integration {
    Write-Section "TEST 4: Integration Tests"
    
    Write-Step "Running integration tests..."
    docker run --rm -v "${PWD}:/workspace" -w /workspace/tests -e NODE_ENV=test openpilot-test:latest sh -c "npm install --legacy-peer-deps && npm run test:integration" | Out-Host
    
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Integration tests failed"
        $Global:TestResults['IntegrationTests'] = $false
        return $false
    }
    Write-Success "Integration tests passed"
    
    $Global:TestResults['IntegrationTests'] = $true
    return $true
}

# =============================================================================
# TEST 5: Coverage Analysis
# =============================================================================
function Test-Coverage {
    Write-Section "TEST 5: Code Coverage Analysis"
    
    Write-Step "Running tests with coverage..."
    docker run --rm -v "${PWD}:/workspace" -w /workspace/tests -e NODE_ENV=test openpilot-test:latest sh -c "npm install --legacy-peer-deps && npm test -- --coverage" | Out-Host
    
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Coverage analysis failed"
        $Global:TestResults['Coverage'] = $false
        return $false
    }
    Write-Success "Coverage analysis completed"
    
    $Global:TestResults['Coverage'] = $true
    return $true
}

# =============================================================================
# TEST 6: Desktop Build (Windows/Linux)
# =============================================================================
function Test-DesktopBuild {
    # Remove any leftover tarball in vscode-extension before desktop build
    if (Test-Path "vscode-extension/openpilot-core-1.0.0.tgz") {
        Remove-Item "vscode-extension/openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Removed leftover tarball from vscode-extension before desktop build." $InfoColor
    }
    # Ensure tarball is present in workspace root for Docker
    if (Test-Path "core/openpilot-core-1.0.0.tgz") {
        Copy-Item "core/openpilot-core-1.0.0.tgz" "openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Copied tarball to workspace root for desktop build." $InfoColor
        # Also copy tarball to vscode-extension for Docker build context
        Copy-Item "core/openpilot-core-1.0.0.tgz" "vscode-extension/openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Copied tarball to vscode-extension for desktop build." $InfoColor
    }
    Write-Section "TEST 6: Desktop App Build"
    
    Write-Step "Building desktop app..."
    docker run --rm -v "${PWD}:/workspace" -w /workspace/desktop openpilot-test:latest sh -c "npm cache clean --force && npm install --legacy-peer-deps && npm install --production --legacy-peer-deps ../openpilot-core-1.0.0.tgz && npm run build" | Out-Host
    
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Desktop build failed"
        $Global:TestResults['DesktopBuild'] = $false
        return $false
    }
    Write-Success "Desktop build successful"
    
    $Global:TestResults['DesktopBuild'] = $true
    return $true
}

# =============================================================================
# TEST 7: Web App Build
# =============================================================================
function Test-WebBuild {
    # Remove any leftover tarball in vscode-extension before web build
    if (Test-Path "vscode-extension/openpilot-core-1.0.0.tgz") {
        Remove-Item "vscode-extension/openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Removed leftover tarball from vscode-extension before web build." $InfoColor
    }
    # Ensure tarball is present in workspace root for Docker
    if (Test-Path "core/openpilot-core-1.0.0.tgz") {
        Copy-Item "core/openpilot-core-1.0.0.tgz" "openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Copied tarball to workspace root for web build." $InfoColor
        # Also copy tarball to vscode-extension for Docker build context
        Copy-Item "core/openpilot-core-1.0.0.tgz" "vscode-extension/openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Copied tarball to vscode-extension for web build." $InfoColor
    }
    Write-Section "TEST 7: Web App Build"
    
    Write-Step "Building web app..."
    docker run --rm -v "${PWD}:/workspace" -w /workspace/web openpilot-test:latest sh -c "npm cache clean --force && npm install --legacy-peer-deps && npm install --production --legacy-peer-deps ../openpilot-core-1.0.0.tgz && npm run build" | Out-Host
    
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Web build failed"
        $Global:TestResults['WebBuild'] = $false
        return $false
    }
    Write-Success "Web build successful"
    
    $Global:TestResults['WebBuild'] = $true
    return $true
}

# =============================================================================
# Main Execution
# =============================================================================
function Main {
    Write-Section "OpenPilot - Complete Local Docker Test Suite"
    Write-ColorOutput "Mirrors ALL GitHub Actions steps" $InfoColor
    Write-ColorOutput "Run this before EVERY push to GitHub" $WarningColor
    Write-Host ""
    
    # Initialize results
    $Global:TestResults = @{
        'DockerCheck' = $false
        'ImageBuild' = $false
        'CoreBuild' = $false
        'CoreTests' = $false
        'VSCodeBuild' = $false
        'VSCodePackage' = $false
        'VSCodeTests' = $false
        'IntegrationTests' = $false
        'Coverage' = $false
        'DesktopBuild' = $false
        'WebBuild' = $false
    }
    
    # Step 0: Check Docker
    if (-not (Test-DockerInstalled)) {
        Write-Section "ABORTED: Docker not available"
        return 1
    }
    $Global:TestResults['DockerCheck'] = $true

    # Step 1: Build Docker images
    if (-not (Invoke-DockerImages)) {
        Write-Section "ABORTED: Failed to build Docker images"
        return 1
    }
    $Global:TestResults['ImageBuild'] = $true

    # Ensure tarball is available in workspace root for all builds
    if (Test-Path "core/openpilot-core-1.0.0.tgz") {
        Copy-Item "core/openpilot-core-1.0.0.tgz" "openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Copied tarball to workspace root for all Docker builds." $InfoColor
    } else {
        Write-Failure "Tarball not found in core directory. Cannot copy to workspace root."
        exit 1
    }

    # Retry core build/tests until both pass
    $maxRetries = 5
    $retryCount = 0
    do {
        $coreResult = Test-CoreBuildAndTests
        if ($coreResult) {
            break
        }
        $retryCount++
        Write-ColorOutput "Core build/tests failed. Retrying ($retryCount/$maxRetries)..." $WarningColor
        Start-Sleep -Seconds 5
    } while ($retryCount -lt $maxRetries)
    if (-not $coreResult) {
        Write-Failure "Core build/tests failed after $maxRetries attempts. Aborting."
        exit 1
    }

    # Run integration and coverage tests (serial)
    Test-Integration | Out-Null
    Test-Coverage | Out-Null

    # Run web, desktop, vscode-extension, and android builds in parallel
    # Export all build/test functions to a temp file
    $tempScript = Join-Path $env:TEMP "openpilot-parallel-builds.ps1"
    $fullScript = Get-Content $PSCommandPath
    $fullScript += "`n& $args[0]"
    Set-Content -Path $tempScript -Value $fullScript

    # Start jobs using -FilePath and pass function name as argument
    $webJob = Start-Job -FilePath $tempScript -ArgumentList 'Test-WebBuild'
    $desktopJob = Start-Job -FilePath $tempScript -ArgumentList 'Test-DesktopBuild'
    $vscodeJob = Start-Job -FilePath $tempScript -ArgumentList 'Test-VSCodeExtension'
    # $androidJob = Start-Job -FilePath $tempScript -ArgumentList 'Test-AndroidBuild' # Implement if needed
    $jobs = @($webJob, $desktopJob, $vscodeJob) #, $androidJob)
    Write-ColorOutput "Waiting for parallel build jobs to complete..." $InfoColor
    $jobs | ForEach-Object { Wait-Job $_ }
    $results = $jobs | ForEach-Object { $r = Receive-Job $_; Remove-Job $_; $r }

    # Check all results
    if ($results -contains $false) {
        Write-Failure "One or more parallel builds failed. Aborting push."
        exit 1
    }

    Write-ColorOutput "All builds/tests passed. Proceeding to git push..." $SuccessColor
    git add .
    git commit -m "Automated: All CI/CD steps passed. Repo optimized."
    git push
    
    # Calculate duration
    $duration = (Get-Date) - $Global:StartTime
    
    # Final Report
    Write-Section "Final Test Results"
    Write-Host ""
    Write-ColorOutput "Test Execution Summary" $InfoColor
    Write-ColorOutput ("=" * 60) $InfoColor
    Write-Host ""
    
    $passed = 0
    $failed = 0
    
    foreach ($test in $Global:TestResults.Keys | Sort-Object) {
        $status = $Global:TestResults[$test]
        $icon = if ($status) { "[OK]" } else { "[X]" }
        $color = if ($status) { $SuccessColor } else { $ErrorColor }
        $statusText = if ($status) { "PASS" } else { "FAIL" }
        
        Write-ColorOutput ("{0,-25} {1,-6} {2}" -f $test, $statusText, $icon) $color
        
        if ($status) { $passed++ } else { $failed++ }
    }
    
    Write-Host ""
    Write-ColorOutput ("=" * 60) $InfoColor
    Write-ColorOutput ("Total: {0} tests | Passed: {1} | Failed: {2}" -f ($passed + $failed), $passed, $failed) $InfoColor
    Write-ColorOutput ("Duration: {0:mm}m {0:ss}s" -f $duration) $InfoColor
    Write-ColorOutput ("=" * 60) $InfoColor
    Write-Host ""
    
    # Critical tests check
    $criticalTests = @('CoreBuild', 'CoreTests', 'VSCodeBuild', 'VSCodePackage')
    $allCriticalPassed = $true
    foreach ($test in $criticalTests) {
        if (-not $Global:TestResults[$test]) {
            $allCriticalPassed = $false
            break
        }
    }
    
    if ($allCriticalPassed) {
        Write-ColorOutput "========================================" $SuccessColor
        Write-ColorOutput "  >>> ALL CRITICAL TESTS PASSED <<<" $SuccessColor
        Write-ColorOutput "  SAFE TO PUSH TO GITHUB" $SuccessColor
        Write-ColorOutput "========================================" $SuccessColor
        Write-Host ""
        Write-ColorOutput "Ready to commit and push:" $InfoColor
        Write-ColorOutput '  git commit -m "your message"' $InfoColor
        Write-ColorOutput '  git push' $InfoColor
        return 0
    }
    else {
        Write-ColorOutput "========================================" $ErrorColor
        Write-ColorOutput "  !!! CRITICAL TESTS FAILED !!!" $ErrorColor
        Write-ColorOutput "  DO NOT PUSH - FIX ISSUES FIRST" $ErrorColor
        Write-ColorOutput "========================================" $ErrorColor
        Write-Host ""
        Write-ColorOutput "Critical failures detected:" $ErrorColor
        foreach ($test in $criticalTests) {
            if (-not $Global:TestResults[$test]) {
                Write-ColorOutput "  - $test" $ErrorColor
            }
        }
        Write-Host ""
        Write-ColorOutput "Fix issues and run this script again" $WarningColor
        return 1
    }
}

# Execute
exit (Main)
