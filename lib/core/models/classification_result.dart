/// Model representing category classification result
class ClassificationResult {
  /// Predicted category
  final String category;

  /// Confidence score (0.0 - 1.0)
  final double confidence;

  /// Classification method used
  final ClassificationMethod method;

  /// All candidate categories with scores
  final Map<String, double> candidateScores;

  /// Processing time in milliseconds
  final int processingTimeMs;

  const ClassificationResult({
    required this.category,
    required this.confidence,
    required this.method,
    this.candidateScores = const {},
    required this.processingTimeMs,
  });

  /// Create result from rule-based classification
  factory ClassificationResult.fromRule({
    required String category,
    required double confidence,
    required Map<String, double> candidateScores,
    required int processingTimeMs,
  }) {
    return ClassificationResult(
      category: category,
      confidence: confidence,
      method: ClassificationMethod.ruleBased,
      candidateScores: candidateScores,
      processingTimeMs: processingTimeMs,
    );
  }

  /// Check if classification is reliable
  bool get isReliable => confidence > 0.7;

  /// Get confidence level description
  String get confidenceLevel {
    if (confidence > 0.9) return 'Very High';
    if (confidence > 0.7) return 'High';
    if (confidence > 0.5) return 'Medium';
    if (confidence > 0.3) return 'Low';
    return 'Very Low';
  }

  /// Get formatted output
  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('Category: $category');
    buffer.writeln('Confidence: ${(confidence * 100).toStringAsFixed(1)}% ($confidenceLevel)');
    buffer.writeln('Method: ${method.name}');
    buffer.writeln('\nProcessing time: ${processingTimeMs}ms');
    
    return buffer.toString();
  }

  @override
  String toString() {
    return 'ClassificationResult(category: $category, confidence: ${(confidence * 100).toStringAsFixed(1)}%, method: ${method.name})';
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'confidence': confidence,
      'method': method.name,
      'candidateScores': candidateScores,
      'processingTimeMs': processingTimeMs,
    };
  }
}

/// Classification methods
enum ClassificationMethod {
  /// Rule-based keyword matching with enhanced combined rules
  ruleBased,
}

/// Confidence threshold configuration
class ConfidenceThresholds {
  /// Threshold for automatic acceptance
  final double autoAccept;
  
  /// Minimum threshold for valid classification
  final double minimum;

  const ConfidenceThresholds({
    this.autoAccept = 0.8,
    this.minimum = 0.3,
  });

  /// Default thresholds
  static const defaultThresholds = ConfidenceThresholds();

  /// Strict thresholds
  static const strict = ConfidenceThresholds(
    autoAccept: 0.9,
    minimum: 0.5,
  );

  /// Lenient thresholds
  static const lenient = ConfidenceThresholds(
    autoAccept: 0.6,
    minimum: 0.2,
  );
}
