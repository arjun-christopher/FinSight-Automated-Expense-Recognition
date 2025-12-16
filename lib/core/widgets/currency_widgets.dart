import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/currency_service.dart';
import '../../settings/providers/currency_providers.dart';

/// Widget to display an amount with currency conversion option
class CurrencyAmount extends ConsumerStatefulWidget {
  final double amount;
  final String? originalCurrency;
  final TextStyle? style;
  final bool showConversion;
  final List<String>? additionalCurrencies;

  const CurrencyAmount({
    super.key,
    required this.amount,
    this.originalCurrency,
    this.style,
    this.showConversion = false,
    this.additionalCurrencies,
  });

  @override
  ConsumerState<CurrencyAmount> createState() => _CurrencyAmountState();
}

class _CurrencyAmountState extends ConsumerState<CurrencyAmount> {
  bool _showingAlternate = false;

  @override
  Widget build(BuildContext context) {
    final preferredCurrency = ref.watch(currencyNotifierProvider);
    final currencyNotifier = ref.watch(currencyNotifierProvider.notifier);
    final sourceCurrency = widget.originalCurrency ?? preferredCurrency;

    if (!widget.showConversion || sourceCurrency == preferredCurrency) {
      return Text(
        currencyNotifier.formatAmount(widget.amount, sourceCurrency),
        style: widget.style,
      );
    }

    return GestureDetector(
      onTap: widget.showConversion 
        ? () => setState(() => _showingAlternate = !_showingAlternate)
        : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary amount
          Text(
            currencyNotifier.formatAmount(widget.amount, sourceCurrency),
            style: widget.style,
          ),
          // Converted amount
          if (_showingAlternate) ...[
            const SizedBox(height: 4),
            FutureBuilder<double>(
              future: currencyNotifier.convertAmount(
                amount: widget.amount,
                from: sourceCurrency,
                to: preferredCurrency,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    '≈ ${currencyNotifier.formatAmount(snapshot.data!, preferredCurrency)}',
                    style: widget.style?.copyWith(
                      fontSize: (widget.style?.fontSize ?? 14) * 0.85,
                      color: Colors.grey,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
          // Additional currencies
          if (_showingAlternate && widget.additionalCurrencies != null)
            ...widget.additionalCurrencies!.map((currency) {
              if (currency == sourceCurrency || currency == preferredCurrency) {
                return const SizedBox.shrink();
              }
              return FutureBuilder<double>(
                future: currencyNotifier.convertAmount(
                  amount: widget.amount,
                  from: sourceCurrency,
                  to: currency,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '≈ ${currencyNotifier.formatAmount(snapshot.data!, currency)}',
                        style: widget.style?.copyWith(
                          fontSize: (widget.style?.fontSize ?? 14) * 0.85,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            }).toList(),
        ],
      ),
    );
  }
}

/// Widget to display multiple currency conversions
class MultiCurrencyDisplay extends ConsumerWidget {
  final double amount;
  final String sourceCurrency;
  final List<String> targetCurrencies;

  const MultiCurrencyDisplay({
    super.key,
    required this.amount,
    required this.sourceCurrency,
    required this.targetCurrencies,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyNotifier = ref.watch(currencyNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currency Conversions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Source amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${CurrencyService.getName(sourceCurrency)}:',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  currencyNotifier.formatAmount(amount, sourceCurrency),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Target currencies
            ...targetCurrencies.where((c) => c != sourceCurrency).map((currency) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FutureBuilder<double>(
                  future: currencyNotifier.convertAmount(
                    amount: amount,
                    from: sourceCurrency,
                    to: currency,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${CurrencyService.getName(currency)}:',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            currencyNotifier.formatAmount(snapshot.data!, currency),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'Error loading $currency',
                        style: TextStyle(color: theme.colorScheme.error),
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(currency),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    );
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
