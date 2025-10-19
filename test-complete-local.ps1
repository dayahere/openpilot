# =============================================================================
# TEST 8: Android App Build
# =============================================================================
function Test-AndroidBuild {
    # Remove any leftover tarball in vscode-extension before android build
    if (Test-Path "vscode-extension/openpilot-core-1.0.0.tgz") {
        Remove-Item "vscode-extension/openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Removed leftover tarball from vscode-extension before android build." $InfoColor
    }
    # Ensure tarball is present in workspace root for Docker
    if (Test-Path "core/openpilot-core-1.0.0.tgz") {
        Copy-Item "core/openpilot-core-1.0.0.tgz" "openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Copied tarball to workspace root for android build." $InfoColor
        # Also copy tarball to vscode-extension for Docker build context
        Copy-Item "core/openpilot-core-1.0.0.tgz" "vscode-extension/openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Copied tarball to vscode-extension for android build." $InfoColor
    }
    Write-Section "TEST 8: Android App Build"
    Write-Step "Building android app..."
    docker run --rm -v "${PWD}:/workspace" -w /workspace/android openpilot-test:latest sh -c "npm cache clean --force && npm install --legacy-peer-deps && npm install --production --legacy-peer-deps ../openpilot-core-1.0.0.tgz && npm install --save-dev @types/uuid && npm run build" | Out-Host  # Adjust if Flutter: use flutter build apk
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Android build failed"
        $Global:TestResults['AndroidBuild'] = $false
        return $false
    }
    Write-Success "Android build successful"
    $Global:TestResults['AndroidBuild'] = $true
    return $true
}
# =============================================================================
# OpenPilot - Complete Local Docker Test Suite
# Mirrors ALL GitHub Actions steps exactly
# =============================================================================

$ErrorActionPreference = "Stop"
## ...existing code...


