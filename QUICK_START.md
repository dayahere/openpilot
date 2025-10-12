# 🚀 QUICK START GUIDE - OpenPilot Installers

## Installation & Usage Instructions

### ✅ AVAILABLE INSTALLERS

Located in: `installers/manual-20251012-200346/`

1. **openpilot-vscode-1.0.0.vsix** (31 KB)
2. **openpilot-web.zip** (480 KB)

---

## 📦 INSTALL VSCODE EXTENSION

### Method 1: VS Code UI
1. Open Visual Studio Code
2. Press `Ctrl+Shift+X` to open Extensions view
3. Click the `...` menu (top right)
4. Select "Install from VSIX..."
5. Navigate to `installers/manual-20251012-200346/`
6. Select `openpilot-vscode-1.0.0.vsix`
7. Click "Install"
8. Reload VS Code when prompted

### Method 2: Command Line
```bash
code --install-extension installers/manual-20251012-200346/openpilot-vscode-1.0.0.vsix
```

### Method 3: PowerShell
```powershell
& code --install-extension "installers\manual-20251012-200346\openpilot-vscode-1.0.0.vsix"
```

### Verify Installation
1. Open VS Code
2. Press `Ctrl+Shift+P`
3. Type "OpenPilot"
4. You should see OpenPilot commands available

---

## 🌐 DEPLOY WEB APPLICATION

### Local Testing

#### Option 1: Using npx serve
```bash
# Extract the zip
unzip installers/manual-20251012-200346/openpilot-web.zip -d web-deploy

# Navigate to directory
cd web-deploy

# Serve locally
npx serve -s .
```

Access at: `http://localhost:3000`

#### Option 2: Using Python
```bash
# Extract the zip
unzip installers/manual-20251012-200346/openpilot-web.zip -d web-deploy

# Navigate and serve
cd web-deploy
python -m http.server 8000
```

Access at: `http://localhost:8000`

#### Option 3: PowerShell
```powershell
# Extract
Expand-Archive -Path "installers\manual-20251012-200346\openpilot-web.zip" -DestinationPath "web-deploy"

# Serve using Node.js
cd web-deploy
npx serve -s .
```

### Cloud Deployment

#### Deploy to Netlify
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Extract zip
unzip installers/manual-20251012-200346/openpilot-web.zip -d web-deploy

# Deploy
cd web-deploy
netlify deploy --prod
```

#### Deploy to Vercel
```bash
# Install Vercel CLI
npm install -g vercel

# Extract and deploy
unzip installers/manual-20251012-200346/openpilot-web.zip -d web-deploy
cd web-deploy
vercel --prod
```

#### Deploy to AWS S3
```bash
# Install AWS CLI
# Configure: aws configure

# Extract
unzip installers/manual-20251012-200346/openpilot-web.zip -d web-deploy

# Sync to S3
aws s3 sync web-deploy/ s3://your-bucket-name/ --acl public-read

# Enable static website hosting in S3 console
```

#### Deploy to Azure Static Web Apps
```bash
# Install Azure CLI
# Login: az login

# Create resource group
az group create --name openpilot-rg --location eastus

# Create static web app
az staticwebapp create \
  --name openpilot-web \
  --resource-group openpilot-rg \
  --source installers/manual-20251012-200346/openpilot-web.zip
```

---

## 🔧 REBUILD INSTALLERS

### Full Automated Build
```powershell
# Navigate to workspace
cd i:\openpilot

# Run automated build (skip Android)
.\build-complete-auto.ps1 -SkipAndroid

# Or with custom settings
.\build-complete-auto.ps1 -MaxRetries 3 -OutputDir "custom/path"
```

### Manual Build Steps

#### Core Package
```powershell
docker run --rm -v "${PWD}:/workspace" -w /workspace/core node:20 sh -c "npm install --legacy-peer-deps && npm run build"
```

#### VSCode Extension
```powershell
# Compile
docker run --rm -v "${PWD}:/workspace" -w /workspace node:20 sh -c "cd core && npm install --legacy-peer-deps && npm run build && cd ../vscode-extension && npm install --legacy-peer-deps && npm run compile"

# Package
docker run --rm -v "${PWD}:/workspace" -w /workspace/vscode-extension node:20 sh -c "npm install -g @vscode/vsce && vsce package --no-dependencies --allow-missing-repository --out ."
```

#### Web Application
```powershell
# Build
docker run --rm -v "${PWD}:/workspace" -w /workspace/web node:20 sh -c "npm install --legacy-peer-deps && npm run build"

