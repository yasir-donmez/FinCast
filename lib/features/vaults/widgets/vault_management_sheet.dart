import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/models/vault.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../shared/widgets/fluid_container.dart';
import '../../../shared/widgets/fluid_button.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/providers/db_providers.dart';
import '../../../features/subscription/widgets/pro_upgrade_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/widgets/liquid_wave.dart';

class VaultManagementSheet extends ConsumerStatefulWidget {
  const VaultManagementSheet({super.key});

  @override
  ConsumerState<VaultManagementSheet> createState() => _VaultManagementSheetState();
}

class _VaultManagementSheetState extends ConsumerState<VaultManagementSheet> with SingleTickerProviderStateMixin {
  bool _isAdding = false;
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _toggleView() {
    HapticFeedback.mediumImpact();
    // Dalga animasyonunu tetikle
    _waveController.forward(from: 0.0);
    
    // Yarısında (dalga tam kaplamışken) içeriği değiştir
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isAdding = !_isAdding);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vaults = ref.watch(allVaultsProvider);
    final activeColor = AppColors.getPrimary(context);
    final secondaryColor = AppColors.getSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Stack(
      children: [
        // Pembe Dalga Efekti (Liquid Wave)
        Positioned.fill(
          child: IgnorePointer(
            child: LiquidWave(
              controller: _waveController,
              color: secondaryColor, // Pembe/İkincil renk
              isTriggered: true,
            ),
          ),
        ),

        // Klavye ile birlikte yükselen içerik
        Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (Widget child, Animation<double> animation) {
              final isAddingView = child.key == const ValueKey('add_view');
              // Görünüm değişimine göre farklı kayma yönleri
              final beginOffset = isAddingView ? const Offset(0.2, 0) : const Offset(-0.2, 0);
              
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
                  ),
                  child: child,
                ),
              );
            },
            child: _isAdding 
              ? _buildAddVaultView(context, activeColor, isDark)
              : _buildListView(context, vaults, activeColor, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildListView(BuildContext context, List<Vault> vaults, Color activeColor, bool isDark) {
    return Column(
      key: ValueKey('list_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (vaults.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: vaults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildManagementItem(
                  context: context, 
                  vault: vaults[index], 
                  activeColor: activeColor,
                  isDark: isDark,
                );
              },
            ),
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 48, color: activeColor),
                    const SizedBox(height: 12),
                    const Text('Henüz bir kasa bulunmuyor.', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        
        const SizedBox(height: 24),
        
        FluidButton(
          onTap: () {
            final subscription = ref.read(subscriptionServiceProvider);
            if (vaults.length >= subscription.maxVaults) {
              ProUpgradeSheet.show(context);
            } else {
              _toggleView();
            }
          },
          width: double.infinity,
          color: activeColor.withValues(alpha: 0.1),
          isSecondary: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: activeColor),
              const SizedBox(width: 8),
              Text(
                'Yeni Kasa Ekle', 
                style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddVaultView(BuildContext context, Color activeColor, bool isDark) {
    return Column(
      key: ValueKey('add_view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        FluidContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          borderRadius: 20,
          isGlass: true,
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          child: TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'Kasa Adı (örn. Birikim, Tatil)',
              hintStyle: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: FluidButton(
                onTap: _toggleView,
                color: Colors.grey.withValues(alpha: 0.1),
                isSecondary: true,
                child: const Text('İptal', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FluidButton(
                onTap: () async {
                  if (_nameController.text.isNotEmpty) {
                    final newVault = Vault()
                      ..name = _nameController.text
                      ..currency = 'TRY'
                      ..showOnDashboard = true;
                    await DatabaseService.addVault(newVault);
                    _nameController.clear();
                    _toggleView();
                  }
                },
                color: activeColor,
                child: const Text(
                  'Kasa Oluştur', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildManagementItem({
    required BuildContext context, 
    required Vault vault, 
    required Color activeColor,
    required bool isDark,
  }) {
    return FluidContainer(
      padding: const EdgeInsets.all(16),
      isGlass: true,
      borderRadius: 28,
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(18)
            ),
            child: Icon(
              IconUtils.getIcon(vault.iconCode ?? vault.name), 
              color: activeColor, 
              size: 24
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vault.name, 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5)
                ),
                Text(
                  vault.currency, 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextSecondary(context).withValues(alpha: 0.6)
                  )
                ),
              ],
            ),
          ),
          Switch(
            value: vault.showOnDashboard,
            activeThumbColor: activeColor,
            onChanged: (val) async {
              vault.showOnDashboard = val;
              await DatabaseService.updateVault(vault);
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _confirmDelete(context, vault),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.getError(context).withValues(alpha: 0.1), 
                shape: BoxShape.circle
              ),
              child: Icon(Icons.delete_outline_rounded, color: AppColors.getError(context), size: 20),
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
        content: Text('${vault.name} kasası ve içindeki tüm işlemler silinecek.'),
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
