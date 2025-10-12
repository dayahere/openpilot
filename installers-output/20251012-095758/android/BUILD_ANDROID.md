# Android APK Build Guide

## Prerequisites
- Android Studio
- Java JDK 11+
- Node.js 18+

## Build Steps

1. Install dependencies:
```bash
npm install
```

2. Build the release APK:
```bash
cd android
./gradlew assembleRelease
```

3. APK will be generated at:
```
android/app/build/outputs/apk/release/app-release.apk
```

## Quick Test
```bash
adb install android/app/build/outputs/apk/release/app-release.apk
```

## Using Docker (if Android SDK not installed)
```bash
docker run --rm -v ${PWD}:/app -w /app reactnativecommunity/react-native-android bash -c 'cd android && ./gradlew assembleRelease'
```
