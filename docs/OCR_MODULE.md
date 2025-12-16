# OCR Module Documentation

## Google ML Kit Text Recognition Integration

This module provides Optical Character Recognition (OCR) capabilities using Google ML Kit Text Recognition. It extracts text from receipt images to enable automated expense data entry.

---

## 📁 File Structure

```
lib/
├── services/
│   └── ocr_service.dart              # Main OCR service class
├── core/models/
│   └── ocr_result.dart               # Result models for OCR output
└── examples/
    └── ocr_examples.dart             # Usage examples
```

---

## 🎯 Core Components

### 1. OcrService (`lib/services/ocr_service.dart`)

Main service class for performing text recognition on images.

**Key Features:**
- ✅ Latin script text recognition (configurable for other scripts)
- ✅ Automatic resource management
- ✅ Text block extraction with metadata
- ✅ Pattern search capabilities
- ✅ Batch processing support
- ✅ Error handling and validation

**Public Methods:**

| Method | Description | Return Type |
|--------|-------------|-------------|
| `recognizeText(String imagePath)` | Full OCR processing with metadata | `Future<OcrResult>` |
| `recognizeTextFromFile(File imageFile)` | Process File object | `Future<OcrResult>` |
| `extractText(String imagePath)` | Get raw text only | `Future<String>` |
| `extractLines(String imagePath)` | Get text lines as list | `Future<List<String>>` |
| `searchText(String imagePath, RegExp pattern)` | Search for patterns | `Future<List<String>>` |
| `containsText(String imagePath, String searchText)` | Check text presence | `Future<bool>` |
| `dispose()` | Clean up resources | `Future<void>` |

### 2. OcrResult Model (`lib/core/models/ocr_result.dart`)

Contains OCR processing results and metadata.

**Properties:**
```dart
class OcrResult {
  final String rawText;                    // Full extracted text
  final List<TextBlockData> textBlocks;    // Individual text blocks
  final bool success;                      // Success status
  final String? errorMessage;              // Error details
  final DateTime timestamp;                // Processing time
  final double? confidence;                // Average confidence (0.0-1.0)
}
```

**Convenience Getters:**
- `hasText` - Check if any text was extracted
- `textBlockCount` - Number of text blocks
- `formattedText` - All text with line breaks
- `lines` - List of non-empty lines

### 3. TextBlockData Model

Represents individual text blocks detected by OCR.

**Properties:**
```dart
class TextBlockData {
  final String text;                  // Block text content
  final BoundingBox? boundingBox;     // Position coordinates
  final double? confidence;           // Block confidence
  final List<String> lines;           // Lines within block
}
```

### 4. BoundingBox Model

Spatial coordinates for detected text.

**Properties:**
```dart
class BoundingBox {
  final double x;        // Left position
  final double y;        // Top position
  final double width;    // Width
  final double height;   // Height
  
  Point get center;      // Center point
}
```

---

## 🚀 Quick Start

### Basic Usage

```dart
import 'package:finsight/services/ocr_service.dart';

Future<void> basicExample() async {
  final ocrService = OcrService();

  // Process image
  final result = await ocrService.recognizeText('/path/to/receipt.jpg');

  if (result.success) {
    print('Extracted text:');
    print(result.rawText);
  } else {
    print('Error: ${result.errorMessage}');
  }

  // Always dispose
  await ocrService.dispose();
}
```

### Simple Text Extraction

```dart
Future<String> getReceiptText(String imagePath) async {
  final ocrService = OcrService();
  final text = await ocrService.extractText(imagePath);
  await ocrService.dispose();
  return text;
}
```

### Search for Patterns

```dart
Future<void> findPrices(String imagePath) async {
  final ocrService = OcrService();
  
  // Find prices like $12.99, £45.00, €23.50
  final pricePattern = RegExp(r'[\$£€]?\s*\d+[.,]\d{2}');
  final prices = await ocrService.searchText(imagePath, pricePattern);
  
  print('Found prices: $prices');
  
  await ocrService.dispose();
}
```

---

## 📱 Integration with Camera Capture

### Complete Receipt Processing Flow

```dart
import 'package:finsight/services/ocr_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Capture receipt image (from Task 4)
final captureState = ref.watch(receiptCaptureProvider);

if (captureState.hasImage) {
  // 2. Process with OCR
  final ocrService = OcrService();
  final result = await ocrService.recognizeText(captureState.imagePath!);
  
  if (result.success) {
    // 3. Extract expense data (future task)
    print('Text to parse: ${result.rawText}');
    
    // TODO: Parse for amount, merchant, date, items
  }
  
  await ocrService.dispose();
}
```

### Flutter Widget Example

