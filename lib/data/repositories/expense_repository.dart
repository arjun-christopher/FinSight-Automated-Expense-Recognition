import '../../core/models/expense.dart';
import '../datasources/expense_local_datasource.dart';

class ExpenseRepository {
  final ExpenseLocalDataSource _localDataSource;

  ExpenseRepository(this._localDataSource);

  // Create a new expense
  Future<int> createExpense(Expense expense) async {
    try {
      return await _localDataSource.insert(expense);
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  // Update an existing expense
  Future<void> updateExpense(Expense expense) async {
    try {
      final result = await _localDataSource.update(expense);
      if (result == 0) {
        throw Exception('Expense not found');
      }
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  // Delete an expense
  Future<void> deleteExpense(int id) async {
    try {
      final result = await _localDataSource.delete(id);
      if (result == 0) {
        throw Exception('Expense not found');
      }
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get expenses: $e');
    }
  }

  // Get expense by id
  Future<Expense?> getExpenseById(int id) async {
    try {
      return await _localDataSource.getById(id);
    } catch (e) {
      throw Exception('Failed to get expense: $e');
    }
  }

  // Get expenses by category
  Future<List<Expense>> getExpensesByCategory(String category) async {
    try {
      return await _localDataSource.getByCategory(category);
    } catch (e) {
      throw Exception('Failed to get expenses by category: $e');
    }
  }

  // Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _localDataSource.getByDateRange(startDate, endDate);
    } catch (e) {
      throw Exception('Failed to get expenses by date range: $e');
    }
  }

  // Get current month expenses
  Future<List<Expense>> getCurrentMonthExpenses() async {
    try {
      return await _localDataSource.getCurrentMonth();
    } catch (e) {
      throw Exception('Failed to get current month expenses: $e');
    }
  }

  // Get total by category
  Future<Map<String, double>> getTotalByCategory() async {
    try {
      return await _localDataSource.getTotalByCategory();
    } catch (e) {
      throw Exception('Failed to get total by category: $e');
    }
  }

  // Get total for period
  Future<double> getTotalForPeriod(DateTime startDate, DateTime endDate) async {
    try {
      return await _localDataSource.getTotalByPeriod(startDate, endDate);
    } catch (e) {
      throw Exception('Failed to get total for period: $e');
    }
  }

  // Search expenses
  Future<List<Expense>> searchExpenses(String query) async {
    try {
      return await _localDataSource.search(query);
    } catch (e) {
      throw Exception('Failed to search expenses: $e');
    }
  }

  // Delete all expenses
  Future<void> deleteAllExpenses() async {
    try {
      await _localDataSource.deleteAll();
    } catch (e) {
      throw Exception('Failed to delete all expenses: $e');
    }
  }

  // Get expense count
  Future<int> getExpenseCount() async {
    try {
      return await _localDataSource.getCount();
    } catch (e) {
      throw Exception('Failed to get expense count: $e');
    }
  }
}
