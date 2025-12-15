# FinSight Release & Deployment Guide

**Complete guide for building, testing, and deploying FinSight to physical devices and app stores.**

---

## 📋 Quick Navigation

### Platform-Specific Guides
- 📱 [Android Release Build Guide](ANDROID_RELEASE_BUILD.md) - APK/AAB, Play Store
- 🍎 [iOS Release Build Guide](IOS_RELEASE_BUILD.md) - TestFlight, App Store

### Quick Start
- [Prerequisites](#prerequisites)
- [First-Time Setup](#first-time-setup)
- [Build for Testing](#build-for-testing)
- [Store Deployment](#store-deployment)

---

## Prerequisites

### Required Accounts
| Platform | Account | Cost | Required For |
|----------|---------|------|--------------|
| **Android** | Google Play Console | $25 one-time | Play Store publishing |
| **iOS** | Apple Developer Program | $99/year | App Store & TestFlight |

### Required Tools

**All Platforms:**
```bash
# Flutter SDK 3.0.0+
flutter --version

# Git (version control)
git --version
```

**Android Only:**
```bash
# Android SDK & Tools
android --version
adb --version

# Java JDK 11+
java -version
```

**iOS Only (macOS required):**
```bash
# Xcode 14.0+
xcodebuild -version

# CocoaPods
pod --version
```

### Verify Setup
```bash
# Check all dependencies
flutter doctor -v

# Should show:
# ✓ Flutter (version 3.x)
# ✓ Android toolchain
# ✓ Xcode (macOS only)
# ✓ Connected devices
```

---

## First-Time Setup

### 1. Clone Repository
```bash
git clone https://github.com/arjun-christopher/FinSight-Automated-Expense-Recognition.git
cd FinSight-Automated-Expense-Recognition
```

### 2. Install Dependencies
```bash
# Get Flutter packages
flutter pub get

# Android: No additional steps

# iOS: Install CocoaPods
cd ios
pod install
cd ..
```

### 3. Verify Build
```bash
# Test debug build
flutter run

# Should launch app on connected device/emulator
```

---

## Build for Testing

### Android - Install APK on Device

**Quick Install:**
```bash
# Build and install in one command
flutter run --release

# Or build APK separately
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Split APKs (smaller size):**
```bash
flutter build apk --release --split-per-abi

# Install the one matching your device:
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk  # Modern phones
adb install build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk  # Older phones
```

**Expected sizes:**
- Universal APK: ~80 MB
- arm64-v8a (modern): ~28 MB
- armeabi-v7a (older): ~25 MB

### iOS - Install on Device

**Prerequisites:**
- Mac with Xcode
- Apple Developer account
- Device UDID registered

**Quick Install:**
```bash
# Connect iPhone via USB
flutter run --release

# Xcode will handle signing automatically
```

**Manual Install:**
```bash
# 1. Build
flutter build ios --release

# 2. Open Xcode
open ios/Runner.xcworkspace

# 3. Select device and click Run (▶)
```

**First-time device setup:**
1. Connect iPhone
2. Unlock and trust computer
3. On iPhone: Settings → General → VPN & Device Management
4. Trust your developer certificate

---

## Store Deployment

### Android - Google Play Store

**Quick Start:**
1. **Generate signing key** (first time only)
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias finsight-key
   ```

2. **Configure signing**
   ```bash
   cp android/key.properties.template android/key.properties
   # Edit android/key.properties with your keystore info
   ```

3. **Build App Bundle**
   ```bash
   flutter build appbundle --release
   ```

4. **Upload to Play Console**
   - Go to [Google Play Console](https://play.google.com/console)
   - Create app → Upload `build/app/outputs/bundle/release/app-release.aab`
   - Complete store listing
   - Submit for review

**📖 Detailed Guide:** [ANDROID_RELEASE_BUILD.md](ANDROID_RELEASE_BUILD.md)

### iOS - App Store

**Quick Start:**
1. **Enroll in Apple Developer Program** ($99/year)
   - [developer.apple.com/programs](https://developer.apple.com/programs)

2. **Create App ID**
   - Bundle ID: `com.finsight.finsight`

3. **Build Archive**
   ```bash
   flutter build ios --release --no-codesign
   open ios/Runner.xcworkspace
   # Xcode: Product → Archive
   ```

4. **Upload to App Store Connect**
   - Xcode: Window → Organizer
   - Select archive → Distribute App
   - Upload to App Store Connect

5. **Submit for Review**
   - [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Complete app listing
   - Submit for review

**📖 Detailed Guide:** [IOS_RELEASE_BUILD.md](IOS_RELEASE_BUILD.md)

---

## Build Commands Reference

### Development Builds
```bash
# Debug build (hot reload enabled)
flutter run

# Release build (optimized)
flutter run --release

# Specific device
flutter run -d [device-id]
```

### Production Builds

**Android:**
```bash
# APK (direct install)
flutter build apk --release --split-per-abi

# AAB (Play Store)
flutter build appbundle --release

# With obfuscation
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols
```

**iOS:**
```bash
# Build (then archive in Xcode)
flutter build ios --release --no-codesign

# Open Xcode to archive
open ios/Runner.xcworkspace
# Product → Archive
```

### Clean Build
```bash
# Clean all build artifacts
flutter clean

# Reinstall dependencies
flutter pub get

# iOS: Reinstall pods
cd ios && pod install && cd ..

# Rebuild
flutter build [apk|appbundle|ios] --release
```

---

## Version Management

### Update Version Number

**Edit `pubspec.yaml`:**
```yaml
version: 1.0.1+2
#        ^^^^^ ^^
#        │     └─ Build number (integer, must increase)
#        └─ Version name (semantic versioning)
```

**Version naming conventions:**
- `1.0.0` - Initial release
- `1.0.1` - Bug fixes
- `1.1.0` - New features
- `2.0.0` - Major changes

### Git Tagging
```bash
# Tag release
git tag -a v1.0.0 -m "Version 1.0.0 - Initial Release"
git push origin v1.0.0

# List tags
git tag -l
```

---

## Testing Checklist

Before releasing:

### Functional Testing
- [ ] App launches successfully
- [ ] All core features work
- [ ] Camera/photo picker functional
- [ ] OCR extracts text correctly
- [ ] Database operations work
- [ ] Export functionality works
- [ ] Settings save properly
- [ ] No crashes in critical flows

### Platform Testing
- [ ] Tested on Android 8.0+ devices
- [ ] Tested on iOS 12.0+ devices
- [ ] Tested on different screen sizes
- [ ] Tested in portrait/landscape
- [ ] Tested light and dark modes

### Performance Testing
- [ ] App launches < 3 seconds
- [ ] Smooth 60fps animations
- [ ] No memory leaks
- [ ] Battery usage acceptable
- [ ] APK/IPA size reasonable

### Security Testing
- [ ] No hardcoded credentials
- [ ] No API keys in code
- [ ] Proper permission handling
- [ ] Data encryption (if storing sensitive)
- [ ] HTTPS only (if network calls)

---

## Common Issues & Solutions

### Issue: "Build failed with signing errors"

**Android:**
```bash
# Verify keystore exists
ls -la ~/upload-keystore.jks

# Verify key.properties configured
cat android/key.properties
```

**iOS:**
```bash
# Open Xcode
open ios/Runner.xcworkspace

# Check Signing & Capabilities tab
# Ensure team selected and certificate valid
```

### Issue: "App crashes on launch"

**Debug:**
```bash
# Android logs
adb logcat | grep flutter

# iOS logs (in Xcode)
# Window → Devices and Simulators → View Device Logs
```

**Common causes:**
- Missing permissions in AndroidManifest.xml / Info.plist
- Incompatible dependencies
- Asset loading issues

### Issue: "Flutter doctor shows errors"

**Common fixes:**
```bash
# Update Flutter
flutter upgrade

# Accept Android licenses
flutter doctor --android-licenses

# Xcode command line tools (macOS)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### Issue: "Dependencies conflict"

**Solution:**
```bash
# Clear dependency cache
flutter pub cache repair

# Update dependencies
flutter pub upgrade

# Reset pubspec.lock
rm pubspec.lock
flutter pub get
```

---

## Deployment Timeline

### Android (Google Play)

| Task | Duration | Notes |
|------|----------|-------|
| Account setup | 30 minutes | One-time, $25 |
| Keystore generation | 5 minutes | One-time |
| First build | 10 minutes | Subsequent: 5 min |
| Store listing | 1 hour | One-time |
| Review process | 1-3 days | Automated checks |
| **Total first release** | **2-4 days** | |

### iOS (App Store)

| Task | Duration | Notes |
|------|----------|-------|
| Developer enrollment | 1-2 days | $99/year |
| Certificate setup | 1 hour | One-time |
| First archive | 15 minutes | Subsequent: 10 min |
| TestFlight upload | 30-60 minutes | Processing time |
| Beta testing | 1-2 weeks | Optional |
| Store listing | 2 hours | One-time |
| Review process | 1-3 days | Manual review |
| **Total first release** | **2-3 weeks** | |

---

## File Structure

### Android Build Files
```
android/
├── app/
│   ├── build.gradle                    # Build configuration
│   ├── proguard-rules.pro              # Code obfuscation rules
│   └── src/main/
│       ├── AndroidManifest.xml         # App manifest
│       └── kotlin/                     # Native code
├── key.properties                      # Signing config (gitignored)
└── key.properties.template             # Template for above

build/app/outputs/
├── flutter-apk/
│   ├── app-release.apk                 # Universal APK
│   ├── app-arm64-v8a-release.apk       # 64-bit ARM
│   └── app-armeabi-v7a-release.apk     # 32-bit ARM
└── bundle/release/
    └── app-release.aab                 # App Bundle (Play Store)
```

### iOS Build Files
```
ios/
├── Runner.xcworkspace                  # Open this in Xcode
├── Runner/
│   ├── Info.plist                      # App configuration
│   └── Assets.xcassets/                # App icons
└── Podfile                             # Dependency management

build/ios/
└── archive/                            # Xcode archives
```

---

## Security Best Practices

### 🔒 Never Commit

```gitignore
# Signing keys
android/key.properties
android/app/*.jks
android/app/*.keystore
*.keystore

# iOS signing
ios/exportOptions.plist
ios/Runner.xcarchive

# API keys
.env
**/google-services.json
**/GoogleService-Info.plist

# Local configs
local.properties
```

### ✅ Always Do

1. **Use environment variables** for API keys
2. **Store keystores securely** (password manager, encrypted storage)
3. **Enable ProGuard** (Android obfuscation)
4. **Enable code obfuscation** (`--obfuscate` flag)
5. **Upload debug symbols** for crash reporting
6. **Enable 2FA** on Play Console and App Store Connect
7. **Backup signing keys** in multiple secure locations

### 📝 Document Securely

Keep secure records of:
- Keystore passwords
- Key aliases
- Certificate fingerprints
- Bundle IDs
- Account credentials

**Recommended tools:**
- 1Password, LastPass, Bitwarden (password managers)
- Encrypted USB drives (physical backup)
- Secure cloud storage with 2FA

---

## Post-Release

### Monitor Performance

**Android (Play Console):**
- Crashes & ANRs
- User ratings & reviews
- Install/uninstall stats
- Device compatibility

**iOS (App Store Connect):**
- Crash reports
- App analytics
- Ratings & reviews
- Sales & trends

### Update Strategy

**Bug Fixes (1.0.x):**
- Minor version bump
- Fast review process
- Push immediately

**New Features (1.x.0):**
- Minor version bump
- Beta test on TestFlight
- Staged rollout

**Major Updates (x.0.0):**
- Major version bump
- Extended beta testing
- Marketing campaign

### User Feedback

**Respond to reviews:**
- Reply within 24-48 hours
- Address bugs mentioned
- Thank positive feedback
- Professional tone

**Collect feedback:**
- In-app feedback form
- Email support
- Social media channels
- User surveys

---

## Cost Summary

### One-Time Costs
| Item | Cost |
|------|------|
| Google Play Developer Account | $25 |
| macOS device (for iOS) | $1000+ |

### Recurring Costs
| Item | Cost | Frequency |
|------|------|-----------|
| Apple Developer Program | $99 | Annual |
| Domain (optional) | $12 | Annual |
| Hosting for privacy policy (optional) | $5-10 | Monthly |

**Total Year 1 (both platforms):**
- With Mac: $1136+
- Without Mac (Android only): $25

**Total Year 2+:**
- Both platforms: $99-210/year
- Android only: $0

---

## Resources

### Official Documentation
- [Flutter Deployment Guide](https://flutter.dev/docs/deployment)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Android Developer Guide](https://developer.android.com/studio/publish)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)

### FinSight Documentation
- [Android Release Build Guide](ANDROID_RELEASE_BUILD.md)
- [iOS Release Build Guide](IOS_RELEASE_BUILD.md)
- [Main README](README.md)
- [UI Polish Guide](UI_POLISH_GUIDE.md)

### Community Support
- [Flutter Discord](https://discord.com/invite/flutter)
- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)
- [Reddit r/FlutterDev](https://reddit.com/r/FlutterDev)

---

## Quick Command Reference

```bash
# ============================================
# DEVELOPMENT
# ============================================

# Run debug build
flutter run

# Run release build
flutter run --release

# Hot reload
r

# Hot restart
R

# View logs
flutter logs

# ============================================
# ANDROID PRODUCTION
# ============================================

# Build APK
flutter build apk --release --split-per-abi

# Build App Bundle
flutter build appbundle --release

# Install on device
adb install app-release.apk

# View device logs
adb logcat | grep flutter

# ============================================
# iOS PRODUCTION
# ============================================

# Build iOS
flutter build ios --release --no-codesign

# Open Xcode
open ios/Runner.xcworkspace

# Archive in Xcode
# Product → Archive

# ============================================
# MAINTENANCE
# ============================================

# Clean build
flutter clean

# Update Flutter
flutter upgrade

# Update dependencies
flutter pub upgrade

# Check for issues
flutter doctor -v

# Analyze code
flutter analyze

# Run tests
flutter test
```

---

## Success Checklist

### Before First Release
- [ ] Both platform accounts created and verified
- [ ] Signing keys generated and backed up
- [ ] App tested on physical devices
- [ ] Store listings prepared (descriptions, screenshots)
- [ ] Privacy policy published
- [ ] Support email configured
- [ ] Version 1.0.0 tagged in Git
- [ ] All documentation reviewed

### Each Release
- [ ] Version number incremented
- [ ] Changelog updated
- [ ] Code tested thoroughly
- [ ] No critical bugs
- [ ] Build successful on both platforms
- [ ] Store listings updated (if needed)
- [ ] Release notes written
- [ ] Git tag created

### Post-Release
- [ ] Monitor crash reports first 48 hours
- [ ] Respond to initial reviews
- [ ] Track install metrics
- [ ] Plan next release
- [ ] Document issues/learnings

---

## Support

For issues specific to FinSight deployment:

1. Check platform-specific guide first:
   - [Android Guide](ANDROID_RELEASE_BUILD.md)
   - [iOS Guide](IOS_RELEASE_BUILD.md)

2. Review [Troubleshooting](#common-issues--solutions) section

3. Contact development team:
   - Email: dev@finsight.app
   - GitHub Issues: [Repository](https://github.com/arjun-christopher/FinSight-Automated-Expense-Recognition)

---

**Document Version:** 1.0.0  
**Last Updated:** December 15, 2025  
**Maintained by:** FinSight Development Team

**Happy Deploying! 🚀**
