# OpenPilot - Complete Testing Guide
**Build Date:** October 12, 2025 09:59:50
**Output Directory:** i:\openpilot\installers-output\20251012-095758

## Quick Start Testing

### 1. Test Android App
```bash
adb devices
adb install android/openpilot-mobile.apk
```

### 2. Test Desktop App
```bash
cd desktop
npm install
npm run dev
```

### 3. Test Web App
```bash
cd web
npm install
npm start
# Open: http://localhost:3000
```

### 4. Test VS Code Extension
```bash
code --install-extension vscode/openpilot-vscode.vsix
```

## Platform-Specific Guides
- Android: See android/BUILD_ANDROID.md
- iOS: See ios/BUILD_IOS.md
- Desktop: See desktop/BUILD_DESKTOP.md
- Web: See web/DEPLOY_WEB.md
- VSCode: See vscode/INSTALL_VSCODE.md

## Test Checklist

### Android
- [ ] APK installs successfully
- [ ] App launches without crashes
- [ ] Core features work

### Desktop
- [ ] App launches successfully
- [ ] UI is responsive
- [ ] File system access works

### Web
- [ ] All pages load correctly
- [ ] Responsive on mobile/desktop
- [ ] PWA installable

### VS Code Extension
- [ ] Extension installs
- [ ] Commands work
- [ ] Code generation functional

## Troubleshooting

### Android Issues
- Enable 'Unknown Sources' in settings
- Check logcat: adb logcat *:E

### Desktop Issues
- Run as Administrator if needed
- Check antivirus settings

### Web Issues
- Clear browser cache
- Check browser console

## Support
GitHub Issues: https://github.com/dayahere/openpilot/issues
