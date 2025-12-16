# Android Widget - Quick Start Guide

## What is the FinSight Widget?

A home screen widget that displays your daily spending at a glance, with a quick button to add expenses without opening the app.

## Quick Setup (3 Steps)

### 1. Install the App
```bash
flutter run
```

### 2. Add Widget to Home Screen
1. **Long press** on your home screen
2. Tap **"Widgets"**
3. Find **"FinSight"** and drag it to your screen

### 3. Start Using It!
- Widget shows today's total spending
- Tap **"Quick Add Expense"** to add an expense
- Tap the **amount** to open the app

## How to Update Widget from Your Code

### Basic Usage

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsight/features/expenses/providers/widget_update_provider.dart';

// After adding/editing/deleting an expense
final widgetManager = ref.read(widgetUpdateProvider);
await widgetManager.updateWidgetWithTodayData();
```

### Complete Example

```dart
Future<void> addExpenseAndUpdateWidget(WidgetRef ref) async {
  // 1. Add expense to database
  final expense = Expense(
    amount: 25.50,
    category: 'Food',
    date: DateTime.now(),
  );
  await ref.read(expenseRepositoryProvider).createExpense(expense);
  
  // 2. Update widget
  final widgetManager = ref.read(widgetUpdateProvider);
  if (widgetManager.isSupported) {
    await widgetManager.updateWidgetWithTodayData();
  }
}
```

## Integration Points

### Add Expense Screen
Update widget after saving expense:

```dart
// In your save expense function
await expenseRepository.createExpense(expense);

// Update widget
final widgetManager = ref.read(widgetUpdateProvider);
await widgetManager.updateWidgetWithTodayData();
```

### Delete Expense
Update widget after deletion:

```dart
await expenseRepository.deleteExpense(id);

// Update widget
await ref.read(widgetUpdateProvider).updateWidgetWithTodayData();
```

### App Launch from Widget
Check if app was launched from widget:

```dart
@override
void initState() {
  super.initState();
  _checkWidgetLaunch();
}

Future<void> _checkWidgetLaunch() async {
  final widgetService = ref.read(androidWidgetServiceProvider);
  final route = await widgetService.getInitialRoute();
  
  if (route == '/add-expense') {
    // Navigate to add expense
  }
}
```

## Widget Features

| Feature | Description |
|---------|-------------|
| **Today's Total** | Shows sum of all expenses today |
| **Expense Count** | Number of expenses recorded |
| **Current Date** | Today's date display |
| **Quick Add** | Button to add expense quickly |
| **Auto-Update** | Updates every 30 minutes |
| **Manual Refresh** | Updates when expenses change |

## Customization

### Change Widget Colors

Edit `android/app/src/main/res/drawable/widget_background.xml`:

```xml
<gradient
    android:startColor="#YOUR_START_COLOR"
    android:endColor="#YOUR_END_COLOR"
    android:angle="135" />
```

### Change Update Frequency

Edit `android/app/src/main/res/xml/expense_widget_info.xml`:

```xml
<!-- 15 minutes -->
android:updatePeriodMillis="900000"

<!-- 30 minutes (default) -->
android:updatePeriodMillis="1800000"

<!-- 1 hour -->
android:updatePeriodMillis="3600000"
```

## Troubleshooting

### Widget not updating?
```dart
// Force manual update
await ref.read(widgetUpdateProvider).updateWidgetWithTodayData();
```

### Widget not showing?
1. Rebuild app: `flutter clean && flutter run`
2. Uninstall and reinstall
3. Check Android version (needs Android 5.0+)

### Check if widget is supported:
```dart
final widgetManager = ref.read(widgetUpdateProvider);
if (widgetManager.isSupported) {
  // Widget is available
}
```

## Files Overview

### Flutter Files
- `lib/services/android_widget_service.dart` - Widget service
- `lib/features/expenses/providers/widget_update_provider.dart` - Update manager
- `lib/examples/android_widget_example.dart` - Usage examples

### Android Files
- `ExpenseWidgetProvider.kt` - Widget implementation
- `MainActivity.kt` - Method channel setup
- `res/layout/expense_widget.xml` - Widget UI
- `AndroidManifest.xml` - Widget registration

## Testing

```dart
// Test widget update
await ref.read(widgetUpdateProvider).updateWidgetWithTodayData();

// Check logs
print('Widget updated successfully');
```

## What Gets Displayed

The widget shows:
```
┌─────────────────────────┐
│ FinSight      Dec 15    │
│                         │
│   Today's Spending      │
│      $123.45            │
│    5 expenses           │
│                         │
│ [+ Quick Add Expense]   │
└─────────────────────────┘
```

## Best Practices

✅ **DO:**
- Update widget after each expense operation
- Check if widget is supported before updating
- Use the widget update manager
- Handle errors gracefully

❌ **DON'T:**
- Update widget too frequently (causes battery drain)
- Forget to update widget after expense changes
- Assume widget is available on all platforms

## Next Steps

1. ✅ Add widget to your home screen
2. ✅ Test adding an expense
3. ✅ Verify widget updates
4. ✅ Integrate with your expense flows
5. 📖 Read full documentation: [ANDROID_WIDGET_SETUP.md](./ANDROID_WIDGET_SETUP.md)

## Need Help?

- 📖 Full documentation: [ANDROID_WIDGET_SETUP.md](./ANDROID_WIDGET_SETUP.md)
- 💡 Examples: [android_widget_example.dart](./lib/examples/android_widget_example.dart)
- 🔧 Check logcat: `adb logcat | grep ExpenseWidget`

---

**Quick Reference**: Add widget → Test it → Integrate with expense operations → Done! ✨
