import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/models/vault.dart';
import '../../../core/providers/db_providers.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/fluid_container.dart';
import '../../../shared/widgets/fluid_switch.dart';
import '../../../shared/widgets/fluid_animated_icon.dart';
import '../vaults_providers.dart';

enum VaultDetailTab { transactions, manage }

class VaultDetailSheet extends ConsumerStatefulWidget {
  final String vaultId; // 'v_1' formatında

  const VaultDetailSheet({super.key, required this.vaultId});

  @override
  ConsumerState<VaultDetailSheet> createState() => _VaultDetailSheetState();
}

class _VaultDetailSheetState extends ConsumerState<VaultDetailSheet> with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  bool _isEditingName = false;
  VaultDetailTab _activeTab = VaultDetailTab.transactions;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _switchTab(VaultDetailTab tab) {
    if (_activeTab == tab) return;
    HapticFeedback.mediumImpact();
    setState(() => _activeTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final allVaults = ref.watch(allVaultsProvider);
    final vaultDbId = int.tryParse(widget.vaultId.replaceFirst('v_', ''));
    
    final vault = allVaults.where((v) => v.id == vaultDbId).firstOrNull;
    if (vault == null) return const SizedBox.shrink();

    if (!_isEditingName && _nameController.text != vault.name) {
      _nameController.text = vault.name;
    }

    final allTransactions = ref.watch(vaultTransactionsProvider);
    final vaultTransactions = allTransactions.where((t) => t.groupIds.contains(widget.vaultId)).toList();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.getPrimary(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final scalingFactor = (screenHeight / 812.0).clamp(0.85, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTabSelector(activeColor, isDark, scalingFactor),
        SizedBox(height: 12 * scalingFactor),
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05), 
                    end: Offset.zero
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _activeTab == VaultDetailTab.transactions
              ? _buildMainView(context, vault, vaultTransactions, activeColor, isDark)
              : _buildSelectionView(context, allTransactions, vaultTransactions, activeColor, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector(Color activeColor, bool isDark, double scalingFactor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8 * scalingFactor),
      height: 48 * scalingFactor,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            alignment: _activeTab == VaultDetailTab.transactions ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 40 * scalingFactor,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _switchTab(VaultDetailTab.transactions),
                  child: Center(
                    child: Text(
                      'İşlemler',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13 * scalingFactor,
                        color: _activeTab == VaultDetailTab.transactions ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _switchTab(VaultDetailTab.manage),
                  child: Center(
                    child: Text(
                      'Yönet',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13 * scalingFactor,
                        color: _activeTab == VaultDetailTab.manage ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainView(BuildContext context, Vault vault, List<TransactionUI> vaultTransactions, Color activeColor, bool isDark) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scalingFactor = (screenHeight / 812.0).clamp(0.85, 1.0);
    return Column(
      key: const ValueKey('main_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. ÜST KISIM: İsim ve Dashboard Toggle
        Row(
          children: [
            Expanded(
              child: _isEditingName
                  ? TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: TextStyle(fontSize: 22 * scalingFactor, fontWeight: FontWeight.w900),
                      decoration: InputDecoration(
                        hintText: 'Kasa Adı',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_rounded, color: Colors.green),
                          onPressed: () async {
                            if (_nameController.text.trim().isNotEmpty) {
                              vault.name = _nameController.text.trim();
                              await DatabaseService.updateVault(vault);
                            }
                            setState(() => _isEditingName = false);
                          },
                        ),
                      ),
                      onSubmitted: (val) async {
                         if (val.trim().isNotEmpty) {
                            vault.name = val.trim();
                            await DatabaseService.updateVault(vault);
                          }
                          setState(() => _isEditingName = false);
                      },
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _isEditingName = true),
                      child: Row(
                        children: [
                          Text(
                            vault.name,
                            style: TextStyle(fontSize: 22 * scalingFactor, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                          const SizedBox(width: 8),
                          FluidAnimatedIcon(
                            isActive: _isEditingName,
                            activeIcon: Icons.check_circle_outline_rounded,
                            inactiveIcon: Icons.edit_rounded,
                            color: activeColor,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
            ),
            Row(
              children: [
                const Text(
                  'Ana Sayfa', 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)
                ),
                FluidSwitch(
                  value: vault.showOnDashboard, 
                  activeColor: activeColor,
                  activeIcon: Icons.visibility_rounded,
                  inactiveIcon: Icons.visibility_off_rounded,
                  scalingFactor: 0.8, // Match the scale the user had
                  onChanged: (val) async {
                    vault.showOnDashboard = val;
                    await DatabaseService.updateVault(vault);
                    HapticFeedback.lightImpact();
                  }
                ),
              ],
            ),
          ],
        ),
        
        SizedBox(height: 24 * scalingFactor),

        // 2. İŞLEM LİSTESİ BAŞLIĞI
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BU KASADAKİ İŞLEMLER', 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.withValues(alpha: 0.5), letterSpacing: 2)
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (vaultTransactions.isEmpty)
          _buildEmptyState('Bu kasada henüz işlem yok.', Icons.layers_clear_rounded, activeColor)
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4 * scalingFactor),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              physics: const BouncingScrollPhysics(),
              itemCount: vaultTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tx = vaultTransactions[index];
                return FluidContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 24,
                  isGlass: true,
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: tx.color.withValues(alpha: 0.12), 
                          borderRadius: BorderRadius.circular(14 * scalingFactor)
                        ),
                        child: Icon(tx.icon, color: tx.color, size: 20 * scalingFactor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15 * scalingFactor, letterSpacing: -0.2)),
                            Text(
                              '₺${CurrencyUtils.formatAmount(tx.amount)}', 
                              style: TextStyle(
                                color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context), 
                                fontWeight: FontWeight.w900,
                                fontSize: 13 * scalingFactor,
                              )
                            ),
                          ],
                        ),
                      ),
                      if (tx.showOnDashboard)
                         Padding(
                           padding: const EdgeInsets.only(right: 8),
                           child: Icon(Icons.dashboard_rounded, size: 14, color: AppColors.getPrimary(context).withValues(alpha: 0.4)),
                         ),
                    ],
                  ),
                );
              },
            ),
          ),
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSelectionView(BuildContext context, List<TransactionUI> allTransactions, List<TransactionUI> vaultTransactions, Color activeColor, bool isDark) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scalingFactor = (screenHeight / 812.0).clamp(0.85, 1.0);
    return Column(
      key: const ValueKey('selection_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'İŞLEM SEÇİMİ', 
              style: TextStyle(fontSize: 18 * scalingFactor, fontWeight: FontWeight.w900, letterSpacing: -0.5)
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${vaultTransactions.length} Seçili', 
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: activeColor)
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45 * scalingFactor),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: allTransactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tx = allTransactions[index];
              final isSelected = tx.groupIds.contains(widget.vaultId);
              
              return GestureDetector(
                onTap: () async {
                  final helper = ref.read(transactionGroupingProvider);
                  await helper.toggleVault(tx.id, widget.vaultId);
                  HapticFeedback.selectionClick();
                },
                child: FluidContainer(
                  padding: EdgeInsets.all(12 * scalingFactor),
                  borderRadius: 24 * scalingFactor,
                  isGlass: true,
                  color: isSelected ? activeColor.withValues(alpha: 0.08) : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01)),
                  child: Row(
                    children: [
                      Container(
                        width: 36 * scalingFactor, height: 36 * scalingFactor,
                        decoration: BoxDecoration(
                          color: tx.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(tx.icon, color: tx.color, size: 18 * scalingFactor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14 * scalingFactor, letterSpacing: -0.2)),
                            Text('₺${CurrencyUtils.formatAmount(tx.amount)}', style: TextStyle(fontSize: 12 * scalingFactor, color: Colors.grey, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      FluidSwitch(
                        value: isSelected, 
                        activeColor: activeColor,
                        activeIcon: Icons.check_rounded,
                        inactiveIcon: Icons.close_rounded,
                        scalingFactor: 0.8, // Match the scale the user had
                        onChanged: (val) async {
                          final helper = ref.read(transactionGroupingProvider);
                          await helper.toggleVault(tx.id, widget.vaultId);
                          HapticFeedback.selectionClick();
                        }
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon, Color color) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scalingFactor = (screenHeight / 812.0).clamp(0.85, 1.0);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60 * scalingFactor),
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            Icon(icon, size: 48 * scalingFactor, color: color),
            SizedBox(height: 12 * scalingFactor),
            Text(message, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14 * scalingFactor)),
          ],
        ),
      ),
    );
  }
}
