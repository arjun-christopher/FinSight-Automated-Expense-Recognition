# Notifications Module Documentation

## Overview

The Notifications Module provides a comprehensive notification system for FinSight, enabling users to stay informed about their spending patterns and budget status through local push notifications.

### Key Features

- **Daily Spending Summaries**: Automatic end-of-day spending reports
- **Weekly Reports**: Weekly spending trends and comparisons  
- **Budget Alerts**: Real-time alerts when approaching or exceeding budgets
- **Customizable Scheduling**: User-configurable notification times
- **Notification Settings**: Full control over notification preferences
- **Test Notifications**: Ability to preview notifications

## Architecture

### File Structure

```
lib/
├── services/
│   ├── notification_service.dart          # Core notification logic
│   └── notification_scheduler.dart        # Scheduling and preferences
├── features/
│   └── notifications/
│       └── presentation/
│           └── pages/
│               └── notification_settings_page.dart  # Settings UI
└── examples/
    └── notification_examples.dart         # Usage examples
```

### Dependencies

```yaml
dependencies:
  flutter_local_notifications: ^16.3.0  # Local notifications
  timezone: ^0.9.2                      # Timezone support
  shared_preferences: ^2.2.2            # Settings persistence
  flutter_riverpod: ^2.4.9              # State management
```

## Core Components

### 1. NotificationService

The main service handling all notification operations.

#### Initialization

```dart
final notificationService = NotificationService();
await notificationService.initialize();
```

#### Key Methods

**Daily Summary**
```dart
await notificationService.showDailySummaryNotification(
  expenses: expenses,
  totalSpent: totalSpent,
);
```

**Weekly Report**
```dart
await notificationService.showWeeklyReportNotification(
  expenses: expenses,
  totalSpent: totalSpent,
  previousWeekTotal: previousWeekTotal,
);
```

**Budget Warning**
```dart
await notificationService.showBudgetWarningNotification(
  category: 'Food & Dining',
  spent: 320.0,
  budget: 400.0,
  percentage: 80.0,
);
```

**Budget Exceeded**
```dart
await notificationService.showBudgetExceededNotification(
  category: 'Shopping',
  spent: 550.0,
  budget: 500.0,
  percentage: 110.0,
);
```

**Check All Budgets**
```dart
await notificationService.checkAndSendBudgetAlerts(budgetService);
```

**Schedule Notifications**
```dart
// Daily at 8 PM
await notificationService.scheduleDailySummary(hour: 20, minute: 0);

// Weekly on Monday at 9 AM
await notificationService.scheduleWeeklyReport(
  weekday: DateTime.monday,
  hour: 9,
  minute: 0,
);
```

**Manage Notifications**
```dart
// Cancel specific notification
await notificationService.cancelNotification(id);

// Cancel all notifications
await notificationService.cancelAllNotifications();

// Get pending notifications
final pending = await notificationService.getPendingNotifications();

// Check if notifications are enabled
final enabled = await notificationService.areNotificationsEnabled();
```

#### Notification Channels (Android)

1. **Daily Summary** (`daily_summary`)
   - Importance: High
   - Sound: Yes
   - Description: Daily spending summary notifications

2. **Weekly Report** (`weekly_report`)
   - Importance: High
   - Sound: Yes
   - Description: Weekly spending report notifications

3. **Budget Alerts** (`budget_alerts`)
   - Importance: Max
   - Sound: Yes
   - Vibration: Yes
   - Description: Budget warning and exceeded notifications

### 2. NotificationScheduler

Manages notification scheduling and user preferences.

#### Notification Settings

```dart
// Access settings
final settingsAsync = ref.watch(notificationSettingsProvider);

// Update daily summary
await ref.read(notificationSettingsProvider.notifier)
  .updateDailySummarySettings(
    enabled: true,
    hour: 20,
    minute: 0,
  );

// Update weekly report
await ref.read(notificationSettingsProvider.notifier)
  .updateWeeklyReportSettings(
    enabled: true,
    weekday: DateTime.monday,
    hour: 9,
    minute: 0,
  );

// Update budget alerts
await ref.read(notificationSettingsProvider.notifier)
  .updateBudgetAlertsEnabled(true);

// Reset to defaults
await ref.read(notificationSettingsProvider.notifier)
  .resetToDefaults();
```

#### Default Settings

| Setting | Default Value |
|---------|--------------|
| Daily Summary Enabled | `true` |
| Daily Summary Time | 8:00 PM |
| Weekly Report Enabled | `true` |
| Weekly Report Day | Monday |
| Weekly Report Time | 9:00 AM |
| Budget Alerts Enabled | `true` |

