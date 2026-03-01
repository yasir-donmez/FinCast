import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/database/models/vault.dart';
import '../../../shared/widgets/neu_container.dart';

class ExpandableVaultGrid extends StatefulWidget {
  final List<Vault> vaults;

  const ExpandableVaultGrid({super.key, required this.vaults});

  @override
  State<ExpandableVaultGrid> createState() => _ExpandableVaultGridState();
}

class _ExpandableVaultGridState extends State<ExpandableVaultGrid> {
  int? _expandedTopIndex;
  int? _expandedBottomIndex;

  @override
  Widget build(BuildContext context) {
    // split items
    final List<Vault?> topItems = [];
    final List<Vault?> bottomItems = [];

    for (int i = 0; i < widget.vaults.length; i++) {
      if (i % 2 == 0) {
        topItems.add(widget.vaults[i]);
      } else {
        bottomItems.add(widget.vaults[i]);
      }
    }

    // add the + button
    if (widget.vaults.length % 2 == 0) {
      topItems.add(null); // null means Add Button
    } else {
      bottomItems.add(null);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow(topItems, true),
          const SizedBox(height: 16),
          _buildRow(bottomItems, false),
        ],
      ),
    );
  }

  Widget _buildRow(List<Vault?> items, bool isTopRow) {
    return Row(
      children: List.generate(items.length, (index) {
        final vault = items[index];
        final isExpanded = isTopRow
            ? _expandedTopIndex == index
            : _expandedBottomIndex == index;

        final hasExpandedInRow = isTopRow
            ? _expandedTopIndex != null
            : _expandedBottomIndex != null;

        // Base widths
        const double expandedWidth = 240;
        const double normalWidth = 140;
        const double shrunkWidth = 80;

        double currentWidth = normalWidth;
        if (hasExpandedInRow) {
          currentWidth = isExpanded ? expandedWidth : shrunkWidth;
        }

        return Padding(
          padding: const EdgeInsets.only(right: AppSizes.paddingMedium),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isTopRow) {
                  _expandedTopIndex = isExpanded ? null : index;
                } else {
                  _expandedBottomIndex = isExpanded ? null : index;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: currentWidth,
              height: 110, // Kapsayıcı yükseklik
              child: NeuContainer(
                padding: EdgeInsets.zero,
                isInnerShadow: isExpanded, // Basılıysa (Expanded) içe göçük
                child: vault == null
                    ? _buildAddCard(currentWidth >= normalWidth - 10)
                    : _buildVaultCard(
                        vault,
                        isExpanded,
                        currentWidth <= shrunkWidth + 10,
                      ),
              ),
            ),
          ),
        );
      }),
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

  Color _getColorForVault(Vault vault) {
    final name = vault.name.toLowerCase();
    if (name.contains('maaş')) return AppColors.primary;
    if (name.contains('dolar')) return Colors.greenAccent;
    if (name.contains('yastık') || name.contains('altın')) {
      return Colors.amberAccent;
    }
    return AppColors.secondary;
  }

  Widget _buildVaultCard(Vault vault, bool isExpanded, bool isShrunk) {
    final color = _getColorForVault(vault);
    final icon = _getIconData(vault.iconCode ?? '');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
      child: Stack(
        children: [
          // Arka plan filigranı (soluk simge)
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(icon, size: 100, color: color.withValues(alpha: 0.05)),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: isExpanded
                ? _buildExpandedContent(vault, icon, color)
                : isShrunk
                ? _buildShrunkContent(vault, icon, color)
                : _buildNormalContent(vault, icon, color),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalContent(Vault vault, IconData icon, Color color) {
    return OverflowBox(
      maxWidth: 140 - 24, // normalWidth - padding
      minWidth: 140 - 24,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vault.balance.toStringAsFixed(0),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                vault.currency,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShrunkContent(Vault vault, IconData icon, Color color) {
    return Center(child: Icon(icon, color: color, size: 36));
  }

  Widget _buildExpandedContent(Vault vault, IconData icon, Color color) {
    return OverflowBox(
      maxWidth: 240 - 24, // expandedWidth - padding
      minWidth: 240 - 24,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  vault.name,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      vault.balance.toStringAsFixed(2),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vault.currency,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCard(bool showText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_rounded,
            color: AppColors.textSecondary,
            size: 32,
          ),
          if (showText) const SizedBox(height: 8),
          if (showText)
            const Text(
              "Yeni Ekle",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