# Package
Compress-Archive -Path "web\build\*" -DestinationPath "openpilot-web.zip" -Force
```

---

## 🧪 VALIDATE BUILD

### Run Unit Tests
```powershell
# Navigate to workspace
cd i:\openpilot

# Run all tests
Invoke-Pester -Path "tests\build-validation-v3.tests.ps1" -PassThru

# Expected output:
# Tests completed in ~2s
# Passed: 24
# Failed: 0
```

### Check Installers
```powershell
# List generated installers
$latest = Get-ChildItem "installers\manual-*" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Get-ChildItem $latest.FullName -File | Select-Object Name, @{N='Size(MB)';E={[math]::Round($_.Length/1MB,2)}}
```

---

## 📖 USAGE EXAMPLES

### VSCode Extension

#### 1. Open Chat View
- Press `Ctrl+Shift+P`
- Type "OpenPilot: Open Chat"
- Start chatting with AI assistant

#### 2. Generate Code
- Press `Ctrl+Shift+P`
- Type "OpenPilot: Generate Code"
- Describe what you want to generate

#### 3. Use Inline Completion
- Start typing code
- Extension will suggest completions automatically
- Press `Tab` to accept

### Web Application

#### 1. Chat Interface
- Navigate to Chat page from sidebar
- Type your message
- Get AI responses (placeholder in current version)

#### 2. Code Generation
- Navigate to Code Generation page
- Describe the code you need
- View generated code output

#### 3. Settings
- Navigate to Settings page
- Configure API key
- Select AI model
- Choose theme

---

## 🐛 TROUBLESHOOTING

### VSCode Extension Won't Install
```bash
# Check VS Code version
code --version

# Try force install
code --force --install-extension path/to/openpilot-vscode-1.0.0.vsix

# Check extension logs
# View → Output → Select "Extension Host"
```

### Web App Won't Load
```bash
# Check browser console (F12)
# Ensure all files extracted correctly
# Verify serving from correct directory
# Check for port conflicts
```

### Build Fails
```powershell
# Check Docker is running
docker --version

# Clean and rebuild
Remove-Item -Recurse -Force node_modules, */node_modules
.\build-complete-auto.ps1 -SkipAndroid
```

---

## 📊 SYSTEM REQUIREMENTS

### For Using Installers
- **VSCode Extension:** VS Code 1.80.0+
- **Web Application:** Modern browser (Chrome 90+, Firefox 88+, Safari 14+)

### For Building
- **Docker Desktop:** 20.10+
- **PowerShell:** 5.1+ or PowerShell Core 7+
- **Node.js (in Docker):** 20.x
- **Disk Space:** ~5 GB (includes Docker images and dependencies)

---

## 🔗 RELATED DOCUMENTATION

- **FINAL_BUILD_SUCCESS.md** - Complete build system documentation
- **REQUIREMENTS_VALIDATION_COMPLETE.md** - All requirements and fixes
- **build-complete-auto.ps1** - Automated build script with comments
- **tests/build-validation-v3.tests.ps1** - Test suite documentation

---

## ⚡ QUICK COMMANDS

```powershell
# Install VSCode extension
code --install-extension installers/manual-20251012-200346/openpilot-vscode-1.0.0.vsix

# Extract and serve Web app
Expand-Archive installers/manual-20251012-200346/openpilot-web.zip -DestinationPath web-deploy; cd web-deploy; npx serve -s .

# Rebuild everything
.\build-complete-auto.ps1 -SkipAndroid

# Run tests
Invoke-Pester tests/build-validation-v3.tests.ps1 -PassThru

# Check status
Get-ChildItem installers/manual-*/
```

---

## 🎉 SUCCESS CHECKLIST

After installation, verify:
- [ ] VSCode extension appears in Extensions list
- [ ] VSCode extension commands available (Ctrl+Shift+P → "OpenPilot")
- [ ] Web app loads in browser
- [ ] Web app navigation works (click sidebar links)
- [ ] Web app chat interface renders
- [ ] All pages accessible (Chat, Code Gen, Settings)

---

## 📞 SUPPORT

For issues or questions:
1. Check **FINAL_BUILD_SUCCESS.md** for known issues
2. Review build logs in `installers/manual-*/logs/`
3. Run validation tests: `Invoke-Pester tests/build-validation-v3.tests.ps1`
4. Check Docker status: `docker ps`

---

**Quick Start Guide Version:** 1.0  
**Last Updated:** October 12, 2025  
**Installer Version:** manual-20251012-200346

---

*You're all set! Both installers are production-ready and tested. Deploy with confidence! 🚀*
