import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/models/vault.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../shared/widgets/fluid_container.dart';
import '../../../shared/widgets/fluid_button.dart';
import '../../../shared/widgets/fluid_sheet.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/providers/db_providers.dart'; // Eksik import eklendi
import '../../../features/subscription/widgets/pro_upgrade_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../vaults_providers.dart';

class VaultManagementSheet extends ConsumerWidget {
  const VaultManagementSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vaults = ref.watch(allVaultsProvider);
    final activeColor = AppColors.getPrimary(context); // rotaryColorProvider yerine standart primary
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.vaultsAndGroups, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    Text('Kasalarınızı yönetin.', style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(context))),
                  ],
                ),
              ),
              _AddVaultButton(vaultsCount: vaults.length, activeColor: activeColor),
            ],
          ),
          const SizedBox(height: 32),

          if (vaults.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vaults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildManagementItem(context: context, vault: vaults[index], activeColor: activeColor);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildManagementItem({required BuildContext context, required Vault vault, required Color activeColor}) {
    return FluidContainer(
      padding: const EdgeInsets.all(16),
      isGlass: true,
      borderRadius: 24,
      color: activeColor.withValues(alpha: 0.03),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(IconUtils.getIcon(vault.iconCode ?? vault.name), color: activeColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vault.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5)),
                Text(vault.currency, style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(context).withValues(alpha: 0.6))),
              ],
            ),
          ),
          Switch(
            value: vault.showOnDashboard,
            activeColor: activeColor,
            onChanged: (val) async {
              vault.showOnDashboard = val;
              await DatabaseService.updateVault(vault);
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _confirmDelete(context, vault),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.getError(context).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.delete_outline_rounded, color: AppColors.getError(context), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Vault vault) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Kasa Silinsin mi?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('${vault.name} kasası silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sil', style: TextStyle(color: AppColors.getError(context), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteVault(vault.id);
    }
  }
}

class _AddVaultButton extends ConsumerWidget {
  final int vaultsCount;
  final Color activeColor;
  const _AddVaultButton({required this.vaultsCount, required this.activeColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionServiceProvider);
    
    return GestureDetector(
      onTap: () {
        if (vaultsCount >= subscription.maxVaults) {
          ProUpgradeSheet.show(context);
        } else {
          _showAddVaultSheet(context, activeColor);
        }
      },
      child: FluidContainer(
        width: 48, height: 48,
        padding: EdgeInsets.zero,
        borderRadius: 16,
        color: activeColor.withValues(alpha: 0.1),
        child: Icon(Icons.add_rounded, color: activeColor),
      ),
    );
  }

  void _showAddVaultSheet(BuildContext context, Color activeColor) {
    final nameController = TextEditingController();
    FluidSheet.show(
      context: context,
      title: 'Yeni Kasa Oluştur',
      child: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Kasa Adı'),
          ),
          const SizedBox(height: 32),
          FluidButton(
            onTap: () async {
              if (nameController.text.isNotEmpty) {
                final newVault = Vault()..name = nameController.text..currency = 'TRY'..showOnDashboard = true;
                await DatabaseService.addVault(newVault);
                if (context.mounted) Navigator.pop(context);
              }
            },
            width: double.infinity,
            color: activeColor,
            child: const Text('Kasa Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
