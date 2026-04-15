import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kanakkan/presentation/handlers/backup_restore_handler.dart';
import 'package:kanakkan/presentation/handlers/export_handler.dart';
import 'package:kanakkan/presentation/screens/root/root_scaffold.dart';
import 'package:kanakkan/presentation/providers/theme_provider.dart';
import 'package:kanakkan/presentation/widgets/animations/pressable_scale.dart';
import 'package:kanakkan/presentation/widgets/animations/staggered_entrance.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'package:kanakkan/presentation/screens/settings_screen.dart';
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

                  StaggeredEntrance(
                    index: 0,
                    type: EntranceType.slideRight,
                    child: _DrawerTile(
                      icon: Icons.cloud_upload_outlined,
                      label: "Backup Data",
                      subtitle: "Save a copy to your device",
                      onTap: () async {
                        Navigator.pop(context);
                        final ctx = rootScaffoldKey.currentContext;
                        if (ctx == null || !ctx.mounted) return;
                        await BackupRestoreHandler.runBackup(ctx);
                      },
                    ),
                  ),

                  StaggeredEntrance(
                    index: 1,
                    type: EntranceType.slideRight,
                    child: _DrawerTile(
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
                  ),

                  StaggeredEntrance(
                    index: 2,
                    type: EntranceType.slideRight,
                    child: _DrawerTile(
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
                  ),

                  StaggeredEntrance(
                    index: 3,
                    type: EntranceType.slideRight,
                    child: _DrawerTile(
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
                  ),

                  StaggeredEntrance(
                    index: 4,
                    type: EntranceType.slideRight,
                    child: _DrawerTile(
                      icon: Icons.settings_outlined,
                      label: "Settings",
                      subtitle: "Security, maintenance & reset",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(),

                  // ── FOOTER ──
                  StaggeredEntrance(index: 5, type: EntranceType.slideRight, child: _DrawerFooter()),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
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
                  final overlayContext = rootScaffoldKey.currentContext ?? context;
                  final currentIsDark = themeProvider.themeMode == ThemeMode.dark;
                  
                  // The background color we are transitioning TO
                  final targetBgColor = currentIsDark 
                      ? const Color(0xFFF5F5DC) // Light background
                      : const Color(0xFF121212); // Dark background

                  Navigator.pop(context); // Close drawer

                  // Wait slightly for drawer to begin closing so the fade feels natural
                  await Future.delayed(const Duration(milliseconds: 150));

                  if (!overlayContext.mounted) return;

                  // 1. Fade the entire screen into the *target* background color
                  showGeneralDialog(
                    context: overlayContext,
                    barrierDismissible: false,
                    barrierColor: targetBgColor,
                    transitionDuration: const Duration(milliseconds: 200),
                    pageBuilder: (context, _, _) => const SizedBox.shrink(),
                    transitionBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  );

                  // 2. Wait for the fade-in to complete
                  await Future.delayed(const Duration(milliseconds: 200));

                  // 3. Perform the heavy operation (rebuilding the entire app tree)
                  themeProvider.toggleTheme();

                  // 4. Give the framework 1-2 frames to rasterize the new tree in the background
                  await Future.delayed(const Duration(milliseconds: 50));

                  // 5. Fade out the overlay. Because the overlay matches the new background, 
                  // it will look like the widgets are smoothly fading into existence.
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

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: PressableScale(
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              color: AppTheme.onSurface,
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
            color: AppTheme.onSurface.withValues(alpha: 0.3),
          ),
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


