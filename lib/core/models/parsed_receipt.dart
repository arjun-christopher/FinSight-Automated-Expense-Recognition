/// Model representing structured data parsed from receipt OCR text
class ParsedReceipt {
  /// Total amount (final price paid)
  final double? totalAmount;

  /// Subtotal (before tax and discounts)
  final double? subtotal;

  /// Tax amount
  final double? tax;

  /// Merchant/store name
  final String? merchantName;

  /// Transaction date
  final DateTime? date;

  /// Transaction time
  final String? time;

  /// List of purchased items
  final List<ReceiptItem> items;

  /// Payment method (Cash, Credit Card, etc.)
  final String? paymentMethod;

  /// Receipt/transaction number
  final String? receiptNumber;

  /// Currency symbol/code
  final String? currency;

  /// Confidence score for parsing (0.0-1.0)
  final double confidence;

  /// Raw OCR text that was parsed
  final String rawText;

  /// Parsing metadata and details
  final ParsingMetadata metadata;

  const ParsedReceipt({
    this.totalAmount,
    this.subtotal,
    this.tax,
    this.merchantName,
    this.date,
    this.time,
    this.items = const [],
    this.paymentMethod,
    this.receiptNumber,
    this.currency,
    required this.confidence,
    required this.rawText,
    required this.metadata,
  });

  /// Create an empty/failed parse result
  factory ParsedReceipt.empty({
    required String rawText,
    String? errorMessage,
  }) {
    return ParsedReceipt(
      confidence: 0.0,
      rawText: rawText,
      metadata: ParsingMetadata(
        parseTime: DateTime.now(),
        errors: errorMessage != null ? [errorMessage] : [],
      ),
    );
  }

  /// Check if parsing was successful
  bool get isValid => confidence > 0.3 && (totalAmount != null || merchantName != null);

  /// Check if minimum required fields are present
  bool get hasRequiredFields => totalAmount != null && merchantName != null;

  /// Check if date was extracted
  bool get hasDate => date != null;

  /// Check if items were extracted
  bool get hasItems => items.isNotEmpty;

  /// Get total items count
  int get itemCount => items.length;

  /// Get formatted total amount
  String get formattedTotal {
    if (totalAmount == null) return 'N/A';
    final symbol = currency ?? '\$';
    return '$symbol${totalAmount!.toStringAsFixed(2)}';
  }

  /// Get formatted date
  String? get formattedDate {
    if (date == null) return null;
    return '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}';
  }

  /// Create a copy with updated fields
  ParsedReceipt copyWith({
    double? totalAmount,
    double? subtotal,
    double? tax,
    String? merchantName,
    DateTime? date,
    String? time,
    List<ReceiptItem>? items,
    String? paymentMethod,
    String? receiptNumber,
    String? currency,
    double? confidence,
    String? rawText,
    ParsingMetadata? metadata,
  }) {
    return ParsedReceipt(
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
      time: time ?? this.time,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      currency: currency ?? this.currency,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'ParsedReceipt(merchant: $merchantName, total: $formattedTotal, date: $formattedDate, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'tax': tax,
      'merchantName': merchantName,
      'date': date?.toIso8601String(),
      'time': time,
      'items': items.map((item) => item.toMap()).toList(),
      'paymentMethod': paymentMethod,
      'receiptNumber': receiptNumber,
      'currency': currency,
      'confidence': confidence,
      'rawText': rawText,
    };
  }

  /// Create from map
  factory ParsedReceipt.fromMap(Map<String, dynamic> map) {
    return ParsedReceipt(
      totalAmount: map['totalAmount'] as double?,
      subtotal: map['subtotal'] as double?,
      tax: map['tax'] as double?,
      merchantName: map['merchantName'] as String?,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : null,
      time: map['time'] as String?,
      items: (map['items'] as List?)
              ?.map((item) => ReceiptItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      paymentMethod: map['paymentMethod'] as String?,
      receiptNumber: map['receiptNumber'] as String?,
      currency: map['currency'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      rawText: map['rawText'] as String? ?? '',
      metadata: ParsingMetadata(parseTime: DateTime.now()),
    );
  }
}

/// Individual item from receipt
class ReceiptItem {
  /// Item name/description
  final String name;

  /// Item price
  final double? price;

  /// Quantity
  final int quantity;

  /// Total for this item (price * quantity)
  final double? total;

  const ReceiptItem({
    required this.name,
    this.price,
    this.quantity = 1,
    this.total,
  });

  /// Get formatted price
  String get formattedPrice {
    if (price == null) return 'N/A';
    return '\$${price!.toStringAsFixed(2)}';
  }

  /// Get formatted total
  String get formattedTotal {
    final amount = total ?? (price != null ? price! * quantity : null);
    if (amount == null) return 'N/A';
    return '\$${amount.toStringAsFixed(2)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      name: map['name'] as String,
      price: (map['price'] as num?)?.toDouble(),
      quantity: map['quantity'] as int? ?? 1,
      total: (map['total'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() => '$name x$quantity = $formattedTotal';
}

/// Metadata about the parsing process
class ParsingMetadata {
  /// When the parsing was performed
  final DateTime parseTime;

  /// Which parser strategies were used
  final List<String> strategiesUsed;

  /// Field extraction confidence scores
  final Map<String, double> fieldConfidences;

  /// Warnings during parsing
  final List<String> warnings;

  /// Errors during parsing
  final List<String> errors;

  /// Parsing duration in milliseconds
  final int? durationMs;

  ParsingMetadata({
    required this.parseTime,
    this.strategiesUsed = const [],
    this.fieldConfidences = const {},
    this.warnings = const [],
    this.errors = const [],
    this.durationMs,
  });

  /// Check if parsing was successful
  bool get hasErrors => errors.isNotEmpty;

  /// Check if there were warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Get overall quality indicator
  String get quality {
    if (hasErrors) return 'Poor';
    if (hasWarnings) return 'Fair';
    if (fieldConfidences.isEmpty) return 'Unknown';
    
    final avgConfidence = fieldConfidences.values.reduce((a, b) => a + b) / 
                          fieldConfidences.length;
    
    if (avgConfidence > 0.8) return 'Excellent';
    if (avgConfidence > 0.6) return 'Good';
    if (avgConfidence > 0.4) return 'Fair';
    return 'Poor';
  }

  @override
  String toString() {
    return 'ParsingMetadata(quality: $quality, strategies: ${strategiesUsed.length}, duration: ${durationMs}ms)';
  }
}

/// Field type enum for tracking what was extracted
enum ReceiptField {
  totalAmount,
  subtotal,
  tax,
  merchantName,
  date,
  time,
  items,
  paymentMethod,
  receiptNumber,
}

/// Extraction confidence levels
enum ConfidenceLevel {
  high,    // > 0.8
  medium,  // 0.5 - 0.8
  low,     // 0.3 - 0.5
  none,    // < 0.3
}

extension ConfidenceLevelExtension on double {
  ConfidenceLevel get level {
    if (this > 0.8) return ConfidenceLevel.high;
    if (this > 0.5) return ConfidenceLevel.medium;
    if (this > 0.3) return ConfidenceLevel.low;
    return ConfidenceLevel.none;
  }
}
