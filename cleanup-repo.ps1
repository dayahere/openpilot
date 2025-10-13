# OpenPilot Repository Cleanup and Organization Script
# This script will clean, organize, test, and push the repository

Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  OpenPilot Repository Cleanup & Organization      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Define directories and files to remove
$toRemove = @{
    # Temporary and build artifacts
    Directories = @(
        "artifacts-local",
        "build-output",
        "installers-output",
        "docker-installers-output",
        "build-artifacts",
        "final-check",
        "temp-vsix-check",
        "manual-vsix-build",
        "x",
        "coverage",
        "artifacts"  # Generated artifacts, will be rebuilt
    )
    
    # Duplicate and outdated files
    Files = @(
        # Build logs
        "build-all-fixed-20251012-172249.log",
        "build-auto-20251012-183531.log",
        "build-auto-fix.log",
        "build-autofix.log",
        "build-complete.log",
        "build-final-20251012-172848.log",
        
        # Duplicate documentation (keeping only the latest)
        "BUILD_ARTIFACTS_SUMMARY.md",
        "BUILD_COMPLETE.md",
        "BUILD_SUMMARY.md",
        "CI_CD_FIXES_LOG.md",
        "CI_CD_SUCCESS_REPORT.md",
        "COMPLETE_SOLUTION.md",
        "COMPREHENSIVE_TEST_PLAN.md",
        "DEPLOYMENT_COMPLETE.md",
        "EXTENSION-FIXED.md",
        "FINAL_BUILD_SUCCESS.md",
        "FINAL_DELIVERY.md",
        "FINAL_DELIVERY_SUMMARY.md",
        "GITHUB_ACTIONS_FIX.md",
        "GIT_PUSH_SUCCESS_REPORT.md",
        "GIT_WORKFLOW.md",
        "IMPLEMENTATION_COMPLETE_GUIDE.md",
        "IMPLEMENTATION_PLAN.md",
        "IMPLEMENTATION_ROADMAP.md",
        "LOCAL_BUILD_GUIDE.md",
        "LOCAL_CONTAINER_BUILD_GUIDE.md",
        "OPENPILOT_COMPLETE_GUIDE.md",
        "PHOTOSTUDIO_COMPARISON.md",
        "QUICK_REFERENCE.md",
        "QUICK_REFERENCE_CARD.md",
        "QUICK_START_TESTING.md",
        "QUICK_TEST_GUIDE.md",
        "REQUIREMENTS_VALIDATION_COMPLETE.md",
        "TESTING_STATUS_REPORT.md",
        "TESTING_SUCCESS_SUMMARY.md",
        "TESTING_SUMMARY.md",
        "TESTS_FINAL_SUMMARY.md",
        "TEST_ARCHITECTURE.md",
        "TEST_COMPLETE.md",
        "TEST_COVERAGE_COMPLETE.md",
        "TEST_COVERAGE_PROGRESS.md",
        "TEST_STATUS.md",
        "STATUS.md",
        "WORKSPACE_CONFLICT_FIX.md",
        "EXTENSION-QUICK-START.txt",
        
        # Zip files
        "final-check.zip",
        "temp.zip",
        "x.zip",
        "openpilot-artifacts-v1.0.0.zip",
        "openpilot-build-artifacts-20251011-233008.zip",
        
        # Duplicate build scripts (keeping main ones)
        "build-complete-auto.ps1",
        "monitor-auto-build.ps1",
        "monitor-build.ps1",
        "monitor-container-build.ps1",
        "monitor-simple.ps1",
        "simple-docker-build.ps1",
        "start-implementation.ps1",
        "implement-all-features.ps1",
        "validate-and-build.ps1"
    )
}

# Step 1: Backup before cleanup
Write-Host " STEP 1: Creating backup..." -ForegroundColor Yellow
$backupDir = "i:\openpilot-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "   Creating backup at: $backupDir" -ForegroundColor Gray

