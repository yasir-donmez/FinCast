import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_widget.dart';
import '../../../core/providers/db_providers.dart';
import '../../../core/database/models/transaction_record.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/precision_mini_segmented_control.dart';

class SpendingGiantsWidget extends ConsumerStatefulWidget {
  final DashboardWidgetSize size;
  const SpendingGiantsWidget({
    super.key,
    this.size = DashboardWidgetSize.large,
  });

  @override
  ConsumerState<SpendingGiantsWidget> createState() =>
      _SpendingGiantsWidgetState();
}

class _SpendingGiantsWidgetState extends ConsumerState<SpendingGiantsWidget> {
  int _selectedFilterIndex = 0; // 0: Hafta, 1: Ay, 2: Yıl

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(expenseTransactionsProvider);
    final filteredTransactions = _filterTransactions(transactions);
    final categoryGiants = _getCategoryGiants(filteredTransactions);
    final transactionGiants = _getTransactionGiants(filteredTransactions);

    switch (widget.size) {
      case DashboardWidgetSize.small:
        return _buildSmallView(categoryGiants);
      case DashboardWidgetSize.wide:
        return _buildWideView(categoryGiants, transactionGiants);
      case DashboardWidgetSize.large:
        return _buildLargeView(categoryGiants, transactionGiants);
    }
  }

  Widget _buildSmallView(List<_CategoryGiant> giants) {
    final theme = Theme.of(context);
    if (giants.isEmpty) return _buildEmptyState();
    final top = giants.first;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.pie_chart_rounded,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          '%${top.percentage.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        Text(
          top.categoryId?.toUpperCase() ?? 'DİĞER',
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 8,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildWideView(
    List<_CategoryGiant> cGiants,
    List<TransactionRecord> tGiants,
  ) {
    final theme = Theme.of(context);
    if (cGiants.isEmpty) return _buildEmptyState();
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LİDER KATEGORİ',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 8,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              Text(
                cGiants.first.categoryId ?? 'Diğer',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '%${cGiants.first.percentage.toStringAsFixed(1)} pay',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 30,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EN BÜYÜK HARCAMA',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 8,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              Text(
                tGiants.isNotEmpty ? tGiants.first.title : '-',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                tGiants.isNotEmpty
                    ? CurrencyUtils.formatAmount(tGiants.first.amount)
                    : '-',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLargeView(
    List<_CategoryGiant> categoryGiants,
    List<TransactionRecord> transactionGiants,
  ) {
    return Column(
      children: [
        // Filtreleme (H/A/Y)
        _buildFilterTabs(),
        const SizedBox(height: 16),

        // Kategori ve İşlem Listesi
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: categoryGiants.isEmpty
                ? _buildEmptyState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('LİDER KATEGORİLER'),
                      const SizedBox(height: 8),
                      ...categoryGiants.map((g) => _buildGiantCategoryItem(g)),
                      const SizedBox(height: 16),
                      _buildSectionTitle('EN BÜYÜK İŞLEMLER'),
                      const SizedBox(height: 8),
                      ...transactionGiants.map(
                        (tx) => _buildGiantTransactionItem(tx),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.auto_graph_rounded,
            size: 32,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 8),
          Text(
            'Veri henüz işlenmedi',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return PrecisionMiniSegmentedControl(
      items: const ['HAFTA', 'AY', 'YIL'],
      selectedIndex: _selectedFilterIndex,
      onChanged: (index) {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
    );
  }

  Widget _buildGiantCategoryItem(_CategoryGiant giant) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.category_rounded,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      giant.categoryId ?? 'Diğer',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      '%${giant.percentage.toStringAsFixed(1)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: giant.percentage / 100,
                    backgroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.05,
                    ),
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiantTransactionItem(TransactionRecord tx) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              tx.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            CurrencyUtils.formatAmount(tx.amount),
            style: theme.textTheme.labelLarge?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<TransactionRecord> _filterTransactions(
    List<TransactionRecord> transactions,
  ) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedFilterIndex) {
      case 0:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 1:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 2:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now;
    }

    return transactions.where((tx) => tx.date.isAfter(startDate)).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<_CategoryGiant> _getCategoryGiants(
    List<TransactionRecord> transactions,
  ) {
    if (transactions.isEmpty) return [];

    final Map<String, double> categorySums = {};
    double total = 0;

    for (final tx in transactions) {
      final catId = tx.categoryId ?? 'Diğer';
      categorySums[catId] = (categorySums[catId] ?? 0) + tx.amount;
      total += tx.amount;
    }

    final sortedEntries = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .take(3)
        .map(
          (e) => _CategoryGiant(
            categoryId: e.key,
            amount: e.value,
            percentage: total > 0 ? (e.value / total) * 100 : 0,
          ),
        )
        .toList();
  }

  List<TransactionRecord> _getTransactionGiants(
    List<TransactionRecord> transactions,
  ) {
    return transactions.take(3).toList();
  }
}

class _CategoryGiant {
  final String? categoryId;
  final double amount;
  final double percentage;

  _CategoryGiant({
    this.categoryId,
    required this.amount,
    required this.percentage,
  });
}
