enum BudgetPeriod {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly'),
  yearly('yearly');

  final String value;
  const BudgetPeriod(this.value);

  static BudgetPeriod fromString(String value) {
    return BudgetPeriod.values.firstWhere(
      (period) => period.value == value,
      orElse: () => BudgetPeriod.monthly,
    );
  }
}

class Budget {
  final int? id;
  final String category;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final double alertThreshold; // 0.0 to 1.0 (e.g., 0.8 = 80%)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.period,
    required this.startDate,
    this.endDate,
    this.alertThreshold = 0.8,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert Budget to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'period': period.value,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'alert_threshold': alertThreshold,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create Budget from Map
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      period: BudgetPeriod.fromString(map['period'] as String),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      alertThreshold: map['alert_threshold'] != null
          ? (map['alert_threshold'] as num).toDouble()
          : 0.8,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Create a copy with updated fields
  Budget copyWith({
    int? id,
    String? category,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    double? alertThreshold,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Check if budget is currently active based on dates
  bool isCurrentlyActive() {
    final now = DateTime.now();
    if (!isActive) return false;
    if (now.isBefore(startDate)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  @override
  String toString() {
    return 'Budget(id: $id, category: $category, amount: $amount, period: ${period.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget &&
        other.id == id &&
        other.category == category &&
        other.amount == amount;
  }

  @override
  int get hashCode {
    return Object.hash(id, category, amount);
  }
}
