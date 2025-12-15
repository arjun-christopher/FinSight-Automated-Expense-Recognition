import '../models/budget.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/expense_repository.dart';

/// Service for budget tracking and alerts
class BudgetService {
  final BudgetRepository _budgetRepository;
  final ExpenseRepository _expenseRepository;

  BudgetService(this._budgetRepository, this._expenseRepository);

  /// Get budget status for a specific category and month
  Future<BudgetStatus?> getBudgetStatus({
    required String category,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final budget = await _budgetRepository.getBudgetByCategory(category);

    if (budget == null || !budget.isActive) return null;

    // Get spending for the budget period
    final spending = await _getSpendingForPeriod(
      category: category,
      budget: budget,
      date: targetDate,
    );

    final percentageUsed = budget.amount > 0
        ? (spending / budget.amount) * 100
        : 0.0;

    final alertLevel = _determineAlertLevel(percentageUsed, budget.alertThreshold);

    return BudgetStatus(
      budget: budget,
      currentSpending: spending,
      percentageUsed: percentageUsed,
      alertLevel: alertLevel,
    );
  }

  /// Get all budget statuses for current period
  Future<List<BudgetStatus>> getAllBudgetStatuses({DateTime? date}) async {
    final budgets = await _budgetRepository.getCurrentlyActiveBudgets();
    final statuses = <BudgetStatus>[];

    for (final budget in budgets) {
      final status = await getBudgetStatus(
        category: budget.category,
        date: date,
      );
      if (status != null) {
        statuses.add(status);
      }
    }

    return statuses;
  }

  /// Get budgets that need alerts (warning or exceeded)
  Future<List<BudgetStatus>> getBudgetsWithAlerts({DateTime? date}) async {
    final allStatuses = await getAllBudgetStatuses(date: date);
    return allStatuses.where((status) {
      return status.alertLevel == BudgetAlertLevel.warning ||
             status.alertLevel == BudgetAlertLevel.exceeded;
    }).toList();
  }

  /// Get exceeded budgets only
  Future<List<BudgetStatus>> getExceededBudgets({DateTime? date}) async {
    final allStatuses = await getAllBudgetStatuses(date: date);
    return allStatuses.where((status) {
      return status.alertLevel == BudgetAlertLevel.exceeded;
    }).toList();
  }

  /// Calculate total budget across all categories
  Future<double> getTotalBudget() async {
    final budgets = await _budgetRepository.getCurrentlyActiveBudgets();
    return budgets.fold(0.0, (sum, budget) => sum + budget.amount);
  }

  /// Calculate total spending across all categories
  Future<double> getTotalSpending({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final budgets = await _budgetRepository.getCurrentlyActiveBudgets();
    double totalSpending = 0.0;

    for (final budget in budgets) {
      final spending = await _getSpendingForPeriod(
        category: budget.category,
        budget: budget,
        date: targetDate,
      );
      totalSpending += spending;
    }

    return totalSpending;
  }

  /// Get overall budget health summary
  Future<BudgetHealthSummary> getBudgetHealthSummary({DateTime? date}) async {
    final allStatuses = await getAllBudgetStatuses(date: date);
    
    if (allStatuses.isEmpty) {
      return BudgetHealthSummary(
        totalBudget: 0,
        totalSpending: 0,
        healthyCount: 0,
        warningCount: 0,
        exceededCount: 0,
        overallPercentage: 0,
        overallHealth: BudgetAlertLevel.healthy,
      );
    }

    final totalBudget = allStatuses.fold(0.0, (sum, s) => sum + s.budget.amount);
    final totalSpending = allStatuses.fold(0.0, (sum, s) => sum + s.currentSpending);

    final healthyCount = allStatuses.where((s) => s.isHealthy).length;
    final warningCount = allStatuses.where((s) => s.isWarning).length;
    final exceededCount = allStatuses.where((s) => s.isExceeded).length;

    final overallPercentage = totalBudget > 0
        ? (totalSpending / totalBudget) * 100
        : 0.0;

    final overallHealth = _determineAlertLevel(overallPercentage, 0.8);

    return BudgetHealthSummary(
      totalBudget: totalBudget,
      totalSpending: totalSpending,
      healthyCount: healthyCount,
      warningCount: warningCount,
      exceededCount: exceededCount,
      overallPercentage: overallPercentage,
      overallHealth: overallHealth,
    );
  }

  /// Check if a new expense would exceed budget
  Future<bool> wouldExceedBudget({
    required String category,
    required double amount,
    DateTime? date,
  }) async {
    final status = await getBudgetStatus(category: category, date: date);
    if (status == null) return false;

    final projectedSpending = status.currentSpending + amount;
    return projectedSpending > status.budget.amount;
  }

  /// Get remaining budget for category
  Future<double> getRemainingBudget({
    required String category,
    DateTime? date,
  }) async {
    final status = await getBudgetStatus(category: category, date: date);
    if (status == null) return 0.0;
    return status.remaining;
  }

  /// Helper: Get spending for a budget period
  Future<double> _getSpendingForPeriod({
    required String category,
    required Budget budget,
    required DateTime date,
  }) async {
    final dateRange = _getDateRangeForPeriod(budget.period, date);
    
    final expenses = await _expenseRepository.getExpensesByDateRange(
      startDate: dateRange.start,
      endDate: dateRange.end,
    );

    // Filter by category and sum amounts
    return expenses
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Helper: Determine alert level based on percentage
  BudgetAlertLevel _determineAlertLevel(double percentage, double threshold) {
    final thresholdPercentage = threshold * 100;
    
    if (percentage >= 100) {
      return BudgetAlertLevel.exceeded;
    } else if (percentage >= thresholdPercentage) {
      return BudgetAlertLevel.warning;
    } else {
      return BudgetAlertLevel.healthy;
    }
  }

  /// Helper: Get date range for budget period
  DateTimeRange _getDateRangeForPeriod(BudgetPeriod period, DateTime date) {
    switch (period) {
      case BudgetPeriod.daily:
        final start = DateTime(date.year, date.month, date.day);
        final end = start.add(const Duration(days: 1));
        return DateTimeRange(start: start, end: end);

      case BudgetPeriod.weekly:
        final weekDay = date.weekday;
        final start = date.subtract(Duration(days: weekDay - 1));
        final startOfWeek = DateTime(start.year, start.month, start.day);
        final end = startOfWeek.add(const Duration(days: 7));
        return DateTimeRange(start: startOfWeek, end: end);

      case BudgetPeriod.monthly:
        final start = DateTime(date.year, date.month, 1);
        final end = DateTime(date.year, date.month + 1, 1);
        return DateTimeRange(start: start, end: end);

      case BudgetPeriod.yearly:
        final start = DateTime(date.year, 1, 1);
        final end = DateTime(date.year + 1, 1, 1);
        return DateTimeRange(start: start, end: end);
    }
  }
}

/// Budget status with spending information
class BudgetStatus {
  final Budget budget;
  final double currentSpending;
  final double percentageUsed;
  final BudgetAlertLevel alertLevel;

  BudgetStatus({
    required this.budget,
    required this.currentSpending,
    required this.percentageUsed,
    required this.alertLevel,
  });

  /// Remaining budget amount
  double get remaining => budget.amount - currentSpending;

  /// Whether budget is exceeded
  bool get isExceeded => currentSpending > budget.amount;

  /// Whether budget is in warning zone
  bool get isWarning => alertLevel == BudgetAlertLevel.warning;

  /// Whether budget is healthy
  bool get isHealthy => alertLevel == BudgetAlertLevel.healthy;

  @override
  String toString() {
    return 'BudgetStatus(category: ${budget.category}, spent: \$$currentSpending / \$${budget.amount}, ${percentageUsed.toStringAsFixed(1)}%)';
  }
}

/// Alert levels for budget status
enum BudgetAlertLevel {
  healthy,  // Below threshold
  warning,  // At or above threshold, but below 100%
  exceeded, // At or above 100%
}

extension BudgetAlertLevelExtension on BudgetAlertLevel {
  String get displayName {
    switch (this) {
      case BudgetAlertLevel.healthy:
        return 'On Track';
      case BudgetAlertLevel.warning:
        return 'Warning';
      case BudgetAlertLevel.exceeded:
        return 'Exceeded';
    }
  }

  String get description {
    switch (this) {
      case BudgetAlertLevel.healthy:
        return 'You\'re staying within budget';
      case BudgetAlertLevel.warning:
        return 'Approaching budget limit';
      case BudgetAlertLevel.exceeded:
        return 'Budget limit exceeded';
    }
  }
}

/// Overall budget health summary
class BudgetHealthSummary {
  final double totalBudget;
  final double totalSpending;
  final int healthyCount;
  final int warningCount;
  final int exceededCount;
  final double overallPercentage;
  final BudgetAlertLevel overallHealth;

  BudgetHealthSummary({
    required this.totalBudget,
    required this.totalSpending,
    required this.healthyCount,
    required this.warningCount,
    required this.exceededCount,
    required this.overallPercentage,
    required this.overallHealth,
  });

  double get totalRemaining => totalBudget - totalSpending;
  int get totalCategories => healthyCount + warningCount + exceededCount;
}

/// Date range helper class
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}