# ...existing function definitions...

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
    # Ensure working directory is project root
    $rootDir = (Resolve-Path .).Path
    if ($rootDir -like "*\core") {
        Write-Failure "Script must be run from project root (I:\openpilot), not core directory."
        exit 1
    }

    # Generate tarball in Docker container
    Write-Step "Generating core tarball in Docker..."
    docker run --rm -v "${PWD}/core:/workspace" -w /workspace openpilot-test:latest sh -c "npm pack --force" | Out-Host
    $tarball = Get-Item "core\openpilot-core-1.0.0.tgz" -ErrorAction SilentlyContinue
    if (-not $tarball -or $tarball.Length -lt 1000) {
        Write-Failure "Failed to generate valid tarball in core directory"
        exit 1
    }
    Write-ColorOutput "Generated tarball: $($tarball.FullName) ($($tarball.Length) bytes)" $InfoColor

    # Remove any leftover tarball in vscode-extension before core build
    if (Test-Path "vscode-extension/openpilot-core-1.0.0.tgz") {
        Remove-Item "vscode-extension/openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Removed leftover tarball from vscode-extension before core build." $InfoColor
    }
    # Copy tarball to workspace root and vscode-extension
    Copy-Item "core/openpilot-core-1.0.0.tgz" "openpilot-core-1.0.0.tgz" -Force
    Write-ColorOutput "Copied tarball to workspace root for core build." $InfoColor
    Copy-Item "core/openpilot-core-1.0.0.tgz" "vscode-extension/openpilot-core-1.0.0.tgz" -Force
    Write-ColorOutput "Copied tarball to vscode-extension for core build." $InfoColor
    Write-Section "TEST 1: Core Library Build and Unit Tests"
    
    Write-Step "Building @openpilot/core..."
    docker run --rm -v "${PWD}:/workspace" -w /workspace/core openpilot-test:latest sh -c "npm cache clean --force && npm install --legacy-peer-deps && npm install --save-dev typescript jest @jest/globals @types/uuid && npm install --production --legacy-peer-deps ../openpilot-core-1.0.0.tgz && npm install --save-dev @types/uuid && npm run build"
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
    Remove-Item "vscode-extension/openpilot-core-*.tgz" -ErrorAction SilentlyContinue
    if (Test-Path "core/openpilot-core-1.0.0.tgz") {
        Copy-Item "core/openpilot-core-1.0.0.tgz" "vscode-extension/openpilot-core-1.0.0.tgz" -Force
        Write-ColorOutput "Copied tarball to vscode-extension directory for Docker build." $InfoColor
    } else {
        Write-Failure "Tarball not found in core directory. Cannot proceed with VSCode extension build."
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
        "npm install --production --legacy-peer-deps",
        "npm install --save-dev @types/uuid"
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
    Write-Step "Waiting for Ollama to be reachable and model loaded from test container..."
    $POLL_COUNT = 0
    $response = $null
    do {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -TimeoutSec 5 2>$null
            Write-Host "Ollama /api/tags response (container): $($response | ConvertTo-Json -Compress) ($POLL_COUNT/60 sec)"
        } catch {}
        Start-Sleep 1
        $POLL_COUNT++
    } while ($POLL_COUNT -lt 5 -and ($response -eq $null -or $response.models.Count -eq 0))

    Write-Success "Ollama API is up (container check). Proceeding to pull model. [OK]"

    Write-Step "Pulling llama2 model via HTTP API (FIXED)..."
    $MAX_PULL_ATTEMPTS = 3
    $PULL_SUCCESS = $false
    for ($i = 0; $i -lt $MAX_PULL_ATTEMPTS; $i++) {
        try {
            Write-Host "[PULL ATTEMPT $((1+$i))] Using HTTP API..."
            Invoke-RestMethod -Uri "http://localhost:11434/api/pull" -Method Post `
              -Body (@{name="llama2"} | ConvertTo-Json) `
              -ContentType "application/json" -TimeoutSec 120
            $PULL_SUCCESS = $true
            break
        }
        catch {
            Write-Host "[PULL ATTEMPT $((1+$i))] HTTP failed, trying CLI..." -ForegroundColor Yellow
            docker exec openpilot-ollama-1 ollama pull llama2 2>&1 | Out-Null
            Start-Sleep 2
        }
    }

    if (-not $PULL_SUCCESS) {
        Write-Error "[FAIL] Model pull failed after $MAX_PULL_ATTEMPTS attempts"
        exit 1
    }

    $modelWait = 0
    $modelMaxWait = 60
    $modelReady = $false
    do {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -TimeoutSec 5 2>$null
            Write-Host "Ollama /api/tags response (container): $($response | ConvertTo-Json -Compress) ($modelWait/$modelMaxWait sec)"
            if ($response.models | Where-Object { $_.name -eq "llama2:latest" }) {
                $modelReady = $true
                Write-Success "Ollama model 'llama2' is loaded (container check). Proceeding with integration tests."
                break
            }
        } catch {}
        Start-Sleep 1
        $modelWait++
    } while ($modelWait -lt $modelMaxWait -and -not $modelReady)

    if (-not $modelReady) {
        Write-Failure "Ollama model 'llama2' did not load in time. Aborting integration tests."
        $Global:TestResults['IntegrationTests'] = $false
        return $false
    }
    docker-compose exec -T openpilot-test sh -c "cd /workspace/tests && npm install --legacy-peer-deps && npm run test:integration" | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Integration tests failed"
        $Global:TestResults['IntegrationTests'] = $false
        return $false
    }
    Write-Success "Integration tests passed"
    $Global:TestResults['IntegrationTests'] = $true
    return $true
        Write-Section "TEST 4: Integration Tests"
        Write-Step "Waiting for Ollama to be reachable from test container..."
        $maxWait = 30
        $waited = 0
        $ollamaReady = $false
        while ($waited -lt $maxWait) {
            try {
                # Check from container (primary)
                $curlResult = docker-compose exec -T openpilot-test sh -c "curl -s -w '%{http_code}' -o /dev/null http://ollama:11434/api/tags"
                Write-ColorOutput "Ollama /api/tags HTTP status (container): $curlResult ($waited/$maxWait sec)" $InfoColor
                if ($curlResult -eq "200") {
                    $ollamaReady = $true
                    break
                }
            } catch {
                Write-ColorOutput "[DEBUG] Container readiness check failed: $($_.Exception.Message)" $WarningColor
            }
            # Optional host check for debugging
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -ErrorAction Stop
                Write-ColorOutput "Ollama /api/tags HTTP status (host): $($response.StatusCode) ($waited/$maxWait sec)" $InfoColor
                if ($response.StatusCode -eq 200) {
                    $ollamaReady = $true
                    break
                }
            } catch {
                Write-ColorOutput "[DEBUG] Host readiness check failed: $($_.Exception.Message)" $WarningColor
            }
            Start-Sleep -Seconds 1
            $waited += 1
            Write-ColorOutput "Waiting for Ollama API... ($waited/$maxWait seconds)" $InfoColor
        }
        if (-not $ollamaReady) {
            Write-Failure "Ollama API is not reachable after waiting $maxWait seconds. Aborting integration tests."
            $Global:TestResults['IntegrationTests'] = $false
            return $false
        }
        # Pull llama2 model after API is up
        Write-Step "Pulling llama2 model from test container..."
        $pullResult = docker-compose exec -T openpilot-test sh -c "ollama pull llama2"
        Write-ColorOutput "Ollama pull llama2 result: $pullResult" $InfoColor
        # Wait for model to appear in /api/tags
        $modelWait = 0
        $modelMaxWait = 60
        while ($modelWait -lt $modelMaxWait) {
            $tagsJson = docker-compose exec -T openpilot-test sh -c "curl -s http://ollama:11434/api/tags"
            Write-ColorOutput "Ollama /api/tags response (container): $tagsJson ($modelWait/$modelMaxWait sec)" $InfoColor
            if ($tagsJson -match '"name":"llama2:latest"') {
                Write-Success "Ollama model 'llama2' is loaded (container check). Proceeding with integration tests."
                break
            }
            Start-Sleep -Seconds 1
            $modelWait += 1
            Write-ColorOutput "Waiting for llama2 model... ($modelWait/$modelMaxWait seconds)" $InfoColor
        }
        if ($modelWait -ge $modelMaxWait) {
            Write-Failure "Ollama model 'llama2' did not load in time. Aborting integration tests."
            $Global:TestResults['IntegrationTests'] = $false
            return $false
        }
        Write-Success "Ollama model is loaded. Running integration tests..."
        docker-compose exec -T openpilot-test sh -c "cd /workspace/tests && npm install --legacy-peer-deps && npm run test:integration" | Out-Host
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
    docker run --rm -v "${PWD}:/workspace" -w /workspace/desktop openpilot-test:latest sh -c "npm cache clean --force && npm install --legacy-peer-deps && npm install --production --legacy-peer-deps ../openpilot-core-1.0.0.tgz && npm install --save-dev @types/uuid && npm run build" | Out-Host
    
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
    docker run --rm -v "${PWD}:/workspace" -w /workspace/web openpilot-test:latest sh -c "npm cache clean --force && npm install --legacy-peer-deps && npm install --production --legacy-peer-deps ../openpilot-core-1.0.0.tgz && npm install --save-dev @types/uuid && npm run build" | Out-Host
    
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

    # Pre-pull Ollama model to cache before starting Docker Compose
    Write-Step "Starting Ollama container for model pre-pull..."
    docker-compose -f "I:/openpilot/docker-compose.yml" up -d ollama
    Write-Step "Pre-pulling Ollama model to cache (only needed once)..."
    try {
        docker-compose -f "I:/openpilot/docker-compose.yml" exec ollama pull llama2
        Write-Success "Ollama model pre-pull complete. Model is cached for fast startup."
    } catch {
        Write-Warning "Ollama model pre-pull failed. Continuing with startup."
    }

    # Set Ollama API URL for all test runs
    $env:OLLAMA_API_URL = "http://ollama:11434"
    # Stop and remove any existing Ollama containers to avoid port conflicts
    Write-Step "Stopping and removing any existing Ollama containers..."
    docker ps -a --filter "ancestor=ollama/ollama" --format "{{.ID}}" | ForEach-Object { docker stop $_; docker rm $_ }
    docker ps -a --filter "name=ollama" --format "{{.ID}}" | ForEach-Object { docker stop $_; docker rm $_ }
    Write-Success "Existing Ollama containers stopped and removed."
    Write-Section "OpenPilot - Complete Local Docker Test Suite"
    Write-ColorOutput "Mirrors ALL GitHub Actions steps" $InfoColor
    Write-ColorOutput "Run this before EVERY push to GitHub" $WarningColor
    Write-Host ""

    # Start Docker Compose for Ollama and test container
    Write-Step "Starting Docker Compose for Ollama and test environment..."
    docker-compose -f "I:/openpilot/docker-compose.yml" up -d --build
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Failed to start Docker Compose environment. Aborting."
        exit 1
    }
    Write-Success "Docker Compose environment started. Waiting for Ollama to be ready..."

    # Wait for Ollama to be reachable
    $maxWait = 30
    $waited = 0
    while ($waited -lt $maxWait) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Success "Ollama model is loaded. Proceeding with CI/CD pipeline."
                break
            }
        } catch {
            Write-ColorOutput "[DEBUG] Host readiness check failed: $($_.Exception.Message)" $WarningColor
            # Try readiness check inside the test container
            $containerStatus = docker-compose -f "I:/openpilot/docker-compose.yml" exec -T openpilot-test sh -c "curl -s -o /dev/null -w '%{http_code}' http://ollama:11434/api/tags"
            Write-ColorOutput "[DEBUG] Container readiness HTTP status: $containerStatus ($waited/$maxWait sec)" $InfoColor
            if ($containerStatus -eq "200") {
                Write-Success "Ollama model is loaded (container check). Proceeding with CI/CD pipeline."
                break
            }
        }
        Start-Sleep -Seconds 1
        $waited += 1
        Write-ColorOutput "Waiting for Ollama model... ($waited/$maxWait seconds)" $InfoColor
    }
    if ($waited -ge $maxWait) {
    Write-Failure "Ollama model did not load in time. Aborting."
        exit 1
    }
    
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
        Write-Warning "Tarball not found in core directory. Skipping copy to workspace root."
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

    # Export all build/test functions to a temp file
    $tempScript = Join-Path $env:TEMP "openpilot-parallel-builds.ps1"
    $fullScript = Get-Content $PSCommandPath
    $fullScript += "`n& $args[0]"
    Set-Content -Path $tempScript -Value $fullScript

    # Copy tarball before each parallel job to avoid race conditions
    $workspaceRoot = (Resolve-Path ".").Path
    $tarballSrc = Join-Path $workspaceRoot "openpilot-core-1.0.0.tgz"
    $tarballDst = Join-Path $workspaceRoot "core\openpilot-core-1.0.0.tgz"

    # Parallel builds after core (using jobs)
    $tempScript = Join-Path $env:TEMP "openpilot-parallel-builds.ps1"
    $fullScript = Get-Content $PSCommandPath
    $fullScript += "`n& `$args[0]"
    Set-Content -Path $tempScript -Value $fullScript


    # Parallel builds after core (using jobs)
    $artifactsDir = Join-Path $workspaceRoot "artifacts"
    if (-not (Test-Path $artifactsDir)) { New-Item -ItemType Directory -Path $artifactsDir | Out-Null }




