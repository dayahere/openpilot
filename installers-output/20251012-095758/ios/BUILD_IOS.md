# iOS IPA Build Guide

## Prerequisites (macOS Required)
- macOS Ventura or later
- Xcode 14+
- CocoaPods
- Apple Developer Account

## Build Steps

1. Install dependencies:
```bash
cd mobile
npm install
cd ios
pod install
```

2. Open in Xcode:
```bash
open ios/OpenPilot.xcworkspace
```

3. Build and Archive:
- Select your team in Signing
- Choose 'Any iOS Device'
- Product > Archive

## Quick Test (Simulator)
```bash
cd mobile
npx react-native run-ios
```
