# Android Release Build Guide

Complete guide for building and deploying FinSight on Android devices.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Generating Signing Key](#generating-signing-key)
3. [Configuring Signing](#configuring-signing)
4. [Building Release APK](#building-release-apk)
5. [Building App Bundle (AAB)](#building-app-bundle-aab)
6. [Installing on Device](#installing-on-device)
7. [Play Store Deployment](#play-store-deployment)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools
- Flutter SDK (3.0.0 or higher)
- Android Studio or Android SDK
- Java Development Kit (JDK 11 or higher)
- Physical Android device or emulator

### Verify Installation
```bash
flutter doctor -v
java -version
```

---

## Generating Signing Key

### Step 1: Create a Keystore

**On macOS/Linux:**
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias finsight-key
```

**On Windows:**
```cmd
keytool -genkey -v -keystore %USERPROFILE%\upload-keystore.jks ^
  -keyalg RSA -keysize 2048 -validity 10000 ^
  -alias finsight-key
```

### Step 2: Answer the Prompts

```
Enter keystore password: [Create a strong password]
Re-enter new password: [Confirm password]
What is your first and last name? [Your Name]
What is the name of your organizational unit? [Your Team/Company]
What is the name of your organization? [FinSight]
What is the name of your City or Locality? [Your City]
What is the name of your State or Province? [Your State]
What is the two-letter country code for this unit? [US]
Is CN=..., correct? [yes]

[Enter] to use the same password as the keystore password
```

### Step 3: Secure Your Keystore

⚠️ **CRITICAL SECURITY:**
- **NEVER** commit the keystore to version control
- **BACKUP** the keystore in a secure location (password manager, encrypted storage)
- **DOCUMENT** the passwords securely
- **LOSING** the keystore means you cannot update your app on Play Store

**Recommended Storage:**
1. Password Manager (1Password, LastPass, Bitwarden)
2. Encrypted cloud storage with 2FA
3. Physical backup on encrypted USB drive

---

## Configuring Signing

### Step 1: Copy Template
```bash
cd android
cp key.properties.template key.properties
```

### Step 2: Edit key.properties

Open `android/key.properties` and fill in your values:

```properties
storePassword=YOUR_STRONG_KEYSTORE_PASSWORD
keyPassword=YOUR_STRONG_KEY_PASSWORD
keyAlias=finsight-key
storeFile=/Users/yourname/upload-keystore.jks
```

**Important:**
- Use absolute path for `storeFile`
- Use forward slashes `/` even on Windows
- Example Windows path: `C:/Users/yourname/upload-keystore.jks`

### Step 3: Verify .gitignore

Ensure `android/key.properties` is in `.gitignore`:
```bash
grep -r "key.properties" .gitignore
```

You should see: `android/key.properties`

---

## Building Release APK

### Build Commands

**Standard APK (all architectures):**
```bash
flutter build apk --release
```

**Split APKs by architecture (recommended for smaller files):**
```bash
flutter build apk --release --split-per-abi
```

This creates separate APKs for:
- `app-armeabi-v7a-release.apk` (~25 MB) - Older 32-bit ARM devices
- `app-arm64-v8a-release.apk` (~28 MB) - Modern 64-bit ARM devices (most phones)
- `app-x86_64-release.apk` (~30 MB) - Intel/AMD emulators and tablets

**With optimization flags:**
```bash
flutter build apk --release \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols
```

### Build Output Location
```
build/app/outputs/flutter-apk/
├── app-armeabi-v7a-release.apk
├── app-arm64-v8a-release.apk
├── app-x86_64-release.apk
└── app-release.apk (universal, ~80 MB)
```

### Build Flags Explained

| Flag | Purpose |
|------|---------|
| `--release` | Production build with optimizations |
| `--split-per-abi` | Separate APK per CPU architecture (smaller) |
| `--obfuscate` | Obfuscate Dart code (harder to reverse engineer) |
| `--split-debug-info` | Save symbols for crash analysis |

---

## Building App Bundle (AAB)

### Why App Bundle?

✅ **Advantages:**
- Required for Play Store (since August 2021)
- Smaller downloads (~50% reduction)
- Automatic APK generation for each device
- Better optimization

❌ **Disadvantages:**
- Cannot install directly on device
- Only works with Play Store

### Build Command

```bash
flutter build appbundle --release
```

**With optimization:**
```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols
```

### Output Location
```
build/app/outputs/bundle/release/app-release.aab
```

---

## Installing on Device

### Method 1: ADB Install (Recommended)

**Step 1: Enable Developer Options**
1. Go to **Settings → About Phone**
2. Tap **Build Number** 7 times
3. Go back to **Settings → Developer Options**
4. Enable **USB Debugging**

**Step 2: Connect Device**
```bash
# Verify device connected
adb devices

# Should show:
# List of devices attached
# ABC123456789    device
```

**Step 3: Install APK**

For universal APK:
```bash
flutter install
# or
adb install build/app/outputs/flutter-apk/app-release.apk
```

For split APK (install the one matching your device):
```bash
# For most modern devices (64-bit ARM)
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# For older devices (32-bit ARM)
adb install build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

**Step 4: Launch App**
```bash
adb shell am start -n com.finsight.finsight/.MainActivity
```

### Method 2: Direct File Transfer

**Step 1: Transfer APK**
1. Connect device via USB
2. Copy APK to device storage:
```bash
adb push build/app/outputs/flutter-apk/app-release.apk /sdcard/Download/
```

**Step 2: Install from Device**
1. Open **Files** app on device
2. Navigate to **Downloads**
3. Tap `app-release.apk`
4. Tap **Install** (may need to enable "Install unknown apps")

### Method 3: Wireless Install

**Using ADB over WiFi:**
```bash
# 1. Connect device via USB first
adb tcpip 5555

# 2. Find device IP (Settings → About → Status → IP address)
# 3. Connect wirelessly
adb connect 192.168.1.XXX:5555

# 4. Disconnect USB, install as normal
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Play Store Deployment

### Step 1: Create Play Console Account

1. Go to [Google Play Console](https://play.google.com/console)
2. Pay one-time $25 registration fee
3. Complete account verification

### Step 2: Create App Listing

1. Click **Create app**
2. Fill in app details:
   - **App name:** FinSight - Expense Tracker
   - **Default language:** English (United States)
   - **App or game:** App
   - **Free or paid:** Free

### Step 3: Complete Store Listing

**Main Store Listing:**
- **Short description** (80 chars): "Automated expense tracking with receipt OCR and smart insights"
- **Full description** (4000 chars): [See template below](#store-listing-template)
- **App icon:** 512x512 PNG
- **Feature graphic:** 1024x500 PNG
- **Screenshots:** At least 2 phone screenshots (1080x1920 or similar)

**Categorization:**
- **App category:** Finance
- **Tags:** expense tracker, receipt scanner, budget, OCR

**Content rating:**
- Complete questionnaire
- Expected rating: Everyone

**Privacy policy:**
- URL to your privacy policy (required)

### Step 4: Upload App Bundle

1. Go to **Production → Releases**
2. Click **Create new release**
3. Upload `build/app/outputs/bundle/release/app-release.aab`
4. Set release name: `1.0.0 (1)`
5. Add release notes:
```
Initial release of FinSight:
• Capture and scan receipts with OCR
• Automatic expense categorization
• Budget tracking and insights
• Export to PDF/CSV
• Dark mode support
```

### Step 5: Review and Publish

1. Complete all required sections (marked in red)
2. Submit for review
3. Review typically takes 1-3 days
4. App goes live automatically upon approval

### Version Updates

**Increment version:**

Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # 1.0.1 is version name, 2 is version code
```

**Build and upload:**
```bash
flutter build appbundle --release
```

Upload to Play Console under new release.

---

## Store Listing Template

### Short Description
```
Automated expense tracking with receipt OCR and smart insights
```

### Full Description
```
FinSight - Your Smart Expense Tracker

Effortlessly manage your expenses with FinSight, the intelligent expense tracking app that uses advanced OCR technology to digitize your receipts instantly.

KEY FEATURES:

📷 Receipt Scanner
• Capture receipts with your camera
• Automatic text extraction using ML Kit OCR
• Extract merchant, date, amount, and items

🤖 Smart Categorization
• AI-powered expense categorization
• Learn from your spending patterns
• Custom category support

💰 Budget Management
• Set monthly budgets by category
• Track spending in real-time
• Get alerts when approaching limits

📊 Visual Analytics
• Beautiful charts and graphs
• Spending trends over time
• Category breakdowns

📁 Export & Backup
• Export to PDF or CSV
• Secure local storage
• Cloud backup support (coming soon)

🎨 Beautiful Design
• Modern Material Design 3
• Smooth animations
• Dark mode support

🔒 Privacy First
• All data stored locally
• No ads, no tracking
• Your data belongs to you

PERFECT FOR:
• Freelancers tracking business expenses
• Families managing household budgets
• Anyone wanting better financial visibility

Download FinSight today and take control of your finances!

---

Questions or feedback? Contact us at: support@finsight.app
```

---

## Troubleshooting

### Issue: "Keystore not found"

**Error:**
```
FAILURE: Build failed with an exception.
* What went wrong:
Execution failed for task ':app:validateSigningRelease'.
> Keystore file '/path/to/keystore.jks' not found for signing config 'release'.
```

**Solution:**
1. Verify keystore path in `android/key.properties`
2. Use absolute path
3. Check file exists: `ls -la /path/to/keystore.jks`

---

### Issue: "Wrong password"

**Error:**
```
Keystore was tampered with, or password was incorrect
```

**Solution:**
1. Verify password in `android/key.properties`
2. Test keystore:
```bash
keytool -list -v -keystore /path/to/keystore.jks
```
3. Enter password to verify it works

---

### Issue: "Build fails with ProGuard errors"

**Error:**
```
ERROR: R8: Missing class...
```

**Solution:**
1. Check `android/app/proguard-rules.pro` has proper keep rules
2. Add specific rules for failing classes:
```proguard
-keep class com.your.failing.Class { *; }
```
3. Temporarily disable minification to test:
Edit `android/app/build.gradle`:
```gradle
minifyEnabled false
shrinkResources false
```

---

### Issue: "APK too large"

**Problem:** Universal APK is 80+ MB

**Solution:**
1. Use split APKs:
```bash
flutter build apk --release --split-per-abi
```

2. Or use App Bundle for Play Store:
```bash
flutter build appbundle --release
```

---

### Issue: "Installation failed on device"

**Error:**
```
adb: failed to install app-release.apk: Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE]
```

**Solution:**
1. Uninstall existing app first:
```bash
adb uninstall com.finsight.finsight
```

2. Then install again:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

### Issue: "ADB device not found"

**Error:**
```
adb devices
List of devices attached
[empty]
```

**Solution:**

**Android:**
1. Enable USB Debugging (Settings → Developer Options)
2. Reconnect USB cable
3. On device, tap "Allow USB debugging" popup
4. Try different USB cable/port

**macOS specific:**
```bash
brew install android-platform-tools
```

**Windows specific:**
- Install USB drivers from device manufacturer
- Try different USB ports (USB 2.0 vs 3.0)

---

### Issue: "Play Store rejects AAB"

**Error:**
```
Your app bundle contains native code, and you've not uploaded debug symbols
```

**Solution:**
Build with debug symbols:
```bash
flutter build appbundle --release \
  --split-debug-info=build/app/outputs/symbols
```

Upload symbols:
1. Go to Play Console → App Releases
2. Under the release, click "Manage" → "Native debug symbols"
3. Upload `symbols.zip`

---

## Quick Reference Commands

### Build Commands
```bash
# APK (direct install)
flutter build apk --release --split-per-abi

# AAB (Play Store)
flutter build appbundle --release

# With obfuscation
flutter build apk --release --obfuscate --split-debug-info=build/symbols

# Clean build
flutter clean && flutter build apk --release
```

### Device Commands
```bash
# List devices
adb devices

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Uninstall app
adb uninstall com.finsight.finsight

# View logs
adb logcat | grep flutter

# Take screenshot
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png
```

### Verification Commands
```bash
# Check keystore
keytool -list -v -keystore /path/to/keystore.jks

# Check APK signature
keytool -printcert -jarfile app-release.apk

# Check APK contents
unzip -l app-release.apk

# Check APK size by ABI
ls -lh build/app/outputs/flutter-apk/
```

---

## Security Checklist

Before releasing:

- [ ] Keystore backed up in secure location
- [ ] Passwords stored in password manager
- [ ] `key.properties` added to `.gitignore`
- [ ] No hardcoded API keys in code
- [ ] ProGuard rules configured
- [ ] Code obfuscation enabled
- [ ] Debug logging disabled
- [ ] App permissions justified
- [ ] Privacy policy published
- [ ] Terms of service published

---

## Next Steps

After successful Android release:
1. ✅ Test on multiple physical devices
2. ✅ Monitor Play Console for crash reports
3. ✅ Set up analytics (Firebase Analytics)
4. ✅ Configure in-app updates
5. ✅ Plan beta testing program
6. ✅ Prepare iOS build (see `IOS_RELEASE_BUILD.md`)

---

## Resources

- [Flutter Deployment Docs](https://flutter.dev/docs/deployment/android)
- [Google Play Console](https://play.google.com/console)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [ProGuard Rules](https://www.guardsquare.com/manual/configuration/usage)

---

**Document Version:** 1.0.0  
**Last Updated:** December 15, 2025  
**Maintained by:** FinSight Development Team
