import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/ocr_result.dart';
import 'base_ocr_service.dart';

/// MINIMAL OCR - Just return dummy success immediately for testing
/// This proves the UI/workflow is working, then we can add real OCR
class OcrServiceMinimal extends BaseOcrService {
  
  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    debugPrint('\n' + '⚡'*35);
    debugPrint('⚡ MINIMAL OCR: Immediate dummy response');
    debugPrint('⚡'*35);
    
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));
    
    debugPrint('✅ Returning dummy receipt data');
    
    // Return fake but valid receipt text
    const dummyReceiptText = '''
WALMART SUPERCENTER
123 MAIN STREET
CITY, STATE 12345

GROCERIES          \$45.67
HOUSEHOLD ITEMS    \$23.45
TAX                \$6.91

TOTAL             \$75.03

THANK YOU FOR SHOPPING!
''';
    
    return OcrResult.success(
      rawText: dummyReceiptText,
      textBlocks: [],
      confidence: 0.95,
    );
  }
}
