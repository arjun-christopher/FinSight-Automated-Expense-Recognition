import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/budget_service.dart';
import '../data/repositories/expense_repository.dart';

/// Notification scheduling keys for SharedPreferences
class NotificationPreferenceKeys {
  static const String dailySummaryEnabled = 'notification_daily_summary_enabled';
  static const String dailySummaryHour = 'notification_daily_summary_hour';
  static const String dailySummaryMinute = 'notification_daily_summary_minute';
  
  static const String weeklyReportEnabled = 'notification_weekly_report_enabled';
  static const String weeklyReportWeekday = 'notification_weekly_report_weekday';
  static const String weeklyReportHour = 'notification_weekly_report_hour';
  static const String weeklyReportMinute = 'notification_weekly_report_minute';
  
  static const String budgetAlertsEnabled = 'notification_budget_alerts_enabled';
  
  static const String lastBudgetAlertCheck = 'notification_last_budget_alert_check';
}

/// Default notification times
class NotificationDefaults {
  static const int dailySummaryHour = 20; // 8 PM
  static const int dailySummaryMinute = 0;
  
  static const int weeklyReportWeekday = DateTime.monday;
  static const int weeklyReportHour = 9; // 9 AM
  static const int weeklyReportMinute = 0;
}

/// Notification settings data class
class NotificationSettings {
  final bool dailySummaryEnabled;
  final int dailySummaryHour;
  final int dailySummaryMinute;
  
  final bool weeklyReportEnabled;
  final int weeklyReportWeekday;
  final int weeklyReportHour;
  final int weeklyReportMinute;
  
  final bool budgetAlertsEnabled;

  const NotificationSettings({
    this.dailySummaryEnabled = true,
    this.dailySummaryHour = NotificationDefaults.dailySummaryHour,
    this.dailySummaryMinute = NotificationDefaults.dailySummaryMinute,
    this.weeklyReportEnabled = true,
    this.weeklyReportWeekday = NotificationDefaults.weeklyReportWeekday,
    this.weeklyReportHour = NotificationDefaults.weeklyReportHour,
    this.weeklyReportMinute = NotificationDefaults.weeklyReportMinute,
    this.budgetAlertsEnabled = true,
  });

  NotificationSettings copyWith({
    bool? dailySummaryEnabled,
    int? dailySummaryHour,
    int? dailySummaryMinute,
    bool? weeklyReportEnabled,
    int? weeklyReportWeekday,
    int? weeklyReportHour,
    int? weeklyReportMinute,
    bool? budgetAlertsEnabled,
  }) {
    return NotificationSettings(
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      dailySummaryHour: dailySummaryHour ?? this.dailySummaryHour,
      dailySummaryMinute: dailySummaryMinute ?? this.dailySummaryMinute,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      weeklyReportWeekday: weeklyReportWeekday ?? this.weeklyReportWeekday,
      weeklyReportHour: weeklyReportHour ?? this.weeklyReportHour,
      weeklyReportMinute: weeklyReportMinute ?? this.weeklyReportMinute,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
    );
  }
}

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider for notification settings
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, AsyncValue<NotificationSettings>>((ref) {
  return NotificationSettingsNotifier(ref);
});

/// Notification settings state notifier
class NotificationSettingsNotifier extends StateNotifier<AsyncValue<NotificationSettings>> {
  final Ref _ref;
  
  NotificationSettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  /// Load notification settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      
      final settings = NotificationSettings(
        dailySummaryEnabled: prefs.getBool(NotificationPreferenceKeys.dailySummaryEnabled) ?? true,
        dailySummaryHour: prefs.getInt(NotificationPreferenceKeys.dailySummaryHour) ?? NotificationDefaults.dailySummaryHour,
        dailySummaryMinute: prefs.getInt(NotificationPreferenceKeys.dailySummaryMinute) ?? NotificationDefaults.dailySummaryMinute,
        weeklyReportEnabled: prefs.getBool(NotificationPreferenceKeys.weeklyReportEnabled) ?? true,
        weeklyReportWeekday: prefs.getInt(NotificationPreferenceKeys.weeklyReportWeekday) ?? NotificationDefaults.weeklyReportWeekday,
        weeklyReportHour: prefs.getInt(NotificationPreferenceKeys.weeklyReportHour) ?? NotificationDefaults.weeklyReportHour,
        weeklyReportMinute: prefs.getInt(NotificationPreferenceKeys.weeklyReportMinute) ?? NotificationDefaults.weeklyReportMinute,
        budgetAlertsEnabled: prefs.getBool(NotificationPreferenceKeys.budgetAlertsEnabled) ?? true,
      );
      
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update daily summary settings
  Future<void> updateDailySummarySettings({
    bool? enabled,
    int? hour,
    int? minute,
  }) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    final newSettings = currentSettings.copyWith(
      dailySummaryEnabled: enabled,
      dailySummaryHour: hour,
      dailySummaryMinute: minute,
    );

