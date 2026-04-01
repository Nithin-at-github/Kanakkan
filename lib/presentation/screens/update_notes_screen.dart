import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class UpdateNote {
  final String version;
  final String date;
  final List<String> changes;
  final bool isLatest;
  const UpdateNote({
    required this.version,
    required this.date,
    required this.changes,
    this.isLatest = false,
  });
}

class UpdateNotesScreen extends StatelessWidget {
  const UpdateNotesScreen({super.key});

  static const List<UpdateNote> _updates = [
    UpdateNote(
      version: '1.2.0',
      isLatest: true,
      date: 'March 2026',
      changes: [
        'Direct Backup & Export saving to device storage.',
        'New "Save Options" dialog for flexible file management.',
        'Type-free categories: Income/Expense/Transfer types are now unified.',
        'Account-linked categories: Categories can now be tied to specific accounts.',
        'Category Merge Tool: Consolidate multiple categories with full history migration.',
        'Safe Deletion: Move transactions to another category before deleting.',
        'Drill-down Analysis: Tap on any category to see a detailed transaction list.',
        'Excluded Categories: Hide specific categories from global analysis and totals.',
      ],
    ),
    UpdateNote(
      version: '1.1.0',
      date: 'February 2026',
      changes: [
        'Interactive Charting for better financial visualization.',
        'Budgeting System: Set monthly targets per category.',
        'Salary Allocation: Automatically split your income into multiple wallets.',
        'Enhanced PIN protection and Biometric authentication.',
        'Support for multiple currencies and decimal formatting.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppTheme.background,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              pinned: true,
              stretch: true,
              elevation: 0,
              centerTitle: false,
              backgroundColor: AppTheme.background,
              surfaceTintColor: Colors.transparent,
              leading: Center(
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.onSurface.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                titlePadding: const EdgeInsets.only(
                  bottom: 16,
                  left: 72,
                ), // Offset for leading icon
                title: Text(
                  'Update Notes',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight:
                        FontWeight.w500, // Medium weight instead of bold
                    fontSize: 18,
                  ),
                ),
                centerTitle: false,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: -10,
                      right: -10,
                      child: Icon(
                        Icons.auto_awesome_motion,
                        size: 140,
                        color: AppTheme.accent.withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final note = _updates[index];
                  return _UpdateCard(note: note);
                }, childCount: _updates.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final UpdateNote note;
  const _UpdateCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: note.isLatest
            ? Border.all(
                color: AppTheme.accent.withValues(alpha: 0.2),
                width: 1.5,
              )
            : Border.all(color: AppTheme.onSurface.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: note.isLatest
                        ? AppTheme.accent.withValues(alpha: 0.1)
                        : AppTheme.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Version ${note.version}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: note.isLatest
                          ? AppTheme.accent
                          : AppTheme.onSurface,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  note.date,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Changes
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: note.changes
                  .map(
                    (change) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: note.isLatest
                                  ? AppTheme.accent.withValues(alpha: 0.1)
                                  : AppTheme.onSurface.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 8,
                              color: note.isLatest
                                  ? AppTheme.accent
                                  : AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              change,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.onSurface,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          if (note.isLatest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Center(
                child: Text(
                  'STAY UPDATED!',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
