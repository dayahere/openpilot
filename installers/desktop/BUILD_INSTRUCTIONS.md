# OpenPilot Desktop Installer Build Instructions

## Prerequisites
- Node.js 18+
- npm 9+

## Build Steps

1. **Install Dependencies**
   ```bash
   cd desktop
   npm install
   ```

2. **Build Application**
   ```bash
   npm run build
   ```

3. **Package for Distribution**

   ### Windows (.exe)
   ```bash
   npm run package-win
   ```
   Output: dist/OpenPilot-Setup-1.0.0.exe

   ### macOS (.dmg)
   ```bash
   npm run package-mac
   ```
   Output: dist/OpenPilot-1.0.0.dmg

   ### Linux (.deb, .AppImage)
   ```bash
   npm run package-linux
   ```
   Output: 
   - dist/OpenPilot-1.0.0.deb
   - dist/OpenPilot-1.0.0.AppImage

4. **Run Development Build**
   ```bash
   npm run electron
   ```

## Installation

### Windows
1. Double-click OpenPilot-Setup-1.0.0.exe
2. Follow installation wizard
3. Launch from Start Menu or Desktop shortcut

### macOS
1. Open OpenPilot-1.0.0.dmg
2. Drag OpenPilot to Applications folder
3. Launch from Applications or Launchpad

### Linux (Debian/Ubuntu)
```bash
sudo dpkg -i OpenPilot-1.0.0.deb
```

### Linux (AppImage)
```bash
chmod +x OpenPilot-1.0.0.AppImage
./OpenPilot-1.0.0.AppImage
```

## Testing

1. **Run in Development Mode**
   ```bash
   npm run dev
   ```

2. **Run Built Application**
   - Windows: Check dist/win-unpacked/OpenPilot.exe
   - macOS: Check dist/mac/OpenPilot.app
   - Linux: Check dist/linux-unpacked/openpilot

## Package Configuration

Add to package.json:

```json
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
```

---
**Package:** OpenPilot Desktop  
**Version:** 1.0.0  
**Platforms:** Windows, macOS, Linux  
**Framework:** Electron + React
