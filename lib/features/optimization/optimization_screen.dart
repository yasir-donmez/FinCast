import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';
import 'widgets/neumorphic_circular_slider.dart';
import 'widgets/ai_insight_card.dart';

/// Hedef ve Optimizasyon (Yapay Zeka Karar Motoru Sonuçları) Ekranı
/// Premium Neumorphic Yeniden Tasarım
class OptimizationScreen extends StatefulWidget {
  const OptimizationScreen({super.key});

  @override
  State<OptimizationScreen> createState() => _OptimizationScreenState();
}

class _OptimizationScreenState extends State<OptimizationScreen>
    with SingleTickerProviderStateMixin {
  // Hedef Bakiye (Slider'dan güncellenecek)
  double _targetBalance = 50000.0;

  // AI Nefes Alma Animasyonu (Alt kısımdaki robot ikonu için)
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  // Şimdilik Mock Veriler (Aşama 5 Isar entegrasyonu tamamen bağlanınca DB'den gelecek)
  final List<Map<String, dynamic>> _mockAiRecommendations = [
    {
      'title': 'Eğlence & Dışarı',
      'current': 2000.0,
      'aiTarget': 1200.0,
      'color': AppColors.secondary,
    },
    {
      'title': 'Kafe & Kahve',
      'current': 800.0,
      'aiTarget': 350.0,
      'color': AppColors.primary,
    },
    {
      'title': 'Giyim & Alışveriş',
      'current': 1500.0,
      'aiTarget': 500.0,
      'color': Colors.orangeAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Nefes alma animasyonu (Yavaşça büyüyüp küçülme)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _breathingAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutSine,
      ),
    );
    _breathingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.paddingLarge),

          // 1. ÜST KISIM: Fütüristik Hedef Çarkı (Circular Dial)
          NeumorphicCircularSlider(
            minValue: 10000.0,
            maxValue: 500000.0, // 500 Bin TL'ye kadar çıkabilen devasa kadran
            initialValue: _targetBalance,
            onChanged: (newVal) {
              setState(() {
                _targetBalance = newVal;
                // İleride burada yapay zekaya "Yeni hedefe göre bütçeyi yeniden hesapla" denecek
              });
            },
          ),

          const SizedBox(height: AppSizes.paddingXLarge),

          // 2. ORTA KISIM: AI Koçu Tavsiyeleri (Şık Yatay Kartlar)
          const Padding(
            padding: EdgeInsets.only(left: AppSizes.paddingLarge),
            child: Text(
              "AI Koçu Tavsiyesi (Kilitlenmemiş Giderler)",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
              ),
              itemCount: _mockAiRecommendations.length,
              itemBuilder: (context, index) {
                final item = _mockAiRecommendations[index];
                return AiInsightCard(
                  title: item['title'] as String,
                  currentBudget: item['current'] as double,
                  aiRecommendedBudget: item['aiTarget'] as double,
                  themeColor: item['color'] as Color,
                );
              },
            ),
          ),

          // 3. ALT KISIM: Canlı (Nefes Alan) AI Asistan Mesajı
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingMedium,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(
                  alpha: 0.8,
                ), // Glassmorphic (Yarı saydam yüzey)
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.darkShadow,
                    blurRadius: 10,
                    offset: Offset(4, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Animasyonlu Nefes Alan İkon
                  ScaleTransition(
                    scale: _breathingAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: AppColors.secondary,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),

                  // Mesaj
                  const Expanded(
                    child: Text(
                      "Hedefe ulaşmak için Eğlence ve Giyim esnek bütçelerini yukarıdaki önerilere çekmelisin. (Kilitli Giderleriniz: ₺12.500)",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 50), // BottomNav payı
        ],
      ),
    );
  }
}
