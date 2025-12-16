# Google Authentication - Quick Start

## 🚀 5-Minute Setup

### Step 1: Firebase Console (Web)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create project: "FinSight"
3. Enable Authentication → Google Sign-In
4. Add Android app → Download `google-services.json`
5. Add iOS app → Download `GoogleService-Info.plist`

### Step 2: Android Setup

**Place file:**
```
android/app/google-services.json
```

**Get SHA-1:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Add SHA-1 to Firebase Console:**
- Project Settings → Your apps → Android → Add fingerprint

**Update `android/build.gradle`:**
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**Update `android/app/build.gradle`:**
```gradle
apply plugin: 'com.android.application'
apply plugin: 'com.google.gms.google-services'  // Add this
```

### Step 3: iOS Setup

**Add in Xcode:**
```
ios/Runner/GoogleService-Info.plist
```

**Update `ios/Runner/Info.plist`:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Get this from GoogleService-Info.plist REVERSED_CLIENT_ID -->
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

### Step 4: Initialize in Code

**main.dart:**
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}
```

### Step 5: Setup Auth Routing

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      home: authState.when(
        data: (user) => user != null ? HomePage() : LoginPage(),
        loading: () => SplashScreen(),
        error: (e, _) => ErrorScreen(),
      ),
    );
  }
}
```

---

## 📱 Common Operations

### Check if Signed In
```dart
final isSignedIn = ref.watch(isSignedInProvider);
```

### Get User Data
```dart
final userData = ref.watch(currentUserDataProvider);
print(userData?.email);
print(userData?.displayName);
```

### Sign Out
```dart
await ref.read(authControllerProvider.notifier).signOut();
```

### Protected Route
```dart
if (!ref.watch(isSignedInProvider)) {
  return LoginPage();
}
return ProtectedContent();
```

---

## 🐛 Quick Troubleshooting

**Android: "SHA-1 not configured"**
- Generate SHA-1 with keytool command
- Add to Firebase Console → Project Settings

**iOS: "URL scheme not registered"**
- Get REVERSED_CLIENT_ID from GoogleService-Info.plist
- Add to Info.plist CFBundleURLSchemes

**Both: "Sign-in failed"**
- Check google-services.json / GoogleService-Info.plist are in correct location
- Verify OAuth consent screen is configured
- Check package name / bundle ID matches

---

## 📚 Full Documentation

- **Complete Setup**: [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
- **API Documentation**: [AUTH_MODULE.md](AUTH_MODULE.md)
- **Task Summary**: [TASK_12_SUMMARY.md](TASK_12_SUMMARY.md)
- **Examples**: [auth_examples.dart](lib/examples/auth_examples.dart)

---

## ✅ Setup Checklist

- [ ] Created Firebase project
- [ ] Enabled Google Sign-In
- [ ] Added google-services.json (Android)
- [ ] Added GoogleService-Info.plist (iOS)
- [ ] Configured SHA-1 (Android)
- [ ] Configured URL scheme (iOS)
- [ ] Initialized Firebase in main.dart
- [ ] Set up auth routing
- [ ] Tested sign-in flow
- [ ] Tested session persistence

---

**Ready!** 🎉 Your app now has Google Authentication with automatic session persistence.
