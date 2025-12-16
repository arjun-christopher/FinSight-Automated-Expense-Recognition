# Dashboard Module Documentation

## Overview

The Dashboard Module provides comprehensive data visualization and analytics for expense tracking. It includes three types of charts powered by the `fl_chart` library:

1. **Category Pie Chart** - Shows spending distribution across categories
2. **Monthly Trend Line Chart** - Displays 6-month spending trends
3. **Weekly Bar Chart** - Shows current week's daily spending

## Architecture

### Files Structure

```
lib/features/dashboard/
├── providers/
│   └── dashboard_provider.dart      # State management
├── presentation/
│   └── pages/
│       └── dashboard_page.dart      # Main dashboard UI
└── widgets/
    └── chart_widgets.dart           # Chart components
```

### Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.4.9    # State management
  fl_chart: ^0.65.0           # Chart library
  sqflite: ^2.3.0             # Database access
```

## Core Components

### 1. Dashboard Provider

**File:** `lib/features/dashboard/providers/dashboard_provider.dart`

The provider manages dashboard state and data aggregation.

#### Models

**DashboardStats**
```dart
class DashboardStats {
  final double totalExpenses;         // All-time total
  final double monthlyExpenses;       // Current month total
  final double weeklyExpenses;        // Current week total
  final int expenseCount;             // Total number of expenses
  final Map<String, double> categoryTotals;  // Category breakdown
  final List<MonthlyData> monthlyTrend;      // 6-month history
  final List<WeeklyData> weeklyData;         // Mon-Sun data
  final List<Expense> recentExpenses;        // Last 10 expenses
}
```

**MonthlyData**
```dart
class MonthlyData {
  final DateTime month;
  final double amount;
}
```

**WeeklyData**
```dart
class WeeklyData {
  final String day;    // "Mon", "Tue", etc.
  final double amount;
}
```

#### Provider Usage

```dart
// Watch dashboard state
final dashboardState = ref.watch(dashboardProvider);

// Access statistics
final stats = dashboardState.stats;
if (stats != null) {
  print('Total: \$${stats.totalExpenses}');
  print('Categories: ${stats.categoryTotals}');
}

// Refresh data
ref.read(dashboardProvider.notifier).refresh();

// Filter by date range
await ref.read(dashboardProvider.notifier).filterByDateRange(
  startDate,
  endDate,
);
```

### 2. Chart Widgets

**File:** `lib/features/dashboard/widgets/chart_widgets.dart`

#### CategoryPieChart

Interactive pie chart showing expense distribution by category.

**Features:**
- Touch interaction (sections expand on tap)
- Color-coded categories with emojis
- Percentage labels on sections
- Legend with amounts
- Empty state handling

**Usage:**
```dart
CategoryPieChart(
  categoryTotals: {
    'Food & Dining': 450.50,
    'Transportation': 200.00,
    'Shopping': 320.75,
  },
  size: 200, // Optional, default: 200
)
```

**Properties:**
- `categoryTotals` (Map<String, double>) - Required. Category names to amounts
- `size` (double) - Optional. Chart diameter (default: 200)

#### MonthlyTrendChart

Line chart displaying spending trends over 6 months.

**Features:**
- Smooth curved lines
- Gradient fill under line
- Interactive tooltips
- Month abbreviations on X-axis
- Auto-scaled Y-axis with dollar amounts
- Empty state handling

**Usage:**
```dart
MonthlyTrendChart(
  monthlyData: [
    MonthlyData(month: DateTime(2024, 1), amount: 800),
    MonthlyData(month: DateTime(2024, 2), amount: 950),
    // ... more months
  ],
)
```

**Properties:**
- `monthlyData` (List<MonthlyData>) - Required. List of monthly spending data

#### WeeklyBarChart

Bar chart showing daily spending for the current week.

**Features:**
- Monday-Sunday bars
- Gradient colored bars
- Interactive tooltips
- Day labels (Mon, Tue, Wed, etc.)
- Auto-scaled Y-axis
- Empty state handling

**Usage:**
```dart
WeeklyBarChart(
  weeklyData: [
    WeeklyData(day: 'Mon', amount: 45.50),
    WeeklyData(day: 'Tue', amount: 78.25),
    // ... more days
  ],
)
```

**Properties:**
- `weeklyData` (List<WeeklyData>) - Required. List of daily spending data

### 3. Dashboard Page

**File:** `lib/features/dashboard/presentation/pages/dashboard_page.dart`

The main dashboard screen integrating all components.

**Features:**
- Pull-to-refresh functionality
- Loading states
- Error handling
- Empty state for new users
- Summary cards showing key metrics
- All three chart types
- Recent expenses list

## Integration Guide

### Step 1: Basic Setup

Ensure the dashboard provider is initialized when your app starts:

```dart
// In main.dart
void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### Step 2: Navigate to Dashboard

