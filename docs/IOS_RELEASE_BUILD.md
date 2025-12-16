# iOS Release Build Guide

Complete guide for building and deploying FinSight on iOS devices and App Store.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Apple Developer Account](#apple-developer-account)
3. [Certificates & Provisioning](#certificates--provisioning)
4. [Xcode Configuration](#xcode-configuration)
5. [Building for Device](#building-for-device)
6. [TestFlight Distribution](#testflight-distribution)
7. [App Store Submission](#app-store-submission)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools
- **macOS** (iOS development requires Mac)
- **Xcode 14.0+** (download from App Store)
- **Flutter SDK 3.0.0+**
- **CocoaPods** (for dependency management)
- **Apple Developer Account** ($99/year)

### Verify Installation

```bash
# Check Xcode
xcodebuild -version
# Should show: Xcode 14.x or higher

# Check Flutter
flutter doctor -v

# Check CocoaPods
pod --version
# Should show: 1.11.x or higher
```

### Install CocoaPods (if needed)
```bash
sudo gem install cocoapods
```

---

## Apple Developer Account

### Step 1: Enroll in Program

1. Go to [Apple Developer Program](https://developer.apple.com/programs/)
2. Click **Enroll**
3. Sign in with your Apple ID
4. Pay $99/year enrollment fee
5. Wait for approval (usually 24-48 hours)

### Step 2: App ID Registration

1. Go to [Certificates, IDs & Profiles](https://developer.apple.com/account/resources)
2. Click **Identifiers** → **+**
3. Select **App IDs** → **Continue**
4. Configure:
   - **Description:** FinSight Expense Tracker
   - **Bundle ID:** `com.finsight.finsight` (Explicit)
   - **Capabilities:** Check required capabilities:
     - ✅ Push Notifications (if using)
     - ✅ iCloud (if using cloud sync)
     - ✅ Background Modes (if needed)
5. Click **Continue** → **Register**

---

## Certificates & Provisioning

### Method 1: Automatic Signing (Recommended for Beginners)

**Step 1: Open Xcode**
```bash
open ios/Runner.xcworkspace
```

**Step 2: Configure Signing**
1. Select **Runner** in project navigator
2. Select **Signing & Capabilities** tab
3. Check **Automatically manage signing**
4. Select your **Team** from dropdown
5. Xcode will automatically:
   - Create certificates
   - Create provisioning profiles
   - Download and install them

**Pros:**
- ✅ Simple and fast
- ✅ No manual certificate management

**Cons:**
- ❌ Limited control
- ❌ Can cause issues with CI/CD

---

### Method 2: Manual Signing (Recommended for Production)

#### Step 1: Create Certificates

**Development Certificate:**
```bash
# Generate CSR (Certificate Signing Request)
# 1. Open Keychain Access app
# 2. Keychain Access → Certificate Assistant → Request Certificate from a Certificate Authority
# 3. Fill in:
#    - Email: your@email.com
#    - Common Name: Your Name
#    - CA Email: leave empty
#    - Request: Saved to disk
# 4. Save as: CertificateSigningRequest.certSigningRequest
```

Upload to Apple Developer:
1. Go to [Certificates](https://developer.apple.com/account/resources/certificates)
2. Click **+** → **iOS App Development** → **Continue**
3. Upload CSR file
4. Download certificate
5. Double-click to install in Keychain

**Distribution Certificate:**
- Same process, but select **iOS Distribution** instead

#### Step 2: Create Provisioning Profiles

**Development Profile:**
1. Go to [Profiles](https://developer.apple.com/account/resources/profiles)
2. Click **+** → **iOS App Development** → **Continue**
3. Select App ID: `com.finsight.finsight`
4. Select Certificate (created above)
5. Select Devices (register devices first)
6. Name: `FinSight Development`
7. Download and double-click to install

**Distribution Profile:**
1. Click **+** → **App Store** → **Continue**
2. Select App ID: `com.finsight.finsight`
3. Select Distribution Certificate
4. Name: `FinSight App Store`
5. Download and install

#### Step 3: Register Devices (for Development)

1. Go to [Devices](https://developer.apple.com/account/resources/devices)
2. Click **+**
3. Enter:
   - **Device Name:** iPhone 14 Pro (or your device name)
   - **Device ID (UDID):** Find using steps below
4. Click **Continue** → **Register**

**Finding UDID:**

**Method 1 - Xcode:**
```bash
# Connect iPhone via USB
# Open Xcode → Window → Devices and Simulators
# Select your device
# Copy "Identifier" field
```

**Method 2 - Finder (macOS Catalina+):**
```bash
# Connect iPhone
# Open Finder → Select iPhone in sidebar
# Click on device info to cycle through options
# UDID will be displayed
```

---

## Xcode Configuration

### Step 1: Open Project
```bash
cd ios
open Runner.xcworkspace  # Important: Use .xcworkspace, not .xcodeproj
```

### Step 2: General Settings

Select **Runner** → **General** tab:

```
Display Name: FinSight
Bundle Identifier: com.finsight.finsight
Version: 1.0.0
Build: 1

Deployment Info:
├── iOS: 12.0 (minimum supported version)
├── iPhone ✅
└── iPad ✅

App Icons and Launch Screen:
└── Configure app icon set (1024x1024 required)
```

### Step 3: Signing & Capabilities

**For Development:**
```
Signing & Capabilities Tab:
├── Team: [Select your team]
├── Provisioning Profile: FinSight Development
└── Signing Certificate: Apple Development
```

**For Release:**
```
Release Configuration:
├── Team: [Select your team]
├── Provisioning Profile: FinSight App Store
└── Signing Certificate: Apple Distribution
```

### Step 4: Build Settings

Select **Runner** → **Build Settings** tab:

Search and update:
```
PRODUCT_BUNDLE_IDENTIFIER: com.finsight.finsight
MARKETING_VERSION: 1.0.0
CURRENT_PROJECT_VERSION: 1
IPHONEOS_DEPLOYMENT_TARGET: 12.0
SWIFT_VERSION: 5.0
ENABLE_BITCODE: No (Flutter doesn't support bitcode)
```

### Step 5: Info.plist Configuration

The Info.plist should already have:
```xml
<key>CFBundleDisplayName</key>
<string>FinSight</string>

<key>NSCameraUsageDescription</key>
<string>FinSight needs camera access to capture receipt images</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>FinSight needs photo library access to select receipt images</string>
```

Add additional permissions if needed:
```xml
<!-- If using location -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>FinSight uses your location to tag expenses</string>

<!-- If using notifications -->
<key>NSUserNotificationsUsageDescription</key>
<string>FinSight sends reminders for budget tracking</string>
```

---

## Building for Device

### Method 1: Using Flutter Command (Recommended)

**Step 1: Connect Device**
```bash
# Connect iPhone via USB
# Unlock device and tap "Trust This Computer"

# Verify device detected
flutter devices
# Should show your iPhone
```

**Step 2: Build and Install**

```bash
# Build for connected device
flutter run --release

# Or build without installing
flutter build ios --release
```

### Method 2: Using Xcode

**Step 1: Select Device**
- Open Xcode
- Top toolbar: Select your iPhone (not "Any iOS Device")

**Step 2: Build and Run**
- Click **Run** button (▶️) or press `⌘R`
- Xcode will:
  1. Build the app
  2. Install on device
  3. Launch automatically

### Common Build Issues

**Issue: "Untrusted Developer"**

When launching on device for first time:
1. iPhone shows: "Untrusted Developer"
2. Fix: **Settings → General → VPN & Device Management**
3. Tap your developer account
4. Tap **Trust "[Your Name]"**
5. Launch app again

---

## TestFlight Distribution

TestFlight allows beta testing with up to 10,000 external testers.

### Step 1: Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   ```
   Platform: iOS
   Name: FinSight
   Primary Language: English (U.S.)
   Bundle ID: com.finsight.finsight
   SKU: com.finsight.finsight.1.0.0
   User Access: Full Access
   ```
4. Click **Create**

### Step 2: Build Archive

**Using Flutter:**
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get
cd ios && pod install && cd ..

# Build release
flutter build ios --release --no-codesign

# Open Xcode to archive
open ios/Runner.xcworkspace
```

**In Xcode:**
1. Select **Product → Destination → Any iOS Device (arm64)**
2. Select **Product → Archive**
3. Wait for archive to complete (5-10 minutes)
4. Archive Organizer will open automatically

### Step 3: Upload to App Store Connect

**In Archive Organizer:**
1. Select your archive
2. Click **Distribute App**
3. Select **App Store Connect** → **Next**
4. Select **Upload** → **Next**
5. Choose options:
   ```
   ✅ Include bitcode: No (Flutter doesn't support)
   ✅ Upload symbols: Yes (for crash reports)
   ✅ Manage version and build number: Yes
   ```
6. Click **Next** → **Upload**
7. Wait for upload (10-20 minutes)

### Step 4: Configure TestFlight

**In App Store Connect:**

1. Go to **My Apps** → **FinSight** → **TestFlight** tab
2. Wait for "Processing" to complete (20-60 minutes)
3. Build will show status: **Ready to Submit**

**Add Internal Testers:**
1. Click **Internal Testing** → **+** → Add users
2. Select team members (up to 100)
3. Click **Add**
4. Testers receive email with TestFlight invite

**Add External Testers:**
1. Click **External Testing** → **+** → Create Group
2. Name group: "Beta Testers"
3. Add testers by email
4. Add build to group
5. Fill in beta test information:
   ```
   What to Test:
   - Receipt scanning with OCR
   - Expense categorization
   - Budget tracking
   - Export features
   - UI animations
   
   Known Issues:
   - None
   ```
6. Submit for Beta App Review (1-2 days)

### Step 5: Testers Install App

Testers receive email:
1. Install **TestFlight** app from App Store
2. Open invite email
3. Tap **View in TestFlight**
4. Tap **Install**
5. App installs like regular app

### Step 6: Collect Feedback

**TestFlight automatically collects:**
- Crash logs
- Screenshots (if testers submit)
- Feedback comments
- Usage metrics

**Access feedback:**
App Store Connect → FinSight → TestFlight → Feedback

---

## App Store Submission

### Step 1: Prepare App Information

**In App Store Connect:**

Go to **My Apps** → **FinSight** → **App Store** tab

**App Information:**
```
Name: FinSight - Expense Tracker
Subtitle: Smart Receipt Scanner & Budget Tracker
Privacy Policy URL: https://finsight.app/privacy
Category: Finance
  Secondary: Productivity
```

**Pricing and Availability:**
```
Price: Free
Availability: All countries
```

**App Privacy:**
1. Click **Edit** next to App Privacy
2. Answer privacy questionnaire:
   ```
   Data Collection:
   - Financial Info: Expenses, Transactions
   - Photos: Receipt images
   - Usage Data: Analytics (if using)
   
   Purpose:
   - App Functionality
   - Analytics (optional)
   
   Linked to User: No (all data stored locally)
   Tracking: No
   ```

### Step 2: Prepare App Store Listing

**Version Information:**
```
Version: 1.0.0
Copyright: 2025 FinSight
```

**Description (4000 chars max):**
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
• All data stored locally on your device
• No ads, no tracking
• Your data belongs to you

PERFECT FOR:
• Freelancers tracking business expenses
• Families managing household budgets
• Students monitoring spending
• Anyone wanting better financial visibility

Download FinSight today and take control of your finances!

---
Questions or feedback? Contact us at: support@finsight.app
```

**Keywords:**
```
expense,receipt,scanner,budget,finance,tracker,ocr,money,spending,accounting
```
(Max 100 characters, comma-separated)

**Support URL:**
```
https://finsight.app/support
```

**Marketing URL (optional):**
```
https://finsight.app
```

### Step 3: Prepare Screenshots

**Required Screenshots:**

**iPhone 6.7" Display (iPhone 14 Pro Max):**
- Size: 1290 x 2796 pixels
- Minimum: 3 screenshots
- Recommended: 5-8 screenshots

**iPhone 6.5" Display (iPhone 11 Pro Max):**
- Size: 1242 x 2688 pixels
- Minimum: 3 screenshots

**iPad Pro 12.9" Display:**
- Size: 2048 x 2732 pixels
- Minimum: 3 screenshots

**Screenshot Tips:**
1. Show key features (scanner, dashboard, charts)
2. Use device frames
3. Add captions/annotations
4. Show actual app UI (no mockups)
5. Avoid excessive text

**Taking Screenshots:**
```bash
# Run app on simulator
flutter run -d "iPhone 14 Pro Max"

# In simulator: ⌘S to capture screenshot
# Files saved to Desktop
```

**Tools for Screenshot Enhancement:**
- [Screenshot Creator](https://screenshot-creator.com)
- [App Store Screenshot](https://appscreenshot.app)
- Figma or Sketch

### Step 4: Upload Build

1. Scroll to **Build** section
2. Click **+** next to build number
3. Select your TestFlight build
4. Wait for processing

### Step 5: App Review Information

```
Sign-in required: No (unless you have login)

Contact Information:
- First Name: [Your first name]
- Last Name: [Your last name]
- Phone: [Your phone]
- Email: support@finsight.app

Notes:
The app stores all data locally on the device. No server-side components are required for review.

Demo Account (if login required):
- Username: demo@finsight.app
- Password: Demo123!
```

### Step 6: Version Release

```
Release Options:
├── Automatically release this version: ✅ (Recommended)
├── Manually release this version: ◻️
└── Scheduled release: ◻️
```

### Step 7: Submit for Review

1. Click **Add for Review** (top right)
2. Review all sections (marked in green when complete)
3. Click **Submit to App Review**
4. Confirmation: "Your app has been submitted"

### Step 8: Review Process

**Timeline:**
- Initial review: 24-48 hours
- Additional reviews (if needed): 24 hours each

**Status Updates:**
1. **Waiting for Review** - In queue
2. **In Review** - Being reviewed
3. **Pending Developer Release** - Approved, awaiting your release
4. **Ready for Sale** - Live on App Store!

**Common Rejection Reasons:**
- Incomplete app information
- Misleading screenshots
- Missing privacy policy
- App crashes on launch
- Incomplete functionality

### Step 9: Post-Approval

**After approval:**
1. App appears on App Store within 24 hours
2. Users can download via: [App Store Link]
3. Monitor reviews and ratings
4. Respond to user feedback

---

## Version Updates

### Step 1: Update Version Numbers

**In pubspec.yaml:**
```yaml
version: 1.0.1+2  # 1.0.1 = version, 2 = build number
```

**Or in Xcode:**
```
General Tab:
├── Version: 1.0.1
└── Build: 2
```

### Step 2: Build New Archive

```bash
flutter clean
flutter build ios --release --no-codesign
open ios/Runner.xcworkspace
```

In Xcode:
- Product → Archive
- Distribute to App Store Connect

### Step 3: Submit Update

**In App Store Connect:**
1. Go to **My Apps** → **FinSight**
2. Click **+** next to Versions → **iOS**
3. Enter new version: `1.0.1`
4. Update "What's New in This Version":
   ```
   Bug Fixes & Improvements:
   • Fixed receipt scanner accuracy
   • Improved export performance
   • UI refinements
   • Bug fixes
   ```
5. Select new build
6. Submit for review

---

## Troubleshooting

### Issue: "No provisioning profiles found"

**Solution:**
```bash
# In Xcode:
Preferences → Accounts → [Your Apple ID] → Download Manual Profiles

# Or use automatic signing:
Signing & Capabilities → ✅ Automatically manage signing
```

---

### Issue: "Codesign failed with exit code 1"

**Error:**
```
error: Signing for "Runner" requires a development team.
```

**Solution:**
1. Open `ios/Runner.xcworkspace`
2. Select **Runner** → **Signing & Capabilities**
3. Select your **Team**
4. Ensure signing certificate is valid

---

### Issue: "Archive not showing in Organizer"

**Solution:**
```bash
# 1. Clean build folder
Product → Clean Build Folder (⇧⌘K)

# 2. Ensure correct scheme
Product → Scheme → Edit Scheme → Build Configuration: Release

# 3. Ensure correct destination
Product → Destination → Any iOS Device (arm64)

# 4. Archive again
Product → Archive
```

---

### Issue: "Pod install fails"

**Error:**
```
[!] CocoaPods could not find compatible versions for pod "XXX"
```

**Solution:**
```bash
cd ios

# Clear pod cache
rm -rf Pods
rm Podfile.lock

# Update CocoaPods
pod repo update

# Install dependencies
pod install --repo-update

cd ..
```

---

### Issue: "Build takes very long time"

**Solution:**
```bash
# 1. Clean Flutter build
flutter clean

# 2. Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# 3. Close other Xcode projects

# 4. Restart Xcode

# 5. Build again
flutter build ios --release
```

---

### Issue: "App crashes on launch (Release only)"

**Solution:**

1. **Enable crash logs:**
   ```bash
   # Connect device
   # Xcode → Window → Devices and Simulators
   # Select device → View Device Logs
   ```

2. **Common causes:**
   - Missing Info.plist permissions
   - Asset catalog issues
   - Network security settings
   
3. **Test in Release mode:**
   ```bash
   flutter run --release
   # Debug crashes before archiving
   ```

---

### Issue: "Upload to App Store failed"

**Error:**
```
ERROR ITMS-90XXX: ...
```

**Solutions:**

**ITMS-90339 (Deprecated API):**
```
Update to latest Flutter SDK:
flutter upgrade
```

**ITMS-90171 (Invalid Bundle Structure):**
```
Clean and rebuild:
flutter clean
flutter build ios --release --no-codesign
```

**ITMS-90685 (Missing CFBundleVersion):**
```
Ensure version and build set in pubspec.yaml:
version: 1.0.0+1
```

---

## Quick Reference Commands

### Build Commands
```bash
# Development build
flutter run

# Release build for device
flutter run --release

# Build iOS (no install)
flutter build ios --release

# Build with Xcode
open ios/Runner.xcworkspace
# Then: Product → Archive
```

### Device Commands
```bash
# List devices
flutter devices

# Install on specific device
flutter run -d [device-id]

# View device logs
flutter logs

# Screenshot from simulator
# Simulator: ⌘S (saves to Desktop)
```

### Pod Commands
```bash
cd ios

# Install pods
pod install

# Update pods
pod update

# Clean pods
rm -rf Pods Podfile.lock
pod install

cd ..
```

### Xcode Commands
```bash
# Open workspace
open ios/Runner.xcworkspace

# Clean build
# Xcode: Product → Clean Build Folder (⇧⌘K)

# View archives
# Xcode: Window → Organizer

# View logs
# Xcode: Window → Devices and Simulators
```

---

## Pre-Release Checklist

Before submitting to App Store:

- [ ] App tested on physical devices (iPhone & iPad)
- [ ] All features working in Release mode
- [ ] No crashes or major bugs
- [ ] Privacy policy published
- [ ] Support email active
- [ ] App icon set (1024x1024)
- [ ] Screenshots prepared (3+ per size)
- [ ] App description written
- [ ] Keywords optimized
- [ ] Version/build numbers incremented
- [ ] TestFlight beta testing completed
- [ ] App Store Connect profile complete
- [ ] Provisioning profiles valid
- [ ] Certificates not expired

---

## Cost Summary

| Item | Cost | Frequency |
|------|------|-----------|
| Apple Developer Program | $99 | Annual |
| macOS Device (Mac required) | $1000+ | One-time |
| iPhone for testing | $500+ | Optional |
| App Store listing | Free | N/A |
| TestFlight distribution | Free | N/A |

**Total minimum:** $99/year (if you already have Mac)

---

## Timeline Estimate

| Task | Duration |
|------|----------|
| Apple Developer enrollment | 1-2 days |
| Certificate/provisioning setup | 1-2 hours |
| First build and archive | 30 minutes |
| TestFlight upload | 20-60 minutes |
| TestFlight processing | 20-60 minutes |
| Beta App Review | 1-2 days |
| Beta testing | 1-2 weeks |
| App Store submission | 30 minutes |
| App Review | 1-3 days |
| **Total (first release):** | **2-3 weeks** |

---

## Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Flutter iOS Deployment](https://flutter.dev/docs/deployment/ios)
- [TestFlight Guide](https://developer.apple.com/testflight/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

**Document Version:** 1.0.0  
**Last Updated:** December 15, 2025  
**Maintained by:** FinSight Development Team
