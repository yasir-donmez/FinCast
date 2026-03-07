import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_constants.dart';
import '../dashboard_providers.dart';
import '../../../shared/widgets/neu_container.dart';

class ExpandableVaultGrid extends StatefulWidget {
  final List<DashboardItem> items;

  const ExpandableVaultGrid({super.key, required this.items});

  @override
  State<ExpandableVaultGrid> createState() => _ExpandableVaultGridState();
}

class _ExpandableVaultGridState extends State<ExpandableVaultGrid> {
  final Set<int> _selectedIndices =
      {}; // Sayfa başı veya satır başı bağımsız detay durumu
  late PageController _pageController;
  int _currentPage = 0;

  bool _isExpanded(int index, int totalInPage, int startIndex) {
    if (totalInPage == 1) return true;
    if (totalInPage == 2) return true;
    if (totalInPage == 3) {
      if (index == startIndex) return true;
      return _selectedIndices.contains(index);
    }
    return _selectedIndices.contains(index);
  }

  bool _isShrunk(int index, int totalInPage, int startIndex) {
    if (totalInPage <= 2) return false;
    if (totalInPage == 3) {
      if (index == startIndex) return false;
      int otherIdx = (index == startIndex + 1)
          ? startIndex + 2
          : startIndex + 1;
      return _selectedIndices.contains(otherIdx);
    }
    if (totalInPage == 4) {
      int localIdx = index - startIndex;
      int otherIdx = (localIdx % 2 == 0) ? index + 1 : index - 1;
      return _selectedIndices.contains(otherIdx);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double parentWidth = constraints.maxWidth;
        final count = widget.items.length;

        if (count == 0) return const SizedBox.shrink();

        if (count == 1) {
          return _buildLayoutFor1(widget.items, parentWidth, 0);
        } else if (count == 2) {
          return _buildLayoutFor2(widget.items, parentWidth, 0);
        } else if (count == 3) {
          return _buildLayoutFor3(widget.items, parentWidth, 0);
        } else if (count == 4) {
          return _buildLayoutFor4(widget.items, parentWidth, 0);
        } else {
          // 5 ve üzeri: Sayfalı (Paginated) Düzen + Dots
          return _buildPaginatedLayout(parentWidth);
        }
      },
    );
  }

  // CASE 1: Tek Kasa
  Widget _buildLayoutFor1(
    List<DashboardItem> items,
    double width,
    int startIndex,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: _buildVaultCardWrapper(
        item: items[0],
        index: startIndex,
        width: width - (AppSizes.paddingMedium * 2),
        height: 236,
        isExpanded: true,
        isShrunk: false,
      ),
    );
  }

  // CASE 2: İki Kasa - İkisi de Açık
  Widget _buildLayoutFor2(
    List<DashboardItem> items,
    double width,
    int startIndex,
  ) {
    if (items.length < 2) return _buildLayoutFor1(items, width, startIndex);
    final double cardWidth = width - (AppSizes.paddingMedium * 2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildVaultCardWrapper(
            item: items[0],
            index: startIndex,
            width: cardWidth,
            height: 114,
            isExpanded: true,
            isShrunk: false,
          ),
          const SizedBox(height: 8),
          _buildVaultCardWrapper(
            item: items[1],
            index: startIndex + 1,
            width: cardWidth,
            height: 114,
            isExpanded: true,
            isShrunk: false,
          ),
        ],
      ),
    );
  }

  // CASE 3: Üç Kasa - Biri Büyük, İkisi Küçük (Yalnızca Dikey Büyüme)
  Widget _buildLayoutFor3(
    List<DashboardItem> items,
    double width,
    int startIndex,
  ) {
    if (items.length < 3) return _buildLayoutFor2(items, width, startIndex);
    final availableWidth = width - (AppSizes.paddingMedium * 3);
    final halfWidth = availableWidth * 0.5;

    final rightH1 = _isExpanded(startIndex + 1, 3, startIndex)
        ? 160.0
        : (_isShrunk(startIndex + 1, 3, startIndex) ? 60.0 : 114.0);
    final rightH2 = _isExpanded(startIndex + 2, 3, startIndex)
        ? 160.0
        : (_isShrunk(startIndex + 2, 3, startIndex) ? 60.0 : 114.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildVaultCardWrapper(
            item: items[0],
            index: startIndex,
            width: halfWidth,
            height: 236,
            isExpanded: true,
            isShrunk: false,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildVaultCardWrapper(
                item: items[1],
                index: startIndex + 1,
                width: halfWidth,
                height: rightH1,
                isExpanded: _isExpanded(startIndex + 1, 3, startIndex),
                isShrunk: _isShrunk(startIndex + 1, 3, startIndex),
              ),
              const SizedBox(height: 8),
              _buildVaultCardWrapper(
                item: items[2],
                index: startIndex + 2,
                width: halfWidth,
                height: rightH2,
                isExpanded: _isExpanded(startIndex + 2, 3, startIndex),
                isShrunk: _isShrunk(startIndex + 2, 3, startIndex),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CASE 4: Dört Kasa - Satır İçi Bağımsız Genişleme
  Widget _buildLayoutFor4(
    List<DashboardItem> items,
    double width,
    int startIndex,
  ) {
    if (items.length < 4) return _buildLayoutFor3(items, width, startIndex);
    final availableWidth = width - (AppSizes.paddingMedium * 3);

    double getW(int idx) {
      if (_isExpanded(idx, 4, startIndex)) return availableWidth * 0.75;
      if (_isShrunk(idx, 4, startIndex)) return availableWidth * 0.25;
      return availableWidth * 0.5;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVaultCardWrapper(
                item: items[0],
                index: startIndex,
                width: getW(startIndex),
                height: 114,
                isExpanded: _isExpanded(startIndex, 4, startIndex),
                isShrunk: _isShrunk(startIndex, 4, startIndex),
              ),
              _buildVaultCardWrapper(
                item: items[1],
                index: startIndex + 1,
                width: getW(startIndex + 1),
                height: 114,
                isExpanded: _isExpanded(startIndex + 1, 4, startIndex),
                isShrunk: _isShrunk(startIndex + 1, 4, startIndex),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVaultCardWrapper(
                item: items[2],
                index: startIndex + 2,
                width: getW(startIndex + 2),
                height: 114,
                isExpanded: _isExpanded(startIndex + 2, 4, startIndex),
                isShrunk: _isShrunk(startIndex + 2, 4, startIndex),
              ),
              _buildVaultCardWrapper(
                item: items[3],
                index: startIndex + 3,
                width: getW(startIndex + 3),
                height: 114,
                isExpanded: _isExpanded(startIndex + 3, 4, startIndex),
                isShrunk: _isShrunk(startIndex + 3, 4, startIndex),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CASE 5+: Sayfalı Düzen (4'erli gruplar)
  Widget _buildPaginatedLayout(double width) {
    // Öğeleri 4'erli sayfalar halinde böl
    final int pageCount = (widget.items.length / 4).ceil();

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: pageCount,
            itemBuilder: (context, pageIdx) {
              final startIndex = pageIdx * 4;
              final pageItems = widget.items.skip(startIndex).take(4).toList();

              if (pageItems.length == 1)
                return _buildLayoutFor1(pageItems, width, startIndex);
              if (pageItems.length == 2)
                return _buildLayoutFor2(pageItems, width, startIndex);
              if (pageItems.length == 3)
                return _buildLayoutFor3(pageItems, width, startIndex);
              return _buildLayoutFor4(pageItems, width, startIndex);
            },
          ),
        ),
        const SizedBox(height: 8),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (idx) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == idx ? 12 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == idx
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Kart Sarmalayıcı Yardımcı Method
  Widget _buildVaultCardWrapper({
    required DashboardItem item,
    required int index,
    required double width,
    required double height,
    required bool isExpanded,
    bool isShrunk = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          int pageIdx = index ~/ 4;
          int localStartIndex = pageIdx * 4;
          int totalInPage = (widget.items.length - localStartIndex).clamp(0, 4);

          if (totalInPage == 4) {
            int localIdx = index - localStartIndex;
            int otherIdx = (localIdx % 2 == 0) ? index + 1 : index - 1;
            _selectedIndices.remove(otherIdx);
          } else if (totalInPage == 3) {
            if (index == localStartIndex + 1)
              _selectedIndices.remove(localStartIndex + 2);
            if (index == localStartIndex + 2)
              _selectedIndices.remove(localStartIndex + 1);
          }

          if (_selectedIndices.contains(index)) {
            _selectedIndices.remove(index);
          } else {
            _selectedIndices.add(index);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        child: NeuContainer(
          padding: EdgeInsets.zero,
          isInnerShadow: isExpanded, // Seçiliyse basılı efekt
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            child: _buildVaultCard(item, isExpanded, isShrunk, width, height),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String code) {
    switch (code) {
      case 'account_balance_wallet_rounded':
        return Icons.account_balance_wallet_rounded;
      case 'attach_money_rounded':
        return Icons.attach_money_rounded;
      case 'diamond_rounded':
        return Icons.diamond_rounded;
      default:
        return Icons.wallet_rounded;
    }
  }

  Color _getColorForItem(DashboardItem item) {
    if (item.balance < 0) {
      return const Color(0xFFE57373); // Reddish color for negative balance
    }

    final name = item.name.toLowerCase();
    if (name.contains('maaş')) return AppColors.primary;
    if (name.contains('dolar')) return Colors.greenAccent;
    if (name.contains('yastık') || name.contains('altın')) {
      return Colors.amberAccent;
    }
    return AppColors.secondary;
  }

  Widget _buildVaultCard(
    DashboardItem item,
    bool isExpanded,
    bool isShrunk,
    double width,
    double height,
  ) {
    final color = _getColorForItem(item);
    final icon = _getIconData(item.iconCode ?? '');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
      child: Stack(
        children: [
          // Arka plan filigranı (soluk simge)
          Positioned(
            right: isShrunk ? -10 : -25,
            bottom: isShrunk ? -10 : -25,
            child: Icon(
              icon,
              size: isShrunk ? 70 : 110,
              color: color.withValues(alpha: 0.04),
            ),
          ),

          // İçerik geçişi
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder:
                (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: SizedBox(
              key: ValueKey('${item.id}_${isExpanded}_${isShrunk}'),
              width: width,
              height: height,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 10.0,
                ),
                child: isExpanded
                    ? _buildExpandedContent(item, icon, color)
                    : isShrunk
                    ? _buildShrunkContent(item, icon, color)
                    : _buildNormalContent(item, icon, color),
              ),
            ),
          ),

          // Grup ise üstte geniş bir önizleme (Eğer çok dar değilse)
          if (item.isGroup && !isShrunk && !isExpanded)
            Positioned(
              top: 10,
              right: 12,
              child: _buildGroupPreview(item, color, isExpanded),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupPreview(DashboardItem item, Color color, bool isExpanded) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_rounded, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            '${item.itemCount}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalContent(DashboardItem item, IconData icon, Color color) {
    double effectiveBalance = item.balance;
    if (effectiveBalance == 0 &&
        (item.minLimit != null || item.maxLimit != null)) {
      effectiveBalance =
          ((item.minLimit ?? 0) + (item.maxLimit ?? 0)) /
          ((item.minLimit != null && item.maxLimit != null) ? 2 : 1);
    }

    String displayBalance = effectiveBalance.abs().toStringAsFixed(
      effectiveBalance.abs() > 1000 ? 0 : 2,
    ); // Küsuratı uçur çok büyükse

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Icon(icon, color: color, size: 26)],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (item.balance != 0)
                            Icon(
                              item.balance < 0
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_up_rounded,
                              color: item.balance < 0
                                  ? const Color(0xFFE57373)
                                  : Colors.greenAccent,
                              size: 18,
                            ),
                          if (item.balance != 0) const SizedBox(width: 4),
                          Text(
                            displayBalance,
                            style: TextStyle(
                              color: item.balance < 0
                                  ? const Color(0xFFE57373)
                                  : AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.currency,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.8),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShrunkContent(DashboardItem item, IconData icon, Color color) {
    return Center(child: Icon(icon, color: color, size: 22));
  }

  Widget _buildExpandedContent(DashboardItem item, IconData icon, Color color) {
    double effectiveBalance = item.balance;
    if (effectiveBalance == 0 &&
        (item.minLimit != null || item.maxLimit != null)) {
      effectiveBalance =
          ((item.minLimit ?? 0) + (item.maxLimit ?? 0)) /
          ((item.minLimit != null && item.maxLimit != null) ? 2 : 1);
    }

    String displayBalance = effectiveBalance.abs().toStringAsFixed(
      effectiveBalance.abs() > 1000 ? 0 : 2,
    ); // Küsüratsız eklenti

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Icon+Name on Left, Transactions compact grid on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Icon + Name
              Expanded(
                flex: 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Right: Transactions Grid (Wrap)
              if (item.itemIconCodes.isNotEmpty)
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 2,
                      runSpacing: 2,
                      children: List.generate(
                        item.itemIconCodes.length > 10
                            ? 10
                            : item.itemIconCodes.length,
                        (idx) {
                          // Son gösterilen öğe ve gerçekten 10'dan fazla varsa "+X" rozetini bas
                          if (idx == 9 && item.itemIconCodes.length > 10) {
                            final int hiddenCount =
                                item.itemIconCodes.length - 9;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+$hiddenCount',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: color.withValues(alpha: 0.9),
                                ),
                              ),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getIconData(item.itemIconCodes[idx]),
                                  size: 8,
                                  color: color.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  item.itemAmounts[idx].abs().toStringAsFixed(
                                    0,
                                  ),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: item.itemAmounts[idx] < 0
                                        ? const Color(0xFFE57373)
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom Row: Balance + Min/Max Constraints
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (item.balance != 0)
                  Icon(
                    item.balance < 0
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    color: item.balance < 0
                        ? const Color(0xFFE57373)
                        : Colors.greenAccent,
                    size: 24,
                  ),
                if (item.balance != 0) const SizedBox(width: 4),
                Text(
                  displayBalance,
                  style: TextStyle(
                    color: item.balance < 0
                        ? const Color(0xFFE57373)
                        : AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.currency,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.minLimit != null || item.maxLimit != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.minLimit != null)
                          Text(
                            '${item.minLimit!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        if (item.minLimit != null && item.maxLimit != null)
                          Text(
                            ' - ',
                            style: TextStyle(
                              fontSize: 14,
                              color: color.withValues(alpha: 0.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (item.maxLimit != null)
                          Text(
                            '${item.maxLimit!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
