# Firebase Setup Guide for FinSight

This guide walks you through setting up Firebase Authentication with Google Sign-In for the FinSight app.

## Table of Contents

1. [Firebase Console Setup](#firebase-console-setup)
2. [Android Configuration](#android-configuration)
3. [iOS Configuration](#ios-configuration)
4. [Google Sign-In Configuration](#google-sign-in-configuration)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

---

## Firebase Console Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: **"FinSight"** (or your preferred name)
4. Accept terms and click **"Continue"**
5. (Optional) Enable Google Analytics
6. Click **"Create project"**
7. Wait for project creation to complete

### Step 2: Enable Authentication

1. In Firebase Console, select your project
2. Click **"Authentication"** in the left sidebar
3. Click **"Get started"**
4. Go to **"Sign-in method"** tab
5. Click on **"Google"** provider
6. Toggle **"Enable"**
7. Enter **"Project support email"** (your email)
8. Click **"Save"**

---

## Android Configuration

### Step 1: Add Android App to Firebase

1. In Firebase Console, click the Android icon (⚙️)
2. Enter Android package name: `com.finsight.app` (match your app's package name)
3. (Optional) Enter app nickname: "FinSight Android"
4. Get SHA-1 certificate fingerprint:

   ```bash
   # Debug SHA-1 (for development)
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release SHA-1 (for production)
   keytool -list -v -keystore /path/to/your/keystore.jks -alias your-key-alias
   ```

5. Copy SHA-1 fingerprint and paste in Firebase Console
6. Click **"Register app"**
7. Download `google-services.json`
8. Click **"Next"** → **"Next"** → **"Continue to console"**

### Step 2: Add google-services.json

1. Place `google-services.json` in `android/app/` directory

   ```
   android/
   └── app/
       └── google-services.json
   ```

### Step 3: Update Android Build Files

**android/build.gradle** (Project level):

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**android/app/build.gradle** (App level):

```gradle
// At the top, after 'apply plugin'
apply plugin: 'com.android.application'
apply plugin: 'com.google.gms.google-services'  // Add this line

android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.finsight.app"  // Your package name
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
    }
}
```

### Step 4: Update AndroidManifest.xml

No additional changes needed for Google Sign-In.

---

## iOS Configuration

### Step 1: Add iOS App to Firebase

1. In Firebase Console, click the iOS icon (🍎)
2. Enter iOS bundle ID: `com.finsight.app` (match your app's bundle ID)
3. (Optional) Enter app nickname: "FinSight iOS"
4. (Optional) Enter App Store ID (if published)
5. Click **"Register app"**
6. Download `GoogleService-Info.plist`
7. Click **"Next"** → **"Next"** → **"Continue to console"**

### Step 2: Add GoogleService-Info.plist

1. Open your iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Drag `GoogleService-Info.plist` into the `Runner` folder in Xcode
   - Make sure **"Copy items if needed"** is checked
   - Make sure **"Runner"** target is selected

3. Verify file is in correct location:
   ```
   ios/
   └── Runner/
       └── GoogleService-Info.plist
   ```

### Step 3: Update Info.plist

**ios/Runner/Info.plist**:

Add the following inside `<dict>` tag:

```xml
<dict>
    <!-- Existing keys... -->
    
    <!-- Add these for Google Sign-In -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <!-- Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
                <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
            </array>
        </dict>
    </array>
    
    <!-- Optional: Add this if you want to customize status bar -->
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
</dict>
```

**To find your REVERSED_CLIENT_ID:**
1. Open `GoogleService-Info.plist`
2. Find the `REVERSED_CLIENT_ID` key
3. Copy its value (looks like: `com.googleusercontent.apps.123456789-abcdefg`)
4. Replace `com.googleusercontent.apps.YOUR-CLIENT-ID` with this value

### Step 4: Update Podfile (if needed)

**ios/Podfile**:

```ruby
# Uncomment this line to define a global platform for your project
platform :ios, '12.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

Then run:
```bash
cd ios
pod install
cd ..
```

---

## Google Sign-In Configuration

### Web Client ID (for iOS)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to **"APIs & Services"** → **"Credentials"**
4. You should see OAuth 2.0 Client IDs:
   - Web client (auto-created by Google Service)
   - iOS client
   - Android client

### Configure OAuth Consent Screen

1. In Google Cloud Console, go to **"APIs & Services"** → **"OAuth consent screen"**
2. Select **"External"** user type
3. Fill in required fields:
   - App name: **FinSight**
   - User support email: your email
   - Developer contact: your email
4. Click **"Save and Continue"**
5. Skip scopes (default scopes are fine)
6. Add test users (your email) for testing
7. Click **"Save and Continue"**
8. Review and click **"Back to Dashboard"**

---

## Code Integration

### Step 1: Initialize Firebase in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

### Step 2: Setup Auth State Listener

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'FinSight',
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginPage();
          }
          return const HomePage();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}
```

### Step 3: Use LoginPage

The `LoginPage` is already created and ready to use. Just navigate to it:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const LoginPage()),
);
```

---

## Testing

### Test Google Sign-In Flow

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Tap "Sign in with Google" button**

3. **Select Google account**

4. **Verify authentication:**
   - User should be signed in
   - Firebase Console → Authentication → Users should show the new user

### Test Session Persistence

1. **Sign in to the app**
2. **Close the app completely**
3. **Reopen the app**
4. **Verify:** User should still be signed in (no login screen)

### Test Sign Out

1. **Navigate to Profile page**
2. **Tap "Sign Out"**
3. **Confirm sign out**
4. **Verify:** App should show login screen

---

## Troubleshooting

### Android Issues

#### Issue: "SHA-1 certificate fingerprint not configured"

**Solution:**
1. Generate SHA-1 certificate:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
2. Add SHA-1 to Firebase Console:
   - Go to Project Settings → Your apps → Android app
   - Scroll to "SHA certificate fingerprints"
   - Click "Add fingerprint"
   - Paste SHA-1 and save

#### Issue: "google-services.json not found"

**Solution:**
1. Download `google-services.json` from Firebase Console
2. Place in `android/app/` directory
3. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

#### Issue: "Google Play Services not available"

**Solution:**
- Use a real device or emulator with Google Play Services installed
- Update Google Play Services on device

### iOS Issues

#### Issue: "GoogleService-Info.plist not found"

**Solution:**
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to Xcode project properly (must be in Runner target)
3. Verify in Xcode: File should appear under Runner folder

#### Issue: "URL scheme not registered"

**Solution:**
1. Open `GoogleService-Info.plist`
2. Copy `REVERSED_CLIENT_ID` value
3. Add to `Info.plist` under `CFBundleURLSchemes`
4. Clean and rebuild:
   ```bash
   cd ios
   pod install
   cd ..
   flutter clean
   flutter run
   ```

#### Issue: "Keychain error"

**Solution:**
1. Reset simulator:
   ```bash
   xcrun simctl erase all
   ```
2. Or use a real device

### General Issues

#### Issue: "PlatformException: sign_in_failed"

**Causes:**
- OAuth consent screen not configured
- Wrong SHA-1 fingerprint
- Package name mismatch
- Bundle ID mismatch

**Solution:**
1. Verify OAuth consent screen is configured
2. Check SHA-1 is correct in Firebase Console
3. Verify package name matches in:
   - Firebase Console
   - `android/app/build.gradle`
   - `AndroidManifest.xml`
4. Verify bundle ID matches in:
   - Firebase Console
   - Xcode project settings
   - `Info.plist`

#### Issue: "User cancelled sign-in"

This is normal behavior when user dismisses Google Sign-In popup. Handle it gracefully:

```dart
final user = await authService.signInWithGoogle();
if (user == null) {
  // User cancelled - don't show error
  return;
}
```

#### Issue: "Network error"

**Solution:**
- Check internet connection
- Verify Firebase project is active
- Check firewall/proxy settings

---

## Production Checklist

Before releasing to production:

- [ ] Generate release SHA-1 certificate
- [ ] Add release SHA-1 to Firebase Console
- [ ] Set up OAuth consent screen for production
- [ ] Update app signing configuration
- [ ] Test on real devices (Android & iOS)
- [ ] Verify deep linking works
- [ ] Set up Firebase Analytics (optional)
- [ ] Configure App Check (optional, for security)
- [ ] Review Firebase security rules
- [ ] Enable multi-factor authentication (optional)
- [ ] Set up email templates for authentication
- [ ] Configure password policies (if using email auth later)
- [ ] Test error scenarios
- [ ] Set up monitoring and alerts

---

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Google Sign-In Plugin](https://pub.dev/packages/google_sign_in)
- [Firebase Auth Plugin](https://pub.dev/packages/firebase_auth)

---

## Support

If you encounter issues:

1. Check [FlutterFire Issues](https://github.com/firebase/flutterfire/issues)
2. Check [Google Sign-In Issues](https://github.com/flutter/plugins/issues)
3. Review Firebase Console logs
4. Enable Flutter debug logging:
   ```bash
   flutter run --verbose
   ```

---

**Setup complete!** 🎉 Your app is now ready to use Google Authentication with Firebase.
