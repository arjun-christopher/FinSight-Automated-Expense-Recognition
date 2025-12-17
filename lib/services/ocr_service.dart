import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import '../core/models/ocr_result.dart';
import 'base_ocr_service.dart';

/// Service class for performing Optical Character Recognition (OCR) on images
/// using Google ML Kit Text Recognition.
class OcrService extends BaseOcrService {
  /// Text recognizer instance (can be recreated if it gets stuck)
  TextRecognizer? _textRecognizer;

  /// Whether the service has been initialized
  bool _isInitialized = false;
  
  /// Track the last time we recreated the recognizer
  DateTime? _lastRecreation;

  OcrService() {
    _initialize();
  }

  /// Initialize or reinitialize the text recognizer
  Future<void> _initialize() async {
    try {
      // Close existing recognizer if it exists
      if (_textRecognizer != null) {
        debugPrint('🔄 OCR: Closing existing TextRecognizer before reinitializing');
        await _textRecognizer!.close();
        _textRecognizer = null;
        // Small delay to ensure native cleanup
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      debugPrint('🎯 OCR: Creating new TextRecognizer (Latin script)');
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      _isInitialized = true;
      _lastRecreation = DateTime.now();
      debugPrint('✅ OCR: TextRecognizer initialized successfully');
    } catch (e) {
      debugPrint('❌ OCR: Failed to initialize TextRecognizer: $e');
      _isInitialized = false;
    }
  }

  /// Check if the service is ready to use
  bool get isInitialized => _isInitialized && _textRecognizer != null;

  /// Preprocess image to optimize for OCR
  /// Resizes large images and ensures proper format
  Future<String> _preprocessImage(String imagePath) async {
    debugPrint('🖼️  OCR: Preprocessing image...');
    
    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    
    // Decode image
    img.Image? image;
    try {
      image = img.decodeImage(bytes);
    } catch (e) {
      debugPrint('⚠️  OCR: Could not decode image for preprocessing: $e');
      return imagePath; // Return original if can't decode
    }
    
    if (image == null) {
      debugPrint('⚠️  OCR: Image decoded to null, using original');
      return imagePath;
    }
    
    debugPrint('   Original size: ${image.width}x${image.height}');
    
    // Resize if image is too large (max 2048px on longest side)
    const maxDimension = 2048;
    if (image.width > maxDimension || image.height > maxDimension) {
      debugPrint('   📏 Resizing large image...');
      final scaleFactor = maxDimension / (image.width > image.height ? image.width : image.height);
      final newWidth = (image.width * scaleFactor).round();
      final newHeight = (image.height * scaleFactor).round();
      
      image = img.copyResize(image, width: newWidth, height: newHeight);
      debugPrint('   ✓ Resized to: ${image.width}x${image.height}');
    }
    
    // Save preprocessed image to temporary file
    final tempDir = imageFile.parent;
    final tempPath = '${tempDir.path}/temp_preprocessed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final tempFile = File(tempPath);
    
    // Encode as JPEG with 85% quality
    final encodedBytes = img.encodeJpg(image, quality: 85);
    await tempFile.writeAsBytes(encodedBytes);
    
    debugPrint('   ✓ Preprocessed image saved: ${(encodedBytes.length / 1024).toStringAsFixed(1)} KB');
    return tempPath;
  }

  /// Process an image and extract text using OCR with retry logic
  ///
  /// [imagePath] - Absolute path to the image file
  ///
  /// Returns an [OcrResult] containing extracted text and metadata
  Future<OcrResult> recognizeText(String imagePath, {int maxRetries = 2}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      if (attempt > 0) {
        debugPrint('\n🔄 OCR: Retry attempt $attempt of $maxRetries');
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
      
      final result = await _recognizeTextInternal(imagePath, attempt);
      
      // If successful, return immediately
      if (result.success) {
        return result;
      }
      
      // If it's the last attempt, return the failure
      if (attempt == maxRetries) {
        return result;
      }
      
      // If failed due to timeout, recreate recognizer before retry
      if (result.errorMessage?.contains('timed out') == true) {
        debugPrint('⚠️  OCR: Timeout detected, recreating recognizer...');
        await _initialize();
      }
    }
    
    return OcrResult.failure(errorMessage: 'OCR failed after $maxRetries retries');
  }

  /// Internal method that performs actual OCR processing
  Future<OcrResult> _recognizeTextInternal(String imagePath, int attemptNumber) async {
    final overallStopwatch = Stopwatch()..start();
    debugPrint('\n' + '🔍'*30);
    debugPrint('🔍 OCR: Starting text recognition (attempt ${attemptNumber + 1})');
    debugPrint('Path: $imagePath');
    debugPrint('Initialized: $_isInitialized');
    debugPrint('Recognizer exists: ${_textRecognizer != null}');
    if (_lastRecreation != null) {
      debugPrint('Last recreation: ${DateTime.now().difference(_lastRecreation!).inSeconds}s ago');
    }
    debugPrint('🔍'*30);
    
    // STRATEGY: Force recreate recognizer for EVERY call to avoid stale state
    debugPrint('🔄 OCR: FORCE RECREATING TextRecognizer (fresh instance strategy)');
    await _initialize();
    
    if (!_isInitialized || _textRecognizer == null) {
      return OcrResult.failure(
        errorMessage: 'OCR service failed to initialize',
      );
    }

    String? preprocessedPath;
    
    try {
      // Validate image file exists
      debugPrint('📂 OCR: Checking if file exists...');
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('❌ OCR: File not found');
        return OcrResult.failure(
          errorMessage: 'Image file not found: $imagePath',
        );
      }

      final fileSize = await imageFile.length();
      final fileSizeKB = fileSize / 1024;
      final fileSizeMB = fileSizeKB / 1024;
      debugPrint('✓ OCR: File exists (${fileSizeKB.toStringAsFixed(1)} KB)');
      
      // Check file size - reject very large images that might cause hanging
      const maxSizeMB = 10; // 10MB limit
      if (fileSizeMB > maxSizeMB) {
        debugPrint('❌ OCR: File too large (${fileSizeMB.toStringAsFixed(1)} MB > $maxSizeMB MB)');
        return OcrResult.failure(
          errorMessage: 'Image file too large (${fileSizeMB.toStringAsFixed(1)} MB). Please use an image smaller than $maxSizeMB MB.',
        );
      }
      
      // Create InputImage from file path
      debugPrint('🖼️  OCR: Creating InputImage from file...');
      
      // Preprocess image: resize if needed, optimize format
      debugPrint('🔧 OCR: Preprocessing image...');
      try {
        preprocessedPath = await _preprocessImage(imagePath);
        debugPrint('✓ OCR: Using preprocessed image: $preprocessedPath');
      } catch (e) {
        debugPrint('⚠️  OCR: Preprocessing failed, using original: $e');
        preprocessedPath = imagePath;
      }
      
      InputImage? inputImage;
      try {
        inputImage = InputImage.fromFilePath(preprocessedPath);
        debugPrint('✓ OCR: InputImage created successfully');
      } catch (e) {
        debugPrint('❌ OCR: Failed to create InputImage: $e');
        return OcrResult.failure(
          errorMessage: 'Failed to create InputImage: $e',
        );
      }

      // Perform text recognition with AGGRESSIVE timeout (5 seconds)
      // STRATEGY: Shorter timeout, faster failure, retry with fresh recognizer
      debugPrint('⏳ OCR: Calling native ML Kit processImage() (max 5 seconds)...');
      debugPrint('⏳ OCR: Starting at: ${DateTime.now()}');
      final sw = Stopwatch()..start();
      
      RecognizedText? recognizedText;
      bool processingCompleted = false;
      
      try {
        // Use aggressive 5-second timeout
        recognizedText = await _textRecognizer!
            .processImage(inputImage)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                sw.stop();
                debugPrint('⏱️  OCR: TIMEOUT after ${sw.elapsedMilliseconds}ms');
                debugPrint('⏱️  OCR: Native call did not complete - will retry with fresh recognizer');
                throw TimeoutException('ML Kit timeout');
              },
            ).then((result) {
              processingCompleted = true;
              return result;
            });
        
        sw.stop();
        debugPrint('✓ OCR: Completed in ${sw.elapsedMilliseconds}ms');
        
      } on TimeoutException catch (e) {
        debugPrint('❌ OCR: Timeout - destroying recognizer for retry');
        // Force cleanup for next attempt
        try {
          await _textRecognizer?.close();
          _textRecognizer = null;
          _isInitialized = false;
        } catch (e) {
          debugPrint('⚠️  OCR: Error during cleanup: $e');
        }
        return OcrResult.failure(
          errorMessage: 'OCR timed out after ${sw.elapsedMilliseconds}ms',
        );
      } catch (e) {
        sw.stop();
        debugPrint('❌ OCR: Exception after ${sw.elapsedMilliseconds}ms: $e');
        return OcrResult.failure(
          errorMessage: 'OCR failed: ${e.toString().replaceAll("Exception: ", "")}',
        );
      }
      
