import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../vaults_providers.dart';

/// Grup kartı — üst üste binmiş kart görünümü
/// İçindeki işlemlerin ikonlarını mini olarak gösterir
class GroupCard extends StatefulWidget {
  final TransactionGroup group;
  final List<MockTransaction> transactions;
  final bool isEditMode;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GroupCard({
    super.key,
    required this.group,
    required this.transactions,
    this.isEditMode = false,
    this.onTap,
    this.onDelete,
  });

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    final duration = 300 + Random().nextInt(200);
    _shakeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    );
    _shakeAnimation = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    if (widget.isEditMode) {
      _shakeController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant GroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditMode && !oldWidget.isEditMode) {
      _shakeController.repeat(reverse: true);
    } else if (!widget.isEditMode && oldWidget.isEditMode) {
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
    final txList = widget.transactions;
    // İlk 4 işlemin ikonlarını göster
    final displayTx = txList.take(4).toList();

    Widget card = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.darkShadow,
              offset: Offset(4, 4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: AppColors.lightShadow,
              offset: Offset(-3, -3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mini ikon grid (2x2)
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  children: List.generate(4, (i) {
                    if (i < displayTx.length) {
                      return Container(
                        decoration: BoxDecoration(
                          color: displayTx[i].color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          displayTx[i].icon,
                          color: displayTx[i].color,
                          size: 18,
                        ),
                      );
                    }
                    // Boş alan
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.innerSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 6),
              // Grup adı
              Text(
                widget.group.name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Eleman sayısı
              Text(
                '${txList.length} işlem',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Edit modda sallanma + silme butonu
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
        ],
      );
    }

    return card;
  }
}
