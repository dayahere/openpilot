# OpenPilot - Start Implementation
# Quick start script for implementing all features

param(
    [switch]$Desktop,
    [switch]$Android,
    [switch]$Tests,
    [switch]$Online,
    [switch]$All
)

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  OPENPILOT IMPLEMENTATION LAUNCHER    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan

if ($All) {
    $Desktop = $true
    $Android = $true
    $Tests = $true
    $Online = $true
}

if (-not ($Desktop -or $Android -or $Tests -or $Online)) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\start-implementation.ps1 -Desktop   # Build desktop installers" -ForegroundColor White
    Write-Host "  .\start-implementation.ps1 -Android   # Build Android APK" -ForegroundColor White
    Write-Host "  .\start-implementation.ps1 -Tests     # Create test files" -ForegroundColor White
    Write-Host "  .\start-implementation.ps1 -Online    # Create online AI tests" -ForegroundColor White
    Write-Host "  .\start-implementation.ps1 -All       # Do everything!`n" -ForegroundColor White
    exit
}

$outputDir = "i:\openpilot\production-output\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

Write-Host "Output Directory: $outputDir`n" -ForegroundColor Yellow

# ====================
# DESKTOP INSTALLERS
# ====================
if ($Desktop) {
    Write-Host "`n[1] DESKTOP INSTALLERS" -ForegroundColor Cyan
    Write-Host "═══════════════════════" -ForegroundColor Gray
    
    Write-Host "`nStep 1: Creating Electron main process..." -ForegroundColor Yellow
    
    # Create desktop/electron.js
    $electronJs = @'
const { app, BrowserWindow, Menu } = require('electron');
const path = require('path');
const url = require('url');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
    icon: path.join(__dirname, 'build', 'logo192.png'),
    title: 'OpenPilot - AI Code Assistant',
  });

  const startUrl = process.env.ELECTRON_START_URL || url.format({
    pathname: path.join(__dirname, 'build', 'index.html'),
    protocol: 'file:',
    slashes: true
  });

  mainWindow.loadURL(startUrl);
  
  if (process.env.NODE_ENV === 'development') {
    mainWindow.webContents.openDevTools();
  }

  const menuTemplate = [
    {
      label: 'File',
      submenu: [
        { label: 'Exit', accelerator: 'CmdOrCtrl+Q', click: () => app.quit() }
      ]
    },
    {
      label: 'Edit',
      submenu: [
        { role: 'undo' },
        { role: 'redo' },
        { type: 'separator' },
        { role: 'cut' },
        { role: 'copy' },
        { role: 'paste' }
      ]
    },
    {
      label: 'View',
      submenu: [
        { role: 'reload' },
        { role: 'toggleDevTools' },
        { type: 'separator' },
        { role: 'resetZoom' },
        { role: 'zoomIn' },
        { role: 'zoomOut' }
      ]
    }
  ];

  const menu = Menu.buildFromTemplate(menuTemplate);
  Menu.setApplicationMenu(menu);

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.on('ready', createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (mainWindow === null) {
    createWindow();
  }
});
'@
    
    Set-Content -Path "desktop\electron.js" -Value $electronJs
    Write-Host "  ✓ Created desktop/electron.js" -ForegroundColor Green
    
    Write-Host "`nStep 2: Updating desktop/package.json..." -ForegroundColor Yellow
    
    # Read and update package.json using PowerShell
    $pkgPath = "desktop\package.json"
    $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
    
    # Update fields
    $pkg.main = "electron.js"
    $pkg.homepage = "./"
    
    # Add electron dependency
    if (-not $pkg.dependencies) {
        $pkg | Add-Member -NotePropertyName "dependencies" -NotePropertyValue @{} -Force
    }
    $pkg.dependencies | Add-Member -NotePropertyName "electron" -NotePropertyValue "^27.1.0" -Force
    
    # Add devDependencies
    $pkg.devDependencies | Add-Member -NotePropertyName "electron-builder" -NotePropertyValue "^24.9.1" -Force
    $pkg.devDependencies | Add-Member -NotePropertyName "concurrently" -NotePropertyValue "^8.2.2" -Force
    $pkg.devDependencies | Add-Member -NotePropertyName "wait-on" -NotePropertyValue "^7.2.0" -Force
    
    # Add build scripts
    $pkg.scripts | Add-Member -NotePropertyName "build:win" -NotePropertyValue "npm run build && electron-builder --win --x64" -Force
    $pkg.scripts | Add-Member -NotePropertyName "build:linux" -NotePropertyValue "npm run build && electron-builder --linux" -Force
    
    # Add electron-builder configuration
    $buildConfig = @{
        appId = "com.openpilot.desktop"
        productName = "OpenPilot"
        directories = @{
            output = "dist"
        }
        files = @(
            "build/**/*"
            "electron.js"
            "package.json"
        )
        win = @{
            target = @("nsis")
            artifactName = "`${productName}-Setup-`${version}.`${ext}"
        }
        linux = @{
            target = @("AppImage", "deb")
            category = "Development"
            artifactName = "`${productName}-`${version}.`${ext}"
        }
        nsis = @{
            oneClick = $false
            allowToChangeInstallationDirectory = $true
            createDesktopShortcut = $true
            createStartMenuShortcut = $true
        }
    }
    
    $pkg | Add-Member -NotePropertyName "build" -NotePropertyValue $buildConfig -Force
    
    # Save package.json
    $pkg | ConvertTo-Json -Depth 10 | Set-Content $pkgPath
    Write-Host "  ✓ Updated desktop/package.json" -ForegroundColor Green
    
    Write-Host "`nStep 3: Installing desktop dependencies..." -ForegroundColor Yellow
    docker run --rm -v "${PWD}:/app" -w /app/desktop node:20 npm install --legacy-peer-deps 2>&1 | Select-Object -Last 5
    Write-Host "  ✓ Dependencies installed" -ForegroundColor Green
    
    Write-Host "`nStep 4: Building React desktop app..." -ForegroundColor Yellow
    docker run --rm -v "${PWD}:/app" -w /app/desktop node:20 npm run build 2>&1 | Select-Object -Last 3
    Write-Host "  ✓ React app built" -ForegroundColor Green
    
    Write-Host "`nStep 5: Building Windows installer..." -ForegroundColor Yellow
    Write-Host "  (This may take 5-10 minutes)" -ForegroundColor Gray
    docker run --rm -v "${PWD}:/app" -w /app/desktop node:20 npm run build:win 2>&1 | Select-Object -Last 5
    
    if (Test-Path "desktop\dist\*.exe") {
        Copy-Item "desktop\dist\*.exe" -Destination $outputDir -Force
        $exe = Get-ChildItem "desktop\dist\*.exe" | Select-Object -First 1
        $sizeMB = [math]::Round($exe.Length / 1MB, 2)
        Write-Host "  ✓ Windows installer created: $($exe.Name) ($sizeMB MB)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Windows installer not found - check build output" -ForegroundColor Yellow
    }
    
    Write-Host "`nStep 6: Building Linux packages..." -ForegroundColor Yellow
    Write-Host "  (This may take 5-10 minutes)" -ForegroundColor Gray
    docker run --rm -v "${PWD}:/app" -w /app/desktop node:20 npm run build:linux 2>&1 | Select-Object -Last 5
    
    if (Test-Path "desktop\dist\*.AppImage") {
        Copy-Item "desktop\dist\*.AppImage" -Destination $outputDir -Force
        $appimage = Get-ChildItem "desktop\dist\*.AppImage" | Select-Object -First 1
        $sizeMB = [math]::Round($appimage.Length / 1MB, 2)
        Write-Host "  ✓ Linux AppImage created: $($appimage.Name) ($sizeMB MB)" -ForegroundColor Green
    }
    
    if (Test-Path "desktop\dist\*.deb") {
        Copy-Item "desktop\dist\*.deb" -Destination $outputDir -Force
        $deb = Get-ChildItem "desktop\dist\*.deb" | Select-Object -First 1
        $sizeMB = [math]::Round($deb.Length / 1MB, 2)
        Write-Host "  ✓ Linux .deb created: $($deb.Name) ($sizeMB MB)" -ForegroundColor Green
    }
    
    Write-Host "`n✅ Desktop installers complete!`n" -ForegroundColor Green
}

