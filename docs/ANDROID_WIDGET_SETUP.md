# Android Home Screen Widget - Setup & Configuration Guide

## Overview
The FinSight Android home screen widget provides users with at-a-glance access to their daily spending information directly from their home screen. The widget displays today's total spending, expense count, and offers a quick action button to add expenses without opening the app.

## Features

### Widget Display
- **Today's Spending Total**: Shows the sum of all expenses for the current day
- **Expense Count**: Displays number of expenses recorded today
- **Current Date**: Shows the current date for context
- **Beautiful Gradient UI**: Purple gradient background with rounded corners
- **Responsive Design**: Adapts to different widget sizes (minimum 4x2 cells)

### Quick Actions
- **Quick Add Expense**: Tap the button to launch the app directly to add expense screen
- **View Dashboard**: Tap the amount to open the app to dashboard
- **Auto-Refresh**: Updates every 30 minutes automatically
- **Manual Refresh**: Updates immediately when expenses are added/edited/deleted

## File Structure

```
android/app/src/main/
├── kotlin/com/finsight/finsight/
│   ├── MainActivity.kt                      # Updated with widget channel
│   └── ExpenseWidgetProvider.kt             # Widget provider implementation
├── res/
│   ├── layout/
│   │   └── expense_widget.xml               # Widget layout
│   ├── drawable/
│   │   ├── widget_background.xml            # Widget gradient background
│   │   ├── widget_button_background.xml     # Button background
│   │   ├── ic_add.xml                       # Add icon
│   │   └── ic_widget_logo.xml               # Widget logo
│   ├── values/
│   │   └── strings.xml                      # String resources
│   └── xml/
│       └── expense_widget_info.xml          # Widget metadata
└── AndroidManifest.xml                      # Widget receiver registration

lib/
├── services/
│   └── android_widget_service.dart          # Flutter widget service
├── features/expenses/providers/
│   └── widget_update_provider.dart          # Widget update manager
└── examples/
    └── android_widget_example.dart          # Usage examples
```

## Installation & Setup

### Step 1: Verify Android Configuration

The widget is already configured in your Android project. Verify the following files exist:

1. **AndroidManifest.xml** - Widget receiver is registered
2. **ExpenseWidgetProvider.kt** - Widget logic implementation
3. **Layout and drawable resources** - Widget UI components
4. **MainActivity.kt** - Method channel configuration

### Step 2: Build and Install App

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build and run on Android device/emulator
flutter run
```

### Step 3: Add Widget to Home Screen

1. **Long press** on your Android home screen
2. Tap **"Widgets"** from the menu
3. Scroll to find **"FinSight"**
4. **Drag** the FinSight widget to your desired location
5. Release to place the widget

## Widget Configuration

### Widget Metadata (expense_widget_info.xml)

```xml
<appwidget-provider>
    android:minWidth="250dp"              <!-- Minimum width -->
    android:minHeight="180dp"             <!-- Minimum height -->
    android:targetCellWidth="4"           <!-- Grid cells wide -->
    android:targetCellHeight="2"          <!-- Grid cells tall -->
    android:updatePeriodMillis="1800000"  <!-- Auto-update: 30 min -->
    android:resizeMode="horizontal|vertical" <!-- Resizable -->
    android:widgetCategory="home_screen"  <!-- Available on home screen -->
</appwidget-provider>
```

### Customization Options

#### Change Widget Colors
Edit [widget_background.xml](android/app/src/main/res/drawable/widget_background.xml):

```xml
<gradient
    android:startColor="#667eea"  <!-- Start color -->
    android:endColor="#764ba2"    <!-- End color -->
    android:angle="135" />        <!-- Gradient angle -->
