import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/dialogs/change_pin_sheet.dart';
import 'package:kanakkan/presentation/handlers/backup_restore_handler.dart';
import 'package:kanakkan/presentation/providers/backup_settings_provider.dart';
import 'package:kanakkan/presentation/widgets/animations/staggered_entrance.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // ── SECURITY SECTION ──
          _SectionHeader(title: "SECURITY"),
          StaggeredEntrance(
            index: 0,
            child: _SettingsTile(
              icon: Icons.pin_outlined,
              title: "Change PIN",
              subtitle: "Update your login PIN",
              onTap: () => _changePin(context),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(indent: 20, endIndent: 20, thickness: 0.5),

          // ── BACKUP SECTION ──
          _SectionHeader(title: "BACKUP"),
          const StaggeredEntrance(index: 1, child: _DriveBackupSection()),

          const SizedBox(height: 12),
          const Divider(indent: 20, endIndent: 20, thickness: 0.5),

          // ── DANGER ZONE ──
          _SectionHeader(title: "DANGER ZONE", isError: true),
          StaggeredEntrance(
            index: 2,
            child: _SettingsTile(
              icon: Icons.delete_forever_outlined,
              title: "Delete & Reset",
              subtitle: "Erase everything permanently. This is irreversible.",
              color: AppTheme.error,
              onTap: () => _reset(context),
            ),
          ),
        ],
      ),
    );
  }

  // ============= ACTIONS =============

  Future<void> _changePin(BuildContext context) async {
    await ChangePinSheet.show(context);
  }

  void _reset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ConfirmResetDialog(parentContext: context),
    );
  }
}

// ── UI COMPONENTS ──

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isError;
  const _SectionHeader({required this.title, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isError ? AppTheme.error : AppTheme.onSurfaceVariant,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppTheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: themeColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: themeColor.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = AppTheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: themeColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppTheme.accent,
            ),
          ],
        ),
      ),
    );
  }
}

/// Toggle + status + manual actions for Google Drive auto-backup. Reads
/// [BackupSettingsProvider] so it updates live as a backup runs.
class _DriveBackupSection extends StatelessWidget {
  const _DriveBackupSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<BackupSettingsProvider>(
      builder: (context, backup, _) {
        return Column(
          children: [
            _SettingsSwitchTile(
              icon: Icons.cloud_upload_outlined,
              title: "Auto-backup to Google Drive",
              subtitle: _statusText(backup),
              value: backup.autoBackupEnabled,
              onChanged: (value) => _toggle(context, backup, value),
            ),
            if (backup.autoBackupEnabled) ...[
              _SettingsTile(
                icon: Icons.cloud_sync_outlined,
                title: backup.isBackingUp ? "Backing up…" : "Back up now",
                subtitle: "Upload the latest data to Drive immediately",
                onTap: backup.isBackingUp ? () {} : () => backup.backupNow(),
              ),
              _SettingsTile(
                icon: Icons.link_off,
                title: "Disconnect Google Account",
                subtitle: "Turn off auto-backup and sign out",
                onTap: () => _toggle(context, backup, false),
              ),
            ],
          ],
        );
      },
    );
  }

  String _statusText(BackupSettingsProvider backup) {
    if (backup.isBackingUp) return "Backing up…";
    if (backup.lastBackupError != null) {
      return "Backup failed: ${backup.lastBackupError}";
    }
    final last = backup.lastBackupAt;
    if (last == null) return "Not backed up yet";
    return "Last backup: ${_relativeTime(last)}";
  }

  Future<void> _toggle(
    BuildContext context,
    BackupSettingsProvider backup,
    bool value,
  ) async {
    try {
      await backup.setAutoBackupEnabled(value);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}

class _ConfirmResetDialog extends StatelessWidget {
  // Reset itself is a long-running flow (DB wipe, provider reinit, another
  // dialog shown after). Using this dialog's own `context` for that would be
  // unsafe once "Delete All" pops this dialog — its context is deactivated
  // right after. Pass the stable outer (Settings screen) context through
  // instead, same pattern as _ExportSheet.parentContext in export_handler.dart.
  final BuildContext parentContext;
  const _ConfirmResetDialog({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final autoBackupOn = context.watch<BackupSettingsProvider>().autoBackupEnabled;

    return Dialog(
      backgroundColor: AppTheme.dialogSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.error.withValues(alpha: 0.1),
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Permanently Delete All Data?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "This will erase all transactions, accounts, and settings. This cannot be undone.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            if (autoBackupOn) ...[
              const SizedBox(height: 12),
              Text(
                "Google Drive auto-backup will also be turned off, so your last "
                "backup there doesn't get silently overwritten with empty data. "
                "You can turn it back on anytime in Settings.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Keep Data"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await BackupRestoreHandler.runReset(parentContext);
                    },
                    child: const Text("Delete All"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
