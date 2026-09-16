import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kanakkan/data/services/backup_service.dart';
import 'package:kanakkan/data/services/drive_backup_service.dart';

/// How long to wait between automatic backups before another one is due.
/// Not user-configurable in v1.
const kAutoBackupInterval = Duration(hours: 24);

class BackupSettingsProvider extends ChangeNotifier {
  static const _enabledKey = 'drive_auto_backup_enabled';
  static const _lastBackupKey = 'drive_last_backup_at';

  final _storage = const FlutterSecureStorage();
  final DriveBackupService _drive;

  BackupSettingsProvider({DriveBackupService? driveBackupService})
    : _drive = driveBackupService ?? DriveBackupService.instance;

  bool _autoBackupEnabled = false;
  DateTime? _lastBackupAt;
  String? _lastBackupError;
  bool _isBackingUp = false;

  bool get autoBackupEnabled => _autoBackupEnabled;
  DateTime? get lastBackupAt => _lastBackupAt;
  String? get lastBackupError => _lastBackupError;
  bool get isBackingUp => _isBackingUp;

  /// Loads persisted settings — call once at app startup, before
  /// [maybeRunAutoBackup].
  Future<void> loadSettings() async {
    final enabled = await _storage.read(key: _enabledKey);
    _autoBackupEnabled = enabled == 'true';

    final lastBackupMs = await _storage.read(key: _lastBackupKey);
    _lastBackupAt = lastBackupMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(int.parse(lastBackupMs));

    notifyListeners();
  }

  /// Turns auto-backup on/off. Enabling triggers an interactive Google
  /// sign-in (must be called from a user gesture, e.g. a Settings toggle).
  /// Throws whatever [DriveBackupService.signIn] throws on failure — the
  /// toggle stays off and the caller can show the error.
  Future<void> setAutoBackupEnabled(bool enabled) async {
    if (enabled == _autoBackupEnabled) return;

    if (enabled) {
      await _drive.signIn();
    } else {
      await _drive.signOut();
    }

    _autoBackupEnabled = enabled;
    _lastBackupError = null;
    notifyListeners();
    await _storage.write(key: _enabledKey, value: enabled.toString());
  }

  /// Runs a backup right now regardless of when the last one happened.
  Future<void> backupNow() async {
    _isBackingUp = true;
    _lastBackupError = null;
    notifyListeners();

    try {
      await _drive.backupNow();
      _lastBackupAt = DateTime.now();
      await _storage.write(
        key: _lastBackupKey,
        value: _lastBackupAt!.millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      _lastBackupError = e.toString();
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  /// Call on app cold start and on resume-from-background. Runs a backup
  /// only if auto-backup is on and it's been more than [kAutoBackupInterval]
  /// since the last successful one (or none has happened yet). Silent,
  /// fire-and-forget — errors land in [lastBackupError] for Settings to show
  /// next time it's opened, nothing interrupts the current screen.
  ///
  /// Skips (without touching [lastBackupAt]/[lastBackupError]) if the local
  /// DB has no accounts or transactions — e.g. right after Delete & Reset, or
  /// on a fresh install — so an empty DB never silently overwrites a real
  /// backup already in Drive. "Back up now" (manual) bypasses this check.
  Future<void> maybeRunAutoBackup() async {
    if (!_autoBackupEnabled || _isBackingUp) return;
    if (!isBackupDue(_lastBackupAt)) return;
    if (await BackupService.instance.isDatabaseEmpty()) return;
    await backupNow();
  }
}

/// True if enough time has passed since [lastBackupAt] (or it's null, i.e.
/// no backup has ever run) that another automatic backup should happen.
/// Pure function, kept separate from [BackupSettingsProvider] so the due/not
/// due decision is testable without mocking Drive/sign-in.
bool isBackupDue(DateTime? lastBackupAt, {DateTime? now}) {
  if (lastBackupAt == null) return true;
  return (now ?? DateTime.now()).difference(lastBackupAt) >= kAutoBackupInterval;
}
