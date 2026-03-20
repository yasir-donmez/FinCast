import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/services/subscription_service.dart';
import '../../../shared/widgets/fluid_button.dart';
import '../../../shared/widgets/fluid_sheet.dart';
import '../../auth/widgets/liquid_background.dart';

/// FinCast "Pro Üyelik" (Paywall) Sayfası.
/// Kullanıcıyı premium özelliklere teşvik eden, akışkan tasarımlı alt sayfa.
class ProUpgradeSheet extends ConsumerWidget {
  const ProUpgradeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return FluidSheet.show(
      context: context,
      child: const ProUpgradeSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = AppColors.getPrimary(context);
    final secondaryColor = AppColors.secondary;

    return LiquidBackground(
      useSystemBackground: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Başlık ve İkon
              _buildHeader(primaryColor),
              const SizedBox(height: 32),
              
              // Özellik Listesi
              _buildFeatureItem(
                context,
                Icons.auto_awesome_rounded,
                'Günde 3 AI Analizi',
                'Finansal verileriniz için her gün 3 derin analiz ve tahminleme hakkı.',
                primaryColor,
              ),
              _buildFeatureItem(
                context,
                Icons.account_balance_wallet_rounded,
                'Sınırsız Kasa & Tema',
                'Dilediğiniz kadar kasa oluşturun ve özel renklerle özelleştirin.',
                secondaryColor,
              ),
              _buildFeatureItem(
                context,
                Icons.block_rounded,
                'Reklamsız Deneyim',
                'Uygulamayı hiçbir reklam kesintisi olmadan, akışkan bir şekilde kullanın.',
                Colors.amber,
              ),
              _buildFeatureItem(
                context,
                Icons.verified_user_rounded,
                'Öncelikli Destek',
                'Yeni özelliklere herkesten önce erişin ve öncelikli destek alın.',
                Colors.cyan,
              ),
              
              const SizedBox(height: 48),
              
              // Abonelik Seçenekleri (Örnek)
              _buildSubscriptionOption(
                context,
                'Yıllık Plan',
                '₺199.99 / yıl',
                '1 Ay Ücretsiz Dene',
                ref,
                true,
              ),
              const SizedBox(height: 16),
              _buildSubscriptionOption(
                context,
                'Aylık Plan',
                '₺24.99 / ay',
                null,
                ref,
                false,
              ),
              
              const SizedBox(height: 32),
              Text(
                'İstediğiniz zaman iptal edebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getTextSecondary(context).withValues(alpha: 0.3),
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0.5, 0.5), blurRadius: 0.5),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: Icon(
              Icons.rocket_launch_rounded, 
              size: 40, 
              color: primaryColor.withValues(alpha: 0.65), 
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ✍️ KAZINMIŞ METİN (Etched Text)
        Text(
          'FinCast Pro\'ya Geçin',
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.w900, 
            letterSpacing: -1,
            color: Colors.white.withValues(alpha: 0.8),
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.5), offset: const Offset(1, 1), blurRadius: 1),
              Shadow(color: Colors.white.withValues(alpha: 0.1), offset: const Offset(-0.5, -0.5), blurRadius: 1),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Finansal potansiyelinizi %100 açığa çıkarın.',
          style: TextStyle(
            fontSize: 14, 
            color: Colors.grey.withValues(alpha: 0.6),
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0.5, 0.5), blurRadius: 0.5),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🛠️ KAZINMIŞ KÜÇÜK İKON (Etched Mini Icon)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
            ),
            child: Icon(icon, size: 20, color: color.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.85),
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(0.8, 0.8), blurRadius: 0.5),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getTextSecondary(context).withValues(alpha: 0.5),
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0.5, 0.5), blurRadius: 0.5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOption(
    BuildContext context, 
    String title, 
    String price, 
    String? badge,
    WidgetRef ref,
    bool isPopular,
  ) {
    return FluidButton(
      onTap: () async {
        // Satın alım taklidi (Mock Purchase)
        final service = ref.read(subscriptionServiceProvider);
        await service.setProStatus(true);
        if (context.mounted) Navigator.pop(context);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      price, 
                      style: TextStyle(
                        fontSize: 12, 
                        color: AppColors.getTextSecondary(context).withValues(alpha: 0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            ],
          ),
          if (badge != null)
            Positioned(
              top: -24,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10)],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
