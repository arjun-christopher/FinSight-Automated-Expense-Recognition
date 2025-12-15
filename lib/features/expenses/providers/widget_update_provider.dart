import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/android_widget_service.dart';
import '../data/repositories/expense_repository.dart';

// Provider for Android Widget Service
final androidWidgetServiceProvider = Provider<AndroidWidgetService>((ref) {
  return AndroidWidgetService();
});

// Provider to automatically update widget when expenses change
final widgetUpdateProvider = Provider<WidgetUpdateManager>((ref) {
  final widgetService = ref.watch(androidWidgetServiceProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  return WidgetUpdateManager(widgetService, expenseRepo);
});

/// Manager class for keeping widget in sync with expense data
class WidgetUpdateManager {
  final AndroidWidgetService _widgetService;
  final ExpenseRepository _expenseRepository;

  WidgetUpdateManager(this._widgetService, this._expenseRepository);

  /// Update widget with today's spending data
  Future<void> updateWidgetWithTodayData() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Get today's expenses
      final todayExpenses = await _expenseRepository.getExpensesByDateRange(
        startOfDay,
        endOfDay,
      );

      // Calculate total and count
      final todayAmount = todayExpenses.fold<double>(
        0.0,
        (sum, expense) => sum + expense.amount,
      );
      final expenseCount = todayExpenses.length;

      // Update widget
      await _widgetService.updateWidget(
        todayAmount: todayAmount,
        expenseCount: expenseCount,
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  /// Check if widgets are supported on this platform
  bool get isSupported => _widgetService.isWidgetSupported;
}
