import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/data/services/export_service.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PRESET DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────────

enum _DatePreset {
  allTime,
  thisWeek,
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
  custom,
}

extension _DatePresetLabel on _DatePreset {
  String get label {
    switch (this) {
      case _DatePreset.allTime:
        return 'All Time';
      case _DatePreset.thisWeek:
        return 'This Week';
      case _DatePreset.thisMonth:
        return 'This Month';
      case _DatePreset.lastMonth:
        return 'Last Month';
      case _DatePreset.last3Months:
        return 'Last 3 Months';
      case _DatePreset.thisYear:
        return 'This Year';
      case _DatePreset.custom:
        return 'Custom…';
    }
  }

  DateTimeRange? toRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (this) {
      case _DatePreset.allTime:
        return null;
      case _DatePreset.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(weekStart.year, weekStart.month, weekStart.day),
          end: today,
        );
      case _DatePreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: today,
        );
      case _DatePreset.lastMonth:
        final firstOfThisMonth = DateTime(now.year, now.month, 1);
        final lastOfLastMonth = firstOfThisMonth.subtract(
          const Duration(days: 1),
        );
        return DateTimeRange(
          start: DateTime(lastOfLastMonth.year, lastOfLastMonth.month, 1),
          end: DateTime(
            lastOfLastMonth.year,
            lastOfLastMonth.month,
            lastOfLastMonth.day,
            23,
            59,
            59,
          ),
        );
      case _DatePreset.last3Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: today,
        );
      case _DatePreset.thisYear:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: today);
      case _DatePreset.custom:
        return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HANDLER
// ─────────────────────────────────────────────────────────────────────────────

class ExportHandler {
  static void showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ExportSheet(parentContext: context),
    );
  }

  static Future<void> runExport(
    BuildContext context,
    String format,
    DateTimeRange? range,
  ) async {
    // Step 1 — Show choice dialog
    final choice = await _showSaveChoiceDialog(context);
    if (choice == null || !context.mounted) return; // cancelled or dismissed

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

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
                  'Generating document…',
                  style: TextStyle(fontSize: 14, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      if (!context.mounted) return;
      final ledger = context.read<LedgerProvider>();
      final categories = context.read<CategoryProvider>();

      var txs = ledger.transactions;

      if (range != null) {
        final startMs = range.start.millisecondsSinceEpoch;
        final endMs = range.end.millisecondsSinceEpoch;
        txs = txs
            .where((tx) => tx.timestamp >= startMs && tx.timestamp <= endMs)
            .toList();
      }

      // Sort oldest → newest
      txs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (txs.isEmpty) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'No transactions found in selected date range.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final bool saveToStorage = choice == 'storage';

      if (format == 'csv') {
        await ExportService.instance.exportToCsv(
          transactions: txs,
          ledger: ledger,
          categories: categories,
          saveToStorage: saveToStorage,
        );
      } else {
        await ExportService.instance.exportToPdf(
          transactions: txs,
          ledger: ledger,
          categories: categories,
          saveToStorage: saveToStorage,
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Export failed: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      navigator.pop();
    }
  }

  // ── SAVE CHOICE DIALOG ───────────────────────────────────────────────────────

  static Future<String?> _showSaveChoiceDialog(BuildContext context) async {
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
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.save_outlined,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Save Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'How would you like to save your export?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              _ChoiceTile(
                icon: Icons.save_alt_rounded,
                title: 'Save to Device Storage',
                subtitle: 'Choose a folder on your phone',
                onTap: () => Navigator.pop(context, 'storage'),
              ),
              const SizedBox(height: 12),
              _ChoiceTile(
                icon: Icons.share_outlined,
                title: 'Share / Send File',
                subtitle: 'Send via WhatsApp, Drive, etc.',
                onTap: () => Navigator.pop(context, 'share'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.black54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _ExportSheet extends StatefulWidget {
  final BuildContext parentContext;
  const _ExportSheet({required this.parentContext});

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  _DatePreset _selected = _DatePreset.allTime;
  DateTimeRange? _customRange;

  DateTimeRange? get _effectiveRange {
    if (_selected == _DatePreset.allTime) return null;
    if (_selected == _DatePreset.custom) return _customRange;
    return _selected.toRange();
  }

  String get _rangeSummary {
    final r = _effectiveRange;
    if (r == null) return 'All transactions will be included.';
    return '${_fmt(r.start)}  →  ${_fmt(r.end)}';
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year}';

  String _monthName(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];

  Future<void> _onPresetTap(_DatePreset preset) async {
    if (preset == _DatePreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        initialDateRange: _customRange,
        builder: (context, child) => Theme(
          data: ThemeData(
            useMaterial3: false,
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: AppTheme.accent,
              onSurface: Colors.black,
              surface: AppTheme.background,
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppTheme.background),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        setState(() {
          _customRange = picked;
          _selected = _DatePreset.custom;
        });
      }
    } else {
      setState(() => _selected = preset);
    }
  }

  void _export(String format) {
    Navigator.pop(context);
    ExportHandler.runExport(widget.parentContext, format, _effectiveRange);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  Icon(
                    Icons.file_download_outlined,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Export Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // ── Date Range Presets ──
              Text(
                'DATE RANGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _DatePreset.values.map((preset) {
                  final isActive = _selected == preset;
                  return ChoiceChip(
                    label: Text(preset.label),
                    selected: isActive,
                    onSelected: (_) => _onPresetTap(preset),
                    selectedColor: AppTheme.primary,
                    backgroundColor: Colors.black.withValues(alpha: 0.04),
                    labelStyle: TextStyle(
                      color: isActive ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isActive ? AppTheme.primary : Colors.black12,
                      ),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),

              // ── Range Summary ──
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _rangeSummary,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'FORMAT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // ── Format Buttons ──
              Row(
                children: [
                  Expanded(
                    child: _FormatButton(
                      icon: Icons.table_chart_outlined,
                      label: 'CSV',
                      subtitle: 'Spreadsheets',
                      color: const Color(0xFF2E7D32),
                      onTap: () => _export('csv'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormatButton(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'PDF',
                      subtitle: 'Print & Share',
                      color: const Color(0xFFC62828),
                      onTap: () => _export('pdf'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHOICE TILE
// ─────────────────────────────────────────────────────────────────────────────

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceTile({
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.black45),
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
// FORMAT BUTTON CARD
// ─────────────────────────────────────────────────────────────────────────────

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FormatButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.black45),
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
