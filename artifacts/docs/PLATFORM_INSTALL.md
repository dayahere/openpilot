# 🚀 Complete Platform Installation Guide

## 📱 All Supported Platforms

OpenPilot runs on **5 platforms**:

1. ✅ **VS Code Extension** (Windows, macOS, Linux)
2. ✅ **Desktop Application** (Windows, macOS, Linux)
3. ✅ **Web Application** (Any browser, PWA)
4. ✅ **iOS Mobile App** (iPhone, iPad)
5. ✅ **Android Mobile App** (Phones, Tablets)

---

## 🖥️ Platform 1: VS Code Extension

### Installation

**Method 1: From Marketplace (Coming Soon)**
```bash
# Search for "OpenPilot" in VS Code Extensions
# Click Install
```

**Method 2: Local Install**
```bash
cd vscode-extension
npm install
npm run compile
code --install-extension openpilot-*.vsix
```

**Method 3: Development Mode**
```bash
cd vscode-extension
npm install
npm run compile
# Press F5 in VS Code
```

### Usage

1. Open VS Code
2. Click OpenPilot icon in sidebar
3. Start chatting or coding
4. Use `Ctrl+Shift+P` → "OpenPilot: ..."

### Features
- ✅ Inline code completions
- ✅ Chat sidebar
- ✅ Context menu integration
- ✅ Keyboard shortcuts
- ✅ Repository analysis

---

## 💻 Platform 2: Desktop Application

### Windows

**Installer (Recommended)**
```powershell
# Download openpilot-setup.exe
# Double-click to install
# Run from Start Menu
```

**Portable Version**
```powershell
# Download openpilot-portable.zip
# Extract anywhere
# Run openpilot.exe
```

**Build from Source**
```powershell
cd desktop
npm install
npm run build
npm start
```

### macOS

**DMG Installer (Recommended)**
```bash
# Download OpenPilot.dmg
# Drag to Applications
# Open from Launchpad
```

**Homebrew** (Coming Soon)
```bash
brew install --cask openpilot
```

**Build from Source**
```bash
cd desktop
npm install
npm run build
npm start
```

### Linux

**AppImage (All Distributions)**
```bash
# Download openpilot.AppImage
chmod +x openpilot.AppImage
./openpilot.AppImage
```

**Debian/Ubuntu (.deb)**
```bash
sudo dpkg -i openpilot_1.0.0_amd64.deb
openpilot
```

**Fedora/RHEL (.rpm)**
```bash
sudo rpm -i openpilot-1.0.0.x86_64.rpm
openpilot
```

**Arch Linux (AUR)** (Coming Soon)
```bash
yay -S openpilot
```

**Build from Source**
```bash
cd desktop
npm install
npm run build
npm start
```

### Features
- ✅ Native performance
- ✅ System tray integration
- ✅ Auto-updates
- ✅ Offline mode
- ✅ File system access

---

## 🌐 Platform 3: Web Application (PWA)

### Installation

**Access Online**
```
Visit: https://openpilot.dev
```

**Install as PWA (All Browsers)**

**Chrome/Edge:**
1. Visit https://openpilot.dev
2. Click install icon in address bar
3. Or: Menu → "Install OpenPilot..."

**Safari (iOS/macOS):**
1. Visit https://openpilot.dev
2. Tap Share button
3. "Add to Home Screen"

**Firefox:**
1. Visit https://openpilot.dev
2. Click "Install" prompt
3. Or use PWA extension

### Self-Host

```bash
cd web
npm install
npm run build

# Serve with your preferred server
npx serve -s build
# Or
python -m http.server 3000 -d build
```

### Features
- ✅ Works offline (PWA)
- ✅ Installable
- ✅ Cross-platform
- ✅ No download required
- ✅ Auto-updates

---

## 📱 Platform 4: iOS Mobile App

### Installation

**App Store (Coming Soon)**
```
Search: "OpenPilot AI"
Tap: Get
```

**TestFlight Beta**
```
1. Install TestFlight
2. Open invitation link
3. Install OpenPilot
```

**Build from Source**

**Requirements:**
- macOS with Xcode 15+
- iOS Developer Account
- CocoaPods

```bash
cd mobile
npm install
cd ios
pod install
cd ..

# Open Xcode
open ios/OpenPilot.xcworkspace

# Or run directly
npx react-native run-ios
```

### Features
- ✅ Native iOS app
- ✅ Voice input (Siri integration)
- ✅ Haptic feedback
- ✅ Offline mode
- ✅ iCloud sync
- ✅ Dark mode
- ✅ Widgets

### Requirements
- iOS 14.0 or later
- 100 MB free space
- Optional: Internet for cloud models

---

## 🤖 Platform 5: Android Mobile App

### Installation

**Google Play Store (Coming Soon)**
```
Search: "OpenPilot AI"
Tap: Install
```

**APK Direct Download**
```
1. Download openpilot.apk
2. Enable "Unknown sources"
3. Install APK
```

**Build from Source**

**Requirements:**
- Android Studio
- JDK 11+
- Android SDK

```bash
cd mobile
npm install

# Connect device or start emulator
npx react-native run-android
```

**Build Release APK**
```bash
cd mobile/android
./gradlew assembleRelease

# APK location:
# android/app/build/outputs/apk/release/app-release.apk
```

### Features
- ✅ Native Android app
- ✅ Voice input (Google Assistant)
- ✅ Material Design
- ✅ Offline mode
- ✅ Google Drive sync
- ✅ Dark mode
- ✅ Widgets

### Requirements
- Android 7.0 (API 24) or later
- 100 MB free space
- Optional: Internet for cloud models

