import 'package:flutter/material.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/database/models/financial_goal.dart';
import '../../../../shared/widgets/precision_glass_card.dart';
import '../../../../shared/widgets/precision_membership_orb.dart';
import '../../../../l10n/app_localizations.dart';

class OptimizationPersonaHeader extends StatelessWidget {
  final List<FinancialGoal> goals;
  final String? currentPersonaText;
  final AppLocalizations l10n;

  const OptimizationPersonaHeader({
    super.key,
    required this.goals,
    this.currentPersonaText,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final savedPersona = goals.firstOrNull?.aiPersonaText;
    final displayText = currentPersonaText ?? savedPersona;
    final screenWidth = MediaQuery.of(context).size.width;

    return PrecisionGlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 20,
      ),
      child: Row(
        children: [
          PrecisionMembershipOrb(color: AppColors.getPrimary(context), size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.financialIdentity.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.getPrimary(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayText ?? l10n.financialIdentityHint,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
