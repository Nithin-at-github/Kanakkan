import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // Still version 1 (development phase)
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kanakkan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: _dbVersion, onCreate: _createDB);
  }

  // =====================================================
  // CREATE DATABASE
  // =====================================================

  Future<void> _createDB(Database db, int version) async {
    // ================= ACCOUNTS =================
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        entityType TEXT NOT NULL,
        mediumType TEXT NOT NULL
      )
    ''');

    // ================= CATEGORIES =================
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        UNIQUE(name, type)
      )
    ''');

    // ================= TRANSACTIONS =================
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        fromAccountId INTEGER,
        toAccountId INTEGER,
        categoryId INTEGER,
        note TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');

    // ================= BUDGETS =================
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        allocatedAmount REAL NOT NULL,
        UNIQUE(categoryId, month, year)
      )
    ''');

    // =====================================================
    // INDEXES (PERFORMANCE OPTIMIZATION)
    // =====================================================

    /// Fast date filtering (Dashboard & reports)
    await db.execute('''
      CREATE INDEX idx_transactions_timestamp
      ON transactions(timestamp)
    ''');

    /// Fast category spending lookup (Budgets)
    await db.execute('''
      CREATE INDEX idx_transactions_category
      ON transactions(categoryId)
    ''');

    /// Fast account-based queries
    await db.execute('''
      CREATE INDEX idx_transactions_accounts
      ON transactions(fromAccountId, toAccountId)
    ''');

    /// Faster budget period lookup
    await db.execute('''
      CREATE INDEX idx_budgets_period
      ON budgets(categoryId, month, year)
    ''');

    await db.execute('''
     CREATE TABLE category_balances(
      categoryId INTEGER PRIMARY KEY,
      balance REAL NOT NULL DEFAULT 0
    )
    ''');
  }
}
