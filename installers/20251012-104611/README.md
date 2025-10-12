# Quick Build & Test Guide

Build Date: 2025-10-12 10:46:11
Output: i:\openpilot\installers\20251012-104611

## Build All Installers

Each platform has a detailed BUILD guide in its folder:

### Android APK
See: android\BUILD_APK.md
Time: 15-20 minutes
Command: 
`powershell
cd i:\openpilot\mobile
docker run --rm -v ${PWD}:/app -w /app reactnativecommunity/react-native-android bash -c "cd android && ./gradlew assembleRelease"
`

### Desktop App  
See: desktop\BUILD_DESKTOP.md
Time: 5-10 minutes
Command:
`powershell
cd i:\openpilot\desktop
docker run --rm -v ${PWD}:/app -w /app node:20 npm install && npm run build
`

### Web App
See: web\BUILD_WEB.md  
Time: 3-5 minutes
Command:
`powershell
cd i:\openpilot\web
docker run --rm -v ${PWD}:/app -w /app node:20 npm install && npm run build
`

### VSCode Extension
See: vscode\BUILD_VSCODE.md
Time: 2-3 minutes  
Command:
`powershell
cd i:\openpilot\vscode-extension
docker run --rm -v ${PWD}:/app -w /app node:20 npx @vscode/vsce package
`

### iOS App
See: ios\BUILD_IOS.md
Requires: macOS with Xcode

## Quick Test Commands

### Test Android
`powershell
adb install i:\openpilot\mobile\android\app\build\outputs\apk\release\app-release.apk
`

### Test Desktop
`powershell
cd i:\openpilot\desktop\build
start index.html
`

### Test Web
`powershell
docker run --rm -p 3000:3000 -v i:\openpilot\web\build:/usr/share/nginx/html nginx:alpine
# Open: http://localhost:3000
`

### Test VSCode
`powershell
code --install-extension i:\openpilot\vscode-extension\*.vsix
`

## Troubleshooting

**Docker Issues:**
- Start Docker Desktop
- Allocate 4GB+ memory: Settings â†’ Resources
- Clean cache: `docker system prune -a`

**Build Failures:**
- Delete node_modules and package-lock.json
- Run `npm install` again
- Check Docker logs: `docker logs {container_id}`

**Dependency Errors:**
- Use Node 20: `docker run --rm node:20`
- Add `--legacy-peer-deps` flag
- Clear npm cache: `npm cache clean --force`

## Support

Repository: https://github.com/dayahere/openpilot
Issues: https://github.com/dayahere/openpilot/issues

## Next Steps

1. Follow the BUILD guide for each platform you want to build
2. Test each installer thoroughly
3. Document any issues found
4. Create GitHub release with working installers
