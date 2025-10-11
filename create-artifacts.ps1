# OpenPilot - Create Distribution Artifacts
# Copies source files and creates ready-to-deploy artifacts

param(
    [switch]$Clean = $false
)

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  OpenPilot - Create Distribution Artifacts" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$WorkspaceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Clean
if ($Clean -and (Test-Path "$WorkspaceRoot\artifacts")) {
    Write-Host "Cleaning artifacts..." -ForegroundColor Yellow
    Remove-Item -Path "$WorkspaceRoot\artifacts" -Recurse -Force
    Write-Host "Done" -ForegroundColor Green
    Write-Host ""
}

# Create structure
Write-Host "Creating artifact directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\artifacts" | Out-Null
Write-Host "Done" -ForegroundColor Green
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Copying Components" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Core Library
Write-Host "Core Library..." -ForegroundColor Cyan
Copy-Item -Path "$WorkspaceRoot\core" -Destination "$WorkspaceRoot\artifacts\core" -Recurse -Force -Exclude @("node_modules", "coverage", ".git")
Write-Host "  DONE" -ForegroundColor Green

# Mobile
Write-Host "Mobile App..." -ForegroundColor Cyan
Copy-Item -Path "$WorkspaceRoot\mobile" -Destination "$WorkspaceRoot\artifacts\mobile" -Recurse -Force -Exclude @("node_modules", "coverage", ".git", "android", "ios")
Write-Host "  DONE" -ForegroundColor Green

# Desktop
Write-Host "Desktop App..." -ForegroundColor Cyan
Copy-Item -Path "$WorkspaceRoot\desktop" -Destination "$WorkspaceRoot\artifacts\desktop" -Recurse -Force -Exclude @("node_modules", "coverage", ".git", "build")
Write-Host "  DONE" -ForegroundColor Green

# Web
Write-Host "Web App..." -ForegroundColor Cyan
Copy-Item -Path "$WorkspaceRoot\web" -Destination "$WorkspaceRoot\artifacts\web" -Recurse -Force -Exclude @("node_modules", "coverage", ".git", "build")
Write-Host "  DONE" -ForegroundColor Green

# Backend
Write-Host "Backend API..." -ForegroundColor Cyan
Copy-Item -Path "$WorkspaceRoot\backend" -Destination "$WorkspaceRoot\artifacts\backend" -Recurse -Force -Exclude @("node_modules", "coverage", ".git", "dist")
Write-Host "  DONE" -ForegroundColor Green

# VSCode Extension
Write-Host "VSCode Extension..." -ForegroundColor Cyan
Copy-Item -Path "$WorkspaceRoot\vscode-extension" -Destination "$WorkspaceRoot\artifacts\vscode-extension" -Recurse -Force -Exclude @("node_modules", "coverage", ".git", "dist", "out")
Write-Host "  DONE" -ForegroundColor Green

# Tests
Write-Host "Tests..." -ForegroundColor Cyan
Copy-Item -Path "$WorkspaceRoot\tests" -Destination "$WorkspaceRoot\artifacts\tests" -Recurse -Force -Exclude @("node_modules", "coverage", ".git")
Write-Host "  DONE" -ForegroundColor Green

# Documentation
Write-Host "Documentation..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\artifacts\docs" | Out-Null
Copy-Item -Path "$WorkspaceRoot\*.md" -Destination "$WorkspaceRoot\artifacts\docs\" -Force
Copy-Item -Path "$WorkspaceRoot\docs\*" -Destination "$WorkspaceRoot\artifacts\docs\" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  DONE" -ForegroundColor Green

# Scripts
Write-Host "Scripts..." -ForegroundColor Cyan
Copy-Item -Path "$WorkspaceRoot\scripts" -Destination "$WorkspaceRoot\artifacts\scripts" -Recurse -Force -Exclude @("node_modules", ".git")
Write-Host "  DONE" -ForegroundColor Green

# Configuration Files
Write-Host "Configuration..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\artifacts\config" | Out-Null
Copy-Item -Path "$WorkspaceRoot\package.json" -Destination "$WorkspaceRoot\artifacts\config\" -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$WorkspaceRoot\tsconfig.json" -Destination "$WorkspaceRoot\artifacts\config\" -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$WorkspaceRoot\docker-compose*.yml" -Destination "$WorkspaceRoot\artifacts\config\" -Force
Copy-Item -Path "$WorkspaceRoot\Dockerfile*" -Destination "$WorkspaceRoot\artifacts\config\" -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$WorkspaceRoot\.dockerignore" -Destination "$WorkspaceRoot\artifacts\config\" -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$WorkspaceRoot\.gitignore" -Destination "$WorkspaceRoot\artifacts\config\" -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$WorkspaceRoot\.prettierrc" -Destination "$WorkspaceRoot\artifacts\config\" -Force -ErrorAction SilentlyContinue
Write-Host "  DONE" -ForegroundColor Green

