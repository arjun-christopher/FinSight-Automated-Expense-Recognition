/// Quick Reference: Database Operations
/// 
/// Copy-paste these snippets into your code

// ============================================================
// 1. SETUP IN WIDGET (Using Riverpod)
// ============================================================

// In ConsumerWidget:
final expenseRepo = ref.watch(expenseRepositoryProvider);
final receiptRepo = ref.watch(receiptImageRepositoryProvider);
final budgetRepo = ref.watch(budgetRepositoryProvider);

// ============================================================
// 2. EXPENSES
// ============================================================

// Create
final expense = Expense(
  amount: 45.99,
  category: 'Groceries',
  description: 'Weekly shopping',
  date: DateTime.now(),
  paymentMethod: 'Credit Card',
  tags: ['food', 'weekly'],
);
final id = await expenseRepo.createExpense(expense);

// Read
final allExpenses = await expenseRepo.getAllExpenses();
final expense = await expenseRepo.getExpenseById(id);
final monthExpenses = await expenseRepo.getCurrentMonthExpenses();
final categoryExpenses = await expenseRepo.getExpensesByCategory('Groceries');

// Update
await expenseRepo.updateExpense(expense.copyWith(amount: 50.00));

// Delete
await expenseRepo.deleteExpense(id);

// Analytics
final totals = await expenseRepo.getTotalByCategory();
final yearTotal = await expenseRepo.getTotalForPeriod(startDate, endDate);

// ============================================================
// 3. RECEIPT IMAGES
// ============================================================

// Create
final receipt = ReceiptImage(
  filePath: '/path/to/receipt.jpg',
  extractedText: 'Full OCR text...',
  confidence: 0.95,
  extractedAmount: 45.99,
  extractedDate: DateTime.now(),
  extractedMerchant: 'Store Name',
  isProcessed: true,
);
final receiptId = await receiptRepo.createReceiptImage(receipt);

// Read
final allReceipts = await receiptRepo.getAllReceiptImages();
final unprocessed = await receiptRepo.getUnprocessedReceipts();
final highConfidence = await receiptRepo.getHighConfidenceReceipts(0.9);

// Update
await receiptRepo.updateReceiptImage(receipt.copyWith(isProcessed: true));

// Delete
await receiptRepo.deleteReceiptImage(receiptId);

// ============================================================
// 4. BUDGETS
// ============================================================

// Create
final budget = Budget(
  category: 'Groceries',
  amount: 500.00,
  period: BudgetPeriod.monthly,
  startDate: DateTime(2025, 1, 1),
  alertThreshold: 0.8,
  isActive: true,
);
final budgetId = await budgetRepo.createBudget(budget);

// Read
final allBudgets = await budgetRepo.getAllBudgets();
final activeBudgets = await budgetRepo.getActiveBudgets();
final currentBudgets = await budgetRepo.getCurrentlyActiveBudgets();
final budget = await budgetRepo.getBudgetByCategory('Groceries');

// Update
await budgetRepo.updateBudget(budget.copyWith(amount: 600.00));

// Activate/Deactivate
await budgetRepo.deactivateBudget(budgetId);
await budgetRepo.activateBudget(budgetId);

// Delete
await budgetRepo.deleteBudget(budgetId);

// ============================================================
// 5. RIVERPOD PROVIDERS
// ============================================================

// FutureProvider for expenses
final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return await repo.getAllExpenses();
});

// In widget:
final expensesAsync = ref.watch(expensesProvider);
return expensesAsync.when(
  data: (expenses) => ExpenseList(expenses),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => ErrorWidget(err),
);

// StreamProvider (for real-time updates)
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  // Create a stream that polls the database
  return Stream.periodic(Duration(seconds: 1), (_) async {
    final repo = ref.read(expenseRepositoryProvider);
    return await repo.getAllExpenses();
  }).asyncMap((future) => future);
});

// StateNotifier for state management
class ExpenseNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ExpenseRepository _repository;
  
  ExpenseNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExpenses();
  }
  
  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAllExpenses());
  }
  
  Future<void> addExpense(Expense expense) async {
    await _repository.createExpense(expense);
    await loadExpenses();
  }
}

final expenseNotifierProvider = 
    StateNotifierProvider<ExpenseNotifier, AsyncValue<List<Expense>>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return ExpenseNotifier(repo);
});

// ============================================================
// 6. COMMON PATTERNS
// ============================================================

// Receipt -> Expense workflow
Future<void> createExpenseFromReceipt(ReceiptImage receipt) async {
  // 1. Save receipt
  final receiptId = await receiptRepo.createReceiptImage(receipt);
  
  // 2. Create expense from extracted data
  final expense = Expense(
    amount: receipt.extractedAmount ?? 0.0,
    category: 'Uncategorized', // User can change
    description: 'From ${receipt.extractedMerchant}',
    date: receipt.extractedDate ?? DateTime.now(),
    receiptImageId: receiptId,
  );
  
  await expenseRepo.createExpense(expense);
}

// Budget tracking
Future<bool> checkBudgetAlert(String category) async {
  final budget = await budgetRepo.getBudgetByCategory(category);
  if (budget == null || !budget.isCurrentlyActive()) return false;
  
  final spent = await expenseRepo.getTotalForPeriod(
    budget.startDate,
    budget.endDate ?? DateTime.now(),
  );
  
  final percentage = spent / budget.amount;
  return percentage >= budget.alertThreshold;
}

// Get dashboard data
Future<Map<String, dynamic>> getDashboardData() async {
  final monthExpenses = await expenseRepo.getCurrentMonthExpenses();
  final categoryTotals = await expenseRepo.getTotalByCategory();
  final unprocessedReceipts = await receiptRepo.getUnprocessedCount();
  final activeBudgets = await budgetRepo.getCurrentlyActiveBudgets();
  
  return {
    'monthTotal': monthExpenses.fold(0.0, (sum, e) => sum + e.amount),
    'expenseCount': monthExpenses.length,
    'categoryTotals': categoryTotals,
    'unprocessedReceipts': unprocessedReceipts,
    'budgets': activeBudgets,
  };
}