#### SharedPreferences Keys

```dart
// Daily Summary
notification_daily_summary_enabled
notification_daily_summary_hour
notification_daily_summary_minute

// Weekly Report
notification_weekly_report_enabled
notification_weekly_report_weekday
notification_weekly_report_hour
notification_weekly_report_minute

// Budget Alerts
notification_budget_alerts_enabled
notification_last_budget_alert_check
```

### 3. NotificationContentGenerator

Helper class for generating notification content with real data.

```dart
final generator = NotificationContentGenerator(
  expenseRepository: expenseRepository,
  budgetService: budgetService,
);

// Send daily summary with current data
await generator.sendDailySummaryNotification(notificationService);

// Send weekly report with current data
await generator.sendWeeklyReportNotification(notificationService);

// Check and send budget alerts
await generator.checkAndSendBudgetAlerts(notificationService);
```

### 4. Riverpod Providers

```dart
// Services
notificationServiceProvider
notificationContentGeneratorProvider
sharedPreferencesProvider

// Settings
notificationSettingsProvider
```

## User Interface

### NotificationSettingsPage

Complete settings screen for managing notifications.

**Features:**
- Toggle daily summary on/off
- Set daily summary time
- Toggle weekly report on/off
- Set weekly report day and time
- Toggle budget alerts on/off
- Test all notification types
- Reset to default settings

**Usage:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NotificationSettingsPage(),
  ),
);
```

## Integration Guide

### Step 1: Initialize in main.dart

```dart
import 'package:finsight/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Schedule recurring notifications
  await notificationService.scheduleDailySummary();
  await notificationService.scheduleWeeklyReport();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

### Step 2: Trigger Budget Alerts After Expense Creation

```dart
import 'package:finsight/services/notification_service.dart';
import 'package:finsight/services/notification_scheduler.dart';

Future<void> addExpense(Expense expense) async {
  // Save expense
  await expenseRepository.createExpense(expense);
  
  // Check if budget alerts are enabled
  final settings = await ref.read(notificationSettingsProvider.future);
  if (settings.budgetAlertsEnabled) {
    // Check budgets and send alerts
    final notificationService = ref.read(notificationServiceProvider);
    final budgetService = ref.read(budgetServiceProvider);
    await notificationService.checkAndSendBudgetAlerts(budgetService);
  }
}
```

### Step 3: Add Settings to App Menu

```dart
ListTile(
  leading: const Icon(Icons.notifications),
  title: const Text('Notifications'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsPage(),
      ),
    );
  },
)
```

## Notification Types

### 1. Daily Spending Summary

**Trigger:** Scheduled (default 8:00 PM)  
**Channel:** `daily_summary`  
**Format:**
- Title: 📊 Daily Spending Summary
- Body: You spent $X.XX today across N expenses. Top category: Category ($X.XX)
- Empty: No expenses recorded today. Keep tracking!

**Payload:** `daily_summary`

### 2. Weekly Spending Report

**Trigger:** Scheduled (default Monday 9:00 AM)  
**Channel:** `weekly_report`  
**Format:**
- Title: 📈 Weekly Spending Report
- Body: Week total: $X.XX (N expenses). Daily average: $X.XX. ⬆️/⬇️ Y% vs last week
- Trend shown if >10% change

**Payload:** `weekly_report`

### 3. Budget Warning

**Trigger:** When spending reaches alert threshold (default 80%)  
**Channel:** `budget_alerts`  
**Format:**
- Title: ⚠️ Budget Warning: [Category]
- Body: You've used X% of your budget. $X.XX remaining.

**Payload:** `budget_warning:[category]`

### 4. Budget Exceeded

**Trigger:** When spending exceeds budget (≥100%)  
**Channel:** `budget_alerts`  
**Format:**
- Title: 🚨 Budget Exceeded: [Category]
- Body: You've exceeded your budget by $X.XX (X% used).

**Payload:** `budget_exceeded:[category]`

## Platform-Specific Setup

### Android Setup

#### 1. AndroidManifest.xml

Add notification permissions:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Notification Permissions -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    
    <application>
        <!-- Notification Receiver -->
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

#### 2. Build Configuration

In `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### iOS Setup

#### 1. Request Permissions

Permissions are requested automatically on first launch via:
```dart
await notificationService.initialize();
```

#### 2. Info.plist (Optional)

Add custom permission messages in `ios/Runner/Info.plist`:

```xml
<dict>
    <key>UIUserNotificationSettings</key>
    <dict>
        <key>UISupportedNotificationTypes</key>
        <array>
            <string>Alert</string>
            <string>Sound</string>
            <string>Badge</string>
        </array>
    </dict>
