import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_widget.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/db_providers.dart';
import '../../../core/database/models/transaction_record.dart';
import '../../../core/utils/currency_utils.dart';

class TimelineActivityWidget extends ConsumerStatefulWidget {
  final DashboardWidgetSize size;
  const TimelineActivityWidget({super.key, this.size = DashboardWidgetSize.large});

  @override
  ConsumerState<TimelineActivityWidget> createState() => _TimelineActivityWidgetState();
}

class _TimelineActivityWidgetState extends ConsumerState<TimelineActivityWidget> {
  int _selectedTabIndex = 0; // 0: Gün, 1: Ay, 2: Yıl

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(allTransactionsProvider);
    final filteredTransactions = _filterTransactions(transactions);

    switch (widget.size) {
      case DashboardWidgetSize.small:
        return _buildSmallView(filteredTransactions);
      case DashboardWidgetSize.wide:
        return _buildWideView(filteredTransactions);
      case DashboardWidgetSize.large:
        return _buildLargeView(filteredTransactions);
    }
  }

  Widget _buildSmallView(List<TransactionRecord> txs) {
    if (txs.isEmpty) return _buildEmptyState();
    final latest = txs.first;
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(latest.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded, 
             color: latest.isIncome ? theme.colorScheme.primary : theme.colorScheme.error, size: 24),
        const SizedBox(height: 8),
        Text(
          CurrencyUtils.formatAmount(latest.amount),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        Text(
          'SON İŞLEM',
          style: theme.textTheme.labelLarge?.copyWith(fontSize: 8, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
        ),
      ],
    );
  }

  Widget _buildWideView(List<TransactionRecord> txs) {
    if (txs.isEmpty) return _buildEmptyState();
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SON İŞLEMLER', style: theme.textTheme.labelLarge?.copyWith(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
            Icon(Icons.history_rounded, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          ],
        ),
        const SizedBox(height: 12),
        ...txs.take(2).map((tx) => Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tx.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(CurrencyUtils.formatAmount(tx.amount), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: tx.isIncome ? theme.colorScheme.primary : theme.colorScheme.error)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildLargeView(List<TransactionRecord> filteredTransactions) {
    return Column(
      children: [
        // Periyot Tabları
        _buildPeriodTabs(),
        const SizedBox(height: 16),
        
        // İşlem Listesi
        Expanded(
          child: filteredTransactions.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: filteredTransactions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _buildTransactionItem(filteredTransactions[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildPeriodTabs() {
    final List<String> tabs = ['GÜN', 'AY', 'YIL'];
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionRecord tx) {
    final theme = Theme.of(context);
    final isIncome = tx.isIncome;
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Kategori İkonu
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isIncome ? theme.colorScheme.primary : theme.colorScheme.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 18,
              color: isIncome ? theme.colorScheme.primary : theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 12),
          
          // Başlık ve Tarih
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  DateFormat('dd MMM').format(tx.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Tutar
          Text(
            (isIncome ? '+' : '-') + CurrencyUtils.formatAmount(tx.amount),
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 14,
              color: isIncome ? theme.colorScheme.primary : theme.colorScheme.error,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 32,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 8),
          Text(
            'İşlem bulunamadı',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionRecord> _filterTransactions(List<TransactionRecord> all) {
    final now = DateTime.now();
    return all.where((tx) {
      if (_selectedTabIndex == 0) { // Gün
        return tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day;
      } else if (_selectedTabIndex == 1) { // Ay
        return tx.date.year == now.year && tx.date.month == now.month;
      } else { // Yıl
        return tx.date.year == now.year;
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // En yeni en üstte
  }
}
