# Android APK Build with Docker

## Prerequisites
- Docker installed and running

## Build APK (15-20 minutes)

`powershell
cd i:\openpilot\mobile

# Step 1: Install dependencies
docker run --rm -v ${PWD}:/app -w /app node:20 npm install

# Step 2: Build APK
docker run --rm -v ${PWD}:/app -w /app reactnativecommunity/react-native-android:latest bash -c "cd android && chmod +x gradlew && ./gradlew assembleRelease --no-daemon"

# Step 3: Find APK
# Location: android\app\build\outputs\apk\release\app-release.apk
`

## Install on Device

`powershell
adb devices
adb install android\app\build\outputs\apk\release\app-release.apk
`

## Troubleshooting

If build fails:
1. Ensure Docker has 4GB+ memory
2. Clean build: `docker run --rm -v ${PWD}:/app -w /app reactnativecommunity/react-native-android bash -c "cd android && ./gradlew clean"`
3. Check logs in android\app\build\outputs\logs\