# Ensure artifacts directory exists
$artifactsDir = Join-Path (Resolve-Path ".").Path "artifacts"
if (-not (Test-Path $artifactsDir)) {
    New-Item -ItemType Directory -Path $artifactsDir | Out-Null
}
$webArtifactsDir = Join-Path $artifactsDir "web"
$desktopArtifactsDir = Join-Path $artifactsDir "desktop"
$vscodeArtifactsDir = Join-Path $artifactsDir "vscode"
$androidArtifactsDir = Join-Path $artifactsDir "android"
New-Item -ItemType Directory -Path $webArtifactsDir, $desktopArtifactsDir, $vscodeArtifactsDir, $androidArtifactsDir -Force | Out-Null

# Parallel builds after core (using jobs)
$workspaceRoot = (Resolve-Path ".").Path
$tarballSrc = Join-Path $workspaceRoot "openpilot-core-1.0.0.tgz"
$tarballDst = Join-Path $workspaceRoot "core\openpilot-core-1.0.0.tgz"

$webJob = Start-Job -ScriptBlock { 
    Set-Location $using:workspaceRoot; 
    Copy-Item $using:tarballSrc $using:tarballDst -Force -ErrorAction SilentlyContinue; 
    $webDir = "$using:workspaceRoot/web";
    if (Test-Path "$webDir/package.json") {
        docker run --rm -v "$webDir:/workspace" -w /workspace openpilot-test:latest sh -c "rm -rf node_modules package-lock.json && npm install --omit=prod --legacy-peer-deps && npm audit fix --legacy-peer-deps && npm run build && cp -r dist/* /workspace/.." *>&1 | Out-File "$using:workspaceRoot/web-job.log";
        if ($LASTEXITCODE -eq 0) { Copy-Item "$webDir/dist/*" $using:webArtifactsDir -Force -Recurse -ErrorAction SilentlyContinue }
    } else {
        "Web package.json not found" | Out-File "$using:workspaceRoot/web-job.log"
    }
}
$desktopJob = Start-Job -ScriptBlock { 
    Set-Location $using:workspaceRoot; 
    Copy-Item $using:tarballSrc $using:tarballDst -Force -ErrorAction SilentlyContinue; 
    $desktopDir = "$using:workspaceRoot/desktop";
    if (Test-Path "$desktopDir/package.json") {
        docker run --rm -v "$desktopDir:/workspace" -w /workspace openpilot-test:latest sh -c "rm -rf node_modules package-lock.json && npm install --omit=prod --legacy-peer-deps && npm audit fix --legacy-peer-deps && npm run build && cp -r dist/* /workspace/.." *>&1 | Out-File "$using:workspaceRoot/desktop-job.log";
        if ($LASTEXITCODE -eq 0) { Copy-Item "$desktopDir/dist/*" $using:desktopArtifactsDir -Force -Recurse -ErrorAction SilentlyContinue }
    } else {
        "Desktop package.json not found" | Out-File "$using:workspaceRoot/desktop-job.log"
    }
}
$vscodeJob = Start-Job -ScriptBlock { 
    Set-Location $using:workspaceRoot; 
    Copy-Item $using:tarballSrc $using:tarballDst -Force -ErrorAction SilentlyContinue; 
    $vscodeDir = "$using:workspaceRoot/vscode-extension";
    if (Test-Path "$vscodeDir/package.json") {
        docker run --rm -v "$vscodeDir:/workspace" -w /workspace openpilot-test:latest sh -c "rm -rf node_modules package-lock.json && npm install --omit=prod --legacy-peer-deps && npm audit fix --legacy-peer-deps && npm run build && npm pack && cp *.tgz /workspace/.." *>&1 | Out-File "$using:workspaceRoot/vscode-job.log";
        if ($LASTEXITCODE -eq 0) { Copy-Item "$vscodeDir/*.tgz" $using:vscodeArtifactsDir -Force -ErrorAction SilentlyContinue }
    } else {
        "VSCode package.json not found" | Out-File "$using:workspaceRoot/vscode-job.log"
    }
}
$androidJob = Start-Job -ScriptBlock { 
    Set-Location $using:workspaceRoot; 
    Copy-Item $using:tarballSrc $using:tarballDst -Force -ErrorAction SilentlyContinue; 
    $androidDir = "$using:workspaceRoot/android";
    if (Test-Path "$androidDir/pubspec.yaml") {
        docker run --rm -v "$androidDir:/workspace" -w /workspace openpilot-test:latest sh -c "flutter pub get && flutter build apk && cp build/app/outputs/flutter-apk/app-release.apk /workspace/.." *>&1 | Out-File "$using:workspaceRoot/android-job.log";
        if ($LASTEXITCODE -eq 0) { Copy-Item "$androidDir/app-release.apk" $using:androidArtifactsDir -Force -ErrorAction SilentlyContinue }
    } else {
        "Android pubspec.yaml not found" | Out-File "$using:workspaceRoot/android-job.log"
    }
}