</dict>
```

## Notification Scheduling

### How Scheduling Works

1. **Timezone Initialization**: Uses `timezone` package to handle time zones
2. **Exact Scheduling**: Uses `AndroidScheduleMode.exactAllowWhileIdle` for precision
3. **Recurring Notifications**: Uses `matchDateTimeComponents` for daily/weekly repeats
4. **Persistence**: Scheduled notifications survive app restarts

### Scheduling IDs

| Notification Type | ID |
|------------------|-----|
| Daily Summary | 100 |
| Weekly Report | 200 |
| Budget Warning | 1 + category.hashCode |
| Budget Exceeded | 2 + category.hashCode |

### Rescheduling

Notifications are automatically rescheduled when:
- Settings are changed
- App is updated
- Device reboots (Android only)

## Common Use Cases

### 1. Send Immediate Daily Summary

```dart
final notificationService = ref.read(notificationServiceProvider);
final contentGenerator = ref.read(notificationContentGeneratorProvider);

await contentGenerator.sendDailySummaryNotification(notificationService);
```

### 2. Check Budget After Expense

```dart
Future<void> onExpenseAdded(Expense expense) async {
  final settings = await ref.read(notificationSettingsProvider.future);
  
  if (settings.budgetAlertsEnabled) {
    final notificationService = ref.read(notificationServiceProvider);
    final budgetService = ref.read(budgetServiceProvider);
    
    await notificationService.checkAndSendBudgetAlerts(budgetService);
  }
}
```

### 3. Customize Notification Times

```dart
// Change daily summary to 9 PM
await ref.read(notificationSettingsProvider.notifier)
  .updateDailySummarySettings(hour: 21, minute: 0);

// Change weekly report to Friday 5 PM
await ref.read(notificationSettingsProvider.notifier)
  .updateWeeklyReportSettings(
    weekday: DateTime.friday,
    hour: 17,
    minute: 0,
  );
```

### 4. Disable Budget Alerts Temporarily

```dart
await ref.read(notificationSettingsProvider.notifier)
  .updateBudgetAlertsEnabled(false);
```

### 5. Test Notification Before Enabling

```dart
final notificationService = ref.read(notificationServiceProvider);

await notificationService.showBudgetWarningNotification(
  category: 'Test',
  spent: 80,
  budget: 100,
  percentage: 80,
);
```

## API Reference

### NotificationService

| Method | Description | Returns |
|--------|-------------|---------|
| `initialize()` | Initialize notification service | `Future<void>` |
| `showDailySummaryNotification()` | Show daily summary | `Future<void>` |
| `showWeeklyReportNotification()` | Show weekly report | `Future<void>` |
| `showBudgetWarningNotification()` | Show budget warning | `Future<void>` |
| `showBudgetExceededNotification()` | Show budget exceeded | `Future<void>` |
| `checkAndSendBudgetAlerts()` | Check all budgets and send alerts | `Future<void>` |
| `scheduleDailySummary()` | Schedule daily summary | `Future<void>` |
| `scheduleWeeklyReport()` | Schedule weekly report | `Future<void>` |
| `cancelNotification()` | Cancel specific notification | `Future<void>` |
| `cancelAllNotifications()` | Cancel all notifications | `Future<void>` |
| `getPendingNotifications()` | Get pending notifications | `Future<List>` |
| `areNotificationsEnabled()` | Check if enabled | `Future<bool>` |

### NotificationSettingsNotifier

| Method | Description | Returns |
|--------|-------------|---------|
| `updateDailySummarySettings()` | Update daily summary settings | `Future<void>` |
| `updateWeeklyReportSettings()` | Update weekly report settings | `Future<void>` |
| `updateBudgetAlertsEnabled()` | Toggle budget alerts | `Future<void>` |
| `resetToDefaults()` | Reset all settings | `Future<void>` |

### NotificationContentGenerator

| Method | Description | Returns |
|--------|-------------|---------|
| `sendDailySummaryNotification()` | Generate and send daily summary | `Future<void>` |
| `sendWeeklyReportNotification()` | Generate and send weekly report | `Future<void>` |
| `checkAndSendBudgetAlerts()` | Check budgets and send alerts | `Future<void>` |

## Performance Considerations

### Best Practices

1. **Initialize Once**: Initialize notification service in `main.dart`
2. **Batch Checks**: Don't check budgets on every expense; batch checks
3. **Throttle Alerts**: Use SharedPreferences to track last alert time
4. **Background Tasks**: Consider using `workmanager` for background checks
5. **Memory**: NotificationService is a singleton to prevent multiple instances

### Optimization Tips

```dart
// Store last alert check time
final prefs = await SharedPreferences.getInstance();
final lastCheck = prefs.getString('last_budget_alert_check');
final now = DateTime.now();

