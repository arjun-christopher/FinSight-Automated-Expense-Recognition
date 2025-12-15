/// Model representing category classification result
class ClassificationResult {
  /// Predicted category
  final String category;

  /// Confidence score (0.0 - 1.0)
  final double confidence;

  /// Classification method used
  final ClassificationMethod method;

  /// Rule-based prediction (if available)
  final String? rulePrediction;

  /// Rule-based confidence (if available)
  final double? ruleConfidence;

  /// LLM prediction (if available)
  final String? llmPrediction;

  /// LLM confidence (if available)
  final double? llmConfidence;

  /// Reasoning from LLM (if available)
  final String? reasoning;

  /// All candidate categories with scores
  final Map<String, double> candidateScores;

  /// Processing time in milliseconds
  final int processingTimeMs;

  const ClassificationResult({
    required this.category,
    required this.confidence,
    required this.method,
    this.rulePrediction,
    this.ruleConfidence,
    this.llmPrediction,
    this.llmConfidence,
    this.reasoning,
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
      rulePrediction: category,
      ruleConfidence: confidence,
      candidateScores: candidateScores,
      processingTimeMs: processingTimeMs,
    );
  }

  /// Create result from LLM classification
  factory ClassificationResult.fromLLM({
    required String category,
    required double confidence,
    String? reasoning,
    required int processingTimeMs,
  }) {
    return ClassificationResult(
      category: category,
      confidence: confidence,
      method: ClassificationMethod.llm,
      llmPrediction: category,
      llmConfidence: confidence,
      reasoning: reasoning,
      processingTimeMs: processingTimeMs,
    );
  }

  /// Create result from hybrid classification
  factory ClassificationResult.hybrid({
    required String category,
    required double confidence,
    required String rulePrediction,
    required double ruleConfidence,
    required String llmPrediction,
    required double llmConfidence,
    String? reasoning,
    required Map<String, double> candidateScores,
    required int processingTimeMs,
  }) {
    return ClassificationResult(
      category: category,
      confidence: confidence,
      method: ClassificationMethod.hybrid,
      rulePrediction: rulePrediction,
      ruleConfidence: ruleConfidence,
      llmPrediction: llmPrediction,
      llmConfidence: llmConfidence,
      reasoning: reasoning,
      candidateScores: candidateScores,
      processingTimeMs: processingTimeMs,
    );
  }

  /// Check if classification is reliable
  bool get isReliable => confidence > 0.7;

  /// Check if rule and LLM agree (for hybrid)
  bool get hasConsensus {
    if (method != ClassificationMethod.hybrid) return true;
    return rulePrediction == llmPrediction;
  }

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
    
    if (method == ClassificationMethod.hybrid) {
      buffer.writeln('\nRule-based: $rulePrediction (${(ruleConfidence! * 100).toStringAsFixed(1)}%)');
      buffer.writeln('LLM: $llmPrediction (${(llmConfidence! * 100).toStringAsFixed(1)}%)');
      buffer.writeln('Consensus: ${hasConsensus ? "Yes ✓" : "No ✗"}');
    }
    
    if (reasoning != null) {
      buffer.writeln('\nReasoning: $reasoning');
    }
    
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
      'rulePrediction': rulePrediction,
      'ruleConfidence': ruleConfidence,
      'llmPrediction': llmPrediction,
      'llmConfidence': llmConfidence,
      'reasoning': reasoning,
      'candidateScores': candidateScores,
      'processingTimeMs': processingTimeMs,
    };
  }
}

/// Classification methods
enum ClassificationMethod {
  /// Rule-based keyword matching
  ruleBased,
  
  /// LLM-based classification
  llm,
  
  /// Hybrid (combination of both)
  hybrid,
}

/// Confidence threshold configuration
class ConfidenceThresholds {
  /// Threshold for automatic acceptance
  final double autoAccept;
  
  /// Threshold for LLM fallback in hybrid mode
  final double llmFallback;
  
  /// Minimum threshold for valid classification
  final double minimum;

  const ConfidenceThresholds({
    this.autoAccept = 0.8,
    this.llmFallback = 0.5,
    this.minimum = 0.3,
  });

  /// Default thresholds
  static const defaultThresholds = ConfidenceThresholds();

  /// Strict thresholds
  static const strict = ConfidenceThresholds(
    autoAccept: 0.9,
    llmFallback: 0.7,
    minimum: 0.5,
  );

  /// Lenient thresholds
  static const lenient = ConfidenceThresholds(
    autoAccept: 0.6,
    llmFallback: 0.4,
    minimum: 0.2,
  );
}
