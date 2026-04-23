import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/database/models/vault.dart';
import '../../../../core/database/models/transaction_record.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/precision_card.dart';
import '../../../../shared/widgets/precision_clickable.dart';
import '../../../../shared/widgets/fluid_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../vaults_providers.dart';
import 'transaction_card.dart';

class TransactionDetailSheet extends ConsumerStatefulWidget {
  final TransactionUI transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onRemoveFromVault;
  final bool isInVault;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
    this.onRemoveFromVault,
    required this.isInVault,
  });

  @override
  ConsumerState<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends ConsumerState<TransactionDetailSheet> {
  List<Vault> _attachedVaults = [];
  TransactionRecord? _fullRecord;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final allVaults = await DatabaseService.getAllVaults();
    final ids = widget.transaction.groupIds.map((id) => int.tryParse(id.replaceFirst('v_', ''))).whereType<int>().toList();
    if (widget.transaction.dbId != null) {
      _fullRecord = await DatabaseService.getTransaction(widget.transaction.dbId!);
    }
    if (mounted) {
      setState(() {
        _attachedVaults = allVaults.where((v) => ids.contains(v.id)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final sf = (screenHeight / 812.0).clamp(0.75, 1.0);

    final hasFlexibleAmount = tx.minAmount != null && tx.maxAmount != null && tx.minAmount! > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. HEADER
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.5 + (0.5 * value),
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130 * sf, height: 130 * sf,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [tx.color.withValues(alpha: 0.2), tx.color.withValues(alpha: 0.0)],
                    ),
                  ),
                ),
                Container(
                  width: 90 * sf, height: 90 * sf,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(28 * sf),
                    border: Border.all(color: tx.color.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Icon(tx.icon, size: 40 * sf, color: tx.color),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // TUTAR
        Column(
          children: [
            if (hasFlexibleAmount) ...[
              Text(
                '₺${CurrencyUtils.formatAmount(tx.minAmount!)} — ₺${CurrencyUtils.formatAmount(tx.maxAmount!)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.withValues(alpha: 0.6), letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              '₺${CurrencyUtils.formatAmount(tx.amount)}',
              style: TextStyle(
                fontSize: 44 * sf,
                fontWeight: FontWeight.w900,
                color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context),
                letterSpacing: -2, height: 1,
              ),
            ),
            if (hasFlexibleAmount)
              Text('ortalama tutar'.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey.withValues(alpha: 0.4), letterSpacing: 1)),
          ],
        ),

        SizedBox(height: 24 * sf),

        // 2. BİLGİ KARTLARI
        PrecisionCard(
          scalingFactor: sf,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow(context, icon: Icons.calendar_today_rounded, label: 'Eklendi', value: _fullRecord != null ? DateFormat('dd MMMM yyyy').format(_fullRecord!.date) : '-', color: Colors.blue),
              const Divider(height: 24, thickness: 0.5),
              _buildInfoRow(context, icon: Icons.replay_rounded, label: l10n.period, value: _getDetailedPeriodLabel(tx.periodType, l10n), color: Colors.purple),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. KASALAR
        if (_attachedVaults.isNotEmpty) ...[
          Text(l10n.vaults.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.withValues(alpha: 0.5), letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ..._attachedVaults.map((vault) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: PrecisionCard(
              scalingFactor: sf,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.getPrimary(context).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.account_balance_wallet_rounded, size: 14, color: AppColors.getPrimary(context)),
                  ),
                  const SizedBox(width: 10),
                  Text(vault.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  PrecisionClickable(
                    onTap: () async {
                      final confirm = await showFluidDialog<bool>(
                        context: context,
                        accentColor: AppColors.error,
                        icon: const Icon(Icons.outbox_rounded),
                        title: const Text('Kasadan Çıkar'),
                        content: Text('Bu işlemi "${vault.name}" kasasından çıkarmak istediğinize emin misiniz?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel, style: TextStyle(color: AppColors.getTextSecondary(context)))),
                          FluidDialogButton(label: l10n.ok, onTap: () => Navigator.pop(context, true), color: AppColors.error),
                        ],
                      );
                      if (confirm == true) {
                        final record = await DatabaseService.getTransaction(tx.dbId!);
                        if (record != null) {
                          record.vaultIds = List<int>.from(record.vaultIds)..remove(vault.id);
                          await DatabaseService.updateTransaction(record);
                          HapticFeedback.heavyImpact();
                          _loadData();
                        }
                      }
                    },
                    color: AppColors.error.withValues(alpha: 0.1),
                    pressedColor: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    padding: const EdgeInsets.all(8),
                    scaleOnPress: 0.9,
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                  ),
                ],
              ),
            ),
          )),
        ],

        SizedBox(height: 32 * sf),

        // 4. AKSİYONLAR
        Row(
          children: [
            Expanded(
              child: PrecisionClickable(
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit();
                },
                color: Colors.transparent,
                pressedColor: AppColors.getPrimary(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.edit.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      color: AppColors.getPrimary(context), 
                      letterSpacing: 1.5, 
                      fontSize: 14
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            PrecisionClickable(
              onTap: () => widget.onDelete(),
              width: 56 * sf, height: 56 * sf,
              color: AppColors.error.withValues(alpha: 0.1),
              pressedColor: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20 * sf),
              scaleOnPress: 0.9,
              child: Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String label, required String value, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.getTextSecondary(context))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }

  String _getDetailedPeriodLabel(int period, AppLocalizations l10n) {
    String base = '';
    switch (period) {
      case 0: base = l10n.oneTime; break;
      case 1: base = "Her hafta"; break;
      case 2: base = "Her ay"; break;
      case 3: base = "Her yıl"; break;
      case 4: base = "2 haftada bir"; break;
      case 5: base = "3 haftada bir"; break;
      case 6: base = "3 ayda bir"; break;
      case 7: base = "6 ayda bir"; break;
      default: base = l10n.oneTime;
    }
    if (period != 0 && _fullRecord != null) {
      final daysPast = DateTime.now().difference(_fullRecord!.date).inDays;
      int count = 0;
      if (period == 1) count = (daysPast / 7).floor();
      else if (period == 2) count = (daysPast / 30).floor();
      else if (period == 3) count = (daysPast / 365).floor();
      if (count > 0) return "$base ($count. tekrar)";
    }
    return base;
  }
}
