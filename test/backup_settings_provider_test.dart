import 'package:flutter_test/flutter_test.dart';
import 'package:kanakkan/presentation/providers/backup_settings_provider.dart';

void main() {
  group('isBackupDue', () {
    test('is due when no backup has ever run', () {
      expect(isBackupDue(null), isTrue);
    });

    test('is not due right after a backup', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final lastBackup = now.subtract(const Duration(hours: 1));
      expect(isBackupDue(lastBackup, now: now), isFalse);
    });

    test('is not due just under the interval', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final lastBackup = now.subtract(
        kAutoBackupInterval - const Duration(minutes: 1),
      );
      expect(isBackupDue(lastBackup, now: now), isFalse);
    });

    test('is due once the interval has fully elapsed', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final lastBackup = now.subtract(kAutoBackupInterval);
      expect(isBackupDue(lastBackup, now: now), isTrue);
    });

    test('is due well past the interval', () {
      final now = DateTime(2026, 1, 10, 12, 0);
      final lastBackup = now.subtract(const Duration(days: 3));
      expect(isBackupDue(lastBackup, now: now), isTrue);
    });
  });
}