```dart
// Using GoRouter
context.go('/dashboard');

// Or using Navigator
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => DashboardPage()),
);
```

### Step 3: Access Dashboard Data Programmatically

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    
    if (dashboardState.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (dashboardState.stats != null) {
      final stats = dashboardState.stats!;
      
      // Access any statistic
      print('Total: \$${stats.totalExpenses}');
      print('This Month: \$${stats.monthlyExpenses}');
      print('Expense Count: ${stats.expenseCount}');
      
      // Access chart data
      stats.categoryTotals.forEach((category, amount) {
        print('$category: \$${amount}');
      });
    }
    
    return Container();
  }
}
```

## Customization

### Changing Chart Colors

Edit `lib/features/dashboard/widgets/chart_widgets.dart`:

**Pie Chart Categories:**
```dart
Map<String, Color> _getCategoryColors(BuildContext context) {
  return {
    'Food & Dining': const Color(0xFFFF6B6B),     // Red
    'Transportation': const Color(0xFF45B7D1),     // Blue
    'Shopping': const Color(0xFFFFA07A),           // Orange
    // ... add more
  };
}
```

**Line Chart Gradient:**
```dart
gradient: LinearGradient(
  colors: [
    Colors.blue,      // Start color
    Colors.purple,    // End color
  ],
)
```

**Bar Chart Gradient:**
```dart
gradient: LinearGradient(
  colors: [
    Colors.green,
    Colors.teal,
  ],
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
)
```

### Adjusting Chart Sizes

**Pie Chart:**
```dart
CategoryPieChart(
  categoryTotals: data,
  size: 250,  // Increase size
)
```

**Line Chart Aspect Ratio:**
```dart
// In MonthlyTrendChart widget
AspectRatio(
  aspectRatio: 2.0,  // Wider chart (default: 1.7)
  child: LineChart(...),
)
```

**Bar Chart Aspect Ratio:**
```dart
// In WeeklyBarChart widget
AspectRatio(
  aspectRatio: 1.5,  // Adjust width/height ratio
  child: BarChart(...),
)
```

### Modifying Data Calculations

Edit `lib/features/dashboard/providers/dashboard_provider.dart`:

**Change Monthly Trend Duration:**
```dart
List<MonthlyData> _calculateMonthlyTrend(List<Expense> expenses) {
  // Change from 6 to 12 months
  final months = List.generate(12, (index) {
    final month = now.subtract(Duration(days: 30 * (11 - index)));
    // ... rest of logic
  });
}
```

**Change Weekly Data to Start Sunday:**
```dart
List<WeeklyData> _calculateWeeklyData(List<Expense> expenses) {
  final weekStart = now.subtract(
    Duration(days: now.weekday), // Start Sunday instead of Monday
  );
  // ... rest of logic
}
```

## API Reference

### DashboardNotifier Methods

```dart
// Load or reload dashboard data
Future<void> loadDashboardData()

// Refresh dashboard (convenient alias)
Future<void> refresh()

