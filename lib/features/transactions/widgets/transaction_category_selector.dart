import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';

class TransactionCategorySelector extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int selectedCategoryIndex;
  final int selectedSubModelIndex;
  final int expandedCategoryIndex;
  final Function(int categoryIndex, int subIndex, int expandedIndex) onChanged;

  const TransactionCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.selectedSubModelIndex,
    required this.expandedCategoryIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Güvenlik kontrolü
    final safeSelectedIndex = selectedCategoryIndex >= 0 && selectedCategoryIndex < categories.length 
        ? selectedCategoryIndex 
        : 0;
        
    final selectedCat = categories[safeSelectedIndex];
    final List<Map<String, dynamic>> subModels =
        (selectedCat['subModels'] as List<Map<String, dynamic>>?) ?? [];
    final bool isExpanded = expandedCategoryIndex == safeSelectedIndex;
    final bool hasSubModels = subModels.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- ANA KATEGORİ ŞERİDİ (Yatay) ---
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = index == safeSelectedIndex;
              final catColor = cat['color'] as Color;

              // Seçili alt model varsa, onun bilgilerini göster
              final bool showSubInfo =
                  isSelected &&
                  selectedSubModelIndex >= 0 &&
                  selectedSubModelIndex <
                      ((cat['subModels'] as List?)?.length ?? 0);

              final displayIcon = showSubInfo
                  ? (cat['subModels'] as List)[selectedSubModelIndex]['icon'] as IconData
                  : cat['icon'] as IconData;
              final displayName = showSubInfo
                  ? (cat['subModels'] as List)[selectedSubModelIndex]['name'] as String
                  : cat['name'] as String;

              return GestureDetector(
                onTap: () {
                  int newExp = expandedCategoryIndex;
                  int newSel = safeSelectedIndex;
                  int newSub = selectedSubModelIndex;

                  if (isSelected && (cat['subModels'] as List?)?.isNotEmpty == true) {
                    newExp = isExpanded ? -1 : safeSelectedIndex;
                  } else {
                    newSel = index;
                    newSub = -1;
                    newExp = -1;
                  }
                  onChanged(newSel, newSub, newExp);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: AnimatedRotation(
                          turns: isSelected ? 0.02 : 0.0, // Hafif bir eğim animasyonu
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? catColor.withValues(alpha: 0.15)
                                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                              border: Border.all(
                                color: isSelected
                                    ? catColor.withValues(alpha: 0.4)
                                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: catColor.withValues(alpha: 0.2),
                                        blurRadius: 15,
                                        spreadRadius: -2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              displayIcon,
                              color: isSelected
                                  ? AppColors.getAccentDeep(context, catColor)
                                  : AppColors.getTextSecondary(context).withValues(alpha: 0.5),
                              size: isSelected ? 28 : 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 70,
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.getTextPrimary(context)
                                : AppColors.getTextSecondary(context).withValues(alpha: 0.8),
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Hizalama için her zaman aynı yükseklikte bir alan bırakıyoruz
                      SizedBox(
                        height: 16,
                        child: (cat['subModels'] as List?)?.isNotEmpty == true
                            ? AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: isSelected 
                                      ? catColor 
                                      : AppColors.getTextSecondary(context).withValues(alpha: 0.3),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // --- ALT KATEGORİ ŞERİDİ ---
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: isExpanded && hasSubModels
              ? AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isExpanded ? 1.0 : 0.0,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                      itemCount: subModels.length,
                      itemBuilder: (context, subIndex) {
                        final sub = subModels[subIndex];
                        final isSubSelected = subIndex == selectedSubModelIndex;
                        final Color parentColor = selectedCat['color'] as Color;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              final newSub = isSubSelected ? -1 : subIndex;
                              onChanged(safeSelectedIndex, newSub, expandedCategoryIndex);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSubSelected
                                    ? parentColor.withValues(alpha: 0.2)
                                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                                border: Border.all(
                                  color: isSubSelected
                                      ? parentColor.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    sub['icon'] as IconData,
                                    size: 14,
                                    color: isSubSelected
                                        ? parentColor
                                        : AppColors.getTextSecondary(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    sub['name'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSubSelected ? FontWeight.w900 : FontWeight.w600,
                                      color: isSubSelected
                                          ? AppColors.getTextPrimary(context)
                                          : AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
