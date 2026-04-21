import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/services/subscription_service.dart';
import '../../../shared/widgets/fluid_button.dart';
import '../../../shared/widgets/fluid_sheet.dart';
import '../../../shared/widgets/membership_orb.dart';

/// FinCast "Pro Üyelik" (Paywall) Sayfası.
class ProUpgradeSheet extends ConsumerWidget {
  const ProUpgradeSheet({super.key});

  static void show(BuildContext context) {
    FluidSheet.show(
      context: context,
      child: const ProUpgradeSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = AppColors.getPrimary(context);
    final secondaryTextColor = AppColors.getTextSecondary(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ekran yüksekliğine göre boşlukları ve boyutları ayarla
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 700;
        
        final verticalSpacing = isSmallScreen ? 8.0 : 16.0;
        final headerSpacing = isSmallScreen ? 12.0 : 20.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 Üst Bar (Küre ve Başlık)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24.0, 
                vertical: isSmallScreen ? 12.0 : 20.0
              ),
              child: Column(
                children: [
                  Hero(
                    tag: 'pro_orb',
                    child: MembershipOrb(
                      color: primaryColor,
                      size: isSmallScreen ? 36 : 44,
                    ),
                  ),
                  SizedBox(height: headerSpacing),
                  Text(
                    'FinCast Pro\'ya Geçin',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 22 : 26, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: -0.5
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isSmallScreen) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Finansal potansiyelinizi %100 açığa çıkarın.',
                      style: TextStyle(
                        fontSize: 14, 
                        color: secondaryTextColor.withValues(alpha: 0.6)
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            // 🚀 Avantajlar Listesi (Daha kompakt)
            _buildFeatureItem(context, Icons.analytics_rounded, 'AI Analizleri', 'Günlük 3 derin analiz.', isSmallScreen),
            _buildFeatureItem(context, Icons.account_balance_wallet_rounded, 'Sınırsız Kasa', 'Dilediğiniz kadar kasa.', isSmallScreen),
            _buildFeatureItem(context, Icons.block_rounded, 'Sıfır Reklam', 'Kesintisiz deneyim.', isSmallScreen),
            
            SizedBox(height: verticalSpacing * 1.5),
            
            // PLANLAR Başlığı
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PLANLAR', 
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.2,
                  color: secondaryTextColor.withValues(alpha: 0.4),
                ),
              ),
            ),
            SizedBox(height: verticalSpacing),
            
            // PRO SEÇENEKLERİ
            _buildPlanCard(
              context: context,
              title: 'Yıllık Pro',
              price: '₺199.99 / yıl',
              subtitle: 'Aylık ₺16.66',
              badge: 'AVANTAJLI',
              ref: ref,
              isPopular: true,
              isSmall: isSmallScreen,
              backgroundColor: Colors.pinkAccent.withValues(alpha: 0.08),
              borderColor: primaryColor.withValues(alpha: 0.5),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            _buildPlanCard(
              context: context,
              title: 'Aylık Pro',
              price: '₺24.99 / ay',
              subtitle: 'İstediğin zaman iptal et',
              ref: ref,
              isSmall: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            
            // MEVCUT PLAN (Daha küçük)
            _buildPlanCard(
              context: context,
              title: 'Ücretsiz Plan',
              subtitle: 'Temel özellikler.',
              isCurrent: true,
              isSmall: isSmallScreen,
              borderColor: Colors.transparent,
              backgroundColor: Colors.transparent,
            ),

            SizedBox(height: verticalSpacing),
            
            // 🔘 Alt Bilgi
            Text(
              '7 gün ücretsiz deneme içerir.',
              style: TextStyle(
                fontSize: 11, 
                color: secondaryTextColor.withValues(alpha: 0.3)
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String subtitle, bool isSmall) {
    final primaryColor = AppColors.getPrimary(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 4 : 8),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: isSmall ? 18 : 20),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 14 : 15)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitle, 
                    style: TextStyle(
                      fontSize: isSmall ? 11 : 12, 
                      color: AppColors.getTextSecondary(context).withValues(alpha: 0.5)
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    String? price,
    String? badge,
    String? savings,
    bool isCurrent = false,
    bool isPopular = false,
    Gradient? accentGradient,
    Color? borderColor,
    Color? backgroundColor,
    bool isSmall = false,
    WidgetRef? ref,
  }) {
    final primaryColor = AppColors.getPrimary(context);
    
    return FluidButton(
      onTap: () {
        if (!isCurrent && ref != null) {
          ref.read(subscriptionServiceProvider).setProStatus(true);
          Navigator.pop(context);
        }
      },
      isSecondary: true,
      width: double.infinity,
      padding: EdgeInsets.zero,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmall ? 10 : 14),
            decoration: BoxDecoration(
              color: backgroundColor ?? (isCurrent 
                  ? Colors.white.withValues(alpha: 0.002) 
                  : (isPopular ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04))),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: borderColor ?? (isCurrent 
                    ? Colors.white.withValues(alpha: 0.01) 
                    : (isPopular ? primaryColor : Colors.white.withValues(alpha: 0.08))),
                width: isPopular ? 2.5 : 1.2,
              ),
              gradient: accentGradient,
              boxShadow: [
                if (isPopular)
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Opacity(
              opacity: isCurrent ? 0.4 : 1.0,
              child: Row(
                children: [
                  // 🔘 SOL İKON (Hizalı Radyo/Check)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? Colors.grey : (isPopular ? primaryColor : Colors.white.withValues(alpha: 0.2)),
                        width: 1.5,
                      ),
                    ),
                    child: isCurrent ? const Center(
                      child: Icon(Icons.check_rounded, size: 12, color: Colors.grey),
                    ) : null,
                  ),
                  const SizedBox(width: 12),
                  
                  // 📝 ORTA BİLGİ ALANI
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                title, 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 14 : 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // 💰 SAĞ FİYAT VEYA ETİKET
                  if (isCurrent)
                    Text(
                      'MEVCUT', 
                      style: TextStyle(
                        fontSize: isSmall ? 8 : 10, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.grey.withValues(alpha: 0.5),
                        letterSpacing: 0.5
                      )
                    )
                  else if (price != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: price.split(' ').first,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900, 
                                  fontSize: isSmall ? 15 : 18,
                                  color: AppColors.getTextPrimary(context)
                                ),
                              ),
                              TextSpan(
                                text: ' ${price.split(' ').skip(1).join(' ')}',
                                style: TextStyle(
                                  fontSize: isSmall ? 9 : 11, 
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getTextSecondary(context).withValues(alpha: 0.4)
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          if (badge != null)
            Positioned(
              top: 0,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3), 
                      blurRadius: 8, 
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 8, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