      sw.stop();
      
      if (recognizedText == null) {
        debugPrint('❌ OCR: recognizedText is null');
        throw Exception('ML Kit returned null result');
      }
      
      debugPrint('✓ OCR: Processing completed in ${sw.elapsedMilliseconds}ms');

      // Extract text and metadata
      debugPrint('📊 OCR: Extracting text blocks...');
      final textBlocks = _extractTextBlocks(recognizedText);
      final rawText = recognizedText.text;
      final confidence = _calculateAverageConfidence(textBlocks);
      
      overallStopwatch.stop();
      debugPrint('📝 OCR: Extracted ${rawText.length} characters');
      debugPrint('📊 OCR: Confidence: ${((confidence ?? 0.0) * 100).toStringAsFixed(1)}%');
      debugPrint('⏱️  OCR: Total time including overhead: ${overallStopwatch.elapsedMilliseconds}ms');

      return OcrResult.success(
        rawText: rawText,
        textBlocks: textBlocks,
        confidence: confidence,
      );
    } catch (e) {
      overallStopwatch.stop();
      debugPrint('❌ OCR: Error occurred after ${overallStopwatch.elapsedMilliseconds}ms - $e');
      
      // Check if this is a timeout
      if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        return OcrResult.failure(
          errorMessage: 'OCR processing timed out. The image may be too complex or large.',
        );
      }
      
      return OcrResult.failure(
        errorMessage: 'OCR processing failed: ${e.toString()}',
      );
    } finally {
      // Cleanup preprocessed file if it was created
      if (preprocessedPath != null && preprocessedPath != imagePath) {
        try {
          final tempFile = File(preprocessedPath);
          if (await tempFile.exists()) {
            await tempFile.delete();
            debugPrint('🗑️  OCR: Cleaned up preprocessed file');
          }
        } catch (e) {
          debugPrint('⚠️  OCR: Could not delete preprocessed file: $e');
        }
      }
    }
  }

  /// Process an image from a File object
  ///
  /// [imageFile] - The image file to process
  ///
  /// Returns an [OcrResult] containing extracted text and metadata
  Future<OcrResult> recognizeTextFromFile(File imageFile) async {
    return recognizeText(imageFile.path);
  }

  /// Extract text blocks from recognized text
  List<TextBlockData> _extractTextBlocks(RecognizedText recognizedText) {
    final textBlocks = <TextBlockData>[];

    for (final block in recognizedText.blocks) {
      // Extract bounding box if available
      BoundingBox? boundingBox;
      final rect = block.boundingBox;
      if (rect != null) {
        boundingBox = BoundingBox(
          x: rect.left,
          y: rect.top,
          width: rect.width,
          height: rect.height,
        );
      }

      // Extract lines from the block
      final lines = block.lines.map((line) => line.text).toList();

      // Calculate average confidence for this block
      double? blockConfidence;
      if (block.lines.isNotEmpty) {
        final confidenceValues = block.lines
            .where((line) => line.confidence != null)
            .map((line) => line.confidence!)
            .toList();
        
        if (confidenceValues.isNotEmpty) {
          blockConfidence = confidenceValues.reduce((a, b) => a + b) / confidenceValues.length;
        }
      }

      textBlocks.add(TextBlockData(
        text: block.text,
        boundingBox: boundingBox,
        confidence: blockConfidence,
        lines: lines,
      ));
    }

    return textBlocks;
  }

  /// Calculate average confidence across all text blocks
  double? _calculateAverageConfidence(List<TextBlockData> textBlocks) {
    final confidenceValues = textBlocks
        .where((block) => block.confidence != null)
        .map((block) => block.confidence!)
        .toList();

    if (confidenceValues.isEmpty) return null;

    return confidenceValues.reduce((a, b) => a + b) / confidenceValues.length;
  }

  /// Get raw text from image (convenience method)
  ///
  /// Returns just the text string without additional metadata
  Future<String> extractText(String imagePath) async {
    final result = await recognizeText(imagePath);
    return result.success ? result.rawText : '';
  }

  /// Get lines of text from image
  ///
  /// Returns a list of non-empty text lines
  Future<List<String>> extractLines(String imagePath) async {
    final result = await recognizeText(imagePath);
    return result.success ? result.lines : [];
  }

  /// Search for specific text pattern in image
  ///
  /// [imagePath] - Path to the image
  /// [pattern] - Regular expression pattern to search for
  ///
  /// Returns list of matching strings
  Future<List<String>> searchText(String imagePath, RegExp pattern) async {
    final result = await recognizeText(imagePath);
    if (!result.success) return [];

    return pattern
        .allMatches(result.rawText)
        .map((match) => match.group(0) ?? '')
        .where((text) => text.isNotEmpty)
        .toList();
  }

  /// Check if image contains specific text
  ///
  /// Case-insensitive search
  Future<bool> containsText(String imagePath, String searchText) async {
    final result = await recognizeText(imagePath);
    if (!result.success) return false;

    return result.rawText.toLowerCase().contains(searchText.toLowerCase());
  }

  /// Dispose of resources
  ///
  /// Should be called when the service is no longer needed
  Future<void> dispose() async {
    if (_textRecognizer != null) {
      try {
        await _textRecognizer!.close();
        debugPrint('✅ OCR: TextRecognizer disposed successfully');
      } catch (e) {
        debugPrint('⚠️  OCR: Error disposing TextRecognizer: $e');
      }
      _textRecognizer = null;
      _isInitialized = false;
    }
  }
}

/// Custom exception for OCR errors
class OcrException implements Exception {
  final String message;

  OcrException(this.message);

  @override
  String toString() => 'OcrException: $message';
}
