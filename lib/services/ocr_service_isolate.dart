import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../core/models/ocr_result.dart';

/// Alternative OCR Service using Isolates for better timeout control
/// This runs OCR in a separate thread that can be forcefully killed
class OcrServiceIsolate {
  
  /// Process image with actual cancellation via Isolate
  Future<OcrResult> recognizeText(String imagePath) async {
    debugPrint('\n🔷 ISOLATE OCR: Starting in separate thread');
    debugPrint('📁 Path: $imagePath');
    
    final stopwatch = Stopwatch()..start();
    
    // Validate file exists first
    final file = File(imagePath);
    if (!await file.exists()) {
      return OcrResult.failure(errorMessage: 'File not found: $imagePath');
    }
    
    final fileSize = await file.length();
    debugPrint('📊 File size: ${(fileSize / 1024).toStringAsFixed(1)} KB');
    
    if (fileSize > 10 * 1024 * 1024) {
      return OcrResult.failure(errorMessage: 'Image too large (max 10MB)');
    }
    
    // Create a ReceivePort to get results from the isolate
    final receivePort = ReceivePort();
    Isolate? isolate;
    
    try {
      // Spawn isolate with OCR task
      debugPrint('🚀 Spawning OCR isolate...');
      isolate = await Isolate.spawn(
        _ocrIsolateEntry,
        _OcrIsolateMessage(
          sendPort: receivePort.sendPort,
          imagePath: imagePath,
        ),
      );
      
      debugPrint('✅ Isolate spawned, waiting for result (max 8 seconds)...');
      
      // Wait for result with timeout
      final result = await receivePort.first.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('⏱️ ISOLATE TIMEOUT - Killing isolate');
          return _OcrIsolateResult(
            success: false,
            errorMessage: 'OCR timed out after 8 seconds',
          );
        },
      );
      
      stopwatch.stop();
      
      if (result is _OcrIsolateResult) {
        debugPrint('📦 Received result from isolate (${stopwatch.elapsedMilliseconds}ms)');
        debugPrint('   Success: ${result.success}');
        
        if (result.success) {
          return OcrResult.success(
            rawText: result.text ?? '',
            textBlocks: [],
            confidence: result.confidence,
          );
        } else {
          return OcrResult.failure(
            errorMessage: result.errorMessage ?? 'OCR failed',
          );
        }
      } else {
        return OcrResult.failure(errorMessage: 'Invalid result from isolate');
      }
      
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Isolate error after ${stopwatch.elapsedMilliseconds}ms: $e');
      return OcrResult.failure(errorMessage: 'OCR error: $e');
    } finally {
      // CRITICAL: Force kill the isolate if it's still running
      if (isolate != null) {
        debugPrint('🔪 Killing isolate to prevent memory leak');
        isolate.kill(priority: Isolate.immediate);
      }
      receivePort.close();
    }
  }
  
  /// Isolate entry point - runs OCR in separate thread
  static Future<void> _ocrIsolateEntry(_OcrIsolateMessage message) async {
    try {
      debugPrint('🔷 Inside isolate - creating TextRecognizer');
      
      // Create fresh TextRecognizer in this isolate
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      debugPrint('🔷 Creating InputImage from path');
      final inputImage = InputImage.fromFilePath(message.imagePath);
      
      debugPrint('🔷 Calling processImage() - THIS IS WHERE IT HANGS');
      final sw = Stopwatch()..start();
      
      // This is the native call that hangs
      final recognizedText = await recognizer.processImage(inputImage);
      
      sw.stop();
      debugPrint('🔷 processImage() returned in ${sw.elapsedMilliseconds}ms');
      
      final text = recognizedText.text;
      debugPrint('🔷 Extracted ${text.length} characters');
      
      // Calculate confidence
      double? confidence;
      if (recognizedText.blocks.isNotEmpty) {
        final confidenceValues = recognizedText.blocks
            .expand((block) => block.lines)
            .where((line) => line.confidence != null)
            .map((line) => line.confidence!)
            .toList();
        
        if (confidenceValues.isNotEmpty) {
          confidence = confidenceValues.reduce((a, b) => a + b) / confidenceValues.length;
        }
      }
      
      // Close recognizer
      await recognizer.close();
      
      // Send result back to main isolate
      message.sendPort.send(_OcrIsolateResult(
        success: true,
        text: text,
        confidence: confidence,
      ));
      
      debugPrint('🔷 Result sent back to main isolate');
      
    } catch (e) {
      debugPrint('🔷 Error in isolate: $e');
      message.sendPort.send(_OcrIsolateResult(
        success: false,
        errorMessage: e.toString(),
      ));
    }
  }
}

/// Message sent to OCR isolate
class _OcrIsolateMessage {
  final SendPort sendPort;
  final String imagePath;
  
  _OcrIsolateMessage({
    required this.sendPort,
    required this.imagePath,
  });
}

/// Result sent back from OCR isolate
class _OcrIsolateResult {
  final bool success;
  final String? text;
  final double? confidence;
  final String? errorMessage;
  
  _OcrIsolateResult({
    required this.success,
    this.text,
    this.confidence,
    this.errorMessage,
  });
}