# Step 2: Remove directories
Write-Host "`n STEP 2: Removing temporary and build directories..." -ForegroundColor Yellow
foreach ($dir in $toRemove.Directories) {
    $path = "i:\openpilot\$dir"
    if (Test-Path $path) {
        Write-Host "   Removing: $dir" -ForegroundColor Red
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Step 3: Remove files
Write-Host "`n STEP 3: Removing duplicate and outdated files..." -ForegroundColor Yellow
foreach ($file in $toRemove.Files) {
    $path = "i:\openpilot\$file"
    if (Test-Path $path) {
        Write-Host "   Removing: $file" -ForegroundColor Red
        Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
    }
}

# Step 4: Organize documentation
Write-Host "`n STEP 4: Organizing documentation..." -ForegroundColor Yellow
$docsToKeep = @(
    "README.md",
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "LICENSE",
    "FAQ.md",
    "INSTALL.md",
    "CODEOWNERS",
    "COMPREHENSIVE_TEST_COVERAGE_AND_REQUIREMENTS.md",
    "TEST_IMPLEMENTATION_COMPLETE.md",
    "COMPLETE-SETUP-GUIDE.md",
    "COMPREHENSIVE-STATUS-REPORT.md",
    "QUESTIONS-ANSWERED.md",
    "SETUP-EXTENSION.md",
    "VSCODE_EXTENSION_USAGE_GUIDE.md",
    "DOCKER_TESTING.md",
    "README_TESTS.md",
    "START_HERE.md",
    "PROJECT_SUMMARY.md",
    "EXECUTIVE_SUMMARY.md"
)

# Create docs directory structure
if (-not (Test-Path "i:\openpilot\docs\guides")) {
    New-Item -ItemType Directory -Path "i:\openpilot\docs\guides" -Force | Out-Null
}
if (-not (Test-Path "i:\openpilot\docs\testing")) {
    New-Item -ItemType Directory -Path "i:\openpilot\docs\testing" -Force | Out-Null
}
if (-not (Test-Path "i:\openpilot\docs\build")) {
    New-Item -ItemType Directory -Path "i:\openpilot\docs\build" -Force | Out-Null
}

# Move guides to docs/guides
$guides = @("COMPLETE-SETUP-GUIDE.md", "SETUP-EXTENSION.md", "VSCODE_EXTENSION_USAGE_GUIDE.md", "INSTALL.md")
foreach ($guide in $guides) {
    if (Test-Path "i:\openpilot\$guide") {
        Move-Item -Path "i:\openpilot\$guide" -Destination "i:\openpilot\docs\guides\" -Force
        Write-Host "   Moved: $guide -> docs/guides/" -ForegroundColor Green
    }
}

# Move testing docs to docs/testing
$testDocs = @("COMPREHENSIVE_TEST_COVERAGE_AND_REQUIREMENTS.md", "TEST_IMPLEMENTATION_COMPLETE.md", "DOCKER_TESTING.md", "README_TESTS.md")
foreach ($doc in $testDocs) {
    if (Test-Path "i:\openpilot\$doc") {
        Move-Item -Path "i:\openpilot\$doc" -Destination "i:\openpilot\docs\testing\" -Force
        Write-Host "   Moved: $doc -> docs/testing/" -ForegroundColor Green
    }
}

# Step 5: Organize scripts
Write-Host "`n STEP 5: Organizing build scripts..." -ForegroundColor Yellow
if (-not (Test-Path "i:\openpilot\scripts\build")) {
    New-Item -ItemType Directory -Path "i:\openpilot\scripts\build" -Force | Out-Null
}

$buildScripts = @(
    "build-local.ps1",
    "build-local.sh",
    "local-container-build.ps1",
    "docker-build-installers.ps1",
    "podman-build-installers.ps1",
    "create-artifacts.ps1",
    "create-installers.ps1",
    "generate-installers.ps1",
    "build-artifacts.ps1",
    "quick-build.ps1"
)

foreach ($script in $buildScripts) {
    if (Test-Path "i:\openpilot\$script") {
        Copy-Item -Path "i:\openpilot\$script" -Destination "i:\openpilot\scripts\build\" -Force
        Write-Host "   Copied: $script -> scripts/build/" -ForegroundColor Green
    }
}

# Step 6: Clean node_modules and reinstall
Write-Host "`n STEP 6: Cleaning and reinstalling dependencies..." -ForegroundColor Yellow
$projectDirs = @("core", "vscode-extension", "desktop", "web", "mobile", "tests")
foreach ($dir in $projectDirs) {
    $path = "i:\openpilot\$dir"
    if (Test-Path "$path\package.json") {
        Write-Host "   Processing: $dir" -ForegroundColor Cyan
        
        # Remove node_modules
        if (Test-Path "$path\node_modules") {
            Remove-Item -Path "$path\node_modules" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Remove package-lock.json
        if (Test-Path "$path\package-lock.json") {
            Remove-Item -Path "$path\package-lock.json" -Force
        }
    }
}

# Step 7: Update .gitignore
Write-Host "`n STEP 7: Updating .gitignore..." -ForegroundColor Yellow
$gitignoreAdditions = @"

# Cleanup - Additional ignores
artifacts-local/
build-output/
installers-output/
docker-installers-output/
temp-vsix-check/
manual-vsix-build/
final-check/
x/
*.backup
openpilot-backup-*/

# Test outputs
*.test.log
test-results/
playwright-report/
"@

Add-Content -Path "i:\openpilot\.gitignore" -Value $gitignoreAdditions
Write-Host "   Updated .gitignore" -ForegroundColor Green

Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  Cleanup Complete!                                  ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Removed temporary directories: $($toRemove.Directories.Count)" -ForegroundColor White
Write-Host "  Removed duplicate files: $($toRemove.Files.Count)" -ForegroundColor White
Write-Host "  Organized documentation into docs/" -ForegroundColor White
Write-Host "  Organized scripts into scripts/" -ForegroundColor White
Write-Host "  Cleaned node_modules from all projects" -ForegroundColor White
Write-Host "`nNext: Run cleanup-and-test-all.ps1 to rebuild and test" -ForegroundColor Yellow
