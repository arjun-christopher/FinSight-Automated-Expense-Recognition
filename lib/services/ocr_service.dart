import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../core/models/ocr_result.dart';

/// Service class for performing Optical Character Recognition (OCR) on images
/// using Google ML Kit Text Recognition.
class OcrService {
  /// Text recognizer instance
  late final TextRecognizer _textRecognizer;

  /// Whether the service has been initialized
  bool _isInitialized = false;

  OcrService() {
    _initialize();
  }

  /// Initialize the text recognizer
  void _initialize() {
    // Use default Latin script recognizer
    // For other scripts, use: TextRecognizer(script: TextRecognitionScript.chinese)
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _isInitialized = true;
  }

  /// Check if the service is ready to use
  bool get isInitialized => _isInitialized;

  /// Process an image and extract text using OCR
  ///
  /// [imagePath] - Absolute path to the image file
  ///
  /// Returns an [OcrResult] containing extracted text and metadata
  ///
  /// Throws [OcrException] if processing fails
  Future<OcrResult> recognizeText(String imagePath) async {
    debugPrint('🔍 OCR: Starting text recognition for: $imagePath');
    
    if (!_isInitialized) {
      debugPrint('❌ OCR: Service not initialized');
      return OcrResult.failure(
        errorMessage: 'OCR service not initialized',
      );
    }

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
      debugPrint('✓ OCR: File exists (${(fileSize / 1024).toStringAsFixed(1)} KB)');
      
      // Create InputImage from file path
      debugPrint('🖼️  OCR: Creating InputImage...');
      final inputImage = InputImage.fromFilePath(imagePath);

      // Perform text recognition with 10 second timeout
      debugPrint('⏳ OCR: Processing image (max 10 seconds)...');
      final sw = Stopwatch()..start();
      
      final recognizedText = await _textRecognizer.processImage(inputImage).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          sw.stop();
          debugPrint('⏱️  OCR: TIMEOUT after ${sw.elapsedMilliseconds}ms');
          throw Exception('OCR processing timed out after 10 seconds');
        },
      );
      
      sw.stop();
      debugPrint('✓ OCR: Processing completed in ${sw.elapsedMilliseconds}ms');

      // Extract text and metadata
      final textBlocks = _extractTextBlocks(recognizedText);
      final rawText = recognizedText.text;
      final confidence = _calculateAverageConfidence(textBlocks);
      
      debugPrint('📝 OCR: Extracted ${rawText.length} characters');
      debugPrint('📊 OCR: Confidence: ${((confidence ?? 0.0) * 100).toStringAsFixed(1)}%');

      return OcrResult.success(
        rawText: rawText,
        textBlocks: textBlocks,
        confidence: confidence,
      );
    } catch (e) {
      debugPrint('❌ OCR: Error occurred - $e');
      return OcrResult.failure(
        errorMessage: 'OCR processing failed: ${e.toString()}',
      );
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
    if (_isInitialized) {
      await _textRecognizer.close();
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
