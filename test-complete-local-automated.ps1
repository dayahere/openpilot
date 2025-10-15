# =============================================================================
# OpenPilot - Automated Complete Local Docker Test Suite
# =============================================================================

$ErrorActionPreference = "Stop"
$SuccessColor = "Green"
$ErrorColor = "Red"
$InfoColor = "Cyan"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "========================================" $InfoColor
Write-ColorOutput "  Step 1: Creating @openpilot/core tarball in Docker" $InfoColor
Write-ColorOutput "========================================" $InfoColor

# Remove any old tarballs
Remove-Item "core/openpilot-core-*.tgz" -ErrorAction SilentlyContinue
Remove-Item "openpilot-core-*.tgz" -ErrorAction SilentlyContinue

# Run npm pack in Docker, mounting only core dir
$packOutput = docker run --rm -v "${PWD}/core:/core" -w /core node:20-bullseye-slim sh -c "npm install --legacy-peer-deps && npm run build && npm pack --loglevel verbose && ls -l" | Out-String
Write-ColorOutput $packOutput $InfoColor

# Check for tarball
if (Test-Path "core/openpilot-core-1.0.0.tgz") {
    $tarballInfo = Get-Item "core/openpilot-core-1.0.0.tgz"
    Write-ColorOutput "Tarball created: $($tarballInfo.FullName) ($($tarballInfo.Length) bytes)" $SuccessColor
    Write-ColorOutput "========================================" $InfoColor
    Write-ColorOutput "  Step 2: Running Complete Local Docker Test Suite" $InfoColor
    Write-ColorOutput "========================================" $InfoColor
    powershell -ExecutionPolicy Bypass -File test-complete-local.ps1
    exit $LASTEXITCODE
} else {
    Write-ColorOutput "Tarball NOT created. Check Docker output above." $ErrorColor
    exit 1
}
