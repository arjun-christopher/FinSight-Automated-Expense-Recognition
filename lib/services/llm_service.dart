import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/expense_constants.dart';

/// Service for LLM-based category classification using AirLLM
class LlmService {
  final String apiKey;
  final String baseUrl;
  final String model;
  final Duration timeout;

  LlmService({
    required this.apiKey,
    this.baseUrl = 'https://api.airllm.com/v1',
    this.model = 'gpt-4',
    this.timeout = const Duration(seconds: 30),
  });

  /// Classify expense category using LLM
  /// 
  /// Returns a map with:
  /// - category: predicted category
  /// - confidence: confidence score (0.0-1.0)
  /// - reasoning: explanation of the classification
  Future<Map<String, dynamic>> classifyCategory({
    required String merchantName,
    String? description,
    double? amount,
  }) async {
    final prompt = _buildPrompt(
      merchantName: merchantName,
      description: description,
      amount: amount,
    );

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content': _getSystemPrompt(),
                },
                {
                  'role': 'user',
                  'content': prompt,
                },
              ],
              'temperature': 0.3, // Lower for more deterministic results
              'max_tokens': 150,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return _parseResponse(content);
      } else {
        throw LlmException(
          'API request failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw LlmException('Failed to classify with LLM: $e');
    }
  }

  /// Build classification prompt
  String _buildPrompt({
    required String merchantName,
    String? description,
    double? amount,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Classify the following expense:');
    buffer.writeln('Merchant: $merchantName');
    
    if (description != null && description.isNotEmpty) {
      buffer.writeln('Description: $description');
    }
    
    if (amount != null) {
      buffer.writeln('Amount: \$${amount.toStringAsFixed(2)}');
    }

    return buffer.toString();
  }

  /// Get system prompt with categories
  String _getSystemPrompt() {
    return '''You are an expense categorization expert. Classify expenses into one of these categories:

${ExpenseCategories.all.map((c) => '- $c').join('\n')}

Respond ONLY in this exact JSON format:
{
  "category": "<category_name>",
  "confidence": <0.0-1.0>,
  "reasoning": "<brief explanation>"
}

Guidelines:
- Choose the MOST appropriate category from the list above
- Use exact category names as listed
- Confidence should reflect how certain you are (0.0-1.0)
- Keep reasoning brief (1-2 sentences)
- Consider merchant name, description, and amount
- Use "Other" only as last resort''';
  }

  /// Parse LLM response
  Map<String, dynamic> _parseResponse(String content) {
    try {
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        throw FormatException('No JSON found in response');
      }

      final jsonStr = jsonMatch.group(0)!;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Validate required fields
      final category = data['category'] as String?;
      final confidence = data['confidence'];
      final reasoning = data['reasoning'] as String?;

      if (category == null || confidence == null) {
        throw FormatException('Missing required fields in response');
      }

      // Validate category is in our list
      if (!ExpenseCategories.all.contains(category)) {
        throw FormatException('Invalid category: $category');
      }

      // Convert confidence to double
      final confidenceValue = confidence is num 
          ? confidence.toDouble() 
          : double.parse(confidence.toString());

      // Clamp confidence between 0 and 1
      final clampedConfidence = confidenceValue.clamp(0.0, 1.0);

      return {
        'category': category,
        'confidence': clampedConfidence,
        'reasoning': reasoning ?? 'No reasoning provided',
      };
    } catch (e) {
      throw LlmException('Failed to parse LLM response: $e\nContent: $content');
    }
  }

  /// Test LLM service availability
  Future<bool> testConnection() async {
    try {
      await classifyCategory(merchantName: 'Starbucks');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get available models (mock implementation)
  List<String> getAvailableModels() {
    return [
      'gpt-4',
      'gpt-3.5-turbo',
      'claude-3-opus',
      'claude-3-sonnet',
    ];
  }
}

/// Exception thrown by LLM service
class LlmException implements Exception {
  final String message;
  
  LlmException(this.message);

  @override
  String toString() => 'LlmException: $message';
}

/// Fast LLM service using lightweight models for quick classification
class FastLlmService extends LlmService {
  FastLlmService({
    required String apiKey,
    String? baseUrl,
  }) : super(
    apiKey: apiKey,
    baseUrl: baseUrl ?? 'https://api.openai.com/v1',
    model: 'gpt-3.5-turbo',  // Fast and cheap model
    timeout: const Duration(seconds: 3),  // Shorter timeout
  );

  @override
  Future<Map<String, dynamic>> classifyCategory({
    required String merchantName,
    String? description,
    double? amount,
  }) async {
    // Ultra-short, optimized prompt for speed
    final prompt = 'Categorize: $merchantName. Reply with just the category name.';
    
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'system', 'content': 'Classify expenses into: Food & Dining, Groceries, Transportation, Shopping, Entertainment, Utilities, Healthcare, Travel, Fitness, or Other. Reply with ONLY the category name.'},
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.2,
              'max_tokens': 20,  // Very short response for speed
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = (data['choices'][0]['message']['content'] as String).trim();
        
        // Quick parsing - just extract the category
        String category = ExpenseCategories.other;
        double confidence = 0.8;
        
        final normalized = content.toLowerCase();
        if (normalized.contains('food') || normalized.contains('dining')) {
          category = ExpenseCategories.food;
          confidence = 0.9;
        } else if (normalized.contains('grocer')) {
          category = ExpenseCategories.groceries;
          confidence = 0.9;
        } else if (normalized.contains('transport')) {
          category = ExpenseCategories.transportation;
          confidence = 0.9;
        } else if (normalized.contains('shop')) {
          category = ExpenseCategories.shopping;
          confidence = 0.85;
        } else if (normalized.contains('entertain')) {
          category = ExpenseCategories.entertainment;
          confidence = 0.9;
        } else if (normalized.contains('util')) {
          category = ExpenseCategories.utilities;
          confidence = 0.9;
        } else if (normalized.contains('health')) {
          category = ExpenseCategories.healthcare;
          confidence = 0.9;
        } else if (normalized.contains('travel')) {
          category = ExpenseCategories.travel;
          confidence = 0.9;
        } else if (normalized.contains('fit')) {
          category = ExpenseCategories.fitness;
          confidence = 0.85;
        }
        
        return {
          'category': category,
          'confidence': confidence,
          'reasoning': 'Fast LLM classification',
        };
      } else {
        // Fall back to mock on error
        return _mockClassify(merchantName);
      }
    } catch (e) {
      // Fall back to mock on error
      return _mockClassify(merchantName);
    }
  }
  
  Map<String, dynamic> _mockClassify(String merchantName) {
    final merchant = merchantName.toLowerCase();
    
    if (merchant.contains('starbucks') || merchant.contains('cafe') || merchant.contains('restaurant')) {
      return {'category': ExpenseCategories.food, 'confidence': 0.9, 'reasoning': 'Fast rule match'};
    } else if (merchant.contains('walmart') || merchant.contains('target')) {
      return {'category': ExpenseCategories.groceries, 'confidence': 0.9, 'reasoning': 'Fast rule match'};
    } else if (merchant.contains('uber') || merchant.contains('gas')) {
      return {'category': ExpenseCategories.transportation, 'confidence': 0.85, 'reasoning': 'Fast rule match'};
    }
    return {'category': ExpenseCategories.other, 'confidence': 0.6, 'reasoning': 'Default'};
  }
}

