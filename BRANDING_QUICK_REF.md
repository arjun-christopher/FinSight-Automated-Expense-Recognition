# FinSight Branding Quick Reference

## 🎨 Import Statement

```dart
import 'package:finsight/core/widgets/branded_widgets.dart';
import 'package:finsight/core/widgets/animated_splash_screen.dart';
```

## 🚀 Quick Usage

### BrandedAppBar (Most Common)
```dart
// Simple
BrandedAppBar(title: 'Dashboard')

// With actions
BrandedAppBar(
  title: 'Settings',
  actions: [
    IconButton(icon: Icon(Icons.save), onPressed: () {}),
  ],
)

// Without logo (title only)
BrandedAppBar(title: 'Details', showLogo: false)
```

### AppLogo (Flexible)
```dart
// Small icon
AppLogo(size: 32)

// With text
AppLogo(size: 60, showText: true)

// Animated entrance
AppLogo(size: 80, showText: true, animate: true)
```

### BrandedHeader (Page Headers)
```dart
// Simple
BrandedHeader(title: 'Welcome')

// With subtitle
BrandedHeader(
  title: 'Dashboard',
  subtitle: 'Your financial overview',
)

// With logo
BrandedHeader(
  title: 'About',
  subtitle: 'Version 1.0.0',
  showLogo: true,
)
```

## 🎬 Animations

### Splash Screen (Auto on Launch)
```dart
AnimatedSplashScreen(
  duration: Duration(seconds: 3),  // Optional
  onComplete: () {
    // Navigate to main app
  },
)
```

### Logo Animation
```dart
// Elastic scale-in
AppLogo(animate: true)

// Custom animation
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: 1),
  duration: Duration(milliseconds: 600),
  builder: (context, value, child) => Opacity(
    opacity: value,
    child: AppLogo(size: 60),
  ),
)
```

## 🎨 Colors

```dart
// Primary Green
Color(0xFF2E7D32)
Theme.of(context).primaryColor

// Accent Cyan
Color(0xFF00BCD4)

// Gradient
LinearGradient(
  colors: [Color(0xFF2E7D32), Color(0xFF00BCD4)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

## 📏 Standard Sizes

| Use Case | Size (dp) | Widget |
|----------|-----------|--------|
| List item icon | 24 | `AppLogo(size: 24)` |
| AppBar icon | 32 | `AppLogo(size: 32)` |
| Standard logo | 48 | `AppLogo(size: 48)` |
| Header logo | 60 | `AppLogo(size: 60)` |
| About/splash | 100 | `AppLogo(size: 100)` |

## 🔧 Common Patterns

### Full-Screen Welcome
```dart
Scaffold(
  body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppLogo(size: 120, animate: true),
        SizedBox(height: 24),
        Text('Welcome to FinSight',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  ),
)
```

### Settings Section
```dart
ListTile(
  leading: AppLogo(size: 40),
  title: Text('About FinSight'),
  subtitle: Text('Version 1.0.0'),
  onTap: () => showAboutDialog(context),
)
```

### Empty State with Branding
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AppLogo(size: 80, animate: true),
      SizedBox(height: 16),
      Text('No expenses yet',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
      Text('Tap + to add your first expense',
        style: TextStyle(color: Colors.grey),
      ),
    ],
  ),
)
```

### Loading with Brand
```dart
Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppLogo(size: 60),
      SizedBox(height: 16),
      CircularProgressIndicator(),
      SizedBox(height: 8),
      Text('Loading...'),
    ],
  ),
)
```

## ⚠️ Common Mistakes

### ❌ Don't Do
```dart
// Don't use regular AppBar when branding is important
AppBar(title: Text('Dashboard'))

// Don't hardcode logo images everywhere
Image.asset('assets/icons/logo.png')

// Don't use inconsistent sizes
AppLogo(size: 37)  // Use standard sizes
```

### ✅ Do This
```dart
// Use BrandedAppBar for consistency
BrandedAppBar(title: 'Dashboard')

// Use AppLogo widget with fallback
AppLogo(size: 40)

// Use standard sizes
AppLogo(size: 48)  // Standard sizes: 24, 32, 48, 60, 80, 100
```

## 🎯 When to Use Each Component

| Component | Use When |
|-----------|----------|
| `BrandedAppBar` | Main screens (Dashboard, Settings, etc.) |
| `AppLogo` | Anywhere you need the logo (flexible) |
| `BrandedHeader` | Page headers with gradient background |
| `AnimatedSplashScreen` | App launch (automatic) |

## 🔄 State Management

### Splash Screen State
```dart
// In main.dart
final splashCompleteProvider = StateProvider<bool>((ref) => false);

// Usage
final splashComplete = ref.watch(splashCompleteProvider);
if (splashComplete) {
  // Show main app
} else {
  // Show splash
}
```

## 📱 Platform-Specific

### Android Widget
```xml
<!-- Widget logo (auto-generated) -->
<ImageView
    android:src="@mipmap/ic_launcher"
    android:layout_width="32dp"
    android:layout_height="32dp" />
```

### App Icon (Auto-generated)
```bash
flutter pub run flutter_launcher_icons
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Logo not showing | Run `flutter pub get`, hot restart |
| White background | Check PNG has transparency |
| Blurry logo | Use higher resolution source image |
| Animation stutters | Reduce animation complexity or duration |
| Fallback icon shows | Check asset path in pubspec.yaml |

## 📚 Full Documentation

- **Complete Guide**: [BRANDING_INTEGRATION.md](BRANDING_INTEGRATION.md)
- **Asset Setup**: [LOGO_PLACEMENT_GUIDE.md](LOGO_PLACEMENT_GUIDE.md)
- **Task Summary**: [TASK_18_SUMMARY.md](TASK_18_SUMMARY.md)

## 🎁 Bonus Tips

```dart
// Hero animation with logo
Hero(
  tag: 'app_logo',
  child: AppLogo(size: 60),
)

// Shimmer effect (requires shimmer package)
Shimmer.fromColors(
  baseColor: Color(0xFF2E7D32),
  highlightColor: Color(0xFF00BCD4),
  child: AppLogo(size: 80),
)

// Rotate animation
RotationTransition(
  turns: animation,
  child: AppLogo(size: 60),
)

// Pulse effect
ScaleTransition(
  scale: Tween(begin: 1.0, end: 1.1).animate(
    CurvedAnimation(parent: controller, curve: Curves.easeInOut),
  ),
  child: AppLogo(size: 60),
)
```

---

**Last Updated**: Task 18  
**Status**: ✅ Production Ready  
**Version**: 1.0.0
