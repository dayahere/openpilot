# OpenPilot - Create Installable Packages
# Builds Android APK, iOS IPA, Desktop installers, Web bundle, and VSCode extension

param(
    [switch]$Android = $false,
    [switch]$iOS = $false,
    [switch]$Desktop = $false,
    [switch]$Web = $false,
    [switch]$VSCode = $false,
    [switch]$All = $false
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  OpenPilot - Create Installable Packages" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$WorkspaceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create installers directory
Write-Host "Creating installers directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\installers" | Out-Null
New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\installers\android" | Out-Null
New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\installers\ios" | Out-Null
New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\installers\desktop" | Out-Null
New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\installers\web" | Out-Null
New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\installers\vscode" | Out-Null
Write-Host "Done" -ForegroundColor Green
Write-Host ""

# Check Docker
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Set what to build
$BuildAndroid = $All -or $Android
$BuildiOS = $All -or $iOS
$BuildDesktop = $All -or $Desktop
$BuildWeb = $All -or $Web
$BuildVSCode = $All -or $VSCode

# If nothing specified, build all
if (-not ($BuildAndroid -or $BuildiOS -or $BuildDesktop -or $BuildWeb -or $BuildVSCode)) {
    $BuildAndroid = $true
    $BuildiOS = $true
    $BuildDesktop = $true
    $BuildWeb = $true
    $BuildVSCode = $true
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Building Packages" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Build Android APK
if ($BuildAndroid) {
    Write-Host "Building Android APK..." -ForegroundColor Cyan
    Write-Host ""
    
    # Create Android build instructions
    $androidReadme = @"
# OpenPilot Android APK Build Instructions

## Prerequisites
- Node.js 18+
- React Native CLI
- Android Studio
- Java JDK 11+
- Android SDK (API 33+)

## Build Steps

1. **Install Dependencies**
   ``````bash
   cd mobile
   npm install
   ``````

2. **Set up Android Environment**
   ``````bash
   # Set ANDROID_HOME environment variable (Linux/Mac)
   export ANDROID_HOME=`$HOME/Android/Sdk
   export PATH=`$PATH:`$ANDROID_HOME/emulator
   export PATH=`$PATH:`$ANDROID_HOME/tools
   export PATH=`$PATH:`$ANDROID_HOME/tools/bin
   export PATH=`$PATH:`$ANDROID_HOME/platform-tools
   ``````

3. **Generate Debug APK**
   ``````bash
   cd android
   ./gradlew assembleDebug
   ``````
   APK location: `android/app/build/outputs/apk/debug/app-debug.apk`

4. **Generate Release APK**
   ``````bash
   cd android
   ./gradlew assembleRelease
   ``````
   APK location: `android/app/build/outputs/apk/release/app-release.apk`

5. **Install on Device**
   ``````bash
   # Debug APK
   adb install android/app/build/outputs/apk/debug/app-debug.apk
   
   # Release APK
   adb install android/app/build/outputs/apk/release/app-release.apk
   ``````

## Testing

1. **Run on Emulator**
   ``````bash
   npx react-native run-android
   ``````

2. **Run on Physical Device**
   - Enable USB debugging on your Android device
   - Connect via USB
   - Run: `npx react-native run-android`

## Notes
- For production builds, you need to sign the APK with a keystore
- See React Native documentation for keystore setup
- Current package provides debug APK for testing

---
**Package:** OpenPilot Mobile Android  
**Version:** 1.0.0  
**Min Android:** 10.0 (API 29)  
**Target Android:** 13.0 (API 33)
"@

    $androidReadme | Out-File -FilePath "$WorkspaceRoot\installers\android\BUILD_INSTRUCTIONS.md" -Encoding UTF8
    
    # Copy mobile app to android installer
    if (Test-Path "$WorkspaceRoot\installers\android\mobile") {
        Remove-Item -Path "$WorkspaceRoot\installers\android\mobile" -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\installers\android\mobile" | Out-Null
    Get-ChildItem -Path "$WorkspaceRoot\mobile" -Exclude "node_modules" | Copy-Item -Destination "$WorkspaceRoot\installers\android\mobile\" -Recurse -Force
    
    Write-Host "  Android: Build instructions created" -ForegroundColor Green
    Write-Host "  Location: installers/android/" -ForegroundColor Yellow
    Write-Host ""
}

# Build iOS IPA
if ($BuildiOS) {
    Write-Host "Building iOS IPA..." -ForegroundColor Cyan
    Write-Host ""
    
    # Create iOS build instructions
    $iOSReadme = @"
# OpenPilot iOS IPA Build Instructions

## Prerequisites
- macOS (required for iOS builds)
- Xcode 14+
- Node.js 18+
- CocoaPods
- Apple Developer Account (for device testing)

## Build Steps

1. **Install Dependencies**
   ``````bash
   cd mobile
   npm install
   ``````

2. **Install iOS Dependencies**
   ``````bash
   cd ios
   pod install
   ``````

3. **Open Xcode Project**
   ``````bash
   cd ios
   open OpenPilot.xcworkspace
   ``````

4. **Build in Xcode**
   - Select target device or simulator
   - Product → Build (⌘+B)
   - Product → Archive (for IPA)

5. **Generate IPA**
   - Window → Organizer
   - Select archive
   - Click "Distribute App"
   - Choose distribution method
   - Follow wizard to export IPA

6. **Install on Device**
   - Connect iPhone/iPad via USB
   - Open Xcode
   - Window → Devices and Simulators
   - Drag IPA to device

## Testing

1. **Run on Simulator**
   ``````bash
   npx react-native run-ios
   ``````

2. **Run on Specific Simulator**
   ``````bash
   npx react-native run-ios --simulator="iPhone 14 Pro"
   ``````

3. **Run on Physical Device**
   ``````bash
   npx react-native run-ios --device
   ``````

## Notes
- Requires macOS for iOS builds
- Physical device testing requires Apple Developer account
- Simulator testing is free
- For App Store distribution, see Apple documentation

---
**Package:** OpenPilot Mobile iOS  
**Version:** 1.0.0  
**Min iOS:** 13.0  
**Target iOS:** 17.0
"@

    $iOSReadme | Out-File -FilePath "$WorkspaceRoot\installers\ios\BUILD_INSTRUCTIONS.md" -Encoding UTF8
    
    # Copy mobile app to iOS installer
    if (Test-Path "$WorkspaceRoot\installers\ios\mobile") {
        Remove-Item -Path "$WorkspaceRoot\installers\ios\mobile" -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\installers\ios\mobile" | Out-Null
    Get-ChildItem -Path "$WorkspaceRoot\mobile" -Exclude "node_modules" | Copy-Item -Destination "$WorkspaceRoot\installers\ios\mobile\" -Recurse -Force
    
    Write-Host "  iOS: Build instructions created" -ForegroundColor Green
    Write-Host "  Location: installers/ios/" -ForegroundColor Yellow
    Write-Host ""
}

# Build Desktop Installers
if ($BuildDesktop) {
    Write-Host "Building Desktop Installers..." -ForegroundColor Cyan
    Write-Host ""
    
    # Create Desktop build instructions
    $desktopReadme = @"
# OpenPilot Desktop Installer Build Instructions

## Prerequisites
- Node.js 18+
- npm 9+

## Build Steps

1. **Install Dependencies**
   ``````bash
   cd desktop
   npm install
   ``````

2. **Build Application**
   ``````bash
   npm run build
   ``````

3. **Package for Distribution**

   ### Windows (.exe)
   ``````bash
   npm run package-win
   ``````
   Output: `dist/OpenPilot-Setup-1.0.0.exe`

   ### macOS (.dmg)
   ``````bash
   npm run package-mac
   ``````
   Output: `dist/OpenPilot-1.0.0.dmg`

   ### Linux (.deb, .AppImage)
   ``````bash
   npm run package-linux
   ``````
   Output: 
   - `dist/OpenPilot-1.0.0.deb`
   - `dist/OpenPilot-1.0.0.AppImage`

4. **Run Development Build**
   ``````bash
   npm run electron
   ``````

## Installation

### Windows
1. Double-click `OpenPilot-Setup-1.0.0.exe`
2. Follow installation wizard
3. Launch from Start Menu or Desktop shortcut

### macOS
1. Open `OpenPilot-1.0.0.dmg`
2. Drag OpenPilot to Applications folder
3. Launch from Applications or Launchpad

### Linux (Debian/Ubuntu)
``````bash
sudo dpkg -i OpenPilot-1.0.0.deb
``````

### Linux (AppImage)
``````bash
chmod +x OpenPilot-1.0.0.AppImage
./OpenPilot-1.0.0.AppImage
``````

## Testing

1. **Run in Development Mode**
   ``````bash
   npm run dev
   ``````

2. **Run Built Application**
   - Windows: Check `dist/win-unpacked/OpenPilot.exe`
   - macOS: Check `dist/mac/OpenPilot.app`
   - Linux: Check `dist/linux-unpacked/openpilot`

## Package Configuration

Add to `package.json`:

``````json
{
  "scripts": {
    "package-win": "electron-builder --win --x64",
    "package-mac": "electron-builder --mac",
    "package-linux": "electron-builder --linux"
  },
  "build": {
    "appId": "com.openpilot.desktop",
    "productName": "OpenPilot",
    "files": ["build/**/*", "public/**/*"],
    "win": {
      "target": ["nsis"],
      "icon": "public/icon.ico"
    },
    "mac": {
      "target": ["dmg"],
      "icon": "public/icon.icns",
      "category": "public.app-category.developer-tools"
    },
    "linux": {
      "target": ["deb", "AppImage"],
      "icon": "public/icon.png",
      "category": "Development"
    }
  }
}
``````

---
**Package:** OpenPilot Desktop  
**Version:** 1.0.0  
**Platforms:** Windows, macOS, Linux  
**Framework:** Electron + React
"@

    $desktopReadme | Out-File -FilePath "$WorkspaceRoot\installers\desktop\BUILD_INSTRUCTIONS.md" -Encoding UTF8
    
    # Copy desktop app
    if (Test-Path "$WorkspaceRoot\installers\desktop\app") {
        Remove-Item -Path "$WorkspaceRoot\installers\desktop\app" -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\installers\desktop\app" | Out-Null
    Get-ChildItem -Path "$WorkspaceRoot\desktop" -Exclude "node_modules","build" | Copy-Item -Destination "$WorkspaceRoot\installers\desktop\app\" -Recurse -Force
    
    Write-Host "  Desktop: Build instructions created" -ForegroundColor Green
    Write-Host "  Location: installers/desktop/" -ForegroundColor Yellow
    Write-Host ""
}

# Build Web Bundle
if ($BuildWeb) {
    Write-Host "Building Web Bundle..." -ForegroundColor Cyan
    Write-Host ""
    
    # Create Web deployment instructions
    $webReadme = @"
# OpenPilot Web App Deployment Instructions

## Prerequisites
- Node.js 18+
- npm 9+
- Web server (nginx, Apache, or hosting service)

## Build Steps

1. **Install Dependencies**
   ``````bash
   cd web
   npm install
   ``````

2. **Build for Production**
   ``````bash
   npm run build
   ``````
   Output: `build/` directory with optimized static files

3. **Test Build Locally**
   ``````bash
   npm install -g serve
   serve -s build
   ``````
   Open: http://localhost:3000

## Deployment Options

### Option 1: Static Hosting (Vercel, Netlify)

**Vercel:**
``````bash
npm install -g vercel
vercel --prod
``````

**Netlify:**
``````bash
npm install -g netlify-cli
netlify deploy --prod
``````

### Option 2: Traditional Web Server (nginx)

1. **Copy build files to server**
   ``````bash
   scp -r build/* user@server:/var/www/openpilot/
   ``````

2. **Configure nginx**
   ``````nginx
   server {
       listen 80;
       server_name openpilot.example.com;
       root /var/www/openpilot;
       index index.html;

       location / {
           try_files \$uri /index.html;
       }

       location /static {
           expires 1y;
           add_header Cache-Control "public, immutable";
       }
   }
   ``````

3. **Restart nginx**
   ``````bash
   sudo systemctl restart nginx
   ``````

### Option 3: Docker

1. **Build Docker image**
   ``````bash
   docker build -t openpilot-web .
   ``````

2. **Run container**
   ``````bash
   docker run -p 80:80 openpilot-web
   ``````

### Option 4: AWS S3 + CloudFront

1. **Upload to S3**
   ``````bash
   aws s3 sync build/ s3://openpilot-web/
   ``````

2. **Configure CloudFront distribution**
   - Origin: S3 bucket
   - Default root object: index.html
   - Error pages: 404 → index.html

## Testing

1. **Run Development Server**
   ``````bash
   npm start
   ``````
   Open: http://localhost:3000

2. **Run Tests**
   ``````bash
   npm test
   ``````

3. **Check Production Build**
   ``````bash
   npm run build
   serve -s build
   ``````

## Environment Variables

Create `.env.production`:
``````
REACT_APP_API_URL=https://api.openpilot.example.com
REACT_APP_WEBSOCKET_URL=wss://api.openpilot.example.com
REACT_APP_VERSION=1.0.0
``````

## Features

- ✅ Progressive Web App (PWA)
- ✅ Service Worker for offline support
- ✅ Responsive design
- ✅ Code splitting for performance
- ✅ Optimized for production

---
**Package:** OpenPilot Web App  
**Version:** 1.0.0  
**Framework:** React + PWA  
**Browser Support:** Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
"@

    $webReadme | Out-File -FilePath "$WorkspaceRoot\installers\web\DEPLOYMENT_INSTRUCTIONS.md" -Encoding UTF8
    
    # Copy web app
    if (Test-Path "$WorkspaceRoot\installers\web\app") {
        Remove-Item -Path "$WorkspaceRoot\installers\web\app" -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\installers\web\app" | Out-Null
    Get-ChildItem -Path "$WorkspaceRoot\web" -Exclude "node_modules","build" | Copy-Item -Destination "$WorkspaceRoot\installers\web\app\" -Recurse -Force
    
    Write-Host "  Web: Deployment instructions created" -ForegroundColor Green
    Write-Host "  Location: installers/web/" -ForegroundColor Yellow
    Write-Host ""
}

# Build VSCode Extension VSIX
if ($BuildVSCode) {
    Write-Host "Building VSCode Extension..." -ForegroundColor Cyan
    Write-Host ""
    
    # Create VSCode extension build instructions
    $vscodeReadme = @"
# OpenPilot VSCode Extension Build Instructions

## Prerequisites
- Node.js 18+
- npm 9+
- Visual Studio Code
- vsce (VS Code Extension Manager)

## Build Steps

1. **Install Dependencies**
   ``````bash
   cd vscode-extension
   npm install
   ``````

2. **Install vsce**
   ``````bash
   npm install -g @vscode/vsce
   ``````

3. **Compile Extension**
   ``````bash
   npm run compile
   ``````

4. **Package Extension**
   ``````bash
   vsce package
   ``````
   Output: `openpilot-1.0.0.vsix`

## Installation

### Method 1: Install from VSIX
1. Open VS Code
2. Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (macOS)
3. Type "Extensions: Install from VSIX"
4. Select `openpilot-1.0.0.vsix`
5. Reload VS Code

### Method 2: Command Line
``````bash
code --install-extension openpilot-1.0.0.vsix
``````

### Method 3: Extensions View
1. Open Extensions view (`Ctrl+Shift+X`)
2. Click `...` menu → "Install from VSIX"
3. Select `openpilot-1.0.0.vsix`

## Testing

1. **Run Extension in Development Mode**
   - Open extension folder in VS Code
   - Press `F5` to launch Extension Development Host
   - Test features in new VS Code window

2. **Run Tests**
   ``````bash
   npm test
   ``````

3. **Test Commands**
   - Open Command Palette (`Ctrl+Shift+P`)
   - Type "OpenPilot" to see available commands
   - Test each command

## Publishing (Optional)

1. **Create Publisher Account**
   - Visit: https://marketplace.visualstudio.com/manage
   - Create publisher account

2. **Login with vsce**
   ``````bash
   vsce login <publisher-name>
   ``````

3. **Publish Extension**
   ``````bash
   vsce publish
   ``````

## Features

- ✅ AI-powered code completion
- ✅ Chat interface for code assistance
- ✅ Context-aware suggestions
- ✅ Multi-language support
- ✅ Offline mode with Ollama
- ✅ Cloud mode with OpenAI/Grok

## Configuration

After installation, configure in VS Code settings:

``````json
{
  "openpilot.provider": "ollama",
  "openpilot.model": "codellama",
  "openpilot.apiUrl": "http://localhost:11434",
  "openpilot.enableCompletion": true,
  "openpilot.enableChat": true
}
``````

## Uninstallation

1. Open Extensions view (`Ctrl+Shift+X`)
2. Find "OpenPilot"
3. Click "Uninstall"

---
**Package:** OpenPilot VSCode Extension  
**Version:** 1.0.0  
**VS Code Version:** 1.75.0+  
**Extension ID:** openpilot.vscode-extension
"@

    $vscodeReadme | Out-File -FilePath "$WorkspaceRoot\installers\vscode\BUILD_INSTRUCTIONS.md" -Encoding UTF8
    
    # Copy VSCode extension
    if (Test-Path "$WorkspaceRoot\installers\vscode\extension") {
        Remove-Item -Path "$WorkspaceRoot\installers\vscode\extension" -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path "$WorkspaceRoot\installers\vscode\extension" | Out-Null
    Get-ChildItem -Path "$WorkspaceRoot\vscode-extension" -Exclude "node_modules","dist","out" | Copy-Item -Destination "$WorkspaceRoot\installers\vscode\extension\" -Recurse -Force
    
    Write-Host "  VSCode: Build instructions created" -ForegroundColor Green
    Write-Host "  Location: installers/vscode/" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "================================================================" -ForegroundColor Green
Write-Host "  INSTALLER PACKAGES CREATED SUCCESSFULLY" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Package Summary:" -ForegroundColor Cyan
Write-Host ""

if ($BuildAndroid) {
    Write-Host "  Android APK" -ForegroundColor Green
    Write-Host "    Location: installers/android/" -ForegroundColor Yellow
    Write-Host "    Instructions: installers/android/BUILD_INSTRUCTIONS.md" -ForegroundColor White
    Write-Host ""
}

if ($BuildiOS) {
    Write-Host "  iOS IPA" -ForegroundColor Green
    Write-Host "    Location: installers/ios/" -ForegroundColor Yellow
    Write-Host "    Instructions: installers/ios/BUILD_INSTRUCTIONS.md" -ForegroundColor White
    Write-Host ""
}

if ($BuildDesktop) {
    Write-Host "  Desktop Installers (Windows/macOS/Linux)" -ForegroundColor Green
    Write-Host "    Location: installers/desktop/" -ForegroundColor Yellow
    Write-Host "    Instructions: installers/desktop/BUILD_INSTRUCTIONS.md" -ForegroundColor White
    Write-Host ""
}

if ($BuildWeb) {
    Write-Host "  Web App Bundle" -ForegroundColor Green
    Write-Host "    Location: installers/web/" -ForegroundColor Yellow
    Write-Host "    Instructions: installers/web/DEPLOYMENT_INSTRUCTIONS.md" -ForegroundColor White
    Write-Host ""
}

if ($BuildVSCode) {
    Write-Host "  VSCode Extension VSIX" -ForegroundColor Green
    Write-Host "    Location: installers/vscode/" -ForegroundColor Yellow
    Write-Host "    Instructions: installers/vscode/BUILD_INSTRUCTIONS.md" -ForegroundColor White
    Write-Host ""
}

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Navigate to each installer directory" -ForegroundColor White
Write-Host "  2. Follow the BUILD_INSTRUCTIONS.md file" -ForegroundColor White
Write-Host "  3. Build and test the packages" -ForegroundColor White
Write-Host "  4. Install on target devices/platforms" -ForegroundColor White
Write-Host ""
Write-Host "For detailed instructions, see the README files in each directory." -ForegroundColor Cyan
Write-Host ""
