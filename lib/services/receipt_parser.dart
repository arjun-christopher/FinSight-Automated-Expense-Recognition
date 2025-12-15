import 'dart:math';
import '../core/models/parsed_receipt.dart';
import 'nlp_helper.dart';

/// Hybrid Receipt Parser
/// Combines rule-based regex patterns with NLP techniques for intelligent extraction
class ReceiptParser {
  /// Parse raw OCR text into structured receipt data
  ///
  /// Uses a hybrid approach:
  /// 1. Regex patterns for amounts, dates, numbers (rule-based)
  /// 2. NLP for merchant extraction and text understanding (ML-like)
  /// 3. Scoring and validation to select best candidates
  Future<ParsedReceipt> parse(String ocrText) async {
    final stopwatch = Stopwatch()..start();

    if (ocrText.trim().isEmpty) {
      return ParsedReceipt.empty(
        rawText: ocrText,
        errorMessage: 'Empty OCR text',
      );
    }

    final lines = _splitIntoLines(ocrText);
    final metadata = ParsingMetadata(parseTime: DateTime.now());
    final fieldConfidences = <String, double>{};
    final strategiesUsed = <String>[];

    // Extract fields using hybrid approach
    double? totalAmount;
    double? subtotal;
    double? tax;
    String? merchantName;
    DateTime? date;
    String? time;
    List<ReceiptItem> items = [];
    String? paymentMethod;
    String? receiptNumber;
    String? currency;

    try {
      // 1. Extract merchant name (NLP-based)
      final merchantResult = _extractMerchant(lines);
      merchantName = merchantResult['value'];
      if (merchantName != null) {
        fieldConfidences['merchantName'] = merchantResult['confidence'] ?? 0.5;
        strategiesUsed.add('NLP-Merchant');
      }

      // 2. Extract total amount (Regex + NLP hybrid)
      final totalResult = _extractTotalAmount(lines);
      totalAmount = totalResult['value'];
      if (totalAmount != null) {
        fieldConfidences['totalAmount'] = totalResult['confidence'] ?? 0.7;
        strategiesUsed.add('Regex-Total');
      }

      // 3. Extract tax (Regex + keyword matching)
      final taxResult = _extractTax(lines);
      tax = taxResult['value'];
      if (tax != null) {
        fieldConfidences['tax'] = taxResult['confidence'] ?? 0.6;
        strategiesUsed.add('Regex-Tax');
      }

      // 4. Calculate subtotal if not found
      if (subtotal == null && totalAmount != null && tax != null) {
        subtotal = totalAmount - tax;
        fieldConfidences['subtotal'] = 0.8;
        strategiesUsed.add('Calculated-Subtotal');
      }

      // 5. Extract date (Regex patterns)
      final dateResult = _extractDate(lines);
      date = dateResult['value'];
      if (date != null) {
        fieldConfidences['date'] = dateResult['confidence'] ?? 0.7;
        strategiesUsed.add('Regex-Date');
      }

      // 6. Extract time (Regex patterns)
      time = _extractTime(ocrText);
      if (time != null) {
        fieldConfidences['time'] = 0.7;
        strategiesUsed.add('Regex-Time');
      }

      // 7. Extract items (NLP scoring)
      items = _extractItems(lines);
      if (items.isNotEmpty) {
        fieldConfidences['items'] = 0.6;
        strategiesUsed.add('NLP-Items');
      }

      // 8. Extract payment method (NLP)
      paymentMethod = NlpHelper.extractPaymentMethod(ocrText);
      if (paymentMethod != null) {
        fieldConfidences['paymentMethod'] = 0.6;
        strategiesUsed.add('NLP-Payment');
      }

      // 9. Extract receipt number (Regex)
      receiptNumber = _extractReceiptNumber(ocrText);
      if (receiptNumber != null) {
        fieldConfidences['receiptNumber'] = 0.5;
        strategiesUsed.add('Regex-ReceiptNumber');
      }

      // 10. Detect currency
      currency = NlpHelper.detectCurrency(ocrText) ?? 'USD';

    } catch (e) {
      metadata.errors.add('Parsing error: $e');
    }

    stopwatch.stop();

    // Calculate overall confidence
    final overallConfidence = NlpHelper.calculateOverallConfidence({
      'totalAmount': totalAmount != null,
      'merchantName': merchantName != null,
      'date': date != null,
      'tax': tax != null,
      'items': items.isNotEmpty,
    });

    return ParsedReceipt(
      totalAmount: totalAmount,
      subtotal: subtotal,
      tax: tax,
      merchantName: merchantName,
      date: date,
      time: time,
      items: items,
      paymentMethod: paymentMethod,
      receiptNumber: receiptNumber,
      currency: currency,
      confidence: overallConfidence,
      rawText: ocrText,
      metadata: ParsingMetadata(
        parseTime: metadata.parseTime,
        strategiesUsed: strategiesUsed,
        fieldConfidences: fieldConfidences,
        warnings: metadata.warnings,
        errors: metadata.errors,
        durationMs: stopwatch.elapsedMilliseconds,
      ),
    );
  }

