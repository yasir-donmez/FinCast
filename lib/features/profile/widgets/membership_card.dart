import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/theme/app_constants.dart';
import '../../../l10n/app_localizations.dart';

class MembershipCard extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isPro;
  final Color activeColor;
  final VoidCallback onTap;

  const MembershipCard({
    super.key,
    required this.l10n,
    required this.isPro,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: activeColor.withValues(alpha: isPro ? 0.3 : 0.05),
                  width: 1.0,
                ),
                color: activeColor.withValues(alpha: isPro ? 0.05 : 0.02),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPro
                          ? Icons.workspace_premium_rounded
                          : Icons.person_outline_rounded,
                      color: activeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPro ? "FinCast PRO" : "Free Plan",
                          style: TextStyle(
                            color: AppColors.getTextPrimary(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPro 
                            ? "PRO Üyelik Aktif" 
                            : "Sınırsız kasa ve AI analizi için yükseltin.",
                          style: TextStyle(
                            color: AppColors.getTextSecondary(context).withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPro 
                        ? activeColor.withValues(alpha: 0.1)
                        : AppColors.getSurface(context).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPro ? "AKTİF" : "YÜKSELT",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isPro ? activeColor : AppColors.getTextSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
