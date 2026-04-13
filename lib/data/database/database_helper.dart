import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Bumped to 11: Trigger wallet reconciliation for subcategory rollup fix
  static const int _dbVersion = 11;
  static int get dbVersion => _dbVersion;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("kanakkan.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
    );
  }

  // =====================================================
  // CREATE DATABASE
  // =====================================================

  Future<void> _createDB(Database db, int version) async {
    await _createCoreTables(db);
    await _createWalletTables(db);
    await _createIndexes(db);
  }

  // =====================================================
  // CORE TABLES
  // =====================================================

  Future<void> _createCoreTables(Database db) async {
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        initialBalance REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        parentId INTEGER,
        isSalaryWallet INTEGER NOT NULL DEFAULT 0,
        linkedAccountId INTEGER,
        excludeFromAnalysis INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(parentId) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

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
        transferGroupId TEXT,
        FOREIGN KEY(fromAccountId) REFERENCES accounts(id) ON DELETE SET NULL,
        FOREIGN KEY(toAccountId) REFERENCES accounts(id) ON DELETE SET NULL
      )
    ''');

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
  }

  // =====================================================
  // WALLET / CATEGORY BALANCE TABLES
  // =====================================================

  Future<void> _createWalletTables(Database db) async {
    await db.execute('''
      CREATE TABLE category_balances(
        categoryId INTEGER PRIMARY KEY,
        balance REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE salary_allocation_templates(
        categoryId INTEGER PRIMARY KEY,
        amount REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE salary_allocations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        salaryTransactionId INTEGER NOT NULL,
        categoryId INTEGER NOT NULL,
        amount REAL NOT NULL
      )
    ''');

    await _createWalletSplitsTable(db);
  }

  /// Records exactly how much was deducted from each wallet per expense.
  /// For a simple expense: one row (categoryId, amount).
  /// For a salary-fallback expense: two rows — category wallet + salary wallet.
  Future<void> _createWalletSplitsTable(Database db) async {
    await db.execute('''
      CREATE TABLE transaction_wallet_splits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId INTEGER NOT NULL,
        categoryId INTEGER NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY(transactionId) REFERENCES transactions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_wallet_splits_tx
      ON transaction_wallet_splits(transactionId)
    ''');
  }

  // =====================================================
  // INDEXES (PERFORMANCE)
  // =====================================================

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE INDEX idx_transactions_timestamp
      ON transactions(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_category
      ON transactions(categoryId)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_accounts
      ON transactions(fromAccountId, toAccountId)
    ''');

    await db.execute('''
      CREATE INDEX idx_budgets_period
      ON budgets(categoryId, month, year)
    ''');

    await db.execute('''
      CREATE INDEX idx_salary_allocations_tx
      ON salary_allocations(salaryTransactionId)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_transfer_group
      ON transactions(transferGroupId)
    ''');
  }

  // =====================================================
  // MIGRATIONS
  // =====================================================

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("PRAGMA foreign_keys = OFF");

      await db.execute('''
        CREATE TABLE accounts_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          initialBalance REAL NOT NULL DEFAULT 0
        )
      ''');
      await db.execute(
        'INSERT OR IGNORE INTO accounts_new(id,name) SELECT id,name FROM accounts',
      );
      await db.execute("DROP TABLE accounts");
      await db.execute("ALTER TABLE accounts_new RENAME TO accounts");

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
          FOREIGN KEY(toAccountId) REFERENCES accounts(id) ON DELETE SET NULL
        )
      ''');
      await db.execute(
        'INSERT INTO transactions_new SELECT * FROM transactions',
      );
      await db.execute("DROP TABLE transactions");
      await db.execute("ALTER TABLE transactions_new RENAME TO transactions");

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
      await db.execute('INSERT INTO budgets_new SELECT * FROM budgets');
      await db.execute("DROP TABLE budgets");
      await db.execute("ALTER TABLE budgets_new RENAME TO budgets");

      await _createWalletTables(db);
      await db.execute("PRAGMA foreign_keys = ON");
    }

    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN transferGroupId TEXT
      ''');
      await db.execute('''
        CREATE INDEX idx_transactions_transfer_group
        ON transactions(transferGroupId)
      ''');
    }

    if (oldVersion < 4) {
      // Add wallet splits table — tracks which wallets were debited per expense
      // and how much, supporting the salary-fallback partial deduction feature.
      await _createWalletSplitsTable(db);
    }

    if (oldVersion < 5) {
      // Add parentId to categories for subcategory support.
      // NULL = top-level category, non-null = subcategory of parentId.
      await db.execute('''
        ALTER TABLE categories ADD COLUMN parentId INTEGER
        REFERENCES categories(id) ON DELETE CASCADE
      ''');

      await db.execute('''
        CREATE INDEX idx_categories_parent
        ON categories(parentId)
      ''');
    }

    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN isSalaryWallet INTEGER NOT NULL DEFAULT 0',
      );
      // Auto-migrate existing "salary" named category
      await db.execute(
        "UPDATE categories SET isSalaryWallet = 1 WHERE LOWER(name) = 'salary' AND type = 'income'",
      );
    }

    if (oldVersion < 8) {
      // Rebuild categories table: remove `type` column, add `linkedAccountId`.
      // We use a safer rename-copy-drop pattern to avoid self-referencing 
      // foreign key issues (the 'no such table: categories_new' error).
      await db.execute('PRAGMA foreign_keys = OFF');

      // 1. Rename existing table to a temporary name
      await db.execute('ALTER TABLE categories RENAME TO categories_old');

      // 2. Create the new table with the FINAL name immediately
      // This ensures the self-referencing FK points to 'categories', not 'categories_old' or 'categories_new'.
      await db.execute('''
        CREATE TABLE categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          parentId INTEGER,
          isSalaryWallet INTEGER NOT NULL DEFAULT 0,
          linkedAccountId INTEGER,
          FOREIGN KEY(parentId) REFERENCES categories(id) ON DELETE CASCADE
        )
      ''');

      // 3. Copy existing rows from the old table
      // We check if 'type' column exists by querying the table info or just trying a safe SELECT.
      // Since version 7 might have already removed it, we select only the needed columns.
      await db.execute('''
        INSERT OR IGNORE INTO categories(id, name, parentId, isSalaryWallet)
        SELECT id, name, parentId, isSalaryWallet FROM categories_old
      ''');

      // 4. Drop the old table
      await db.execute('DROP TABLE categories_old');

      // 5. Recreate index on the new table
      await db.execute('''
        CREATE INDEX idx_categories_parent ON categories(parentId)
      ''');

      await db.execute('PRAGMA foreign_keys = ON');
    }

    if (oldVersion < 9) {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN excludeFromAnalysis INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  /// Returns the absolute path to the database file.
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'kanakkan.db');
  }

  /// Closes the database connection and clears the cached instance.
  /// Must be called before replacing the DB file during restore.
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Reopens the database after a restore.
  /// Runs migrations if the restored DB is on an older version.
  Future<void> reopenDatabase() async {
    _database = await _initDB('kanakkan.db');
  }

  /// Deletes the database completely and re-initializes it.
  Future<void> resetDatabase() async {
    await closeDatabase();
    final path = await getDatabasePath();
    await deleteDatabase(path);
    await reopenDatabase();
  }
}
