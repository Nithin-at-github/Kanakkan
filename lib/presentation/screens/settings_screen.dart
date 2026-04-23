import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/dialogs/change_pin_sheet.dart';
import 'package:kanakkan/presentation/handlers/backup_restore_handler.dart';
import 'package:kanakkan/presentation/widgets/animations/staggered_entrance.dart';

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

          // ── DANGER ZONE ──
          _SectionHeader(title: "DANGER ZONE", isError: true),
          StaggeredEntrance(
            index: 1,
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
    showDialog(context: context, builder: (ctx) => _ConfirmResetDialog());
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

class _ConfirmResetDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.background,
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
                      await BackupRestoreHandler.runReset(context);
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
