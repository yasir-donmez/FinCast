import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/neu_container.dart';
import '../vaults_providers.dart';

/// Tek bir işlem kartı — grid'de gösterilir
/// Edit modda sallanma animasyonu + silme butonu gösterir
class TransactionCard extends StatefulWidget {
  final MockTransaction transaction;
  final bool isEditMode;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.isEditMode = false,
    this.onDelete,
    this.onEdit,
    this.onTap,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    // Her karta rastgele süre vererek doğal görünüm sağla
    final duration = 300 + Random().nextInt(200); // 300-500ms arası
    _shakeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    );
    _shakeAnimation = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    // İlk oluşturulduğunda edit modundaysa başlat
    if (widget.isEditMode) {
      _shakeController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TransactionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditMode && !oldWidget.isEditMode) {
      // Edit modu açıldı → başlat
      _shakeController.repeat(reverse: true);
    } else if (!widget.isEditMode && oldWidget.isEditMode) {
      // Edit modu kapandı → durdur
      _shakeController.stop();
      _shakeController.reset();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;

    Widget card = GestureDetector(
      onTap: widget.onTap,
      child: NeuContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: AppSizes.radiusDefault,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tx.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(tx.icon, color: tx.color, size: 24),
            ),
            const SizedBox(height: 8),
            // İsim
            Text(
              tx.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            // Tutar
            Text(
              tx.minAmount != null && tx.maxAmount != null
                  ? '${tx.isIncome ? '+' : '-'}₺${tx.minAmount!.toStringAsFixed(0)} - ₺${tx.maxAmount!.toStringAsFixed(0)}'
                  : '${tx.isIncome ? '+' : '-'}₺${tx.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: tx.isIncome ? Colors.green : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );

    // Edit modda sallanma + silme butonu ekle
    if (widget.isEditMode) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox.expand(
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _shakeAnimation.value,
                  child: child,
                );
              },
              child: card,
            ),
          ),
          // Silme butonu (sol üst köşe)
          Positioned(
            top: -6,
            left: -6,
            child: GestureDetector(
              onTap: widget.onDelete,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Düzenleme butonu (sağ üst köşe)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: widget.onEdit,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return card;
  }
}
