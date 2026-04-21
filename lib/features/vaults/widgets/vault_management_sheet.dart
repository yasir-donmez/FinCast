import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/models/vault.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/fluid_container.dart';
import '../../../shared/widgets/fluid_button.dart';
import '../../../shared/widgets/fluid_dialog.dart';
import '../../../core/providers/db_providers.dart';
import '../vaults_providers.dart';
import '../../auth/widgets/liquid_wave.dart';
import '../../../shared/widgets/fluid_switch.dart';

enum ManagementTab { vaults, transactions }

class VaultManagementSheet extends ConsumerStatefulWidget {
  final bool startInAddMode;
  const VaultManagementSheet({super.key, this.startInAddMode = false});

  @override
  ConsumerState<VaultManagementSheet> createState() => _VaultManagementSheetState();
}

class _VaultManagementSheetState extends ConsumerState<VaultManagementSheet> with TickerProviderStateMixin {
  late bool _isAdding;
  ManagementTab _activeTab = ManagementTab.vaults;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _isAdding = widget.startInAddMode;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _switchTab(ManagementTab tab) {
    if (_activeTab == tab) return;
    HapticFeedback.mediumImpact();
    setState(() => _activeTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final vaults = ref.watch(allVaultsProvider);
    final transactions = ref.watch(vaultTransactionsProvider);
    final standaloneTransactions = transactions.where((t) => t.groupIds.isEmpty).toList();
    
    final activeColor = AppColors.getPrimary(context);
    final secondaryColor = AppColors.getSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final scalingFactor = (screenHeight / 812.0).clamp(0.85, 1.0);
    
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: LiquidWave(
              controller: _waveController,
              color: secondaryColor,
              isTriggered: true,
            ),
          ),
        ),

