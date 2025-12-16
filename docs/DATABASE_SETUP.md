# Database Setup - Complete Implementation

## 📊 Database Schema

### Tables

#### 1. **expenses**
```sql
- id (INTEGER PRIMARY KEY AUTOINCREMENT)
- amount (REAL NOT NULL)
- category (TEXT NOT NULL)
- description (TEXT)
- date (TEXT NOT NULL)
- payment_method (TEXT)
- receipt_image_id (INTEGER) - FK to receipt_images
- tags (TEXT) - Comma-separated
- is_recurring (INTEGER DEFAULT 0)
- created_at (TEXT NOT NULL)
- updated_at (TEXT NOT NULL)

Indexes:
- idx_expenses_date (date)
- idx_expenses_category (category)
```

#### 2. **receipt_images**
```sql
- id (INTEGER PRIMARY KEY AUTOINCREMENT)
- file_path (TEXT NOT NULL)
- extracted_text (TEXT)
- confidence (REAL)
- extracted_amount (REAL)
- extracted_date (TEXT)
- extracted_merchant (TEXT)
- is_processed (INTEGER DEFAULT 0)
- created_at (TEXT NOT NULL)
- updated_at (TEXT NOT NULL)
```

#### 3. **budgets**
```sql
- id (INTEGER PRIMARY KEY AUTOINCREMENT)
- category (TEXT NOT NULL UNIQUE)
- amount (REAL NOT NULL)
- period (TEXT NOT NULL) - daily, weekly, monthly, yearly
- start_date (TEXT NOT NULL)
- end_date (TEXT)
- alert_threshold (REAL DEFAULT 0.8)
- is_active (INTEGER DEFAULT 1)
- created_at (TEXT NOT NULL)
- updated_at (TEXT NOT NULL)

Indexes:
- idx_budgets_active (is_active)
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
│              (Widgets, Pages, State)                 │
└────────────────────┬────────────────────────────────┘
                     │
                     ├─── Uses Riverpod Providers
                     │
┌────────────────────▼────────────────────────────────┐
│              Repository Layer                        │
│  ┌──────────────────────────────────────────────┐  │
│  │  ExpenseRepository                           │  │
│  │  ReceiptImageRepository                      │  │
│  │  BudgetRepository                            │  │
│  │  (Business logic & error handling)           │  │
│  └──────────────────┬───────────────────────────┘  │
└─────────────────────┼──────────────────────────────┘
                      │
┌─────────────────────▼──────────────────────────────┐
│              Data Source Layer (DAOs)               │
│  ┌──────────────────────────────────────────────┐  │
│  │  ExpenseLocalDataSource                      │  │
│  │  ReceiptImageLocalDataSource                 │  │
│  │  BudgetLocalDataSource                       │  │
│  │  (Raw CRUD operations)                       │  │
│  └──────────────────┬───────────────────────────┘  │
└─────────────────────┼──────────────────────────────┘
                      │
┌─────────────────────▼──────────────────────────────┐
│                Database Helper                       │
│         (SQLite connection & schema)                 │
│              finsight.db                             │
└──────────────────────────────────────────────────────┘
```

## 📁 File Structure

```
lib/
├── core/
│   ├── database/
│   │   └── database_helper.dart          # SQLite setup & schema
│   ├── models/
│   │   ├── expense.dart                  # Expense model
│   │   ├── receipt_image.dart            # ReceiptImage model
│   │   └── budget.dart                   # Budget model
│   └── providers/
│       └── database_providers.dart       # Riverpod providers
├── data/
│   ├── datasources/
│   │   ├── expense_local_datasource.dart
│   │   ├── receipt_image_local_datasource.dart
│   │   └── budget_local_datasource.dart
│   └── repositories/
│       ├── expense_repository.dart
│       ├── receipt_image_repository.dart
│       └── budget_repository.dart
└── examples/
    └── database_usage_example.dart       # Complete usage guide
```

## 🎯 Features Implemented

### Models
- ✅ Expense model with tags, categories, and receipt linking
- ✅ ReceiptImage model with OCR data fields
- ✅ Budget model with periods and alert thresholds
- ✅ All models include `toMap()` and `fromMap()` methods
- ✅ `copyWith()` methods for immutable updates
- ✅ Proper equality and hashCode implementations

