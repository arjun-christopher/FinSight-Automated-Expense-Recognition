import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling currency operations
/// - Detects user location and default currency
/// - Provides currency conversion
/// - Manages currency preferences
class CurrencyService {
  static const String _currencyPrefsKey = 'preferred_currency';
  static const String _exchangeRatesKey = 'exchange_rates';
  static const String _lastUpdateKey = 'rates_last_update';

  // Common currencies with their symbols
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CNY': '¥',
    'INR': '₹',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'CHF': 'CHF',
    'SEK': 'kr',
    'NZD': 'NZ\$',
    'MXN': 'Mex\$',
    'SGD': 'S\$',
    'HKD': 'HK\$',
    'NOK': 'kr',
    'KRW': '₩',
    'TRY': '₺',
    'RUB': '₽',
    'BRL': 'R\$',
    'ZAR': 'R',
  };

  // Currency names
  static const Map<String, String> currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'CHF': 'Swiss Franc',
    'SEK': 'Swedish Krona',
    'NZD': 'New Zealand Dollar',
    'MXN': 'Mexican Peso',
    'SGD': 'Singapore Dollar',
    'HKD': 'Hong Kong Dollar',
    'NOK': 'Norwegian Krone',
    'KRW': 'South Korean Won',
    'TRY': 'Turkish Lira',
    'RUB': 'Russian Ruble',
    'BRL': 'Brazilian Real',
    'ZAR': 'South African Rand',
  };

  // Location-based currency mapping
  static const Map<String, String> countryToCurrency = {
    'US': 'USD',
    'GB': 'GBP',
    'EU': 'EUR',
    'DE': 'EUR',
    'FR': 'EUR',
    'IT': 'EUR',
    'ES': 'EUR',
    'JP': 'JPY',
    'CN': 'CNY',
    'IN': 'INR',
    'AU': 'AUD',
    'CA': 'CAD',
    'CH': 'CHF',
    'SE': 'SEK',
    'NZ': 'NZD',
    'MX': 'MXN',
    'SG': 'SGD',
    'HK': 'HKD',
    'NO': 'NOK',
    'KR': 'KRW',
    'TR': 'TRY',
    'RU': 'RUB',
    'BR': 'BRL',
    'ZA': 'ZAR',
  };

  /// Detect currency based on user's location
  Future<String> detectDefaultCurrency() async {
    try {
      // Try to detect from IP-based geolocation (free service)
      final response = await http.get(
        Uri.parse('https://ipapi.co/json/'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final countryCode = data['country_code'] as String?;
        final currency = data['currency'] as String?;
        
        if (currency != null && currencySymbols.containsKey(currency)) {
          return currency;
        }
        
        if (countryCode != null) {
          return countryToCurrency[countryCode] ?? 'USD';
        }
      }
    } catch (e) {
      // If geolocation fails, try timezone-based detection
      final timezone = DateTime.now().timeZoneName;
      if (timezone.contains('EST') || timezone.contains('EDT') || 
          timezone.contains('PST') || timezone.contains('PDT')) {
        return 'USD';
      } else if (timezone.contains('GMT') || timezone.contains('BST')) {
        return 'GBP';
      } else if (timezone.contains('IST')) {
        return 'INR';
      } else if (timezone.contains('JST')) {
        return 'JPY';
      }
    }

    // Default to USD if detection fails
    return 'USD';
  }

  /// Get preferred currency from storage
  Future<String> getPreferredCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_currencyPrefsKey);
    
    if (saved != null) {
      return saved;
    }

    // Auto-detect if not set
    final detected = await detectDefaultCurrency();
    await setPreferredCurrency(detected);
    return detected;
  }

  /// Set preferred currency
  Future<void> setPreferredCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyPrefsKey, currency);
  }

  /// Get currency symbol
  static String getSymbol(String currency) {
    return currencySymbols[currency] ?? currency;
  }

  /// Get currency name
  static String getName(String currency) {
    return currencyNames[currency] ?? currency;
  }

  /// Fetch latest exchange rates (using free API)
  Future<Map<String, double>> fetchExchangeRates(String baseCurrency) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we have cached rates from today
    final lastUpdate = prefs.getInt(_lastUpdateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    
    if (lastUpdate != null && lastUpdate == today) {
      final cached = prefs.getString(_exchangeRatesKey);
      if (cached != null) {
        final Map<String, dynamic> decoded = jsonDecode(cached);
        return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
    }

    try {
      // Use exchangerate-api.com (free tier: 1500 requests/month)
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$baseCurrency'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final ratesMap = rates.map((key, value) => 
          MapEntry(key, (value as num).toDouble())
        );
        
        // Cache the rates
        await prefs.setString(_exchangeRatesKey, jsonEncode(ratesMap));
        await prefs.setInt(_lastUpdateKey, today);
        
        return ratesMap;
      }
    } catch (e) {
      // Return default rates if fetch fails
      return _getDefaultRates(baseCurrency);
    }

    return _getDefaultRates(baseCurrency);
  }

  /// Convert amount from one currency to another
  Future<double> convertCurrency({
    required double amount,
    required String from,
    required String to,
  }) async {
    if (from == to) return amount;

    final rates = await fetchExchangeRates(from);
    final rate = rates[to];
    
    if (rate == null) return amount;
    
    return amount * rate;
  }

  /// Format amount with currency
  String formatAmount(double amount, String currency) {
    final symbol = getSymbol(currency);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Get default rates (fallback)
  Map<String, double> _getDefaultRates(String baseCurrency) {
    // Approximate rates as fallback (USD base)
    final usdRates = {
      'USD': 1.0,
      'EUR': 0.92,
      'GBP': 0.79,
      'JPY': 149.50,
      'CNY': 7.24,
      'INR': 83.12,
      'AUD': 1.52,
      'CAD': 1.36,
      'CHF': 0.88,
      'SEK': 10.35,
      'NZD': 1.65,
      'MXN': 17.08,
      'SGD': 1.34,
      'HKD': 7.83,
      'NOK': 10.72,
      'KRW': 1305.50,
      'TRY': 28.75,
      'RUB': 92.50,
      'BRL': 4.87,
      'ZAR': 18.65,
    };

    if (baseCurrency == 'USD') {
      return usdRates;
    }

    // Convert from USD to base currency
    final baseRate = usdRates[baseCurrency] ?? 1.0;
    return usdRates.map((key, value) => 
      MapEntry(key, value / baseRate)
    );
  }
}
