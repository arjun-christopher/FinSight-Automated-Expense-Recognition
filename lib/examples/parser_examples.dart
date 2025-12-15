/// COMPREHENSIVE EXAMPLES: Receipt Parser with Test Cases

import '../services/receipt_parser.dart';
import '../core/models/parsed_receipt.dart';

// ============================================================
// EXAMPLE 1: Basic Parser Usage
// ============================================================

Future<void> basicParserExample() async {
  final parser = ReceiptParser();

  final ocrText = '''
    WALMART SUPERCENTER
    123 Main Street
    Date: 12/15/2023
    
    Milk                 4.99
    Bread                2.99
    Eggs                 3.49
    
    Subtotal           11.47
    Tax                 0.92
    Total              12.39
    
    Payment: Credit Card
  ''';

  final result = await parser.parse(ocrText);

  print('✅ Parsing Complete');
  print('Merchant: ${result.merchantName}');
  print('Total: ${result.formattedTotal}');
  print('Date: ${result.formattedDate}');
  print('Tax: \$${result.tax?.toStringAsFixed(2)}');
  print('Items: ${result.itemCount}');
  print('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
}

// ============================================================
// EXAMPLE 2: Restaurant Receipt
// ============================================================

Future<void> restaurantReceiptExample() async {
  final parser = ReceiptParser();

  final ocrText = '''
    THE OLIVE GARDEN
    Italian Restaurant
    Server: John
    Table: 15
    
    03/22/2024  7:45 PM
    
    Spaghetti Carbonara     18.99
    Caesar Salad             8.99
    Tiramisu                 6.99
    Coffee                   2.99
    
    Subtotal               37.96
    Tax (8.5%)              3.23
    -------------------------
    TOTAL                  41.19
    
    Thank you for dining with us!
  ''';

  final result = await parser.parse(ocrText);

  print('\n=== Restaurant Receipt ===');
  print('Merchant: ${result.merchantName}');
  print('Total: ${result.formattedTotal}');
  print('Date: ${result.formattedDate}');
  print('Time: ${result.time}');
  print('Tax: \$${result.tax?.toStringAsFixed(2)}');
  print('Items:');
  for (final item in result.items) {
    print('  - ${item.name}: ${item.formattedPrice} x${item.quantity}');
  }
}

// ============================================================
// EXAMPLE 3: Gas Station Receipt
// ============================================================

Future<void> gasStationReceiptExample() async {
  final parser = ReceiptParser();

  final ocrText = '''
    SHELL STATION
    789 Highway Rd
    
    Date: 11/28/2023
    Time: 09:15 AM
    
    Pump #3
    Regular Unleaded
    
    Gallons: 12.5
    Price/Gal: \$3.45
    
    Fuel Total         43.13
    
    Receipt #: 987654
    Payment: Debit Card
  ''';

  final result = await parser.parse(ocrText);

  print('\n=== Gas Station Receipt ===');
  print('Merchant: ${result.merchantName}');
  print('Total: ${result.formattedTotal}');
  print('Date: ${result.formattedDate}');
  print('Time: ${result.time}');
  print('Receipt #: ${result.receiptNumber}');
  print('Payment: ${result.paymentMethod}');
}

// ============================================================
// EXAMPLE 4: Grocery Store with Multiple Items
// ============================================================

Future<void> groceryStoreExample() async {
  final parser = ReceiptParser();

  final ocrText = '''
    TARGET STORE #1234
    5678 Oak Avenue
    
    12/01/2023  3:30 PM
    
    PRODUCE
    Bananas 2x              2.98
    Apples 1.5lb            4.47
    
    DAIRY
    Milk Gallon             4.99
    Cheese Block            5.99
    
    BAKERY
    Bread Wheat             2.99
    Bagels 6pk              3.99
    
    FROZEN
    Ice Cream               6.99
    Pizza                   7.99
    
    SUBTOTAL              40.39
    TAX                    3.23
    TOTAL                 43.62
    
    VISA ****1234
    Thank you!
  ''';

  final result = await parser.parse(ocrText);

  print('\n=== Grocery Store Receipt ===');
  print('Merchant: ${result.merchantName}');
  print('Total: ${result.formattedTotal}');
  print('Date: ${result.formattedDate}');
  print('Tax: \$${result.tax?.toStringAsFixed(2)}');
  print('Items: ${result.itemCount}');
  print('Payment: ${result.paymentMethod}');
  
  print('\nExtracted Items:');
  for (final item in result.items) {
    print('  ${item}');
  }
}

// ============================================================
// EXAMPLE 5: Coffee Shop Receipt
// ============================================================

Future<void> coffeeShopExample() async {
  final parser = ReceiptParser();

  final ocrText = '''
    STARBUCKS COFFEE
    
    Order #: 456
    01/15/2024 8:45 AM
    
    Grande Latte            5.45
    Blueberry Muffin        3.95
    
    Subtotal                9.40
    Tax                     0.75
    Total                  10.15
    
    Paid with Apple Pay
  ''';

  final result = await parser.parse(ocrText);

  print('\n=== Coffee Shop Receipt ===');
  print('Merchant: ${result.merchantName}');
  print('Total: ${result.formattedTotal}');
  print('Items: ${result.itemCount}');
  print('Payment: ${result.paymentMethod}');
}

// ============================================================
// EXAMPLE 6: Batch Processing Multiple Receipts
// ============================================================

Future<void> batchProcessingExample() async {
  final parser = ReceiptParser();

  final receipts = [
    'WALMART\nDate: 12/15/2023\nTotal: \$45.67',
    'TARGET\nDate: 12/16/2023\nTotal: \$32.10',
    'KROGER\nDate: 12/17/2023\nTotal: \$28.99',
  ];

  final results = await parser.parseBatch(receipts);

  print('\n=== Batch Processing Results ===');
  for (var i = 0; i < results.length; i++) {
    final result = results[i];
    print('Receipt ${i + 1}:');
    print('  Merchant: ${result.merchantName}');
    print('  Total: ${result.formattedTotal}');
    print('  Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
  }
}

// ============================================================
// EXAMPLE 7: Integration with OCR Service
// ============================================================

Future<void> ocrIntegrationExample(String imagePath) async {
  // Assume OCR has already been performed
  // (This would come from Task 5 - OcrService)
  
  final ocrService = OcrService(); // From Task 5
  final parser = ReceiptParser();

  print('Processing receipt...');

  // Step 1: Extract text with OCR
  final ocrResult = await ocrService.recognizeText(imagePath);

  if (!ocrResult.success) {
    print('OCR failed: ${ocrResult.errorMessage}');
    await ocrService.dispose();
    return;
  }

  print('✅ OCR complete - ${ocrResult.textBlockCount} blocks');

  // Step 2: Parse extracted text
  final parsed = await parser.parse(ocrResult.rawText);

  print('✅ Parsing complete');

  // Step 3: Display results
  print('\n📄 Receipt Details:');
  print('Merchant: ${parsed.merchantName ?? "Unknown"}');
  print('Amount: ${parsed.formattedTotal}');
  print('Date: ${parsed.formattedDate ?? "Unknown"}');
  print('Tax: \$${parsed.tax?.toStringAsFixed(2) ?? "N/A"}');
  
  if (parsed.items.isNotEmpty) {
    print('\nItems:');
    for (final item in parsed.items) {
      print('  • ${item.name} - ${item.formattedPrice}');
    }
  }

  print('\n📊 Quality: ${parser.assessQuality(parsed)}');
  print('Confidence: ${(parsed.confidence * 100).toStringAsFixed(1)}%');

  await ocrService.dispose();
}

// Mock OcrService for example (would use real one from Task 5)
class OcrService {
  Future<OcrResult> recognizeText(String path) async {
    // Mock implementation
    return OcrResult(
      success: true,
      rawText: 'Sample OCR text',
      textBlockCount: 5,
    );
  }

  Future<void> dispose() async {}
}

class OcrResult {
  final bool success;
  final String rawText;
  final int textBlockCount;
  final String? errorMessage;

  OcrResult({
    required this.success,
    required this.rawText,
    required this.textBlockCount,
    this.errorMessage,
  });
}

// ============================================================
// EXAMPLE 8: Validation and Quality Assessment
// ============================================================

Future<void> validationExample() async {
  final parser = ReceiptParser();

  final ocrText = '''
    BEST BUY
    Electronics Store
    
    Date: 06/15/2023
    
    Laptop Computer      899.99
    Mouse                 24.99
    Keyboard              49.99
    
    Subtotal            974.97
    Tax (7%)             68.25
    Total             1,043.22
    
    Payment: Credit Card
  ''';

  final result = await parser.parse(ocrText);

  // Validate the result
  final isValid = parser.validate(result);
  print('✅ Valid: $isValid');

  // Assess quality
  final quality = parser.assessQuality(result);
  print('📊 Quality: $quality');

  // Check confidence
  print('🎯 Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');

  // Check required fields
  print('Required fields present: ${result.hasRequiredFields}');

  // Field-by-field confidence
  print('\n📈 Field Confidence Scores:');
  for (final entry in result.metadata.fieldConfidences.entries) {
    print('  ${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%');
  }
}

// ============================================================
// EXAMPLE 9: Error Handling
// ============================================================

Future<void> errorHandlingExample() async {
  final parser = ReceiptParser();

  // Empty text
  var result = await parser.parse('');
  print('Empty text - Valid: ${result.isValid}');
  print('Error: ${result.metadata.errors.join(", ")}');

  // Gibberish text
  result = await parser.parse('asdfghjkl qwertyuiop 12345');
  print('\nGibberish - Valid: ${result.isValid}');
  print('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');

  // Partial data
  result = await parser.parse('WALMART\n\$45.67');
  print('\nPartial data - Valid: ${result.isValid}');
  print('Merchant: ${result.merchantName}');
  print('Total: ${result.formattedTotal}');
}

// ============================================================
// EXAMPLE 10: Complete Workflow (Camera → OCR → Parse → Form)
// ============================================================

Future<void> completeWorkflowExample() async {
  print('=== COMPLETE WORKFLOW ===\n');

  // Simulated OCR text from camera capture
  final ocrText = '''
    WHOLE FOODS MARKET
    456 Green Street
    
    Date: 12/15/2023
    Time: 2:30 PM
    
    Organic Apples          6.99
    Spinach                 3.49
    Almond Milk             4.99
    Quinoa                  7.99
    
    Subtotal              23.46
    Tax                    1.88
    Total                 25.34
    
    Payment: Visa
    Receipt #123456
  ''';

  print('Step 1: Parse receipt text...');
  final parser = ReceiptParser();
  final parsed = await parser.parse(ocrText);

  print('✅ Parsed successfully\n');

  print('Step 2: Extract data for expense form...');
  
  // Prepare data for expense form (Task 3)
  final expenseData = {
    'amount': parsed.totalAmount,
    'merchant': parsed.merchantName,
    'date': parsed.date,
    'category': 'Groceries', // Could be auto-detected
    'paymentMethod': parsed.paymentMethod,
    'notes': 'Auto-parsed from receipt',
  };

  print('Expense Form Data:');
  expenseData.forEach((key, value) {
    print('  $key: $value');
  });

  print('\nStep 3: Ready to create expense entry!');
  print('Confidence: ${(parsed.confidence * 100).toStringAsFixed(1)}%');
  
  // Would then call:
  // ref.read(expenseFormProvider.notifier).setAmount(parsed.totalAmount);
  // ref.read(expenseFormProvider.notifier).setMerchant(parsed.merchantName);
  // ref.read(expenseFormProvider.notifier).setDate(parsed.date);
}

// ============================================================
// TEST CASES
// ============================================================

Future<void> runTestCases() async {
  print('🧪 RUNNING TEST CASES\n');
  print('=' * 50);

  final parser = ReceiptParser();

  // Test Case 1: Complete receipt
  print('\n1. Complete Receipt Test');
  var result = await parser.parse('''
    BEST BUY
    05/10/2023
    
    Laptop              899.99
    Mouse                24.99
    
    Subtotal           924.98
    Tax                 74.00
    Total              998.98
  ''');
  
  assert(result.merchantName != null, 'Should extract merchant');
  assert(result.totalAmount != null, 'Should extract total');
  assert(result.date != null, 'Should extract date');
  assert(result.tax != null, 'Should extract tax');
  print('✅ PASSED - All fields extracted');

  // Test Case 2: Minimal receipt
  print('\n2. Minimal Receipt Test');
  result = await parser.parse('WALMART\nTotal: \$45.67');
  assert(result.merchantName != null, 'Should extract merchant');
  assert(result.totalAmount != null, 'Should extract total');
  print('✅ PASSED - Minimal data extracted');

  // Test Case 3: Date formats
  print('\n3. Date Format Test');
  final dateFormats = [
    '12/15/2023',
    '15-12-2023',
    '2023-12-15',
    'Dec 15, 2023',
  ];
  
  for (final dateStr in dateFormats) {
    result = await parser.parse('Test Store\n$dateStr\nTotal: \$10.00');
    assert(result.date != null, 'Should parse $dateStr');
  }
  print('✅ PASSED - All date formats parsed');

  // Test Case 4: Amount patterns
  print('\n4. Amount Pattern Test');
  final amountPatterns = [
    '\$45.67',
    '45.67',
    'Total: 45.67',
    'TOTAL \$45.67',
  ];
  
  for (final pattern in amountPatterns) {
    result = await parser.parse('Test Store\n$pattern');
    assert(result.totalAmount != null, 'Should parse $pattern');
  }
  print('✅ PASSED - All amount patterns parsed');

  // Test Case 5: Validation
  print('\n5. Validation Test');
  result = await parser.parse('STORE\nTotal: \$100.00\nTax: \$8.00');
  assert(parser.validate(result), 'Valid receipt should pass');
  print('✅ PASSED - Validation works');

  print('\n' + '=' * 50);
  print('🎉 ALL TESTS PASSED!\n');
}

// ============================================================
// MAIN DEMO
// ============================================================

Future<void> runAllExamples() async {
  print('📋 RECEIPT PARSER EXAMPLES\n');

  await basicParserExample();
  await restaurantReceiptExample();
  await gasStationReceiptExample();
  await groceryStoreExample();
  await coffeeShopExample();
  await batchProcessingExample();
  await validationExample();
  await errorHandlingExample();
  await completeWorkflowExample();
  
  print('\n' + '=' * 50);
  await runTestCases();
}
