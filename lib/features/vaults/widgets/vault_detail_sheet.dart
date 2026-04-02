import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/models/vault.dart';
import '../../../core/providers/db_providers.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/fluid_container.dart';
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTabSelector(activeColor, isDark),
        const SizedBox(height: 12),
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

  Widget _buildTabSelector(Color activeColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutBack,
            alignment: _activeTab == VaultDetailTab.transactions ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: (MediaQuery.of(context).size.width - 64) / 2,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
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
                        fontSize: 13,
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
                        fontSize: 13,
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
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
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
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.edit_rounded, size: 16, color: activeColor.withValues(alpha: 0.5)),
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
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: vault.showOnDashboard, 
                    activeThumbColor: activeColor,
                    onChanged: (val) async {
                      vault.showOnDashboard = val;
                      await DatabaseService.updateVault(vault);
                      HapticFeedback.lightImpact();
                    }
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 24),

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
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
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
                          borderRadius: BorderRadius.circular(14)
                        ),
                        child: Icon(tx.icon, color: tx.color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2)),
                            Text(
                              '₺${CurrencyUtils.formatAmount(tx.amount)}', 
                              style: TextStyle(
                                color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context), 
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
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
    return Column(
      key: const ValueKey('selection_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'İŞLEM SEÇİMİ', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)
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
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
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
                  padding: const EdgeInsets.all(12),
                  borderRadius: 24,
                  isGlass: true,
                  color: isSelected ? activeColor.withValues(alpha: 0.08) : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01)),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: tx.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(tx.icon, color: tx.color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2)),
                            Text('₺${CurrencyUtils.formatAmount(tx.amount)}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: isSelected, 
                          activeThumbColor: activeColor,
                          onChanged: (val) async {
                            final helper = ref.read(transactionGroupingProvider);
                            await helper.toggleVault(tx.id, widget.vaultId);
                            HapticFeedback.selectionClick();
                          }
                        ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
