/// EXAMPLE USAGE: OCR Service with Google ML Kit Text Recognition

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ocr_service.dart';
import '../core/models/ocr_result.dart';

// ============================================================
// EXAMPLE 1: Basic OCR - Extract Text from Image
// ============================================================

Future<void> basicOcrExample() async {
  final ocrService = OcrService();

  // Path to receipt image
  final imagePath = '/path/to/receipt.jpg';

  // Perform OCR
  final result = await ocrService.recognizeText(imagePath);

  if (result.success) {
    print('✅ OCR successful!');
    print('Raw text:\n${result.rawText}');
    print('\nFound ${result.textBlockCount} text blocks');
    print('Confidence: ${result.confidence?.toStringAsFixed(2)}');
  } else {
    print('❌ OCR failed: ${result.errorMessage}');
  }

  // Clean up
  await ocrService.dispose();
}

// ============================================================
// EXAMPLE 2: Extract Just the Text (Simple Method)
// ============================================================

Future<void> simpleTextExtraction() async {
  final ocrService = OcrService();

  final imagePath = '/path/to/receipt.jpg';

  // Get just the text string
  final text = await ocrService.extractText(imagePath);

  print('Extracted text:');
  print(text);

  await ocrService.dispose();
}

// ============================================================
// EXAMPLE 3: Extract Lines of Text
// ============================================================

Future<void> extractLinesExample() async {
  final ocrService = OcrService();

  final imagePath = '/path/to/receipt.jpg';

  // Get lines as a list
  final lines = await ocrService.extractLines(imagePath);

  print('Found ${lines.length} lines:');
  for (var i = 0; i < lines.length; i++) {
    print('${i + 1}. ${lines[i]}');
  }

  await ocrService.dispose();
}

// ============================================================
// EXAMPLE 4: Process Text Blocks with Metadata
// ============================================================

Future<void> textBlocksExample() async {
  final ocrService = OcrService();

  final imagePath = '/path/to/receipt.jpg';

  final result = await ocrService.recognizeText(imagePath);

  if (result.success) {
    print('Processing ${result.textBlocks.length} text blocks:\n');

    for (var i = 0; i < result.textBlocks.length; i++) {
      final block = result.textBlocks[i];
      print('Block ${i + 1}:');
      print('  Text: ${block.text}');
      print('  Lines: ${block.lines.length}');
      print('  Confidence: ${block.confidence?.toStringAsFixed(2) ?? "N/A"}');
      
      if (block.boundingBox != null) {
        print('  Position: ${block.boundingBox}');
      }
      print('');
    }
  }

  await ocrService.dispose();
}

// ============================================================
// EXAMPLE 5: Search for Specific Patterns (e.g., Prices)
// ============================================================

Future<void> searchPatternsExample() async {
  final ocrService = OcrService();

  final imagePath = '/path/to/receipt.jpg';

  // Search for price patterns (e.g., $12.99, £45.00)
  final pricePattern = RegExp(r'[\$£€]?\s*\d+[.,]\d{2}');
  final prices = await ocrService.searchText(imagePath, pricePattern);

  print('Found prices:');
  for (final price in prices) {
    print('  $price');
  }

  // Search for dates (e.g., 12/25/2023, 25-12-2023)
  final datePattern = RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}');
  final dates = await ocrService.searchText(imagePath, datePattern);

  print('\nFound dates:');
  for (final date in dates) {
    print('  $date');
  }

  await ocrService.dispose();
}

// ============================================================
// EXAMPLE 6: Check if Image Contains Specific Text
// ============================================================

Future<void> containsTextExample() async {
  final ocrService = OcrService();

  final imagePath = '/path/to/receipt.jpg';

  // Check if receipt is from a specific store
  final isWalmart = await ocrService.containsText(imagePath, 'Walmart');
  final isTarget = await ocrService.containsText(imagePath, 'Target');

  print('Receipt from Walmart? $isWalmart');
  print('Receipt from Target? $isTarget');

  // Check for specific terms
  final hasTax = await ocrService.containsText(imagePath, 'tax');
  final hasTotal = await ocrService.containsText(imagePath, 'total');

  print('Contains tax? $hasTax');
  print('Contains total? $hasTotal');

  await ocrService.dispose();
}