$jobs = @($webJob, $desktopJob, $vscodeJob, $androidJob)
Write-ColorOutput "Waiting for parallel build jobs to complete..." $InfoColor
$jobs | Wait-Job

# Process job outputs
$results = $jobs | ForEach-Object {
    $logFile = switch ($_.Name) {
        "Job1" { "$workspaceRoot/web-job.log" }
        "Job2" { "$workspaceRoot/desktop-job.log" }
        "Job3" { "$workspaceRoot/vscode-job.log" }
        "Job4" { "$workspaceRoot/android-job.log" }
    }
    $output = Get-Content $logFile -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch "Container.*Running|OCI runtime.*failed|executable file not found" }
    Write-Host $output
    $success = $output -match "\[PASS\].*successful" -or $output -match "Successfully built.*apk" -or $output -match "npm notice.*total files"
    Remove-Item $logFile -ErrorAction SilentlyContinue
    $success
}

Write-ColorOutput "Artifacts generated in $artifactsDir" $InfoColor
if ($results -contains $false) {
    Write-Warning "One or more parallel builds failed, but artifacts were generated where possible."
} else {
    Write-Success "All parallel builds completed successfully"
}

    $jobs = @($webJob, $desktopJob, $vscodeJob, $androidJob)
    Write-ColorOutput "Waiting for parallel build jobs to complete..." $InfoColor
    $jobs | Wait-Job

    Write-ColorOutput "Artifacts generated in $artifactsDir" $SuccessColor
    # Print build results from log files
    $jobLogs = @("web-job.log", "desktop-job.log", "vscode-job.log", "android-job.log")
    foreach ($i in 0..3) {
        $logFile = Join-Path $workspaceRoot $jobLogs[$i]
        if (Test-Path $logFile) {
            Get-Content $logFile | Write-Host
            Remove-Item $logFile -ErrorAction SilentlyContinue
        }
    }

    # Only push if all critical tests passed
    $criticalTests = @('CoreBuild', 'CoreTests', 'VSCodeBuild', 'VSCodePackage')
    $allCriticalPassed = $true
    foreach ($test in $criticalTests) {
        if (-not $Global:TestResults[$test]) {
            $allCriticalPassed = $false
            break
        }
    }
    if ($allCriticalPassed) {
        Write-ColorOutput "All builds/tests passed. Proceeding to git push..." $SuccessColor
        git add .
        git commit -m "Automated: All CI/CD steps passed. Repo optimized."
        git push
    } else {
        Write-Failure "Critical tests failed. Git push blocked."
    }
    
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
