import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finsight.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Expense table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        payment_method TEXT,
        receipt_image_id INTEGER,
        tags TEXT,
        is_recurring INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        currency TEXT DEFAULT 'USD',
        FOREIGN KEY (receipt_image_id) REFERENCES receipt_images (id) ON DELETE SET NULL
      )
    ''');

    // Create index for faster date queries
    await db.execute('''
      CREATE INDEX idx_expenses_date ON expenses(date)
    ''');

    // Create index for category queries
    await db.execute('''
      CREATE INDEX idx_expenses_category ON expenses(category)
    ''');

    // Create ReceiptImage table
    await db.execute('''
      CREATE TABLE receipt_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL,
        extracted_text TEXT,
        confidence REAL,
        extracted_amount REAL,
        extracted_date TEXT,
        extracted_merchant TEXT,
        is_processed INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create Budget table
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        monthly_limit REAL NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        UNIQUE(category, year, month)
      )
    ''');

    // Create index for budget queries
    await db.execute('''
      CREATE INDEX idx_budgets_date ON budgets(year, month)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_budgets_category ON budgets(category)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add currency column to existing expenses table
      await db.execute('ALTER TABLE expenses ADD COLUMN currency TEXT DEFAULT "USD"');
    }
    // if (oldVersion < 3) {
    //   await db.execute('ALTER TABLE expenses ADD COLUMN new_field TEXT');
    // }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finsight.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
