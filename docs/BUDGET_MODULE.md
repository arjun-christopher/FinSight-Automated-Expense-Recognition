# Budget Module Documentation

## Overview

The Budget Module provides comprehensive budget tracking and alert functionality. Users can set budgets per category, track spending against limits, and receive alerts when approaching or exceeding budgets.

## Features

- ✅ Set monthly/weekly/daily/yearly budgets per category
- ✅ Real-time spending tracking
- ✅ Configurable alert thresholds (default: 80%)
- ✅ Visual progress indicators
- ✅ Budget status (Healthy, Warning, Exceeded)
- ✅ Overall budget health summary
- ✅ Active/inactive budget toggle
- ✅ Dashboard integration with alerts

## Architecture

### Files Structure

```
lib/
├── core/models/
│   └── budget.dart                          # Budget model & enums
├── data/repositories/
│   └── budget_repository.dart               # Database operations
├── services/
│   └── budget_service.dart                  # Business logic
├── features/budget/
│   ├── providers/
│   │   └── budget_providers.dart            # Riverpod providers
│   └── presentation/
│       ├── pages/
│       │   ├── budget_list_page.dart        # Budget list screen
│       │   └── set_budget_page.dart         # Create/edit budget
│       └── widgets/
│           ├── budget_card.dart             # Budget display card
│           └── budget_alert_banner.dart     # Alert notifications
└── examples/
    └── budget_examples.dart                 # Usage examples
```

### Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.4.9    # State management
  sqflite: ^2.3.0             # Database
```

## Core Components

### 1. Budget Model

**File:** `lib/core/models/budget.dart`

#### Budget Class

```dart
class Budget {
  final int? id;
  final String category;             // Expense category
  final double amount;                // Budget limit
  final BudgetPeriod period;          // daily/weekly/monthly/yearly
  final DateTime startDate;           // When budget starts
  final DateTime? endDate;            // Optional end date
  final double alertThreshold;        // 0.0-1.0 (default: 0.8 = 80%)
  final bool isActive;                // Active/inactive toggle
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### BudgetPeriod Enum

```dart
enum BudgetPeriod {
  daily,
  weekly,
  monthly,
  yearly,
}
```

**Methods:**
- `toMap()` - Convert to database map
- `fromMap()` - Create from database map
- `copyWith()` - Create copy with updated fields
- `isCurrentlyActive()` - Check if budget is currently active

### 2. Budget Service

**File:** `lib/services/budget_service.dart`

Handles budget calculations and alert logic.

#### Key Methods

```dart
// Get budget status for a category
Future<BudgetStatus?> getBudgetStatus({
  required String category,
  DateTime? date,
});

// Get all budget statuses
Future<List<BudgetStatus>> getAllBudgetStatuses({DateTime? date});

// Get budgets with alerts (warning or exceeded)
Future<List<BudgetStatus>> getBudgetsWithAlerts({DateTime? date});

// Get exceeded budgets only
Future<List<BudgetStatus>> getExceededBudgets({DateTime? date});

// Get budget health summary
Future<BudgetHealthSummary> getBudgetHealthSummary({DateTime? date});

// Check if expense would exceed budget
Future<bool> wouldExceedBudget({
  required String category,
  required double amount,
  DateTime? date,
});

// Get remaining budget for category
Future<double> getRemainingBudget({
  required String category,
  DateTime? date,
});
```

#### BudgetStatus Class

```dart
class BudgetStatus {
  final Budget budget;
  final double currentSpending;
  final double percentageUsed;
  final BudgetAlertLevel alertLevel;
  
  double get remaining;       // Budget - spending
  bool get isExceeded;        // Spending > budget
  bool get isWarning;         // 80%+ but < 100%
  bool get isHealthy;         // < 80%
}
```

#### BudgetAlertLevel Enum

```dart
enum BudgetAlertLevel {
  healthy,   // < threshold (default: 80%)
  warning,   // >= threshold and < 100%
  exceeded,  // >= 100%
}
```

#### BudgetHealthSummary Class

```dart
class BudgetHealthSummary {
  final double totalBudget;         // Sum of all budgets
  final double totalSpending;       // Sum of all spending
  final int healthyCount;           // Number of healthy budgets
  final int warningCount;           // Number of warning budgets
  final int exceededCount;          // Number of exceeded budgets
  final double overallPercentage;   // Total spending / total budget
  final BudgetAlertLevel overallHealth;
  
  double get totalRemaining;
  int get totalCategories;
}
```

### 3. Budget Repository

**File:** `lib/data/repositories/budget_repository.dart`

Database operations for budgets.

#### Methods

```dart
// CRUD Operations
Future<int> createBudget(Budget budget);
Future<void> updateBudget(Budget budget);
Future<void> deleteBudget(int id);

// Queries
Future<List<Budget>> getAllBudgets();
Future<Budget?> getBudgetById(int id);
Future<Budget?> getBudgetByCategory(String category);
Future<List<Budget>> getActiveBudgets();
Future<List<Budget>> getCurrentlyActiveBudgets();
Future<List<Budget>> getBudgetsByPeriod(BudgetPeriod period);

// State Management
Future<void> activateBudget(int id);
Future<void> deactivateBudget(int id);

// Utilities
Future<bool> budgetExistsForCategory(String category);
Future<int> getBudgetCount();
Future<int> getActiveBudgetCount();
```

### 4. Budget Providers

**File:** `lib/features/budget/providers/budget_providers.dart`

Riverpod providers for state management.

#### Available Providers

```dart
// Repository & Service
final budgetRepositoryProvider
final budgetServiceProvider

// Data Providers
final budgetsProvider                        // All budgets
final activeBudgetsProvider                  // Active budgets only
final budgetStatusesProvider                 // All budget statuses
final budgetAlertsProvider                   // Budgets with alerts
final budgetHealthSummaryProvider            // Overall health
final budgetStatusByCategoryProvider(category) // Status by category

// State Notifier
final budgetListProvider                     // Managed budget list
```

#### BudgetListNotifier Methods

```dart
Future<void> loadBudgets();
Future<void> createBudget(Budget budget);
Future<void> updateBudget(Budget budget);
Future<void> deleteBudget(int id);
Future<void> toggleBudgetActive(Budget budget);
```

## User Interface

### 1. Budget List Page

**File:** `lib/features/budget/presentation/pages/budget_list_page.dart`

Main budget screen showing all budgets with their status.

**Features:**
- Budget health summary card
- Alert banner for warnings/exceeded
- List of all budgets with progress
- Pull-to-refresh
- Empty state for new users
- FAB to add new budget

**Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => BudgetListPage()),
);
```

### 2. Set Budget Page

**File:** `lib/features/budget/presentation/pages/set_budget_page.dart`

Create or edit budget screen.

**Features:**
- Category selection dropdown
- Amount input
- Period selection (daily/weekly/monthly/yearly)
- Start date picker
- Optional end date picker
- Alert threshold slider (50%-100%)
- Active/inactive toggle
- Form validation

**Usage:**
```dart
// Create new budget
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => SetBudgetPage()),
);