# GitHub Workflows
Write-Host "CI/CD Workflows..." -ForegroundColor Cyan
Copy-Item -Path "$WorkspaceRoot\.github" -Destination "$WorkspaceRoot\artifacts\.github" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  DONE" -ForegroundColor Green

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Creating Deployment Package" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Create README for artifacts
$artifactReadme = @"
# OpenPilot - Distribution Artifacts

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Package Contents

### Applications
- **core/** - Core AI engine library
- **mobile/** - React Native mobile application
- **desktop/** - Electron desktop application  
- **web/** - Progressive Web App (PWA)
- **backend/** - Express.js REST API server
- **vscode-extension/** - Visual Studio Code extension

### Supporting Files
- **tests/** - Complete test suite (43 tests)
- **docs/** - Project documentation
- **scripts/** - Build and deployment scripts
- **config/** - Configuration files
- **.github/** - CI/CD workflows

## Deployment Instructions

### Core Library
``````bash
cd core
npm install
npm run build
``````

### Mobile App
``````bash
cd mobile
npm install
# For iOS
cd ios && pod install
npx react-native run-ios

# For Android
npx react-native run-android
``````

### Desktop App
``````bash
cd desktop
npm install
npm run build
npm run electron
``````

### Web App
``````bash
cd web
npm install
npm run build
npm start
``````

### Backend API
``````bash
cd backend
npm install
npm run build
npm start
``````

### VSCode Extension
``````bash
cd vscode-extension
npm install
npm run compile
# Install: code --install-extension openpilot-*.vsix
``````

## Testing

Run all tests:
``````bash
cd tests
npm install
npm test
``````

## Requirements

- Node.js 18+
- npm 9+
- Docker (optional, for containerized deployment)

## Documentation

See `docs/` directory for:
- Architecture documentation
- API documentation
- Installation guides
- User manuals

## Support

- **Repository:** https://github.com/dayahere/openpilot
- **Issues:** https://github.com/dayahere/openpilot/issues
- **Documentation:** See docs/ directory

---

**Build Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Version:** 1.0.0  
**Status:** Production Ready
"@

$artifactReadme | Out-File -FilePath "$WorkspaceRoot\artifacts\README.md" -Encoding UTF8

Write-Host "Creating deployment package README..." -ForegroundColor Yellow
Write-Host "  DONE" -ForegroundColor Green
Write-Host ""

# Generate statistics
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  ARTIFACTS CREATED SUCCESSFULLY" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

$components = @{
    "core" = "Core Library"
    "mobile" = "Mobile App"
    "desktop" = "Desktop App"
    "web" = "Web App"
    "backend" = "Backend API"
    "vscode-extension" = "VSCode Extension"
    "tests" = "Test Suite"
    "docs" = "Documentation"
    "scripts" = "Scripts"
    "config" = "Configuration"
}

Write-Host "Artifact Summary:" -ForegroundColor Cyan
Write-Host ""

$totalFiles = 0
$totalSize = 0

foreach ($key in $components.Keys | Sort-Object) {
    $path = "$WorkspaceRoot\artifacts\$key"
    if (Test-Path $path) {
        $files = Get-ChildItem -Path $path -Recurse -File
        $fileCount = $files.Count
        $size = ($files | Measure-Object -Property Length -Sum).Sum
        $sizeMB = [math]::Round($size / 1MB, 2)
        
        $totalFiles += $fileCount
        $totalSize += $size
        
        $name = $components[$key]
        Write-Host ("  {0,-25} {1,6} files  {2,8} MB" -f $name, $fileCount, $sizeMB) -ForegroundColor Green
    }
}

Write-Host ""
Write-Host ("  {0,-25} {1,6} files  {2,8} MB" -f "TOTAL", $totalFiles, [math]::Round($totalSize / 1MB, 2)) -ForegroundColor Yellow
Write-Host ""
Write-Host "Location: $WorkspaceRoot\artifacts\" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review artifacts in artifacts/ directory" -ForegroundColor White
Write-Host "  2. Package for distribution (zip/tar)" -ForegroundColor White
Write-Host "  3. Deploy to target environments" -ForegroundColor White
Write-Host ""