```

#### Change Update Frequency
Edit [expense_widget_info.xml](android/app/src/main/res/xml/expense_widget_info.xml):

```xml
<!-- Update every 15 minutes: 900000 ms -->
<!-- Update every 30 minutes: 1800000 ms (default) -->
<!-- Update every hour: 3600000 ms -->
android:updatePeriodMillis="1800000"
```

#### Modify Widget Size
Edit dimensions in [expense_widget_info.xml](android/app/src/main/res/xml/expense_widget_info.xml):

```xml
android:minWidth="250dp"         <!-- Adjust minimum width -->
android:minHeight="180dp"        <!-- Adjust minimum height -->
android:targetCellWidth="4"      <!-- Grid cells (1 cell ≈ 70-80dp) -->
android:targetCellHeight="2"     <!-- Grid cells -->
```

## Flutter Integration

### Automatic Updates

The widget automatically updates when expenses are modified. The integration is handled through the widget update manager.

#### Update Widget After Expense Operations

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsight/features/expenses/providers/widget_update_provider.dart';

// After adding an expense
Future<void> addExpense(WidgetRef ref, Expense expense) async {
  // Save expense
  await expenseRepo.createExpense(expense);
  
  // Update widget
  final widgetManager = ref.read(widgetUpdateProvider);
  if (widgetManager.isSupported) {
    await widgetManager.updateWidgetWithTodayData();
  }
}
```

### Manual Widget Update

```dart
// Manually refresh widget data
final widgetManager = ref.read(widgetUpdateProvider);
await widgetManager.updateWidgetWithTodayData();
```

### Check Widget Launch

```dart
// Check if app was launched from widget
final widgetService = ref.read(androidWidgetServiceProvider);
final initialRoute = await widgetService.getInitialRoute();

if (initialRoute == "/add-expense") {
  // Navigate to add expense screen
}
```

## Widget Actions

### Quick Add Expense
- **Trigger**: User taps "Quick Add Expense" button on widget
- **Behavior**: Opens app to add expense screen (`/add-expense` route)
- **Implementation**: MainActivity receives intent with `action = "add_expense"`

### View Dashboard
- **Trigger**: User taps on the amount display
- **Behavior**: Opens app to dashboard
- **Implementation**: Standard app launch

## Widget Data Flow

```
┌─────────────────┐
│   Flutter App   │
│  (Add Expense)  │
└────────┬────────┘
         │
         ├─ Save to Database
         │
         ├─ Call MethodChannel
         │  (updateWidget)
         ▼
┌─────────────────┐
│  MainActivity   │
│ (MethodChannel) │
└────────┬────────┘
         │
         ├─ Update SharedPreferences
         │
         ├─ Send Broadcast
         ▼
┌──────────────────┐
│ WidgetProvider   │
│ (Receive Update) │
└────────┬─────────┘
         │
         ├─ Read SharedPreferences
         │
         ├─ Update RemoteViews
         ▼
┌──────────────────┐
│  Home Screen     │
│   (Display)      │
└──────────────────┘
```

## API Reference

### AndroidWidgetService

#### updateWidget()
```dart
Future<bool> updateWidget({
  required double todayAmount,
  required int expenseCount,
})
```
Updates the widget with current spending data.

**Parameters:**
- `todayAmount`: Total spending for today (USD)
- `expenseCount`: Number of expenses today

**Returns:** `true` if update successful

#### getInitialRoute()
```dart
Future<String?> getInitialRoute()
```
Gets the route if app was launched from widget.

**Returns:** Route string (e.g., `/add-expense`) or `null`

#### isWidgetSupported
```dart
bool get isWidgetSupported
```
Check if platform supports widgets (Android only).

### WidgetUpdateManager

#### updateWidgetWithTodayData()
```dart
Future<void> updateWidgetWithTodayData()
```
Fetches today's expenses from database and updates widget.

#### isSupported
```dart
bool get isSupported
```
Check if widgets are available on current platform.

## Troubleshooting

### Widget Not Showing
**Problem**: Widget doesn't appear in widget picker

**Solutions:**
1. Rebuild the app: `flutter clean && flutter build apk`
2. Uninstall and reinstall the app
3. Check AndroidManifest.xml for receiver registration
4. Verify widget metadata file exists

