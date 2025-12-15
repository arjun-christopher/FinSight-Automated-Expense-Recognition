import 'package:flutter/material.dart';
import '../core/models/expense.dart';
import '../core/models/receipt_image.dart';
import '../core/models/budget.dart';
import '../core/database/database_helper.dart';
import '../data/datasources/expense_local_datasource.dart';
import '../data/datasources/receipt_image_local_datasource.dart';
import '../data/datasources/budget_local_datasource.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/receipt_image_repository.dart';
import '../data/repositories/budget_repository.dart';

/// Example usage of the database system
/// 
/// This demonstrates how to:
/// 1. Initialize the database
/// 2. Create repositories
/// 3. Perform CRUD operations on all entities
/// 4. Query data with different filters
class DatabaseUsageExample {
  late ExpenseRepository expenseRepository;
  late ReceiptImageRepository receiptImageRepository;
  late BudgetRepository budgetRepository;

  Future<void> initialize() async {
    // Initialize repositories
    expenseRepository = ExpenseRepository(ExpenseLocalDataSource());
    receiptImageRepository = ReceiptImageRepository(ReceiptImageLocalDataSource());
    budgetRepository = BudgetRepository(BudgetLocalDataSource());

    debugPrint('✅ Database initialized successfully');
  }

  // ==================== EXPENSE EXAMPLES ====================

  Future<void> expenseExamples() async {
    debugPrint('\n📊 EXPENSE EXAMPLES\n');

    // 1. Create a new expense
    final expense = Expense(
      amount: 45.99,
      category: 'Groceries',
      description: 'Weekly grocery shopping',
      date: DateTime.now(),
      paymentMethod: 'Credit Card',
      tags: ['food', 'weekly'],
    );

    final expenseId = await expenseRepository.createExpense(expense);
    debugPrint('Created expense with ID: $expenseId');

    // 2. Get all expenses
    final allExpenses = await expenseRepository.getAllExpenses();
    debugPrint('Total expenses: ${allExpenses.length}');

    // 3. Get current month expenses
    final monthExpenses = await expenseRepository.getCurrentMonthExpenses();
    debugPrint('Current month expenses: ${monthExpenses.length}');

    // 4. Get expenses by category
    final groceryExpenses = await expenseRepository.getExpensesByCategory('Groceries');
    debugPrint('Grocery expenses: ${groceryExpenses.length}');

    // 5. Get total by category
    final categoryTotals = await expenseRepository.getTotalByCategory();
    debugPrint('Category totals: $categoryTotals');

    // 6. Get total for a period
    final startDate = DateTime(2025, 1, 1);
    final endDate = DateTime(2025, 12, 31);
    final yearTotal = await expenseRepository.getTotalForPeriod(startDate, endDate);
    debugPrint('Year total: \$${yearTotal.toStringAsFixed(2)}');

    // 7. Search expenses
    final searchResults = await expenseRepository.searchExpenses('grocery');
    debugPrint('Search results: ${searchResults.length}');

    // 8. Update expense
    if (allExpenses.isNotEmpty) {
      final updatedExpense = allExpenses.first.copyWith(
        amount: 50.00,
        description: 'Updated grocery shopping',
      );
      await expenseRepository.updateExpense(updatedExpense);
      debugPrint('Updated expense ID: ${updatedExpense.id}');
    }

    // 9. Get expense count
    final count = await expenseRepository.getExpenseCount();
    debugPrint('Total expense count: $count');
  }

  // ==================== RECEIPT IMAGE EXAMPLES ====================

  Future<void> receiptImageExamples() async {
    debugPrint('\n📷 RECEIPT IMAGE EXAMPLES\n');

    // 1. Create a new receipt image
    final receiptImage = ReceiptImage(
      filePath: '/path/to/receipt.jpg',
      extractedText: 'Total: \$45.99\nDate: 2025-12-15',
      confidence: 0.95,
      extractedAmount: 45.99,
      extractedDate: DateTime.now(),
      extractedMerchant: 'Grocery Store',
      isProcessed: true,
    );

    final receiptId = await receiptImageRepository.createReceiptImage(receiptImage);
    debugPrint('Created receipt image with ID: $receiptId');

    // 2. Get all receipt images
    final allReceipts = await receiptImageRepository.getAllReceiptImages();
    debugPrint('Total receipt images: ${allReceipts.length}');

    // 3. Get processed receipts
    final processedReceipts = await receiptImageRepository.getProcessedReceipts();
    debugPrint('Processed receipts: ${processedReceipts.length}');

    // 4. Get unprocessed receipts
    final unprocessedReceipts = await receiptImageRepository.getUnprocessedReceipts();
    debugPrint('Unprocessed receipts: ${unprocessedReceipts.length}');

    // 5. Search by merchant
    final merchantReceipts = await receiptImageRepository.searchByMerchant('Grocery');
    debugPrint('Receipts from Grocery Store: ${merchantReceipts.length}');

    // 6. Get high confidence receipts
    final highConfidenceReceipts = await receiptImageRepository.getHighConfidenceReceipts(0.9);
    debugPrint('High confidence receipts (>90%): ${highConfidenceReceipts.length}');

    // 7. Update receipt image
    if (allReceipts.isNotEmpty) {
      final updatedReceipt = allReceipts.first.copyWith(
        isProcessed: true,
        confidence: 0.98,
      );
      await receiptImageRepository.updateReceiptImage(updatedReceipt);
      debugPrint('Updated receipt ID: ${updatedReceipt.id}');
    }

    // 8. Get unprocessed count
    final unprocessedCount = await receiptImageRepository.getUnprocessedCount();
    debugPrint('Unprocessed count: $unprocessedCount');
  }