// ============================================================
// EXAMPLE 7: Flutter Widget Integration - Display OCR Results
// ============================================================

class OcrResultWidget extends StatefulWidget {
  final String imagePath;

  const OcrResultWidget({super.key, required this.imagePath});

  @override
  State<OcrResultWidget> createState() => _OcrResultWidgetState();
}

class _OcrResultWidgetState extends State<OcrResultWidget> {
  final _ocrService = OcrService();
  OcrResult? _result;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    setState(() => _isProcessing = true);

    final result = await _ocrService.recognizeText(widget.imagePath);

    setState(() {
      _result = result;
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Result')),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : _result != null
              ? _buildResult()
              : const Center(child: Text('No result')),
    );
  }

  Widget _buildResult() {
    if (!_result!.success) {
      return Center(
        child: Text('Error: ${_result!.errorMessage}'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Image preview
        Image.file(File(widget.imagePath), height: 200),
        const SizedBox(height: 16),

        // Statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Text Blocks: ${_result!.textBlockCount}'),
                Text('Lines: ${_result!.lines.length}'),
                if (_result!.confidence != null)
                  Text('Confidence: ${(_result!.confidence! * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Raw text
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Extracted Text:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_result!.rawText),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EXAMPLE 8: Batch Processing Multiple Images
// ============================================================

Future<void> batchProcessingExample() async {
  final ocrService = OcrService();

  final imagePaths = [
    '/path/to/receipt1.jpg',
    '/path/to/receipt2.jpg',
    '/path/to/receipt3.jpg',
  ];

  print('Processing ${imagePaths.length} images...\n');

  for (var i = 0; i < imagePaths.length; i++) {
    print('Processing image ${i + 1}/${imagePaths.length}...');
    
    final result = await ocrService.recognizeText(imagePaths[i]);
    
    if (result.success) {
      print('  ✅ Success - ${result.textBlockCount} blocks, ${result.lines.length} lines');
    } else {
      print('  ❌ Failed - ${result.errorMessage}');
    }
  }

  await ocrService.dispose();
}

// ============================================================
// EXAMPLE 9: Process Image from File Object
// ============================================================

Future<void> processFileObjectExample() async {
  final ocrService = OcrService();

  // Get File object from image picker or camera
  final imageFile = File('/path/to/receipt.jpg');

  // Process File directly
  final result = await ocrService.recognizeTextFromFile(imageFile);

  if (result.success) {
    print('Text extracted from ${imageFile.path}:');
    print(result.rawText);
  }

  await ocrService.dispose();
}

// ============================================================
// EXAMPLE 10: Error Handling and Validation
// ============================================================

Future<void> errorHandlingExample() async {
  final ocrService = OcrService();

  try {
    // Check if service is ready
    if (!ocrService.isInitialized) {
      print('Service not initialized!');
      return;
    }

    final imagePath = '/path/to/receipt.jpg';

    // Validate file exists
    final file = File(imagePath);
    if (!await file.exists()) {
      print('Image file not found!');
      return;
    }

    // Process image
    final result = await ocrService.recognizeText(imagePath);

    // Check result
    if (result.success) {
      if (result.hasText) {
        print('Successfully extracted text!');
        print('Text: ${result.rawText}');
      } else {
        print('No text found in image');
      }
    } else {
      print('OCR failed: ${result.errorMessage}');
    }
  } catch (e) {
    print('Unexpected error: $e');
  } finally {
    // Always dispose
    await ocrService.dispose();
  }
}

// ============================================================
// EXAMPLE 11: Integration with Camera Capture
// ============================================================

Future<void> cameraIntegrationExample(String capturedImagePath) async {
  print('Processing captured receipt...');

  final ocrService = OcrService();

  // Process the captured image
  final result = await ocrService.recognizeText(capturedImagePath);

  if (result.success && result.hasText) {
    print('✅ Receipt processed!');
    print('Extracted text:');
    print(result.rawText);
    print('\nReady to parse and extract expense data...');

    // Next step: Parse the text to extract amount, merchant, date
    // (This will be implemented in a future parser service)
  } else {
    print('❌ Could not extract text from receipt');
  }

  await ocrService.dispose();
}

// ============================================================
// EXAMPLE 12: Real-time OCR with Progress Updates
// ============================================================

class RealtimeOcrProcessor {
  final OcrService _ocrService = OcrService();
  final void Function(String status)? onStatusUpdate;

  RealtimeOcrProcessor({this.onStatusUpdate});

  Future<OcrResult> processWithUpdates(String imagePath) async {
    _updateStatus('Validating image...');
    
    final file = File(imagePath);
    if (!await file.exists()) {
      _updateStatus('Image not found!');
      return OcrResult.failure(errorMessage: 'Image not found');
    }

    _updateStatus('Starting OCR processing...');
    
    final result = await _ocrService.recognizeText(imagePath);

    if (result.success) {
      _updateStatus('OCR complete! Found ${result.textBlockCount} text blocks');
    } else {
      _updateStatus('OCR failed: ${result.errorMessage}');
    }

    return result;
  }

  void _updateStatus(String status) {
    print('[OCR] $status');
    onStatusUpdate?.call(status);
  }

  Future<void> dispose() async {
    await _ocrService.dispose();
  }
}

// Usage:
Future<void> realtimeOcrExample() async {
  final processor = RealtimeOcrProcessor(
    onStatusUpdate: (status) {
      print('Status: $status');
    },
  );

  final result = await processor.processWithUpdates('/path/to/receipt.jpg');

  if (result.success) {
    print('Final result: ${result.rawText}');
  }

  await processor.dispose();
}

// ============================================================
// EXAMPLE 13: Performance Monitoring
// ============================================================

Future<void> performanceMonitoringExample() async {
  final ocrService = OcrService();
  final imagePath = '/path/to/receipt.jpg';

  final stopwatch = Stopwatch()..start();

  final result = await ocrService.recognizeText(imagePath);

  stopwatch.stop();

  print('OCR Performance Report:');
  print('  Processing time: ${stopwatch.elapsedMilliseconds}ms');
  print('  Success: ${result.success}');
  if (result.success) {
    print('  Text blocks: ${result.textBlockCount}');
    print('  Characters: ${result.rawText.length}');
    print('  Lines: ${result.lines.length}');
    print('  Confidence: ${result.confidence?.toStringAsFixed(2) ?? "N/A"}');
  }

  await ocrService.dispose();
}

// ============================================================
// MAIN DEMO - Run All Examples
// ============================================================

Future<void> runOcrExamples() async {
  print('=== OCR Service Examples ===\n');

  // Replace with actual image path for testing
  final testImagePath = '/path/to/test/receipt.jpg';

  print('1. Basic OCR Example');
  await basicOcrExample();
  print('\n---\n');

  print('2. Simple Text Extraction');
  await simpleTextExtraction();
  print('\n---\n');

  print('3. Extract Lines');
  await extractLinesExample();
  print('\n---\n');

  print('4. Text Blocks with Metadata');
  await textBlocksExample();
  print('\n---\n');

  print('5. Search Patterns');
  await searchPatternsExample();
  print('\n---\n');

  print('6. Contains Text');
  await containsTextExample();
  print('\n---\n');

  print('7. Error Handling');
  await errorHandlingExample();
  print('\n---\n');

  print('8. Performance Monitoring');
  await performanceMonitoringExample();
  print('\n---\n');

  print('All examples completed!');
}
