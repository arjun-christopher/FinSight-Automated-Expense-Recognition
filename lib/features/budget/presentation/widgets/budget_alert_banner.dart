import 'package:flutter/material.dart';
import '../../../../services/budget_service.dart';

/// Alert banner showing budget warnings
class BudgetAlertBanner extends StatelessWidget {
  final List<BudgetStatus> alerts;

  const BudgetAlertBanner({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exceededCount = alerts.where((a) => a.isExceeded).length;
    final warningCount = alerts.where((a) => a.isWarning).length;

    if (alerts.isEmpty) return const SizedBox.shrink();

    final color = exceededCount > 0 ? Colors.red : Colors.orange;
    final icon = exceededCount > 0 ? Icons.error : Icons.warning;

    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exceededCount > 0
                        ? 'Budget Alert!'
                        : 'Budget Warning',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (exceededCount > 0)
              Text(
                '$exceededCount ${exceededCount == 1 ? 'category has' : 'categories have'} exceeded budget limits',
                style: theme.textTheme.bodyMedium,
              ),
            if (warningCount > 0)
              Text(
                '$warningCount ${warningCount == 1 ? 'category is' : 'categories are'} approaching budget limits',
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 12),
            ...alerts.take(3).map((alert) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getAlertColor(alert.alertLevel),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${alert.budget.category}: ${alert.percentageUsed.toStringAsFixed(1)}% used',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (alerts.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${alerts.length - 3} more',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getAlertColor(BudgetAlertLevel level) {
    switch (level) {
      case BudgetAlertLevel.healthy:
        return Colors.green;
      case BudgetAlertLevel.warning:
        return Colors.orange;
      case BudgetAlertLevel.exceeded:
        return Colors.red;
    }
  }
}
