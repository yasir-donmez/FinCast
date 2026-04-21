import 'package:flutter/material.dart';
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
              if (!_isAdding) _buildPremiumTabSelector(activeColor, isDark),
              
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
                  ? _buildAddVaultView(context, activeColor, isDark)
                  : (_activeTab == ManagementTab.vaults 
                      ? _buildVaultListView(context, vaults, activeColor, isDark)
                      : _buildTransactionListView(context, standaloneTransactions, activeColor, isDark)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTabSelector(Color activeColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          // Hareketli Arka Plan (Indicator)
          AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutBack,
            alignment: _activeTab == ManagementTab.vaults ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width / 2 - 20,
              height: 42,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
                        fontSize: 14,
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
                        fontSize: 14,
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

  Widget _buildVaultListView(BuildContext context, List<Vault> vaults, Color activeColor, bool isDark) {
    return Column(
      key: const ValueKey('vault_list'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (vaults.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: vaults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildVaultItem(context, vaults[index], activeColor, isDark),
            ),
          )
        else
          _buildEmptyState('Henüz bir kasa bulunmuyor.', Icons.account_balance_wallet_outlined, activeColor),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTransactionListView(BuildContext context, List<TransactionUI> txs, Color activeColor, bool isDark) {
    return Column(
      key: const ValueKey('tx_list'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (txs.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: txs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildTransactionItem(context, txs[index], activeColor, isDark),
            ),
          )
        else
          _buildEmptyState('Tekil işlem bulunamadı.', Icons.receipt_long_rounded, activeColor),
        const SizedBox(height: 12),
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

  Widget _buildVaultItem(BuildContext context, Vault vault, Color activeColor, bool isDark) {
    return FluidContainer(
      padding: const EdgeInsets.all(12),
      isGlass: true,
      borderRadius: 24,
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(IconUtils.getIcon(vault.iconCode ?? vault.name), color: activeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vault.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5)),
                Text(vault.currency, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.withValues(alpha: 0.6))),
              ],
            ),
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
              },
            ),
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

  Widget _buildTransactionItem(BuildContext context, TransactionUI tx, Color activeColor, bool isDark) {
    return FluidContainer(
      padding: const EdgeInsets.all(12),
      isGlass: true,
      borderRadius: 24,
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: tx.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(tx.icon, color: tx.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.5)),
                Text('₺${CurrencyUtils.formatAmount(tx.amount)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context))),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: tx.showOnDashboard,
              activeThumbColor: activeColor,
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
          ),
        ],
      ),
    );
  }

  Widget _buildAddVaultView(BuildContext context, Color activeColor, bool isDark) {
    return Column(
      key: const ValueKey('add_view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        FluidContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          borderRadius: 24,
          isGlass: true,
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
          child: TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            decoration: InputDecoration(
              icon: Icon(Icons.drive_file_rename_outline_rounded, color: activeColor.withValues(alpha: 0.5), size: 22),
              hintText: 'Kasa Adı (örn. Birikim)',
              hintStyle: TextStyle(fontWeight: FontWeight.w500, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2), fontSize: 15),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16), // Boşluk eklendi
        FluidContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          borderRadius: 24,
          isGlass: true,
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
          child: TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            decoration: InputDecoration(
              icon: Icon(Icons.payments_rounded, color: activeColor.withValues(alpha: 0.5), size: 22),
              hintText: 'Başlangıç Bakiyesi',
              suffixText: '₺',
              suffixStyle: TextStyle(fontWeight: FontWeight.w900, color: activeColor),
              hintStyle: TextStyle(fontWeight: FontWeight.w500, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2), fontSize: 15),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 32),
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Kasa Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
