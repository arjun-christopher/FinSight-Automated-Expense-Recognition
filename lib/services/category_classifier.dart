import 'package:flutter/foundation.dart';
import '../core/constants/expense_constants.dart';
import '../core/models/classification_result.dart';

/// Rule-based category classifier with enhanced pattern matching
class CategoryClassifier {
  final ConfidenceThresholds thresholds;
  
  // Cache for classification results (merchant name -> result)
  final Map<String, ClassificationResult> _cache = {};

  CategoryClassifier({
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

  /// Enhanced classify with combined rules (merchant + description + amount patterns)
  Future<ClassificationResult> classifyEnhanced({
    required String merchantName,
    String? description,
    double? amount,
  }) async {
    // Check cache first
    final cacheKey = _normalizeText(merchantName);
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final stopwatch = Stopwatch()..start();
    final text = _normalizeText('$merchantName ${description ?? ''}');
    final scores = <String, double>{};

    // Rule 1: Keyword matching
    for (final category in ExpenseCategories.all) {
      scores[category] = _calculateCategoryScore(text, category);
    }

    // Rule 2: Amount-based patterns (combined rule)
    if (amount != null) {
      _applyAmountRules(scores, amount);
    }

    // Rule 3: Description context patterns (combined rule)
    if (description != null && description.isNotEmpty) {
      _applyDescriptionRules(scores, description, merchantName);
    }

    // Find best match
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bestCategory = sortedEntries.first.key;
    final bestScore = sortedEntries.first.value;

    stopwatch.stop();

    final result = ClassificationResult.fromRule(
      category: bestCategory,
      confidence: bestScore,
      candidateScores: scores,
      processingTimeMs: stopwatch.elapsedMilliseconds,
    );

    _cache[cacheKey] = result;
    return result;
  }

  /// Combined Rule: Amount-based classification patterns
  void _applyAmountRules(Map<String, double> scores, double amount) {
    if (amount < 10) {
      // Small amounts likely food/snacks
      scores[ExpenseCategories.food] = (scores[ExpenseCategories.food] ?? 0) + 0.15;
    } else if (amount >= 10 && amount < 50) {
      // Medium amounts likely food/groceries/gas
      scores[ExpenseCategories.food] = (scores[ExpenseCategories.food] ?? 0) + 0.10;
      scores[ExpenseCategories.groceries] = (scores[ExpenseCategories.groceries] ?? 0) + 0.10;
      scores[ExpenseCategories.transportation] = (scores[ExpenseCategories.transportation] ?? 0) + 0.08;
    } else if (amount >= 50 && amount < 150) {
      // Higher amounts likely groceries/utilities/shopping
      scores[ExpenseCategories.groceries] = (scores[ExpenseCategories.groceries] ?? 0) + 0.12;
      scores[ExpenseCategories.shopping] = (scores[ExpenseCategories.shopping] ?? 0) + 0.10;
      scores[ExpenseCategories.utilities] = (scores[ExpenseCategories.utilities] ?? 0) + 0.08;
    } else if (amount >= 150 && amount < 500) {
      // Large amounts likely shopping/travel/healthcare
      scores[ExpenseCategories.shopping] = (scores[ExpenseCategories.shopping] ?? 0) + 0.15;
      scores[ExpenseCategories.travel] = (scores[ExpenseCategories.travel] ?? 0) + 0.12;
      scores[ExpenseCategories.healthcare] = (scores[ExpenseCategories.healthcare] ?? 0) + 0.10;
    } else {
      // Very large amounts likely travel/insurance/rent
      scores[ExpenseCategories.travel] = (scores[ExpenseCategories.travel] ?? 0) + 0.18;
      scores[ExpenseCategories.insurance] = (scores[ExpenseCategories.insurance] ?? 0) + 0.15;
      scores[ExpenseCategories.home] = (scores[ExpenseCategories.home] ?? 0) + 0.12;
    }
  }

  /// Combined Rule: Merchant + Description context patterns
  void _applyDescriptionRules(Map<String, double> scores, String description, String merchantName) {
    final combined = _normalizeText('$merchantName $description');
    
    // Pattern 1: Time-based patterns
    if (combined.contains('breakfast') || combined.contains('morning') || combined.contains('coffee')) {
      scores[ExpenseCategories.food] = (scores[ExpenseCategories.food] ?? 0) + 0.20;
    }
    if (combined.contains('lunch') || combined.contains('noon')) {
      scores[ExpenseCategories.food] = (scores[ExpenseCategories.food] ?? 0) + 0.18;
    }
    if (combined.contains('dinner') || combined.contains('evening')) {
      scores[ExpenseCategories.food] = (scores[ExpenseCategories.food] ?? 0) + 0.18;
    }

    // Pattern 2: Location-based patterns
    if (combined.contains('airport') || combined.contains('flight') || combined.contains('hotel')) {
      scores[ExpenseCategories.travel] = (scores[ExpenseCategories.travel] ?? 0) + 0.25;
    }
    if (combined.contains('store') || combined.contains('mall') || combined.contains('online')) {
      scores[ExpenseCategories.shopping] = (scores[ExpenseCategories.shopping] ?? 0) + 0.20;
    }

    // Pattern 3: Action-based patterns
    if (combined.contains('fill up') || combined.contains('refuel') || combined.contains('gas')) {
      scores[ExpenseCategories.transportation] = (scores[ExpenseCategories.transportation] ?? 0) + 0.25;
    }
    if (combined.contains('prescription') || combined.contains('doctor') || combined.contains('medical')) {
      scores[ExpenseCategories.healthcare] = (scores[ExpenseCategories.healthcare] ?? 0) + 0.25;
    }
    if (combined.contains('monthly') || combined.contains('subscription') || combined.contains('renewal')) {
      scores[ExpenseCategories.subscriptions] = (scores[ExpenseCategories.subscriptions] ?? 0) + 0.25;
    }

    // Normalize scores to [0, 1]
    for (final key in scores.keys) {
      scores[key] = (scores[key]!).clamp(0.0, 1.0);
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
  }) async {
    final results = <ClassificationResult>[];

    for (final expense in expenses) {
      final result = await classify(
        merchantName: expense['merchantName'] as String,
        description: expense['description'] as String?,
        amount: expense['amount'] as double?,
      );
      results.add(result);
    }

    return results;
  }

  /// Main classification method - uses enhanced rule-based classification
  Future<ClassificationResult> classify({
    required String merchantName,
    String? description,
    double? amount,
  }) async {
    // Use enhanced classification with combined rules
    return classifyEnhanced(
      merchantName: merchantName,
      description: description,
      amount: amount,
    );
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

}
