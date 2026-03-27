import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/analysis_provider.dart';
import 'package:kanakkan/presentation/screens/analysis_transactions_screen.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DRILL TYPES
// ─────────────────────────────────────────────────────────────────────────────

enum DrillType {
  expenseBreakdown,
  incomeBreakdown,
  savingsTrend,
  monthlyTrend,
  dailySpend,
  yearTrend,
  yearExpenseBreakdown,
  yearIncomeBreakdown,
}

extension DrillTypeLabel on DrillType {
  String get title => switch (this) {
    DrillType.expenseBreakdown => 'Expense Breakdown',
    DrillType.incomeBreakdown => 'Income Sources',
    DrillType.savingsTrend => 'Savings Trend',
    DrillType.monthlyTrend => '6-Month Trend',
    DrillType.dailySpend => 'Daily Spending',
    DrillType.yearTrend => 'Year Overview',
    DrillType.yearExpenseBreakdown => 'Year Expense Breakdown',
    DrillType.yearIncomeBreakdown => 'Year Income Sources',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// DRILL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AnalysisDrillScreen extends StatelessWidget {
  final DrillType type;
  const AnalysisDrillScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalysisProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              p.periodLabel,
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildContent(context, p),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AnalysisProvider p) {
    return switch (type) {
      DrillType.expenseBreakdown => _BreakdownDrill(
        items: p.expenseBreakdown,
        color: AppTheme.error,
        label: 'Expenses',
      ),
      DrillType.incomeBreakdown => _BreakdownDrill(
        items: p.incomeBreakdown,
        color: AppTheme.success,
        label: 'Income',
      ),
      DrillType.savingsTrend => _SavingsDrill(provider: p),
      DrillType.monthlyTrend => _TrendDrill(
        trend: p.trend,
        title: '6-Month Income vs Expense',
      ),
      DrillType.dailySpend => _DailyDrill(provider: p),
      DrillType.yearTrend => _TrendDrill(
        trend: p.yearMonthlyBreakdown,
        title: 'Monthly Breakdown',
      ),
      DrillType.yearExpenseBreakdown => _BreakdownDrill(
        items: p.yearExpenseBreakdown,
        color: AppTheme.error,
        label: 'Year Expenses',
      ),
      DrillType.yearIncomeBreakdown => _BreakdownDrill(
        items: p.yearIncomeBreakdown,
        color: AppTheme.success,
        label: 'Year Income',
      ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BREAKDOWN DRILL — Pie + full list with subcategory expansion
// ─────────────────────────────────────────────────────────────────────────────

class _BreakdownDrill extends StatefulWidget {
  final List<CategoryBreakdown> items;
  final Color color;
  final String label;
  const _BreakdownDrill({
    required this.items,
    required this.color,
    required this.label,
  });

  @override
  State<_BreakdownDrill> createState() => _BreakdownDrillState();
}

class _BreakdownDrillState extends State<_BreakdownDrill> {
  int? _touchedIndex;
  final Set<int> _expandedIds = {};

  static const _palette = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF43C6AC),
    Color(0xFFFFBE76),
    Color(0xFF786FA6),
    Color(0xFFF8A5C2),
    Color(0xFF63CDDA),
    Color(0xFFEA8685),
    Color(0xFF596275),
    Color(0xFFFD9644),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'No data for this period.',
            style: TextStyle(color: Colors.black45),
          ),
        ),
      );
    }

    final total = widget.items.fold(0.0, (s, i) => s + i.amount);

    return Column(
      children: [
        // ── TOTAL CARD ──
        _totalCard(total),
        const SizedBox(height: 20),

        // ── PIE CHART ──
        _pieChart(),
        const SizedBox(height: 8),
        _legend(),

        const SizedBox(height: 24),

        // ── FULL LIST WITH SUBCATEGORY DRILL ──
        ...widget.items.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          final color = _palette[idx % _palette.length];
          final isExpanded = _expandedIds.contains(item.categoryId);

          return Column(
            children: [
              // Main category row
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnalysisTransactionsScreen(
                      categoryId: item.categoryId,
                      categoryName: item.name,
                    ),
                  ),
                ),
                child: _CategoryRow(
                  item: item,
                  color: color,
                  isExpanded: isExpanded,
                  hasChildren: item.subcategories.isNotEmpty,
                  onToggleExpand: () => setState(() {
                    if (isExpanded) {
                      _expandedIds.remove(item.categoryId);
                    } else {
                      _expandedIds.add(item.categoryId);
                    }
                  }),
                ),
              ),

              // Subcategory rows (animated)
              if (isExpanded)
                _SubcategoryList(
                  subcategories: item.subcategories,
                  parentColor: color,
                  parentTotal: item.amount,
                ),

              const Divider(height: 1, color: Colors.black12),
            ],
          );
        }),
      ],
    );
  }

  Widget _totalCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${formatAmt(total)}',
            style: TextStyle(
              color: widget.color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pieChart() {
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              if (response?.touchedSection != null) {
                setState(() {
                  _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                });
              } else {
                setState(() => _touchedIndex = null);
              }
            },
          ),
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: widget.items.asMap().entries.map((e) {
            final isTouched = _touchedIndex == e.key;
            final color = _palette[e.key % _palette.length];
            return PieChartSectionData(
              value: e.value.amount,
              color: color,
              radius: isTouched ? 80 : 65,
              title: e.value.percentage > 5
                  ? '${e.value.percentage.toStringAsFixed(0)}%'
                  : '',
              titleStyle: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: widget.items.asMap().entries.map((e) {
        final color = _palette[e.key % _palette.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              e.value.name,
              style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryBreakdown item;
  final Color color;
  final bool isExpanded;
  final bool hasChildren;
  final VoidCallback? onToggleExpand;
  const _CategoryRow({
    required this.item,
    required this.color,
    required this.isExpanded,
    required this.hasChildren,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              if (item.subcategories.isNotEmpty)
                Text(
                  '${item.subcategories.length} sub',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              const SizedBox(width: 8),
              Text(
                '₹${formatAmt(item.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 8),
              if (hasChildren)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 24,
                    color: Colors.black45,
                  ),
                  onPressed: onToggleExpand,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (item.percentage / 100).clamp(0.0, 1.0),
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${item.percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubcategoryList extends StatelessWidget {
  final List<CategoryBreakdown> subcategories;
  final Color parentColor;
  final double parentTotal;

  const _SubcategoryList({
    required this.subcategories,
    required this.parentColor,
    required this.parentTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 22, bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: parentColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: parentColor.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Column(
        children: subcategories.map((sub) {
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnalysisTransactionsScreen(
                  categoryId: sub.categoryId,
                  categoryName: sub.name,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.subdirectory_arrow_right,
                        size: 14,
                        color: parentColor.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(sub.name, style: TextStyle(fontSize: 13)),
                      ),
                      Text(
                        '₹${formatAmt(sub.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: parentColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${sub.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (sub.percentage / 100).clamp(0.0, 1.0),
                      backgroundColor: parentColor.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(
                        parentColor.withValues(alpha: 0.6),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAVINGS DRILL — line chart + summary cards
// ─────────────────────────────────────────────────────────────────────────────

class _SavingsDrill extends StatelessWidget {
  final AnalysisProvider provider;
  const _SavingsDrill({required this.provider});

  @override
  Widget build(BuildContext context) {
    final trend = provider.isMonthly
        ? provider.trend
        : provider.yearMonthlyBreakdown;

    final savingsData = trend
        .map((t) => FlSpot(trend.indexOf(t).toDouble(), t.savings))
        .toList();

    final maxAbs = savingsData.map((s) => s.y.abs()).fold(0.0, math.max);
    final maxY = maxAbs * 1.4;

    return Column(
      children: [
        // Summary
        _DrillSummaryRow(
          items: [
            _SummaryItem(
              'Income',
              provider.isMonthly
                  ? provider.totalIncome
                  : provider.yearTotalIncome,
              AppTheme.success,
            ),
            _SummaryItem(
              'Expense',
              provider.isMonthly
                  ? provider.totalExpense
                  : provider.yearTotalExpense,
              AppTheme.error,
            ),
            _SummaryItem(
              'Savings',
              provider.isMonthly ? provider.savings : provider.yearSavings,
              AppTheme.accent,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Savings rate gauge
        _SavingsGauge(
          rate: provider.isMonthly
              ? provider.savingsRate
              : provider.yearSavingsRate,
        ),

        const SizedBox(height: 24),

        // Savings line chart
        _ChartCard(
          title: 'Savings Over Time',
          child: SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: -maxY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: val == 0 ? Colors.black26 : Colors.black12,
                    strokeWidth: val == 0 ? 1.5 : 0.8,
                    dashArray: val == 0 ? null : [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
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
                      reservedSize: 22,
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
                              fontSize: 10,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: savingsData,
                    isCurved: true,
                    color: AppTheme.accent,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                        radius: 4,
                        color: spot.y >= 0 ? AppTheme.success : AppTheme.error,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.accent.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Month list
        _ChartCard(
          title: 'Monthly Detail',
          child: Column(
            children: trend.map((t) {
              final isSaving = t.savings >= 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        t.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${formatAmt(t.income)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.success,
                                ),
                              ),
                              Text(
                                '₹${formatAmt(t.expense)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: t.income > 0
                                  ? (t.expense / t.income).clamp(0.0, 1.0)
                                  : 0,
                              backgroundColor: AppTheme.success.withValues(
                                alpha: 0.2,
                              ),
                              valueColor: AlwaysStoppedAnimation(
                                AppTheme.error.withValues(alpha: 0.7),
                              ),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${isSaving ? '+' : ''}₹${formatAmt(t.savings)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSaving ? AppTheme.success : AppTheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TREND DRILL — grouped bar chart + table
// ─────────────────────────────────────────────────────────────────────────────

class _TrendDrill extends StatelessWidget {
  final List<MonthlyTrend> trend;
  final String title;
  const _TrendDrill({required this.trend, required this.title});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.black45)),
      );
    }

    final maxVal = trend
        .expand((t) => [t.income, t.expense])
        .fold(0.0, math.max);

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: AppTheme.success, label: 'Income'),
            const SizedBox(width: 16),
            _LegendDot(color: AppTheme.error, label: 'Expense'),
            const SizedBox(width: 16),
            _LegendDot(color: AppTheme.accent, label: 'Savings'),
          ],
        ),
        const SizedBox(height: 16),

        // Bar chart
        _ChartCard(
          title: title,
          child: SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.25,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, rodIdx) {
                      final t = trend[group.x];
                      final label = rodIdx == 0 ? 'Income' : 'Expense';
                      final val = rodIdx == 0 ? t.income : t.expense;
                      return BarTooltipItem(
                        '$label\n₹${formatAmt(val)}',
                        TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, meta) => Text(
                        formatAmt(v),
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
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
                      reservedSize: 22,
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
                              fontSize: 10,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 4,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Colors.black12, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(trend.length, (i) {
                  final t = trend[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: t.income,
                        color: AppTheme.success,
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: t.expense,
                        color: AppTheme.error,
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Summary table
        _ChartCard(
          title: 'Summary Table',
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                ),
                children: ['Month', 'Income', 'Expense', 'Savings']
                    .map(
                      (h) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Text(
                          h,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              ...trend.map((t) {
                final saving = t.savings;
                return TableRow(
                  children: [
                    _tableCell(t.label),
                    _tableCell(
                      '₹${formatAmt(t.income)}',
                      color: AppTheme.success,
                    ),
                    _tableCell(
                      '₹${formatAmt(t.expense)}',
                      color: AppTheme.error,
                    ),
                    _tableCell(
                      '${saving >= 0 ? '+' : ''}₹${formatAmt(saving)}',
                      color: saving >= 0 ? AppTheme.success : AppTheme.error,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableCell(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color ?? Colors.black87,
          fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAILY SPEND DRILL — full line chart + heatmap-style bars
// ─────────────────────────────────────────────────────────────────────────────

class _DailyDrill extends StatelessWidget {
  final AnalysisProvider provider;
  const _DailyDrill({required this.provider});

  @override
  Widget build(BuildContext context) {
    final daily = provider.dailySpend;
    if (daily.isEmpty) {
      return const Center(
        child: Text(
          'No expense data this month.',
          style: TextStyle(color: Colors.black45),
        ),
      );
    }

    final focusMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month + provider.monthOffset,
    );
    final daysInMonth = DateTime(focusMonth.year, focusMonth.month + 1, 0).day;
    final maxVal = daily.values.fold(0.0, math.max);
    final totalSpend = daily.values.fold(0.0, (s, v) => s + v);
    final avgDaily = totalSpend / daysInMonth;
    final peakDay = daily.entries.reduce((a, b) => a.value > b.value ? a : b);

    return Column(
      children: [
        // Summary
        _DrillSummaryRow(
          items: [
            _SummaryItem('Total', totalSpend, AppTheme.error),
            _SummaryItem('Daily Avg', avgDaily, Colors.orange),
            _SummaryItem(
              'Peak Day ${peakDay.key}',
              peakDay.value,
              AppTheme.primary,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Line chart
        _ChartCard(
          title: 'Spending by Day',
          child: SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: daysInMonth.toDouble(),
                minY: 0,
                maxY: maxVal * 1.3,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            'Day ${s.x.toInt()}\n₹${formatAmt(s.y)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 3,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Colors.black12, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, meta) => Text(
                        '₹${formatAmt(v)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
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
                      interval: 5,
                      reservedSize: 22,
                      getTitlesWidget: (v, meta) => Text(
                        '${v.toInt()}',
                        style: TextStyle(fontSize: 10, color: Colors.black45),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(daysInMonth, (i) {
                      final day = i + 1;
                      return FlSpot(day.toDouble(), daily[day] ?? 0);
                    }),
                    isCurved: true,
                    color: AppTheme.error,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, _, _) {
                        final isHigh = spot.y >= maxVal * 0.7;
                        return FlDotCirclePainter(
                          radius: isHigh ? 5 : 3,
                          color: isHigh
                              ? AppTheme.error
                              : AppTheme.error.withValues(alpha: 0.5),
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.error.withValues(alpha: 0.08),
                    ),
                  ),
                  // Average line
                  LineChartBarData(
                    spots: [
                      FlSpot(1, avgDaily),
                      FlSpot(daysInMonth.toDouble(), avgDaily),
                    ],
                    color: Colors.orange.withValues(alpha: 0.6),
                    barWidth: 1.5,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Spend list for days with data
        _ChartCard(
          title: 'Days with Spending',
          child: Column(
            children:
                (daily.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
                    .map((e) {
                      final pct = maxVal > 0 ? e.value / maxVal : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${e.key}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct.clamp(0.0, 1.0),
                                  backgroundColor: AppTheme.error.withValues(
                                    alpha: 0.1,
                                  ),
                                  valueColor: AlwaysStoppedAnimation(
                                    AppTheme.error.withValues(
                                      alpha: 0.7 + pct * 0.3,
                                    ),
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '₹${formatAmt(e.value)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED DRILL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DrillSummaryRow extends StatelessWidget {
  final List<_SummaryItem> items;
  const _DrillSummaryRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: item == items.last ? 0 : 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: item.color.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${formatAmt(item.value.abs())}',
                      style: TextStyle(
                        color: item.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SummaryItem {
  final String label;
  final double value;
  final Color color;
  const _SummaryItem(this.label, this.value, this.color);
}

class _SavingsGauge extends StatelessWidget {
  final double rate;
  const _SavingsGauge({required this.rate});

  @override
  Widget build(BuildContext context) {
    final color = rate >= 20
        ? AppTheme.success
        : rate >= 0
        ? Colors.orange
        : AppTheme.error;
    final label = rate >= 30
        ? 'Excellent'
        : rate >= 20
        ? 'Good'
        : rate >= 0
        ? 'Below Target'
        : 'Overspending';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Savings Rate',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (rate.abs() / 100).clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0%',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 18,
                ),
              ),
              Text(
                '100%',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Target: 20% or more',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// HELPER
// ─────────────────────────────────────────
