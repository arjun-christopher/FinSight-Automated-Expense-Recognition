import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/notification_scheduler.dart';
import '../services/budget_service.dart';
import '../core/models/expense.dart';

/// ============================================================================
/// NOTIFICATION EXAMPLES FOR FINSIGHT
/// ============================================================================
/// 
/// This file contains 10 comprehensive examples demonstrating how to use
/// the notification system in FinSight.
/// 
/// Examples included:
/// 1. Initialize Notification Service
/// 2. Send Daily Summary Notification
/// 3. Send Weekly Report Notification
/// 4. Send Budget Alert Notifications
/// 5. Schedule Recurring Notifications
/// 6. Configure Notification Settings
/// 7. Test Notifications
/// 8. Check Notification Permissions
/// 9. Trigger Budget Alerts on Expense Add
/// 10. Complete Notification Setup in Main App
/// 
/// To use these examples:
/// 1. Copy the relevant example code
/// 2. Integrate into your app
/// 3. Customize as needed
/// ============================================================================

// ============================================================================
// EXAMPLE 1: Initialize Notification Service
// ============================================================================
// Shows how to initialize the notification service at app startup

class Example1InitializeNotifications extends ConsumerStatefulWidget {
  const Example1InitializeNotifications({super.key});

  @override
  ConsumerState<Example1InitializeNotifications> createState() =>
      _Example1InitializeNotificationsState();
}

class _Example1InitializeNotificationsState
    extends ConsumerState<Example1InitializeNotifications> {
  bool _initialized = false;
  String _status = 'Not initialized';

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      setState(() => _status = 'Initializing...');
      
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
      
      setState(() {
        _initialized = true;
        _status = 'Initialized successfully';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Initialize Notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _initialized ? Icons.check_circle : Icons.pending,
              size: 64,
              color: _initialized ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(_status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeNotifications,
              child: const Text('Re-initialize'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 2: Send Daily Summary Notification
// ============================================================================
// Demonstrates sending a daily spending summary notification

class Example2DailySummaryNotification extends ConsumerWidget {
  const Example2DailySummaryNotification({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Summary')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _sendDailySummary(context, ref),
          child: const Text('Send Daily Summary'),
        ),
      ),
    );
  }

  Future<void> _sendDailySummary(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);
    final contentGenerator = ref.read(notificationContentGeneratorProvider);

    await contentGenerator.sendDailySummaryNotification(notificationService);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily summary notification sent!')),
      );
    }
  }
}

// ============================================================================
// EXAMPLE 3: Send Weekly Report Notification
// ============================================================================
// Demonstrates sending a weekly spending report notification

class Example3WeeklyReportNotification extends ConsumerWidget {
  const Example3WeeklyReportNotification({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Report')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _sendWeeklyReport(context, ref),
          child: const Text('Send Weekly Report'),
        ),
      ),
    );
  }

  Future<void> _sendWeeklyReport(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);
    final contentGenerator = ref.read(notificationContentGeneratorProvider);

    await contentGenerator.sendWeeklyReportNotification(notificationService);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weekly report notification sent!')),
      );
    }
  }
}

// ============================================================================
// EXAMPLE 4: Send Budget Alert Notifications
// ============================================================================
// Demonstrates sending budget warning and exceeded notifications

class Example4BudgetAlerts extends ConsumerWidget {
  const Example4BudgetAlerts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Alerts')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _sendWarning(context, ref),
              child: const Text('Send Budget Warning'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _sendExceeded(context, ref),
              child: const Text('Send Budget Exceeded'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _checkAllBudgets(context, ref),
              child: const Text('Check All Budgets & Alert'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendWarning(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);

    await notificationService.showBudgetWarningNotification(
      category: 'Food & Dining',
      spent: 320.0,
      budget: 400.0,
      percentage: 80.0,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget warning sent!')),
      );
    }
  }

  Future<void> _sendExceeded(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);

    await notificationService.showBudgetExceededNotification(
      category: 'Shopping',
      spent: 550.0,
      budget: 500.0,
      percentage: 110.0,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget exceeded notification sent!')),
      );
    }
  }

  Future<void> _checkAllBudgets(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);
    final budgetService = ref.read(budgetServiceProvider);

    await notificationService.checkAndSendBudgetAlerts(budgetService);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked all budgets and sent alerts!')),
      );
    }
  }
}

