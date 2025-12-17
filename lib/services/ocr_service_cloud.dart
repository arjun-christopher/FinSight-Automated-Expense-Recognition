import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;
import '../core/models/ocr_result.dart';
import 'base_ocr_service.dart';

/// Cloud-only OCR service using OCR.space API
/// NO ML KIT - Pure cloud processing
class OcrServiceCloud extends BaseOcrService {
  
  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    debugPrint('\n' + '☁️'*35);
    debugPrint('☁️ CLOUD OCR: Starting (NO ML Kit)');
    debugPrint('☁️'*35);
    
    final sw = Stopwatch()..start();
    
    try {
      // Step 1: Validate and prepare image
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return OcrResult.failure(errorMessage: 'Image file not found');
      }
      
      // Step 2: Compress image for upload (OCR.space free tier = 1MB max)
      debugPrint('📦 Compressing image for upload...');
      final compressedBytes = await _compressImage(imagePath);
      
      if (compressedBytes == null || compressedBytes.isEmpty) {
        return OcrResult.failure(errorMessage: 'Failed to compress image');
      }
      
      final compressedKB = compressedBytes.length / 1024;
      debugPrint('✅ Compressed to ${compressedKB.toStringAsFixed(1)} KB');
      
      // Step 3: Upload to OCR.space API
      debugPrint('📤 Uploading to OCR.space...');
      final base64Image = base64Encode(compressedBytes);
      
      final response = await http.post(
        Uri.parse('https://api.ocr.space/parse/image'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'apikey': 'helloworld', // Free tier key
          'base64Image': 'data:image/jpeg;base64,$base64Image',
          'language': 'eng',
          'isOverlayRequired': 'false',
          'detectOrientation': 'true',
          'scale': 'true',
          'OCREngine': '2',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏱️ Upload timeout');
          throw TimeoutException('Cloud OCR timeout');
        },
      );
      
      sw.stop();
      
      // Step 4: Parse response
      if (response.statusCode != 200) {
        debugPrint('❌ HTTP ${response.statusCode}');
        return OcrResult.failure(
          errorMessage: 'Cloud OCR server error (${response.statusCode})',
        );
      }
      
      final json = jsonDecode(response.body);
      debugPrint('📥 Response received (${sw.elapsedMilliseconds}ms)');
      
      // Check for errors
      if (json['IsErroredOnProcessing'] == true) {
        final error = json['ErrorMessage']?[0] ?? 'Unknown error';
        debugPrint('❌ OCR error: $error');
        return OcrResult.failure(errorMessage: 'Cloud OCR: $error');
      }
      
      // Extract text
      final parsedResults = json['ParsedResults'] as List?;
      if (parsedResults == null || parsedResults.isEmpty) {
        debugPrint('❌ No parsed results');
        return OcrResult.failure(errorMessage: 'No text found in image');
      }
      
      final text = parsedResults[0]['ParsedText'] as String? ?? '';
      
      if (text.trim().isEmpty) {
        debugPrint('❌ Empty text result');
        return OcrResult.failure(
          errorMessage: 'Could not extract text from receipt',
        );
      }
      
      // Clean up text (remove excessive line breaks)
      final cleanedText = text.replaceAll(RegExp(r'\r\n|\r'), '\n').trim();
      
      debugPrint('✅ Extracted ${cleanedText.length} characters');
      debugPrint('📝 Preview: ${cleanedText.substring(0, cleanedText.length > 100 ? 100 : cleanedText.length)}...');
      
      return OcrResult.success(
        rawText: cleanedText,
        textBlocks: [],
        confidence: 0.85, // Cloud API doesn't provide per-word confidence
      );
      
    } on TimeoutException catch (e) {
      sw.stop();
      debugPrint('⏱️ Timeout after ${sw.elapsedMilliseconds}ms: $e');
      return OcrResult.failure(
        errorMessage: 'OCR service timed out. Please check your internet connection.',
      );
    } catch (e) {
      sw.stop();
      debugPrint('❌ Exception after ${sw.elapsedMilliseconds}ms: $e');
      return OcrResult.failure(
        errorMessage: 'OCR failed: ${e.toString()}',
      );
    }
  }
  
  /// Compress image to under 1MB for OCR.space API
  Future<List<int>?> _compressImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final originalBytes = await file.readAsBytes();
      final originalKB = originalBytes.length / 1024;
      
      debugPrint('   Original: ${originalKB.toStringAsFixed(1)} KB');
      
      // If already small enough, use original
      if (originalBytes.length < 900 * 1024) {
        return originalBytes;
      }
      
      // Decode and resize
      final image = img.decodeImage(originalBytes);
      if (image == null) {
        debugPrint('   ❌ Could not decode image');
        return null;
      }
      
      debugPrint('   Size: ${image.width}x${image.height}');
      
      // Resize to max 1200px (smaller = faster processing)
      img.Image resized = image;
      if (image.width > 1200 || image.height > 1200) {
        final scale = 1200 / (image.width > image.height ? image.width : image.height);
        resized = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
        );
        debugPrint('   Resized: ${resized.width}x${resized.height}');
      }
      
      // Encode as JPEG with quality adjustment
      var quality = 85;
      List<int> encoded = img.encodeJpg(resized, quality: quality);
      
      // Reduce quality if still too large
      while (encoded.length > 900 * 1024 && quality > 50) {
        quality -= 10;
        encoded = img.encodeJpg(resized, quality: quality);
        debugPrint('   Reduced quality to $quality');
      }
      
      return encoded;
      
    } catch (e) {
      debugPrint('   ❌ Compression error: $e');
      return null;
    }
  }
}