    await _saveSettings(newSettings);
    
    // Reschedule notifications
    final notificationService = _ref.read(notificationServiceProvider);
    if (newSettings.dailySummaryEnabled) {
      await notificationService.scheduleDailySummary(
        hour: newSettings.dailySummaryHour,
        minute: newSettings.dailySummaryMinute,
      );
    } else {
      await notificationService.cancelNotification(100); // Daily summary ID
    }
  }

  /// Update weekly report settings
  Future<void> updateWeeklyReportSettings({
    bool? enabled,
    int? weekday,
    int? hour,
    int? minute,
  }) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    final newSettings = currentSettings.copyWith(
      weeklyReportEnabled: enabled,
      weeklyReportWeekday: weekday,
      weeklyReportHour: hour,
      weeklyReportMinute: minute,
    );

    await _saveSettings(newSettings);
    
    // Reschedule notifications
    final notificationService = _ref.read(notificationServiceProvider);
    if (newSettings.weeklyReportEnabled) {
      await notificationService.scheduleWeeklyReport(
        weekday: newSettings.weeklyReportWeekday,
        hour: newSettings.weeklyReportHour,
        minute: newSettings.weeklyReportMinute,
      );
    } else {
      await notificationService.cancelNotification(200); // Weekly report ID
    }
  }

  /// Update budget alerts setting
  Future<void> updateBudgetAlertsEnabled(bool enabled) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    final newSettings = currentSettings.copyWith(
      budgetAlertsEnabled: enabled,
    );

    await _saveSettings(newSettings);
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings(NotificationSettings settings) async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    
    await prefs.setBool(NotificationPreferenceKeys.dailySummaryEnabled, settings.dailySummaryEnabled);
    await prefs.setInt(NotificationPreferenceKeys.dailySummaryHour, settings.dailySummaryHour);
    await prefs.setInt(NotificationPreferenceKeys.dailySummaryMinute, settings.dailySummaryMinute);
    
    await prefs.setBool(NotificationPreferenceKeys.weeklyReportEnabled, settings.weeklyReportEnabled);
    await prefs.setInt(NotificationPreferenceKeys.weeklyReportWeekday, settings.weeklyReportWeekday);
    await prefs.setInt(NotificationPreferenceKeys.weeklyReportHour, settings.weeklyReportHour);
    await prefs.setInt(NotificationPreferenceKeys.weeklyReportMinute, settings.weeklyReportMinute);
    
    await prefs.setBool(NotificationPreferenceKeys.budgetAlertsEnabled, settings.budgetAlertsEnabled);
    
    state = AsyncValue.data(settings);
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    const defaultSettings = NotificationSettings();
    await _saveSettings(defaultSettings);
    
    // Reschedule with default times
    final notificationService = _ref.read(notificationServiceProvider);
    await notificationService.scheduleDailySummary();
    await notificationService.scheduleWeeklyReport();
  }
}

/// Helper class for generating notification content
class NotificationContentGenerator {
  final ExpenseRepository _expenseRepository;
  final BudgetService _budgetService;

  NotificationContentGenerator({
    required ExpenseRepository expenseRepository,
    required BudgetService budgetService,
  })  : _expenseRepository = expenseRepository,
        _budgetService = budgetService;

  /// Generate and send daily summary notification
  Future<void> sendDailySummaryNotification(NotificationService notificationService) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final expenses = await _expenseRepository.getExpensesByDateRange(startOfDay, endOfDay);
    final totalSpent = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    await notificationService.showDailySummaryNotification(
      expenses: expenses,
      totalSpent: totalSpent,
    );
  }

  /// Generate and send weekly report notification
  Future<void> sendWeeklyReportNotification(NotificationService notificationService) async {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endDate = startDate.add(const Duration(days: 7));

    final expenses = await _expenseRepository.getExpensesByDateRange(startDate, endDate);
    final totalSpent = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    // Get previous week's total
    final previousWeekStart = startDate.subtract(const Duration(days: 7));
    final previousWeekExpenses = await _expenseRepository.getExpensesByDateRange(
      previousWeekStart,
      startDate,
    );
    final previousWeekTotal = previousWeekExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    await notificationService.showWeeklyReportNotification(
      expenses: expenses,
      totalSpent: totalSpent,
      previousWeekTotal: previousWeekTotal,
    );
  }

  /// Check and send budget alerts if needed
  Future<void> checkAndSendBudgetAlerts(NotificationService notificationService) async {
    await notificationService.checkAndSendBudgetAlerts(_budgetService);
  }
}

/// Provider for notification content generator
final notificationContentGeneratorProvider = Provider<NotificationContentGenerator>((ref) {
  final expenseRepository = ref.read(expenseRepositoryProvider);
  final budgetService = ref.read(budgetServiceProvider);
  
  return NotificationContentGenerator(
    expenseRepository: expenseRepository,
    budgetService: budgetService,
  );
});
