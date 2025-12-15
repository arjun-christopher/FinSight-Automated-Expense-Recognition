class Expense {
  final int? id;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;
  final String? paymentMethod;
  final int? receiptImageId;
  final List<String>? tags;
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
    this.paymentMethod,
    this.receiptImageId,
    this.tags,
    this.isRecurring = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert Expense to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      'receipt_image_id': receiptImageId,
      'tags': tags?.join(','),
      'is_recurring': isRecurring ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create Expense from Map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      paymentMethod: map['payment_method'] as String?,
      receiptImageId: map['receipt_image_id'] as int?,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : null,
      isRecurring: map['is_recurring'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Create a copy with updated fields
  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? paymentMethod,
    int? receiptImageId,
    List<String>? tags,
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptImageId: receiptImageId ?? this.receiptImageId,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, category: $category, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense &&
        other.id == id &&
        other.amount == amount &&
        other.category == category &&
        other.date == date;
  }

  @override
  int get hashCode {
    return Object.hash(id, amount, category, date);
  }
}
