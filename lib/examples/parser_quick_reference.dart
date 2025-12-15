/// QUICK REFERENCE: Receipt Parser API

import '../services/receipt_parser.dart';
import '../services/nlp_helper.dart';
import '../core/models/parsed_receipt.dart';

// ============================================================
// BASIC USAGE
// ============================================================

// Parse receipt text
final parser = ReceiptParser();
final result = await parser.parse(ocrText);

// Access extracted fields
result.merchantName      // Store name
result.totalAmount       // Final total
result.subtotal          // Pre-tax subtotal
result.tax               // Tax amount
result.date              // Transaction date
result.time              // Transaction time
result.items             // List of items
result.paymentMethod     // Payment type
result.receiptNumber     // Receipt number
result.currency          // Currency code

// ============================================================
// VALIDATION & QUALITY
// ============================================================

// Check if valid
if (result.isValid) {
  // Has minimum required fields
}

// Check required fields
if (result.hasRequiredFields) {
  // Has total AND merchant
}

// Validate result
if (parser.validate(result)) {
  // Passes validation rules
}

// Quality assessment
final quality = parser.assessQuality(result);
// Returns: "Excellent", "Good", "Fair", "Poor", or "Invalid"

// Check confidence
if (result.confidence > 0.8) {
  // High confidence - ready to use
} else if (result.confidence > 0.5) {
  // Medium - may need review
} else {
  // Low - needs manual verification
}

// ============================================================
// FORMATTED OUTPUT
// ============================================================

result.formattedTotal    // "$45.67"
result.formattedDate     // "2023-12-15"
result.itemCount         // Number of items

// Per-item formatting
for (final item in result.items) {
  item.name              // "Milk"
  item.formattedPrice    // "$4.99"
  item.formattedTotal    // "$9.98" (price * quantity)
  item.quantity          // 2
}

// ============================================================
// METADATA & DEBUGGING
// ============================================================

result.metadata.strategiesUsed       // ["NLP-Merchant", "Regex-Total", ...]
result.metadata.fieldConfidences     // {"totalAmount": 0.9, "merchantName": 0.8}
result.metadata.durationMs           // Parsing time in milliseconds
result.metadata.warnings             // List of warnings
result.metadata.errors               // List of errors
result.metadata.quality              // "Excellent", "Good", etc.

// ============================================================
// BATCH PROCESSING
// ============================================================

final ocrTexts = [text1, text2, text3];
final results = await parser.parseBatch(ocrTexts);

for (final result in results) {
  print('Merchant: ${result.merchantName}');
  print('Total: ${result.formattedTotal}');
}

// ============================================================
// NLP HELPER UTILITIES
// ============================================================

// String similarity (0.0 - 1.0)
final similarity = NlpHelper.stringSimilarity('walmart', 'Walmart');  // 0.875

// Extract merchant name
final merchant = NlpHelper.extractMerchantName(lines);

// Score merchant name
final score = NlpHelper.scoreMerchantName('WALMART SUPERCENTER');  // 0.8

// Extract numbers from text
final numbers = NlpHelper.extractNumbers('\$45.67 tax \$3.65');  // [45.67, 3.65]

// Find largest amount
final largest = NlpHelper.findLargestAmount(text);  // 45.67

// Check line type
NlpHelper.isLikelyTotalLine('Total: \$45.67')      // true
NlpHelper.isLikelyTaxLine('Tax: \$3.65')           // true
NlpHelper.isLikelyDateLine('Date: 12/15/2023')     // true

// Detect currency
final currency = NlpHelper.detectCurrency('\$45.67');  // "USD"

// Extract payment method
final payment = NlpHelper.extractPaymentMethod('Paid with Visa');  // "Credit Card"

// Calculate overall confidence
final confidence = NlpHelper.calculateOverallConfidence({
  'totalAmount': true,
  'merchantName': true,
  'date': false,
});  // 0.65

// Fuzzy match
final matched = NlpHelper.fuzzyMatch(
  'Wallmart',
  ['Walmart', 'Target', 'Costco'],
  threshold: 0.7,
);  // "Walmart"

// Find context around keyword
final context = NlpHelper.findContext(
  'subtotal 45.67 total 49.32',
  'total',
  contextWords: 3,
);  // "subtotal 45.67 total 49.32"

// ============================================================
// INTEGRATION PATTERNS
// ============================================================

// Pattern 1: Parse and validate
final result = await parser.parse(ocrText);
if (parser.validate(result) && result.confidence > 0.7) {
  // Use the data
}

// Pattern 2: Confidence-based workflow
if (result.confidence > 0.8) {
  autoCreateExpense(result);
} else if (result.confidence > 0.5) {
  showReviewScreen(result);
} else {
  showManualForm(withHints: result);
}

