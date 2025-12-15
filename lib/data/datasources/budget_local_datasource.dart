import 'package:sqflite/sqflite.dart';
import '../../core/models/budget.dart';
import '../../core/database/database_helper.dart';

class BudgetLocalDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a new budget
  Future<int> insert(Budget budget) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update an existing budget
  Future<int> update(Budget budget) async {
    final db = await _dbHelper.database;
    return await db.update(
      'budgets',
      budget.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  // Delete a budget by id
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all budgets
  Future<List<Budget>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  // Get budget by id
  Future<Budget?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  // Get budget by category
  Future<Budget?> getByCategory(String category) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'category = ?',
      whereArgs: [category],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  // Get all active budgets
  Future<List<Budget>> getActive() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'category ASC',
    );
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  // Get budgets by period
  Future<List<Budget>> getByPeriod(BudgetPeriod period) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'period = ?',
      whereArgs: [period.value],
      orderBy: 'category ASC',
    );
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  // Get currently active budgets (based on dates and is_active flag)
  Future<List<Budget>> getCurrentlyActive() async {
    final now = DateTime.now();
    final db = await _dbHelper.database;
    
    // Get all active budgets and filter by date in Dart
    // (SQLite date comparison can be complex, so doing it in code)
    final allActive = await getActive();
    
    return allActive.where((budget) {
      if (now.isBefore(budget.startDate)) return false;
      if (budget.endDate != null && now.isAfter(budget.endDate!)) return false;
      return true;
    }).toList();
  }

  // Deactivate a budget
  Future<int> deactivate(int id) async {
    final budget = await getById(id);
    if (budget == null) return 0;
    
    return await update(budget.copyWith(isActive: false));
  }

  // Activate a budget
  Future<int> activate(int id) async {
    final budget = await getById(id);
    if (budget == null) return 0;
    
    return await update(budget.copyWith(isActive: true));
  }

  // Check if budget exists for category
  Future<bool> existsForCategory(String category) async {
    final budget = await getByCategory(category);
    return budget != null;
  }

  // Delete all budgets
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete('budgets');
  }

  // Get count of budgets
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM budgets');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get count of active budgets
  Future<int> getActiveCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM budgets WHERE is_active = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
