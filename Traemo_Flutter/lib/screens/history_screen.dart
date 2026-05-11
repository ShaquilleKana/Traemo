import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class HistoryTransaction {
  const HistoryTransaction({
    required this.id,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    required this.icon,
  });

  final String id;
  final String category;
  final int amount;
  final String type;
  final DateTime date;
  final String icon;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.isDark,
    this.isActive = false,
  });

  final bool isDark;
  final bool isActive;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryTransaction> transactionList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadTransactions();
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      loadTransactions();
    }
  }

  Future<void> loadTransactions() async {
    if (_isLoading) return;

    _isLoading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");

      if (userId == null) {
        return;
      }

      final transactions = await ApiService.getTransactions(userId);

      if (!mounted) return;

      setState(() {
        transactionList = transactions
            .whereType<Map<String, dynamic>>()
            .map(_fromJson)
            .toList();
      });
    } catch (e) {
      developer.log("LOAD TRANSACTION ERROR: $e", name: 'HistoryScreen');
    } finally {
      _isLoading = false;
    }
  }

  HistoryTransaction _fromJson(Map<String, dynamic> transaction) {
    final rawDate = transaction['created_at'] ?? transaction['tanggal'];
    final parsedDate = DateTime.tryParse(rawDate?.toString() ?? '');

    return HistoryTransaction(
      id: transaction['id'].toString(),
      category: transaction['kategori']?.toString() ?? '-',
      amount: int.tryParse(transaction['jumlah'].toString()) ?? 0,
      type: transaction['tipe']?.toString() ?? 'expense',
      date: parsedDate ?? DateTime.now(),
      icon: _iconNameForCategory(transaction['kategori']?.toString() ?? ''),
    );
  }

  String _iconNameForCategory(String category) {
    final normalized = category.toLowerCase();

    if (normalized.contains('makan')) return 'food';
    if (normalized.contains('coffee') || normalized.contains('kopi')) {
      return 'coffee';
    }
    if (normalized.contains('bensin') || normalized.contains('transport')) {
      return 'car';
    }
    if (normalized.contains('belanja')) return 'shopping';
    if (normalized.contains('gaji') || normalized.contains('salary')) {
      return 'wallet';
    }

    return 'wallet';
  }

  Map<String, List<HistoryTransaction>> _grouped() {
    final map = <String, List<HistoryTransaction>>{};
    for (final t in transactionList) {
      final key = formatHistoryDate(t.date, todayAnchor: DateTime.now());
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'coffee':
        return Icons.local_cafe_outlined;
      case 'car':
        return Icons.directions_car_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final fg = isDark ? AppColors.darkForeground : AppColors.lightForeground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final income = isDark ? AppColors.darkIncome : AppColors.lightIncome;
    final expense = isDark ? AppColors.darkExpense : AppColors.lightExpense;

    final groups = _grouped();
    final keys = groups.keys.toList();

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          Text(
            'History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All your transactions',
            style: TextStyle(fontSize: 14, color: muted),
          ),
          const SizedBox(height: 24),
          for (final dateKey in keys) ...[
            Text(
              dateKey,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
            const SizedBox(height: 12),
            for (final t in groups[dateKey]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: t.type == 'income'
                                    ? income.withValues(alpha: 0.1)
                                    : expense.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _iconFor(t.icon),
                                size: 20,
                                color: t.type == 'income' ? income : expense,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.category,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: fg,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatTimeId(t.date),
                                    style: TextStyle(fontSize: 12, color: muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${t.type == 'income' ? '+' : '-'} ${formatCurrencyIdr(t.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: t.type == 'income' ? income : expense,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            t.type == 'income'
                                ? Icons.north_east
                                : Icons.south_east,
                            size: 16,
                            color: t.type == 'income' ? income : expense,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