### Data Sources (DAOs)
- ✅ Full CRUD operations (Create, Read, Update, Delete)
- ✅ Advanced queries:
  - Filter by category, date range, period
  - Aggregate totals by category
  - Search functionality
  - Confidence-based filtering for receipts
  - Active/inactive budget filtering
- ✅ Batch operations (deleteAll, getCount)
- ✅ Optimized with database indexes

### Repositories
- ✅ Clean abstraction layer over data sources
- ✅ Comprehensive error handling
- ✅ Business logic encapsulation
- ✅ Type-safe operations
- ✅ Validation (e.g., budget uniqueness per category)

### Providers
- ✅ Riverpod dependency injection setup
- ✅ Singleton database instance
- ✅ Repository providers for all entities

## 📝 Usage Examples

### Basic Operations

```dart
// Get repository using Riverpod
final expenseRepo = ref.watch(expenseRepositoryProvider);

// Create expense
final expense = Expense(
  amount: 45.99,
  category: 'Groceries',
  description: 'Weekly shopping',
  date: DateTime.now(),
);
final id = await expenseRepo.createExpense(expense);

// Get all expenses
final expenses = await expenseRepo.getAllExpenses();

// Get current month expenses
final monthExpenses = await expenseRepo.getCurrentMonthExpenses();

// Get total by category
final totals = await expenseRepo.getTotalByCategory();

// Update expense
await expenseRepo.updateExpense(expense.copyWith(amount: 50.00));

// Delete expense
await expenseRepo.deleteExpense(id);
```

### With FutureProvider

```dart
final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return await repo.getAllExpenses();
});

// In widget
final expensesAsync = ref.watch(expensesProvider);
return expensesAsync.when(
  data: (expenses) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

### Receipt + Expense Workflow

```dart
// 1. Save receipt image
final receipt = ReceiptImage(
  filePath: '/path/to/image.jpg',
  extractedAmount: 45.99,
  extractedMerchant: 'Store Name',
  isProcessed: true,
);
final receiptId = await receiptRepo.createReceiptImage(receipt);

// 2. Create expense from receipt
final expense = Expense(
  amount: receipt.extractedAmount!,
  category: 'Groceries',
  date: DateTime.now(),
  receiptImageId: receiptId,
);
await expenseRepo.createExpense(expense);
```

### Budget Tracking

```dart
// Create budget
final budget = Budget(
  category: 'Groceries',
  amount: 500.00,
  period: BudgetPeriod.monthly,
  startDate: DateTime(2025, 1, 1),
  alertThreshold: 0.8, // Alert at 80%
);
await budgetRepo.createBudget(budget);

// Check budget status
final spent = await expenseRepo.getTotalForPeriod(
  budget.startDate,
  budget.endDate ?? DateTime.now(),
);
final percentage = (spent / budget.amount) * 100;
if (percentage >= budget.alertThreshold * 100) {
  // Show alert!
}
```

## 🔍 Advanced Queries

### Date Range Queries
```dart
final expenses = await expenseRepo.getExpensesByDateRange(
  DateTime(2025, 1, 1),
  DateTime(2025, 12, 31),
);
```

### Search
```dart
final results = await expenseRepo.searchExpenses('grocery');
```

### High Confidence Receipts
```dart
final reliable = await receiptRepo.getHighConfidenceReceipts(0.9);
```

### Active Budgets
```dart
final activeBudgets = await budgetRepo.getCurrentlyActiveBudgets();
```

## 🛠️ Database Operations

### Initialize Database
The database is automatically initialized on first access via `DatabaseHelper.instance`.

### Clear All Data
```dart
await expenseRepo.deleteAllExpenses();
await receiptRepo.deleteAllReceiptImages();
await budgetRepo.deleteAllBudgets();
```

### Delete Database
```dart
await DatabaseHelper.instance.deleteDatabase();
```

## 🚀 Next Steps

The database layer is now ready for:
1. Integration with UI screens
2. OCR processing and receipt extraction
3. Budget alerts and notifications
4. Analytics and reporting
5. Data export (PDF/CSV)
6. Cloud sync with Firebase

## 📚 Resources

- Complete working examples: `lib/examples/database_usage_example.dart`
- All models: `lib/core/models/`
- Repositories: `lib/data/repositories/`
- Providers: `lib/core/providers/database_providers.dart`