---

## 🔧 Backend Server (Optional)

For team collaboration and cloud sync:

### Installation

```bash
cd backend
npm install
npm run build

# Configure
cp .env.example .env
# Edit .env with your settings

# Start server
npm start
```

### Docker Deployment

```bash
# Build image
docker build -t openpilot-backend .

# Run container
docker run -d -p 8000:8000 \
  -e MONGODB_URI=your-connection-string \
  openpilot-backend
```

### Cloud Deployment

**Vercel/Netlify:**
```bash
vercel deploy
# Or
netlify deploy
```

**AWS/GCP/Azure:**
See [DEPLOY.md](DEPLOY.md) for detailed instructions

---

## 🤖 AI Model Setup

### Local Models (Recommended)

#### Ollama (Easiest)

**Windows:**
```powershell
winget install Ollama.Ollama
ollama serve
ollama pull codellama
```

**macOS:**
```bash
brew install ollama
ollama serve
ollama pull codellama
```

**Linux:**
```bash
curl https://ollama.ai/install.sh | sh
ollama serve
ollama pull codellama
```

**Recommended Models:**
```bash
# Fast completions (7B)
ollama pull codellama:7b

# Balanced quality (13B)
ollama pull codellama:13b

# Best quality (34B)
ollama pull codellama:34b

# Alternatives
ollama pull deepseek-coder:6.7b
ollama pull starcoder:3b
```

#### llama.cpp (Advanced)

```bash
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
make
./main -m models/codellama-13b.gguf
```

### Cloud Models (Optional)

#### OpenAI
```bash
# Get API key from: https://platform.openai.com
# Add to .env:
OPENAI_API_KEY=sk-your-key
AI_PROVIDER=openai
AI_MODEL=gpt-4-turbo
```

#### Anthropic Claude
```bash
# Get API key from: https://console.anthropic.com
ANTHROPIC_API_KEY=your-key
AI_PROVIDER=anthropic
AI_MODEL=claude-3-opus
```

#### Google Gemini (Free!)
```bash
# Get API key from: https://makersuite.google.com
GOOGLE_API_KEY=your-key
AI_PROVIDER=google
AI_MODEL=gemini-pro
```

---

## ⚙️ Configuration

### Create .env File

```bash
cp .env.example .env
```

### Basic Configuration

```env
# AI Provider
AI_PROVIDER=ollama
AI_MODEL=codellama
AI_BASE_URL=http://localhost:11434

# Features
ENABLE_VOICE=true
ENABLE_CODE_GEN=true
OFFLINE_MODE=false

# Privacy
TELEMETRY_ENABLED=false
LOCAL_ONLY=true
```

### Advanced Configuration

```env
# Performance
CACHE_SIZE=500
MAX_TOKENS=4096
TEMPERATURE=0.7
MAX_CONTEXT_LINES=100

# Completion
COMPLETION_DELAY=100
MIN_COMPLETION_LENGTH=3

# Chat
STREAM_RESPONSES=true
SAVE_HISTORY=true
```

---

## 🧪 Testing Installation

### Test All Platforms

```bash
# Run automated tests
python scripts/auto-fix-loop.py

# Or manual tests
npm run test:all
```

### Platform-Specific Tests

**VS Code Extension:**
```bash
cd vscode-extension
npm test
```

**Desktop:**
```bash
cd desktop
npm test
```

**Web:**
```bash
cd web
npm test
```

**Mobile:**
```bash
cd mobile
npm test
```

---

## 🔍 Troubleshooting

### Common Issues

**"Cannot connect to Ollama"**
```bash
# Start Ollama server
ollama serve

# Test connection
curl http://localhost:11434/api/version
```

**"Module not found"**
```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

**"TypeScript errors"**
```bash
# Rebuild TypeScript
npm run build:all
```

**"Tests failing"**
```bash
# Run auto-fix
python scripts/auto-fix-loop.py
```

**Mobile build errors:**
```bash
# Clean and rebuild
cd mobile

# iOS
cd ios
pod install
pod update
cd ..

# Android
cd android
./gradlew clean
cd ..
```

### Platform-Specific Issues

See detailed troubleshooting:
- [Windows Issues](docs/troubleshoot-windows.md)
- [macOS Issues](docs/troubleshoot-macos.md)
- [Linux Issues](docs/troubleshoot-linux.md)
- [iOS Issues](docs/troubleshoot-ios.md)
- [Android Issues](docs/troubleshoot-android.md)

---

## 📊 Verify Installation

### Quick Test

```bash
# Test chat
openpilot chat "Hello, can you help me?"

# Test completion
openpilot complete "function add("

# Test code generation
openpilot generate "Create a React todo component"
```

### Health Check

```bash
# Check all systems
openpilot doctor

# Expected output:
# ✅ Dependencies installed
# ✅ AI model available
# ✅ Configuration valid
# ✅ All systems operational
```

---

## 🚀 Next Steps

1. ✅ Choose your platform(s)
2. ✅ Install OpenPilot
3. ✅ Setup AI model
4. ✅ Configure settings
5. ✅ Start building!

**See also:**
- [Quick Reference](QUICK_REFERENCE.md) - Command cheat sheet
- [Complete Guide](docs/COMPLETE_GUIDE.md) - Full documentation
- [Examples](docs/EXAMPLES.md) - Code examples

---

**Need help?** 
- 💬 [Discord Community](https://discord.gg/openpilot)
- 🐛 [Report Issues](https://github.com/openpilot/issues)
- 📧 [Email Support](mailto:support@openpilot.dev)

**Last Updated:** October 11, 2025
