import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/budget.dart';
import '../../../../core/constants/expense_constants.dart';
import '../../providers/budget_providers.dart';
import '../../../../services/budget_service.dart';

/// Card widget displaying budget information with progress
class BudgetCard extends ConsumerWidget {
  final Budget budget;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;

  const BudgetCard({
    super.key,
    required this.budget,
    this.onTap,
    this.onDelete,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(budgetStatusByCategoryProvider(budget.category));

    return Card(
      elevation: budget.isActive ? 2 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: statusAsync.when(
            data: (status) {
              if (status == null) {
                return _buildBudgetWithoutStatus(context, theme);
              }
              return _buildBudgetWithStatus(context, theme, status);
            },
            loading: () => _buildBudgetWithoutStatus(context, theme),
            error: (_, __) => _buildBudgetWithoutStatus(context, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetWithStatus(
    BuildContext context,
    ThemeData theme,
    BudgetStatus status,
  ) {
    final emoji = ExpenseCategories.getEmoji(budget.category);
    final color = _getStatusColor(status.alertLevel);
    final percentage = status.percentageUsed.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          children: [
            // Category Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),

            // Category Name & Period
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget.category,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getPeriodText(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.alertLevel.displayName,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            // More Menu
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: onToggleActive,
                  child: Row(
                    children: [
                      Icon(
                        budget.isActive ? Icons.pause : Icons.play_arrow,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(budget.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: onDelete,
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),

        // Spending Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${status.currentSpending.toStringAsFixed(2)} of \$${budget.amount.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        // Remaining Amount
        if (status.remaining > 0) ...[
          const SizedBox(height: 4),
          Text(
            '\$${status.remaining.toStringAsFixed(2)} remaining',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else if (status.isExceeded) ...[
          const SizedBox(height: 4),
          Text(
            '\$${(-status.remaining).toStringAsFixed(2)} over budget',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],

        // Inactive Overlay
        if (!budget.isActive) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.pause_circle_outline, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Budget inactive',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBudgetWithoutStatus(BuildContext context, ThemeData theme) {
    final emoji = ExpenseCategories.getEmoji(budget.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget.category,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getPeriodText(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '\$${budget.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: onToggleActive,
                  child: Row(
                    children: [
                      Icon(
                        budget.isActive ? Icons.pause : Icons.play_arrow,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(budget.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: onDelete,
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _getPeriodText() {
    switch (budget.period) {
      case BudgetPeriod.daily:
        return 'Daily budget';
      case BudgetPeriod.weekly:
        return 'Weekly budget';
      case BudgetPeriod.monthly:
        return 'Monthly budget';
      case BudgetPeriod.yearly:
        return 'Yearly budget';
    }
  }

  Color _getStatusColor(BudgetAlertLevel level) {
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