/// Mock LLM service for testing without API key
class MockLlmService extends LlmService {
  MockLlmService() : super(apiKey: 'mock-key');

  @override
  Future<Map<String, dynamic>> classifyCategory({
    required String merchantName,
    String? description,
    double? amount,
  }) async {
    // No artificial delay for faster processing
    // await Future.delayed(const Duration(milliseconds: 100));

    // Mock classification based on merchant name
    final merchant = merchantName.toLowerCase();
    
    String category;
    double confidence;
    String reasoning;

    if (merchant.contains('starbucks') || merchant.contains('cafe') || merchant.contains('restaurant')) {
      category = ExpenseCategories.food;
      confidence = 0.95;
      reasoning = 'Merchant name indicates food and beverage establishment';
    } else if (merchant.contains('walmart') || merchant.contains('target') || merchant.contains('grocery')) {
      category = ExpenseCategories.groceries;
      confidence = 0.92;
      reasoning = 'Merchant is a grocery or general merchandise store';
    } else if (merchant.contains('uber') || merchant.contains('lyft') || merchant.contains('gas')) {
      category = ExpenseCategories.transportation;
      confidence = 0.90;
      reasoning = 'Merchant provides transportation services';
    } else if (merchant.contains('amazon') || merchant.contains('shop')) {
      category = ExpenseCategories.shopping;
      confidence = 0.85;
      reasoning = 'Merchant is an online or retail shopping platform';
    } else if (merchant.contains('netflix') || merchant.contains('spotify') || merchant.contains('movie')) {
      category = ExpenseCategories.entertainment;
      confidence = 0.93;
      reasoning = 'Merchant provides entertainment or streaming services';
    } else if (merchant.contains('electric') || merchant.contains('utility') || merchant.contains('water')) {
      category = ExpenseCategories.utilities;
      confidence = 0.94;
      reasoning = 'Merchant is a utility service provider';
    } else if (merchant.contains('hospital') || merchant.contains('clinic') || merchant.contains('pharmacy')) {
      category = ExpenseCategories.healthcare;
      confidence = 0.96;
      reasoning = 'Merchant is a healthcare or medical service provider';
    } else if (merchant.contains('hotel') || merchant.contains('airline') || merchant.contains('airbnb')) {
      category = ExpenseCategories.travel;
      confidence = 0.91;
      reasoning = 'Merchant provides travel or accommodation services';
    } else if (merchant.contains('gym') || merchant.contains('fitness')) {
      category = ExpenseCategories.fitness;
      confidence = 0.89;
      reasoning = 'Merchant is a fitness or wellness facility';
    } else {
      category = ExpenseCategories.other;
      confidence = 0.60;
      reasoning = 'Unable to determine specific category from merchant name';
    }

    return {
      'category': category,
      'confidence': confidence,
      'reasoning': reasoning,
    };
  }

  @override
  Future<bool> testConnection() async {
    return true;
  }
}
