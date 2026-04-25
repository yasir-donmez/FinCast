import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/models/vault.dart';
import '../../../shared/widgets/precision_input.dart';
import '../../../shared/widgets/precision_button.dart';
import '../../auth/widgets/liquid_wave.dart';

class AddVaultSheet extends ConsumerStatefulWidget {
  const AddVaultSheet({super.key});

  @override
  ConsumerState<AddVaultSheet> createState() => _AddVaultSheetState();
}

class _AddVaultSheetState extends ConsumerState<AddVaultSheet> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
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
    _balanceController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.getPrimary(context);
    final secondaryColor = AppColors.getSecondary(context);
    final scalingFactor = (MediaQuery.of(context).size.height / 812.0).clamp(0.85, 1.0);

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 50 * scalingFactor,
                child: PrecisionInput(
                  controller: _nameController,
                  hintText: 'Kasa Adı (örn. Birikim)',
                  icon: Icons.drive_file_rename_outline_rounded,
                  autofocus: true,
                  scalingFactor: scalingFactor,
                ),
              ),
              SizedBox(height: 12 * scalingFactor),
              SizedBox(
                height: 50 * scalingFactor,
                child: PrecisionInput(
                  controller: _balanceController,
                  hintText: 'Başlangıç Bakiyesi',
                  icon: Icons.payments_rounded,
                  suffixText: '₺',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  scalingFactor: scalingFactor,
                ),
              ),
              SizedBox(height: 24 * scalingFactor),
              // NEW STANDARD BUTTON
              PrecisionButton(
                label: 'Kasa Oluştur',
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
                activeColor: activeColor,
                height: 64 * scalingFactor,
              ),
              SizedBox(height: 24 * scalingFactor),
            ],
          ),
        ),
      ],
    );
  }
}
