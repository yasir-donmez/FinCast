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
      children: [
        // --- ANA MODEL SATIRI (Yatay Scroll) ---
        SizedBox(
          height: 105,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = index == safeSelectedIndex;

              // Seçili alt model varsa, onun bilgilerini göster
              final bool showSubInfo =
                  isSelected &&
                  selectedSubModelIndex >= 0 &&
                  selectedSubModelIndex <
                      ((cat['subModels'] as List?)?.length ?? 0);

              final displayIcon = showSubInfo
                  ? (cat['subModels']
                            as List<
                              Map<String, dynamic>
                            >)[selectedSubModelIndex]['icon']
                        as IconData
                  : cat['icon'] as IconData;
              final displayName = showSubInfo
                  ? (cat['subModels']
                            as List<
                              Map<String, dynamic>
                            >)[selectedSubModelIndex]['name']
                        as String
                  : cat['name'] as String;

              return GestureDetector(
                onTap: () {
                  int newExp = expandedCategoryIndex;
                  int newSel = safeSelectedIndex;
                  int newSub = selectedSubModelIndex;

                  if (isSelected && (cat['subModels'] as List?)?.isNotEmpty == true) {
                    // Aynı kategoriye tekrar tıklama → aç/kapat
                    newExp = isExpanded ? -1 : safeSelectedIndex;
                  } else {
                    // Farklı kategori seçimi
                    newSel = index;
                    newSub = -1;
                    newExp = -1;
                  }
                  onChanged(newSel, newSub, newExp);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSizes.paddingMedium),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 92 : 78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusDefault,
                      ),
                      color: isSelected
                          ? AppColors.getInnerSurface(context)
                          : isDark
                          ? AppColors.getSurface(context)
                          : Colors.white.withValues(alpha: 0.5), 
                      border: isSelected
                          ? Border.all(
                              color: AppColors.getAccentDeep(
                                context,
                                cat['color'] as Color,
                              ).withValues(alpha: 0.4),
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.getAccentDeep(
                                  context,
                                  cat['color'] as Color,
                                ).withValues(alpha: 0.15),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: AppColors.getDarkShadow(context),
                                offset: const Offset(4, 4),
                                blurRadius: 8,
                              ),
                              BoxShadow(
                                color: AppColors.getLightShadow(context),
                                offset: const Offset(-3, -3),
                                blurRadius: 8,
                              ),
                            ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              displayIcon,
                              key: ValueKey(
                                'icon-${showSubInfo ? (cat['subModels'] as List)[selectedSubModelIndex]['id'] : cat['id']}',
                              ),
                              color: isSelected
                                  ? AppColors.getAccentDeep(
                                      context,
                                      cat['color'] as Color,
                                    )
                                  : AppColors.getTextSecondary(context),
                              size: isSelected ? 28 : 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              key: ValueKey(
                                'text-${showSubInfo ? (cat['subModels'] as List)[selectedSubModelIndex]['id'] : cat['id']}',
                              ),
                              height: 34,
                              alignment: Alignment.center,
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.getTextPrimary(context)
                                      : AppColors.getTextSecondary(context),
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (isSelected && (cat['subModels'] as List?)?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.expand_more_rounded,
                                  size: 14,
                                  color: AppColors.getAccentDeep(
                                    context,
                                    cat['color'] as Color,
                                  ).withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // --- ALT MODEL SATIRI ---
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: isExpanded && hasSubModels ? 48 : 0,
          child: AnimatedOpacity(
            opacity: isExpanded && hasSubModels ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
                vertical: 6,
              ),
              child: Row(
                children: List.generate(subModels.length, (subIndex) {
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSubSelected
                              ? parentColor.withValues(alpha: 0.15)
                              : AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSubSelected
                                ? parentColor.withValues(alpha: 0.5)
                                : isDark
                                ? AppColors.getDarkShadow(context).withValues(alpha: 0.3)
                                : AppColors.getDarkShadow(context).withValues(alpha: 0.6),
                            width: 1,
                          ),
                          boxShadow: isSubSelected
                              ? [
                                  BoxShadow(
                                    color: parentColor.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
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
                                fontWeight: isSubSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
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
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