// Edit existing budget
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SetBudgetPage(budget: existingBudget),
  ),
);
```

### 3. Budget Card Widget

**File:** `lib/features/budget/presentation/widgets/budget_card.dart`

Displays budget with progress indicator.

**Features:**
- Category icon with emoji
- Period label
- Status badge (Healthy/Warning/Exceeded)
- Progress bar with color coding
- Spending info (current/total)
- Remaining/over amount
- Inactive indicator
- Edit/delete menu

**Usage:**
```dart
BudgetCard(
  budget: budget,
  onTap: () => editBudget(budget),
  onDelete: () => deleteBudget(budget),
  onToggleActive: () => toggleActive(budget),
)
```

### 4. Budget Alert Banner

**File:** `lib/features/budget/presentation/widgets/budget_alert_banner.dart`

Shows alert summary at top of screens.

**Features:**
- Warning/error icon
- Count of exceeded/warning budgets
- List of top 3 problem categories
- Color-coded (orange for warning, red for exceeded)

**Usage:**
```dart
Consumer(
  builder: (context, ref, child) {
    final alerts = ref.watch(budgetAlertsProvider);
    return alerts.when(
      data: (alerts) => BudgetAlertBanner(alerts: alerts),
      loading: () => SizedBox.shrink(),
      error: (_, __) => SizedBox.shrink(),
    );
  },
)
```

## Integration Guide

### Step 1: Database Setup

The database schema is automatically created by `DatabaseHelper`:

```sql
CREATE TABLE budgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  amount REAL NOT NULL,
  period TEXT NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT,
  alert_threshold REAL DEFAULT 0.8,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### Step 2: Create a Budget

