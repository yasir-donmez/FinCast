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
              
              // Özellik Listesi (Daha toplu)
              Column(
                children: [
                  _buildFeatureItem(context, Icons.auto_awesome_rounded, 'AI Analizleri', 'Günlük 3 derin finansal analiz ve tahmin.', primaryColor),
                  _buildFeatureItem(context, Icons.account_balance_wallet_rounded, 'Sınırsız Kasa', 'Dilediğiniz kadar kasa ve özel renkler.', secondaryColor),
                  _buildFeatureItem(context, Icons.block_rounded, 'Sıfır Reklam', 'Kesintisiz ve akışkan deneyim.', Colors.amber),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // 📑 PLAN SEÇİM ALANI (Plan Selection)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLANLAR',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.2,
                      color: AppColors.getTextSecondary(context).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // MEVCUT PLAN (Current Plan)
                  _buildCurrentPlanCard(context),
                  const SizedBox(height: 12),
                  
                  // PRO SEÇENEKLERİ (Upgrade Options)
                  _buildSubscriptionOption(
                    context: context,
                    title: 'Yıllık Pro',
                    price: '₺199.99 / yıl',
                    subtitle: 'Aylık ₺16.66\'ya gelir',
                    badge: 'EN AVANTAJLI',
                    savings: '%33 TASARRUF',
                    ref: ref,
                    isPopular: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSubscriptionOption(
                    context: context,
                    title: 'Aylık Pro',
                    price: '₺24.99 / ay',
                    subtitle: 'İstediğin zaman iptal et',
                    ref: ref,
                    isPopular: false,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              Text(
                'Tüm planlar 7 gün ücretsiz deneme içerir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.getTextSecondary(context).withValues(alpha: 0.3),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
            ),
            child: Icon(icon, size: 20, color: color.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getTextSecondary(context).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCurrentPlanCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 20, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ücretsiz Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  'Temel özellikler ile sınırlı kullanım.', 
                  style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(context).withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('MEVCUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOption({
    required BuildContext context, 
    required String title, 
    required String price, 
    required String subtitle,
    required WidgetRef ref,
    bool isPopular = false,
    String? badge,
    String? savings,
  }) {
    final primaryColor = AppColors.getPrimary(context);
    
    return FluidButton(
      onTap: () async {
        final service = ref.read(subscriptionServiceProvider);
        await service.setProStatus(true);
        if (context.mounted) Navigator.pop(context);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4), // İçerideki padding FluidButton tarafından sağlanıyor olabilir, burası ek derinlik için
            child: Row(
              children: [
                // İkon veya Radio-benzeri görsel
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPopular ? primaryColor : Colors.white.withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                  child: isPopular ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    ),
                  ) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (savings != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                savings, 
                                style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        subtitle, 
                        style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(context).withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price.split(' ').first, 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      price.split(' ').skip(1).join(' '), 
                      style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context).withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (badge != null)
            Positioned(
              top: -12,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
