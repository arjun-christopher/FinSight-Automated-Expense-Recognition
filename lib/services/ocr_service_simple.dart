import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import '../core/models/ocr_result.dart';
import 'base_ocr_service.dart';

/// SIMPLIFIED OCR Service - No complex retry logic, just fast fail
class OcrServiceSimple extends BaseOcrService {
  TextRecognizer? _recognizer;
  
  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    debugPrint('\n' + '='*70);
    debugPrint('🔍 SIMPLE OCR: Starting');
    debugPrint('='*70);
    
    final sw = Stopwatch()..start();
    
    try {
      // Step 1: Validate and preprocess image
      final processedPath = await _prepareImage(imagePath);
      if (processedPath == null) {
        return OcrResult.failure(
          errorMessage: 'Failed to prepare image for OCR',
        );
      }
      
      // Step 2: Create fresh recognizer
      debugPrint('📱 Creating TextRecognizer...');
      await _disposeRecognizer();
      _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      debugPrint('✅ TextRecognizer created');
      
      // Step 3: Create InputImage
      debugPrint('🖼️  Creating InputImage...');
      final inputImage = InputImage.fromFilePath(processedPath);
      debugPrint('✅ InputImage created');
      
      // Step 4: Process with HARD 4 second limit
      debugPrint('⚡ Processing (4 second hard limit)...');
      final startTime = DateTime.now();
      
      RecognizedText? result;
      bool completed = false;
      
      // Create a completer for tracking
      final completer = Completer<RecognizedText?>();
      
      // Start the OCR process
      _recognizer!.processImage(inputImage).then((recognizedText) {
        if (!completer.isCompleted) {
          completed = true;
          completer.complete(recognizedText);
          debugPrint('✅ OCR completed in ${DateTime.now().difference(startTime).inMilliseconds}ms');
        }
      }).catchError((error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });
      
      // Race against 4 second timeout
      try {
        result = await completer.future.timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            debugPrint('⏱️  TIMEOUT: OCR took too long (>4s)');
            return null;
          },
        );
      } catch (e) {
        debugPrint('❌ OCR error: $e');
        result = null;
      }
      
      sw.stop();
      
      // Clean up
      await _disposeRecognizer();
      
      // Delete preprocessed file if different
      if (processedPath != imagePath) {
        try {
          await File(processedPath).delete();
        } catch (e) {
          debugPrint('⚠️  Could not delete temp file: $e');
        }
      }
      
      // Check result
      if (result == null || result.text.isEmpty) {
        debugPrint('❌ No text extracted (${sw.elapsedMilliseconds}ms)');
        return OcrResult.failure(
          errorMessage: 'Could not extract text from image',
        );
      }
      
      debugPrint('✅ Extracted ${result.text.length} characters (${sw.elapsedMilliseconds}ms)');
      
      return OcrResult.success(
        rawText: result.text,
        textBlocks: [],
        confidence: _calculateConfidence(result),
      );
      
    } catch (e) {
      sw.stop();
      debugPrint('❌ Exception: $e (${sw.elapsedMilliseconds}ms)');
      await _disposeRecognizer();
      return OcrResult.failure(
        errorMessage: e.toString(),
      );
    }
  }
  
  /// Prepare image: resize if needed, optimize
  Future<String?> _prepareImage(String imagePath) async {
    try {
      debugPrint('📂 Checking file: $imagePath');
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('❌ File not found');
        return null;
      }
      
      final fileSize = await file.length();
      debugPrint('📊 File size: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      
      // If file is small enough, use as-is
      if (fileSize < 1024 * 1024) { // < 1MB
        debugPrint('✅ File size OK, using original');
        return imagePath;
      }
      
      // Resize large images
      debugPrint('🔧 Resizing large image...');
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        debugPrint('❌ Could not decode image');
        return null;
      }
      
      debugPrint('   Original: ${image.width}x${image.height}');
      
      // Resize to max 1600px
      img.Image resized = image;
      if (image.width > 1600 || image.height > 1600) {
        final scale = 1600 / (image.width > image.height ? image.width : image.height);
        resized = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
        );
        debugPrint('   Resized: ${resized.width}x${resized.height}');
      }
      
      // Save as JPEG
      final tempPath = '${file.parent.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(img.encodeJpg(resized, quality: 90));
      
      final newSize = await tempFile.length();
      debugPrint('✅ Saved: ${(newSize / 1024).toStringAsFixed(1)} KB');
      
      return tempPath;
    } catch (e) {
      debugPrint('❌ Prepare failed: $e');
      return null;
    }
  }
  
  /// Calculate confidence from recognized text
  double? _calculateConfidence(RecognizedText text) {
    final values = text.blocks
        .expand((block) => block.lines)
        .where((line) => line.confidence != null)
        .map((line) => line.confidence!)
        .toList();
    
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
  
  /// Dispose recognizer
  Future<void> _disposeRecognizer() async {
    if (_recognizer != null) {
      try {
        await _recognizer!.close();
        debugPrint('🗑️  Recognizer disposed');
      } catch (e) {
        debugPrint('⚠️  Dispose error: $e');
      }
      _recognizer = null;
    }
  }
}
