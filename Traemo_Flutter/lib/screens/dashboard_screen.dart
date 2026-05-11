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
  bool _isLoading = false;

  static const List<String> _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

      if (userId == null) {
        return;
      }

      final data = await ApiService.getDashboardSummary(userId);

      if (!mounted) return;

      setState(() {
        totalBalance = _asNum(data["balance"]);
        totalIncome = _asNum(data["income"]);
        totalExpense = _asNum(data["expense"]);
        weeklyIncome = _asDoubleList(data["weekly_income"]);
        weeklyExpense = _asDoubleList(data["weekly_expense"]);
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final fg = isDark ? AppColors.darkForeground : AppColors.lightForeground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final onPrimary =
        isDark ? AppColors.darkPrimaryForeground : AppColors.lightPrimaryForeground;
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
                      Icon(Icons.north_east, size: 16, color: onPrimary.withValues(alpha: 0.8)),
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
                            getTooltipColor: (_) =>
                                isDark ? AppColors.darkCard : AppColors.lightCard,
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
                      _LegendDot(color: expense, label: 'Expense', muted: muted),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