// Pattern 3: Quality-based handling
switch (parser.assessQuality(result)) {
  case 'Excellent':
    autoCreateExpense(result);
    break;
  case 'Good':
    preFillForm(result);
    break;
  case 'Fair':
    partialFill(result);
    break;
  default:
    manualEntry();
}

// Pattern 4: Complete workflow
final imagePath = captureReceipt();
final ocrResult = await ocrService.recognizeText(imagePath);
final parsed = await parser.parse(ocrResult.rawText);

if (parsed.hasRequiredFields) {
  formProvider.setAmount(parsed.totalAmount);
  formProvider.setMerchant(parsed.merchantName);
  formProvider.setDate(parsed.date);
}

// ============================================================
// COMMON RECEIPT PATTERNS
// ============================================================

// Restaurant receipt
final restaurantText = '''
  THE OLIVE GARDEN
  Server: John
  Date: 03/22/2024  7:45 PM
  
  Spaghetti     18.99
  Salad          8.99
  
  Subtotal      27.98
  Tax            2.24
  TOTAL         30.22
''';

// Grocery store receipt
final groceryText = '''
  TARGET STORE #1234
  12/01/2023  3:30 PM
  
  Milk           4.99
  Bread          2.99
  Eggs           3.49
  
  SUBTOTAL      11.47
  TAX            0.92
  TOTAL         12.39
''';

// Gas station receipt
final gasText = '''
  SHELL STATION
  Date: 11/28/2023
  Time: 09:15 AM
  
  Gallons: 12.5
  Price/Gal: \$3.45
  
  Fuel Total    43.13
''';

// ============================================================
// ERROR HANDLING
// ============================================================

// Empty text
if (ocrText.isEmpty) {
  return ParsedReceipt.empty(
    rawText: ocrText,
    errorMessage: 'Empty OCR text',
  );
}

// Check for errors
if (result.metadata.hasErrors) {
  print('Errors: ${result.metadata.errors}');
}

// Check warnings
if (result.metadata.hasWarnings) {
  print('Warnings: ${result.metadata.warnings}');
}

// Handle low confidence
if (result.confidence < 0.3) {
  // Failed parsing - use manual entry
}

// ============================================================
// PERFORMANCE MONITORING
// ============================================================

// Check parsing duration
final duration = result.metadata.durationMs;
print('Parsed in ${duration}ms');

// Typical durations:
// - Simple receipt: < 10ms
// - Medium receipt: 20-50ms
// - Complex receipt: 50-150ms

// ============================================================
// FIELD CONFIDENCE SCORES
// ============================================================

// Per-field confidence
final fieldScores = result.metadata.fieldConfidences;

print('Merchant confidence: ${fieldScores['merchantName']}');
print('Total confidence: ${fieldScores['totalAmount']}');
print('Date confidence: ${fieldScores['date']}');

// Confidence levels:
// - High (> 0.8): Very reliable
// - Medium (0.5-0.8): Good, may need review
// - Low (0.3-0.5): Needs verification
// - None (< 0.3): Failed

// ============================================================
// DATA CONVERSION
// ============================================================

// To Map (for database)
final map = result.toMap();

// From Map
final restored = ParsedReceipt.fromMap(map);

// ============================================================
// TYPICAL WORKFLOW
// ============================================================

/*
Step 1: Camera Capture
  └─> User takes receipt photo

Step 2: OCR Processing
  └─> final ocrResult = await ocrService.recognizeText(imagePath);

Step 3: Parse Text (THIS MODULE)
  └─> final parsed = await parser.parse(ocrResult.rawText);

Step 4: Validate & Check Confidence
  └─> if (parser.validate(parsed) && parsed.confidence > 0.7)

Step 5: Pre-fill Expense Form
  └─> formProvider.setAmount(parsed.totalAmount);
  └─> formProvider.setMerchant(parsed.merchantName);
  └─> formProvider.setDate(parsed.date);

Step 6: User Review & Submit
  └─> User can edit any field before saving

Step 7: Save to Database
  └─> await expenseRepository.create(expense);
*/

// ============================================================
// EXTRACTION STRATEGIES USED
// ============================================================

/*
Merchant Name:
  • NLP scoring of first 5 lines
  • Keyword matching (restaurant, store, etc.)
  • Position weighting (earlier = higher score)
  • Filter non-merchant terms (receipt, invoice, etc.)

Total Amount:
  • Keyword search (total, amount due, balance)
  • Position analysis (favor bottom of receipt)
  • Largest amount fallback

Tax:
  • Keyword matching (tax, vat, gst)
  • Adjacent number extraction

Date:
  • Multiple regex patterns
  • Format validation
  • Past date verification

Items:
  • Line-by-line scoring
  • Name/price/quantity parsing
  • Filter totals and headers
*/