// Filter by custom date range
Future<void> filterByDateRange(DateTime start, DateTime end)
```

### DashboardState Properties

```dart
final DashboardStats? stats;          // Current statistics
final bool isLoading;                 // Loading indicator
final String? errorMessage;           // Error state
```

## Common Use Cases

### 1. Display Total Spending

```dart
Consumer(
  builder: (context, ref, child) {
    final stats = ref.watch(dashboardProvider).stats;
    return Text(
      'Total: \$${stats?.totalExpenses.toStringAsFixed(2) ?? '0.00'}',
    );
  },
)
```

### 2. Show Top Category

```dart
Consumer(
  builder: (context, ref, child) {
    final stats = ref.watch(dashboardProvider).stats;
    
    if (stats?.categoryTotals.isEmpty ?? true) {
      return Text('No spending yet');
    }
    
    final topCategory = stats!.categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return Text('Top: ${topCategory.key} (\$${topCategory.value})');
  },
)
```

### 3. Pull-to-Refresh Implementation

```dart
RefreshIndicator(
  onRefresh: () async {
    await ref.read(dashboardProvider.notifier).refresh();
  },
  child: ListView(
    children: [
      // Your content
    ],
  ),
)
```

### 4. Date Range Filtering

```dart
ElevatedButton(
  onPressed: () async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (range != null) {
      await ref.read(dashboardProvider.notifier).filterByDateRange(
        range.start,
        range.end,
      );
    }
  },
  child: Text('Filter by Date'),
)
```

## Error Handling

The dashboard gracefully handles various error scenarios:

### Empty Data State
- Shows "No expenses yet" message
- Displays placeholder icons
- Provides guidance to add expenses

### Loading State
- Shows circular progress indicator
- Prevents interaction during data fetch

### Error State
- Displays error icon and message
- Allows refresh attempt
- Provides user-friendly error descriptions

### Chart Empty States
Each chart has its own empty state:
- **Pie Chart:** "No category data" with chart icon
- **Line Chart:** "No trend data" with line chart icon
- **Bar Chart:** "No weekly data" with bar chart icon

## Performance Considerations

1. **Data Caching:** Dashboard data is cached in provider state
2. **Lazy Loading:** Charts only render when visible
3. **Efficient Updates:** Provider only rebuilds when data changes
4. **Database Queries:** Optimized queries in ExpenseRepository

## Testing

### Unit Tests Example

```dart
test('DashboardStats calculates totals correctly', () {
  final stats = DashboardStats(
    totalExpenses: 1000.0,
    monthlyExpenses: 500.0,
    weeklyExpenses: 200.0,
    expenseCount: 15,
    categoryTotals: {'Food': 300.0, 'Transport': 200.0},
    monthlyTrend: [],
    weeklyData: [],
    recentExpenses: [],
  );
  
  expect(stats.totalExpenses, 1000.0);
  expect(stats.categoryTotals.length, 2);
});
```

### Widget Tests Example

```dart
testWidgets('Dashboard shows loading indicator', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: DashboardPage()),
    ),
  );
  
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

## Troubleshooting

### Charts Not Displaying

**Problem:** Charts show empty state even with data

**Solution:** 
- Verify data format matches expected types
- Check that provider is properly initialized
- Ensure database has expense records

### Wrong Data Displayed

**Problem:** Charts show incorrect values

**Solution:**
- Call `refresh()` to reload data
- Check date filtering is not active
- Verify ExpenseRepository queries

### Performance Issues

**Problem:** Dashboard loads slowly

**Solution:**
- Reduce number of recent expenses (default: 10)
- Optimize database queries
- Consider pagination for large datasets

## Examples

See `lib/examples/dashboard_charts_examples.dart` for:
- 8 complete working examples
- Standalone chart usage
- Custom implementations
- Date range filtering
- Stats summaries

## Related Documentation

- [OCR Workflow Documentation](./OCR_WORKFLOW.md)
- [Database Schema](./DATABASE.md)
- [Expense Repository API](./REPOSITORY.md)
- [fl_chart Documentation](https://pub.dev/packages/fl_chart)

## Support

For issues or questions:
1. Check examples in `lib/examples/dashboard_charts_examples.dart`
2. Review this documentation
3. Examine the source code comments
4. Test with sample data first
