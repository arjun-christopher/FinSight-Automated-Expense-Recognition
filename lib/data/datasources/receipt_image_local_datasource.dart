import 'package:sqflite/sqflite.dart';
import '../../core/models/receipt_image.dart';
import '../../core/database/database_helper.dart';

class ReceiptImageLocalDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a new receipt image
  Future<int> insert(ReceiptImage receiptImage) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'receipt_images',
      receiptImage.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update an existing receipt image
  Future<int> update(ReceiptImage receiptImage) async {
    final db = await _dbHelper.database;
    return await db.update(
      'receipt_images',
      receiptImage.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [receiptImage.id],
    );
  }

  // Delete a receipt image by id
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'receipt_images',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all receipt images
  Future<List<ReceiptImage>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipt_images',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ReceiptImage.fromMap(map)).toList();
  }

  // Get receipt image by id
  Future<ReceiptImage?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipt_images',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ReceiptImage.fromMap(maps.first);
  }

  // Get processed receipt images
  Future<List<ReceiptImage>> getProcessed() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipt_images',
      where: 'is_processed = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ReceiptImage.fromMap(map)).toList();
  }

  // Get unprocessed receipt images
  Future<List<ReceiptImage>> getUnprocessed() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipt_images',
      where: 'is_processed = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ReceiptImage.fromMap(map)).toList();
  }

  // Get receipt images by date range
  Future<List<ReceiptImage>> getByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipt_images',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ReceiptImage.fromMap(map)).toList();
  }

  // Search receipt images by merchant
  Future<List<ReceiptImage>> searchByMerchant(String merchant) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipt_images',
      where: 'extracted_merchant LIKE ?',
      whereArgs: ['%$merchant%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ReceiptImage.fromMap(map)).toList();
  }

  // Get receipts with confidence above threshold
  Future<List<ReceiptImage>> getByConfidenceThreshold(double threshold) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipt_images',
      where: 'confidence >= ?',
      whereArgs: [threshold],
      orderBy: 'confidence DESC',
    );
    return maps.map((map) => ReceiptImage.fromMap(map)).toList();
  }

  // Delete all receipt images
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('receipt_images');
  }

  // Get count of receipt images
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM receipt_images');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get count of unprocessed receipts
  Future<int> getUnprocessedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM receipt_images WHERE is_processed = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
