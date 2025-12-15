import '../services/category_classifier.dart';
import '../core/models/classification_result.dart';

/// Comprehensive examples for the Category Classifier module

void main() async {
  print('='.padRight(80, '='));
  print('CATEGORY CLASSIFIER EXAMPLES');
  print('='.padRight(80, '='));
  print('');

  // Example 1: Rule-based classification
  await example1RuleBasedClassification();

  // Example 2: LLM classification (mock)
  await example2LlmClassification();

  // Example 3: Hybrid classification
  await example3HybridClassification();

  // Example 4: Batch classification
  await example4BatchClassification();

  // Example 5: Confidence thresholds
  await example5ConfidenceThresholds();

  // Example 6: Edge cases
  await example6EdgeCases();

  // Example 7: Real-world scenarios
  await example7RealWorldScenarios();

  // Example 8: Performance comparison
  await example8PerformanceComparison();

  // Example 9: Classification methods
  await example9ClassificationMethods();

  // Example 10: Custom configuration
  await example10CustomConfiguration();
}

/// Example 1: Rule-based classification (fast, no API)
Future<void> example1RuleBasedClassification() async {
  print('Example 1: Rule-based Classification');
  print('-' * 40);

  final classifier = ClassifierFactory.createRuleBasedClassifier();

  // Classify food expenses
  final result1 = await classifier.classifyWithRules(
    merchantName: 'Starbucks Coffee',
    description: 'Morning coffee and pastry',
  );
  print('Merchant: Starbucks Coffee');
  print(result1.summary);
  print('');

  // Classify transportation
  final result2 = await classifier.classifyWithRules(
    merchantName: 'Uber Trip',
    description: 'Ride to airport',
  );
  print('Merchant: Uber Trip');
  print(result2.summary);
  print('');

  // Classify groceries
  final result3 = await classifier.classifyWithRules(
    merchantName: 'Walmart Supercenter',
    description: 'Weekly grocery shopping',
  );
  print('Merchant: Walmart Supercenter');
  print(result3.summary);
  print('\n');
}

/// Example 2: LLM classification (intelligent, context-aware)
Future<void> example2LlmClassification() async {
  print('Example 2: LLM Classification (Mock)');
  print('-' * 40);

  final classifier = ClassifierFactory.createMockHybridClassifier();

  // Classify with context
  final result1 = await classifier.classifyWithLLM(
    merchantName: 'Corner Store',
    description: 'Coffee and snacks',
    amount: 12.50,
  );
  print('Merchant: Corner Store');
  print('Description: Coffee and snacks');
  print('Amount: \$12.50');
  print(result1.summary);
  print('');

  // Ambiguous merchant
  final result2 = await classifier.classifyWithLLM(
    merchantName: 'Target',
    description: 'Various items',
    amount: 85.30,
  );
  print('Merchant: Target');
  print('Description: Various items');
  print('Amount: \$85.30');
  print(result2.summary);
  print('\n');
}

/// Example 3: Hybrid classification (best of both)
Future<void> example3HybridClassification() async {
  print('Example 3: Hybrid Classification');
  print('-' * 40);

  final classifier = ClassifierFactory.createMockHybridClassifier();

  // Clear case - rules confident
  final result1 = await classifier.classifyHybrid(
    merchantName: 'McDonalds',
    description: 'Lunch meal',
    amount: 8.99,
  );
  print('Case 1: Clear match (McDonalds)');
  print(result1.summary);
  print('');

  // Ambiguous case - LLM helps
  final result2 = await classifier.classifyHybrid(
    merchantName: 'ABC Store',
    description: 'Purchase',
    amount: 45.00,
  );
  print('Case 2: Ambiguous match (ABC Store)');
  print(result2.summary);
  print('\n');
}

/// Example 4: Batch classification
Future<void> example4BatchClassification() async {
  print('Example 4: Batch Classification');
  print('-' * 40);

  final classifier = ClassifierFactory.createMockHybridClassifier();

  final expenses = [
    {
      'merchantName': 'Whole Foods',
      'description': 'Organic groceries',
      'amount': 67.40,
    },
    {
      'merchantName': 'Shell Gas Station',
      'description': 'Fuel',
      'amount': 45.00,
    },
    {
      'merchantName': 'Netflix',
      'description': 'Monthly subscription',
      'amount': 15.99,
    },
    {
      'merchantName': 'CVS Pharmacy',
      'description': 'Prescription',
      'amount': 25.00,
    },
  ];

  print('Classifying ${expenses.length} expenses...\n');

  final results = await classifier.classifyBatch(
    expenses: expenses,
    method: ClassificationMethod.hybrid,
  );

  for (int i = 0; i < results.length; i++) {
    print('${i + 1}. ${expenses[i]['merchantName']}');
    print('   Category: ${results[i].category}');
    print('   Confidence: ${(results[i].confidence * 100).toStringAsFixed(1)}%');
    print('   Time: ${results[i].processingTimeMs}ms');
    print('');
  }
  print('');
}

