# FinSight Notifications - Quick Setup Guide

## 🚀 Quick Start (5 minutes)

### Step 1: Initialize in main.dart

```dart
import 'package:finsight/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Schedule recurring notifications
  await notificationService.scheduleDailySummary();
  await notificationService.scheduleWeeklyReport();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

### Step 2: Add Notification Settings to Menu

```dart
// In your settings/menu screen
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

### Step 3: Trigger Budget Alerts After Adding Expense

```dart
// In your expense creation logic
Future<void> addExpense(Expense expense) async {
  // Save expense
  await expenseRepository.createExpense(expense);
  
  // Check budget alerts
  final settings = await ref.read(notificationSettingsProvider.future);
  if (settings.budgetAlertsEnabled) {
    final notificationService = ref.read(notificationServiceProvider);
    final budgetService = ref.read(budgetServiceProvider);
    await notificationService.checkAndSendBudgetAlerts(budgetService);
  }
}
```

### Step 4: Platform Setup

#### Android (AndroidManifest.xml)

Add these permissions inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

Add these receivers inside `<application>`:

```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

#### iOS

No additional setup required! Permissions are requested automatically.

---

## 📱 Notification Types

### 1. Daily Summary (8 PM)
- Total spent today
- Number of expenses
- Top category

### 2. Weekly Report (Monday 9 AM)
- Week total
- Daily average
- Trend vs last week

### 3. Budget Alerts (Real-time)
- Warning at 80% budget used
- Alert when budget exceeded

---

## ⚙️ Common Operations

### Send Test Notification

```dart
final service = ref.read(notificationServiceProvider);
await service.showDailySummaryNotification(
  expenses: [],
  totalSpent: 0,
);
```

### Check if Enabled

```dart
final enabled = await notificationService.areNotificationsEnabled();
```

### Change Daily Summary Time

```dart
await ref.read(notificationSettingsProvider.notifier)
  .updateDailySummarySettings(hour: 21, minute: 0); // 9 PM
```

### Disable Budget Alerts

```dart
await ref.read(notificationSettingsProvider.notifier)
  .updateBudgetAlertsEnabled(false);
```

---

## 📚 Full Documentation

- **Complete Guide**: See [NOTIFICATIONS_MODULE.md](NOTIFICATIONS_MODULE.md)
- **Examples**: See [notification_examples.dart](lib/examples/notification_examples.dart)
- **Task Summary**: See [TASK_11_SUMMARY.md](TASK_11_SUMMARY.md)

---

## 🐛 Troubleshooting

**Notifications not appearing?**
```dart
// Check permissions
final enabled = await notificationService.areNotificationsEnabled();
print('Enabled: $enabled');

// Check pending
final pending = await notificationService.getPendingNotifications();
print('Pending: ${pending.length}');
```

**Need to reschedule?**
```dart
await notificationService.scheduleDailySummary();
await notificationService.scheduleWeeklyReport();
```

---

## ✅ Checklist

- [ ] Added initialization to main.dart
- [ ] Added notification settings to menu
- [ ] Integrated budget alerts in expense creation
- [ ] Added Android permissions to AndroidManifest.xml
- [ ] Tested all notification types
- [ ] Verified scheduled notifications work

---

**Ready to go!** 🎉