  /// Split text into clean lines
  List<String> _splitIntoLines(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Extract merchant name using NLP
  Map<String, dynamic> _extractMerchant(List<String> lines) {
    final merchantName = NlpHelper.extractMerchantName(lines);

    if (merchantName == null) {
      return {'value': null, 'confidence': 0.0};
    }

    // Calculate confidence based on score
    final confidence = NlpHelper.scoreMerchantName(merchantName);

    return {'value': merchantName, 'confidence': confidence};
  }

  /// Extract total amount using regex and context
  Map<String, dynamic> _extractTotalAmount(List<String> lines) {
    final candidates = <MapEntry<double, double>>[]; // value, confidence

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      // Strategy 1: Lines with "total" keyword
      if (NlpHelper.isLikelyTotalLine(line)) {
        final numbers = NlpHelper.extractNumbers(line);
        if (numbers.isNotEmpty) {
          // Last number on total line is usually the total
          final amount = numbers.last;
          candidates.add(MapEntry(amount, 0.9));
        }
      }

      // Strategy 2: Large amounts toward the end
      if (i > lines.length * 0.5) { // Bottom half of receipt
        final numbers = NlpHelper.extractNumbers(line);
        for (final number in numbers) {
          if (number > 5.0) { // Reasonable minimum for total
            final positionScore = (i / lines.length) * 0.5; // Favor bottom
            candidates.add(MapEntry(number, 0.5 + positionScore));
          }
        }
      }
    }

    if (candidates.isEmpty) {
      // Fallback: largest amount in entire text
      final largestAmount = NlpHelper.findLargestAmount(lines.join('\n'));
      if (largestAmount != null) {
        return {'value': largestAmount, 'confidence': 0.4};
      }
      return {'value': null, 'confidence': 0.0};
    }

    // Select best candidate
    candidates.sort((a, b) => b.value.compareTo(a.value));
    final best = candidates.first;

    return {'value': best.key, 'confidence': best.value};
  }

  /// Extract tax amount
  Map<String, dynamic> _extractTax(List<String> lines) {
    for (final line in lines) {
      if (NlpHelper.isLikelyTaxLine(line)) {
        final numbers = NlpHelper.extractNumbers(line);
        if (numbers.isNotEmpty) {
          return {'value': numbers.last, 'confidence': 0.8};
        }
      }
    }

    return {'value': null, 'confidence': 0.0};
  }

