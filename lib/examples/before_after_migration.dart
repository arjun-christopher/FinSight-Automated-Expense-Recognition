import 'package:flutter/material.dart';
import '../core/widgets/animated_cards.dart';
import '../core/widgets/animated_buttons.dart';
import '../core/animations/app_animations.dart';

/// Before/After comparison showing migration to animated components
/// This demonstrates how to upgrade existing pages to use the UI polish system

// ============================================================================
// BEFORE: Basic expense list without animations
// ============================================================================

class ExpenseListPageBefore extends StatefulWidget {
  const ExpenseListPageBefore({super.key});

  @override
  State<ExpenseListPageBefore> createState() => _ExpenseListPageBeforeState();
}

class _ExpenseListPageBeforeState extends State<ExpenseListPageBefore> {
  bool _isLoading = true;
  final List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    // Simulate loading
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _expenses.addAll([
        Expense(id: '1', name: 'Groceries', amount: 85.50),
        Expense(id: '2', name: 'Gas', amount: 45.00),
        Expense(id: '3', name: 'Coffee', amount: 12.99),
      ]);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses (Before)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt),
                    ),
                    title: Text(expense.name),
                    subtitle: Text('\$${expense.amount.toStringAsFixed(2)}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToDetails(expense),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToDetails(Expense expense) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to ${expense.name}')),
    );
  }

  Future<void> _addExpense() async {
    // Simulate adding
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added')),
      );
    }
  }
}

// ============================================================================
// AFTER: Same page with animations and polish
// ============================================================================

class ExpenseListPageAfter extends StatefulWidget {
  const ExpenseListPageAfter({super.key});

  @override
  State<ExpenseListPageAfter> createState() => _ExpenseListPageAfterState();
}

class _ExpenseListPageAfterState extends State<ExpenseListPageAfter> {
  bool _isLoading = true;
  bool _isAdding = false;
  final List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    // Simulate loading
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _expenses.clear();
        _expenses.addAll([
          Expense(id: '1', name: 'Groceries', amount: 85.50),
          Expense(id: '2', name: 'Gas', amount: 45.00),
          Expense(id: '3', name: 'Coffee', amount: 12.99),
        ]);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses (After)'),
        actions: [
          // ✨ AnimatedIconButton with rotation effect
          AnimatedIconButton(
            icon: Icons.refresh,
            onPressed: _loadExpenses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          // ✨ ShimmerCard loading placeholders instead of spinner
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) {
                return const ShimmerCard(
                  width: double.infinity,
                  height: 80,
                  margin: EdgeInsets.only(bottom: 12),
                );
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                // ✨ SlideInCard for staggered entrance animation
                return SlideInCard(
                  index: index,
                  // ✨ AnimatedCard for press effect
                  child: AnimatedCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => _navigateToDetails(expense),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.receipt),
                      ),
                      title: Text(expense.name),
                      subtitle: Text('\$${expense.amount.toStringAsFixed(2)}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),
                );
              },
            ),
      // ✨ AnimatedFAB with label
      floatingActionButton: AnimatedFAB(
        icon: const Icon(Icons.add),
        label: 'Add',
        isExtended: true,
        onPressed: _addExpense,
      ),
    );
  }

  void _navigateToDetails(Expense expense) {
    Navigator.push(
      context,
      // ✨ FadePageRoute for smooth transition
      FadePageRoute(
        child: ExpenseDetailsPage(expense: expense),
      ),
    );
  }

  Future<void> _addExpense() async {
    setState(() => _isAdding = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isAdding = false);
      // ✨ Success animation dialog
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✨ Animated success checkmark
              const SuccessAnimation(),
              const SizedBox(height: 24),
              const Text(
                'Expense Added!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your expense has been saved',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // ✨ AnimatedButton for action
              AnimatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Details page showing more animations
// ============================================================================

class ExpenseDetailsPage extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailsPage({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          AnimatedIconButton(
            icon: Icons.edit,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit expense')),
              );
            },
            tooltip: 'Edit',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✨ SlideInCard with stagger
            SlideInCard(
              index: 0,
              child: AnimatedCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expense Name',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        expense.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SlideInCard(
              index: 1,
              child: AnimatedCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${expense.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ✨ ExpandableCard for additional details
            SlideInCard(
              index: 2,
              child: ExpandableCard(
                header: const Text(
                  'Additional Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                expandedContent: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: Today'),
                    SizedBox(height: 8),
                    Text('Category: Uncategorized'),
                    SizedBox(height: 8),
                    Text('Payment Method: Cash'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // ✨ AnimatedButton for delete with loading state
            AnimatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense deleted')),
                );
              },
              backgroundColor: Colors.red,
              child: const Text('Delete Expense'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Side-by-side comparison widget
// ============================================================================

class BeforeAfterComparison extends StatelessWidget {
  const BeforeAfterComparison({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Before / After Comparison'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose a version to compare:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExpenseListPageBefore(),
                  ),
                );
              },
              backgroundColor: Colors.grey,
              child: const Text('BEFORE (No Animations)'),
            ),
            const SizedBox(height: 16),
            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  FadePageRoute(
                    child: const ExpenseListPageAfter(),
                  ),
                );
              },
              child: const Text('AFTER (With Animations)'),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Key Differences:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDifference('Loading', 'Spinner', 'Shimmer cards'),
                      _buildDifference('List items', 'Pop in', 'Slide + fade'),
                      _buildDifference('Cards', 'Static', 'Press animation'),
                      _buildDifference('Navigation', 'Instant', 'Smooth fade'),
                      _buildDifference('Success', 'Snackbar', 'Dialog + animation'),
                      _buildDifference('Buttons', 'Basic', 'Animated'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifference(String feature, String before, String after) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              before,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const Icon(Icons.arrow_forward, size: 16),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              after,
              style: const TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Helper models
// ============================================================================

class Expense {
  final String id;
  final String name;
  final double amount;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
  });
}