```dart
class ReceiptOcrWidget extends StatefulWidget {
  final String imagePath;
  
  const ReceiptOcrWidget({required this.imagePath});
  
  @override
  State<ReceiptOcrWidget> createState() => _ReceiptOcrWidgetState();
}

class _ReceiptOcrWidgetState extends State<ReceiptOcrWidget> {
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
    if (_isProcessing) {
      return const CircularProgressIndicator();
    }
    
    if (_result?.success == true) {
      return Column(
        children: [
          Text('Confidence: ${(_result!.confidence! * 100).toStringAsFixed(1)}%'),
          Text('Text blocks: ${_result!.textBlockCount}'),
          const Divider(),
          Text(_result!.rawText),
        ],
      );
    }
    
    return Text('Error: ${_result?.errorMessage ?? "Unknown"}');
  }
}
```

---

## 🔍 Advanced Features

### 1. Text Block Processing

Access individual text blocks with spatial data:

```dart
final result = await ocrService.recognizeText(imagePath);

for (final block in result.textBlocks) {
  print('Text: ${block.text}');
  print('Lines: ${block.lines.length}');
  print('Confidence: ${block.confidence}');
  
  if (block.boundingBox != null) {
    print('Position: (${block.boundingBox!.x}, ${block.boundingBox!.y})');
    print('Size: ${block.boundingBox!.width}x${block.boundingBox!.height}');
  }
}
```

### 2. Pattern Matching

Extract specific data types:

```dart
final ocrService = OcrService();

// Find dates (MM/DD/YYYY or DD-MM-YYYY)
final datePattern = RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}');
final dates = await ocrService.searchText(imagePath, datePattern);

// Find prices ($12.99, €45.00, £23.50)
final pricePattern = RegExp(r'[\$£€]?\s*\d+[.,]\d{2}');
final prices = await ocrService.searchText(imagePath, pricePattern);

// Find phone numbers
final phonePattern = RegExp(r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}');
final phones = await ocrService.searchText(imagePath, phonePattern);

// Find email addresses
final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
final emails = await ocrService.searchText(imagePath, emailPattern);
```

### 3. Batch Processing

Process multiple images efficiently:

```dart
Future<List<OcrResult>> processMultipleReceipts(List<String> imagePaths) async {
  final ocrService = OcrService();
  final results = <OcrResult>[];
  
  for (final path in imagePaths) {
    final result = await ocrService.recognizeText(path);
    results.add(result);
    
    // Optional: Add delay to avoid overwhelming the system
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  await ocrService.dispose();
  return results;
}
```

### 4. Custom Script Support

Configure for different languages:

```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// For Chinese text
final chineseRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

// For Devanagari script (Hindi, Sanskrit)
final devanagariRecognizer = TextRecognizer(script: TextRecognitionScript.devanagari);

// For Japanese text
final japaneseRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);

// For Korean text
final koreanRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
```

---

## ⚡ Performance Tips

### 1. Image Preprocessing

For best OCR accuracy:
- **Resolution**: 300-600 DPI recommended
- **Format**: JPEG or PNG
- **Size**: Compress to < 2MB (already done in camera capture)
- **Orientation**: Ensure text is upright
- **Lighting**: Good contrast, minimal shadows

### 2. Resource Management

Always dispose of the service:

```dart
final ocrService = OcrService();

try {
  final result = await ocrService.recognizeText(imagePath);
  // Process result
} finally {
  await ocrService.dispose(); // Always clean up
}
```

### 3. Performance Monitoring

```dart
final stopwatch = Stopwatch()..start();

final result = await ocrService.recognizeText(imagePath);

stopwatch.stop();
print('OCR took ${stopwatch.elapsedMilliseconds}ms');
```

**Typical Performance:**
- Small receipt (< 1MB): 500-1500ms
- Medium receipt (1-2MB): 1000-2500ms
- Large receipt (> 2MB): 2000-4000ms

### 4. Caching Results

For repeated access to the same image:

```dart
final Map<String, OcrResult> _cache = {};

Future<OcrResult> getCachedResult(String imagePath) async {
  if (_cache.containsKey(imagePath)) {
    return _cache[imagePath]!;
  }
  
  final result = await ocrService.recognizeText(imagePath);
  _cache[imagePath] = result;
  return result;
}
```

---

## 🐛 Error Handling

### Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "Image file not found" | Invalid path | Verify file exists with `File.exists()` |
| "OCR service not initialized" | Service disposed | Create new instance |
| Low confidence (< 0.5) | Poor image quality | Improve lighting, focus, resolution |
| Empty text result | Image has no text | Validate image contains readable text |
| Processing timeout | Large image | Compress image before processing |

### Comprehensive Error Handling

