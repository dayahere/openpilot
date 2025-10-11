# OpenPilot iOS IPA Build Instructions

## Prerequisites
- macOS (required for iOS builds)
- Xcode 14+
- Node.js 18+
- CocoaPods
- Apple Developer Account (for device testing)

## Build Steps

1. **Install Dependencies**
   ```bash
   cd mobile
   npm install
   ```

2. **Install iOS Dependencies**
   ```bash
   cd ios
   pod install
   ```

3. **Open Xcode Project**
   ```bash
   cd ios
   open OpenPilot.xcworkspace
   ```

4. **Build in Xcode**
   - Select target device or simulator
   - Product â†’ Build (âŒ˜+B)
   - Product â†’ Archive (for IPA)

5. **Generate IPA**
   - Window â†’ Organizer
   - Select archive
   - Click "Distribute App"
   - Choose distribution method
   - Follow wizard to export IPA

6. **Install on Device**
   - Connect iPhone/iPad via USB
   - Open Xcode
   - Window â†’ Devices and Simulators
   - Drag IPA to device

## Testing

1. **Run on Simulator**
   ```bash
   npx react-native run-ios
   ```

2. **Run on Specific Simulator**
   ```bash
   npx react-native run-ios --simulator="iPhone 14 Pro"
   ```

3. **Run on Physical Device**
   ```bash
   npx react-native run-ios --device
   ```

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