```dart
// Using the UI
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => SetBudgetPage()),
);

// Programmatically
final budget = Budget(
  category: 'Food & Dining',
  amount: 500.00,
  period: BudgetPeriod.monthly,
  startDate: DateTime.now(),
  alertThreshold: 0.8,  // Alert at 80%
  isActive: true,
);

await ref.read(budgetListProvider.notifier).createBudget(budget);
```

### Step 3: Check Budget Status

```dart
// Get status for specific category
final status = await ref.read(budgetServiceProvider)
    .getBudgetStatus(category: 'Food & Dining');

if (status != null) {
  print('Spent: \$${status.currentSpending}');
  print('Remaining: \$${status.remaining}');
  print('Status: ${status.alertLevel.displayName}');
}
```

### Step 4: Display Budget in UI

```dart
Consumer(
  builder: (context, ref, child) {
    final statusAsync = ref.watch(
      budgetStatusByCategoryProvider('Food & Dining'),
    );
    
    return statusAsync.when(
      data: (status) {
        if (status == null) return Text('No budget set');
        
        return Column(
          children: [
            Text('Budget: \$${status.budget.amount}'),
            LinearProgressIndicator(
              value: status.percentageUsed / 100,
            ),
            Text('${status.percentageUsed.toFixed(1)}% used'),
          ],
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  },
)
```

### Step 5: Handle Budget Alerts

```dart
// Check before adding expense
final wouldExceed = await ref.read(budgetServiceProvider)
    .wouldExceedBudget(
      category: 'Food & Dining',
      amount: 150.00,
    );

if (wouldExceed) {
  // Show warning dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Budget Warning'),
      content: Text('This expense would exceed your budget'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Add expense anyway
            Navigator.pop(context);
          },
          child: Text('Add Anyway'),
        ),
      ],
    ),
  );
}
```

## Dashboard Integration

The budget module integrates with the dashboard:

### Budget Alert Banner

Shows at top of dashboard when budgets need attention.

### Budget Overview Card

Clickable card showing:
- Overall budget health
- Progress bar
- Total spending / total budget
- Percentage used

Tapping navigates to Budget List Page.

## Alert System

### Alert Thresholds

- **Healthy**: < threshold (default: 80%)
- **Warning**: >= threshold and < 100%
- **Exceeded**: >= 100%

### Configuring Threshold

Set custom alert threshold per budget:

```dart
final budget = Budget(
  category: 'Food',
  amount: 500,
  period: BudgetPeriod.monthly,
  startDate: DateTime.now(),
  alertThreshold: 0.9,  // Alert at 90% instead of 80%
);
```

### Getting Alerts

```dart
// All budgets with alerts
final alerts = await ref.read(budgetServiceProvider)
    .getBudgetsWithAlerts();

// Only exceeded budgets
final exceeded = await ref.read(budgetServiceProvider)
    .getExceededBudgets();

// Display in UI
Consumer(
  builder: (context, ref, child) {
    final alertsAsync = ref.watch(budgetAlertsProvider);
    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return Text('All budgets on track!');
        }
        return BudgetAlertBanner(alerts: alerts);
      },
      loading: () => CircularProgressIndicator(),
      error: (_, __) => SizedBox.shrink(),
    );
  },
)
```

## Budget Periods

### Period Types

1. **Daily**: Resets every day
2. **Weekly**: Resets every Monday
3. **Monthly**: Resets on 1st of each month
4. **Yearly**: Resets on January 1st

### Period Calculation

The service automatically calculates the correct date range based on period:

```dart
// Monthly budget: Jan 1 - Jan 31
// Weekly budget: Monday - Sunday
// Daily budget: 00:00 - 23:59
// Yearly budget: Jan 1 - Dec 31
```

## Common Use Cases

### 1. Set Monthly Budget for All Categories

```dart
Future<void> setupMonthlyBudgets() async {
  final budgets = {
    'Food & Dining': 500.00,
    'Transportation': 200.00,
    'Shopping': 300.00,
    'Entertainment': 150.00,
  };

  for (final entry in budgets.entries) {
    final budget = Budget(
      category: entry.key,
      amount: entry.value,
      period: BudgetPeriod.monthly,
      startDate: DateTime.now(),
    );
    
    await ref.read(budgetListProvider.notifier).createBudget(budget);
  }
}
```

### 2. Check Budget Before Expense

