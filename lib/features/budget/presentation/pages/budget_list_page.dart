import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_providers.dart';
import '../widgets/budget_card.dart';
import '../widgets/budget_alert_banner.dart';
import 'set_budget_page.dart';
import '../../../../services/budget_service.dart';

/// Budget list page showing all budgets with their status
class BudgetListPage extends ConsumerWidget {
  const BudgetListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final budgetListState = ref.watch(budgetListProvider);
    final budgetAlertsAsync = ref.watch(budgetAlertsProvider);
    final healthSummaryAsync = ref.watch(budgetHealthSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToSetBudget(context),
            tooltip: 'Add Budget',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(budgetListProvider);
          ref.invalidate(budgetAlertsProvider);
          ref.invalidate(budgetHealthSummaryProvider);
        },
        child: budgetListState.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Alert Banner
                budgetAlertsAsync.when(
                  data: (alerts) {
                    if (alerts.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: BudgetAlertBanner(alerts: alerts),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Health Summary Card
                healthSummaryAsync.when(
                  data: (summary) => _buildHealthSummaryCard(context, theme, summary),
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                // Budget List Header
                Text(
                  'All Budgets',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Budget Cards
                ...budgets.map((budget) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BudgetCard(
                      budget: budget,
                      onTap: () => _navigateToEditBudget(context, budget),
                      onDelete: () => _deleteBudget(context, ref, budget),
                      onToggleActive: () => _toggleActive(ref, budget),
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(context, error.toString()),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToSetBudget(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
    );
  }

  Widget _buildHealthSummaryCard(
    BuildContext context,
    ThemeData theme,
    BudgetHealthSummary summary,
  ) {
    final color = _getHealthColor(summary.overallHealth);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Budget Health',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    summary.overallHealth.displayName,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: summary.overallPercentage / 100,
                minHeight: 12,
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
                  '\$${summary.totalSpending.toStringAsFixed(2)} of \$${summary.totalBudget.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${summary.overallPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Status Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusCount(
                  context,
                  'Healthy',
                  summary.healthyCount,
                  Colors.green,
                ),
                _buildStatusCount(
                  context,
                  'Warning',
                  summary.warningCount,
                  Colors.orange,
                ),
                _buildStatusCount(
                  context,
                  'Exceeded',
                  summary.exceededCount,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCount(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No budgets yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Set budgets to track your spending and get alerts',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToSetBudget(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading budgets',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getHealthColor(BudgetAlertLevel level) {
    switch (level) {
      case BudgetAlertLevel.healthy:
        return Colors.green;
      case BudgetAlertLevel.warning:
        return Colors.orange;
      case BudgetAlertLevel.exceeded:
        return Colors.red;
    }
  }

  void _navigateToSetBudget(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SetBudgetPage(),
      ),
    );
  }

  void _navigateToEditBudget(BuildContext context, budget) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetBudgetPage(budget: budget),
      ),
    );
  }

  Future<void> _deleteBudget(
    BuildContext context,
    WidgetRef ref,
    budget,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Delete budget for ${budget.category}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(budgetListProvider.notifier).deleteBudget(budget.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleActive(WidgetRef ref, budget) async {
    try {
      await ref.read(budgetListProvider.notifier).toggleBudgetActive(budget);
    } catch (e) {
      // Error handling done in provider
    }
  }
}
