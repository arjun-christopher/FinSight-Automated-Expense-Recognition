# FinSight - Automated Expense Recognition

A production-grade Flutter mobile application for automated expense tracking and receipt management with OCR capabilities.

## Project Overview

FinSight helps users effortlessly manage expenses by:
- Capturing receipt images using the device camera
- Automatically extracting expense details using ML Kit OCR
- Organizing and categorizing expenses
- Providing visual analytics and insights
- Exporting data to PDF/CSV formats

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Local Database**: sqflite
- **OCR**: Google ML Kit Text Recognition
- **Charts**: fl_chart
- **Image Capture**: camera, image_picker
- **Authentication**: Firebase Auth, Google Sign-In
- **Notifications**: Flutter Local Notifications
- **Export**: pdf, csv packages

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── router/
│   │   └── app_router.dart           # GoRouter configuration
│   ├── theme/
│   │   ├── app_theme.dart            # Light & Dark themes
│   │   └── theme_manager.dart        # Theme state management
│   └── widgets/
│       └── main_navigation.dart      # Bottom navigation bar
└── features/
    ├── dashboard/
    │   └── presentation/
    │       └── pages/
    │           └── dashboard_page.dart
    ├── expenses/
    │   └── presentation/
    │       └── pages/
    │           └── add_expense_page.dart
    ├── receipt/
    │   └── presentation/
    │       └── pages/
    │           └── receipt_capture_page.dart
    └── settings/
        └── presentation/
            └── pages/
                └── settings_page.dart
```

## Features (Current Implementation)

### ✅ Completed
- Clean architecture with feature-based folder structure
- Material 3 design with light/dark theme support
- Persistent theme preferences
- Bottom navigation with 4 main screens
- Smooth navigation with GoRouter
- Placeholder UI for all main features

### 🚧 Coming Soon
- Expense CRUD operations
- OCR-based receipt scanning
- Local database integration
- Analytics dashboard
- Firebase authentication
- Export to PDF/CSV
- Push notifications

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode for mobile development
- A code editor (VS Code recommended)

### Installation

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   # For development
   flutter run
   
   # For specific device
   flutter run -d <device_id>
   
   # List available devices
   flutter devices
   ```

3. **Build for production**
   ```bash
   # Android APK
   flutter build apk --release
   
   # Android App Bundle
   flutter build appbundle --release
   
   # iOS
   flutter build ios --release
   ```

### Platform Setup

#### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: Latest
- Permissions configured: Camera, Storage, Internet

#### iOS
- Minimum iOS version: 12.0
- Camera and Photo Library permissions configured

## Development Workflow

The app is being built feature by feature with a focus on:
- Clean code architecture
- Scalability and maintainability
- Best practices and conventions
- Production-ready quality

## 🎨 UI Polish & Animations

FinSight features a comprehensive animation system for a polished, professional user experience:

### Animation System
- **Custom Page Transitions**: Fade, slide, and scale transitions
- **Animated Cards**: Press effects, slide-in, expandable, flip, glass effects
- **Interactive Buttons**: Loading states, press animations, FAB with labels
- **Loading States**: Shimmer placeholders, skeleton screens
- **Success Animations**: Animated checkmarks and confirmations

### Key Features
- ✨ **Staggered List Animations**: Items slide in with 50ms delays
- ✨ **Professional Loading**: Shimmer cards instead of basic spinners
- ✨ **Smooth Interactions**: Scale, ripple, and rotation effects
- ✨ **Consistent Styling**: 16dp card radius, 12dp button radius, refined shadows
- ✨ **Enhanced Dark Mode**: Fully styled with proper contrast

### Quick Start
```dart
// Animated list item
SlideInCard(
  index: index,
  child: AnimatedCard(
    onTap: () => navigate(),
    child: ExpenseCard(),
  ),
)

// Loading button
AnimatedButton(
  onPressed: () => save(),
  isLoading: _isLoading,
  child: Text('Save'),
)

// Loading placeholder
ShimmerCard(width: double.infinity, height: 80)
```

### Documentation
- 📖 [UI Polish Guide](UI_POLISH_GUIDE.md) - Comprehensive documentation
- 🚀 [Quick Start](UI_POLISH_QUICK_START.md) - Get started in 5 minutes
- ✅ [Implementation Checklist](UI_POLISH_CHECKLIST.md) - Integration tasks
- 🎨 [Visual Reference](UI_POLISH_VISUAL_REFERENCE.md) - Animation diagrams
- 📝 [Task Summary](TASK_16_SUMMARY.md) - Complete implementation details

### Live Examples
Run `lib/examples/ui_polish_examples.dart` to see:
- All animated components in action
- Before/after migration comparisons
- Interactive demos of page transitions
- Loading states and success animations

## 📦 Release & Deployment

FinSight is fully configured for production deployment to physical devices and app stores.

### Quick Release
```bash
# Android (APK for device)
flutter build apk --release --split-per-abi

# Android (AAB for Play Store)
flutter build appbundle --release

# iOS (requires macOS & Xcode)
flutter build ios --release --no-codesign
open ios/Runner.xcworkspace  # Then: Product → Archive
```

### Platform Requirements

**Android:**
- ✅ Signing configured with keystore
- ✅ ProGuard obfuscation enabled
- ✅ Multi-ABI splits for smaller downloads
- ✅ Google Play Console ready ($25 one-time)

**iOS:**
- ✅ Xcode project configured
- ✅ Automatic/manual signing support
- ✅ TestFlight beta testing ready
- ✅ App Store Connect ready ($99/year)

### Documentation
- 🚀 [Quick Start Card](RELEASE_QUICK_START.md) - 5-minute release guide
- 📱 [Android Build Guide](ANDROID_RELEASE_BUILD.md) - Complete APK/AAB guide
- 🍎 [iOS Build Guide](IOS_RELEASE_BUILD.md) - Complete TestFlight/App Store guide
- 📖 [Deployment Guide](DEPLOYMENT_GUIDE.md) - Master cross-platform guide
- 📝 [Implementation Summary](TASK_17_SUMMARY.md) - Technical details

### Quick Install on Device
```bash
# Android - Enable USB debugging, then:
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# iOS - Connect device, then:
flutter run --release
```

## License

Copyright © 2025 FinSight. All rights reserved.