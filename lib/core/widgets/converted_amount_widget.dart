import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/currency_service.dart';
import '../../features/settings/providers/currency_providers.dart';
import '../models/expense.dart';

/// Widget that displays an expense amount converted to the user's preferred currency
class ConvertedAmountText extends ConsumerWidget {
  final Expense expense;
  final TextStyle? style;
  final bool showOriginal;

  const ConvertedAmountText({
    super.key,
    required this.expense,
    this.style,
    this.showOriginal = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredCurrency = ref.watch(currencyNotifierProvider);
    
    // If same currency, just display
    if (expense.currency == preferredCurrency) {
      final symbol = CurrencyService.getSymbol(preferredCurrency);
      return Text(
        '$symbol${expense.amount.toStringAsFixed(2)}',
        style: style,
      );
    }

    // Need to convert
    return FutureBuilder<double>(
      future: ref.read(currencyNotifierProvider.notifier).convertAmount(
        amount: expense.amount,
        from: expense.currency,
        to: preferredCurrency,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            '...',
            style: style,
          );
        }

        final convertedAmount = snapshot.data ?? expense.amount;
        final symbol = CurrencyService.getSymbol(preferredCurrency);
        
        if (showOriginal && expense.currency != preferredCurrency) {
          final originalSymbol = CurrencyService.getSymbol(expense.currency);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$symbol${convertedAmount.toStringAsFixed(2)}',
                style: style,
              ),
              Text(
                '($originalSymbol${expense.amount.toStringAsFixed(2)})',
                style: style?.copyWith(
                  fontSize: (style?.fontSize ?? 14) * 0.8,
                  color: Colors.grey,
                ),
              ),
            ],
          );
        }

        return Text(
          '$symbol${convertedAmount.toStringAsFixed(2)}',
          style: style,
        );
      },
    );
  }
}

/// Helper function to get formatted amount with conversion
Future<String> getConvertedAmountString({
  required WidgetRef ref,
  required Expense expense,
  String? targetCurrency,
}) async {
  final currency = targetCurrency ?? ref.read(currencyNotifierProvider);
  
  if (expense.currency == currency) {
    final symbol = CurrencyService.getSymbol(currency ?? 'USD');
    return '$symbol${expense.amount.toStringAsFixed(2)}';
  }

  final convertedAmount = await ref.read(currencyNotifierProvider.notifier).convertAmount(
    amount: expense.amount,
    from: expense.currency ?? 'USD',
    to: currency,
  );

  final symbol = CurrencyService.getSymbol(currency ?? 'USD');
  return '$symbol${convertedAmount.toStringAsFixed(2)}';
}

/// Extension method for easy conversion
extension ExpenseConversion on Expense {
  Future<double> convertTo(String targetCurrency, CurrencyService service) async {
    if (currency == targetCurrency) return amount;
    return await service.convertCurrency(
      amount: amount,
      from: currency ?? 'USD',
      to: targetCurrency,
    );
  }
}
