// Dashboard & Charts Examples for FinSight
// This file demonstrates how to use the dashboard module with fl_chart visualizations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/dashboard/widgets/chart_widgets.dart';
import '../features/dashboard/providers/dashboard_provider.dart';

/// Example 1: Basic Dashboard Setup
/// Shows how to set up and use the dashboard with all three chart types
class Example1BasicDashboard extends ConsumerWidget {
  const Example1BasicDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Example')),
      body: dashboardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dashboardState.stats == null
              ? const Center(child: Text('No data available'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Category Pie Chart
                    CategoryPieChart(
                      categoryTotals: dashboardState.stats!.categoryTotals,
                    ),
                    const SizedBox(height: 24),

                    // Monthly Trend Line Chart
                    MonthlyTrendChart(
                      monthlyData: dashboardState.stats!.monthlyTrend,
                    ),
                    const SizedBox(height: 24),

                    // Weekly Bar Chart
                    WeeklyBarChart(
                      weeklyData: dashboardState.stats!.weeklyData,
                    ),
                  ],
                ),
    );
  }
}

/// Example 2: Standalone Category Pie Chart
/// Demonstrates using just the pie chart with custom data
class Example2StandalonePieChart extends StatelessWidget {
  const Example2StandalonePieChart({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample category data
    final categoryTotals = {
      'Food & Dining': 450.50,
      'Transportation': 200.00,
      'Shopping': 320.75,
      'Entertainment': 150.00,
      'Utilities': 180.25,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Category Breakdown')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spending by Category',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                CategoryPieChart(
                  categoryTotals: categoryTotals,
                  size: 180,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Example 3: Standalone Monthly Trend Chart
/// Demonstrates using just the line chart with custom data
class Example3StandaloneLineChart extends StatelessWidget {
  const Example3StandaloneLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample monthly trend data
    final monthlyData = List.generate(6, (index) {
      final month = DateTime.now().subtract(Duration(days: 30 * (5 - index)));
      return MonthlyData(
        month: month,
        amount: 800 + (index * 150) + (index % 2 * 200).toDouble(),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Spending Trend')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '6-Month Spending Trend',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                MonthlyTrendChart(monthlyData: monthlyData),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Example 4: Standalone Weekly Bar Chart
/// Demonstrates using just the bar chart with custom data
class Example4StandaloneBarChart extends StatelessWidget {
  const Example4StandaloneBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample weekly data
    final weeklyData = [
      WeeklyData(day: 'Mon', amount: 45.50),
      WeeklyData(day: 'Tue', amount: 78.25),
      WeeklyData(day: 'Wed', amount: 32.00),
      WeeklyData(day: 'Thu', amount: 95.75),
      WeeklyData(day: 'Fri', amount: 120.00),
      WeeklyData(day: 'Sat', amount: 85.50),
      WeeklyData(day: 'Sun', amount: 62.30),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Spending')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week\'s Spending',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                WeeklyBarChart(weeklyData: weeklyData),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Example 5: Empty State Handling
/// Shows how charts handle empty data
class Example5EmptyStates extends StatelessWidget {
  const Example5EmptyStates({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Empty States')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Empty Pie Chart:'),
          const CategoryPieChart(categoryTotals: {}),
          const SizedBox(height: 24),
          const Text('Empty Line Chart:'),
          const MonthlyTrendChart(monthlyData: []),
          const SizedBox(height: 24),
          const Text('Empty Bar Chart:'),
          const WeeklyBarChart(weeklyData: []),
        ],
      ),
    );
  }
}

/// Example 6: Dashboard with Pull-to-Refresh
/// Demonstrates how to implement refresh functionality
class Example6RefreshableDashboard extends ConsumerWidget {
  const Example6RefreshableDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refreshable Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardProvider.notifier).refresh();
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
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (dashboardState.stats != null) ...[
                    CategoryPieChart(
                      categoryTotals: dashboardState.stats!.categoryTotals,
                    ),
                    const SizedBox(height: 24),
                    MonthlyTrendChart(
                      monthlyData: dashboardState.stats!.monthlyTrend,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Example 7: Custom Date Range Dashboard
/// Shows how to filter dashboard data by custom date range
class Example7CustomDateRange extends ConsumerStatefulWidget {
  const Example7CustomDateRange({super.key});

  @override
  ConsumerState<Example7CustomDateRange> createState() =>
      _Example7CustomDateRangeState();
}

class _Example7CustomDateRangeState
    extends ConsumerState<Example7CustomDateRange> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Date Range'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
          ),
        ],
      ),
      body: Column(
        children: [
          if (startDate != null && endDate != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatDate(startDate!)} - ${_formatDate(endDate!)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            startDate = null;
                            endDate = null;
                          });
                          ref.read(dashboardProvider.notifier).refresh();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: dashboardState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (dashboardState.stats != null) ...[
                        CategoryPieChart(
                          categoryTotals: dashboardState.stats!.categoryTotals,
                        ),
                        const SizedBox(height: 24),
                        MonthlyTrendChart(
                          monthlyData: dashboardState.stats!.monthlyTrend,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      await ref
          .read(dashboardProvider.notifier)
          .filterByDateRange(picked.start, picked.end);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Example 8: Dashboard Stats Summary
/// Shows how to display dashboard statistics in a summary card format
class Example8StatsSummary extends ConsumerWidget {
  const Example8StatsSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final stats = dashboardState.stats;

    if (stats == null) {
      return const Scaffold(
        body: Center(child: Text('No data available')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Stats Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatCard(
            title: 'Total Expenses',
            value: '\$${stats.totalExpenses.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _StatCard(
            title: 'This Month',
            value: '\$${stats.monthlyExpenses.toStringAsFixed(2)}',
            icon: Icons.calendar_today,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _StatCard(
            title: 'This Week',
            value: '\$${stats.weeklyExpenses.toStringAsFixed(2)}',
            icon: Icons.date_range,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _StatCard(
            title: 'Total Transactions',
            value: '${stats.expenseCount}',
            icon: Icons.receipt,
            color: Colors.purple,
          ),
          const SizedBox(height: 24),
          Text(
            'Top Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...stats.categoryTotals.entries.take(5).map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(entry.key),
                trailing: Text(
                  '\$${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Usage Guide:
/// 
/// To use these examples in your app:
/// 
/// 1. Import the example file:
///    import 'package:finsight/examples/dashboard_charts_examples.dart';
/// 
/// 2. Navigate to any example:
///    Navigator.push(context, MaterialPageRoute(
///      builder: (context) => Example1BasicDashboard(),
///    ));
/// 
/// 3. Customize chart appearance by modifying the chart widgets in:
///    lib/features/dashboard/widgets/chart_widgets.dart
/// 
/// 4. Modify data calculations in:
///    lib/features/dashboard/providers/dashboard_provider.dart