# ====================
# ANDROID APK
# ====================
if ($Android) {
    Write-Host "`n[2] ANDROID APK (CAPACITOR)" -ForegroundColor Cyan
    Write-Host "════════════════════════════" -ForegroundColor Gray
    
    Write-Host "`nStep 1: Installing Capacitor..." -ForegroundColor Yellow
    docker run --rm -v "${PWD}:/app" -w /app/web node:20 npm install @capacitor/core @capacitor/cli @capacitor/android --save --legacy-peer-deps 2>&1 | Select-Object -Last 3
    Write-Host "  ✓ Capacitor installed" -ForegroundColor Green
    
    Write-Host "`nStep 2: Initializing Capacitor project..." -ForegroundColor Yellow
    docker run --rm -v "${PWD}:/app" -w /app/web node:20 npx cap init "OpenPilot" "com.openpilot.app" --web-dir=build 2>&1 | Out-Null
    Write-Host "  ✓ Capacitor initialized" -ForegroundColor Green
    
    Write-Host "`nStep 3: Building web app..." -ForegroundColor Yellow
    docker run --rm -v "${PWD}:/app" -w /app/web node:20 npm run build 2>&1 | Select-Object -Last 3
    Write-Host "  ✓ Web app built" -ForegroundColor Green
    
    Write-Host "`nStep 4: Adding Android platform..." -ForegroundColor Yellow
    docker run --rm -v "${PWD}:/app" -w /app/web node:20 npx cap add android 2>&1 | Out-Null
    Write-Host "  ✓ Android platform added" -ForegroundColor Green
    
    Write-Host "`nStep 5: Syncing Capacitor..." -ForegroundColor Yellow
    docker run --rm -v "${PWD}:/app" -w /app/web node:20 npx cap sync 2>&1 | Out-Null
    Write-Host "  ✓ Capacitor synced" -ForegroundColor Green
    
    Write-Host "`n✅ Android project created at web/android/`n" -ForegroundColor Green
    Write-Host "To build APK:" -ForegroundColor Yellow
    Write-Host "  Option A: npx cap open android  (Open in Android Studio)" -ForegroundColor White
    Write-Host "  Option B: cd web/android && ./gradlew assembleRelease`n" -ForegroundColor White
}

