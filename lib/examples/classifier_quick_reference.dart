# Category Classifier - Quick Reference

## Installation

```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
```

## Quick Start

```dart
import 'package:finsight/services/category_classifier.dart';

// Create classifier (mock for testing)
final classifier = ClassifierFactory.createMockHybridClassifier();

// Classify
final result = await classifier.classify(
  merchantName: 'Starbucks',
  description: 'Coffee',
  amount: 5.50,
);

print('${result.category}: ${(result.confidence * 100).toFixed(1)}%');
```

## Three Classification Methods

### 1. Rule-Based (Fast)
```dart
final result = await classifier.classifyWithRules(
  merchantName: 'Starbucks',
);
// ~1-5ms, no API calls, good for clear merchants
```

### 2. LLM (Intelligent)
```dart
final result = await classifier.classifyWithLLM(
  merchantName: 'Corner Store',
  description: 'Coffee and snacks',
  amount: 12.50,
);
// ~500ms+, requires API, best accuracy
```

### 3. Hybrid (Recommended)
```dart
final result = await classifier.classifyHybrid(
  merchantName: 'ABC Store',
  description: 'Various items',
  amount: 45.00,
);
// Adaptive: fast for clear cases, LLM for ambiguous
```

## Factory Methods

```dart
// Rule-based only (no LLM)
final classifier1 = ClassifierFactory.createRuleBasedClassifier();

// Mock LLM (testing without API key)
final classifier2 = ClassifierFactory.createMockHybridClassifier();

// Real LLM (production)
final classifier3 = ClassifierFactory.createLlmClassifier(
  apiKey: 'your-airllm-key',
);

// Hybrid with real LLM
final classifier4 = ClassifierFactory.createHybridClassifier(
  apiKey: 'your-airllm-key',
);
```

## Classification Result

```dart
final result = await classifier.classify(merchantName: 'Starbucks');

// Properties
result.category              // "Food & Dining"
result.confidence            // 0.95
result.method                // ClassificationMethod.hybrid
result.processingTimeMs      // 5

// Hybrid-specific
result.rulePrediction        // "Food & Dining"
result.ruleConfidence        // 0.95
result.llmPrediction         // "Food & Dining"
result.llmConfidence         // 0.93
result.reasoning             // "Merchant is a coffee shop"
result.hasConsensus          // true (both agree)

// Helpers
result.isReliable            // true if confidence > 0.7
result.confidenceLevel       // "Very High", "High", etc.
result.summary               // Formatted output
```

## Batch Processing

```dart
final expenses = [
  {'merchantName': 'Starbucks', 'description': 'Coffee', 'amount': 5.50},
  {'merchantName': 'Uber', 'description': 'Ride', 'amount': 15.00},
];

final results = await classifier.classifyBatch(
  expenses: expenses,
  method: ClassificationMethod.hybrid,
);
```

## Custom Thresholds

```dart
final classifier = CategoryClassifier(
  llmService: LlmService(apiKey: 'key'),
  thresholds: ConfidenceThresholds(
    autoAccept: 0.85,    // High confidence → skip LLM
    llmFallback: 0.55,   // Low confidence → use LLM
    minimum: 0.35,       // Minimum valid
  ),
);

// Presets
ConfidenceThresholds.defaultThresholds  // 0.8, 0.5, 0.3
ConfidenceThresholds.strict             // 0.9, 0.7, 0.5
ConfidenceThresholds.lenient            // 0.6, 0.4, 0.2
```

## Method Selection

```dart
// Explicit method
final result = await classifier.classify(
  merchantName: 'Store',
  method: ClassificationMethod.ruleBased,  // or .llm, .hybrid
);

// Or use specific methods
await classifier.classifyWithRules(merchantName: 'Store');
await classifier.classifyWithLLM(merchantName: 'Store');
await classifier.classifyHybrid(merchantName: 'Store');
```

## Categories (17)

