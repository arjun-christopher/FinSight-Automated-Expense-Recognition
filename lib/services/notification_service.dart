import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../core/models/expense.dart';
import '../services/budget_service.dart';

/// Notification types for different alert categories
enum NotificationType {
  dailySummary,
  weeklyReport,
  budgetAlert,
  budgetWarning,
  budgetExceeded,
}

/// NotificationService handles all local notifications for the app
/// 
/// Features:
/// - Daily spending summaries
/// - Weekly spending reports
/// - Budget alerts (warning and exceeded)
/// - Scheduled notifications
/// - Immediate notifications
/// 
/// Usage:
/// ```dart
/// final notificationService = NotificationService();
/// await notificationService.initialize();
/// await notificationService.showDailySummaryNotification(expenses, totalSpent);
/// ```
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  /// Must be called before using any other methods
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with settings
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    await _requestIOSPermissions();

    // Create notification channels for Android
    await _createNotificationChannels();

    _initialized = true;
  }

  /// Request notification permissions on iOS
  Future<void> _requestIOSPermissions() async {
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Daily Summary Channel
    const dailySummaryChannel = AndroidNotificationChannel(
      'daily_summary',
      'Daily Summary',
      description: 'Daily spending summary notifications',
      importance: Importance.high,
      playSound: true,
    );

    // Weekly Report Channel
    const weeklyReportChannel = AndroidNotificationChannel(
      'weekly_report',
      'Weekly Report',
      description: 'Weekly spending report notifications',
      importance: Importance.high,
      playSound: true,
    );

    // Budget Alerts Channel
    const budgetAlertsChannel = AndroidNotificationChannel(
      'budget_alerts',
      'Budget Alerts',
      description: 'Budget warning and exceeded notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(dailySummaryChannel);
    await androidPlugin.createNotificationChannel(weeklyReportChannel);
    await androidPlugin.createNotificationChannel(budgetAlertsChannel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on notification payload
    // Can be extended to navigate to specific screens
    print('Notification tapped: ${response.payload}');
  }

  /// Show daily spending summary notification
  /// 
  /// Displays total spent, number of expenses, and top category
  Future<void> showDailySummaryNotification({
    required List<Expense> expenses,
    required double totalSpent,
  }) async {
    if (!_initialized) await initialize();

    final expenseCount = expenses.length;
    
    // Find top category
    String topCategory = 'None';
    double topAmount = 0;
    
    if (expenses.isNotEmpty) {
      final categoryTotals = <String, double>{};
      for (final expense in expenses) {
        categoryTotals[expense.category] = 
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }
      
      final topEntry = categoryTotals.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      topCategory = topEntry.key;
      topAmount = topEntry.value;
    }

    final title = '📊 Daily Spending Summary';
    final body = expenseCount > 0
        ? 'You spent \$${totalSpent.toStringAsFixed(2)} today across $expenseCount expenses. Top category: $topCategory (\$${topAmount.toStringAsFixed(2)})'
        : 'No expenses recorded today. Keep tracking!';

    await _showNotification(
      id: NotificationType.dailySummary.index,
      title: title,
      body: body,
      channelId: 'daily_summary',
      payload: 'daily_summary',
    );
  }

  /// Show weekly spending report notification
  /// 
  /// Displays weekly total, daily average, and trends
  Future<void> showWeeklyReportNotification({
    required List<Expense> expenses,
    required double totalSpent,
    required double previousWeekTotal,
  }) async {
    if (!_initialized) await initialize();

    final expenseCount = expenses.length;
    final dailyAverage = totalSpent / 7;
    
    // Calculate trend
    String trend = '';
    if (previousWeekTotal > 0) {
      final percentChange = ((totalSpent - previousWeekTotal) / previousWeekTotal * 100);
      if (percentChange > 10) {
        trend = ' ⬆️ ${percentChange.toStringAsFixed(0)}% more than last week';
      } else if (percentChange < -10) {
        trend = ' ⬇️ ${percentChange.abs().toStringAsFixed(0)}% less than last week';
      } else {
        trend = ' Similar to last week';
      }
    }

    final title = '📈 Weekly Spending Report';
    final body = 'Week total: \$${totalSpent.toStringAsFixed(2)} ($expenseCount expenses). '
        'Daily average: \$${dailyAverage.toStringAsFixed(2)}.$trend';

    await _showNotification(
      id: NotificationType.weeklyReport.index,
      title: title,
      body: body,
      channelId: 'weekly_report',
      payload: 'weekly_report',
    );
  }

  /// Show budget alert notification (warning)
  /// 
  /// Notifies when spending approaches budget threshold
  Future<void> showBudgetWarningNotification({
    required String category,
    required double spent,
    required double budget,
    required double percentage,
  }) async {
    if (!_initialized) await initialize();

    final remaining = budget - spent;
    
    final title = '⚠️ Budget Warning: $category';
    final body = 'You\'ve used ${percentage.toStringAsFixed(0)}% of your budget. '
        '\$${remaining.toStringAsFixed(2)} remaining.';

    await _showNotification(
      id: NotificationType.budgetWarning.index + category.hashCode,
      title: title,
      body: body,
      channelId: 'budget_alerts',
      payload: 'budget_warning:$category',
    );
  }

  /// Show budget exceeded notification
  /// 
  /// Notifies when spending exceeds budget limit
  Future<void> showBudgetExceededNotification({
    required String category,
    required double spent,
    required double budget,
    required double percentage,
  }) async {
    if (!_initialized) await initialize();

    final over = spent - budget;
    
    final title = '🚨 Budget Exceeded: $category';
    final body = 'You\'ve exceeded your budget by \$${over.toStringAsFixed(2)} '
        '(${percentage.toStringAsFixed(0)}% used).';

    await _showNotification(
      id: NotificationType.budgetExceeded.index + category.hashCode,
      title: title,
      body: body,
      channelId: 'budget_alerts',
      payload: 'budget_exceeded:$category',
    );
  }

  /// Check budget statuses and send alerts if needed
  /// 
  /// Should be called after adding new expenses
  Future<void> checkAndSendBudgetAlerts(BudgetService budgetService) async {
    if (!_initialized) await initialize();

    final statuses = await budgetService.getAllBudgetStatuses(DateTime.now());

    for (final status in statuses) {
      if (status.alertLevel == BudgetAlertLevel.exceeded) {
        await showBudgetExceededNotification(
          category: status.budget.category,
          spent: status.currentSpending,
          budget: status.budget.amount,
          percentage: status.percentageUsed,
        );
      } else if (status.alertLevel == BudgetAlertLevel.warning) {
        // Only show warning if we just crossed the threshold
        // You might want to track this in shared preferences to avoid spam
        await showBudgetWarningNotification(
          category: status.budget.category,
          spent: status.currentSpending,
          budget: status.budget.amount,
          percentage: status.percentageUsed,
        );
      }
    }
  }

  /// Schedule daily summary notification
  /// 
  /// Schedules notification for 8 PM every day
  Future<void> scheduleDailySummary({int hour = 20, int minute = 0}) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      100, // Unique ID for daily summary
      '📊 Daily Spending Summary',
      'Tap to view your spending for today',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          'Daily Summary',
          channelDescription: 'Daily spending summary notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  /// Schedule weekly report notification
  /// 
  /// Schedules notification for Monday 9 AM every week
  Future<void> scheduleWeeklyReport({
    int weekday = DateTime.monday,
    int hour = 9,
    int minute = 0,
  }) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    var scheduledDate = _nextWeekday(now, weekday);
    scheduledDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      hour,
      minute,
    );

    await _notifications.zonedSchedule(
      200, // Unique ID for weekly report
      '📈 Weekly Spending Report',
      'Tap to view your spending for this week',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_report',
          'Weekly Report',
          channelDescription: 'Weekly spending report notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Get next occurrence of a weekday
  DateTime _nextWeekday(DateTime date, int weekday) {
    final daysUntil = (weekday - date.weekday) % 7;
    return date.add(Duration(days: daysUntil == 0 ? 7 : daysUntil));
  }

  /// Show a notification immediately
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _getChannelName(channelId),
          channelDescription: _getChannelDescription(channelId),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Get channel name from channel ID
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'daily_summary':
        return 'Daily Summary';
      case 'weekly_report':
        return 'Weekly Report';
      case 'budget_alerts':
        return 'Budget Alerts';
      default:
        return 'FinSight';
    }
  }

  /// Get channel description from channel ID
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'daily_summary':
        return 'Daily spending summary notifications';
      case 'weekly_report':
        return 'Weekly spending report notifications';
      case 'budget_alerts':
        return 'Budget warning and exceeded notifications';
      default:
        return 'FinSight notifications';
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>() != null) {
      return await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ?? false;
    }
    return true; // iOS doesn't have a direct check
  }
}