        // AnimatedSize sayesinde içerik değiştikçe sheet yumuşakça boy değiştirir
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isAdding) _buildPremiumTabSelector(activeColor, isDark, scalingFactor),
              
              const SizedBox(height: 12),

              AnimatedSwitcher(
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
                child: _isAdding 
                  ? _buildAddVaultView(context, activeColor, isDark, scalingFactor)
                  : (_activeTab == ManagementTab.vaults 
                      ? _buildVaultListView(context, vaults, activeColor, isDark, scalingFactor)
                      : _buildTransactionListView(context, standaloneTransactions, activeColor, isDark, scalingFactor)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTabSelector(Color activeColor, bool isDark, double scalingFactor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8 * scalingFactor),
      height: 50 * scalingFactor,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(25 * scalingFactor),
      ),
      child: Stack(
        children: [
          // Hareketli Arka Plan (Indicator)
          AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutBack,
            alignment: _activeTab == ManagementTab.vaults ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: math.max(0, MediaQuery.of(context).size.width / 2 - 20),
              height: 42 * scalingFactor,
              margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4 * scalingFactor),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(21 * scalingFactor),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4 * scalingFactor),
                  )
                ],
              ),
            ),
          ),
          // Tab Yazıları
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _switchTab(ManagementTab.vaults),
                  child: Center(
                    child: Text(
                      'Kasalar',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14 * scalingFactor,
                        color: _activeTab == ManagementTab.vaults ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _switchTab(ManagementTab.transactions),
                  child: Center(
                    child: Text(
                      'İşlemler',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14 * scalingFactor,
                        color: _activeTab == ManagementTab.transactions ? Colors.white : Colors.grey,
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

  Widget _buildVaultListView(BuildContext context, List<Vault> vaults, Color activeColor, bool isDark, double scalingFactor) {
    return Column(
      key: const ValueKey('vault_list'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (vaults.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45 * scalingFactor),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8 * scalingFactor),
              physics: const BouncingScrollPhysics(),
              itemCount: vaults.length,
              separatorBuilder: (_, __) => SizedBox(height: 10 * scalingFactor),
              itemBuilder: (context, index) => _buildVaultItem(context, vaults[index], activeColor, isDark, scalingFactor),
            ),
          )
        else
          _buildEmptyState('Henüz bir kasa bulunmuyor.', Icons.account_balance_wallet_outlined, activeColor, scalingFactor),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTransactionListView(BuildContext context, List<TransactionUI> txs, Color activeColor, bool isDark, double scalingFactor) {
    return Column(
      key: const ValueKey('tx_list'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (txs.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45 * scalingFactor),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8 * scalingFactor),
              physics: const BouncingScrollPhysics(),
              itemCount: txs.length,
              separatorBuilder: (_, __) => SizedBox(height: 10 * scalingFactor),
              itemBuilder: (context, index) => _buildTransactionItem(context, txs[index], activeColor, isDark, scalingFactor),
            ),
          )
        else
          _buildEmptyState('Tekil işlem bulunamadı.', Icons.receipt_long_rounded, activeColor, scalingFactor),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon, Color color, double scalingFactor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60 * scalingFactor),
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            Icon(icon, size: 48 * scalingFactor, color: color),
            SizedBox(height: 12 * scalingFactor),
            Text(message, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13 * scalingFactor)),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultItem(BuildContext context, Vault vault, Color activeColor, bool isDark, double scalingFactor) {
    return FluidContainer(
      padding: EdgeInsets.all(12 * scalingFactor),
      isGlass: true,
      borderRadius: 24 * scalingFactor,
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10 * scalingFactor),
            decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16 * scalingFactor)),
            child: Icon(IconUtils.getIcon(vault.iconCode ?? vault.name), color: activeColor, size: 22 * scalingFactor),
          ),
          SizedBox(width: 12 * scalingFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vault.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16 * scalingFactor, letterSpacing: -0.5)),
                Text(vault.currency, style: TextStyle(fontSize: 11 * scalingFactor, fontWeight: FontWeight.w600, color: Colors.grey.withValues(alpha: 0.6))),
              ],
            ),
          ),
          FluidSwitch(
            value: vault.showOnDashboard,
            activeColor: activeColor,
            activeIcon: Icons.visibility_rounded,
            inactiveIcon: Icons.visibility_off_rounded,
            scalingFactor: scalingFactor,
            onChanged: (val) async {
              vault.showOnDashboard = val;
              await DatabaseService.updateVault(vault);
              HapticFeedback.lightImpact();
            },
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _confirmDeleteVault(context, vault),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.getError(context).withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.delete_outline_rounded, color: AppColors.getError(context), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionUI tx, Color activeColor, bool isDark, double scalingFactor) {
    return FluidContainer(
      padding: EdgeInsets.all(12 * scalingFactor),
      isGlass: true,
      borderRadius: 24 * scalingFactor,
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10 * scalingFactor),
            decoration: BoxDecoration(color: tx.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16 * scalingFactor)),
            child: Icon(tx.icon, color: tx.color, size: 22 * scalingFactor),
          ),
          SizedBox(width: 12 * scalingFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15 * scalingFactor, letterSpacing: -0.5)),
                Text('₺${CurrencyUtils.formatAmount(tx.amount)}', style: TextStyle(fontSize: 12 * scalingFactor, fontWeight: FontWeight.w800, color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context))),
              ],
            ),
          ),
          FluidSwitch(
            value: tx.showOnDashboard,
            activeColor: activeColor,
            activeIcon: Icons.visibility_rounded,
            inactiveIcon: Icons.visibility_off_rounded,
            scalingFactor: scalingFactor,
            onChanged: (val) async {
              if (tx.dbId == null) return;
              final record = await DatabaseService.getTransaction(tx.dbId!);
              if (record != null) {
                record.showOnDashboard = val;
                await DatabaseService.updateTransaction(record);
                HapticFeedback.lightImpact();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddVaultView(BuildContext context, Color activeColor, bool isDark, double scalingFactor) {
    return Column(
      key: const ValueKey('add_view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 12 * scalingFactor),
        FluidContainer(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4 * scalingFactor),
          borderRadius: 24 * scalingFactor,
          isGlass: true,
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
          child: TextField(
            controller: _nameController,
            autofocus: true,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17 * scalingFactor),
            decoration: InputDecoration(
              icon: Icon(Icons.drive_file_rename_outline_rounded, color: activeColor.withValues(alpha: 0.5), size: 22 * scalingFactor),
              hintText: 'Kasa Adı (örn. Birikim)',
              hintStyle: TextStyle(fontWeight: FontWeight.w500, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2), fontSize: 15 * scalingFactor),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 16 * scalingFactor),
        FluidContainer(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4 * scalingFactor),
          borderRadius: 24 * scalingFactor,
          isGlass: true,
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
          child: TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17 * scalingFactor),
            decoration: InputDecoration(
              icon: Icon(Icons.payments_rounded, color: activeColor.withValues(alpha: 0.5), size: 22 * scalingFactor),
              hintText: 'Başlangıç Bakiyesi',
              suffixText: '₺',
              suffixStyle: TextStyle(fontWeight: FontWeight.w900, color: activeColor, fontSize: 15 * scalingFactor),
              hintStyle: TextStyle(fontWeight: FontWeight.w500, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2), fontSize: 15 * scalingFactor),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 32 * scalingFactor),
        FluidButton(
          onTap: () async {
            if (_nameController.text.isNotEmpty) {
              final double? initialBalance = double.tryParse(_balanceController.text.replaceAll(',', '.'));
              
              final newVault = Vault()
                ..name = _nameController.text
                ..currency = 'TRY'
                ..balance = initialBalance ?? 0.0
                ..showOnDashboard = true;
              
              await DatabaseService.addVault(newVault);
              _nameController.clear();
              _balanceController.clear();
              if (context.mounted) Navigator.pop(context);
            }
          },
          color: activeColor,
          width: double.infinity,
          height: 60 * scalingFactor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_task_rounded, color: Colors.white, size: 20 * scalingFactor),
              SizedBox(width: 8 * scalingFactor),
              Text('Kasa Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15 * scalingFactor)),
            ],
          ),
        ),
        SizedBox(height: 24 * scalingFactor),
      ],
    );
  }

  void _confirmDeleteVault(BuildContext context, Vault vault) async {
    final confirm = await showFluidDialog<bool>(
      context: context,
      accentColor: AppColors.error,
      icon: const Icon(Icons.account_balance_wallet_rounded),
      title: const Text('Kasa Silinsin mi?'),
      content: Text('${vault.name} kasası ve içindeki tüm işlemler silinecek.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), 
          child: Text('İptal', style: TextStyle(color: AppColors.getTextSecondary(context))),
        ),
        _FluidDialogButton(
          label: 'Sil',
          onTap: () => Navigator.pop(context, true),
          color: AppColors.error,
        ),
      ],
    );
    if (confirm == true) await DatabaseService.deleteVault(vault.id);
  }
}

class _FluidDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _FluidDialogButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FluidContainer(
        padding: const EdgeInsets.symmetric(vertical: 12),
        borderRadius: 16,
        color: color.withValues(alpha: 0.15),
        borderWidth: 1.5,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
