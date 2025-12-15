import '../../core/models/budget.dart';
import '../datasources/budget_local_datasource.dart';

class BudgetRepository {
  final BudgetLocalDataSource _localDataSource;

  BudgetRepository(this._localDataSource);

  // Create a new budget
  Future<int> createBudget(Budget budget) async {
    try {
      // Check if budget already exists for this category
      final exists = await _localDataSource.existsForCategory(budget.category);
      if (exists) {
        throw Exception('Budget already exists for category: ${budget.category}');
      }
      return await _localDataSource.insert(budget);
    } catch (e) {
      throw Exception('Failed to create budget: $e');
    }
  }

  // Update an existing budget
  Future<void> updateBudget(Budget budget) async {
    try {
      final result = await _localDataSource.update(budget);
      if (result == 0) {
        throw Exception('Budget not found');
      }
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  // Delete a budget
  Future<void> deleteBudget(int id) async {
    try {
      final result = await _localDataSource.delete(id);
      if (result == 0) {
        throw Exception('Budget not found');
      }
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }

  // Get all budgets
  Future<List<Budget>> getAllBudgets() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get budgets: $e');
    }
  }

  // Get budget by id
  Future<Budget?> getBudgetById(int id) async {
    try {
      return await _localDataSource.getById(id);
    } catch (e) {
      throw Exception('Failed to get budget: $e');
    }
  }

  // Get budget by category
  Future<Budget?> getBudgetByCategory(String category) async {
    try {
      return await _localDataSource.getByCategory(category);
    } catch (e) {
      throw Exception('Failed to get budget by category: $e');
    }
  }

  // Get active budgets
  Future<List<Budget>> getActiveBudgets() async {
    try {
      return await _localDataSource.getActive();
    } catch (e) {
      throw Exception('Failed to get active budgets: $e');
    }
  }

  // Get budgets by period
  Future<List<Budget>> getBudgetsByPeriod(BudgetPeriod period) async {
    try {
      return await _localDataSource.getByPeriod(period);
    } catch (e) {
      throw Exception('Failed to get budgets by period: $e');
    }
  }

  // Get currently active budgets (filtered by dates)
  Future<List<Budget>> getCurrentlyActiveBudgets() async {
    try {
      return await _localDataSource.getCurrentlyActive();
    } catch (e) {
      throw Exception('Failed to get currently active budgets: $e');
    }
  }

  // Deactivate a budget
  Future<void> deactivateBudget(int id) async {
    try {
      final result = await _localDataSource.deactivate(id);
      if (result == 0) {
        throw Exception('Budget not found');
      }
    } catch (e) {
      throw Exception('Failed to deactivate budget: $e');
    }
  }

  // Activate a budget
  Future<void> activateBudget(int id) async {
    try {
      final result = await _localDataSource.activate(id);
      if (result == 0) {
        throw Exception('Budget not found');
      }
    } catch (e) {
      throw Exception('Failed to activate budget: $e');
    }
  }

  // Check if budget exists for category
  Future<bool> budgetExistsForCategory(String category) async {
    try {
      return await _localDataSource.existsForCategory(category);
    } catch (e) {
      throw Exception('Failed to check budget existence: $e');
    }
  }

  // Delete all budgets
  Future<void> deleteAllBudgets() async {
    try {
      await _localDataSource.deleteAll();
    } catch (e) {
      throw Exception('Failed to delete all budgets: $e');
    }
  }

  // Get budget count
  Future<int> getBudgetCount() async {
    try {
      return await _localDataSource.getCount();
    } catch (e) {
      throw Exception('Failed to get budget count: $e');
    }
  }

  // Get active budget count
  Future<int> getActiveBudgetCount() async {
    try {
      return await _localDataSource.getActiveCount();
    } catch (e) {
      throw Exception('Failed to get active budget count: $e');
    }
  }
}
