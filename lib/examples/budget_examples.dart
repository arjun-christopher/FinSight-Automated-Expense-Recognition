// Budget Module Examples for FinSight
// This file demonstrates how to use the budget tracking system

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/budget.dart';
import '../features/budget/providers/budget_providers.dart';
import '../features/budget/presentation/pages/budget_list_page.dart';
import '../features/budget/presentation/pages/set_budget_page.dart';
import '../features/budget/presentation/widgets/budget_card.dart';
import '../features/budget/presentation/widgets/budget_alert_banner.dart';
import '../services/budget_service.dart';

/// Example 1: Basic Budget List
/// Shows how to display all budgets
class Example1BudgetList extends ConsumerWidget {
  const Example1BudgetList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Budgets')),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return const Center(child: Text('No budgets yet'));
          }
          return ListView.builder(
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              return BudgetCard(budget: budgets[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Example 2: Create Budget Programmatically
/// Demonstrates creating a budget without UI
class Example2CreateBudget extends ConsumerWidget {
  const Example2CreateBudget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Budget')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final budget = Budget(
              category: 'Food & Dining',
              amount: 500.00,
              period: BudgetPeriod.monthly,
              startDate: DateTime.now(),
              alertThreshold: 0.8,
            );

            try {
              await ref.read(budgetListProvider.notifier).createBudget(budget);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget created!')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
          child: const Text('Create \$500 Food Budget'),
        ),
      ),
    );
  }
}

/// Example 3: Display Budget Status
/// Shows current spending vs budget for a category
class Example3BudgetStatus extends ConsumerWidget {
  final String category;

  const Example3BudgetStatus({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(budgetStatusByCategoryProvider(category));

    return Scaffold(
      appBar: AppBar(title: Text('$category Budget')),
      body: statusAsync.when(
        data: (status) {
          if (status == null) {
            return const Center(child: Text('No budget set'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget: \$${status.budget.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Spent: \$${status.currentSpending.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Remaining: \$${status.remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    color: status.remaining > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: status.percentageUsed / 100,
                  minHeight: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    status.isExceeded ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${status.percentageUsed.toStringAsFixed(1)}% used',
                  style: TextStyle(
                    color: status.isExceeded ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Example 4: Budget Alerts Banner
/// Shows all budget warnings and exceeded budgets
class Example4BudgetAlerts extends ConsumerWidget {
  const Example4BudgetAlerts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(budgetAlertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Alerts')),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('All budgets are on track!'),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              BudgetAlertBanner(alerts: alerts),
              const SizedBox(height: 16),
              ...alerts.map((alert) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      alert.isExceeded ? Icons.error : Icons.warning,
                      color: alert.isExceeded ? Colors.red : Colors.orange,
                    ),
                    title: Text(alert.budget.category),
                    subtitle: Text(
                      '\$${alert.currentSpending.toStringAsFixed(2)} / \$${alert.budget.amount.toStringAsFixed(2)}',
                    ),
                    trailing: Text(
                      '${alert.percentageUsed.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: alert.isExceeded ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Example 5: Budget Health Summary
/// Displays overall budget health across all categories
class Example5BudgetHealth extends ConsumerWidget {
  const Example5BudgetHealth({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(budgetHealthSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Health')),
      body: healthAsync.when(
        data: (health) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Health',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildMetric(
                        context,
                        'Total Budget',
                        '\$${health.totalBudget.toStringAsFixed(2)}',
                      ),
                      _buildMetric(
                        context,
                        'Total Spending',
                        '\$${health.totalSpending.toStringAsFixed(2)}',
                      ),
                      _buildMetric(
                        context,
                        'Remaining',
                        '\$${health.totalRemaining.toStringAsFixed(2)}',
                      ),
                      const Divider(),
                      _buildMetric(
                        context,
                        'Healthy Budgets',
                        '${health.healthyCount}',
                      ),
                      _buildMetric(
                        context,
                        'Warning Budgets',
                        '${health.warningCount}',
                      ),
                      _buildMetric(
                        context,
                        'Exceeded Budgets',
                        '${health.exceededCount}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Example 6: Check Before Adding Expense
/// Verify if expense would exceed budget
class Example6CheckBudgetBeforeExpense extends ConsumerWidget {
  const Example6CheckBudgetBeforeExpense({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(budgetServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense Check')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final category = 'Food & Dining';
            final amount = 150.00;

            final wouldExceed = await service.wouldExceedBudget(
              category: category,
              amount: amount,
            );

            if (context.mounted) {
              if (wouldExceed) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Budget Warning'),
                    content: Text(
                      'Adding \$$amount to $category would exceed your budget. Continue anyway?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Add expense anyway
                        },
                        child: const Text('Add Anyway'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Within budget!')),
                );
              }
            }
          },
          child: const Text('Check \$150 Food Expense'),
        ),
      ),
    );
  }
}

/// Example 7: Active vs Inactive Budgets
/// Toggle budget active state
class Example7ToggleBudgetActive extends ConsumerWidget {
  const Example7ToggleBudgetActive({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Toggle Budgets')),
      body: budgetsAsync.when(
        data: (budgets) {
          return ListView.builder(
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return SwitchListTile(
                title: Text(budget.category),
                subtitle: Text('\$${budget.amount.toStringAsFixed(2)}'),
                value: budget.isActive,
                onChanged: (value) async {
                  await ref
                      .read(budgetListProvider.notifier)
                      .toggleBudgetActive(budget);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Example 8: Budget Periods Comparison
/// Show budgets grouped by period
class Example8BudgetsByPeriod extends ConsumerWidget {
  const Example8BudgetsByPeriod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets by Period')),
      body: budgetsAsync.when(
        data: (budgets) {
          final grouped = <BudgetPeriod, List<Budget>>{};
          for (final budget in budgets) {
            grouped.putIfAbsent(budget.period, () => []).add(budget);
          }

          return ListView(
            children: BudgetPeriod.values.map((period) {
              final periodBudgets = grouped[period] ?? [];
              if (periodBudgets.isEmpty) return const SizedBox.shrink();

              return ExpansionTile(
                title: Text(_getPeriodName(period)),
                subtitle: Text('${periodBudgets.length} budgets'),
                children: periodBudgets.map((budget) {
                  return ListTile(
                    title: Text(budget.category),
                    trailing: Text('\$${budget.amount.toStringAsFixed(2)}'),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _getPeriodName(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return 'Daily Budgets';
      case BudgetPeriod.weekly:
        return 'Weekly Budgets';
      case BudgetPeriod.monthly:
        return 'Monthly Budgets';
      case BudgetPeriod.yearly:
        return 'Yearly Budgets';
    }
  }
}

/// Usage Guide:
/// 
/// To use these examples:
/// 
/// 1. Import the example file:
///    import 'package:finsight/examples/budget_examples.dart';
/// 
/// 2. Navigate to any example:
///    Navigator.push(context, MaterialPageRoute(
///      builder: (context) => Example1BudgetList(),
///    ));
/// 
/// 3. Access budget service directly:
///    final service = ref.read(budgetServiceProvider);
///    final status = await service.getBudgetStatus(category: 'Food');
/// 
/// 4. Create budgets programmatically:
///    final budget = Budget(...);
///    await ref.read(budgetListProvider.notifier).createBudget(budget);
