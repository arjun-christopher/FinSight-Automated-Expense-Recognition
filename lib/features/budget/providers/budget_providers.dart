import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/budget.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../services/budget_service.dart';
import '../../../core/providers/database_providers.dart';

/// Provider for BudgetRepository
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final dataSource = ref.watch(budgetLocalDataSourceProvider);
  return BudgetRepository(dataSource);
});

/// Provider for BudgetService
final budgetServiceProvider = Provider<BudgetService>((ref) {
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  return BudgetService(budgetRepo, expenseRepo);
});

/// Provider for list of all budgets
final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getAllBudgets();
});

/// Provider for active budgets only
final activeBudgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getCurrentlyActiveBudgets();
});

/// Provider for all budget statuses
final budgetStatusesProvider = FutureProvider<List<BudgetStatus>>((ref) async {
  final service = ref.watch(budgetServiceProvider);
  return service.getAllBudgetStatuses();
});

/// Provider for budgets with alerts
final budgetAlertsProvider = FutureProvider<List<BudgetStatus>>((ref) async {
  final service = ref.watch(budgetServiceProvider);
  return service.getBudgetsWithAlerts();
});

/// Provider for budget health summary
final budgetHealthSummaryProvider = FutureProvider<BudgetHealthSummary>((ref) async {
  final service = ref.watch(budgetServiceProvider);
  return service.getBudgetHealthSummary();
});

/// Provider for budget status by category
final budgetStatusByCategoryProvider = FutureProvider.family<BudgetStatus?, String>(
  (ref, category) async {
    final service = ref.watch(budgetServiceProvider);
    return service.getBudgetStatus(category: category);
  },
);

/// StateNotifier for managing budget list state
class BudgetListNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  final BudgetRepository _repository;

  BudgetListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    state = const AsyncValue.loading();
    try {
      final budgets = await _repository.getAllBudgets();
      state = AsyncValue.data(budgets);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createBudget(Budget budget) async {
    try {
      await _repository.createBudget(budget);
      await loadBudgets();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      await _repository.updateBudget(budget);
      await loadBudgets();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBudget(int id) async {
    try {
      await _repository.deleteBudget(id);
      await loadBudgets();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleBudgetActive(Budget budget) async {
    try {
      if (budget.isActive) {
        await _repository.deactivateBudget(budget.id!);
      } else {
        await _repository.activateBudget(budget.id!);
      }
      await loadBudgets();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for budget list with state management
final budgetListProvider = StateNotifierProvider<BudgetListNotifier, AsyncValue<List<Budget>>>(
  (ref) {
    final repository = ref.watch(budgetRepositoryProvider);
    return BudgetListNotifier(repository);
  },
);
