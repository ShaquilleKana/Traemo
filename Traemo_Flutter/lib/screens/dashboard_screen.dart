import 'dart:developer' as developer;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.isDark,
    this.isActive = false,
  });

  final bool isDark;
  final bool isActive;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  num totalBalance = 0;
  num totalIncome = 0;
  num totalExpense = 0;
  List<double> weeklyIncome = List<double>.filled(7, 0);
  List<double> weeklyExpense = List<double>.filled(7, 0);
  List<_ExpenseCategoryDistribution> expenseCategoryDistribution = [];
  bool _isLoading = false;

  static const List<String> _labels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  static const List<Color> _neonPieColors = [
    Color(0xFF10F29A),
    Color(0xFF38BDF8),
    Color(0xFFFACC15),
    Color(0xFFA855F7),
    Color(0xFF22D3EE),
    Color(0xFFF472B6),
  ];

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadDashboardData();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      loadDashboardData();
    }
  }

  Future<void> loadDashboardData() async {
    if (_isLoading) return;

    _isLoading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");
      final token = prefs.getString("auth_token") ?? '';

      if (userId == null || token.isEmpty) {
        return;
      }

      final data = await ApiService.getDashboardSummary(userId, token: token);

      if (!mounted) return;

      setState(() {
        totalBalance = _asNum(data["balance"]);
        totalIncome = _asNum(data["income"]);
        totalExpense = _asNum(data["expense"]);
        weeklyIncome = _asDoubleList(data["weekly_income"]);
        weeklyExpense = _asDoubleList(data["weekly_expense"]);
        expenseCategoryDistribution = _asExpenseCategoryDistribution(
            data["expense_category_distribution"]);
      });
    } catch (e) {
      developer.log("DASHBOARD ERROR: $e", name: 'DashboardScreen');
    } finally {
      _isLoading = false;
    }
  }

  num _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<double> _asDoubleList(dynamic value) {
    if (value is! List) return List<double>.filled(7, 0);

    final values = value.map((e) => _asNum(e).toDouble()).toList();
    if (values.length >= 7) return values.take(7).toList();

    return [
      ...values,
      ...List<double>.filled(7 - values.length, 0),
    ];
  }

  List<_ExpenseCategoryDistribution> _asExpenseCategoryDistribution(
    dynamic value,
  ) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map(
          (item) => _ExpenseCategoryDistribution(
            category: item['category']?.toString() ?? '-',
            total: _asNum(item['total']),
          ),
        )
        .where((item) => item.total > 0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final fg = isDark ? AppColors.darkForeground : AppColors.lightForeground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final onPrimary = isDark
        ? AppColors.darkPrimaryForeground
        : AppColors.lightPrimaryForeground;
    final income = isDark ? AppColors.darkIncome : AppColors.lightIncome;
    final expense = isDark ? AppColors.darkExpense : AppColors.lightExpense;
    final gridColor =
        isDark ? AppColors.chartGridDark : AppColors.chartGridLight;

    final rawMaxY = [
      ...weeklyIncome,
      ...weeklyExpense,
    ].reduce((a, b) => a > b ? a : b);
    final maxY = rawMaxY > 0 ? rawMaxY * 1.05 : 1.0;

    final incomeSpots = <FlSpot>[
      for (var i = 0; i < weeklyIncome.length; i++)
        FlSpot(i.toDouble(), weeklyIncome[i]),
    ];
    final expenseSpots = <FlSpot>[
      for (var i = 0; i < weeklyExpense.length; i++)
        FlSpot(i.toDouble(), weeklyExpense[i]),
    ];

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Financial overview this week',
              style: TextStyle(fontSize: 14, color: muted),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary,
                    primary.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 20, color: onPrimary.withValues(alpha: 0.8)),
                      const SizedBox(width: 8),
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrencyIdr(totalBalance),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.north_east,
                          size: 16, color: onPrimary.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(
                        '+12% from last week',
                        style: TextStyle(
                          fontSize: 14,
                          color: onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    border: border,
                    card: card,
                    iconBg: income.withValues(alpha: 0.1),
                    icon: Icons.trending_up,
                    iconColor: income,
                    label: 'Total Income',
                    value: formatCurrencyIdr(totalIncome),
                    valueColor: fg,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    border: border,
                    card: card,
                    iconBg: expense.withValues(alpha: 0.1),
                    icon: Icons.trending_down,
                    iconColor: expense,
                    label: 'Total Expense',
                    value: formatCurrencyIdr(totalExpense),
                    valueColor: fg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (_labels.length - 1).toDouble(),
                        minY: 0,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: gridColor,
                            strokeWidth: 1,
                            dashArray: [3, 3],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final i = value.round();
                                if (i < 0 || i >= _labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _labels[i],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value <= 0) return const SizedBox.shrink();
                                return Text(
                                  '${(value / 1000).round()}k',
                                  style: TextStyle(fontSize: 12, color: muted),
                                );
                              },
                            ),
                          ),
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((s) {
                                return LineTooltipItem(
                                  formatCurrencyIdr(s.y.toInt()),
                                  TextStyle(
                                    fontSize: 12,
                                    color: fg,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: incomeSpots,
                            isCurved: true,
                            color: income,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  income.withValues(alpha: 0.3),
                                  income.withValues(alpha: 0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          LineChartBarData(
                            spots: expenseSpots,
                            isCurved: true,
                            color: expense,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  expense.withValues(alpha: 0.3),
                                  expense.withValues(alpha: 0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendDot(color: income, label: 'Income', muted: muted),
                      const SizedBox(width: 24),
                      _LegendDot(
                          color: expense, label: 'Expense', muted: muted),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _ExpenseDistributionCard(
              border: border,
              card: card,
              foreground: fg,
              muted: muted,
              totalExpense: totalExpense,
              distribution: expenseCategoryDistribution,
              colors: _neonPieColors,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCategoryDistribution {
  const _ExpenseCategoryDistribution({
    required this.category,
    required this.total,
  });

  final String category;
  final num total;
}

class _ExpenseDistributionCard extends StatelessWidget {
  const _ExpenseDistributionCard({
    required this.border,
    required this.card,
    required this.foreground,
    required this.muted,
    required this.totalExpense,
    required this.distribution,
    required this.colors,
  });

  final Color border;
  final Color card;
  final Color foreground;
  final Color muted;
  final num totalExpense;
  final List<_ExpenseCategoryDistribution> distribution;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final hasData = distribution.isNotEmpty && totalExpense > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkPrimary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expense Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on expense categories',
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 20),
          if (hasData)
            LayoutBuilder(
              builder: (context, constraints) {
                final chartSize = constraints.maxWidth < 360 ? 220.0 : 260.0;
                final centerRadius = chartSize * 0.27;
                final sectionRadius = chartSize * 0.14;

                return Column(
                  children: [
                    Center(
                      child: SizedBox(
                        width: chartSize,
                        height: chartSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: chartSize * 0.78,
                              height: chartSize * 0.78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  for (final color in colors.take(4))
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.16),
                                      blurRadius: 28,
                                      spreadRadius: -8,
                                    ),
                                ],
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 650),
                              curve: Curves.easeOutCubic,
                              builder: (context, progress, child) {
                                return PieChart(
                                  PieChartData(
                                    startDegreeOffset: -90,
                                    sectionsSpace: 4,
                                    centerSpaceRadius: centerRadius,
                                    borderData: FlBorderData(show: false),
                                    sections: _buildSections(
                                      progress,
                                      sectionRadius,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Container(
                              width: centerRadius * 1.7,
                              height: centerRadius * 1.7,
                              decoration: BoxDecoration(
                                color: card,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: border.withValues(alpha: 0.8),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.darkPrimary
                                        .withValues(alpha: 0.14),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Total Expense',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: muted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatCurrencyIdr(totalExpense),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: foreground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 14,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < distribution.length; i++)
                          _ExpenseLegendItem(
                            color: colors[i % colors.length],
                            label: distribution[i].category,
                            percentage:
                                distribution[i].total / totalExpense * 100,
                            foreground: foreground,
                            muted: muted,
                          ),
                      ],
                    ),
                  ],
                );
              },
            )
          else
            _ExpenseEmptyState(muted: muted, foreground: foreground),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    double progress,
    double sectionRadius,
  ) {
    return [
      for (var i = 0; i < distribution.length; i++)
        PieChartSectionData(
          value: distribution[i].total.toDouble() * progress,
          showTitle: false,
          radius: sectionRadius,
          color: colors[i % colors.length],
          badgeWidget: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: colors[i % colors.length],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors[i % colors.length].withValues(alpha: 0.7),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          badgePositionPercentageOffset: 1.08,
          borderSide: BorderSide(
            color: colors[i % colors.length].withValues(alpha: 0.9),
            width: 1.2,
          ),
        ),
    ];
  }
}

class _ExpenseLegendItem extends StatelessWidget {
  const _ExpenseLegendItem({
    required this.color,
    required this.label,
    required this.percentage,
    required this.foreground,
    required this.muted,
  });

  final Color color;
  final String label;
  final double percentage;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 130, maxWidth: 240),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.7),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${percentage.round()}%',
            style: TextStyle(
              fontSize: 12,
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseEmptyState extends StatelessWidget {
  const _ExpenseEmptyState({
    required this.muted,
    required this.foreground,
  });

  final Color muted;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.darkPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.darkPrimary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.donut_large,
            color: AppColors.darkPrimary.withValues(alpha: 0.8),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada data pengeluaran',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kategori pengeluaran akan muncul setelah transaksi tercatat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.border,
    required this.card,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final Color border;
  final Color card;
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkMutedForeground
                  : AppColors.lightMutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.muted,
  });

  final Color color;
  final String label;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: muted)),
      ],
    );
  }
}
