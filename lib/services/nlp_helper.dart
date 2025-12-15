/// NLP Helper utilities for intelligent text processing and analysis
/// Provides text similarity, keyword matching, and scoring algorithms

import 'dart:math';

/// NLP Helper class for text analysis and intelligent extraction
class NlpHelper {
  /// Common merchant keywords by category
  static const Map<String, List<String>> merchantKeywords = {
    'restaurant': ['restaurant', 'cafe', 'bistro', 'diner', 'grill', 'kitchen', 'bar', 'pub', 'pizzeria', 'burger'],
    'grocery': ['market', 'grocery', 'supermarket', 'foods', 'mart', 'store'],
    'gas': ['gas', 'fuel', 'petroleum', 'shell', 'chevron', 'exxon', 'bp', 'mobil'],
    'retail': ['store', 'shop', 'boutique', 'outlet', 'center', 'mall'],
    'pharmacy': ['pharmacy', 'drug', 'cvs', 'walgreens', 'rite aid'],
    'coffee': ['coffee', 'starbucks', 'dunkin', 'cafe', 'espresso'],
  };

  /// Common receipt keywords that are NOT merchant names
  static const List<String> nonMerchantKeywords = [
    'receipt', 'invoice', 'bill', 'ticket', 'order', 'transaction',
    'total', 'subtotal', 'tax', 'amount', 'payment', 'cash', 'credit',
    'thank you', 'thanks', 'welcome', 'customer', 'cashier', 'server',
    'date', 'time', 'number', '#', 'no.', 'phone', 'address', 'www',
  ];

  /// Date-related keywords
  static const List<String> dateKeywords = [
    'date', 'time', 'on', 'at',
  ];

  /// Total amount keywords
  static const List<String> totalKeywords = [
    'total', 'amount due', 'balance', 'grand total', 'amount',
  ];

  /// Tax keywords
  static const List<String> taxKeywords = [
    'tax', 'vat', 'gst', 'sales tax',
  ];

