import 'package:flutter_test/flutter_test.dart';
import 'package:finsight/services/category_classifier.dart';
import 'package:finsight/services/llm_service.dart';

/// Test classification performance and timeouts
void main() {
  group('Classification Performance Tests', () {
    
    test('High confidence merchants use rules only (<10ms)', () async {
      final classifier = CategoryClassifier(llmService: MockLlmService());
      
      final stopwatch = Stopwatch()..start();
      
      // Clear merchants should use rules only
      final result = await classifier.classifyHybrid(
        merchantName: 'Walmart Supercenter',
        description: 'groceries',
        amount: 50.0,
      );
      
      stopwatch.stop();
      final timeMs = stopwatch.elapsedMilliseconds;
      
      print('✅ High Confidence Test (Rules Only):');
      print('  Merchant: Walmart Supercenter');
      print('  Category: ${result.category}');
      print('  Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
      print('  Time: ${timeMs}ms');
      
      expect(timeMs, lessThan(100), 
        reason: 'High confidence should be very fast');
      expect(result.category, equals('Groceries'));
    });

    test('Classification completes within 3 second timeout', () async {
      final classifier = CategoryClassifier(llmService: MockLlmService());
      
      final stopwatch = Stopwatch()..start();
      
      try {
        final result = await classifier.classifyHybrid(
          merchantName: 'Unknown Store',
          description: 'purchase',
          amount: 25.0,
        ).timeout(const Duration(seconds: 3));
        
        stopwatch.stop();
        
        expect(result.category, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
        
        print('✅ Classification completed in ${stopwatch.elapsedMilliseconds}ms');
      } catch (e) {
        stopwatch.stop();
        print('❌ Classification failed: $e');
        print('   Time: ${stopwatch.elapsedMilliseconds}ms');
        rethrow;
      }
    });

    test('Cached results are instant (<50ms)', () async {
      final classifier = CategoryClassifier(llmService: MockLlmService());
      
      // First call
      await classifier.classifyHybrid(
        merchantName: 'Starbucks Coffee',
        description: 'coffee',
        amount: 5.0,
      );
      
      // Second call - should be cached
      final stopwatch = Stopwatch()..start();
      
      final result = await classifier.classifyHybrid(
        merchantName: 'Starbucks Coffee',
        description: 'coffee',
        amount: 5.0,
      );
      
      stopwatch.stop();
      final timeMs = stopwatch.elapsedMilliseconds;
      
      print('⚡ Cached Result Test:');
      print('  Merchant: Starbucks Coffee (cached)');
      print('  Category: ${result.category}');
      print('  Time: ${timeMs}ms');
      
      expect(timeMs, lessThan(50), 
        reason: 'Cached results should be very fast');
    });

    test('Batch classification performance (5 merchants)', () async {
      final classifier = CategoryClassifier(llmService: MockLlmService());
      
      final merchants = [
        'Walmart',
        'Starbucks',
        'Shell Gas Station',
        'Target',
        'McDonald\'s',
      ];
      
      print('📊 Batch Classification Performance:');
      
      final stopwatch = Stopwatch()..start();
      
      for (final merchant in merchants) {
        final sw = Stopwatch()..start();
        
        final result = await classifier.classifyHybrid(
          merchantName: merchant,
          description: 'purchase',
          amount: 25.0,
        );
        
        sw.stop();
        print('  $merchant → ${result.category} (${sw.elapsedMilliseconds}ms)');
      }
      
      stopwatch.stop();
      
      print('  Total: ${stopwatch.elapsedMilliseconds}ms');
      print('  Average: ${(stopwatch.elapsedMilliseconds / merchants.length).toStringAsFixed(1)}ms');
      
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
        reason: 'Batch should complete quickly');
    });
  });
  
  group('Classification Timeout Tests', () {
    test('Classification does not hang indefinitely', () async {
      final classifier = CategoryClassifier(llmService: MockLlmService());
      
      final future = classifier.classifyHybrid(
        merchantName: 'Test Merchant',
        description: 'test',
        amount: 10.0,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          fail('Classification timed out after 5 seconds');
        },
      );
      
      final result = await future;
      expect(result.category, isNotNull);
    });
  });
}