  /// Extract date using multiple patterns
  Map<String, dynamic> _extractDate(List<String> lines) {
    // Date patterns to try
    final patterns = [
      // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'),
      // MM/DD/YY or DD/MM/YY
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2})'),
      // YYYY-MM-DD (ISO format)
      RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'),
      // Month DD, YYYY (e.g., Jan 15, 2024)
      RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+(\d{1,2}),?\s+(\d{4})', 
             caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final date = _parseDate(match, pattern);
          if (date != null) {
            // Higher confidence if line contains date keywords
            final confidence = NlpHelper.isLikelyDateLine(line) ? 0.9 : 0.7;
            return {'value': date, 'confidence': confidence};
          }
        }
      }
    }

    return {'value': null, 'confidence': 0.0};
  }

  /// Parse date from regex match
  DateTime? _parseDate(RegExpMatch match, RegExp pattern) {
    try {
      final patternStr = pattern.pattern;

      // ISO format: YYYY-MM-DD
      if (patternStr.contains('(\\d{4})[/-](\\d{1,2})[/-](\\d{1,2})')) {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      }

      // Month name format
      if (patternStr.contains('Jan|Feb|Mar')) {
        final monthStr = match.group(1)!.substring(0, 3).toLowerCase();
        final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 
                       'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
        final month = months.indexOf(monthStr) + 1;
        final day = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      }

      // MM/DD/YYYY or DD/MM/YYYY
      final part1 = int.parse(match.group(1)!);
      final part2 = int.parse(match.group(2)!);
      var year = int.parse(match.group(3)!);

      // Handle 2-digit year
      if (year < 100) {
        year += year < 50 ? 2000 : 1900;
      }

      // Try MM/DD/YYYY first (US format)
      if (part1 <= 12 && part2 <= 31) {
        return DateTime(year, part1, part2);
      }

      // Try DD/MM/YYYY (international format)
      if (part2 <= 12 && part1 <= 31) {
        return DateTime(year, part2, part1);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extract time
  String? _extractTime(String text) {
    // 12-hour format (e.g., 10:30 AM, 2:45 PM)
    var pattern = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);
    var match = pattern.firstMatch(text);
    if (match != null) {
      return match.group(0);
    }

    // 24-hour format (e.g., 14:30, 09:15)
    pattern = RegExp(r'(\d{2}):(\d{2})(?![\d/])');
    match = pattern.firstMatch(text);
    if (match != null) {
      final hour = int.parse(match.group(1)!);
      if (hour >= 0 && hour <= 23) {
        return match.group(0);
      }
    }

    return null;
  }

  /// Extract receipt number
  String? _extractReceiptNumber(String text) {
    // Common patterns for receipt numbers
    final patterns = [
      RegExp(r'Receipt\s*#?\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'Transaction\s*#?\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'Order\s*#?\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'#\s*(\d{4,})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  /// Extract line items using NLP scoring
  List<ReceiptItem> _extractItems(List<String> lines) {
    final items = <ReceiptItem>[];

    for (final line in lines) {
      final score = NlpHelper.scoreItemLine(line);

      if (score > 0.5) {
        final item = _parseItemLine(line);
        if (item != null) {
          items.add(item);
        }
      }
    }

    return items;
  }

  /// Parse a line into an item
  ReceiptItem? _parseItemLine(String line) {
    try {
      // Extract price (last number on line)
      final numbers = NlpHelper.extractNumbers(line);
      if (numbers.isEmpty) return null;

      final price = numbers.last;

      // Extract quantity if present
      var quantity = 1;
      final qtyPattern = RegExp(r'(\d+)\s*x\b|x\s*(\d+)', caseSensitive: false);
      final qtyMatch = qtyPattern.firstMatch(line);
      if (qtyMatch != null) {
        quantity = int.parse(qtyMatch.group(1) ?? qtyMatch.group(2) ?? '1');
      }

      // Extract item name (everything before the price)
      var name = line.split(RegExp(r'\d+[.,]\d{2}'))[0].trim();
      
      // Remove quantity from name if present
      name = name.replaceAll(qtyPattern, '').trim();
      
      if (name.isEmpty) return null;

      return ReceiptItem(
        name: name,
        price: price / quantity,
        quantity: quantity,
        total: price,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse multiple receipts in batch
  Future<List<ParsedReceipt>> parseBatch(List<String> ocrTexts) async {
    final results = <ParsedReceipt>[];

    for (final text in ocrTexts) {
      final result = await parse(text);
      results.add(result);
    }

    return results;
  }

  /// Validate a parsed receipt
  bool validate(ParsedReceipt receipt) {
    // Must have either total or merchant
    if (receipt.totalAmount == null && receipt.merchantName == null) {
      return false;
    }

    // If has tax, it should be less than total
    if (receipt.tax != null && receipt.totalAmount != null) {
      if (receipt.tax! >= receipt.totalAmount!) {
        return false;
      }
    }

    // Date shouldn't be in the future
    if (receipt.date != null) {
      if (receipt.date!.isAfter(DateTime.now())) {
        return false;
      }
    }

    return true;
  }

  /// Get parsing quality assessment
  String assessQuality(ParsedReceipt receipt) {
    if (!receipt.isValid) return 'Invalid';
    
    final fieldsExtracted = [
      receipt.totalAmount != null,
      receipt.merchantName != null,
      receipt.date != null,
      receipt.tax != null,
      receipt.items.isNotEmpty,
    ].where((e) => e).length;

    if (fieldsExtracted >= 4) return 'Excellent';
    if (fieldsExtracted >= 3) return 'Good';
    if (fieldsExtracted >= 2) return 'Fair';
    return 'Poor';
  }
}
