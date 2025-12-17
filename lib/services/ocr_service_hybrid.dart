import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/ocr_result.dart';
import 'base_ocr_service.dart';
import 'ocr_service_simple.dart';
import 'ocr_service_fallback.dart';

/// Hybrid OCR: Try simple ML Kit once, then immediately fall back to cloud
class OcrServiceHybrid extends BaseOcrService {
  final OcrServiceSimple _mlKit = OcrServiceSimple();
  final OcrServiceFallback _cloud = OcrServiceFallback();
  
  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    debugPrint('\n' + '🚀'*35);
    debugPrint('🚀 HYBRID OCR: Multi-method approach');
    debugPrint('🚀'*35);
    
    final totalSw = Stopwatch()..start();
    
    // Method 1: ML Kit (4 second timeout)
    debugPrint('\n📍 Method 1: ML Kit (quick attempt)');
    try {
      final result = await _mlKit.recognizeText(imagePath).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏱️  ML Kit timed out at Dart level');
          return OcrResult.failure(errorMessage: 'ML Kit timeout');
        },
      );
      
      if (result.success && result.rawText.isNotEmpty) {
        totalSw.stop();
        debugPrint('✅ SUCCESS with ML Kit (${totalSw.elapsedMilliseconds}ms total)');
        return result;
      } else {
        debugPrint('⚠️  ML Kit failed: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ ML Kit exception: $e');
    }
    
    // Method 2: Cloud API
    debugPrint('\n📍 Method 2: Cloud OCR');
    try {
      final result = await _cloud.recognizeTextViaApi(imagePath);
      
      if (result.success) {
        totalSw.stop();
        debugPrint('✅ SUCCESS with Cloud API (${totalSw.elapsedMilliseconds}ms total)');
        return result;
      } else {
        debugPrint('⚠️  Cloud API failed: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Cloud API exception: $e');
    }
    
    // All methods failed
    totalSw.stop();
    debugPrint('\n❌ All OCR methods failed (${totalSw.elapsedMilliseconds}ms total)');
    return OcrResult.failure(
      errorMessage: 'Could not process receipt. Please try with a clearer photo or enter details manually.',
    );
  }
}
