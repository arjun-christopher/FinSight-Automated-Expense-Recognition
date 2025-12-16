import 'package:sqflite/sqflite.dart';
import '../../core/models/expense.dart';
import '../../core/database/database_helper.dart';

class ExpenseLocalDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a new expense
  Future<int> insert(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update an existing expense
  Future<int> update(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.update(
      'expenses',
      expense.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Delete an expense by id
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all expenses
  Future<List<Expense>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  // Get expense by id
  Future<Expense?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Expense.fromMap(maps.first);
  }

  // Get expenses by category
  Future<List<Expense>> getByCategory(String category) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  // Get expenses within a date range
  Future<List<Expense>> getByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  // Get expenses for current month
  Future<List<Expense>> getCurrentMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return getByDateRange(startOfMonth, endOfMonth);
  }

  // Get total amount by category
  Future<Map<String, double>> getTotalByCategory() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM expenses GROUP BY category',
    );
    
    final Map<String, double> totals = {};
    for (var row in result) {
      totals[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return totals;
  }

  // Get total amount for a specific period
  Future<double> getTotalByPeriod(DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE date >= ? AND date <= ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    
    if (result.isEmpty || result.first['total'] == null) return 0.0;
    return (result.first['total'] as num).toDouble();
  }

  // Search expenses by description
  Future<List<Expense>> search(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'description LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  // Delete all expenses
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('expenses');
  }

  // Get count of expenses
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM expenses');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
