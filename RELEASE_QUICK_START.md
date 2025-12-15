# 🚀 FinSight Release Quick Start Card

**Ultra-fast guide to release FinSight on physical devices and stores.**

---

## 📱 Android (5 Steps)

### 1️⃣ Generate Keystore (First Time Only)
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias finsight-key
```

### 2️⃣ Configure Signing
```bash
cd android
cp key.properties.template key.properties
# Edit key.properties with your keystore path and passwords
```

### 3️⃣ Build Release
```bash
# For device install (APK)
flutter build apk --release --split-per-abi

# For Play Store (AAB)
flutter build appbundle --release
```

### 4️⃣ Install on Device
```bash
# Modern phones (64-bit)
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Older phones (32-bit)
adb install build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

### 5️⃣ Upload to Play Store
1. Go to [play.google.com/console](https://play.google.com/console)
2. Create app → Upload `build/app/outputs/bundle/release/app-release.aab`
3. Complete listing → Submit for review

**Expected time:** 2-4 days (including review)  
**Cost:** $25 one-time

📖 **Full Guide:** [ANDROID_RELEASE_BUILD.md](ANDROID_RELEASE_BUILD.md)

---

## 🍎 iOS (6 Steps)

### 1️⃣ Prerequisites (macOS Only)
```bash
# Install Xcode from App Store
# Install CocoaPods
sudo gem install cocoapods

# Install iOS dependencies
cd ios && pod install && cd ..
```

### 2️⃣ Enroll in Apple Developer Program
- Visit [developer.apple.com/programs](https://developer.apple.com/programs)
- Pay $99/year enrollment fee
- Wait 1-2 days for approval

### 3️⃣ Configure Signing
```bash
open ios/Runner.xcworkspace
```
- Xcode → Signing & Capabilities
- Select your Team
- Enable "Automatically manage signing"

### 4️⃣ Build for Device
```bash
# Connect iPhone via USB
flutter run --release

# Or build and archive manually
flutter build ios --release --no-codesign
open ios/Runner.xcworkspace
# Xcode: Product → Archive
```

### 5️⃣ Upload to TestFlight
- Xcode → Window → Organizer
- Select archive → Distribute App
- Upload to App Store Connect
- Wait 20-60 minutes for processing

### 6️⃣ Submit to App Store
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. My Apps → FinSight → App Store
3. Complete store listing
4. Add build → Submit for review

**Expected time:** 2-3 weeks (including beta testing & review)  
**Cost:** $99/year

📖 **Full Guide:** [IOS_RELEASE_BUILD.md](IOS_RELEASE_BUILD.md)

---

## ⚡ Ultra-Quick Testing

### Android - Instant Install
```bash
flutter run --release
# Done! App installs and launches on connected device
```

### iOS - Instant Install (macOS)
```bash
flutter run --release
# Done! App installs and launches on connected iPhone
```

---

## 📋 Pre-Release Checklist

### Must Have ✅
- [ ] App tested on physical device
- [ ] No crashes in core features
- [ ] Camera/OCR working
- [ ] Database operations successful
- [ ] Privacy policy URL ready
- [ ] Support email active
- [ ] App icon 1024x1024 prepared
- [ ] Screenshots captured (3+ per platform)

### Security ✅
- [ ] No hardcoded API keys
- [ ] Keystore backed up securely
- [ ] key.properties in .gitignore
- [ ] Passwords stored securely (password manager)

---

## 💰 Quick Cost Reference

| Platform | Setup | Ongoing |
|----------|-------|---------|
| **Android** | $25 one-time | $0/year |
| **iOS** | $99/year | $99/year |
| **Both** | $124 | $99/year |

**Need Mac for iOS:** ~$1000 (one-time)

---

## ⏱️ Quick Timeline

| Platform | First Release | Updates |
|----------|--------------|---------|
| **Android** | 2-4 days | 1-2 days |
| **iOS** | 2-3 weeks | 1-3 days |

---

## 🔥 Most Used Commands

```bash
# ===========================
# DEVELOPMENT
# ===========================
flutter run --release                    # Quick test on device

# ===========================
# ANDROID PRODUCTION
# ===========================
flutter build apk --release --split-per-abi    # Device install
flutter build appbundle --release              # Play Store
adb install app-arm64-v8a-release.apk         # Install

# ===========================
# iOS PRODUCTION
# ===========================
flutter build ios --release --no-codesign      # Prepare build
open ios/Runner.xcworkspace                    # Open Xcode
# Then: Product → Archive

# ===========================
# MAINTENANCE
# ===========================
flutter clean                            # Clean build
flutter doctor -v                        # Check setup
flutter pub upgrade                      # Update deps
```

---

## 🆘 Quick Troubleshooting

### "Keystore not found"
```bash
# Verify path in android/key.properties
ls -la ~/upload-keystore.jks
```

### "Signing error"
```bash
# Android: Check key.properties
# iOS: Open Xcode → Signing & Capabilities → Select Team
```

### "Build fails"
```bash
flutter clean
flutter pub get
# Try build again
```

### "Device not detected"
```bash
# Android
adb devices

# iOS
flutter devices

# Enable USB debugging / trust computer
```

---

## 🎯 Success Criteria

### Ready to Ship When:
- ✅ App launches without crash
- ✅ Core features functional
- ✅ Tested on physical device
- ✅ No blocking bugs
- ✅ Store assets prepared
- ✅ Documentation reviewed

---

## 📚 Full Documentation

| Guide | Purpose | Length |
|-------|---------|--------|
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Master overview | 400 lines |
| [ANDROID_RELEASE_BUILD.md](ANDROID_RELEASE_BUILD.md) | Android details | 500 lines |
| [IOS_RELEASE_BUILD.md](IOS_RELEASE_BUILD.md) | iOS details | 600 lines |
| [TASK_17_SUMMARY.md](TASK_17_SUMMARY.md) | Implementation | 400 lines |

**Total Documentation:** 1900+ lines covering every scenario

---

## 🎉 You're Ready!

1. **Choose platform** (Android is faster to start)
2. **Follow numbered steps** above
3. **Check full guide** if you get stuck
4. **Ship your app!** 🚀

**Questions?** Check the comprehensive guides linked above!

---

**Last Updated:** December 15, 2025  
**Version:** 1.0.0