```dart
Future<OcrResult> safeOcrProcessing(String imagePath) async {
  final ocrService = OcrService();
  
  try {
    // 1. Validate service
    if (!ocrService.isInitialized) {
      return OcrResult.failure(errorMessage: 'Service not initialized');
    }
    
    // 2. Validate file
    final file = File(imagePath);
    if (!await file.exists()) {
      return OcrResult.failure(errorMessage: 'File not found');
    }
    
    // 3. Check file size
    final fileSize = await file.length();
    if (fileSize == 0) {
      return OcrResult.failure(errorMessage: 'Empty file');
    }
    if (fileSize > 10 * 1024 * 1024) { // 10MB
      return OcrResult.failure(errorMessage: 'File too large');
    }
    
    // 4. Process
    final result = await ocrService.recognizeText(imagePath);
    
    // 5. Validate result
    if (result.success && !result.hasText) {
      return OcrResult.failure(errorMessage: 'No text detected');
    }
    
    return result;
  } catch (e) {
    return OcrResult.failure(errorMessage: 'Unexpected error: $e');
  } finally {
    await ocrService.dispose();
  }
}
```

---

## 🔗 Integration Points

### With Camera Capture Module (Task 4)

```dart
// After capturing receipt
final capturedPath = ref.read(receiptCaptureProvider).imagePath;

if (capturedPath != null) {
  final ocrResult = await ocrService.recognizeText(capturedPath);
  // Process OCR result
}
```

### With Expense Form (Task 3)

```dart
// Pre-fill expense form with OCR data
if (ocrResult.success) {
  // TODO: Parse text for amount, merchant, date
  // ref.read(expenseFormProvider.notifier).setAmount(parsedAmount);
  // ref.read(expenseFormProvider.notifier).setMerchant(parsedMerchant);
}
```

### With Database (Task 2)

```dart
// Save OCR text to receipt_image record
final receiptImage = ReceiptImage(
  id: null,
  expenseId: expenseId,
  imagePath: imagePath,
  ocrText: ocrResult.rawText,  // Store extracted text
  ocrProcessed: true,
  createdAt: DateTime.now(),
);

await receiptImageRepository.create(receiptImage);
```

---

## 📊 OCR Result Analysis

### Quality Metrics

```dart
void analyzeOcrQuality(OcrResult result) {
  if (!result.success) return;
  
  // Confidence check
  if (result.confidence != null) {
    if (result.confidence! > 0.8) {
      print('✅ High confidence - Very reliable');
    } else if (result.confidence! > 0.6) {
      print('⚠️ Medium confidence - Mostly reliable');
    } else {
      print('❌ Low confidence - Needs review');
    }
  }
  
  // Text density check
  final charCount = result.rawText.length;
  if (charCount < 20) {
    print('⚠️ Very little text detected');
  }
  
  // Block distribution
  final avgBlockSize = charCount / result.textBlockCount;
  print('Average block size: ${avgBlockSize.toStringAsFixed(1)} chars');
}
```

---

## 🧪 Testing

### Unit Test Example

```dart
void main() {
  group('OcrService Tests', () {
    late OcrService ocrService;
    
    setUp(() {
      ocrService = OcrService();
    });
    
    tearDown(() async {
      await ocrService.dispose();
    });
    
    test('recognizeText returns success for valid image', () async {
      final result = await ocrService.recognizeText('test_images/receipt1.jpg');
      expect(result.success, true);
      expect(result.hasText, true);
    });
    
    test('recognizeText returns failure for missing file', () async {
      final result = await ocrService.recognizeText('nonexistent.jpg');
      expect(result.success, false);
      expect(result.errorMessage, isNotNull);
    });
    
    test('extractText returns non-empty string', () async {
      final text = await ocrService.extractText('test_images/receipt1.jpg');
      expect(text, isNotEmpty);
    });
  });
}
```

---

## 📝 Next Steps

1. **Parse OCR Text** - Extract structured data (amount, merchant, date, items)
2. **Improve Accuracy** - Add image preprocessing (contrast, brightness, rotation)
3. **Smart Detection** - Auto-detect receipt format and adjust parsing
4. **Validation** - Cross-check extracted data for consistency
5. **User Correction** - Allow manual editing of extracted data

---

## 📚 Additional Resources

- **Google ML Kit Docs**: https://developers.google.com/ml-kit/vision/text-recognition
- **Package Repository**: https://pub.dev/packages/google_mlkit_text_recognition
- **Flutter Integration**: https://firebase.google.com/docs/ml-kit/flutter/recognize-text

---

## 🎓 Best Practices

1. ✅ Always dispose `OcrService` after use
2. ✅ Validate image exists before processing
3. ✅ Handle `OcrResult.success` flag
4. ✅ Check `result.hasText` before accessing text
5. ✅ Use try-catch for error handling
6. ✅ Monitor performance with Stopwatch
7. ✅ Cache results for repeated access
8. ✅ Compress images before OCR (Task 4 already does this)
9. ✅ Use appropriate script for language
10. ✅ Provide user feedback during processing

---

**Module Status**: ✅ Complete and Ready for Integration

**Dependencies**: 
- ✅ google_mlkit_text_recognition (already in pubspec.yaml)
- ✅ Camera Capture Module (Task 4)

**Next Task**: Parse OCR text to extract expense fields (amount, merchant, date, items)