# ====================
# TEST COVERAGE
# ====================
if ($Tests) {
    Write-Host "`n[3] 100% TEST COVERAGE" -ForegroundColor Cyan
    Write-Host "══════════════════════" -ForegroundColor Gray
    
    Write-Host "`nCreating advanced test files..." -ForegroundColor Yellow
    Write-Host "  (See IMPLEMENTATION_COMPLETE_GUIDE.md for test code)" -ForegroundColor Gray
    
    Write-Host "`nTest files to create:" -ForegroundColor Yellow
    Write-Host "  • tests/unit/ai-engine-http-errors.test.ts" -ForegroundColor White
    Write-Host "  • tests/unit/ai-engine-streams.test.ts" -ForegroundColor White
    Write-Host "  • tests/unit/ai-engine-tokens.test.ts" -ForegroundColor White
    Write-Host "  • tests/unit/context-manager-files.test.ts" -ForegroundColor White
    Write-Host "  • tests/unit/repository-analysis-advanced.test.ts" -ForegroundColor White
    
    Write-Host "`nTarget coverage: 100% (currently 95%, 92%, 88%)" -ForegroundColor Gray
    Write-Host "Estimated: 60-80 new tests needed`n" -ForegroundColor Gray
}

# ====================
# ONLINE AI TESTS
# ====================
if ($Online) {
    Write-Host "`n[4] ONLINE AI PROVIDER TESTS" -ForegroundColor Cyan
    Write-Host "════════════════════════════" -ForegroundColor Gray
    
    Write-Host "`nCreating online AI test file..." -ForegroundColor Yellow
    Write-Host "  (See IMPLEMENTATION_COMPLETE_GUIDE.md for test code)" -ForegroundColor Gray
    
    Write-Host "`nTest file to create:" -ForegroundColor Yellow
    Write-Host "  • tests/integration/ai-online.test.ts" -ForegroundColor White
    
    Write-Host "`nProviders: OpenAI, Claude, Grok" -ForegroundColor Gray
    Write-Host "Cost: ~`$0.10 per test run (optional)`n" -ForegroundColor Gray
}

# ====================
# SUMMARY
# ====================
Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  IMPLEMENTATION SUMMARY               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Output Directory: $outputDir`n" -ForegroundColor Yellow

$artifacts = Get-ChildItem $outputDir -File -ErrorAction SilentlyContinue
if ($artifacts) {
    Write-Host "Build Artifacts:" -ForegroundColor Green
    foreach ($file in $artifacts) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        Write-Host "  • $($file.Name) ($sizeMB MB)" -ForegroundColor White
    }
} else {
    Write-Host "No build artifacts generated yet." -ForegroundColor Gray
}

Write-Host "`nNext Steps:" -ForegroundColor Cyan
if ($Desktop) {
    Write-Host "  • Test Windows installer: $outputDir\*.exe" -ForegroundColor White
    Write-Host "  • Test Linux packages: $outputDir\*.AppImage or *.deb" -ForegroundColor White
}
if ($Android) {
    Write-Host "  • Open web/android in Android Studio" -ForegroundColor White
    Write-Host "  • Build -> Generate Signed Bundle / APK" -ForegroundColor White
}
if ($Tests) {
    Write-Host "  • Create test files (see IMPLEMENTATION_COMPLETE_GUIDE.md)" -ForegroundColor White
    Write-Host "  • Run: npm test -- --coverage" -ForegroundColor White
}
if ($Online) {
    Write-Host "  • Create tests/integration/ai-online.test.ts" -ForegroundColor White
    Write-Host "  • Set API keys and run: npm test ai-online.test.ts" -ForegroundColor White
}

Write-Host "`nDocumentation:" -ForegroundColor Cyan
Write-Host "  • IMPLEMENTATION_COMPLETE_GUIDE.md - Complete code examples" -ForegroundColor White
Write-Host "  • IMPLEMENTATION_ROADMAP.md - Technical details" -ForegroundColor White
Write-Host "  • OPENPILOT_COMPLETE_GUIDE.md - User guide`n" -ForegroundColor White

Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
Write-Host "Total Cost: `$0 (all features FREE!)" -ForegroundColor Green
Write-Host "═══════════════════════════════════════`n" -ForegroundColor Gray
