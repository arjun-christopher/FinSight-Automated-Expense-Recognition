#!/usr/bin/env python3
"""
Test script for expense classification performance
Tests the classification API and measures response time
"""

import subprocess
import json
import time
import sys
from pathlib import Path

def run_flutter_test(test_name):
    """Run a specific Flutter test"""
    print(f"\n{'='*60}")
    print(f"Running: {test_name}")
    print('='*60)
    
    try:
        result = subprocess.run(
            ['/tmp/flutter/bin/flutter', 'test', test_name, '--no-pub'],
            cwd='/workspaces/FinSight-Automated-Expense-Recognition',
            capture_output=True,
            text=True,
            timeout=60
        )
        
        print(result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr)
            
        return result.returncode == 0
    except subprocess.TimeoutExpired:
        print(f"❌ TEST TIMEOUT: {test_name} took longer than 60 seconds!")
        return False
    except Exception as e:
        print(f"❌ ERROR running test: {e}")
        return False

def test_classification_dart():
    """Test classification using Dart unit test"""
    print("\n" + "🔬 TESTING CLASSIFICATION PERFORMANCE".center(60))
    print("="*60)
    
    # Check if test exists
    test_file = Path('/workspaces/FinSight-Automated-Expense-Recognition/test/classification_performance_test.dart')
    if not test_file.exists():
        print(f"❌ Test file not found: {test_file}")
        return False
    
    print(f"\n📋 Test file: {test_file.name}")
    print(f"📏 File size: {test_file.stat().st_size} bytes")
    
    # Run the test
    success = run_flutter_test('test/classification_performance_test.dart')
    
    if success:
        print("\n✅ Classification tests PASSED")
    else:
        print("\n❌ Classification tests FAILED")
    
    return success

def test_classification_timeout():
    """Test classification timeout scenarios"""
    print("\n" + "⏱️  TESTING CLASSIFICATION TIMEOUTS".center(60))
    print("="*60)
    
    test_code = '''
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/category_classifier.dart';
import '../lib/services/llm_service.dart';

void main() {
  test('Classification completes within timeout', () async {
    final classifier = CategoryClassifier(llmService: MockLlmService());
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await classifier.classifyHybrid(
        merchantName: 'Walmart',
        description: 'groceries',
        amount: 50.0,
      ).timeout(Duration(seconds: 2));
      
      stopwatch.stop();
      
      expect(result.category, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      
      print('✅ Classification completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      stopwatch.stop();
      print('❌ Classification failed: $e');
      print('   Time: ${stopwatch.elapsedMilliseconds}ms');
      rethrow;
    }
  });
}
'''
    
    # Write temporary test file
    temp_test = Path('/workspaces/FinSight-Automated-Expense-Recognition/test/temp_timeout_test.dart')
    temp_test.write_text(test_code)
    
    try:
        success = run_flutter_test('test/temp_timeout_test.dart')
        temp_test.unlink()
        return success
    except Exception as e:
        print(f"Error: {e}")
        if temp_test.exists():
            temp_test.unlink()
        return False

def check_llm_service():
    """Check LLM service configuration"""
    print("\n" + "🔍 CHECKING LLM SERVICE CONFIGURATION".center(60))
    print("="*60)
    
    llm_file = Path('/workspaces/FinSight-Automated-Expense-Recognition/lib/services/llm_service.dart')
    
    if not llm_file.exists():
        print("❌ LLM service file not found!")
        return False
    
    content = llm_file.read_text()
    
    # Check for FastLlmService
    if 'class FastLlmService' in content:
        print("✅ FastLlmService class found")
    else:
        print("❌ FastLlmService class not found!")
        return False
    
    # Check for gpt-3.5-turbo
    if 'gpt-3.5-turbo' in content:
        print("✅ GPT-3.5-turbo model configured")
    else:
        print("⚠️  GPT-3.5-turbo not found in config")
    
    # Check timeout
    if 'timeout: 3' in content or 'timeout: Duration(seconds: 3)' in content:
        print("✅ 3-second timeout configured")
    else:
        print("⚠️  Timeout not set to 3 seconds")
    
    return True

def check_classifier_service():
    """Check classifier configuration"""
    print("\n" + "🔍 CHECKING CLASSIFIER CONFIGURATION".center(60))
    print("="*60)
    
    classifier_file = Path('/workspaces/FinSight-Automated-Expense-Recognition/lib/services/category_classifier.dart')
    
    if not classifier_file.exists():
        print("❌ Classifier file not found!")
        return False
    
    content = classifier_file.read_text()
    
    # Check for hybrid method
    if 'classifyHybrid' in content:
        print("✅ classifyHybrid method found")
    else:
        print("❌ classifyHybrid method not found!")
        return False
    
    # Check for cache
    if '_cache' in content or 'cache' in content.lower():
        print("✅ Caching implemented")
    else:
        print("⚠️  Caching not found")
    
    # Check for timeout
    if 'timeout' in content.lower():
        print("✅ Timeout protection found")
    else:
        print("⚠️  No timeout protection found")
    
    return True

def main():
    """Run all classification tests"""
    print("\n" + "🧪 CLASSIFICATION TEST SUITE".center(60))
    print("="*60)
    print("Testing classification performance and timeouts")
    print("="*60)
    
    results = {
        'llm_service_check': check_llm_service(),
        'classifier_check': check_classifier_service(),
        'dart_tests': test_classification_dart(),
        'timeout_tests': test_classification_timeout(),
    }
    
    # Summary
    print("\n" + "📊 TEST SUMMARY".center(60))
    print("="*60)
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    for test_name, success in results.items():
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print("="*60)
    print(f"Result: {passed}/{total} checks passed")
    
    if passed == total:
        print("\n🎉 All tests PASSED!")
        return 0
    else:
        print(f"\n⚠️  {total - passed} test(s) FAILED")
        return 1

if __name__ == '__main__':
    sys.exit(main())
