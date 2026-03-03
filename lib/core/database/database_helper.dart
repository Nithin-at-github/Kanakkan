import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // schema version; bump when making structural changes
  static const int _dbVersion = 2;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kanakkan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        // ensure foreign key support is active
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
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
        initialBalance REAL NOT NULL DEFAULT 0
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
        timestamp INTEGER NOT NULL,
        FOREIGN KEY(fromAccountId) REFERENCES accounts(id) ON DELETE SET NULL,
        FOREIGN KEY(toAccountId)   REFERENCES accounts(id) ON DELETE SET NULL
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
        UNIQUE(categoryId, month, year),
        FOREIGN KEY(categoryId) REFERENCES categories(id) ON DELETE CASCADE
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

  // handle migrations when schema version increases
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // migrate accounts table: drop old columns and add initialBalance
      await db.execute('PRAGMA foreign_keys = OFF');

      await db.execute('''
        CREATE TABLE accounts_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          initialBalance REAL NOT NULL DEFAULT 0
        )
      ''');

      await db.execute('''
        INSERT INTO accounts_new(id, name)
        SELECT id, name FROM accounts;
      ''');

      await db.execute('DROP TABLE accounts');
      await db.execute('ALTER TABLE accounts_new RENAME TO accounts');

      // migrate transactions table to add foreign key constraints
      await db.execute('''
        CREATE TABLE transactions_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          fromAccountId INTEGER,
          toAccountId INTEGER,
          categoryId INTEGER,
          note TEXT,
          timestamp INTEGER NOT NULL,
          FOREIGN KEY(fromAccountId) REFERENCES accounts(id) ON DELETE SET NULL,
          FOREIGN KEY(toAccountId)   REFERENCES accounts(id) ON DELETE SET NULL
        )
      ''');

      await db.execute('''
        INSERT INTO transactions_new(id, type, amount, fromAccountId, toAccountId, categoryId, note, timestamp)
        SELECT id, type, amount, fromAccountId, toAccountId, categoryId, note, timestamp
        FROM transactions;
      ''');

      await db.execute('DROP TABLE transactions');
      await db.execute('ALTER TABLE transactions_new RENAME TO transactions');

      // migrate budgets table to add foreign key
      await db.execute('''
        CREATE TABLE budgets_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          categoryId INTEGER NOT NULL,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          allocatedAmount REAL NOT NULL,
          UNIQUE(categoryId, month, year),
          FOREIGN KEY(categoryId) REFERENCES categories(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        INSERT INTO budgets_new(id, categoryId, month, year, allocatedAmount)
        SELECT id, categoryId, month, year, allocatedAmount FROM budgets;
      ''');

      await db.execute('DROP TABLE budgets');
      await db.execute('ALTER TABLE budgets_new RENAME TO budgets');

      await db.execute('PRAGMA foreign_keys = ON');
    }
  }
}
