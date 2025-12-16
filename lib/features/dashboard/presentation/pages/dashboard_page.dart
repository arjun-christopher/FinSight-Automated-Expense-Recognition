import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/chart_widgets.dart';
import '../../../../core/constants/expense_constants.dart';
import '../../../budget/providers/budget_providers.dart';
import '../../../budget/presentation/pages/budget_list_page.dart';
import '../../../budget/presentation/widgets/budget_alert_banner.dart';
import '../../../../core/widgets/branded_widgets.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: BrandedAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).refresh();
        },
        child: dashboardState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : dashboardState.errorMessage != null
                ? _buildErrorState(context, dashboardState.errorMessage!)
                : dashboardState.stats == null
                    ? _buildEmptyState(context)
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Budget Alerts (if any)
                          Consumer(
                            builder: (context, ref, child) {
                              final alertsAsync = ref.watch(budgetAlertsProvider);
                              return alertsAsync.when(
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
                              );
                            },
                          ),

                          // Summary Cards
                          _buildSummaryCards(context, theme, dashboardState.stats!),
                          const SizedBox(height: 16),

                          // Budget Overview Card
                          Consumer(
                            builder: (context, ref, child) {
                              final healthAsync = ref.watch(budgetHealthSummaryProvider);
                              return healthAsync.when(
                                data: (health) {
                                  if (health.totalCategories > 0) {
                                    return _buildBudgetOverviewCard(context, theme, health);
                                  }
                                  return const SizedBox.shrink();
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Category Pie Chart
                          _buildChartSection(
                            context,
                            theme,
                            'Spending by Category',
                            CategoryPieChart(
                              categoryTotals: dashboardState.stats!.categoryTotals,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Monthly Trend Line Chart
                          _buildChartSection(
                            context,
                            theme,
                            'Monthly Trend',
                            MonthlyTrendChart(
                              monthlyData: dashboardState.stats!.monthlyTrend,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Weekly Bar Chart
                          _buildChartSection(
                            context,
                            theme,
                            'This Week',
                            WeeklyBarChart(
                              weeklyData: dashboardState.stats!.weeklyData,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Recent Expenses Section
                          _buildRecentExpenses(context, theme, dashboardState.stats!),
                        ],
                      ),
      ),
    );
  }

  Widget _buildBudgetOverviewCard(
    BuildContext context,
    ThemeData theme,
    health,
  ) {
    final color = _getHealthColor(health.overallHealth);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BudgetListPage()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget Status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: health.overallPercentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${health.totalSpending.toStringAsFixed(0)} / \$${health.totalBudget.toStringAsFixed(0)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${health.overallPercentage.toStringAsFixed(0)}% used',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getHealthColor(alertLevel) {
    switch (alertLevel.toString()) {
      case 'BudgetAlertLevel.healthy':
        return Colors.green;
      case 'BudgetAlertLevel.warning':
        return Colors.orange;
      case 'BudgetAlertLevel.exceeded':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Widget _buildSummaryCards(BuildContext context, ThemeData theme, DashboardStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Expenses',
                value: '\$${stats.totalExpenses.toStringAsFixed(2)}',
                subtitle: '${stats.expenseCount} transactions',
                icon: Icons.account_balance_wallet,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'This Month',
                value: '\$${stats.monthlyExpenses.toStringAsFixed(2)}',
                subtitle: 'Current period',
                icon: Icons.calendar_today,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          title: 'This Week',
          value: '\$${stats.weeklyExpenses.toStringAsFixed(2)}',
          subtitle: 'Last 7 days',
          icon: Icons.date_range,
          color: theme.colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    ThemeData theme,
    String title,
    Widget chart,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            chart,
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpenses(BuildContext context, ThemeData theme, DashboardStats stats) {
    if (stats.recentExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Expenses',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.recentExpenses.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final expense = stats.recentExpenses[index];
              final emoji = ExpenseCategories.getEmoji(expense.category);
              
              return ListTile(
                leading: CircleAvatar(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(expense.description ?? expense.category),
                subtitle: Text(
                  '${expense.category} • ${_formatDate(expense.date)}',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: Text(
                  '\$${expense.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
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
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding expenses to see your dashboard',
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
              'Error loading dashboard',
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
