class ReceiptImage {
  final int? id;
  final String filePath;
  final String? extractedText;
  final double? confidence;
  final double? extractedAmount;
  final DateTime? extractedDate;
  final String? extractedMerchant;
  final bool isProcessed;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReceiptImage({
    this.id,
    required this.filePath,
    this.extractedText,
    this.confidence,
    this.extractedAmount,
    this.extractedDate,
    this.extractedMerchant,
    this.isProcessed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert ReceiptImage to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'extracted_text': extractedText,
      'confidence': confidence,
      'extracted_amount': extractedAmount,
      'extracted_date': extractedDate?.toIso8601String(),
      'extracted_merchant': extractedMerchant,
      'is_processed': isProcessed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create ReceiptImage from Map
  factory ReceiptImage.fromMap(Map<String, dynamic> map) {
    return ReceiptImage(
      id: map['id'] as int?,
      filePath: map['file_path'] as String,
      extractedText: map['extracted_text'] as String?,
      confidence: map['confidence'] != null
          ? (map['confidence'] as num).toDouble()
          : null,
      extractedAmount: map['extracted_amount'] != null
          ? (map['extracted_amount'] as num).toDouble()
          : null,
      extractedDate: map['extracted_date'] != null
          ? DateTime.parse(map['extracted_date'] as String)
          : null,
      extractedMerchant: map['extracted_merchant'] as String?,
      isProcessed: map['is_processed'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Create a copy with updated fields
  ReceiptImage copyWith({
    int? id,
    String? filePath,
    String? extractedText,
    double? confidence,
    double? extractedAmount,
    DateTime? extractedDate,
    String? extractedMerchant,
    bool? isProcessed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReceiptImage(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      extractedText: extractedText ?? this.extractedText,
      confidence: confidence ?? this.confidence,
      extractedAmount: extractedAmount ?? this.extractedAmount,
      extractedDate: extractedDate ?? this.extractedDate,
      extractedMerchant: extractedMerchant ?? this.extractedMerchant,
      isProcessed: isProcessed ?? this.isProcessed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ReceiptImage(id: $id, filePath: $filePath, isProcessed: $isProcessed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptImage &&
        other.id == id &&
        other.filePath == filePath;
  }

  @override
  int get hashCode {
    return Object.hash(id, filePath);
  }
}