### Widget Not Updating
**Problem**: Widget shows old or incorrect data

**Solutions:**
1. Check SharedPreferences are being written
2. Verify broadcast intent is being sent
3. Add logging to ExpenseWidgetProvider.onReceive()
4. Manually refresh widget from system settings

### Widget Crashes
**Problem**: Widget shows "Problem loading widget"

**Solutions:**
1. Check Logcat for errors: `adb logcat | grep Widget`
2. Verify all drawable resources exist
3. Check string resources are defined
4. Ensure PendingIntent flags are correct (FLAG_IMMUTABLE)

### Data Not Syncing
**Problem**: Flutter updates don't reflect on widget

**Solutions:**
1. Verify MethodChannel is configured correctly
2. Check MainActivity.configureFlutterEngine() is called
3. Add try-catch to updateWidget method
4. Test with manual refresh button

## Testing

### Manual Testing Checklist

- [ ] Widget appears in widget picker
- [ ] Widget can be placed on home screen
- [ ] Widget displays $0.00 initially
- [ ] Add expense updates widget immediately
- [ ] Delete expense updates widget
- [ ] Widget updates after app restart
- [ ] Quick Add button opens add expense screen
- [ ] Tapping amount opens app
- [ ] Widget survives device reboot
- [ ] Widget updates automatically (wait 30 min)
- [ ] Multiple widgets can be placed
- [ ] Widget can be resized (if supported)

### Testing Commands

```bash
# View widget logs
adb logcat | grep ExpenseWidget

# Force widget update
adb shell am broadcast -a com.finsight.finsight.REFRESH_WIDGET

# Clear widget data
adb shell pm clear com.finsight.finsight

# Check SharedPreferences
adb shell run-as com.finsight.finsight cat shared_prefs/ExpenseWidgetPrefs.xml
```

## Performance Considerations

### Battery Impact
- Widget updates every 30 minutes (configurable)
- Uses SharedPreferences for data storage (fast)
- No background services or wake locks
- Minimal battery drain

### Memory Usage
- Lightweight RemoteViews (< 1KB)
- No heavy computations
- Data cached in SharedPreferences
- Efficient bitmap handling

### Best Practices
1. Update widget only when necessary
2. Batch updates when possible
3. Use efficient data structures
4. Avoid heavy operations in onUpdate()
5. Test with battery profiler

## Advanced Configuration

### Multiple Widget Instances
The widget supports multiple instances. Each instance displays the same data but can be customized:

```kotlin
// In ExpenseWidgetProvider.kt
override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
    for (appWidgetId in appWidgetIds) {
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }
}
```

### Custom Actions
Add custom actions by modifying the intent filters:

1. Add action to AndroidManifest.xml
2. Handle in ExpenseWidgetProvider.onReceive()
3. Add button to widget layout
4. Set PendingIntent on button

### Localization
Widget supports localization through strings.xml:

```xml
<!-- res/values/strings.xml (English) -->
<string name="widget_title">FinSight</string>
<string name="widget_today_spend">Today\'s Spending</string>

<!-- res/values-es/strings.xml (Spanish) -->
<string name="widget_title">FinSight</string>
<string name="widget_today_spend">Gasto de Hoy</string>
```

## Future Enhancements

Potential improvements:
- [ ] Widget size variations (1x1, 2x2, 4x4)
- [ ] Dark mode support
- [ ] Configurable date range (week, month)
- [ ] Budget progress indicator
- [ ] Category breakdown
- [ ] Historical comparison
- [ ] Interactive charts
- [ ] Widget configuration screen

## Support

For issues or questions:
- Check the troubleshooting section
- Review Android widget logs
- Test with example code
- Verify all setup steps completed

---

**Widget Version**: 1.0.0  
**Android Compatibility**: API 21+ (Android 5.0+)  
**Last Updated**: December 15, 2025  
**Status**: ✅ Production Ready
