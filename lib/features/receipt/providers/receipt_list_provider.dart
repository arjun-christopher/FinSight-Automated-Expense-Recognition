import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/receipt_image.dart';
import '../../../core/models/expense.dart';
import '../../../data/datasources/receipt_image_local_datasource.dart';
import '../../../data/repositories/receipt_image_repository.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../core/providers/database_providers.dart';
import '../../../services/receipt_storage_service.dart';

// Provider for receipt storage service
final receiptStorageServiceProvider = Provider<ReceiptStorageService>((ref) {
  return ReceiptStorageService();
});

// Provider for receipt image datasource
final receiptImageLocalDataSourceProvider = Provider<ReceiptImageLocalDataSource>((ref) {
  return ReceiptImageLocalDataSource();
});

// Provider for receipt image repository
final receiptImageRepositoryProvider = Provider<ReceiptImageRepository>((ref) {
  final dataSource = ref.watch(receiptImageLocalDataSourceProvider);
  return ReceiptImageRepository(dataSource);
});

// Combined item for receipts and expenses
class ReceiptExpenseItem {
  final ReceiptImage? receipt;
  final Expense? expense;
  final DateTime date;
  final String? merchant;
  final double? amount;
  final String? category;
  final String? paymentMethod;
  final bool hasReceipt;

  ReceiptExpenseItem({
    this.receipt,
    this.expense,
    required this.date,
    this.merchant,
    this.amount,
    this.category,
    this.paymentMethod,
    required this.hasReceipt,
  });

  factory ReceiptExpenseItem.fromReceipt(ReceiptImage receipt) {
    return ReceiptExpenseItem(
      receipt: receipt,
      date: receipt.extractedDate ?? receipt.createdAt,
      merchant: receipt.extractedMerchant,
      amount: receipt.extractedAmount,
      hasReceipt: true,
    );
  }

  factory ReceiptExpenseItem.fromExpense(Expense expense) {
    return ReceiptExpenseItem(
      expense: expense,
      date: expense.date,
      merchant: expense.description,
      amount: expense.amount,
      category: expense.category,
      paymentMethod: expense.paymentMethod,
      hasReceipt: false,
    );
  }
}

// State for receipt list screen
class ReceiptListState {
  final List<ReceiptImage> receipts;
  final List<Expense> expenses;
  final bool isLoading;
  final String? error;
  final ReceiptFilterType filterType;
  final String searchQuery;
  final ReceiptViewMode viewMode;

  const ReceiptListState({
    this.receipts = const [],
    this.expenses = const [],
    this.isLoading = false,
    this.error,
    this.filterType = ReceiptFilterType.all,
    this.searchQuery = '',
    this.viewMode = ReceiptViewMode.grid,
  });

  ReceiptListState copyWith({
    List<ReceiptImage>? receipts,
    List<Expense>? expenses,
    bool? isLoading,
    String? error,
    ReceiptFilterType? filterType,
    String? searchQuery,
    ReceiptViewMode? viewMode,
  }) {
    return ReceiptListState(
      receipts: receipts ?? this.receipts,
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterType: filterType ?? this.filterType,
      searchQuery: searchQuery ?? this.searchQuery,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  List<ReceiptExpenseItem> get filteredItems {
    // Combine receipts and expenses without receipt images
    final items = <ReceiptExpenseItem>[];
    
    // Add all receipts
    for (final receipt in receipts) {
      items.add(ReceiptExpenseItem.fromReceipt(receipt));
    }
    
    // Add expenses that don't have receipt images
    for (final expense in expenses) {
      if (expense.receiptImageId == null) {
        items.add(ReceiptExpenseItem.fromExpense(expense));
      }
    }
    
    // Sort by date descending
    items.sort((a, b) => b.date.compareTo(a.date));
    
    var result = items;

    // Apply filter
    switch (filterType) {
      case ReceiptFilterType.processed:
        result = result.where((item) => item.receipt?.isProcessed ?? true).toList();
        break;
      case ReceiptFilterType.unprocessed:
        result = result.where((item) => item.receipt?.isProcessed == false).toList();
        break;
      case ReceiptFilterType.withReceipt:
        result = result.where((item) => item.hasReceipt).toList();
        break;
      case ReceiptFilterType.manualEntry:
        result = result.where((item) => !item.hasReceipt).toList();
        break;
      case ReceiptFilterType.all:
        break;
    }

    // Apply search
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((item) {
        final merchant = item.merchant?.toLowerCase() ?? '';
        final category = item.category?.toLowerCase() ?? '';
        final amount = item.amount?.toString() ?? '';
        final date = item.date.toString();
        return merchant.contains(query) ||
            category.contains(query) ||
            amount.contains(query) ||
            date.contains(query);
      }).toList();
    }

    return result;
  }
}

enum ReceiptFilterType {
  all,
  processed,
  unprocessed,
  withReceipt,
  manualEntry,
}

enum ReceiptViewMode {
  grid,
  list,
}

// Receipt list provider
class ReceiptListNotifier extends StateNotifier<ReceiptListState> {
  final ReceiptImageRepository _repository;
  final ExpenseRepository _expenseRepository;
  final ReceiptStorageService _storageService;

