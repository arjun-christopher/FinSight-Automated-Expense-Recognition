import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/expense.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../core/providers/database_providers.dart';
import '../../../services/currency_service.dart';
import '../../settings/providers/currency_providers.dart';

/// Dashboard statistics model
class DashboardStats {
  final double totalExpenses;
  final double monthlyExpenses;
  final double weeklyExpenses;
  final int expenseCount;
  final Map<String, double> categoryTotals;
  final List<MonthlyData> monthlyTrend;
  final List<WeeklyData> weeklyData;
  final List<Expense> recentExpenses;

  DashboardStats({
    required this.totalExpenses,
    required this.monthlyExpenses,
    required this.weeklyExpenses,
    required this.expenseCount,
    required this.categoryTotals,
    required this.monthlyTrend,
    required this.weeklyData,
    required this.recentExpenses,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalExpenses: 0.0,
      monthlyExpenses: 0.0,
      weeklyExpenses: 0.0,
      expenseCount: 0,
      categoryTotals: {},
      monthlyTrend: [],
      weeklyData: [],
      recentExpenses: [],
    );
  }
}

/// Monthly trend data point
class MonthlyData {
  final DateTime month;
  final double amount;

  MonthlyData({
    required this.month,
    required this.amount,
  });
}

/// Weekly data point
class WeeklyData {
  final String day;
  final double amount;

  WeeklyData({
    required this.day,
    required this.amount,
  });
}

/// Dashboard state
class DashboardState {
  final DashboardStats stats;
  final bool isLoading;
  final String? errorMessage;

  DashboardState({
    required this.stats,
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStats? stats,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Dashboard provider
class DashboardNotifier extends StateNotifier<DashboardState> {
  final ExpenseRepository _repository;
  final Ref _ref;

  DashboardNotifier(this._repository, this._ref)
      : super(DashboardState(stats: DashboardStats.empty(), isLoading: true)) {
    loadDashboardData();
  }
  
  /// Convert expense amount to display currency
  Future<double> _convertAmount(Expense expense) async {
    final displayCurrency = _ref.read(currencyNotifierProvider);
    if (expense.currency == displayCurrency) {
      return expense.amount;
    }
    
    return await _ref.read(currencyNotifierProvider.notifier).convertAmount(
      amount: expense.amount,
      from: expense.currency ?? 'USD',
      to: displayCurrency,
    );
  }

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Get all expenses
      final allExpenses = await _repository.getAllExpenses();

      // Calculate total expenses (convert to display currency)
      double totalExpenses = 0.0;
      for (final expense in allExpenses) {
        totalExpenses += await _convertAmount(expense);
      }

      // Get current month expenses
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final monthExpenses = allExpenses
          .where((e) => e.date.isAfter(monthStart) && e.date.isBefore(monthEnd))
          .toList();
      
      double monthlyTotal = 0.0;
      for (final expense in monthExpenses) {
        monthlyTotal += await _convertAmount(expense);
      }

      // Get week expenses
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
      final weekExpenses = allExpenses
          .where((e) => e.date.isAfter(weekStart) && e.date.isBefore(weekEnd))
          .toList();
      
      double weeklyTotal = 0.0;
      for (final expense in weekExpenses) {
        weeklyTotal += await _convertAmount(expense);
      }

      // Get category totals (convert to display currency)
      final categoryTotals = <String, double>{};
      for (final expense in allExpenses) {
        final convertedAmount = await _convertAmount(expense);
        categoryTotals[expense.category] = 
            (categoryTotals[expense.category] ?? 0.0) + convertedAmount;
      }

      // Calculate monthly trend (last 6 months)
      final monthlyTrend = await _calculateMonthlyTrend(allExpenses);

      // Calculate weekly data (current week)
      final weeklyData = await _calculateWeeklyData(weekExpenses);

      // Get recent expenses (last 10)
      final recentExpenses = allExpenses.take(10).toList();

      state = DashboardState(
        stats: DashboardStats(
          totalExpenses: totalExpenses,
          monthlyExpenses: monthlyTotal,
          weeklyExpenses: weeklyTotal,
          expenseCount: allExpenses.length,
          categoryTotals: categoryTotals,
          monthlyTrend: monthlyTrend,
          weeklyData: weeklyData,
          recentExpenses: recentExpenses,
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard data: $e',
      );
    }
  }

  /// Calculate monthly trend for last 6 months
  Future<List<MonthlyData>> _calculateMonthlyTrend(List<Expense> expenses) async {
    final now = DateTime.now();
    final months = <MonthlyData>[];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthStart = DateTime(monthDate.year, monthDate.month, 1);
      final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59);

      final monthExpenses = expenses.where((e) {
        return e.date.isAfter(monthStart) && e.date.isBefore(monthEnd);
      }).toList();

      double total = 0.0;
      for (final expense in monthExpenses) {
        total += await _convertAmount(expense);
      }

      months.add(MonthlyData(month: monthStart, amount: total));
    }

    return months;
  }

  /// Calculate weekly data for current week
  Future<List<WeeklyData>> _calculateWeeklyData(List<Expense> weekExpenses) async {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weeklyData = <WeeklyData>[];

    for (int i = 0; i < 7; i++) {
      final dayDate = weekStart.add(Duration(days: i));
      final dayStart = DateTime(dayDate.year, dayDate.month, dayDate.day);
      final dayEnd = DateTime(dayDate.year, dayDate.month, dayDate.day, 23, 59);

      final dayExpenses = weekExpenses.where((e) {
        return e.date.isAfter(dayStart) && e.date.isBefore(dayEnd);
      }).toList();

      double total = 0.0;
      for (final expense in dayExpenses) {
        total += await _convertAmount(expense);
      }

      weeklyData.add(WeeklyData(day: days[i], amount: total));
    }

    return weeklyData;
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData();
  }

  /// Filter by date range
  Future<void> filterByDateRange(DateTime startDate, DateTime endDate) async {
    state = state.copyWith(isLoading: true);

    try {
      final expenses = await _repository.getExpensesByDateRange(
        startDate,
        endDate,
      );

      double totalExpenses = 0.0;
      for (final expense in expenses) {
        totalExpenses += await _convertAmount(expense);
      }

      // Calculate category totals for period (convert to display currency)
      final categoryTotals = <String, double>{};
      for (final expense in expenses) {
        final convertedAmount = await _convertAmount(expense);
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0.0) + convertedAmount;
      }

      state = DashboardState(
        stats: DashboardStats(
          totalExpenses: totalExpenses,
          monthlyExpenses: 0.0, // Not applicable for custom range
          weeklyExpenses: 0.0, // Not applicable for custom range
          expenseCount: expenses.length,
          categoryTotals: categoryTotals,
          monthlyTrend: [], // Could calculate if needed
          weeklyData: [], // Could calculate if needed
          recentExpenses: expenses.take(10).toList(),
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to filter data: $e',
      );
    }
  }
}

/// Dashboard provider
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return DashboardNotifier(repository, ref);
});
