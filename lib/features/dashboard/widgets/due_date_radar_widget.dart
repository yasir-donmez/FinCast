import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_widget.dart';
import '../../../core/providers/db_providers.dart';
import '../../../core/database/models/transaction_record.dart';
import '../../../core/utils/currency_utils.dart';

class DueDateRadarWidget extends ConsumerStatefulWidget {
  final DashboardWidgetSize size;
  const DueDateRadarWidget({super.key, this.size = DashboardWidgetSize.large});

  @override
  ConsumerState<DueDateRadarWidget> createState() => _DueDateRadarWidgetState();
}

class _DueDateRadarWidgetState extends ConsumerState<DueDateRadarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(allTransactionsProvider);
    final upcomingItems = _getUpcomingItems(transactions);

    switch (widget.size) {
      case DashboardWidgetSize.small:
        return _buildSmallView(upcomingItems.length);
      case DashboardWidgetSize.wide:
        return _buildWideView(upcomingItems);
      case DashboardWidgetSize.large:
        return _buildLargeView(upcomingItems);
    }
  }

  Widget _buildSmallView(int count) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.radar_rounded, color: count > 0 ? Colors.orange : Colors.blue, size: 24),
        const SizedBox(height: 8),
        Text(
          count > 0 ? '$count ÖDEME' : 'TEMİZ',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
        Text(
          'RADAR',
          style: theme.textTheme.labelLarge?.copyWith(fontSize: 8, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
        ),
      ],
    );
  }

  Widget _buildWideView(List<TransactionRecord> items) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.radar_rounded, color: items.isNotEmpty ? Colors.orange : Colors.blue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                items.isNotEmpty ? '${items.length} Yaklaşan Ödeme' : 'Radar Temiz',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              if (items.isNotEmpty)
                Text(
                  'En yakın: ${items.first.title}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLargeView(List<TransactionRecord> upcomingItems) {
    return Column(
      children: [
        // Radar Durum Özeti
        _buildRadarHeader(upcomingItems.length),
        const SizedBox(height: 16),
        
        // Yaklaşanlar Listesi
        Expanded(
          child: upcomingItems.isEmpty
              ? _buildCleanRadarState()
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: upcomingItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _buildUpcomingItem(upcomingItems[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildRadarHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (count > 0 ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.radar_rounded,
                size: 14,
                color: count > 0 ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                count > 0 ? 'TARAMA: $count BULGU' : 'RADAR TEMİZ',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: count > 0 ? Colors.orange : Colors.blue,
                ),
              ),
            ],
          ),
        ),
        if (count > 0)
          Text(
            'YAKLAŞANLAR',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
      ],
    );
  }

  Widget _buildUpcomingItem(TransactionRecord tx) {
    final theme = Theme.of(context);
    final daysLeft = tx.date.difference(DateTime.now()).inDays + 1;
    final isToday = daysLeft <= 0;
    
    Widget content = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday 
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Gün Sayacı
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isToday 
                    ? [theme.colorScheme.primary, theme.colorScheme.secondary]
                    : [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surfaceContainer],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isToday ? '!' : daysLeft.toString(),
                  style: TextStyle(
                    color: isToday ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!isToday)
                  Text(
                    'GÜN',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Detaylar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  maxLines: 1,
                  style: theme.textTheme.labelLarge?.copyWith(fontSize: 13, letterSpacing: 0),
                ),
                Text(
                  tx.isIncome ? 'Beklenen Gelir' : 'Gider Ödemesi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          
          // Tutar
          Text(
            CurrencyUtils.formatAmount(tx.amount),
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

    if (isToday) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: content,
      );
    }
    
    return content;
  }

  Widget _buildCleanRadarState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 32, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Text(
            'Yakın zamanda ödeme yok',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }

  List<TransactionRecord> _getUpcomingItems(List<TransactionRecord> transactions) {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));

    return transactions.where((tx) => 
      tx.date.isAfter(now.subtract(const Duration(hours: 24))) && 
      tx.date.isBefore(sevenDaysLater)
    ).toList()..sort((a, b) => a.date.compareTo(b.date));
  }
}
