# OpenPilot Android APK Build Instructions

## Prerequisites
- Node.js 18+
- React Native CLI
- Android Studio
- Java JDK 11+
- Android SDK (API 33+)

## Build Steps

1. **Install Dependencies**
   ```bash
   cd mobile
   npm install
   ```

2. **Set up Android Environment**
   ```bash
   # Set ANDROID_HOME environment variable (Linux/Mac)
   export ANDROID_HOME=$HOME/Android/Sdk
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/tools
   export PATH=$PATH:$ANDROID_HOME/tools/bin
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   ```

3. **Generate Debug APK**
   ```bash
   cd android
   ./gradlew assembleDebug
   ```
   APK location: ndroid/app/build/outputs/apk/debug/app-debug.apk

4. **Generate Release APK**
   ```bash
   cd android
   ./gradlew assembleRelease
   ```
   APK location: ndroid/app/build/outputs/apk/release/app-release.apk

5. **Install on Device**
   ```bash
   # Debug APK
   adb install android/app/build/outputs/apk/debug/app-debug.apk
   
   # Release APK
   adb install android/app/build/outputs/apk/release/app-release.apk
   ```

## Testing

1. **Run on Emulator**
   ```bash
   npx react-native run-android
   ```

2. **Run on Physical Device**
   - Enable USB debugging on your Android device
   - Connect via USB
   - Run: 
px react-native run-android

## Notes
- For production builds, you need to sign the APK with a keystore
- See React Native documentation for keystore setup
- Current package provides debug APK for testing

---
**Package:** OpenPilot Mobile Android  
**Version:** 1.0.0  
**Min Android:** 10.0 (API 29)  
**Target Android:** 13.0 (API 33)
