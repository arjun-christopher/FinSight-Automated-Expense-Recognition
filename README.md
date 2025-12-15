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

## License

Copyright © 2025 FinSight. All rights reserved.