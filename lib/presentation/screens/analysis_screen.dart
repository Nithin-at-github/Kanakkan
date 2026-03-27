import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/analysis_provider.dart';
import 'package:kanakkan/presentation/providers/navigation_provider.dart';
import 'package:kanakkan/presentation/screens/analysis_drill_screen.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late NavigationProvider _nav;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nav = context.read<NavigationProvider>();
      _nav.addListener(_onTabChanged);
    });
  }

  @override
  void dispose() {
    _nav.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    // Tab index 1 = Analysis. Reset to today when user navigates here.
    if (_nav.currentIndex == 1 && _nav.previousIndex != 1) {
      context.read<AnalysisProvider>().resetToToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalysisProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _AnalysisHeader(provider: p),
          Expanded(
            child: p.isMonthly
                ? _MonthlyBody(provider: p)
                : _YearlyBody(provider: p),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER — period nav + mode toggle + account filter
// ─────────────────────────────────────────────────────────────────────────────

class _AnalysisHeader extends StatelessWidget {
  final AnalysisProvider provider;
  const _AnalysisHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── MODE TOGGLE ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeTab(
                  label: 'Monthly',
                  selected: provider.isMonthly,
                  onTap: () => provider.setMode(AnalysisMode.monthly),
                ),
                _ModeTab(
                  label: 'Yearly',
                  selected: !provider.isMonthly,
                  onTap: () => provider.setMode(AnalysisMode.yearly),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── PERIOD NAVIGATION ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: Colors.white),
                onPressed: provider.previous,
              ),
              Text(
                provider.periodLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: provider.canGoForward ? Colors.white : Colors.white30,
                ),
                onPressed: provider.canGoForward ? provider.next : null,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── ACCOUNT CHIPS ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: provider.accounts.map((a) {
                final selected = provider.selectedAccountIds.contains(a.id);
                return GestureDetector(
                  onTap: () => provider.toggleAccount(a.id!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.accent : Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      a.name,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MONTHLY BODY
// ─────────────────────────────────────────────────────────────────────────────

class _MonthlyBody extends StatelessWidget {
  final AnalysisProvider provider;
  const _MonthlyBody({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Summary cards row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Income',
                value: provider.totalIncome,
                color: AppTheme.success,
                icon: Icons.arrow_downward,
                onTap: () => _openDrill(context, DrillType.incomeBreakdown),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Expense',
                value: provider.totalExpense,
                color: AppTheme.error,
                icon: Icons.arrow_upward,
                onTap: () => _openDrill(context, DrillType.expenseBreakdown),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Savings',
                value: provider.savings,
                color: provider.savings >= 0 ? AppTheme.accent : AppTheme.error,
                icon: Icons.savings,
                onTap: () => _openDrill(context, DrillType.savingsTrend),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SavingsRateCard(
                rate: provider.savingsRate,
                onTap: () => _openDrill(context, DrillType.savingsTrend),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 6-month trend bar chart
        _SectionCard(
          title: '6-Month Trend',
          onTap: () => _openDrill(context, DrillType.monthlyTrend),
          child: SizedBox(
            height: 160,
            child: _TrendBarChart(trend: provider.trend),
          ),
        ),

        const SizedBox(height: 16),

        // Expense breakdown
        if (provider.expenseBreakdown.isNotEmpty)
          _SectionCard(
            title: 'Expense Breakdown',
            onTap: () => _openDrill(context, DrillType.expenseBreakdown),
            child: _BreakdownPreview(
              items: provider.expenseBreakdown,
              color: AppTheme.error,
            ),
          ),

        const SizedBox(height: 16),

        // Income breakdown
        if (provider.incomeBreakdown.isNotEmpty)
          _SectionCard(
            title: 'Income Sources',
            onTap: () => _openDrill(context, DrillType.incomeBreakdown),
            child: _BreakdownPreview(
              items: provider.incomeBreakdown,
              color: AppTheme.success,
            ),
          ),

        const SizedBox(height: 16),

        // Daily spend
        if (provider.dailySpend.isNotEmpty)
          _SectionCard(
            title: 'Daily Spending',
            onTap: () => _openDrill(context, DrillType.dailySpend),
            child: SizedBox(
              height: 120,
              child: _DailySpendChart(
                dailySpend: provider.dailySpend,
                month: DateTime(
                  DateTime.now().year,
                  DateTime.now().month + provider.monthOffset,
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Insights
        if (provider.insights.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Insights',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.primary,
              ),
            ),
          ),
          ...provider.insights.map((i) => _InsightCard(insight: i)),
        ],
      ],
    );
  }

  void _openDrill(BuildContext context, DrillType type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnalysisDrillScreen(type: type)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YEARLY BODY
// ─────────────────────────────────────────────────────────────────────────────

class _YearlyBody extends StatelessWidget {
  final AnalysisProvider provider;
  const _YearlyBody({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Year Income',
                value: provider.yearTotalIncome,
                color: AppTheme.success,
                icon: Icons.arrow_downward,
                onTap: () => _openDrill(context, DrillType.yearIncomeBreakdown),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Year Expense',
                value: provider.yearTotalExpense,
                color: AppTheme.error,
                icon: Icons.arrow_upward,
                onTap: () =>
                    _openDrill(context, DrillType.yearExpenseBreakdown),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Year Savings',
                value: provider.yearSavings,
                color: provider.yearSavings >= 0
                    ? AppTheme.accent
                    : AppTheme.error,
                icon: Icons.savings,
                onTap: () => _openDrill(context, DrillType.yearTrend),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SavingsRateCard(
                rate: provider.yearSavingsRate,
                onTap: () => _openDrill(context, DrillType.yearTrend),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _SmallStatCard(
                label: 'Avg/Month Income',
                value: provider.avgMonthlyIncome,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallStatCard(
                label: 'Avg/Month Expense',
                value: provider.avgMonthlyExpense,
                color: AppTheme.error,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (provider.bestSavingsMonth.isFinite &&
            provider.bestSavingsMonthLabel.isNotEmpty)
          _BestMonthCard(
            label: provider.bestSavingsMonthLabel,
            savings: provider.bestSavingsMonth,
          ),

        const SizedBox(height: 16),

        // 12-month bar chart
        _SectionCard(
          title: '${provider.periodLabel} — Month by Month',
          onTap: () => _openDrill(context, DrillType.yearTrend),
          child: SizedBox(
            height: 180,
            child: _TrendBarChart(
              trend: provider.yearMonthlyBreakdown,
              compact: true,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Year expense breakdown
        if (provider.yearExpenseBreakdown.isNotEmpty)
          _SectionCard(
            title: 'Expense Breakdown',
            onTap: () => _openDrill(context, DrillType.yearExpenseBreakdown),
            child: _BreakdownPreview(
              items: provider.yearExpenseBreakdown,
              color: AppTheme.error,
            ),
          ),

        const SizedBox(height: 16),

        // Year income breakdown
        if (provider.yearIncomeBreakdown.isNotEmpty)
          _SectionCard(
            title: 'Income Sources',
            onTap: () => _openDrill(context, DrillType.yearIncomeBreakdown),
            child: _BreakdownPreview(
              items: provider.yearIncomeBreakdown,
              color: AppTheme.success,
            ),
          ),
      ],
    );
  }

  void _openDrill(BuildContext context, DrillType type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnalysisDrillScreen(type: type)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black26,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${formatAmt(value.abs())}',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsRateCard extends StatelessWidget {
  final double rate;
  final VoidCallback onTap;
  const _SavingsRateCard({required this.rate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = rate >= 20
        ? AppTheme.success
        : rate >= 0
        ? AppTheme.accent
        : AppTheme.error;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.percent, color: color, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Savings Rate',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black26,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (rate.abs() / 100).clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _SmallStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${formatAmt(value)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _BestMonthCard extends StatelessWidget {
  final String label;
  final double savings;
  const _BestMonthCard({required this.label, required this.savings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.success.withValues(alpha: 0.15),
            AppTheme.accent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Best Savings Month',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(
                '$label — ₹${formatAmt(savings)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onTap;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Details',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                    Icon(Icons.chevron_right, color: Colors.black26, size: 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _BreakdownPreview extends StatelessWidget {
  final List<CategoryBreakdown> items;
  final Color color;
  const _BreakdownPreview({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    final preview = items.take(4).toList();
    return Column(
      children: preview.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '₹${formatAmt(item.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${item.percentage.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (item.percentage / 100).clamp(0.0, 1.0),
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final AnalysisInsight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.level) {
      InsightLevel.good => AppTheme.success,
      InsightLevel.warning => Colors.orange,
      InsightLevel.danger => AppTheme.error,
      InsightLevel.neutral => Colors.blueGrey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.body,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHARTS (preview size — full charts in drill screen)
// ─────────────────────────────────────────────────────────────────────────────

class _TrendBarChart extends StatelessWidget {
  final List<MonthlyTrend> trend;
  final bool compact;
  const _TrendBarChart({required this.trend, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.black38)),
      );
    }

    final maxVal = trend
        .expand((t) => [t.income, t.expense])
        .fold(0.0, math.max);

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= trend.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    trend[idx].label,
                    style: TextStyle(
                      fontSize: compact ? 9 : 10,
                      color: Colors.black54,
                    ),
                  ),
                );
              },
              reservedSize: 20,
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(trend.length, (i) {
          final t = trend[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: t.income,
                color: AppTheme.success.withValues(alpha: 0.8),
                width: compact ? 6 : 8,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: t.expense,
                color: AppTheme.error.withValues(alpha: 0.8),
                width: compact ? 6 : 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DailySpendChart extends StatelessWidget {
  final Map<int, double> dailySpend;
  final DateTime month;
  const _DailySpendChart({required this.dailySpend, required this.month});

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final maxVal = dailySpend.values.fold(0.0, math.max);

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: daysInMonth.toDouble(),
        minY: 0,
        maxY: maxVal * 1.3,
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (v, meta) => Text(
                '${v.toInt()}',
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
              reservedSize: 18,
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal > 0 ? maxVal / 3 : 1000,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Colors.black12, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(daysInMonth, (i) {
              final day = i + 1;
              return FlSpot(day.toDouble(), dailySpend[day] ?? 0);
            }),
            isCurved: true,
            color: AppTheme.error,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.error.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