  // ==================== BUDGET EXAMPLES ====================

  Future<void> budgetExamples() async {
    debugPrint('\n💰 BUDGET EXAMPLES\n');

    // 1. Create a new budget
    final budget = Budget(
      category: 'Groceries',
      amount: 500.00,
      period: BudgetPeriod.monthly,
      startDate: DateTime(2025, 1, 1),
      alertThreshold: 0.8, // Alert at 80%
      isActive: true,
    );

    final budgetId = await budgetRepository.createBudget(budget);
    debugPrint('Created budget with ID: $budgetId');

    // 2. Get all budgets
    final allBudgets = await budgetRepository.getAllBudgets();
    debugPrint('Total budgets: ${allBudgets.length}');

    // 3. Get active budgets
    final activeBudgets = await budgetRepository.getActiveBudgets();
    debugPrint('Active budgets: ${activeBudgets.length}');

    // 4. Get currently active budgets (filtered by dates)
    final currentlyActive = await budgetRepository.getCurrentlyActiveBudgets();
    debugPrint('Currently active budgets: ${currentlyActive.length}');

    // 5. Get budget by category
    final groceryBudget = await budgetRepository.getBudgetByCategory('Groceries');
    if (groceryBudget != null) {
      debugPrint('Grocery budget: \$${groceryBudget.amount}');
    }

    // 6. Get budgets by period
    final monthlyBudgets = await budgetRepository.getBudgetsByPeriod(BudgetPeriod.monthly);
    debugPrint('Monthly budgets: ${monthlyBudgets.length}');

    // 7. Check if budget exists
    final exists = await budgetRepository.budgetExistsForCategory('Transportation');
    debugPrint('Transportation budget exists: $exists');

    // 8. Update budget
    if (allBudgets.isNotEmpty) {
      final updatedBudget = allBudgets.first.copyWith(
        amount: 600.00,
        alertThreshold: 0.75,
      );
      await budgetRepository.updateBudget(updatedBudget);
      debugPrint('Updated budget ID: ${updatedBudget.id}');
    }

    // 9. Deactivate budget
    if (allBudgets.isNotEmpty && allBudgets.first.id != null) {
      await budgetRepository.deactivateBudget(allBudgets.first.id!);
      debugPrint('Deactivated budget ID: ${allBudgets.first.id}');
    }

    // 10. Get active budget count
    final activeCount = await budgetRepository.getActiveBudgetCount();
    debugPrint('Active budget count: $activeCount');
  }

  // ==================== COMBINED OPERATIONS ====================

  Future<void> combinedOperations() async {
    debugPrint('\n🔄 COMBINED OPERATIONS\n');

    // Create a receipt, extract data, and create an expense
    final receipt = ReceiptImage(
      filePath: '/path/to/receipt2.jpg',
      extractedAmount: 89.50,
      extractedDate: DateTime.now(),
      extractedMerchant: 'Electronics Store',
      isProcessed: true,
      confidence: 0.92,
    );

    final receiptId = await receiptImageRepository.createReceiptImage(receipt);
    debugPrint('Created receipt: $receiptId');

    // Create expense from receipt data
    final expenseFromReceipt = Expense(
      amount: receipt.extractedAmount!,
      category: 'Electronics',
      description: 'Purchase from ${receipt.extractedMerchant}',
      date: receipt.extractedDate!,
      receiptImageId: receiptId,
    );

    final expenseId = await expenseRepository.createExpense(expenseFromReceipt);
    debugPrint('Created expense from receipt: $expenseId');

    // Check budget for this category
    final budget = await budgetRepository.getBudgetByCategory('Electronics');
    if (budget != null) {
      final spent = await expenseRepository.getTotalForPeriod(
        budget.startDate,
        budget.endDate ?? DateTime.now(),
      );
      final percentage = (spent / budget.amount) * 100;
      debugPrint('Electronics budget: \$${spent.toStringAsFixed(2)} / \$${budget.amount} (${percentage.toStringAsFixed(1)}%)');

      if (percentage >= budget.alertThreshold * 100) {
        debugPrint('⚠️ Budget alert! Exceeded ${(budget.alertThreshold * 100).toStringAsFixed(0)}% threshold');
      }
    }
  }

  // ==================== CLEANUP ====================

  Future<void> cleanup() async {
    debugPrint('\n🧹 CLEANUP\n');

    // Optionally delete all data (be careful with this!)
    // await expenseRepository.deleteAllExpenses();
    // await receiptImageRepository.deleteAllReceiptImages();
    // await budgetRepository.deleteAllBudgets();
    
    debugPrint('Cleanup completed');
  }

  // Run all examples
  Future<void> runAllExamples() async {
    await initialize();
    await expenseExamples();
    await receiptImageExamples();
    await budgetExamples();
    await combinedOperations();
    // await cleanup(); // Uncomment to clear all data
  }
}

/// Quick usage with Riverpod
/// 
/// In your widget:
/// ```dart
/// final expenseRepo = ref.watch(expenseRepositoryProvider);
/// final expenses = await expenseRepo.getAllExpenses();
/// ```
/// 
/// Or in a FutureProvider:
/// ```dart
/// final expensesProvider = FutureProvider<List<Expense>>((ref) async {
///   final repo = ref.watch(expenseRepositoryProvider);
///   return await repo.getAllExpenses();
/// });
/// ```
