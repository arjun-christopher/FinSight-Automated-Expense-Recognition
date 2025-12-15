import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/receipt_image.dart';
import '../../../data/datasources/receipt_image_local_datasource.dart';
import '../../../data/repositories/receipt_image_repository.dart';
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

// State for receipt list screen
class ReceiptListState {
  final List<ReceiptImage> receipts;
  final bool isLoading;
  final String? error;
  final ReceiptFilterType filterType;
  final String searchQuery;
  final ReceiptViewMode viewMode;

  const ReceiptListState({
    this.receipts = const [],
    this.isLoading = false,
    this.error,
    this.filterType = ReceiptFilterType.all,
    this.searchQuery = '',
    this.viewMode = ReceiptViewMode.grid,
  });

  ReceiptListState copyWith({
    List<ReceiptImage>? receipts,
    bool? isLoading,
    String? error,
    ReceiptFilterType? filterType,
    String? searchQuery,
    ReceiptViewMode? viewMode,
  }) {
    return ReceiptListState(
      receipts: receipts ?? this.receipts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterType: filterType ?? this.filterType,
      searchQuery: searchQuery ?? this.searchQuery,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  List<ReceiptImage> get filteredReceipts {
    var result = receipts;

    // Apply filter
    switch (filterType) {
      case ReceiptFilterType.processed:
        result = result.where((r) => r.isProcessed).toList();
        break;
      case ReceiptFilterType.unprocessed:
        result = result.where((r) => !r.isProcessed).toList();
        break;
      case ReceiptFilterType.all:
        break;
    }

    // Apply search
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((receipt) {
        final merchant = receipt.extractedMerchant?.toLowerCase() ?? '';
        final amount = receipt.extractedAmount?.toString() ?? '';
        final date = receipt.extractedDate?.toString() ?? '';
        return merchant.contains(query) ||
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
}

enum ReceiptViewMode {
  grid,
  list,
}

// Receipt list provider
class ReceiptListNotifier extends StateNotifier<ReceiptListState> {
  final ReceiptImageRepository _repository;
  final ReceiptStorageService _storageService;

  ReceiptListNotifier(this._repository, this._storageService)
      : super(const ReceiptListState());

  // Load all receipts
  Future<void> loadReceipts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final receipts = await _repository.getAllReceiptImages();
      state = state.copyWith(
        receipts: receipts,
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
  final storageService = ref.watch(receiptStorageServiceProvider);
  return ReceiptListNotifier(repository, storageService);
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
