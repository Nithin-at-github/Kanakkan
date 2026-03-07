import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/analysis_provider.dart';
import 'package:provider/provider.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP BAR ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Text(
                    'Analysis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _MonthNavigator(provider: provider),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── ACCOUNT FILTER CHIPS ──
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.accounts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final acc = provider.accounts[i];
                  final selected = provider.selectedAccountIds.contains(acc.id);
                  return GestureDetector(
                    onTap: () => provider.toggleAccount(acc.id!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.accent : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppTheme.accent : Colors.white24,
                        ),
                      ),
                      child: Text(
                        acc.name,
                        style: TextStyle(
                          color: selected ? AppTheme.primary : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── SCROLLABLE CONTENT ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HealthCard(provider: provider),
                    const SizedBox(height: 16),

                    _SectionTitle('💰 How Well Did You Save?'),
                    const SizedBox(height: 10),
                    _SavingsMeter(provider: provider),
                    const SizedBox(height: 20),

                    _SectionTitle('📈 Income vs Spending (6 Months)'),
                    const SizedBox(height: 10),
                    _TrendChart(trend: provider.trend),
                    const SizedBox(height: 20),

                    if (provider.topCategories.isNotEmpty) ...[
                      _SectionTitle('🧾 Where Did Money Go?'),
                      const SizedBox(height: 10),
                      _SpendingBreakdown(
                        categories: provider.topCategories,
                        total: provider.totalExpense,
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (provider.dailySpend.isNotEmpty) ...[
                      _SectionTitle('📅 Daily Spending This Month'),
                      const SizedBox(height: 10),
                      _DailySpendChart(
                        dailySpend: provider.dailySpend,
                        focusMonth: DateTime(
                          DateTime.now().year,
                          DateTime.now().month + provider.monthOffset,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _SectionTitle('💡 Smart Insights'),
                    const SizedBox(height: 10),
                    _InsightsList(insights: provider.insights),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// MONTH NAVIGATOR
// ─────────────────────────────────────────

class _MonthNavigator extends StatelessWidget {
  final AnalysisProvider provider;
  const _MonthNavigator({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: AppTheme.accent,
              size: 20,
            ),
            onPressed: provider.previousMonth,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          Text(
            provider.monthLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: provider.canGoForward ? AppTheme.accent : Colors.white24,
              size: 20,
            ),
            onPressed: provider.canGoForward ? provider.nextMonth : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ─────────────────────────────────────────
// HEALTH CARD
// ─────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  final AnalysisProvider provider;
  const _HealthCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final income = provider.totalIncome;
    final expense = provider.totalExpense;
    final savings = provider.savings;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accent.withOpacity(0.25), Colors.white10],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatPill(
                label: 'Income',
                value: income,
                color: AppTheme.success,
              ),
              const SizedBox(width: 10),
              _StatPill(label: 'Spent', value: expense, color: AppTheme.error),
              const SizedBox(width: 10),
              _StatPill(
                label: 'Saved',
                value: savings,
                color: savings >= 0 ? AppTheme.accent : AppTheme.error,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Income vs expense ratio bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final total = income + expense;
                  final incomeWidth = total > 0
                      ? (income / total) * constraints.maxWidth
                      : constraints.maxWidth / 2;
                  return Row(
                    children: [
                      Container(width: incomeWidth, color: AppTheme.success),
                      Expanded(child: Container(color: AppTheme.error)),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendDot(color: AppTheme.success, label: 'Income'),
              _LegendDot(color: AppTheme.error, label: 'Spent'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${_fmt(value)}',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// SAVINGS METER
// ─────────────────────────────────────────

class _SavingsMeter extends StatelessWidget {
  final AnalysisProvider provider;
  const _SavingsMeter({required this.provider});

  String get _emoji {
    final r = provider.savingsRate;
    if (r >= 30) return '🌟';
    if (r >= 20) return '👍';
    if (r >= 10) return '😐';
    if (r >= 0) return '⚠️';
    return '🚨';
  }

  String get _message {
    final r = provider.savingsRate;
    if (r >= 30)
      return 'Excellent! You saved ${r.toStringAsFixed(0)}% of income';
    if (r >= 20)
      return 'Good job! You saved ${r.toStringAsFixed(0)}% of income';
    if (r >= 10) return 'You saved ${r.toStringAsFixed(0)}%. Try to reach 20%';
    if (r >= 0)
      return 'Low savings. Only ${r.toStringAsFixed(0)}% saved this month';
    return 'You spent more than you earned this month';
  }

  Color get _color {
    final r = provider.savingsRate;
    if (r >= 20) return AppTheme.success;
    if (r >= 10) return AppTheme.accent;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final clampedRate = provider.savingsRate.clamp(0.0, 100.0) / 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              FractionallySizedBox(
                widthFactor: clampedRate,
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0%',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              Text(
                'Target: 20%',
                style: TextStyle(
                  color: _color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '100%',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 6-MONTH TREND CHART
// ─────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final List<MonthlyTrend> trend;
  const _TrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final maxVal = trend.fold(
      0.0,
      (m, d) => math.max(m, math.max(d.income, d.expense)),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.map((d) {
                final incH = maxVal > 0 ? (d.income / maxVal) * 110 : 0.0;
                final expH = maxVal > 0 ? (d.expense / maxVal) * 110 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _Bar(height: incH, color: AppTheme.success),
                            const SizedBox(width: 2),
                            _Bar(height: expH, color: AppTheme.error),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d.label,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppTheme.success, label: 'Income'),
              const SizedBox(width: 16),
              _LegendDot(color: AppTheme.error, label: 'Spending'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      width: 10,
      height: height.clamp(2.0, 110.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SPENDING BREAKDOWN
// ─────────────────────────────────────────

const _kCategoryColors = [
  Color(0xFFFF6B6B),
  Color(0xFFFFD93D),
  Color(0xFF6BCB77),
  Color(0xFF4D96FF),
  Color(0xFFFF922B),
];

class _SpendingBreakdown extends StatelessWidget {
  final List<CategoryBreakdown> categories;
  final double total;
  const _SpendingBreakdown({required this.categories, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Donut
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _DonutPainter(
                values: categories.map((c) => c.amount).toList(),
                colors: _kCategoryColors,
                total: total,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    Text(
                      '₹${_fmt(total)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Category rows
          ...categories.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final color = _kCategoryColors[i % _kCategoryColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹${_fmt(cat.amount)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${cat.percentage.toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (cat.percentage / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double total;
  const _DonutPainter({
    required this.values,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    double startAngle = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.04,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ─────────────────────────────────────────
// DAILY SPEND CHART
// ─────────────────────────────────────────

class _DailySpendChart extends StatelessWidget {
  final Map<int, double> dailySpend;
  final DateTime focusMonth;
  const _DailySpendChart({required this.dailySpend, required this.focusMonth});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        focusMonth.year == now.year && focusMonth.month == now.month;
    final daysInMonth = DateUtils.getDaysInMonth(
      focusMonth.year,
      focusMonth.month,
    );
    final maxDay = isCurrentMonth ? now.day : daysInMonth;
    final maxVal = dailySpend.values.fold(0.0, math.max);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(maxDay, (i) {
            final day = i + 1;
            final val = dailySpend[day] ?? 0;
            final h = maxVal > 0 ? (val / maxVal) * 80 : 0.0;
            final isToday = isCurrentMonth && day == now.day;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (val > 0)
                    Text(
                      _fmtShort(val),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 7,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Container(
                    width: 14,
                    height: h.clamp(3.0, 80.0),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppTheme.accent
                          : AppTheme.error.withOpacity(0.7),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$day',
                    style: TextStyle(
                      color: isToday ? AppTheme.accent : Colors.white38,
                      fontSize: 9,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// INSIGHTS LIST
// ─────────────────────────────────────────

class _InsightsList extends StatelessWidget {
  final List<AnalysisInsight> insights;
  const _InsightsList({required this.insights});

  Color _levelColor(InsightLevel level) {
    switch (level) {
      case InsightLevel.good:
        return AppTheme.success;
      case InsightLevel.warning:
        return AppTheme.accent;
      case InsightLevel.danger:
        return AppTheme.error;
      case InsightLevel.neutral:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: insights.map((insight) {
        final color = _levelColor(insight.level);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      insight.body,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────

String _fmt(double v) {
  if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}

String _fmtShort(double v) {
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}
