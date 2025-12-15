import '../../core/models/receipt_image.dart';
import '../datasources/receipt_image_local_datasource.dart';

class ReceiptImageRepository {
  final ReceiptImageLocalDataSource _localDataSource;

  ReceiptImageRepository(this._localDataSource);

  // Create a new receipt image
  Future<int> createReceiptImage(ReceiptImage receiptImage) async {
    try {
      return await _localDataSource.insert(receiptImage);
    } catch (e) {
      throw Exception('Failed to create receipt image: $e');
    }
  }

  // Update an existing receipt image
  Future<void> updateReceiptImage(ReceiptImage receiptImage) async {
    try {
      final result = await _localDataSource.update(receiptImage);
      if (result == 0) {
        throw Exception('Receipt image not found');
      }
    } catch (e) {
      throw Exception('Failed to update receipt image: $e');
    }
  }

  // Delete a receipt image
  Future<void> deleteReceiptImage(int id) async {
    try {
      final result = await _localDataSource.delete(id);
      if (result == 0) {
        throw Exception('Receipt image not found');
      }
    } catch (e) {
      throw Exception('Failed to delete receipt image: $e');
    }
  }

  // Get all receipt images
  Future<List<ReceiptImage>> getAllReceiptImages() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get receipt images: $e');
    }
  }

  // Get receipt image by id
  Future<ReceiptImage?> getReceiptImageById(int id) async {
    try {
      return await _localDataSource.getById(id);
    } catch (e) {
      throw Exception('Failed to get receipt image: $e');
    }
  }

  // Get processed receipt images
  Future<List<ReceiptImage>> getProcessedReceipts() async {
    try {
      return await _localDataSource.getProcessed();
    } catch (e) {
      throw Exception('Failed to get processed receipts: $e');
    }
  }

  // Get unprocessed receipt images
  Future<List<ReceiptImage>> getUnprocessedReceipts() async {
    try {
      return await _localDataSource.getUnprocessed();
    } catch (e) {
      throw Exception('Failed to get unprocessed receipts: $e');
    }
  }

  // Get receipts by date range
  Future<List<ReceiptImage>> getReceiptsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _localDataSource.getByDateRange(startDate, endDate);
    } catch (e) {
      throw Exception('Failed to get receipts by date range: $e');
    }
  }

  // Search receipts by merchant
  Future<List<ReceiptImage>> searchByMerchant(String merchant) async {
    try {
      return await _localDataSource.searchByMerchant(merchant);
    } catch (e) {
      throw Exception('Failed to search receipts by merchant: $e');
    }
  }

  // Get receipts with high confidence
  Future<List<ReceiptImage>> getHighConfidenceReceipts(double threshold) async {
    try {
      return await _localDataSource.getByConfidenceThreshold(threshold);
    } catch (e) {
      throw Exception('Failed to get high confidence receipts: $e');
    }
  }

  // Delete all receipt images
  Future<void> deleteAllReceiptImages() async {
    try {
      await _localDataSource.deleteAll();
    } catch (e) {
      throw Exception('Failed to delete all receipt images: $e');
    }
  }

  // Get receipt count
  Future<int> getReceiptCount() async {
    try {
      return await _localDataSource.getCount();
    } catch (e) {
      throw Exception('Failed to get receipt count: $e');
    }
  }

  // Get unprocessed receipt count
  Future<int> getUnprocessedCount() async {
    try {
      return await _localDataSource.getUnprocessedCount();
    } catch (e) {
      throw Exception('Failed to get unprocessed count: $e');
    }
  }
}
