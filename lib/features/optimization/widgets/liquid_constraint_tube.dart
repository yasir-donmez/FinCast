import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/neu_container.dart';

/// Kullanıcının esnek bütçelerini kısması gerektiğini anlatan
/// "Cam Test Tüpü ve Renkli Sıvı" Animasyonlu Gösterge Widget'ı
class LiquidConstraintTube extends StatefulWidget {
  final String title;
  final double currentBudget;
  final double aiRecommendedBudget;
  final Color liquidColor;

  const LiquidConstraintTube({
    super.key,
    required this.title,
    required this.currentBudget,
    required this.aiRecommendedBudget,
    this.liquidColor = AppColors.secondary,
  });

  @override
  State<LiquidConstraintTube> createState() => _LiquidConstraintTubeState();
}

class _LiquidConstraintTubeState extends State<LiquidConstraintTube>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fluidAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 2,
      ), // Fokurtu hissi için eklenecek uzunluk
    );

    // AI'ın tavsiye ettiği değer, şu anki bütçenin yüzde kaçı?
    double targetFillRatio = 1.0;
    if (widget.currentBudget > 0) {
      targetFillRatio = widget.aiRecommendedBudget / widget.currentBudget;
      if (targetFillRatio > 1.0) {
        targetFillRatio = 1.0;
      }
      if (targetFillRatio < 0.0) {
        targetFillRatio = 0.05;
      } // Tamamen bos gorunmesin alt sınır
    }

    // Tüp başlangıçta %100 dolu (Eski bütçe kotalı), sonra AI'ın dediği seviyeye çökecek (Tasarruf)
    _fluidAnimation = Tween<double>(begin: 1.0, end: targetFillRatio).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutBack),
    );

    // Ekrana girer girmez animasyonu çalıştır
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Yazı Kısmı (Tüpün Üstü - AI kısıntısı sonucu önerilen rakam)
          AnimatedBuilder(
            animation: _fluidAnimation,
            builder: (context, child) {
              double currentVal = widget.currentBudget * _fluidAnimation.value;
              return Text(
                "₺${currentVal.toInt()}",
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Şeffaf Neumorphic Tüp İçindeki Sıvı
          NeuContainer(
            width: 50,
            height: 200, // Tüp Boyu
            borderRadius: 25,
            padding: EdgeInsets.zero,
            isInnerShadow: true, // İçi oyuk (Cam tüp) hissi
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: _fluidAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    heightFactor:
                        _fluidAnimation.value, // Doluluk oranı animasyonlu
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.liquidColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(
                          20,
                        ), // Sıvı bombeli dursun
                        boxShadow: [
                          BoxShadow(
                            color: widget.liquidColor, // Neon sıvı parlaması
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Kategori Adı
          Text(
            widget.title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
