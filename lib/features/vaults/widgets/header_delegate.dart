import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/fluid_container.dart';
import '../vaults_providers.dart';
import 'vault_card_stack.dart';

class TrueMorphDeckHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<TransactionGroup> groups;
  final List<TransactionUI> allTransactions;
  final String? selectedVaultId;
  final Function(String?) onVaultSelect;
  final Color activeColor;
  final VoidCallback onManageVaults;
  final VoidCallback onAddVault;
  final AppLocalizations l10n;
  final Function(String) onVaultTap;

  TrueMorphDeckHeaderDelegate({
    required this.groups,
    required this.allTransactions,
    required this.selectedVaultId,
    required this.onVaultSelect,
    required this.activeColor,
    required this.onManageVaults,
    required this.onAddVault,
    required this.l10n,
    required this.onVaultTap,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final topPadding = MediaQuery.of(context).padding.top;
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final deckItems = [null, ...groups.map((g) => g.id)];
    final currentIndex = deckItems.indexOf(selectedVaultId);

    final bgAlpha = Curves.easeOutQuad.transform((progress * 1.6).clamp(0.0, 1.0));

    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: bgAlpha * 20,
            sigmaY: bgAlpha * 20,
          ),
          child: Container(
            color: AppColors.getBackground(context).withValues(alpha: bgAlpha * 0.15),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: lerpDouble(topPadding + 80, topPadding + 4, progress)!,
                  left: 0, right: 0,
                  height: lerpDouble(300, 56, progress)!,
                  child: VaultCardStack(
                    deckItems: deckItems,
                    allTransactions: allTransactions,
                    currentIndex: currentIndex,
                    onVaultSelect: onVaultSelect,
                    activeColor: activeColor,
                    l10n: l10n,
                    groups: groups,
                    morphProgress: progress,
                    onVaultTap: onVaultTap,
                  ),
                ),

                Positioned(
                  left: 20 - (progress * 150),
                  top: topPadding + 10,
                  child: Opacity(
                    opacity: (1 - progress * 1.8).clamp(0.0, 1.0),
                    child: Text(l10n.vaults, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                  ),
                ),

                Positioned(
                  right: 20 - (progress * 150),
                  top: topPadding + 10,
                  child: Opacity(
                    opacity: (1 - progress * 1.8).clamp(0.0, 1.0),
                    child: Row(
                      children: [
                        HeaderIconButton(icon: Icons.account_balance_wallet_rounded, onTap: onManageVaults),
                        const SizedBox(width: 8),
                        HeaderIconButton(icon: Icons.add_rounded, onTap: onAddVault),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 420;
  @override
  double get minExtent => 60 + 40;
  @override
  bool shouldRebuild(covariant TrueMorphDeckHeaderDelegate oldDelegate) => true;
}

class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? activeColor;
  
  const HeaderIconButton({
    super.key,
    required this.icon, 
    required this.onTap,
    this.isSelected = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FluidContainer(
        padding: const EdgeInsets.all(10), 
        borderRadius: 14, 
        isGlass: true, 
        color: isSelected ? (activeColor ?? AppColors.getPrimary(context)).withValues(alpha: 0.1) : null, 
        child: Icon(icon, size: 20, color: isSelected ? activeColor : Colors.grey),
      ),
    );
  }
}
