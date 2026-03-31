import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/services/subscription_service.dart';
import '../../../shared/widgets/fluid_button.dart';
import '../../../shared/widgets/fluid_sheet.dart';
import '../../../shared/widgets/membership_orb.dart';
import '../../auth/widgets/liquid_background.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 🌊 Arka Plan Efekti
        Positioned(
          left: -AppSizes.paddingLarge,
          right: -AppSizes.paddingLarge,
          top: -AppSizes.paddingLarge,
          bottom: -AppSizes.paddingLarge,
          child: Opacity(
            opacity: isDark ? 0.2 : 0.1,
            child: const LiquidBackground(),
          ),
        ),
        
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 Üst Bar
            _buildHeader(context, primaryColor),

            const SizedBox(height: 12),
            
            // 🚀 Avantajlar Listesi
            _buildFeatureItem(context, Icons.analytics_rounded, 'AI Analizleri', 'Günlük 3 derin finansal analiz ve tahmin.'),
            _buildFeatureItem(context, Icons.account_balance_wallet_rounded, 'Sınırsız Kasa', 'Dilediğiniz kadar kasa ve özel renkler.'),
            _buildFeatureItem(context, Icons.block_rounded, 'Sıfır Reklam', 'Kesintisiz ve akışkan deneyim.'),
            
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PLANLAR', 
                style: TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.2,
                  color: AppColors.getTextSecondary(context).withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // PRO SEÇENEKLERİ (Upgrade Options)
            _buildPlanCard(
              context: context,
              title: 'Yıllık Pro',
              price: '₺199.99 / yıl',
              subtitle: 'Aylık ₺16.66\'ya gelir',
              badge: 'EN AVANTAJLI',
              savings: '%33 TASARRUF',
              ref: ref,
              isPopular: true,
              backgroundColor: Colors.pinkAccent.withValues(alpha: 0.12),
              borderColor: primaryColor,
              accentGradient: LinearGradient(
                colors: [
                  Colors.pinkAccent.withValues(alpha: 0.3), 
                  Colors.transparent
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            const SizedBox(height: 12),
            _buildPlanCard(
              context: context,
              title: 'Aylık Pro',
              price: '₺24.99 / ay',
              subtitle: 'İstediğin zaman iptal et',
              ref: ref,
              accentGradient: LinearGradient(
                colors: [
                  Colors.pinkAccent.withValues(alpha: 0.06), 
                  Colors.transparent
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            const SizedBox(height: 12),
            
            // MEVCUT PLAN (Current Plan) - Ghostly
            _buildPlanCard(
              context: context,
              title: 'Ücretsiz Plan',
              subtitle: 'Temel özellikler ile sınırlı kullanım.',
              isCurrent: true,
              borderColor: Colors.white.withValues(alpha: 0.02),
              backgroundColor: Colors.transparent,
              contentOpacity: 0.4,
            ),

            const SizedBox(height: 24),
            
            // 🔘 Alt Bilgi
            Center(
              child: Text(
                'Tüm planlar 7 gün ücretsiz deneme içerir.',
                style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(context).withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Hero(
            tag: 'pro_orb',
            child: Container(
              padding: const EdgeInsets.all(4),
              child: MembershipOrb(
                color: primaryColor,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'FinCast Pro\'ya Geçin',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Finansal potansiyelinizi %100 açığa çıkarın.',
            style: TextStyle(fontSize: 15, color: AppColors.getTextSecondary(context).withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String subtitle) {
    final primaryColor = AppColors.getPrimary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(context).withValues(alpha: 0.5))),
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
    double contentOpacity = 1.0,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              opacity: contentOpacity,
              child: Row(
                children: [
                  // 🔘 SOL İKON (Hizalı Radyo/Check)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? Colors.grey : (isPopular ? primaryColor : Colors.white.withValues(alpha: 0.1)),
                        width: 2,
                      ),
                    ),
                    child: isCurrent ? const Center(
                      child: Icon(Icons.check_rounded, size: 14, color: Colors.grey),
                    ) : null,
                  ),
                  const SizedBox(width: 16),
                  
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('MEVCUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    )
                  else if (price != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12), // Çakışmayı engelle
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
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
                    ),
                ],
              ),
            ),
          ),
          
          if (badge != null)
            Positioned(
              top: 15,
              bottom: 15,
              right: -18, // Kartın dışına çıkarıldı
              child: Container(
                width: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4), 
                      blurRadius: 10, 
                      offset: const Offset(4, 0),
                    ),
                  ],
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 8.5, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
