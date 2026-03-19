import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../dashboard_providers.dart';
import '../../../shared/widgets/neu_container.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/database/database_service.dart';
import '../../../core/providers/db_providers.dart';

class ExpandableVaultGrid extends ConsumerStatefulWidget {
  final List<DashboardItem> items;

  const ExpandableVaultGrid({super.key, required this.items});

  @override
  ConsumerState<ExpandableVaultGrid> createState() =>
      _ExpandableVaultGridState();
}

class _ExpandableVaultGridState extends ConsumerState<ExpandableVaultGrid> {
  final Set<int> _selectedIndices =
      {}; // Sayfa başı veya satır başı bağımsız detay durumu
  late PageController _pageController;
  int _currentPage = 0;

  bool _isExpanded(int index, int layoutType, int startIndex) {
    if (layoutType == 1) return true;
    if (layoutType == 2) return true;
    if (layoutType == 3) {
      if (index == startIndex) return true;
      return _selectedIndices.contains(index);
    }
    return _selectedIndices.contains(index);
  }

  bool _isShrunk(int index, int layoutType, int startIndex) {
    if (layoutType <= 2) return false;
    if (layoutType == 3) {
      if (index == startIndex) return false;
      int otherIdx = (index == startIndex + 1)
          ? startIndex + 2
          : startIndex + 1;
      return _selectedIndices.contains(otherIdx);
    }
    if (layoutType == 4) {
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
        return _buildPaginatedLayout(parentWidth);
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
        pageStartIndex: startIndex,
        layoutType: 1,
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
    if (items.isEmpty) return const SizedBox.shrink();
    final double cardWidth = width - (AppSizes.paddingMedium * 2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildVaultCardWrapper(
            item: items[0],
            index: startIndex,
            pageStartIndex: startIndex,
            layoutType: 2,
            width: cardWidth,
            height: 114,
            isExpanded: true,
            isShrunk: false,
          ),
          if (items.length > 1) ...[
            const SizedBox(height: 8),
            _buildVaultCardWrapper(
              item: items[1],
              index: startIndex + 1,
              pageStartIndex: startIndex,
              layoutType: 2,
              width: cardWidth,
              height: 114,
              isExpanded: true,
              isShrunk: false,
            ),
          ],
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
    if (items.isEmpty) return const SizedBox.shrink();

    final int totalInPage = items.length;
    // Calculate total layout width accurately, subtracting padding
    final availableWidth = width - (AppSizes.paddingMedium * 3);
    final leftWidth =
        availableWidth * 0.55; // Biraz daha büyük sol taraf (ya da %50)
    final rightWidth = availableWidth * 0.45; // Sağ tarafa kalan

    final rightH1 = totalInPage > 1
        ? (_isExpanded(startIndex + 1, 3, startIndex)
              ? 160.0
              : (_isShrunk(startIndex + 1, 3, startIndex) ? 60.0 : 114.0))
        : 114.0;
    final rightH2 = totalInPage > 2
        ? (_isExpanded(startIndex + 2, 3, startIndex)
              ? 160.0
              : (_isShrunk(startIndex + 2, 3, startIndex) ? 60.0 : 114.0))
        : 114.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildVaultCardWrapper(
            item: items[0],
            index: startIndex,
            pageStartIndex: startIndex,
            layoutType: 3,
            width: leftWidth,
            height: 236,
            isExpanded: true,
            isShrunk: false,
          ),
          if (totalInPage > 1)
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildVaultCardWrapper(
                  item: items[1],
                  index: startIndex + 1,
                  pageStartIndex: startIndex,
                  layoutType: 3,
                  width: rightWidth,
                  height: rightH1,
                  isExpanded: _isExpanded(startIndex + 1, 3, startIndex),
                  isShrunk: _isShrunk(startIndex + 1, 3, startIndex),
                ),
                if (totalInPage > 2) ...[
                  const SizedBox(height: 8),
                  _buildVaultCardWrapper(
                    item: items[2],
                    index: startIndex + 2,
                    pageStartIndex: startIndex,
                    layoutType: 3,
                    width: rightWidth,
                    height: rightH2,
                    isExpanded: _isExpanded(startIndex + 2, 3, startIndex),
                    isShrunk: _isShrunk(startIndex + 2, 3, startIndex),
                  ),
                ],
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
    if (items.isEmpty) return const SizedBox.shrink();

    final availableWidth = width - (AppSizes.paddingMedium * 3);

    double getW(int idx) {
      if (_isExpanded(idx, 4, startIndex)) return availableWidth * 0.75;
      if (_isShrunk(idx, 4, startIndex)) return availableWidth * 0.25;
      return availableWidth * 0.5;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVaultCardWrapper(
                item: items[0],
                index: startIndex,
                pageStartIndex: startIndex,
                layoutType: 4,
                width: getW(startIndex),
                height: 114,
                isExpanded: _isExpanded(startIndex, 4, startIndex),
                isShrunk: _isShrunk(startIndex, 4, startIndex),
              ),
              if (items.length > 1)
                _buildVaultCardWrapper(
                  item: items[1],
                  index: startIndex + 1,
                  pageStartIndex: startIndex,
                  layoutType: 4,
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
              if (items.length > 2)
                _buildVaultCardWrapper(
                  item: items[2],
                  index: startIndex + 2,
                  pageStartIndex: startIndex,
                  layoutType: 4,
                  width: getW(startIndex + 2),
                  height: 114,
                  isExpanded: _isExpanded(startIndex + 2, 4, startIndex),
                  isShrunk: _isShrunk(startIndex + 2, 4, startIndex),
                ),
              if (items.length > 3)
                _buildVaultCardWrapper(
                  item: items[3],
                  index: startIndex + 3,
                  pageStartIndex: startIndex,
                  layoutType: 4,
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

  // CASE 5+: Sayfalı Düzen (Dinamik Gruplar)
  Widget _buildPaginatedLayout(double width) {
    // Dinamik bakiye ve yerleşim durumuna göre sayfaları hesapla
    List<List<DashboardItem>> pages = [];
    List<int> pageStartIndices = [];
    int i = 0;
    while (i < widget.items.length) {
      pageStartIndices.add(i);
      int layoutCount = widget.items[i].dashboardLayoutType;
      if (layoutCount < 1) layoutCount = 4;
      if (layoutCount > 4) layoutCount = 4;

      List<DashboardItem> pageItems = [];
      for (int j = 0; j < layoutCount; j++) {
        if (i + j < widget.items.length) {
          pageItems.add(widget.items[i + j]);
        } else {
          break;
        }
      }

      pages.add(pageItems);
      i += pageItems.length;
    }

    final int pageCount = pages.length;
    if (_currentPage >= pageCount && pageCount > 0) {
      _currentPage = pageCount - 1;
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: pageCount,
            itemBuilder: (context, pageIdx) {
              if (pageIdx >= pages.length) return const SizedBox.shrink();

              final pageItems = pages[pageIdx];
              final startIndex = pageStartIndices[pageIdx];
              final int layoutType = pageItems.length;

              switch (layoutType) {
                case 1:
                  return _buildLayoutFor1(pageItems, width, startIndex);
                case 2:
                  return _buildLayoutFor2(pageItems, width, startIndex);
                case 3:
                  return _buildLayoutFor3(pageItems, width, startIndex);
                default:
                  return _buildLayoutFor4(pageItems, width, startIndex);
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        // Dots
        if (pageCount > 1)
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
                      : AppColors.getTextSecondary(context).withValues(alpha: 0.3),
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
    required int pageStartIndex,
    required int layoutType,
    required double width,
    required double height,
    required bool isExpanded,
    bool isShrunk = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (layoutType == 4) {
            int localIdx = index - pageStartIndex;
            int otherIdxInRow = (localIdx % 2 == 0) ? index + 1 : index - 1;
            _selectedIndices.remove(otherIdxInRow);
          } else if (layoutType == 3) {
            if (index == pageStartIndex + 1) {
              _selectedIndices.remove(pageStartIndex + 2);
            }
            if (index == pageStartIndex + 2) {
              _selectedIndices.remove(pageStartIndex + 1);
            }
          }

          if (_selectedIndices.contains(index)) {
            _selectedIndices.remove(index);
          } else {
            _selectedIndices.add(index);
          }
        });
      },
      onLongPress: () => _showLayoutSettings(item),
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
    return IconUtils.getIcon(code);
  }

  Color _getColorForItem(DashboardItem item) {
    if (item.balance < 0) {
      return AppColors.getExpense(context);
    }
    return IconUtils.getColor(item.iconCode ?? item.name);
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
    // Filigran için her zaman orijinal ikon rengini kullan (bakiyeden bağımsız)
    final originalColor = IconUtils.getColor(item.iconCode ?? item.name);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
      child: Stack(
        children: [
          // Arka plan filigranı (soluk simge) - bakiyeden bağımsız renk
          Positioned(
            right: isShrunk ? -10 : -20,
            bottom: isShrunk ? -10 : -20,
            child: Icon(
              icon,
              size: isShrunk ? 70 : 120,
              color: originalColor.withValues(alpha: 0.10),
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
              key: ValueKey('${item.id}_${isExpanded}_$isShrunk'),
              width: width,
              height: height,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 10.0,
                ),
                child: isExpanded
                    ? _buildExpandedContent(item, icon, color, width, height)
                    : isShrunk
                    ? _buildShrunkContent(item, icon, color, width, height)
                    : _buildNormalContent(item, icon, color, width, height),
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

  Widget _buildNormalContent(
    DashboardItem item,
    IconData icon,
    Color color,
    double width,
    double height,
  ) {
    String displayBalance = CurrencyUtils.formatAmount(item.balance.abs());

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
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              item.balance < 0
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_up_rounded,
                              color: item.balance < 0
                                  ? AppColors.getExpense(context)
                                  : AppColors.getIncome(context),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              displayBalance,
                              style: TextStyle(
                                color: item.balance < 0
                                    ? AppColors.getExpense(context)
                                    : AppColors.getTextPrimary(context),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildShrunkContent(
    DashboardItem item,
    IconData icon,
    Color color,
    double width,
    double height,
  ) {
    return Center(child: Icon(icon, color: color, size: 22));
  }

  Widget _buildExpandedContent(
    DashboardItem item,
    IconData icon,
    Color color,
    double width,
    double height,
  ) {
    String displayBalance = CurrencyUtils.formatAmount(item.balance.abs());

    // Determine Layout Mode
    final bool isFull = width > 300 && height > 200;
    final bool isWide = width > 300 && height < 150;
    final bool isTall = width < 200;

    // Common Components
    Widget buildHeader() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: (isTall || isWide) ? 12 : 14),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                color: AppColors.getTextSecondary(context),
                fontSize: (isTall || isWide) ? 10 : 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: (isFull || isTall) ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    Widget buildTransactionsGrid(int maxItems) {
      if (item.itemIconCodes.isEmpty) return const SizedBox.shrink();
      return Wrap(
        alignment: (isTall || isWide) ? WrapAlignment.start : WrapAlignment.end,
        spacing: 2,
        runSpacing: 2,
        children: List.generate(
          item.itemIconCodes.length > maxItems
              ? maxItems
              : item.itemIconCodes.length,
          (idx) {
            if (idx == maxItems - 1 && item.itemIconCodes.length > maxItems) {
              final int hiddenCount =
                  item.itemIconCodes.length - (maxItems - 1);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+$hiddenCount',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                    color: item.itemAmounts[idx] < 0
                        ? AppColors.getExpense(context).withValues(alpha: 0.8)
                        : AppColors.getIncome(context).withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    CurrencyUtils.formatAmount(item.itemAmounts[idx].abs()),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: item.itemAmounts[idx] < 0
                          ? AppColors.getExpense(context)
                          : AppColors.getIncome(context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    Widget buildBalanceInfo() {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Icon(
              item.balance < 0
                  ? Icons.trending_down_rounded
                  : Icons.trending_up_rounded,
              color: item.balance < 0
                  ? AppColors.getExpense(context)
                  : AppColors.getIncome(context),
              size: isFull ? 24 : 18,
            ),
            const SizedBox(width: 4),
            Text(
              displayBalance,
              style: TextStyle(
                color: item.balance < 0
                    ? AppColors.getExpense(context)
                    : AppColors.getIncome(context),
                fontSize: isFull ? 26 : 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item.currency,
              style: TextStyle(
                color: color,
                fontSize: isFull ? 12 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isFull && (item.minLimit != null || item.maxLimit != null)) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                        CurrencyUtils.formatAmount(item.minLimit!),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.getIncome(context),
                          fontWeight: FontWeight.w900,
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
                        CurrencyUtils.formatAmount(item.maxLimit!),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.getExpense(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 3, child: buildHeader()),
          Expanded(flex: 4, child: Center(child: buildBalanceInfo())),
          Expanded(flex: 3, child: buildTransactionsGrid(4)),
        ],
      );
    }

    if (isTall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(child: buildTransactionsGrid(12)),
          ),
          const SizedBox(height: 8),
          buildBalanceInfo(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: isFull ? 2 : 3, child: buildHeader()),
            Expanded(
              flex: isFull ? 3 : 2,
              child: buildTransactionsGrid(isFull ? 12 : 6),
            ),
          ],
        ),
        const Spacer(),
        buildBalanceInfo(),
        if (!isFull && (item.minLimit != null || item.maxLimit != null))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.minLimit != null) ...[
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 10,
                      color: AppColors.getExpense(context),
                    ),
                    Text(
                      CurrencyUtils.formatAmount(item.minLimit!),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.getExpense(context),
                      ),
                    ),
                  ],
                  if (item.minLimit != null && item.maxLimit != null)
                    Text(
                      ' ~ ',
                      style: TextStyle(
                        fontSize: 10,
                        color: color.withValues(alpha: 0.5),
                      ),
                    ),
                  if (item.maxLimit != null) ...[
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 10,
                      color: AppColors.getIncome(context),
                    ),
                    Text(
                      CurrencyUtils.formatAmount(item.maxLimit!),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.getIncome(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showLayoutSettings(DashboardItem item) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Görünüm ve Sıralama',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLayoutOption(
                      item,
                      1,
                      Icons.crop_square_rounded,
                      '1\'li',
                    ),
                    _buildLayoutOption(
                      item,
                      2,
                      Icons.view_headline_rounded,
                      '2\'li',
                    ),
                    _buildLayoutOption(
                      item,
                      3,
                      Icons.view_quilt_rounded,
                      '3\'lü',
                    ),
                    _buildLayoutOption(
                      item,
                      4,
                      Icons.view_module_rounded,
                      '4\'lü',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.arrow_upward_rounded),
                  title: const Text('Öne Taşı'),
                  onTap: () {
                    Navigator.pop(context);
                    _moveVault(item, -1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_downward_rounded),
                  title: const Text('Arkaya Taşı'),
                  onTap: () {
                    Navigator.pop(context);
                    _moveVault(item, 1);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutOption(
    DashboardItem item,
    int type,
    IconData icon,
    String label,
  ) {
    final bool isSelected = item.dashboardLayoutType == type;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _updateVaultLayout(item, type);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.getTextSecondary(context).withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.getPrimary(context) : AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.getPrimary(context) : AppColors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateVaultLayout(DashboardItem item, int layoutType) async {
    // Bütün kasalara aynı dizilimi uygula
    final vaults = ref.read(allVaultsProvider);
    for (var v in vaults) {
      v.dashboardLayoutType = layoutType;
    }
    await DatabaseService.updateAllVaults(vaults);

    // Bütün tekil işlemlere aynı dizilimi uygula
    final txs = ref.read(allTransactionsProvider);
    for (var t in txs) {
      t.dashboardLayoutType = layoutType;
    }
    await DatabaseService.updateAllTransactions(txs);

    HapticFeedback.mediumImpact();
  }

  Future<void> _moveVault(DashboardItem item, int direction) async {
    final isVault = item.id.startsWith('v_');
    final realId = int.tryParse(
      item.id.replaceFirst(isVault ? 'v_' : 't_', ''),
    );
    if (realId == null) return;

    final allItems = ref.read(dashboardItemsProvider);
    // Sort logic just to be safe, though provider should return sorted
    final visibleItems = List<DashboardItem>.from(allItems)
      ..sort((a, b) {
        int cmp = a.dashboardOrder.compareTo(b.dashboardOrder);
        if (cmp == 0) return a.id.compareTo(b.id);
        return cmp;
      });

    int index = visibleItems.indexWhere((v) => v.id == item.id);
    if (index == -1) return;

    int newIndex = index + direction;
    if (newIndex < 0 || newIndex >= visibleItems.length) return;

    // Sadece orderları yer değiştirme yerine araya sıkıştırma da yapabiliriz
    // Ama kolaylık açısından herkesi baştan indeksleyelim ve hedefi yer değiştirelim.
    for (int i = 0; i < visibleItems.length; i++) {
      // Şimdilik sadece geçici bir alanda güncelliyoruz
      // Doğrudan DB nesneleri olmadığı için DB nesnelerine yansıtacağız
    }

    // Basit takas (sadece order sayılarını takas eder, eger cakısan varsa tam cozmez ama 10'ar 10'ar artışta çözer)
    final item1 = visibleItems[index];
    final item2 = visibleItems[newIndex];
    int tempOrder = item1.dashboardOrder;
    int order1 = item2.dashboardOrder;
    int order2 = tempOrder;

    if (order1 == order2) {
      // Edge case fallback
      order1 = index * 10;
      order2 = newIndex * 10;
    }

    // Update first item in DB
    if (item1.id.startsWith('v_')) {
      final vault = ref
          .read(allVaultsProvider)
          .firstWhere((v) => 'v_${v.id}' == item1.id);
      vault.dashboardOrder = order1;
      await DatabaseService.updateVault(vault);
    } else {
      final tx = ref
          .read(allTransactionsProvider)
          .firstWhere((t) => 't_${t.id}' == item1.id);
      tx.dashboardOrder = order1;
      await DatabaseService.updateTransaction(tx);
    }

    // Update second item in DB
    if (item2.id.startsWith('v_')) {
      final vault = ref
          .read(allVaultsProvider)
          .firstWhere((v) => 'v_${v.id}' == item2.id);
      vault.dashboardOrder = order2;
      await DatabaseService.updateVault(vault);
    } else {
      final tx = ref
          .read(allTransactionsProvider)
          .firstWhere((t) => 't_${t.id}' == item2.id);
      tx.dashboardOrder = order2;
      await DatabaseService.updateTransaction(tx);
    }

    HapticFeedback.mediumImpact();
  }
}