// ============================================================================
// EXAMPLE 5: Schedule Recurring Notifications
// ============================================================================
// Demonstrates scheduling daily and weekly notifications

class Example5ScheduleNotifications extends ConsumerWidget {
  const Example5ScheduleNotifications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Notifications')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.today),
                title: const Text('Daily Summary'),
                subtitle: const Text('Scheduled for 8:00 PM daily'),
                trailing: ElevatedButton(
                  onPressed: () => _scheduleDailySummary(context, ref),
                  child: const Text('Schedule'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Weekly Report'),
                subtitle: const Text('Scheduled for Monday 9:00 AM'),
                trailing: ElevatedButton(
                  onPressed: () => _scheduleWeeklyReport(context, ref),
                  child: const Text('Schedule'),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _viewPendingNotifications(context, ref),
              icon: const Icon(Icons.list),
              label: const Text('View Pending Notifications'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleDailySummary(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.scheduleDailySummary(hour: 20, minute: 0);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily summary scheduled for 8:00 PM')),
      );
    }
  }

  Future<void> _scheduleWeeklyReport(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.scheduleWeeklyReport(
      weekday: DateTime.monday,
      hour: 9,
      minute: 0,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weekly report scheduled for Monday 9:00 AM')),
      );
    }
  }

  Future<void> _viewPendingNotifications(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);
    final pending = await notificationService.getPendingNotifications();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pending Notifications'),
          content: Text('${pending.length} notifications scheduled'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

// ============================================================================
// EXAMPLE 6: Configure Notification Settings
// ============================================================================
// Demonstrates managing notification preferences

class Example6NotificationSettings extends ConsumerWidget {
  const Example6NotificationSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Daily Summary'),
              subtitle: Text(
                settings.dailySummaryEnabled
                    ? 'Enabled at ${_formatTime(settings.dailySummaryHour, settings.dailySummaryMinute)}'
                    : 'Disabled',
              ),
              value: settings.dailySummaryEnabled,
              onChanged: (value) {
                ref
                    .read(notificationSettingsProvider.notifier)
                    .updateDailySummarySettings(enabled: value);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Weekly Report'),
              subtitle: Text(
                settings.weeklyReportEnabled
                    ? 'Enabled on ${_getWeekdayName(settings.weeklyReportWeekday)}'
                    : 'Disabled',
              ),
              value: settings.weeklyReportEnabled,
              onChanged: (value) {
                ref
                    .read(notificationSettingsProvider.notifier)
                    .updateWeeklyReportSettings(enabled: value);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Budget Alerts'),
              subtitle: Text(
                settings.budgetAlertsEnabled
                    ? 'Enabled'
                    : 'Disabled',
              ),
              value: settings.budgetAlertsEnabled,
              onChanged: (value) {
                ref
                    .read(notificationSettingsProvider.notifier)
                    .updateBudgetAlertsEnabled(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _getWeekdayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}

// ============================================================================
// EXAMPLE 7: Test Notifications
// ============================================================================
// Demonstrates testing all notification types

class Example7TestNotifications extends ConsumerWidget {
  const Example7TestNotifications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Notifications')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildTestCard(
            icon: Icons.today,
            title: 'Daily Summary',
            color: Colors.blue,
            onPressed: () => _testDailySummary(context, ref),
          ),
          _buildTestCard(
            icon: Icons.calendar_today,
            title: 'Weekly Report',
            color: Colors.green,
            onPressed: () => _testWeeklyReport(context, ref),
          ),
          _buildTestCard(
            icon: Icons.warning,
            title: 'Budget Warning',
            color: Colors.orange,
            onPressed: () => _testBudgetWarning(context, ref),
          ),
          _buildTestCard(
            icon: Icons.error,
            title: 'Budget Exceeded',
            color: Colors.red,
            onPressed: () => _testBudgetExceeded(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _testDailySummary(BuildContext context, WidgetRef ref) async {
    final service = ref.read(notificationServiceProvider);
    await service.showDailySummaryNotification(
      expenses: [],
      totalSpent: 0,
    );
    _showSnackBar(context, 'Daily summary sent');
  }

  Future<void> _testWeeklyReport(BuildContext context, WidgetRef ref) async {
    final service = ref.read(notificationServiceProvider);
    await service.showWeeklyReportNotification(
      expenses: [],
      totalSpent: 0,
      previousWeekTotal: 0,
    );
    _showSnackBar(context, 'Weekly report sent');
  }

  Future<void> _testBudgetWarning(BuildContext context, WidgetRef ref) async {
    final service = ref.read(notificationServiceProvider);
    await service.showBudgetWarningNotification(
      category: 'Test Category',
      spent: 80,
      budget: 100,
      percentage: 80,
    );
    _showSnackBar(context, 'Budget warning sent');
  }

  Future<void> _testBudgetExceeded(BuildContext context, WidgetRef ref) async {
    final service = ref.read(notificationServiceProvider);
    await service.showBudgetExceededNotification(
      category: 'Test Category',
      spent: 110,
      budget: 100,
      percentage: 110,
    );
    _showSnackBar(context, 'Budget exceeded sent');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ============================================================================
// EXAMPLE 8: Check Notification Permissions
// ============================================================================
// Demonstrates checking if notifications are enabled

class Example8CheckPermissions extends ConsumerStatefulWidget {
  const Example8CheckPermissions({super.key});

  @override
  ConsumerState<Example8CheckPermissions> createState() =>
      _Example8CheckPermissionsState();
}

class _Example8CheckPermissionsState
    extends ConsumerState<Example8CheckPermissions> {
  bool? _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final service = ref.read(notificationServiceProvider);
    final enabled = await service.areNotificationsEnabled();
    setState(() => _notificationsEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Permissions')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _notificationsEnabled == true
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              size: 64,
              color: _notificationsEnabled == true ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _notificationsEnabled == null
                  ? 'Checking...'
                  : _notificationsEnabled!
                      ? 'Notifications Enabled'
                      : 'Notifications Disabled',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkPermissions,
              child: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 9: Trigger Budget Alerts on Expense Add
// ============================================================================
// Demonstrates auto-triggering budget alerts when adding expenses

class Example9AutoBudgetAlerts extends ConsumerWidget {
  const Example9AutoBudgetAlerts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Budget Alerts')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _addExpenseAndCheckBudget(context, ref),
          child: const Text('Add Expense & Check Budget'),
        ),
      ),
    );
  }

  Future<void> _addExpenseAndCheckBudget(
      BuildContext context, WidgetRef ref) async {
    // Simulate adding an expense
    // In real app, this would be after expense is saved to database
    
    final notificationService = ref.read(notificationServiceProvider);
    final budgetService = ref.read(budgetServiceProvider);
    final settingsAsync = ref.read(notificationSettingsProvider);

    // Check if budget alerts are enabled
    final settings = settingsAsync.value;
    if (settings?.budgetAlertsEnabled != true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget alerts are disabled')),
        );
      }
      return;
    }

    // Check budgets and send alerts
    await notificationService.checkAndSendBudgetAlerts(budgetService);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added and budget checked!')),
      );
    }
  }
}

// ============================================================================
// EXAMPLE 10: Complete Notification Setup in Main App
// ============================================================================
// Shows complete integration in main.dart

/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Schedule recurring notifications
  await notificationService.scheduleDailySummary();
  await notificationService.scheduleWeeklyReport();
  
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'FinSight',
      home: HomePage(),
    );
  }
}
*/

/// ============================================================================
/// USAGE GUIDE
/// ============================================================================
/// 
/// To use these examples in your app:
/// 
/// 1. Import this file:
///    ```dart
///    import 'package:finsight/examples/notification_examples.dart';
///    ```
/// 
/// 2. Navigate to an example:
///    ```dart
///    Navigator.push(
///      context,
///      MaterialPageRoute(builder: (context) => Example1InitializeNotifications()),
///    );
///    ```
/// 
/// 3. Or copy the code from any example and integrate into your existing pages
/// 
/// Key Points:
/// - Always initialize notification service before use
/// - Use providers for accessing services
/// - Check notification settings before sending
/// - Handle errors appropriately
/// - Test notifications in different scenarios
/// 
/// ============================================================================