/// Example 5: Confidence thresholds
Future<void> example5ConfidenceThresholds() async {
  print('Example 5: Confidence Thresholds');
  print('-' * 40);

  // Default thresholds
  final defaultClassifier = CategoryClassifier(
    llmService: MockLlmService(),
    thresholds: ConfidenceThresholds.defaultThresholds,
  );

  // Strict thresholds
  final strictClassifier = CategoryClassifier(
    llmService: MockLlmService(),
    thresholds: ConfidenceThresholds.strict,
  );

  // Lenient thresholds
  final lenientClassifier = CategoryClassifier(
    llmService: MockLlmService(),
    thresholds: ConfidenceThresholds.lenient,
  );

  final testData = {
    'merchantName': 'Local Coffee Shop',
    'description': 'Coffee',
    'amount': 4.50,
  };

  print('Testing with: ${testData['merchantName']}\n');

  final result1 = await defaultClassifier.classifyHybrid(
    merchantName: testData['merchantName'] as String,
    description: testData['description'] as String,
    amount: testData['amount'] as double,
  );
  print('Default thresholds:');
  print('Auto-accept: ${ConfidenceThresholds.defaultThresholds.autoAccept}');
  print('Result: ${result1.category} (${(result1.confidence * 100).toStringAsFixed(1)}%)');
  print('');

  final result2 = await strictClassifier.classifyHybrid(
    merchantName: testData['merchantName'] as String,
    description: testData['description'] as String,
    amount: testData['amount'] as double,
  );
  print('Strict thresholds:');
  print('Auto-accept: ${ConfidenceThresholds.strict.autoAccept}');
  print('Result: ${result2.category} (${(result2.confidence * 100).toStringAsFixed(1)}%)');
  print('');

  final result3 = await lenientClassifier.classifyHybrid(
    merchantName: testData['merchantName'] as String,
    description: testData['description'] as String,
    amount: testData['amount'] as double,
  );
  print('Lenient thresholds:');
  print('Auto-accept: ${ConfidenceThresholds.lenient.autoAccept}');
  print('Result: ${result3.category} (${(result3.confidence * 100).toStringAsFixed(1)}%)');
  print('\n');
}

/// Example 6: Edge cases
Future<void> example6EdgeCases() async {
  print('Example 6: Edge Cases');
  print('-' * 40);

  final classifier = ClassifierFactory.createMockHybridClassifier();

  // Empty description
  final result1 = await classifier.classify(
    merchantName: 'Unknown Store',
    method: ClassificationMethod.hybrid,
  );
  print('Case 1: No description');
  print('Merchant: Unknown Store');
  print('Result: ${result1.category} (${(result1.confidence * 100).toStringAsFixed(1)}%)');
  print('');

  // Very generic merchant
  final result2 = await classifier.classify(
    merchantName: 'Store #123',
    description: 'Purchase',
    method: ClassificationMethod.hybrid,
  );
  print('Case 2: Generic merchant');
  print('Merchant: Store #123');
  print('Result: ${result2.category} (${(result2.confidence * 100).toStringAsFixed(1)}%)');
  print('');

  // Multiple possible categories
  final result3 = await classifier.classify(
    merchantName: 'Costco',
    description: 'Shopping',
    method: ClassificationMethod.hybrid,
  );
  print('Case 3: Multiple possible categories');
  print('Merchant: Costco (could be groceries or shopping)');
  print('Result: ${result3.category} (${(result3.confidence * 100).toStringAsFixed(1)}%)');
  print('\n');
}

/// Example 7: Real-world scenarios
Future<void> example7RealWorldScenarios() async {
  print('Example 7: Real-world Scenarios');
  print('-' * 40);

  final classifier = ClassifierFactory.createMockHybridClassifier();

  // Scenario 1: Business lunch
  final result1 = await classifier.classify(
    merchantName: 'The Capital Grille',
    description: 'Client lunch meeting',
    amount: 145.50,
    method: ClassificationMethod.hybrid,
  );
  print('Scenario 1: Business lunch');
  print('Could be Food or Business?');
  print('Result: ${result1.category}');
  print('Reasoning: ${result1.reasoning ?? "N/A"}');
  print('');

  // Scenario 2: Gas station with convenience store
  final result2 = await classifier.classify(
    merchantName: '7-Eleven',
    description: 'Snacks and drinks',
    amount: 12.30,
    method: ClassificationMethod.hybrid,
  );
  print('Scenario 2: Gas station convenience store');
  print('Could be Transportation or Food?');
  print('Result: ${result2.category}');
  print('Reasoning: ${result2.reasoning ?? "N/A"}');
  print('');

  // Scenario 3: Online marketplace
  final result3 = await classifier.classify(
    merchantName: 'Amazon',
    description: 'Books',
    amount: 45.00,
    method: ClassificationMethod.hybrid,
  );
  print('Scenario 3: Amazon books');
  print('Could be Shopping or Education?');
  print('Result: ${result3.category}');
  print('Reasoning: ${result3.reasoning ?? "N/A"}');
  print('\n');
}

