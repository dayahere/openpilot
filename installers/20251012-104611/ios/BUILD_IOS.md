# iOS Build Guide

**IMPORTANT:** iOS builds require macOS with Xcode. Cannot be built on Windows.

## Prerequisites (macOS only)
- macOS Ventura or later
- Xcode 14+
- CocoaPods: `sudo gem install cocoapods`
- Apple Developer Account

## Build on macOS

`bash
cd /path/to/openpilot/mobile

# Install dependencies
npm install

# Install iOS dependencies
cd ios
pod install

# Open in Xcode
open OpenPilot.xcworkspace

# In Xcode:
# 1. Select your team in "Signing & Capabilities"
# 2. Choose "Any iOS Device" or connected device
# 3. Product â†’ Archive
# 4. Window â†’ Organizer
# 5. Distribute App â†’ Follow wizard
`

## Test on Simulator (macOS)

`bash
cd mobile
npx react-native run-ios
`

## Test on Device (macOS)

`bash
# Connect iPhone via USB
# Trust computer on device
npx react-native run-ios --device
`

## Alternative: Use macOS Cloud Service

If you don't have a Mac:
- **MacStadium**: Rent macOS VM
- **MacinCloud**: macOS cloud hosting  
- **GitHub Actions**: Use macOS runner (automated)
- **CircleCI**: macOS build environment
