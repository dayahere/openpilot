# Simple Repository Cleanup Script
# This script removes duplicate, temporary, and outdated files

param(
    [switch]$DryRun
)

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  OpenPilot Repository Cleanup" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN MODE - No files will be deleted`n" -ForegroundColor Yellow
}

$removedCount = 0

# Define items to remove
$dirsToRemove = @(
    "i:\openpilot\artifacts-local",
    "i:\openpilot\build-output",
    "i:\openpilot\installers-output",
    "i:\openpilot\docker-installers-output",
    "i:\openpilot\build-artifacts",
    "i:\openpilot\final-check",
    "i:\openpilot\temp-vsix-check",
    "i:\openpilot\manual-vsix-build",
    "i:\openpilot\x",
    "i:\openpilot\coverage",
    "i:\openpilot\artifacts"
)

$filesToRemove = @(
    # Build logs
    "i:\openpilot\build-all-fixed-20251012-172249.log",
    "i:\openpilot\build-auto-20251012-183531.log",
    "i:\openpilot\build-auto-fix.log",
    "i:\openpilot\build-autofix.log",
    "i:\openpilot\build-complete.log",
    "i:\openpilot\build-final-20251012-172848.log",
    
    # Zip files
    "i:\openpilot\final-check.zip",
    "i:\openpilot\temp.zip",
    "i:\openpilot\x.zip",
    "i:\openpilot\openpilot-artifacts-v1.0.0.zip",
    "i:\openpilot\openpilot-build-artifacts-20251011-233008.zip"
)

# Remove directories
Write-Host "Removing temporary directories..." -ForegroundColor Yellow
foreach ($dir in $dirsToRemove) {
    if (Test-Path $dir) {
        Write-Host "  - Removing: $dir" -ForegroundColor Gray
        if (-not $DryRun) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
        $removedCount++
    }
}

# Remove files
Write-Host "`nRemoving temporary files..." -ForegroundColor Yellow
foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Write-Host "  - Removing: $file" -ForegroundColor Gray
        if (-not $DryRun) {
            Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
        }
        $removedCount++
    }
}

# Create organized directory structure
Write-Host "`nCreating organized directory structure..." -ForegroundColor Yellow
$dirs = @(
    "i:\openpilot\docs\guides",
    "i:\openpilot\docs\testing",
    "i:\openpilot\docs\build",
    "i:\openpilot\scripts\build"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        Write-Host "  - Creating: $dir" -ForegroundColor Gray
        if (-not $DryRun) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
    }
}

Write-Host "`n====================================" -ForegroundColor Green
Write-Host "  Cleanup Complete!" -ForegroundColor Green
Write-Host "====================================`n" -ForegroundColor Green

if ($DryRun) {
    Write-Host "This was a dry run. Run without -DryRun to actually remove files." -ForegroundColor Yellow
} else {
    Write-Host "Removed approximately $removedCount items." -ForegroundColor Cyan
}
