import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/models/ocr_result.dart';

/// Fallback OCR service using cloud API
/// This is used if ML Kit fails repeatedly
class OcrServiceFallback {
  
  /// Use OCR.space free API as fallback
  /// Note: This requires internet connection
  Future<OcrResult> recognizeTextViaApi(String imagePath) async {
    debugPrint('\n☁️ CLOUD OCR: Using cloud API fallback');
    debugPrint('📁 Path: $imagePath');
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return OcrResult.failure(errorMessage: 'File not found');
      }
      
      // Check file size (OCR.space free tier max 1MB)
      final fileSize = await file.length();
      if (fileSize > 1024 * 1024) {
        return OcrResult.failure(
          errorMessage: 'Image too large for cloud OCR (max 1MB)',
        );
      }
      
      debugPrint('📤 Uploading image to cloud OCR...');
      
      // Read image bytes
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Call OCR.space API (free tier)
      final response = await http.post(
        Uri.parse('https://api.ocr.space/parse/image'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'apikey': 'helloworld', // Free tier API key
          'base64Image': 'data:image/jpeg;base64,$base64Image',
          'language': 'eng',
          'isOverlayRequired': 'false',
          'detectOrientation': 'true',
          'scale': 'true',
          'OCREngine': '2',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Cloud OCR timeout'),
      );
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['IsErroredOnProcessing'] == false) {
          final text = json['ParsedResults'][0]['ParsedText'] as String? ?? '';
          debugPrint('✅ Cloud OCR success (${stopwatch.elapsedMilliseconds}ms)');
          debugPrint('📝 Extracted ${text.length} characters');
          
          return OcrResult.success(
            rawText: text,
            textBlocks: [],
            confidence: 0.8, // Cloud API doesn't provide confidence
          );
        } else {
          final error = json['ErrorMessage'] ?? 'Unknown error';
          return OcrResult.failure(errorMessage: 'Cloud OCR error: $error');
        }
      } else {
        return OcrResult.failure(
          errorMessage: 'Cloud OCR HTTP error: ${response.statusCode}',
        );
      }
      
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Cloud OCR failed: $e');
      return OcrResult.failure(errorMessage: 'Cloud OCR exception: $e');
    }
  }
  
  /// Simple text extraction without cloud services
  /// Returns a very basic result indicating manual entry needed
  Future<OcrResult> manualEntryFallback() async {
    debugPrint('\n📝 MANUAL FALLBACK: All OCR methods failed');
    return OcrResult.failure(
      errorMessage: 'OCR unavailable. Please enter receipt details manually.',
    );
  }
}