/// Example 8: Performance comparison
Future<void> example8PerformanceComparison() async {
  print('Example 8: Performance Comparison');
  print('-' * 40);

  final classifier = ClassifierFactory.createMockHybridClassifier();

  final testData = {
    'merchantName': 'Starbucks',
    'description': 'Coffee',
    'amount': 5.50,
  };

  // Rule-based
  final result1 = await classifier.classify(
    merchantName: testData['merchantName'] as String,
    description: testData['description'] as String,
    amount: testData['amount'] as double,
    method: ClassificationMethod.ruleBased,
  );

  // LLM-based
  final result2 = await classifier.classify(
    merchantName: testData['merchantName'] as String,
    description: testData['description'] as String,
    amount: testData['amount'] as double,
    method: ClassificationMethod.llm,
  );

  // Hybrid
  final result3 = await classifier.classify(
    merchantName: testData['merchantName'] as String,
    description: testData['description'] as String,
    amount: testData['amount'] as double,
    method: ClassificationMethod.hybrid,
  );

  print('Merchant: ${testData['merchantName']}\n');
  print('Method              | Result           | Confidence | Time');
  print('-' * 65);
  print('Rule-based          | ${result1.category.padRight(16)} | ${(result1.confidence * 100).toStringAsFixed(1).padLeft(6)}%    | ${result1.processingTimeMs.toString().padLeft(4)}ms');
  print('LLM                 | ${result2.category.padRight(16)} | ${(result2.confidence * 100).toStringAsFixed(1).padLeft(6)}%    | ${result2.processingTimeMs.toString().padLeft(4)}ms');
  print('Hybrid              | ${result3.category.padRight(16)} | ${(result3.confidence * 100).toStringAsFixed(1).padLeft(6)}%    | ${result3.processingTimeMs.toString().padLeft(4)}ms');
  print('\n');
}

/// Example 9: Classification methods
Future<void> example9ClassificationMethods() async {
  print('Example 9: Classification Methods');
  print('-' * 40);

  final classifier = ClassifierFactory.createMockHybridClassifier();

  print('Testing different methods on ambiguous merchant:\n');

  // Test all three methods
  final merchants = ['Corner Cafe', 'City Parking', 'Online Store'];

  for (final merchant in merchants) {
    print('Merchant: $merchant');
    print('');

    final ruleResult = await classifier.classify(
      merchantName: merchant,
      method: ClassificationMethod.ruleBased,
    );
    print('  Rule-based: ${ruleResult.category} (${(ruleResult.confidence * 100).toStringAsFixed(1)}%)');

    final llmResult = await classifier.classify(
      merchantName: merchant,
      method: ClassificationMethod.llm,
    );
    print('  LLM:        ${llmResult.category} (${(llmResult.confidence * 100).toStringAsFixed(1)}%)');

    final hybridResult = await classifier.classify(
      merchantName: merchant,
      method: ClassificationMethod.hybrid,
    );
    print('  Hybrid:     ${hybridResult.category} (${(hybridResult.confidence * 100).toStringAsFixed(1)}%)');
    print('  Consensus:  ${hybridResult.hasConsensus ? "Yes ✓" : "No ✗"}');
    print('');
  }
  print('');
}

/// Example 10: Custom configuration
Future<void> example10CustomConfiguration() async {
  print('Example 10: Custom Configuration');
  print('-' * 40);

  // Custom thresholds
  final customThresholds = ConfidenceThresholds(
    autoAccept: 0.85,
    llmFallback: 0.55,
    minimum: 0.35,
  );

  final classifier = CategoryClassifier(
    llmService: MockLlmService(),
    thresholds: customThresholds,
  );

  print('Custom thresholds:');
  print('  Auto-accept: ${customThresholds.autoAccept}');
  print('  LLM fallback: ${customThresholds.llmFallback}');
  print('  Minimum: ${customThresholds.minimum}');
  print('');

  final result = await classifier.classifyHybrid(
    merchantName: 'Local Business',
    description: 'Service',
    amount: 50.00,
  );

  print('Result:');
  print('  Category: ${result.category}');
  print('  Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
  print('  Is reliable: ${result.isReliable}');
  print('  Level: ${result.confidenceLevel}');
  print('\n');
}

/// Run all examples
Future<void> runAllExamples() async {
  await main();
}