```dart
ExpenseCategories.food           // Food & Dining
ExpenseCategories.groceries      // Groceries
ExpenseCategories.transportation // Transportation
ExpenseCategories.shopping       // Shopping
ExpenseCategories.entertainment  // Entertainment
ExpenseCategories.utilities      // Utilities
ExpenseCategories.healthcare     // Healthcare
ExpenseCategories.education      // Education
ExpenseCategories.travel         // Travel
ExpenseCategories.fitness        // Fitness
ExpenseCategories.personal       // Personal Care
ExpenseCategories.home           // Home & Garden
ExpenseCategories.business       // Business
ExpenseCategories.insurance      // Insurance
ExpenseCategories.gifts          // Gifts & Donations
ExpenseCategories.subscriptions  // Subscriptions
ExpenseCategories.other          // Other

ExpenseCategories.all            // List of all
```

## Error Handling

```dart
try {
  final result = await classifier.classifyWithLLM(
    merchantName: 'Store',
  );
} on StateError catch (e) {
  // LLM service not configured
  print('No LLM service available');
} on LlmException catch (e) {
  // API error
  print('LLM error: ${e.message}');
}
```

## Performance Tips

```dart
// 1. Use rules for bulk processing
final results = await classifier.classifyBatch(
  expenses: largeList,
  method: ClassificationMethod.ruleBased,  // Fast!
);

// 2. Increase auto-accept (fewer LLM calls)
final classifier = CategoryClassifier(
  thresholds: ConfidenceThresholds(autoAccept: 0.9),
);

// 3. Cache results
final cache = <String, String>{};
if (cache.containsKey(merchant)) {
  return cache[merchant]!;
}
```

## Best Practices

```dart
// 1. Check confidence before auto-accepting
if (result.isReliable) {
  saveExpense(category: result.category);
} else {
  showManualPicker(suggested: result.category);
}

// 2. Use hybrid by default
final result = await classifier.classifyHybrid(...);

// 3. Provide context for better accuracy
final result = await classifier.classify(
  merchantName: 'Store',
  description: 'Coffee and bagel',  // Context helps!
  amount: 12.50,
);

// 4. Handle consensus
if (result.method == ClassificationMethod.hybrid) {
  if (!result.hasConsensus) {
    // Rule and LLM disagree - may need review
    print('Disagreement: ${result.rulePrediction} vs ${result.llmPrediction}');
  }
}
```

## Integration Example

```dart
// Parse receipt → Classify → Save
final parser = ReceiptParser();
final classifier = ClassifierFactory.createHybridClassifier(
  apiKey: 'your-key',
);

// 1. Parse
final receipt = await parser.parse(ocrText);

// 2. Classify
final classification = await classifier.classifyHybrid(
  merchantName: receipt.merchantName ?? 'Unknown',
  description: receipt.items?.map((i) => i.description).join(', '),
  amount: receipt.totalAmount,
);

// 3. Save
if (classification.isReliable) {
  await saveExpense(
    merchant: receipt.merchantName,
    amount: receipt.totalAmount,
    category: classification.category,
    confidence: classification.confidence,
  );
}
```

## Common Patterns

```dart
// Pattern 1: Quick classification
final category = (await classifier.classify(
  merchantName: 'Starbucks',
)).category;

// Pattern 2: With validation
final result = await classifier.classify(merchantName: 'Store');
final category = result.isReliable 
    ? result.category 
    : await askUser(suggested: result.category);

// Pattern 3: Method selection by confidence
String selectMethod(String merchantName) {
  if (isWellKnown(merchantName)) {
    return ClassificationMethod.ruleBased;
  } else if (isAmbiguous(merchantName)) {
    return ClassificationMethod.llm;
  } else {
    return ClassificationMethod.hybrid;
  }
}

// Pattern 4: Fallback chain
ClassificationResult result;
try {
  result = await classifier.classifyWithLLM(merchantName: 'Store');
} catch (e) {
  result = await classifier.classifyWithRules(merchantName: 'Store');
}
```

## Testing

```dart
// Use mock for testing
void main() {
  test('classify coffee shop', () async {
    final classifier = ClassifierFactory.createMockHybridClassifier();
    
    final result = await classifier.classify(
      merchantName: 'Starbucks',
    );
    
    expect(result.category, ExpenseCategories.food);
    expect(result.confidence, greaterThan(0.8));
  });
}
```

## Running Examples

```bash
dart lib/examples/classifier_examples.dart
```

Includes 10 comprehensive examples covering all features.

---

For full documentation, see [CLASSIFIER_MODULE.md](CLASSIFIER_MODULE.md)