```dart
Future<bool> checkBudgetAndPrompt(
  String category,
  double amount,
) async {
  final service = ref.read(budgetServiceProvider);
  final wouldExceed = await service.wouldExceedBudget(
    category: category,
    amount: amount,
  );

  if (wouldExceed) {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Budget Warning'),
        content: Text('This would exceed your $category budget'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
  }

  return true; // No budget or within limit
}
```

### 3. Display Budget Health Dashboard

```dart
Consumer(
  builder: (context, ref, child) {
    final healthAsync = ref.watch(budgetHealthSummaryProvider);
    
    return healthAsync.when(
      data: (health) {
        return Column(
          children: [
            Text('Total Budget: \$${health.totalBudget}'),
            Text('Total Spent: \$${health.totalSpending}'),
            Text('Remaining: \$${health.totalRemaining}'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCount('Healthy', health.healthyCount, Colors.green),
                _buildCount('Warning', health.warningCount, Colors.orange),
                _buildCount('Exceeded', health.exceededCount, Colors.red),
              ],
            ),
          ],
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  },
)
```

### 4. Update Budget Amount

```dart
Future<void> updateBudgetAmount(Budget budget, double newAmount) async {
  final updated = budget.copyWith(amount: newAmount);
  await ref.read(budgetListProvider.notifier).updateBudget(updated);
}
```

### 5. Temporarily Pause Budget

```dart
Future<void> pauseBudget(Budget budget) async {
  await ref.read(budgetListProvider.notifier).toggleBudgetActive(budget);
}
```

## API Reference

### Budget Methods

```dart
Budget.toMap()                    // Convert to database map
Budget.fromMap(map)               // Create from database map
Budget.copyWith({...})            // Create modified copy
Budget.isCurrentlyActive()        // Check if active based on dates
```

### Repository Methods

See [Budget Repository section](#3-budget-repository) for full list.

### Service Methods

See [Budget Service section](#2-budget-service) for full list.

### Provider Methods

See [Budget Providers section](#4-budget-providers) for full list.

## Performance Considerations

1. **Caching**: Budget statuses are cached by providers
2. **Lazy Loading**: Only calculate status when needed
3. **Efficient Queries**: Repository uses indexed queries
4. **Smart Rebuilds**: Providers only rebuild affected widgets

## Error Handling

All repository methods include try-catch blocks:

```dart
try {
  await repository.createBudget(budget);
} catch (e) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

## Testing

### Unit Tests

```dart
test('Budget calculates percentage correctly', () {
  final status = BudgetStatus(
    budget: Budget(category: 'Food', amount: 100),
    currentSpending: 80,
    percentageUsed: 80,
    alertLevel: BudgetAlertLevel.warning,
  );
  
  expect(status.remaining, 20);
  expect(status.isWarning, true);
});
```

### Widget Tests

```dart
testWidgets('BudgetCard shows progress', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BudgetCard(budget: testBudget),
    ),
  );
  
  expect(find.byType(LinearProgressIndicator), findsOneWidget);
});
```

## Troubleshooting

### Budget Not Showing

**Problem:** Budget created but not appearing in list

**Solution:**
- Verify budget is active (`isActive = true`)
- Check start date is not in future
- Refresh budget list: `ref.invalidate(budgetListProvider)`

### Wrong Spending Amount

**Problem:** Budget shows incorrect spending

**Solution:**
- Verify expenses have correct category
- Check date range matches budget period
- Ensure expenses are saved to database

### Alert Not Triggering

**Problem:** Budget exceeded but no alert

**Solution:**
- Check alert threshold (default: 0.8 = 80%)
- Verify budget is active
- Refresh alerts: `ref.invalidate(budgetAlertsProvider)`

## Examples

See `lib/examples/budget_examples.dart` for 8 complete examples:

1. Basic Budget List
2. Create Budget Programmatically
3. Display Budget Status
4. Budget Alerts Banner
5. Budget Health Summary
6. Check Before Adding Expense
7. Active vs Inactive Budgets
8. Budgets by Period

## Related Documentation

- [Dashboard Module](./DASHBOARD_MODULE.md)
- [Database Schema](./DATABASE.md)
- [Expense Repository API](./REPOSITORY.md)

## Support

For issues or questions:
1. Check examples in `lib/examples/budget_examples.dart`
2. Review this documentation
3. Examine source code comments
4. Test with sample budgets first
