# 🚀 Local Container Build System - Complete Guide

## Overview

This guide shows you how to build **all OpenPilot installers locally** using Docker or Podman - **NO Node.js or npm installation required on your host machine!**

Similar to the Photo Studio build system you referenced, this approach:
- ✅ Uses containers for reproducible builds
- ✅ No local Node.js/npm dependencies needed  
- ✅ Builds all platforms in parallel
- ✅ Generates ready-to-distribute installers
- ✅ Includes automated testing

---

## 📦 What Gets Built

| Platform | Output | File Type | Test Method |
|----------|--------|-----------|-------------|
| **VSCode Extension** | `.vsix` | VS Code installer | Install in VS Code |
| **Web App** | `.tar.gz` | Static website | Serve with HTTP server |
| **Desktop App** | `.tar.gz` | Electron app files | Run with Electron |
| **Android App** | `.apk` | Android installer | Install on device |

---

## 🎯 Quick Start

### Prerequisites

**Only 1 requirement**: Docker or Podman installed

- **Docker**: [Download Docker Desktop](https://www.docker.com/products/docker-desktop)
- **Podman** (alternative): [Download Podman](https://podman.io/getting-started/installation)

That's it! No Node.js, npm, or other tools needed.

### Basic Usage

```powershell
# Build everything (takes 15-20 minutes first time)
.\local-container-build.ps1

# Build everything, skip tests (faster)
.\local-container-build.ps1 -SkipTests

# Build only specific platforms
.\local-container-build.ps1 -SkipAndroid  # Skip Android APK
.\local-container-build.ps1 -SkipDesktop  # Skip Desktop app
.\local-container-build.ps1 -SkipWeb      # Skip Web app
.\local-container-build.ps1 -SkipVSCode   # Skip VSCode extension

# Use Podman instead of Docker
.\local-container-build.ps1 -UsePodman

# Clean build (remove old artifacts)
.\local-container-build.ps1 -Clean
```

---

## 📋 Detailed Build Process

### Step-by-Step Breakdown

The script performs these steps:

1. **[1/10] Check Container Tool**
   - Verifies Docker/Podman is installed
   - Shows version information

2. **[2/10] Create Directories**
   - Sets up `artifacts-local/<timestamp>/` structure
   - Creates subdirectories for each platform

3. **[3/10] Run Tests** *(optional)*
   - Builds test environment in container
   - Runs Jest test suite
   - Validates code quality

4. **[4/10] Build Core Library**
   - Compiles TypeScript core library
   - Required by all other platforms
   - Takes 2-3 minutes

5. **[5/10] Build VSCode Extension**
   - Compiles extension code
   - Packages into `.vsix` installer
   - Takes 3-5 minutes

6. **[6/10] Build Web Application**
   - Creates production React build
   - Optimizes and bundles
   - Takes 2-4 minutes

7. **[7/10] Build Desktop Application**
   - Builds Electron app
   - Prepares native packaging
   - Takes 3-5 minutes

8. **[8/10] Build Android APK**
   - Downloads Android SDK (first time only)
   - Builds APK installer
   - Takes 5-10 minutes (first time)

9. **[9/10] Create Documentation**
   - Generates README with instructions
   - Lists all artifacts
   - Provides testing guidance

10. **[10/10] Show Summary**
    - Lists all generated files
    - Shows file sizes
    - Displays testing instructions

---

## 📂 Output Structure

After building, you'll find this structure:

```
artifacts-local/
└── 20251013_103045/          # Timestamp
    ├── vscode/
    │   └── openpilot-vscode_20251013_103045.vsix
    ├── web/
    │   └── openpilot-web_20251013_103045.tar.gz
    ├── desktop/
    │   └── openpilot-desktop_20251013_103045.tar.gz
    ├── android/
    │   └── openpilot-android_20251013_103045.apk
    ├── logs/
    │   ├── test-results.log
    │   ├── core-build.log
    │   ├── vscode-build.log
    │   ├── web-build.log
    │   ├── desktop-build.log
    │   └── android-build.log
    └── README.md             # Build-specific instructions
```

---

## 🧪 Testing Each Platform

### VSCode Extension (.vsix)

```powershell
# Option 1: Command line
code --install-extension artifacts-local/20251013_103045/vscode/openpilot-vscode_20251013_103045.vsix

# Option 2: VS Code UI
# 1. Open VSCode
# 2. Go to Extensions (Ctrl+Shift+X)
# 3. Click "..." menu → "Install from VSIX"
# 4. Select the .vsix file
# 5. Reload VSCode
```

### Web Application (.tar.gz)

```powershell
# Extract
cd artifacts-local/20251013_103045/web
tar -xzf openpilot-web_20251013_103045.tar.gz -C extracted

# Serve with Python
cd extracted
python -m http.server 8080

# Open in browser
start http://localhost:8080

# Or serve with Node.js
npx serve -s . -p 8080
```

### Desktop Application (.tar.gz)

```powershell
# Extract
cd artifacts-local/20251013_103045/desktop
tar -xzf openpilot-desktop_20251013_103045.tar.gz -C extracted

# Run with Electron (requires Electron installed globally)
cd extracted
electron .

# Or package for your OS
# Windows: Use electron-builder
# Mac: Use electron-packager
# Linux: Use AppImage or .deb packaging
```

### Android Application (.apk)

```powershell
# Transfer to Android device
adb install artifacts-local/20251013_103045/android/openpilot-android_20251013_103045.apk

# Or manually:
# 1. Copy APK to device (USB, email, cloud storage)
# 2. On device: Settings → Security → Enable "Unknown Sources"
# 3. Tap APK file to install
# 4. Grant permissions if prompted
```

---

## 🔧 Advanced Options

### Combination Flags

```powershell
# Build only VSCode extension (fastest)
.\local-container-build.ps1 -SkipTests -SkipAndroid -SkipDesktop -SkipWeb

# Build only Web and Desktop
.\local-container-build.ps1 -SkipTests -SkipAndroid -SkipVSCode

# Full clean build with tests
.\local-container-build.ps1 -Clean

# Use Podman for rootless builds
.\local-container-build.ps1 -UsePodman -SkipTests
```

### Build Times (Approximate)

| Configuration | First Run | Subsequent Runs |
|---------------|-----------|-----------------|
| Full build with tests | 25-30 min | 15-20 min |
| Full build, skip tests | 20-25 min | 12-15 min |
| VSCode only | 5-7 min | 3-5 min |
| Web only | 4-6 min | 2-4 min |
| Desktop only | 5-8 min | 3-5 min |
| Android only | 12-15 min | 8-10 min |

*Subsequent runs are faster due to Docker layer caching*

---

## 📊 Comparing to Photo Studio Approach

### Similarities

Both scripts follow the same pattern:

1. ✅ Check container tool availability
2. ✅ Create timestamped artifact directories
3. ✅ Run tests in containers (optional)
4. ✅ Build each platform in isolated containers
5. ✅ Extract artifacts using `container cp`
6. ✅ Generate comprehensive summaries
7. ✅ Provide testing instructions

### Key Differences

| Feature | Photo Studio | OpenPilot |
|---------|--------------|-----------|
| **Language** | Flutter/Dart | TypeScript/React |
| **Platforms** | Web + Android | VSCode + Web + Desktop + Android |
| **Build Tool** | Flutter SDK | Node.js + npm |
| **Test Runner** | `flutter test` | Jest |
| **Output** | `.zip` + `.apk` + `.aab` | `.vsix` + `.tar.gz` + `.apk` |
| **SDK Download** | Flutter (~600MB) | Android SDK (~400MB) |

### Advantages of Container Approach

✅ **Reproducible**: Same results on any machine  
✅ **Isolated**: No conflicts with local tools  
✅ **Clean**: No leftover build artifacts on host  
✅ **Portable**: Works on Windows, Mac, Linux  
✅ **Documented**: All dependencies explicit in Dockerfile  
✅ **Cacheable**: Docker layers speed up rebuilds  

---

## 🐛 Troubleshooting

### Docker Not Found

```
[X] docker is not installed or not in PATH
```

**Solution**: Install Docker Desktop from https://www.docker.com/products/docker-desktop

### Build Fails with Disk Space Error

```
Error: no space left on device
```

**Solution**: 
```powershell
# Clean Docker cache
docker system prune -a

# Or increase Docker disk space in Docker Desktop settings
```

### VSCode .vsix Not Found

```
[!] VSCode .vsix not found, but build succeeded
```

**Solution**: The extension compiled but packaging failed. Check logs:
```powershell
Get-Content artifacts-local/<timestamp>/logs/vscode-build.log
```

### Android Build Very Slow

**Expected**: First Android build downloads ~400MB Android SDK

**Speed up**: After first successful build, the SDK is cached in Docker layers

### Test Failures

```
[X] Tests failed
```

**Solution**: 
1. Check test logs: `artifacts-local/<timestamp>/logs/test-results.log`
2. Run tests locally to debug: `cd tests && npm test`
3. Skip tests for now: `.\local-container-build.ps1 -SkipTests`

---

## 🎓 How It Works (Technical Details)

### Multi-Stage Docker Builds

Each platform uses inline Dockerfiles:

```powershell
& docker build -t openpilot-vscode -f- . @"
FROM node:20-alpine
WORKDIR /workspace
# ... build steps ...
"@
```

### Artifact Extraction

After building, artifacts are copied out:

```powershell
$containerId = & docker create openpilot-vscode
& docker cp "${containerId}:/tmp/output.vsix" "./artifacts/"
& docker rm $containerId
```

### Layer Caching

Docker caches intermediate layers, so:
- First build: Downloads all dependencies (~500MB)
- Subsequent builds: Reuses cached layers (~50MB download)

### Parallel Builds (Manual)

You can run multiple build scripts in parallel:

```powershell
# Terminal 1
.\local-container-build.ps1 -SkipAndroid -SkipDesktop -SkipWeb

# Terminal 2 (simultaneously)
.\local-container-build.ps1 -SkipVSCode -SkipWeb -SkipDesktop

# Terminal 3 (simultaneously)
.\local-container-build.ps1 -SkipVSCode -SkipAndroid -SkipDesktop
```

---

## 📦 Distribution Workflow

### 1. Build Locally

```powershell
.\local-container-build.ps1
```

### 2. Test Artifacts

Test each platform using instructions above

### 3. Collect Artifacts

```powershell
# Get latest build directory
$latest = Get-ChildItem "artifacts-local" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Zip for distribution
Compress-Archive -Path $latest.FullName -DestinationPath "openpilot-release-$(Get-Date -Format 'yyyyMMdd').zip"
```

### 4. Upload to GitHub Releases

```powershell
# Using GitHub CLI
gh release create v1.0.0 openpilot-release-20251013.zip --title "OpenPilot v1.0.0" --notes "Release notes here"
```

---

## 🔄 CI/CD Integration

You can use this script in GitHub Actions:

```yaml
name: Build Installers
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build all platforms
        run: |
          chmod +x local-container-build.ps1
          pwsh ./local-container-build.ps1 -SkipTests
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: installers
          path: artifacts-local/*/
```

---

## 💡 Best Practices

### For Development

```powershell
# Quick iteration on VSCode extension
.\local-container-build.ps1 -SkipTests -SkipAndroid -SkipDesktop -SkipWeb

# Test with real tests
.\local-container-build.ps1 -SkipAndroid -SkipDesktop -SkipWeb
```

### For Testing

```powershell
# Full build with tests
.\local-container-build.ps1

# Check all logs
Get-Content artifacts-local/*/logs/*.log
```

### For Release

```powershell
# Clean build, all platforms
.\local-container-build.ps1 -Clean

# Verify all artifacts exist
Get-ChildItem artifacts-local -Recurse -Include *.vsix,*.apk,*.tar.gz
```

---

## 📚 Additional Resources

- **Docker Documentation**: https://docs.docker.com/
- **Podman Documentation**: https://docs.podman.io/
- **VSCode Extension Publishing**: https://code.visualstudio.com/api/working-with-extensions/publishing-extension
- **Electron Packaging**: https://www.electronjs.org/docs/latest/tutorial/application-distribution

---

## 🎉 Success Criteria

After running the script, you should have:

- ✅ Zero errors in build process
- ✅ All platform artifacts generated
- ✅ Each artifact tested successfully
- ✅ Build logs available for debugging
- ✅ README with platform-specific instructions

---

**Status**: ✅ **READY FOR LOCAL TESTING**

**Next Steps**:
1. Run `.\local-container-build.ps1`
2. Wait 15-20 minutes
3. Test each artifact
4. Report any issues
5. Distribute tested artifacts

---

*Generated for OpenPilot v1.0.0*  
*Last Updated: October 13, 2025*
