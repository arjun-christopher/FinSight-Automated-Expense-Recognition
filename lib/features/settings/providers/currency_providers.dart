import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/currency_service.dart';

/// Provider for currency service
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

/// Provider for preferred currency
final preferredCurrencyProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(currencyServiceProvider);
  return await service.getPreferredCurrency();
});

/// State notifier for currency selection
class CurrencyNotifier extends StateNotifier<String> {
  final CurrencyService _service;

  CurrencyNotifier(this._service) : super('USD') {
    _loadPreferredCurrency();
  }

  Future<void> _loadPreferredCurrency() async {
    state = await _service.getPreferredCurrency();
  }

  Future<void> setCurrency(String currency) async {
    await _service.setPreferredCurrency(currency);
    state = currency;
  }

  Future<double> convertAmount({
    required double amount,
    required String from,
    String? to,
  }) async {
    final targetCurrency = to ?? state;
    return await _service.convertCurrency(
      amount: amount,
      from: from,
      to: targetCurrency,
    );
  }

  String formatAmount(double amount, [String? currency]) {
    return _service.formatAmount(amount, currency ?? state);
  }
}

/// Provider for currency notifier
final currencyNotifierProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  final service = ref.watch(currencyServiceProvider);
  return CurrencyNotifier(service);
});

/// Provider for exchange rates
final exchangeRatesProvider = FutureProvider.family<Map<String, double>, String>(
  (ref, baseCurrency) async {
    final service = ref.watch(currencyServiceProvider);
    return await service.fetchExchangeRates(baseCurrency);
  },
);