// Only check if 1 hour has passed
if (lastCheck == null || 
    now.difference(DateTime.parse(lastCheck)).inHours >= 1) {
  await notificationService.checkAndSendBudgetAlerts(budgetService);
  await prefs.setString('last_budget_alert_check', now.toIso8601String());
}
```

## Error Handling

### Common Errors

1. **Permission Denied**
```dart
final enabled = await notificationService.areNotificationsEnabled();
if (!enabled) {
  // Show dialog to enable notifications in settings
}
```

2. **Initialization Failed**
```dart
try {
  await notificationService.initialize();
} catch (e) {
  print('Failed to initialize notifications: $e');
}
```

3. **Scheduling Failed**
```dart
try {
  await notificationService.scheduleDailySummary();
} catch (e) {
  print('Failed to schedule notification: $e');
}
```

## Testing

### Unit Tests

```dart
test('should send daily summary notification', () async {
  final service = NotificationService();
  await service.initialize();
  
  await service.showDailySummaryNotification(
    expenses: [],
    totalSpent: 0,
  );
  
  // Verify notification was sent
});
```

### Widget Tests

```dart
testWidgets('notification settings page displays correctly', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: NotificationSettingsPage(),
      ),
    ),
  );
  
  expect(find.text('Daily Summary'), findsOneWidget);
  expect(find.text('Weekly Report'), findsOneWidget);
  expect(find.text('Budget Alerts'), findsOneWidget);
});
```

### Manual Testing

Use the test buttons in NotificationSettingsPage:
1. Navigate to Notification Settings
2. Scroll to "Test Notifications" section
3. Tap each test button
4. Verify notifications appear with correct content

## Troubleshooting

### Notifications Not Appearing

**Check Permissions:**
```dart
final enabled = await notificationService.areNotificationsEnabled();
print('Notifications enabled: $enabled');
```

**Check Pending Notifications:**
```dart
final pending = await notificationService.getPendingNotifications();
print('Pending: ${pending.length}');
```

**Verify Initialization:**
```dart
await notificationService.initialize();
print('Service initialized');
```

### Scheduled Notifications Not Firing

**Check System Settings:**
- Android: Battery optimization disabled for app
- iOS: Notifications enabled in Settings

**Verify Schedule:**
```dart
final pending = await notificationService.getPendingNotifications();
for (final notification in pending) {
  print('ID: ${notification.id}, Title: ${notification.title}');
}
```

**Reschedule:**
```dart
await notificationService.scheduleDailySummary();
await notificationService.scheduleWeeklyReport();
```

### Budget Alerts Not Triggering

**Check Settings:**
```dart
final settings = await ref.read(notificationSettingsProvider.future);
print('Budget alerts enabled: ${settings.budgetAlertsEnabled}');
```

**Manually Trigger:**
```dart
await notificationService.checkAndSendBudgetAlerts(budgetService);
```

## Examples

See [notification_examples.dart](lib/examples/notification_examples.dart) for 10 comprehensive examples:

1. Initialize Notification Service
2. Send Daily Summary Notification
3. Send Weekly Report Notification
4. Send Budget Alert Notifications
5. Schedule Recurring Notifications
6. Configure Notification Settings
7. Test Notifications
8. Check Notification Permissions
9. Trigger Budget Alerts on Expense Add
10. Complete Notification Setup in Main App

## Related Documentation

- [Budget Module](BUDGET_MODULE.md) - Budget tracking system
- [Dashboard Module](DASHBOARD.md) - Main dashboard
- [Expense Module](EXPENSE.md) - Expense management

## Future Enhancements

Potential improvements:
1. Push notifications via Firebase Cloud Messaging
2. Notification categories for grouping
3. Custom notification sounds
4. Notification history
5. Smart notification timing (ML-based)
6. Rich notifications with actions
7. Notification badges on app icon
8. Geofencing-based notifications
9. Expense category-specific notifications
10. Multi-language notification support

## Conclusion

The Notifications Module provides a robust, user-friendly system for keeping users informed about their financial activity. With customizable settings, intelligent scheduling, and comprehensive budget integration, it enhances user engagement and helps users stay on top of their spending.
