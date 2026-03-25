import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/data/services/backup_service.dart';
import 'package:kanakkan/data/database/database_helper.dart';
import 'package:kanakkan/presentation/providers/analysis_provider.dart';
import 'package:kanakkan/presentation/providers/budget_provider.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/providers/navigation_provider.dart';
import 'package:kanakkan/presentation/providers/salary_allocation_provider.dart';
import 'package:provider/provider.dart';

/// Stateless handler — call static methods from the drawer.
class BackupRestoreHandler {
  // ── BACKUP ──────────────────────────────────────────────────────────────────

  static Future<void> runBackup(BuildContext context) async {
    // Step 1 — Show options dialog
    final choice = await _showBackupOptionsDialog(context);
    if (choice == null || !context.mounted) return; // cancelled or dismissed

    // Capture navigator before async gap
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    _showLoading(context, 'Preparing backup…');

    try {
      final BackupResult result;
      if (choice == 'storage') {
        result = await BackupService.instance.backupToStorage();
      } else {
        result = await BackupService.instance.backup();
      }

      // Use navigator directly — context may be stale after file picker/share sheet
      navigator.pop(); // close loading

      if (result.isSuccess) {
        messenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Backup saved successfully.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (result.isCancelled) {
        // user dismissed share sheet or cancelled file picker — silent
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.message ?? 'Backup failed.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      navigator.pop(); // close loading on exception
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Backup error: $e',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── RESTORE ─────────────────────────────────────────────────────────────────

  static Future<void> runRestore(BuildContext context) async {
    // Capture navigator and messenger before any async gaps —
    // context becomes deactivated after dialogs close
    final navigator = Navigator.of(context);

    // Step 1 — show loading then pick file
    _showLoading(context, 'Opening file picker…');
    final pickResult = await BackupService.instance.pickAndRestore();
    navigator.pop(); // close loading — use captured navigator, not context

    if (pickResult.isCancelled) return;

    if (pickResult.isError) {
      if (!context.mounted) return;
      _showErrorDialog(context, pickResult.message!);
      return;
    }

    // Step 2 — reinitialize providers
    if (!context.mounted) return;
    _showLoading(context, 'Reloading data…');
    try {
      await _reinitializeProviders(context);
    } finally {
      navigator.pop(); // close loading
    }

    if (!context.mounted) return;
    _showSuccessDialog(context);
  }

  // ── RESET ──────────────────────────────────────────────────────────────────

  static Future<void> runReset(BuildContext context) async {
    final navigator = Navigator.of(context);

    _showLoading(context, 'Deleting all data…');
    try {
      await DatabaseHelper.instance.resetDatabase();
      if (!context.mounted) return;
      await _reinitializeProviders(context);
    } catch (e) {
      if (!context.mounted) return;
      _showErrorDialog(context, 'Reset failed: $e');
      return;
    } finally {
      navigator.pop(); // close loading
    }

    if (!context.mounted) return;
    context.read<NavigationProvider>().setIndex(0); // Go back to default tab
    _showResetSuccessDialog(context);
  }

  // ── CONFIRM RESTORE DIALOG ───────────────────────────────────────────────────

  /// Shows a confirmation dialog BEFORE picking the file.
  /// Returns true if user confirms.
  static Future<bool> confirmRestore(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: AppTheme.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.cloud_download_outlined,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Restore from Backup?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Column(
                      children: [
                        _InfoPoint(
                          icon: Icons.folder_open_outlined,
                          color: Colors.orange,
                          text:
                              'You will be asked to pick a Kanakkan backup file (.db).',
                        ),
                        SizedBox(height: 8),
                        _InfoPoint(
                          icon: Icons.warning_amber_rounded,
                          color: Colors.orange,
                          text:
                              'All current data will be replaced by the backup.',
                        ),
                        SizedBox(height: 8),
                        _InfoPoint(
                          icon: Icons.verified_outlined,
                          color: AppTheme.success,
                          text:
                              'The file will be validated before anything is overwritten.',
                        ),
                        SizedBox(height: 8),
                        _InfoPoint(
                          icon: Icons.backup_outlined,
                          color: AppTheme.accent,
                          text: 'Consider backing up current data first.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.black26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Pick File',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  // ── BACKUP OPTIONS DIALOG ───────────────────────────────────────────────────

  static Future<String?> _showBackupOptionsDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.backup_outlined,
                  color: AppTheme.accent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Backup Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'How would you like to save your backup?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              _BackupOptionTile(
                icon: Icons.save_alt_rounded,
                title: 'Save to Device Storage',
                subtitle: 'Choose a folder on your phone',
                onTap: () => Navigator.pop(context, 'storage'),
              ),
              const SizedBox(height: 12),
              _BackupOptionTile(
                icon: Icons.share_outlined,
                title: 'Share / Send File',
                subtitle: 'Send via WhatsApp, Drive, etc.',
                onTap: () => Navigator.pop(context, 'share'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── REINITIALIZE PROVIDERS ───────────────────────────────────────────────────

  static Future<void> _reinitializeProviders(BuildContext context) async {
    // Reload in dependency order — each provider re-reads from the
    // restored DB so all in-memory state reflects the backup.
    final categories = context.read<CategoryProvider>();
    final balances = context.read<CategoryBalanceProvider>();
    final ledger = context.read<LedgerProvider>();
    final analysis = context.read<AnalysisProvider>();
    final budget = context.read<BudgetProvider>();
    final salary = context.read<SalaryAllocationProvider>();

    // Categories first — ledger depends on them
    await categories.initialize();
    // Balances — ledger and budget depend on them
    await balances.loadBalances();
    // Ledger — analysis depends on it
    await ledger.initialize();
    // Analysis recomputes from the freshly loaded ledger
    analysis.updateDependencies(ledger, categories);

    // Budget and salary template — reload independently
    await budget.loadBudgets();
    await salary.loadTemplate();
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  static void _showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.error_outline,
                  color: AppTheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Restore Failed',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.success.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.success,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Restore Complete',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your data has been restored successfully. Everything is up to date.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Great!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showResetSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.success.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.delete_sweep,
                  color: AppTheme.success,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Data Reset Successfully',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'All your data has been permanently deleted. Start fresh!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKUP OPTION TILE
// ─────────────────────────────────────────────────────────────────────────────

class _BackupOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BackupOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED INFO POINT WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _InfoPoint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoPoint({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
