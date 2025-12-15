/// Budget model for tracking monthly spending limits by category
class Budget {
  final int? id;
  final String category;
  final double monthlyLimit;
  final int year;
  final int month;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Budget({
    this.id,
    required this.category,
    required this.monthlyLimit,
    required this.year,
    required this.month,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create Budget from database map
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      category: map['category'] as String,
      monthlyLimit: map['monthly_limit'] as double,
      year: map['year'] as int,
      month: map['month'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert Budget to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'monthly_limit': monthlyLimit,
      'year': year,
      'month': month,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create copy with updated fields
  Budget copyWith({
    int? id,
    String? category,
    double? monthlyLimit,
    int? year,
    int? month,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      year: year ?? this.year,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this budget is for the current month
  bool get isCurrentMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Get the date this budget applies to
  DateTime get budgetDate => DateTime(year, month);

  @override
  String toString() {
    return 'Budget(id: $id, category: $category, limit: \$$monthlyLimit, $year-$month)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Budget &&
        other.id == id &&
        other.category == category &&
        other.monthlyLimit == monthlyLimit &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      category,
      monthlyLimit,
      year,
      month,
    );
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
  double get remaining => budget.monthlyLimit - currentSpending;

  /// Whether budget is exceeded
  bool get isExceeded => currentSpending > budget.monthlyLimit;

  /// Whether budget is in warning zone (80%+)
  bool get isWarning => percentageUsed >= 80 && percentageUsed < 100;

  /// Whether budget is healthy (<80%)
  bool get isHealthy => percentageUsed < 80;

  @override
  String toString() {
    return 'BudgetStatus(category: ${budget.category}, spent: \$$currentSpending / \$${budget.monthlyLimit}, ${percentageUsed.toStringAsFixed(1)}%)';
  }
}

/// Alert levels for budget status
enum BudgetAlertLevel {
  healthy,  // < 80%
  warning,  // 80% - 99%
  exceeded, // >= 100%
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
