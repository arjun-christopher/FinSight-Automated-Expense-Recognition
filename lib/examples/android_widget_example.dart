import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/android_widget_service.dart';
import '../features/expenses/providers/widget_update_provider.dart';
import '../data/repositories/expense_repository.dart';
import '../core/models/expense.dart';

/// Example demonstrating how to use the Android Widget functionality
/// 
/// This example shows:
/// 1. How to update the widget when adding/editing/deleting expenses
/// 2. How to handle widget actions (like quick add)
/// 3. How to check if widgets are supported

class WidgetIntegrationExample extends ConsumerStatefulWidget {
  const WidgetIntegrationExample({super.key});

  @override
  ConsumerState<WidgetIntegrationExample> createState() => _WidgetIntegrationExampleState();
}

class _WidgetIntegrationExampleState extends ConsumerState<WidgetIntegrationExample> {
  @override
  void initState() {
    super.initState();
    _checkWidgetLaunch();
  }

  /// Check if app was launched from widget with a specific action
  Future<void> _checkWidgetLaunch() async {
    final widgetService = ref.read(androidWidgetServiceProvider);
    final initialRoute = await widgetService.getInitialRoute();
    
    if (initialRoute != null && mounted) {
      // App was launched from widget
      // Navigate to the requested route
      // Example: Navigator.pushNamed(context, initialRoute);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Launched from widget: $initialRoute')),
      );
    }
  }

  /// Example: Add expense and update widget
  Future<void> addExpenseAndUpdateWidget() async {
    final expenseRepo = ref.read(expenseRepositoryProvider);
    final widgetManager = ref.read(widgetUpdateProvider);

    // Add a new expense
    final newExpense = Expense(
      amount: 25.50,
      category: 'Food',
      description: 'Lunch',
      date: DateTime.now(),
    );

    try {
      await expenseRepo.createExpense(newExpense);
      
      // Update widget with new data
      if (widgetManager.isSupported) {
        await widgetManager.updateWidgetWithTodayData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added and widget updated!')),
          );
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Example: Delete expense and update widget
  Future<void> deleteExpenseAndUpdateWidget(int expenseId) async {
    final expenseRepo = ref.read(expenseRepositoryProvider);
    final widgetManager = ref.read(widgetUpdateProvider);

    try {
      await expenseRepo.deleteExpense(expenseId);
      
      // Update widget
      if (widgetManager.isSupported) {
        await widgetManager.updateWidgetWithTodayData();
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Example: Manually refresh widget
  Future<void> refreshWidget() async {
    final widgetManager = ref.read(widgetUpdateProvider);
    
    if (widgetManager.isSupported) {
      await widgetManager.updateWidgetWithTodayData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Widget refreshed!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Widgets not supported on this platform')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgetManager = ref.watch(widgetUpdateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Integration Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Widget support status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Widget Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          widgetManager.isSupported ? Icons.check_circle : Icons.cancel,
                          color: widgetManager.isSupported ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widgetManager.isSupported
                              ? 'Widgets are supported'
                              : 'Widgets not supported on this platform',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            const Text(
              'Widget Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: addExpenseAndUpdateWidget,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense & Update Widget'),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: refreshWidget,
              icon: const Icon(Icons.refresh),
              label: const Text('Manually Refresh Widget'),
            ),

            const SizedBox(height: 24),

            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Add Widget to Home Screen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Long press on your home screen'),
                    Text('2. Tap "Widgets"'),
                    Text('3. Find "FinSight" in the list'),
                    Text('4. Drag the widget to your home screen'),
                    SizedBox(height: 8),
                    Text(
                      'The widget will show your spending for today and allows quick expense entry.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget Update Helper - Use this in your expense operations
class WidgetUpdateHelper {
  final WidgetRef ref;

  WidgetUpdateHelper(this.ref);

  /// Call this after any expense operation (add/edit/delete)
  Future<void> updateWidget() async {
    final widgetManager = ref.read(widgetUpdateProvider);
    
    if (widgetManager.isSupported) {
      await widgetManager.updateWidgetWithTodayData();
    }
  }
}

/// Example: Integration with Add Expense Flow
/// Add this to your AddExpensePage or similar
Future<void> onExpenseAdded(WidgetRef ref, Expense expense) async {
  // Save expense to database
  final expenseRepo = ref.read(expenseRepositoryProvider);
  await expenseRepo.createExpense(expense);

  // Update widget
  final widgetManager = ref.read(widgetUpdateProvider);
  if (widgetManager.isSupported) {
    await widgetManager.updateWidgetWithTodayData();
  }
}