  ReceiptListNotifier(this._repository, this._expenseRepository, this._storageService)
      : super(const ReceiptListState());

  // Load all receipts and expenses
  Future<void> loadReceipts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final receipts = await _repository.getAllReceiptImages();
      final expenses = await _expenseRepository.getAllExpenses();
      state = state.copyWith(
        receipts: receipts,
        expenses: expenses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load receipts: $e',
      );
    }
  }

  // Refresh receipts
  Future<void> refreshReceipts() async {
    await loadReceipts();
  }

  // Delete a receipt
  Future<bool> deleteReceipt(int id, String filePath) async {
    try {
      // Delete from database
      await _repository.deleteReceiptImage(id);

      // Delete the file
      await _storageService.deleteReceiptImage(filePath);

      // Refresh the list
      await loadReceipts();

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete receipt: $e');
      return false;
    }
  }

  // Set filter type
  void setFilterType(ReceiptFilterType filterType) {
    state = state.copyWith(filterType: filterType);
  }

  // Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // Set view mode
  void setViewMode(ReceiptViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Get receipt by id
  Future<ReceiptImage?> getReceiptById(int id) async {
    try {
      return await _repository.getReceiptImageById(id);
    } catch (e) {
      state = state.copyWith(error: 'Failed to get receipt: $e');
      return null;
    }
  }

  // Check if receipt file exists
  Future<bool> checkReceiptFileExists(String filePath) async {
    return await _storageService.receiptImageExists(filePath);
  }

  // Get total storage used
  Future<String> getTotalStorageUsed() async {
    final bytes = await _storageService.getTotalStorageUsed();
    return _formatBytes(bytes);
  }

  // Cleanup orphaned files
  Future<int> cleanupOrphanedFiles() async {
    try {
      final allReceipts = await _repository.getAllReceiptImages();
      final validPaths = allReceipts.map((r) => r.filePath).toList();
      return await _storageService.cleanupOrphanedFiles(validPaths);
    } catch (e) {
      return 0;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// Receipt list provider
final receiptListProvider =
    StateNotifierProvider<ReceiptListNotifier, ReceiptListState>((ref) {
  final repository = ref.watch(receiptImageRepositoryProvider);
  final expenseRepository = ref.watch(expenseRepositoryProvider);
  final storageService = ref.watch(receiptStorageServiceProvider);
  return ReceiptListNotifier(repository, expenseRepository, storageService);
});

// Individual receipt provider
final receiptDetailProvider = FutureProvider.family<ReceiptImage?, int>((ref, id) async {
  final repository = ref.watch(receiptImageRepositoryProvider);
  return await repository.getReceiptImageById(id);
});

// Receipt file provider
final receiptFileProvider = FutureProvider.family<File?, String>((ref, filePath) async {
  final storageService = ref.watch(receiptStorageServiceProvider);
  return await storageService.getReceiptImageFile(filePath);
});
