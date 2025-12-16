# FinSight Branding Integration Guide

## Overview
This document describes the complete branding integration including app icons, splash screens, and logo placement throughout the app.

## 1. App Icon & Splash Screen Setup

### Prerequisites
Ensure the logo assets are placed in the correct locations:

```
assets/
  ├── icons/
  │   └── finsight_icon.png        (1024x1024 - hexagonal gradient icon)
  ├── images/
  │   └── finsight_logo_splash.png (512x512 - for splash screen)
  └── branding/
      └── finsight_branding.png    (300x100 - logo with text)
```

### Color Scheme
- **Primary Green**: `#2E7D32`
- **Accent Cyan**: `#00BCD4`
- **Gradient**: Linear gradient from green to cyan

### Generate App Icons

After placing the logo files, run:

```bash
# Install dependencies
flutter pub get

# Generate app icons for Android & iOS
flutter pub run flutter_launcher_icons

# Generate native splash screens
flutter pub run flutter_native_splash:create
```

This will:
- Create adaptive icons for Android (API 26+)
- Generate iOS app icons in all required sizes
- Create native splash screens for both platforms
- Apply the gradient background color

### Configuration Files

**flutter_icons_config.yaml** - Contains icon and splash configurations:
- Android adaptive icon with green background
- iOS icons in all standard sizes
- Splash screen with gradient background
- Branding image at bottom for Android 12+

## 2. Animated Splash Screen

### Implementation
The app features a custom animated splash screen that shows on every app launch.

**Location**: `lib/core/widgets/animated_splash_screen.dart`

**Features**:
- 🎨 **4-Layer Animation System**:
  1. Fade-in effect (0 to 1 opacity)
  2. Scale animation (0.5x to 1.2x with elastic bounce)
  3. Gradient rotation (360° full rotation)
  4. Ripple effect (3 expanding circles)
  
- 🌈 **Visual Elements**:
  - Animated gradient background (green to cyan)
  - Logo with scale and fade animations
  - Ripple effect emanating from center
  - App name with tagline
  - Version number display
  - Loading indicator

- ⚙️ **Technical Details**:
  - Duration: 3 seconds (configurable)
  - Uses 4 AnimationControllers
  - Custom painters for logo fallback and ripples
  - Completion callback to transition to main app

### Integration
Splash screen is automatically shown on app launch via `main.dart`:

```dart
// Splash complete state provider
final splashCompleteProvider = StateProvider<bool>((ref) => false);

// Shows splash first, then main app
home: splashComplete
  ? MaterialApp.router(...)
  : AnimatedSplashScreen(
      onComplete: () {
        ref.read(splashCompleteProvider.notifier).state = true;
      },
    ),
```

## 3. Logo in App UI

### Branded AppBar

Use `BrandedAppBar` for consistent branding across all pages:

```dart
import 'package:finsight/core/widgets/branded_widgets.dart';

Scaffold(
  appBar: BrandedAppBar(
    title: 'Dashboard',
    showLogo: true,  // Shows FinSight logo + title
    actions: [...],
  ),
)
```

**Features**:
- 32x32 logo icon with rounded corners
- Logo + title combination
- Shadow effect for depth
- Fallback gradient icon if image fails to load

### Standalone Logo Widget

Use `AppLogo` anywhere in the app:

```dart
// Simple logo
AppLogo(size: 48)

// Logo with text and animation
AppLogo(
  size: 60,
  showText: true,
  animate: true,
)
```

**Options**:
- `size`: Logo dimensions (default 48)
- `showText`: Show "FinSight" branding (default false)
- `animate`: Elastic scale-in animation (default false)

### Branded Header

Use `BrandedHeader` for page headers with gradient backgrounds:

```dart
BrandedHeader(
  title: 'Welcome Back',
  subtitle: 'Track your expenses effortlessly',
  showLogo: true,
)
```

**Features**:
- Gradient background (primary color with fade)
- Rounded bottom corners
- Logo display option
- Title and subtitle support

## 4. Android Widget Logo

The home screen widget displays the FinSight logo in its header.

**Location**: `android/app/src/main/res/layout/expense_widget.xml`

**Implementation**:
```xml
<ImageView
    android:id="@+id/widget_logo"
    android:layout_width="32dp"
    android:layout_height="32dp"
    android:src="@mipmap/ic_launcher"
    android:scaleType="fitCenter" />
```

The widget uses the generated launcher icon (`@mipmap/ic_launcher`) which is created by the `flutter_launcher_icons` package.

## 5. Usage Examples

### Dashboard with Branded AppBar
```dart
class DashboardPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: BrandedAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
      body: ...,
    );
  }
}
```

### Settings Page with Logo
```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BrandedHeader(
            title: 'Settings',
            showLogo: true,
          ),
          ListTile(
            leading: AppLogo(size: 40),
            title: Text('About FinSight'),
          ),
        ],
      ),
    );
  }
}
```

