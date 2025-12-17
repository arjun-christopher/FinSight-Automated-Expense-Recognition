import 'package:flutter/foundation.dart';
import '../core/constants/expense_constants.dart';
import '../core/models/classification_result.dart';
import 'llm_service.dart';

/// Hybrid category classifier combining rule-based and LLM approaches
class CategoryClassifier {
  final LlmService? llmService;
  final ConfidenceThresholds thresholds;
  
  // Cache for classification results (merchant name -> result)
  final Map<String, ClassificationResult> _cache = {};

  CategoryClassifier({
    this.llmService,
    this.thresholds = ConfidenceThresholds.defaultThresholds,
  });

  /// Classify using rule-based keyword matching only
  Future<ClassificationResult> classifyWithRules({
    required String merchantName,
    String? description,
  }) async {
    final stopwatch = Stopwatch()..start();

    final text = _normalizeText('$merchantName ${description ?? ''}');
    final scores = <String, double>{};

    // Calculate scores for each category
    for (final category in ExpenseCategories.all) {
      scores[category] = _calculateCategoryScore(text, category);
    }

    // Find best match
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bestCategory = sortedEntries.first.key;
    final bestScore = sortedEntries.first.value;

    stopwatch.stop();

    return ClassificationResult.fromRule(
      category: bestCategory,
      confidence: bestScore,
      candidateScores: scores,
      processingTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Classify using LLM only
  Future<ClassificationResult> classifyWithLLM({
    required String merchantName,
    String? description,
    double? amount,
  }) async {
    if (llmService == null) {
      throw StateError('LLM service not configured');
    }

    final stopwatch = Stopwatch()..start();

    final result = await llmService!.classifyCategory(
      merchantName: merchantName,
      description: description,
      amount: amount,
    );

    stopwatch.stop();

    return ClassificationResult.fromLLM(
      category: result['category'],
      confidence: result['confidence'],
      reasoning: result['reasoning'],
      processingTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Classify using hybrid approach (rules + LLM)
  /// SMART: Uses LLM only when rule-based confidence is low
  Future<ClassificationResult> classifyHybrid({
    required String merchantName,
    String? description,
    double? amount,
  }) async {
    // Check cache first for instant results
    final cacheKey = _normalizeText(merchantName);
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    
    // No LLM service? Use rule-based only
    if (llmService == null) {
      final result = await classifyWithRules(
        merchantName: merchantName,
        description: description,
      );
      _cache[cacheKey] = result;
      return result;
    }
    
    final stopwatch = Stopwatch()..start();
    
    // Step 1: Try rule-based first (fast, 1-5ms)
    final ruleResult = await classifyWithRules(
      merchantName: merchantName,
      description: description,
    );
    
    // Step 2: If confidence is high enough, skip LLM (saves 50-100ms)
    if (ruleResult.confidence >= thresholds.autoAccept) {
      stopwatch.stop();
      final result = ClassificationResult.fromRule(
        category: ruleResult.category,
        confidence: ruleResult.confidence,
        candidateScores: ruleResult.candidateScores,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
      _cache[cacheKey] = result;
      return result;
    }
    
    // Step 3: Low confidence - use fast LLM for better accuracy
    try {
      final llmResult = await llmService!.classifyCategory(
        merchantName: merchantName,
        description: description,
        amount: amount,
      ).timeout(
        const Duration(seconds: 2),  // 2 second timeout for LLM call
        onTimeout: () {
          // If LLM is slow, return rule result
          debugPrint('⏱️ LLM timeout, falling back to rules');
          return {
            'category': ruleResult.category,
            'confidence': ruleResult.confidence,
            'reasoning': 'Timeout - using rules',
          };
        },
      );
      
      stopwatch.stop();
      
      final result = ClassificationResult.hybrid(
        category: llmResult['category'] as String,
        confidence: (llmResult['confidence'] as num).toDouble(),
        rulePrediction: ruleResult.category,
        ruleConfidence: ruleResult.confidence,
        llmPrediction: llmResult['category'] as String,
        llmConfidence: (llmResult['confidence'] as num).toDouble(),
        reasoning: llmResult['reasoning'] as String? ?? 'Hybrid classification',
        candidateScores: ruleResult.candidateScores,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
      
      _cache[cacheKey] = result;
      return result;
    } catch (e) {
      // LLM failed - return rule result
      stopwatch.stop();
      final result = ClassificationResult.fromRule(
        category: ruleResult.category,
        confidence: ruleResult.confidence * 0.9,  // Slight penalty
        candidateScores: ruleResult.candidateScores,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
      _cache[cacheKey] = result;
      return result;
    }
  }

  /// Clear the classification cache
  void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'size': _cache.length,
    };
  }

  /// Batch classify multiple expenses
  Future<List<ClassificationResult>> classifyBatch({
    required List<Map<String, dynamic>> expenses,
    ClassificationMethod method = ClassificationMethod.hybrid,
  }) async {
    final results = <ClassificationResult>[];

    for (final expense in expenses) {
      final result = await classify(
        merchantName: expense['merchantName'] as String,
        description: expense['description'] as String?,
        amount: expense['amount'] as double?,
        method: method,
      );
      results.add(result);
    }

    return results;
  }

  /// Main classification method with method selection
  Future<ClassificationResult> classify({
    required String merchantName,
    String? description,
    double? amount,
    ClassificationMethod method = ClassificationMethod.hybrid,
  }) async {
    switch (method) {
      case ClassificationMethod.ruleBased:
        return classifyWithRules(
          merchantName: merchantName,
          description: description,
        );
      case ClassificationMethod.llm:
        return classifyWithLLM(
          merchantName: merchantName,
          description: description,
          amount: amount,
        );
      case ClassificationMethod.hybrid:
        return classifyHybrid(
          merchantName: merchantName,
          description: description,
          amount: amount,
        );
    }
  }

  /// Calculate category score based on keywords
  double _calculateCategoryScore(String text, String category) {
    final keywords = _getCategoryKeywords(category);
    double score = 0.0;
    int matchCount = 0;

    for (final keyword in keywords) {
      if (text.contains(keyword.toLowerCase())) {
        // Longer keywords get higher weight
        final weight = keyword.length / 10.0;
        score += weight;
        matchCount++;
      }
    }

    // Normalize score
    if (matchCount > 0) {
      score = (score / keywords.length).clamp(0.0, 1.0);
      // Boost score for multiple matches
      score *= (1 + (matchCount / keywords.length) * 0.2);
      score = score.clamp(0.0, 1.0);
    }

    return score;
  }

  /// Get keywords for category
  List<String> _getCategoryKeywords(String category) {
    switch (category) {
      case ExpenseCategories.food:
        return [
          'restaurant', 'cafe', 'coffee', 'starbucks', 'mcdonalds', 'burger',
          'pizza', 'sushi', 'diner', 'bistro', 'grill', 'kitchen', 'food',
          'eat', 'dining', 'lunch', 'dinner', 'breakfast', 'snack', 'meal'
        ];
      case ExpenseCategories.groceries:
        return [
          'grocery', 'supermarket', 'walmart', 'target', 'whole foods',
          'trader joes', 'safeway', 'kroger', 'market', 'foods', 'mart'
        ];
      case ExpenseCategories.transportation:
        return [
          'uber', 'lyft', 'taxi', 'gas', 'fuel', 'shell', 'chevron', 'bp',
          'exxon', 'parking', 'metro', 'bus', 'train', 'transit', 'toll'
        ];
      case ExpenseCategories.shopping:
        return [
          'amazon', 'ebay', 'shop', 'store', 'mall', 'boutique', 'retail',
          'clothing', 'apparel', 'fashion', 'electronics', 'best buy'
        ];
      case ExpenseCategories.entertainment:
        return [
          'netflix', 'spotify', 'hulu', 'disney', 'movie', 'theater',
          'cinema', 'concert', 'show', 'event', 'ticket', 'entertainment',
          'amc', 'regal', 'gaming', 'steam'
        ];
      case ExpenseCategories.utilities:
        return [
          'electric', 'gas', 'water', 'utility', 'power', 'energy',
          'pg&e', 'pge', 'sewage', 'trash', 'waste', 'internet', 'cable'
        ];
      case ExpenseCategories.healthcare:
        return [
          'hospital', 'clinic', 'doctor', 'pharmacy', 'cvs', 'walgreens',
          'medical', 'health', 'dental', 'dentist', 'vision', 'optometry'
        ];
      case ExpenseCategories.education:
        return [
          'school', 'university', 'college', 'tuition', 'education',
          'course', 'class', 'learning', 'academy', 'institute', 'books'
        ];
      case ExpenseCategories.travel:
        return [
          'hotel', 'airline', 'flight', 'airbnb', 'booking', 'travel',
          'vacation', 'resort', 'delta', 'united', 'southwest', 'expedia'
        ];
      case ExpenseCategories.fitness:
        return [
          'gym', 'fitness', 'workout', 'yoga', 'pilates', 'trainer',
          'athletic', 'sport', 'planet fitness', '24 hour', 'equinox'
        ];
      case ExpenseCategories.personal:
        return [
          'salon', 'spa', 'barber', 'beauty', 'cosmetic', 'massage',
          'manicure', 'pedicure', 'hair', 'skin', 'personal care'
        ];
      case ExpenseCategories.home:
        return [
          'home depot', 'lowes', 'ikea', 'furniture', 'hardware', 'garden',
          'home', 'house', 'repair', 'maintenance', 'renovation', 'decor'
        ];
      case ExpenseCategories.business:
        return [
          'office', 'business', 'supplies', 'staples', 'fedex', 'ups',
          'shipping', 'corporate', 'professional', 'service', 'consulting'
        ];
      case ExpenseCategories.insurance:
        return [
          'insurance', 'geico', 'state farm', 'allstate', 'progressive',
          'policy', 'premium', 'coverage', 'health insurance', 'auto insurance'
        ];
      case ExpenseCategories.gifts:
        return [
          'gift', 'donation', 'charity', 'nonprofit', 'foundation',
          'contribution', 'present', 'flowers', 'card'
        ];
      case ExpenseCategories.subscriptions:
        return [
          'subscription', 'monthly', 'annual', 'membership', 'plan',
          'service', 'recurring', 'adobe', 'microsoft', 'apple'
        ];
      default:
        return [];
    }
  }

  /// Normalize text for matching
  String _normalizeText(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
  }

  /// Select final category from rule and LLM predictions
  String _selectFinalCategory({
    required String ruleCategory,
    required double ruleConfidence,
    required String llmCategory,
    required double llmConfidence,
  }) {
    // If both agree, use the prediction
    if (ruleCategory == llmCategory) {
      return ruleCategory;
    }

    // If LLM has significantly higher confidence, use it
    if (llmConfidence > ruleConfidence + 0.2) {
      return llmCategory;
    }

    // If rule has significantly higher confidence, use it
    if (ruleConfidence > llmConfidence + 0.2) {
      return ruleCategory;
    }

    // For close calls, prefer LLM (more intelligent)
    return llmCategory;
  }

  /// Calculate hybrid confidence
  double _calculateHybridConfidence({
    required String ruleCategory,
    required double ruleConfidence,
    required String llmCategory,
    required double llmConfidence,
  }) {
    // If both agree, boost confidence
    if (ruleCategory == llmCategory) {
      return ((ruleConfidence + llmConfidence) / 2 * 1.2).clamp(0.0, 1.0);
    }

    // If they disagree, average with penalty
    return ((ruleConfidence + llmConfidence) / 2 * 0.8).clamp(0.0, 1.0);
  }
}

/// Factory for creating classifiers with different configurations
class ClassifierFactory {
  /// Create rule-based only classifier (fast, no API calls)
  static CategoryClassifier createRuleBasedClassifier() {
    return CategoryClassifier();
  }

  /// Create LLM-based classifier with real API
  static CategoryClassifier createLlmClassifier({
    required String apiKey,
    String? baseUrl,
    String? model,
  }) {
    return CategoryClassifier(
      llmService: LlmService(
        apiKey: apiKey,
        baseUrl: baseUrl ?? 'https://api.airllm.com/v1',
        model: model ?? 'gpt-4',
      ),
    );
  }

  /// Create hybrid classifier with mock LLM (for testing)
  static CategoryClassifier createMockHybridClassifier() {
    return CategoryClassifier(
      llmService: MockLlmService(),
    );
  }
  
  /// Create fast hybrid classifier with lightweight LLM
  static CategoryClassifier createFastHybridClassifier({
    required String apiKey,
    String? baseUrl,
  }) {
    return CategoryClassifier(
      llmService: FastLlmService(
        apiKey: apiKey,
        baseUrl: baseUrl,
      ),
    );
  }

  /// Create hybrid classifier with real API
  static CategoryClassifier createHybridClassifier({
    required String apiKey,
    String? baseUrl,
    String? model,
    ConfidenceThresholds? thresholds,
  }) {
    return CategoryClassifier(
      llmService: LlmService(
        apiKey: apiKey,
        baseUrl: baseUrl ?? 'https://api.airllm.com/v1',
        model: model ?? 'gpt-4',
      ),
      thresholds: thresholds ?? ConfidenceThresholds.defaultThresholds,
    );
  }
}
