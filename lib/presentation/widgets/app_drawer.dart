import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The app-wide navigation drawer.
/// Attach via `drawer: const AppDrawer()` on RootScaffold's Scaffold.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          // Fills the status bar area with primary color so it
          // blends seamlessly with the drawer header.
          Container(
            color: AppTheme.primary,
            height: MediaQuery.of(context).padding.top,
          ),
          Expanded(
            child: SafeArea(
              top: false, // already handled above
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── HEADER ──
                  _DrawerHeader(),

                  const SizedBox(height: 8),

                  // ── MANAGEMENT SECTION ──
                  _SectionLabel(label: "Management"),

                  _DrawerTile(
                    icon: Icons.cloud_upload_outlined,
                    label: "Backup Data",
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: trigger backup
                    },
                  ),

                  _DrawerTile(
                    icon: Icons.cloud_download_outlined,
                    label: "Restore Data",
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: trigger restore
                    },
                  ),

                  _DrawerTile(
                    icon: Icons.file_download_outlined,
                    label: "Export Records",
                    subtitle: "Download as CSV or PDF",
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: open export options
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Divider(height: 1, color: Colors.black12),
                  ),

                  _DrawerTile(
                    icon: Icons.delete_forever_outlined,
                    label: "Delete & Reset",
                    subtitle: "Erase all data permanently",
                    iconColor: AppTheme.error,
                    labelColor: AppTheme.error,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmReset(context);
                    },
                  ),

                  const Spacer(),

                  // ── FOOTER ──
                  _DrawerFooter(),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
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
                backgroundColor: AppTheme.error.withOpacity(0.1),
                child: const Icon(
                  Icons.delete_forever,
                  color: AppTheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Delete & Reset?",
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
                  color: AppTheme.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withOpacity(0.2)),
                ),
                child: const Column(
                  children: [
                    _WarningPoint(
                      text: "All transactions will be permanently deleted.",
                    ),
                    SizedBox(height: 8),
                    _WarningPoint(
                      text:
                          "All accounts, categories and budgets will be removed.",
                    ),
                    SizedBox(height: 8),
                    _WarningPoint(
                      text:
                          "Wallet balances and salary allocations will be erased.",
                    ),
                    SizedBox(height: 8),
                    _WarningPoint(text: "This action cannot be undone."),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: execute reset
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Delete All",
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App icon / logo mark
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text(
                "₹",
                style: TextStyle(
                  fontSize: 24,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const Text(
            "I-W-¡-³-",
            style: TextStyle(
              fontFamily: 'Ravivarma',
              fontSize: 44,
              color: AppTheme.accent,
            ),
          ),
          
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (_, snap) {
              final version = snap.hasData
                  ? "v${snap.data!.version} (${snap.data!.buildNumber})"
                  : "—";
              return Text(
                version,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black38,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAWER TILE
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor ?? AppTheme.primary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          size: 18,
          color: (iconColor ?? Colors.black).withOpacity(0.3),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        "Made with ♥ in Kerala",
        style: TextStyle(fontSize: 11, color: Colors.black26),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WARNING POINT (used in reset dialog)
// ─────────────────────────────────────────────────────────────────────────────

class _WarningPoint extends StatelessWidget {
  final String text;
  const _WarningPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.error,
          size: 16,
        ),
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
