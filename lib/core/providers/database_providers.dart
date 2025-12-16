import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../../data/datasources/expense_local_datasource.dart';
import '../../data/datasources/receipt_image_local_datasource.dart';
import '../../data/datasources/budget_local_datasource.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/receipt_image_repository.dart';
import '../../data/repositories/budget_repository.dart';

// Database Helper Provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// Data Source Providers
final expenseLocalDataSourceProvider = Provider<ExpenseLocalDataSource>((ref) {
  return ExpenseLocalDataSource();
});

final receiptImageLocalDataSourceProvider = Provider<ReceiptImageLocalDataSource>((ref) {
  return ReceiptImageLocalDataSource();
});

final budgetLocalDataSourceProvider = Provider<BudgetLocalDataSource>((ref) {
  return BudgetLocalDataSource();
});

// Repository Providers
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final dataSource = ref.watch(expenseLocalDataSourceProvider);
  return ExpenseRepository(dataSource);
});

final receiptImageRepositoryProvider = Provider<ReceiptImageRepository>((ref) {
  final dataSource = ref.watch(receiptImageLocalDataSourceProvider);
  return ReceiptImageRepository(dataSource);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final dataSource = ref.watch(budgetLocalDataSourceProvider);
  return BudgetRepository(dataSource);
});

// Data Providers
final allExpensesProvider = FutureProvider((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getAllExpenses();
});

final allBudgetsProvider = FutureProvider((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return await repository.getAllBudgets();
});