  /// Calculate Levenshtein distance between two strings
  /// Returns similarity score (0.0 = completely different, 1.0 = identical)
  static double stringSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1.toLowerCase(), s2.toLowerCase());
    final maxLength = max(s1.length, s2.length);
    
    return 1.0 - (distance / maxLength);
  }

  /// Calculate Levenshtein distance
  static int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    final matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    for (var i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }

    return matrix[len1][len2];
  }

  /// Calculate word overlap score between two texts
  static double wordOverlapScore(String text1, String text2) {
    final words1 = _tokenize(text1);
    final words2 = _tokenize(text2);

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final commonWords = words1.where((word) => words2.contains(word)).length;
    final totalWords = max(words1.length, words2.length);

    return commonWords / totalWords;
  }

  /// Tokenize text into words
  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && word.length > 1)
        .toList();
  }

  /// Score a potential merchant name (0.0-1.0)
  static double scoreMerchantName(String text) {
    var score = 0.5; // Base score

    final textLower = text.toLowerCase();

    // Boost if contains merchant keywords
    for (final category in merchantKeywords.values) {
      for (final keyword in category) {
        if (textLower.contains(keyword)) {
          score += 0.2;
          break;
        }
      }
    }

    // Penalize if contains non-merchant keywords
    for (final keyword in nonMerchantKeywords) {
      if (textLower.contains(keyword)) {
        score -= 0.3;
        break;
      }
    }

    // Boost if it's on the first few lines (typical merchant position)
    // (This will be handled by caller with line position info)

    // Penalize if too short or too long
    if (text.length < 3) score -= 0.3;
    if (text.length > 50) score -= 0.2;

    // Boost if contains capital letters (brand names often capitalized)
    if (text != text.toLowerCase() && text != text.toUpperCase()) {
      score += 0.1;
    }

    // Penalize if all uppercase (might be a header/category)
    if (text == text.toUpperCase() && text.length > 3) {
      score -= 0.1;
    }

    // Penalize if contains numbers (unlikely for merchant name)
    if (RegExp(r'\d').hasMatch(text)) {
      score -= 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Extract the most likely merchant name from lines
  static String? extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return null;

    final candidates = <MapEntry<String, double>>[];

    // Score first 5 lines (merchant name usually near top)
    for (var i = 0; i < min(5, lines.length); i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.length < 3) continue;

      var score = scoreMerchantName(line);

      // Boost score for earlier lines
      score += (5 - i) * 0.1;

      candidates.add(MapEntry(line, score));
    }

    if (candidates.isEmpty) return null;

    // Sort by score and return best candidate
    candidates.sort((a, b) => b.value.compareTo(a.value));

    return candidates.first.value > 0.5 ? candidates.first.key : null;
  }

  /// Check if line contains a total amount indicator
  static bool isLikelyTotalLine(String line) {
    final lineLower = line.toLowerCase();

    // Check for total keywords
    for (final keyword in totalKeywords) {
      if (lineLower.contains(keyword)) return true;
    }

    // Check pattern: word followed by amount
    if (RegExp(r'(total|amount|balance|due)\s*[:=]?\s*[\$£€]?\s*\d+[.,]\d{2}', 
               caseSensitive: false).hasMatch(line)) {
      return true;
    }

    return false;
  }

  /// Check if line contains a tax indicator
  static bool isLikelyTaxLine(String line) {
    final lineLower = line.toLowerCase();

    for (final keyword in taxKeywords) {
      if (lineLower.contains(keyword)) return true;
    }

    return false;
  }

  /// Check if line contains a date
  static bool isLikelyDateLine(String line) {
    // Check for date patterns
    if (RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}').hasMatch(line)) {
      return true;
    }

    // Check for date keywords
    final lineLower = line.toLowerCase();
    for (final keyword in dateKeywords) {
      if (lineLower.contains(keyword)) return true;
    }

    return false;
  }

  /// Extract numbers from text
  static List<double> extractNumbers(String text) {
    final numbers = <double>[];
    
    // Pattern for amounts: optional currency symbol, digits with optional decimal
    final pattern = RegExp(r'[\$£€]?\s*(\d+[.,]\d{2,})|\b(\d+\.\d{2})\b');
    final matches = pattern.allMatches(text);

    for (final match in matches) {
      final numStr = (match.group(1) ?? match.group(2) ?? '')
          .replaceAll(',', '')
          .replaceAll(' ', '');
      final num = double.tryParse(numStr);
      if (num != null) numbers.add(num);
    }

    return numbers;
  }

  /// Find the largest number in text (likely total)
  static double? findLargestAmount(String text) {
    final numbers = extractNumbers(text);
    if (numbers.isEmpty) return null;
    return numbers.reduce(max);
  }

  /// Clean and normalize text
  static String normalizeText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')  // Multiple spaces to single space
        .replaceAll(RegExp(r'[^\w\s\d.,\$£€-]'), '') // Remove special chars
        .trim();
  }

  /// Calculate confidence score based on extracted fields
  static double calculateOverallConfidence(Map<String, bool> extractedFields) {
    if (extractedFields.isEmpty) return 0.0;

    final weights = {
      'totalAmount': 0.35,
      'merchantName': 0.30,
      'date': 0.15,
      'tax': 0.10,
      'items': 0.10,
    };

    var score = 0.0;
    for (final entry in extractedFields.entries) {
      if (entry.value) {
        score += weights[entry.key] ?? 0.05;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Score a line for being a potential item line
  static double scoreItemLine(String line) {
    var score = 0.0;

    // Must contain a price
    if (!RegExp(r'\d+[.,]\d{2}').hasMatch(line)) return 0.0;

    // Boost if contains quantity indicators
    if (RegExp(r'\bx\d+\b|\d+x\b|\bqty\b', caseSensitive: false).hasMatch(line)) {
      score += 0.3;
    }

    // Boost if has reasonable length
    if (line.length > 10 && line.length < 80) {
      score += 0.2;
    }

    // Boost if starts with item-like text (letters)
    if (RegExp(r'^[a-zA-Z]').hasMatch(line)) {
      score += 0.2;
    }

    // Penalize if contains total/tax keywords
    final lineLower = line.toLowerCase();
    if (totalKeywords.any((kw) => lineLower.contains(kw)) ||
        taxKeywords.any((kw) => lineLower.contains(kw))) {
      score -= 0.5;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Detect currency from text
  static String? detectCurrency(String text) {
    if (text.contains('\$')) return 'USD';
    if (text.contains('€')) return 'EUR';
    if (text.contains('£')) return 'GBP';
    if (text.contains('¥')) return 'JPY';
    if (text.contains('₹')) return 'INR';
    return null;
  }

  /// Extract payment method
  static String? extractPaymentMethod(String text) {
    final textLower = text.toLowerCase();

    if (textLower.contains('cash')) return 'Cash';
    if (textLower.contains('credit') || textLower.contains('visa') || 
        textLower.contains('mastercard') || textLower.contains('amex')) {
      return 'Credit Card';
    }
    if (textLower.contains('debit')) return 'Debit Card';
    if (textLower.contains('check') || textLower.contains('cheque')) return 'Check';
    if (textLower.contains('paypal')) return 'PayPal';
    if (textLower.contains('venmo')) return 'Venmo';
    if (textLower.contains('apple pay')) return 'Apple Pay';
    if (textLower.contains('google pay')) return 'Google Pay';

    return null;
  }

  /// Calculate text quality score
  static double calculateTextQuality(String text) {
    if (text.isEmpty) return 0.0;

    var score = 1.0;

    // Check for gibberish (too many special characters)
    final specialChars = text.replaceAll(RegExp(r'[\w\s]'), '').length;
    final specialRatio = specialChars / text.length;
    if (specialRatio > 0.3) score -= 0.3;

    // Check for reasonable word length
    final words = _tokenize(text);
    if (words.isEmpty) return 0.0;

    final avgWordLength = words.fold<int>(0, (sum, word) => sum + word.length) / 
                          words.length;
    if (avgWordLength < 2 || avgWordLength > 15) score -= 0.2;

    // Check for too many single characters
    final singleChars = words.where((w) => w.length == 1).length;
    if (singleChars / words.length > 0.5) score -= 0.3;

    return score.clamp(0.0, 1.0);
  }

  /// Find context around a keyword
  static String? findContext(String text, String keyword, {int contextWords = 5}) {
    final words = text.split(RegExp(r'\s+'));
    final keywordLower = keyword.toLowerCase();

    for (var i = 0; i < words.length; i++) {
      if (words[i].toLowerCase().contains(keywordLower)) {
        final start = max(0, i - contextWords);
        final end = min(words.length, i + contextWords + 1);
        return words.sublist(start, end).join(' ');
      }
    }

    return null;
  }

  /// Score multiple candidates and return best match
  static T? selectBestCandidate<T>(
    List<T> candidates,
    double Function(T) scoreFunction,
  ) {
    if (candidates.isEmpty) return null;

    var bestCandidate = candidates.first;
    var bestScore = scoreFunction(bestCandidate);

    for (final candidate in candidates.skip(1)) {
      final score = scoreFunction(candidate);
      if (score > bestScore) {
        bestScore = score;
        bestCandidate = candidate;
      }
    }

    return bestScore > 0.5 ? bestCandidate : null;
  }

  /// Fuzzy match a string against a list of options
  static String? fuzzyMatch(String input, List<String> options, {double threshold = 0.7}) {
    if (options.isEmpty) return null;

    var bestMatch = options.first;
    var bestScore = stringSimilarity(input, bestMatch);

    for (final option in options.skip(1)) {
      final score = stringSimilarity(input, option);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = option;
      }
    }

    return bestScore >= threshold ? bestMatch : null;
  }
}
