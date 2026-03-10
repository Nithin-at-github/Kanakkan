import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:kanakkan/data/database/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RESULT TYPES
// ─────────────────────────────────────────────────────────────────────────────

enum BackupRestoreStatus { success, cancelled, error }

class BackupResult {
  final BackupRestoreStatus status;
  final String? message;
  const BackupResult._(this.status, [this.message]);

  factory BackupResult.success([String? msg]) =>
      BackupResult._(BackupRestoreStatus.success, msg);
  factory BackupResult.cancelled() =>
      BackupResult._(BackupRestoreStatus.cancelled);
  factory BackupResult.error(String msg) =>
      BackupResult._(BackupRestoreStatus.error, msg);

  bool get isSuccess => status == BackupRestoreStatus.success;
  bool get isCancelled => status == BackupRestoreStatus.cancelled;
  bool get isError => status == BackupRestoreStatus.error;
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKUP SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  final _db = DatabaseHelper.instance;

  // Expected tables — used to validate a backup file before restore
  static const _requiredTables = [
    'accounts',
    'categories',
    'transactions',
    'category_balances',
    'salary_allocations',
    'salary_allocation_templates',
    'budgets',
  ];

  // ── BACKUP ──────────────────────────────────────────────────────────────────

  /// Copies the DB to a temp file then shares it via the system share sheet.
  Future<BackupResult> backup() async {
    try {
      // Checkpoint WAL so all data is flushed to the main DB file
      final db = await _db.database;
      await db.rawQuery('PRAGMA wal_checkpoint(FULL)');

      final dbPath = await _db.getDatabasePath();
      final source = File(dbPath);

      if (!await source.exists()) {
        return BackupResult.error('Database file not found.');
      }

      // Copy to temp dir with a timestamped name
      final temp = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final backupName = 'kanakkan_backup_$timestamp.db';
      final dest = File('${temp.path}/$backupName');

      await source.copy(dest.path);

      // Share via system sheet — user chooses where to save
      final result = await Share.shareXFiles([
        XFile(dest.path, mimeType: 'application/octet-stream'),
      ], subject: 'Kanakkan Backup — $timestamp');

      // Clean up temp file
      if (await dest.exists()) await dest.delete();

      if (result.status == ShareResultStatus.dismissed) {
        return BackupResult.cancelled();
      }

      return BackupResult.success(backupName);
    } catch (e) {
      return BackupResult.error('Backup failed: $e');
    }
  }

  // ── VALIDATE ────────────────────────────────────────────────────────────────

  /// Opens a candidate file as a read-only SQLite DB and checks:
  /// 1. It is a valid SQLite file
  /// 2. It contains all required tables
  /// 3. Its schema version is not newer than current
  ///
  /// Returns null on success, or an error string on failure.
  Future<String?> validateBackupFile(String filePath) async {
    Database? candidate;
    try {
      candidate = await openReadOnlyDatabase(filePath);

      // Check schema version
      final versionResult = await candidate.rawQuery('PRAGMA user_version');
      final fileVersion = versionResult.first['user_version'] as int? ?? 0;
      if (fileVersion > DatabaseHelper.dbVersion) {
        return 'This backup was created with a newer version of Kanakkan '
            '(v$fileVersion). Please update the app before restoring.';
      }

      // Check required tables
      final tables = await candidate.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final tableNames = tables.map((r) => r['name'] as String).toSet();
      final missing = _requiredTables
          .where((t) => !tableNames.contains(t))
          .toList();
      if (missing.isNotEmpty) {
        return 'Invalid backup file. Missing tables: ${missing.join(', ')}';
      }

      return null; // valid
    } catch (e) {
      return 'Invalid file — not a Kanakkan database.';
    } finally {
      await candidate?.close();
    }
  }

  // ── RESTORE ─────────────────────────────────────────────────────────────────

  /// Full restore flow:
  /// 1. Pick file
  /// 2. Validate
  /// 3. Close DB
  /// 4. Replace file
  /// 5. Reopen DB
  ///
  /// Returns a [BackupResult]. Caller is responsible for reinitializing
  /// all providers after a successful restore.
  Future<BackupResult> pickAndRestore() async {
    try {
      // Step 1 — Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return BackupResult.cancelled();
      }

      final pickedPath = result.files.single.path;
      if (pickedPath == null) {
        return BackupResult.error('Could not access the selected file.');
      }

      // Step 2 — Validate
      final validationError = await validateBackupFile(pickedPath);
      if (validationError != null) {
        return BackupResult.error(validationError);
      }

      // Step 3 — Close current DB
      await _db.closeDatabase();

      // Step 4 — Replace DB file
      final dbPath = await _db.getDatabasePath();
      final source = File(pickedPath);
      await source.copy(dbPath);

      // Step 5 — Reopen (runs migrations if needed)
      await _db.reopenDatabase();

      return BackupResult.success();
    } catch (e) {
      // Attempt to reopen even on error so app stays functional
      try {
        await _db.reopenDatabase();
      } catch (_) {}
      return BackupResult.error('Restore failed: $e');
    }
  }
}