### Receipt Viewer with Animated Logo
```dart
class ReceiptViewerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AppLogo(size: 32, animate: true),
            SizedBox(width: 12),
            Text('Receipt Details'),
          ],
        ),
      ),
      body: ...,
    );
  }
}
```

## 6. Branding Consistency Guidelines

### When to Show the Logo

**✅ Always Show**:
- Dashboard/home screen
- About/settings pages
- Splash screen
- Android widget
- Empty states with branding

**✅ Optional**:
- Secondary pages (forms, lists)
- Detail views
- Modal dialogs

**❌ Don't Show**:
- Error states (focus on error message)
- Loading overlays (use spinner instead)
- Confirmation dialogs

### Logo Sizes

- **Extra Small**: 24dp - List items, small icons
- **Small**: 32dp - AppBar, compact headers
- **Medium**: 48dp - Standard logo placement
- **Large**: 60dp - Headers, about pages
- **Extra Large**: 100dp+ - Splash screen, empty states

### Colors

Use the theme colors for consistency:
```dart
// Primary gradient
LinearGradient(
  colors: [Color(0xFF2E7D32), Color(0xFF00BCD4)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Or use theme
Theme.of(context).primaryColor  // Green #2E7D32
```

## 7. Testing Checklist

After implementing branding:

- [ ] App icon appears correctly on home screen
- [ ] Splash screen shows with smooth animations
- [ ] Logo appears in dashboard AppBar
- [ ] Android widget displays logo properly
- [ ] Logo loads with fallback if image missing
- [ ] Animations perform smoothly (60fps)
- [ ] Logo is visible in light and dark themes
- [ ] Adaptive icon works on Android 8+
- [ ] iOS app icon appears in all sizes
- [ ] Splash screen transitions smoothly to app

## 8. Troubleshooting

### Logo not appearing in AppBar
- Ensure `assets/icons/finsight_icon.png` exists
- Check `pubspec.yaml` has `assets/icons/` in assets section
- Run `flutter pub get` after adding assets
- Hot restart the app (not hot reload)

### Splash screen not showing
- Check `splashCompleteProvider` is initialized in main.dart
- Verify AnimatedSplashScreen is imported
- Ensure splash duration completes before transition
- Check console for animation errors

### Widget logo missing
- Run `flutter pub run flutter_launcher_icons`
- Verify `@mipmap/ic_launcher` was generated
- Check Android build completed successfully
- Reinstall widget on device

### Animation performance issues
- Reduce animation duration
- Disable ripple effect for low-end devices
- Use `AnimatedOpacity` instead of custom animations
- Profile app with Flutter DevTools

## 9. Customization

### Change Splash Duration
```dart
AnimatedSplashScreen(
  duration: Duration(milliseconds: 2000), // 2 seconds
  onComplete: () { ... },
)
```

### Disable Specific Animations
```dart
// In animated_splash_screen.dart
// Comment out unwanted animation controllers
// For example, to disable ripple:
// _rippleController.forward(); // <-- comment this
```

### Custom Logo Colors
Edit `flutter_icons_config.yaml`:
```yaml
android: true
ios: true
image_path: "assets/icons/finsight_icon.png"
adaptive_icon_background: "#YOUR_COLOR"  # Change background
```

### Widget Logo Size
Edit `expense_widget.xml`:
```xml
<ImageView
    android:layout_width="40dp"   <!-- Change size -->
    android:layout_height="40dp"
    ... />
```

## 10. Files Modified/Created

**New Files**:
- `lib/core/widgets/animated_splash_screen.dart` - Custom splash screen
- `lib/core/widgets/branded_widgets.dart` - BrandedAppBar, AppLogo, BrandedHeader
- `flutter_icons_config.yaml` - Icon and splash configuration
- `assets/LOGO_SETUP.md` - Logo asset instructions
- `BRANDING_INTEGRATION.md` - This document

**Modified Files**:
- `lib/main.dart` - Integrated splash screen on app launch
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` - Uses BrandedAppBar
- `android/app/src/main/res/layout/expense_widget.xml` - Added logo to widget header
- `pubspec.yaml` - Added dependencies (flutter_launcher_icons, flutter_native_splash, lottie)

## 11. Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  lottie: ^3.0.0  # For future Lottie animations

dev_dependencies:
  flutter_launcher_icons: ^0.13.1  # App icon generation
  flutter_native_splash: ^2.3.8    # Splash screen generation
```

## 12. Future Enhancements

- [ ] Lottie animation for splash screen (JSON-based)
- [ ] Animated logo transitions between pages
- [ ] Logo color variations for dark theme
- [ ] Microinteractions on logo tap
- [ ] Seasonal logo variants
- [ ] Logo appearing in push notifications
- [ ] Animated loading states with logo
- [ ] Logo watermark in exported reports

---

**Last Updated**: Task 18 - App Icon & Logo Integration
**Status**: ✅ Complete
**Platform Support**: Android, iOS
**Flutter Version**: 3.0+
