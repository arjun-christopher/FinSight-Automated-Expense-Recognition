import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/notification_scheduler.dart';
import '../../../services/notification_service.dart';

/// Notification Settings Page
/// 
/// Allows users to configure:
/// - Daily spending summary notifications
/// - Weekly report notifications  
/// - Budget alert notifications
/// - Notification times
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(notificationSettingsProvider.notifier).resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset to default settings')),
              );
            },
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDailySummarySection(context, ref, settings),
            const SizedBox(height: 24),
            _buildWeeklyReportSection(context, ref, settings),
            const SizedBox(height: 24),
            _buildBudgetAlertsSection(context, ref, settings),
            const SizedBox(height: 24),
            _buildTestNotificationsSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummarySection(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Get a summary of your daily spending',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.dailySummaryEnabled,
                  onChanged: (value) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .updateDailySummarySettings(enabled: value);
                  },
                ),
              ],
            ),
            if (settings.dailySummaryEnabled) ...[
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Notification Time'),
                subtitle: Text(
                  _formatTime(settings.dailySummaryHour, settings.dailySummaryMinute),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectTime(
                  context,
                  ref,
                  settings.dailySummaryHour,
                  settings.dailySummaryMinute,
                  (hour, minute) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .updateDailySummarySettings(hour: hour, minute: minute);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyReportSection(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.green),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Report',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Get a weekly spending report',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.weeklyReportEnabled,
                  onChanged: (value) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .updateWeeklyReportSettings(enabled: value);
                  },
                ),
              ],
            ),
            if (settings.weeklyReportEnabled) ...[
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Day of Week'),
                subtitle: Text(_getWeekdayName(settings.weeklyReportWeekday)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectWeekday(
                  context,
                  ref,
                  settings.weeklyReportWeekday,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Notification Time'),
                subtitle: Text(
                  _formatTime(settings.weeklyReportHour, settings.weeklyReportMinute),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectTime(
                  context,
                  ref,
                  settings.weeklyReportHour,
                  settings.weeklyReportMinute,
                  (hour, minute) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .updateWeeklyReportSettings(hour: hour, minute: minute);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetAlertsSection(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Alerts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Get notified when approaching or exceeding budgets',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
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

  Widget _buildTestNotificationsSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bug_report, color: Colors.purple),
                SizedBox(width: 12),
                Text(
                  'Test Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Send test notifications to see how they look:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _sendTestDailySummary(context, ref),
                  icon: const Icon(Icons.today, size: 18),
                  label: const Text('Daily Summary'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendTestWeeklyReport(context, ref),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Weekly Report'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendTestBudgetWarning(context, ref),
                  icon: const Icon(Icons.warning, size: 18),
                  label: const Text('Budget Warning'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendTestBudgetExceeded(context, ref),
                  icon: const Icon(Icons.error, size: 18),
                  label: const Text('Budget Exceeded'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    WidgetRef ref,
    int currentHour,
    int currentMinute,
    Function(int, int) onTimeSelected,
  ) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );

    if (time != null) {
      onTimeSelected(time.hour, time.minute);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification time updated')),
        );
      }
    }
  }

  Future<void> _selectWeekday(
    BuildContext context,
    WidgetRef ref,
    int currentWeekday,
  ) async {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (index) {
            final weekday = index + 1;
            return RadioListTile<int>(
              title: Text(weekdays[index]),
              value: weekday,
              groupValue: currentWeekday,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .updateWeeklyReportSettings(weekday: value);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification day updated')),
                  );
                }
              },
            );
          }),
        ),
      ),
    );
  }

  Future<void> _sendTestDailySummary(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);
    final contentGenerator = ref.read(notificationContentGeneratorProvider);
    
    await contentGenerator.sendDailySummaryNotification(notificationService);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test daily summary sent!')),
      );
    }
  }

  Future<void> _sendTestWeeklyReport(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);
    final contentGenerator = ref.read(notificationContentGeneratorProvider);
    
    await contentGenerator.sendWeeklyReportNotification(notificationService);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test weekly report sent!')),
      );
    }
  }

  Future<void> _sendTestBudgetWarning(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);
    
    await notificationService.showBudgetWarningNotification(
      category: 'Food & Dining',
      spent: 320.0,
      budget: 400.0,
      percentage: 80.0,
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test budget warning sent!')),
      );
    }
  }

  Future<void> _sendTestBudgetExceeded(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);
    
    await notificationService.showBudgetExceededNotification(
      category: 'Shopping',
      spent: 550.0,
      budget: 500.0,
      percentage: 110.0,
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test budget exceeded sent!')),
      );
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }
}
