import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/dialogs/change_pin_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kanakkan/presentation/handlers/backup_restore_handler.dart';
import 'package:kanakkan/presentation/handlers/export_handler.dart';
import 'package:kanakkan/presentation/screens/root/root_scaffold.dart';
import 'package:kanakkan/presentation/providers/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'package:kanakkan/presentation/screens/update_notes_screen.dart';

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
                  _SectionLabel(label: "MANAGEMENT"),

                  _DrawerTile(
                    icon: Icons.cloud_upload_outlined,
                    label: "Backup Data",
                    subtitle: "Save a copy to your device",
                    onTap: () async {
                      Navigator.pop(context);
                      // Drawer context is now deactivated — use the stable
                      // scaffold context so Provider lookups + dialogs work.
                      final ctx = rootScaffoldKey.currentContext;
                      if (ctx == null || !ctx.mounted) return;
                      await BackupRestoreHandler.runBackup(ctx);
                    },
                  ),

                  _DrawerTile(
                    icon: Icons.cloud_download_outlined,
                    label: "Restore Data",
                    subtitle: "Load from a backup file",
                    onTap: () async {
                      Navigator.pop(context);
                      await Future.delayed(const Duration(milliseconds: 300));
                      final ctx = rootScaffoldKey.currentContext;
                      if (ctx == null || !ctx.mounted) return;
                      final confirmed =
                          await BackupRestoreHandler.confirmRestore(ctx);
                      if (!confirmed || !ctx.mounted) return;
                      await BackupRestoreHandler.runRestore(ctx);
                    },
                  ),

                  _DrawerTile(
                    icon: Icons.file_download_outlined,
                    label: "Export Records",
                    subtitle: "Download as CSV or PDF",
                    onTap: () {
                      Navigator.pop(context);
                      final ctx = rootScaffoldKey.currentContext;
                      if (ctx == null) return;
                      ExportHandler.showExportOptions(ctx);
                    },
                  ),

                  _DrawerTile(
                    icon: Icons.new_releases_outlined,
                    label: "Update Notes",
                    subtitle: "See what's new in Kanakkan",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UpdateNotesScreen(),
                        ),
                      );
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Divider(height: 1, color: Colors.black12),
                  ),

                  // ── SECURITY SECTION ──
                  _SectionLabel(label: "SECURITY"),

                  _DrawerTile(
                    icon: Icons.pin_outlined,
                    label: "Change PIN",
                    subtitle: "Update your login PIN",
                    onTap: () async {
                      Navigator.pop(context);
                      // Wait for drawer close animation before showing sheet
                      await Future.delayed(const Duration(milliseconds: 300));
                      final ctx = rootScaffoldKey.currentContext;
                      if (ctx == null || !ctx.mounted) return;
                      await ChangePinSheet.show(ctx);
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
                      final ctx = rootScaffoldKey.currentContext;
                      if (ctx != null) _confirmReset(ctx);
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
    // Capture navigator before the async dialog — the builder's `_` context
    // is deactivated once the dialog closes, causing the stale context error.
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
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
                  Icons.delete_forever,
                  color: AppTheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Delete & Reset?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
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
                      onPressed: () => navigator.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        navigator.pop();
                        await Future.delayed(const Duration(milliseconds: 300));
                        final ctx = rootScaffoldKey.currentContext;
                        if (ctx == null || !ctx.mounted) return;
                        await BackupRestoreHandler.runReset(ctx);
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

class _DrawerHeader extends StatefulWidget {
  @override
  State<_DrawerHeader> createState() => _DrawerHeaderState();
}

class _DrawerHeaderState extends State<_DrawerHeader> {
  // Cached once — PackageInfo.fromPlatform() is a platform-channel call
  // that never changes at runtime. Storing it here means it runs once per
  // drawer lifecycle instead of on every build.
  late final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App icon / logo mark
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
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
              const Spacer(),
              _ThemeSwitch(
                isDark: isDark,
                onChanged: (bool value) async {
                  final themeProvider = context.read<ThemeProvider>();
                  final overlayContext =
                      rootScaffoldKey.currentContext ?? context;

                  Navigator.pop(context); // Close drawer smoothly

                  // Wait for the drawer close animation to fully complete
                  await Future.delayed(const Duration(milliseconds: 250));

                  if (!overlayContext.mounted) return;

                  // Show a fully opaque 'Lights Out' fade transition using the brand's primary color
                  showGeneralDialog(
                    context: overlayContext,
                    barrierDismissible: false,
                    barrierColor: AppTheme.primary, // Deep purple fade
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        Center(
                          // Show an animated glowing sun/moon during the darkness
                          child: _ThemeTransitionLoader(toDark: !isDark),
                        ),
                    transitionBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                  );

                  // Wait for the fade-in to completely darken the screen
                  await Future.delayed(const Duration(milliseconds: 350));

                  // Trigger the massive global rebuild underneath the solid overlay
                  themeProvider.toggleTheme();

                  // Give the framework time to re-evaluate and rasterize the new tree (the jank happens here)
                  await Future.delayed(const Duration(milliseconds: 250));

                  // Fade the overlay back out, revealing the beautifully rendered new theme
                  if (overlayContext.mounted) {
                    Navigator.of(overlayContext, rootNavigator: true).pop();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            "I-W-¡-³-",
            style: TextStyle(
              fontFamily: 'Ravivarma',
              fontSize: 44,
              color: AppTheme.accent,
            ),
          ),

          FutureBuilder<PackageInfo>(
            future: _packageInfoFuture,
            builder: (_, snap) {
              final version = snap.hasData
                  ? "v${snap.data!.version} (${snap.data!.buildNumber})"
                  : "—";
              return Text(
                version,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
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
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.onSurfaceVariant,
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
    final color = iconColor ?? AppTheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor ?? AppTheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          size: 18,
          color: (iconColor ?? AppTheme.onSurface).withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerFooter extends StatelessWidget {
  static const _linkedInUrl = 'https://www.linkedin.com/in/nithinjk28/';

  Future<void> _openLinkedIn() async {
    final uri = Uri.parse(_linkedInUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Made with ♥ in Keralam",
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white24
                  : Colors.black26,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _openLinkedIn,
            child: Text(
              "by Nithin JK",
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
                decorationColor: AppTheme.accent,
              ),
            ),
          ),
        ],
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
        Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: AppTheme.onSurface),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM THEME SWITCH
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeSwitch extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ThemeSwitch({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isDark),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: 60,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? Colors.black38 : Colors.white24,
          border: Border.all(
            color: isDark
                ? AppTheme.accent.withValues(alpha: 0.3)
                : Colors.white38,
          ),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              left: isDark
                  ? 28
                  : 0, // 60 width - 8 padding - 24 thumb width = 28 track length
              right: isDark ? 0 : 28,
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppTheme.accent : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      key: ValueKey(isDark),
                      size: 14,
                      color: isDark ? AppTheme.primary : AppTheme.accent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM THEME TRANSITION LOADER
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeTransitionLoader extends StatelessWidget {
  final bool toDark;

  const _ThemeTransitionLoader({required this.toDark});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (value * 0.5), // Scale from 0.5 to 1.0
          child: Transform.rotate(
            angle: value * 2 * 3.14159, // One full rotation
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          boxShadow: [
            BoxShadow(
              color: (toDark ? AppTheme.accent : Colors.orange).withValues(
                alpha: 0.2,
              ),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Icon(
          toDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          size: 64,
          color: toDark ? AppTheme.accent : Colors.orange,
        ),
      ),
    );
  }
}
