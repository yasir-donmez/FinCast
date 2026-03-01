import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/neu_container.dart';

/// Analiz ekranı için yeni nesil yatay, şık ve animasyonlu "AI İçgörü / Bütçe Kısıntısı" kartı.
class AiInsightCard extends StatefulWidget {
  final String title;
  final double currentBudget;
  final double aiRecommendedBudget;
  final Color themeColor;

  const AiInsightCard({
    super.key,
    required this.title,
    required this.currentBudget,
    required this.aiRecommendedBudget,
    this.themeColor = AppColors.secondary,
  });

  @override
  State<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<AiInsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Çubuğun yumuşakça dolma süresi
    );

    double fillRatio = 1.0;
    if (widget.currentBudget > 0) {
      fillRatio = widget.aiRecommendedBudget / widget.currentBudget;
      if (fillRatio > 1.0) fillRatio = 1.0;
      if (fillRatio < 0.05) fillRatio = 0.05; // Tamamen boş kalmasın
    }

    // %100'den (Mevcut bütçe tam dolu) AI'ın dediği seviyeye çöken animasyon
    _progressAnimation = Tween<double>(begin: 1.0, end: fillRatio).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutExpo),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: NeuContainer(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        borderRadius: AppSizes.radiusLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Kısım: Başlık ve Değerler
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // İkon ve Başlık
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.themeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForCategory(widget.title),
                        color: widget.themeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.title.replaceAll(
                        '\n',
                        ' ',
                      ), // Satır atlamaları temizle
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // Hedef ve Şu anki
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Hedef: ₺${widget.aiRecommendedBudget.toInt()}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: widget.themeColor,
                        shadows: [
                          Shadow(
                            color: widget.themeColor.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "Şu an: ₺${widget.currentBudget.toInt()}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration
                            .lineThrough, // Çizik çekilmiş eski bütçe hissi
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // Alt Kısım: Yatay İlerleme / Daralma Çubuğu
            NeuContainer(
              height: 12,
              borderRadius: 6,
              isInnerShadow: true,
              padding: EdgeInsets.zero,
              child: Align(
                alignment: Alignment.centerLeft, // Soldan sağa dolum
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.themeColor,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: widget.themeColor,
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Başlığa göre mantıklı ikon döndüren yardımcı metod
  IconData _getIconForCategory(String title) {
    if (title.toLowerCase().contains("eğlence"))
      return Icons.movie_creation_rounded;
    if (title.toLowerCase().contains("kafe")) return Icons.local_cafe_rounded;
    if (title.toLowerCase().contains("giyim")) return Icons.checkroom_rounded;
    return Icons.category_rounded;
  }
}
