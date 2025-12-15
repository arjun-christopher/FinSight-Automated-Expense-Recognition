/// QUICK REFERENCE: OCR Service API

import 'package:finsight/services/ocr_service.dart';
import 'package:finsight/core/models/ocr_result.dart';

// ============================================================
// BASIC USAGE
// ============================================================

// Initialize service
final ocrService = OcrService();

// Extract text from image
final result = await ocrService.recognizeText('/path/to/image.jpg');

// Check success
if (result.success) {
  print(result.rawText);  // Full extracted text
} else {
  print(result.errorMessage);  // Error details
}

// Always dispose when done
await ocrService.dispose();

// ============================================================
// QUICK METHODS
// ============================================================

// Just get the text (no metadata)
final text = await ocrService.extractText(imagePath);

// Get lines as a list
final lines = await ocrService.extractLines(imagePath);

// Search for patterns
final prices = await ocrService.searchText(
  imagePath,
  RegExp(r'\$\d+\.\d{2}'),  // Find prices like $12.99
);

// Check if text exists
final hasTotal = await ocrService.containsText(imagePath, 'total');

// ============================================================
// OCR RESULT PROPERTIES
// ============================================================

// result.rawText          - Full extracted text
// result.textBlocks       - List of text blocks with metadata
// result.success          - True if OCR succeeded
// result.errorMessage     - Error details (if failed)
// result.timestamp        - When OCR was performed
// result.confidence       - Average confidence (0.0-1.0)

// Convenience getters:
// result.hasText          - Check if any text extracted
// result.textBlockCount   - Number of text blocks
// result.formattedText    - Text with line breaks
// result.lines            - List of non-empty lines

// ============================================================
// TEXT BLOCK DATA
// ============================================================

for (final block in result.textBlocks) {
  print(block.text);           // Block text
  print(block.lines);          // Lines within block
  print(block.confidence);     // Confidence level
  print(block.boundingBox);    // Position (x, y, width, height)
}

// ============================================================
// COMMON PATTERNS
// ============================================================

// Find prices: $12.99, €45.00, £23.50
RegExp(r'[\$£€]?\s*\d+[.,]\d{2}')

// Find dates: 12/25/2023, 25-12-2023
RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}')

// Find phone numbers: (555) 123-4567
RegExp(r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}')

// Find email: user@example.com
RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b')

// Find time: 10:30 AM, 14:45
RegExp(r'\d{1,2}:\d{2}\s*(?:AM|PM)?')

// ============================================================
// ERROR HANDLING
// ============================================================

try {
  if (!ocrService.isInitialized) {
    throw Exception('Service not ready');
  }
  
  final result = await ocrService.recognizeText(imagePath);
  
  if (!result.success) {
    print('OCR failed: ${result.errorMessage}');
    return;
  }
  
  if (!result.hasText) {
    print('No text detected in image');
    return;
  }
  
  // Process text
  print(result.rawText);
  
} catch (e) {
  print('Error: $e');
} finally {
  await ocrService.dispose();
}

// ============================================================
// FLUTTER WIDGET EXAMPLE
// ============================================================

class OcrButton extends StatelessWidget {
  final String imagePath;
  
  const OcrButton({required this.imagePath});
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final ocrService = OcrService();
        
        // Show loading
        showDialog(
          context: context,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        // Process OCR
        final result = await ocrService.recognizeText(imagePath);
        
        // Hide loading
        Navigator.pop(context);
        
        // Show result
        if (result.success) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('OCR Result'),
              content: Text(result.rawText),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage ?? 'OCR failed')),
          );
        }
        
        await ocrService.dispose();
      },
      child: const Text('Extract Text'),
    );
  }
}

// ============================================================
// PERFORMANCE TIPS
// ============================================================

// 1. Always dispose after use
await ocrService.dispose();

// 2. Process in background/async
Future.microtask(() async {
  final result = await ocrService.recognizeText(imagePath);
  // Handle result
});

// 3. Cache results if needed
final Map<String, OcrResult> cache = {};
if (cache.containsKey(imagePath)) {
  return cache[imagePath]!;
}

// 4. Monitor processing time
final stopwatch = Stopwatch()..start();
final result = await ocrService.recognizeText(imagePath);
stopwatch.stop();
print('OCR took ${stopwatch.elapsedMilliseconds}ms');

// 5. Batch process efficiently
for (final path in imagePaths) {
  final result = await ocrService.recognizeText(path);
  // Process result
  await Future.delayed(Duration(milliseconds: 100)); // Optional throttle
}

// ============================================================
// INTEGRATION WITH CAMERA CAPTURE
// ============================================================

// Step 1: Capture image
final captureState = ref.watch(receiptCaptureProvider);

if (captureState.hasImage) {
  // Step 2: Process with OCR
  final ocrService = OcrService();
  final result = await ocrService.recognizeText(captureState.imagePath!);
  
  if (result.success) {
    // Step 3: Parse text for expense data
    final text = result.rawText;
    print('Extracted: $text');
    
    // TODO: Parse amount, merchant, date, etc.
  }
  
  await ocrService.dispose();
}

// ============================================================
// CUSTOM SCRIPT SUPPORT (Advanced)
// ============================================================

// For Chinese text
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final chineseRecognizer = TextRecognizer(
  script: TextRecognitionScript.chinese,
);

// For Japanese text
final japaneseRecognizer = TextRecognizer(
  script: TextRecognitionScript.japanese,
);

// For Korean text
final koreanRecognizer = TextRecognizer(
  script: TextRecognitionScript.korean,
);

// For Devanagari (Hindi, Sanskrit)
final devanagariRecognizer = TextRecognizer(
  script: TextRecognitionScript.devanagari,
);

// ============================================================
// VALIDATION HELPERS
// ============================================================

bool isValidOcrResult(OcrResult result) {
  return result.success &&
         result.hasText &&
         result.rawText.length > 10 &&
         (result.confidence ?? 0.0) > 0.5;
}

// ============================================================
// TYPICAL WORKFLOW
// ============================================================

/*
1. User captures receipt (Camera Capture Module)
   └─> imagePath = '/path/to/receipt.jpg'

2. Process with OCR (This Module)
   └─> result = await ocrService.recognizeText(imagePath)

3. Parse extracted text (Future Task)
   └─> amount, merchant, date = parseReceiptData(result.rawText)

4. Pre-fill expense form (Task 3 Integration)
   └─> ref.read(expenseFormProvider.notifier).setAmount(amount)

5. Save to database (Task 2 Integration)
   └─> await expenseRepository.create(expense)
*/

// ============================================================
// TROUBLESHOOTING
// ============================================================

/*
Issue: No text detected
Solution: 
  - Check image quality and lighting
  - Ensure text is upright
  - Verify image file exists and is valid

Issue: Low confidence (< 0.5)
Solution:
  - Improve image resolution
  - Better lighting conditions
  - Reduce glare and shadows

Issue: Wrong script detected
Solution:
  - Use appropriate TextRecognitionScript
  - e.g., TextRecognizer(script: TextRecognitionScript.chinese)

Issue: Slow processing (> 3 seconds)
Solution:
  - Compress image before OCR
  - Check image size (should be < 2MB)
  - Consider batch processing limits
*/
