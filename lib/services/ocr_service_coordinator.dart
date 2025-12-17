import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/ocr_result.dart';
import 'base_ocr_service.dart';
import 'ocr_service_isolate.dart';
import 'ocr_service_fallback.dart';

/// Coordinator that tries multiple OCR strategies in order
/// Strategy 1: Isolate-based ML Kit (can be killed if hangs)
/// Strategy 2: Cloud API fallback
/// Strategy 3: Manual entry
class OcrServiceCoordinator extends BaseOcrService {
  final OcrServiceIsolate _isolateService = OcrServiceIsolate();
  final OcrServiceFallback _fallbackService = OcrServiceFallback();
  
  int _isolateFailureCount = 0;
  
  /// Process image with multiple fallback strategies
  Future<OcrResult> recognizeText(String imagePath) async {
    debugPrint('\n' + '='*70);
    debugPrint('🎯 OCR COORDINATOR: Starting multi-strategy OCR');
    debugPrint('='*70);
    
    final overallStopwatch = Stopwatch()..start();
    
    // Strategy 1: Isolate-based ML Kit (can force kill if hangs)
    debugPrint('\n📍 STRATEGY 1: Isolate-based ML Kit OCR');
    try {
      final result = await _isolateService.recognizeText(imagePath);
      
      if (result.success) {
        overallStopwatch.stop();
        debugPrint('✅ SUCCESS with Strategy 1 (${overallStopwatch.elapsedMilliseconds}ms)');
        _isolateFailureCount = 0; // Reset failure count
        return result;
      } else {
        debugPrint('⚠️ Strategy 1 failed: ${result.errorMessage}');
        _isolateFailureCount++;
      }
    } catch (e) {
      debugPrint('❌ Strategy 1 exception: $e');
      _isolateFailureCount++;
    }
    
    // If isolate has failed multiple times, skip to cloud
    if (_isolateFailureCount >= 2) {
      debugPrint('⚠️ Isolate has failed $_isolateFailureCount times, skipping to cloud');
    } else {
      // Give it one more chance
      debugPrint('\n🔄 Retrying Strategy 1 (attempt 2)');
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final result = await _isolateService.recognizeText(imagePath);
        
        if (result.success) {
          overallStopwatch.stop();
          debugPrint('✅ SUCCESS with Strategy 1 retry (${overallStopwatch.elapsedMilliseconds}ms)');
          _isolateFailureCount = 0;
          return result;
        }
      } catch (e) {
        debugPrint('❌ Strategy 1 retry failed: $e');
      }
    }
    
    // Strategy 2: Cloud API fallback (requires internet)
    debugPrint('\n📍 STRATEGY 2: Cloud OCR API');
    try {
      final result = await _fallbackService.recognizeTextViaApi(imagePath);
      
      if (result.success) {
        overallStopwatch.stop();
        debugPrint('✅ SUCCESS with Strategy 2 (${overallStopwatch.elapsedMilliseconds}ms)');
        return result;
      } else {
        debugPrint('⚠️ Strategy 2 failed: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Strategy 2 exception: $e');
    }
    
    // Strategy 3: Manual entry fallback
    debugPrint('\n📍 STRATEGY 3: Manual entry fallback');
    overallStopwatch.stop();
    debugPrint('⚠️ All OCR strategies failed after ${overallStopwatch.elapsedMilliseconds}ms');
    
    return OcrResult.failure(
      errorMessage: 'OCR is currently unavailable. Please enter receipt details manually or try again later.',
    );
  }
}
