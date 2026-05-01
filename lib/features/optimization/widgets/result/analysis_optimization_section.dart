import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../shared/widgets/precision_glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../ai_service.dart';

class AnalysisOptimizationSection extends StatelessWidget {
  final OptimizationResult opt;
  final AppLocalizations l10n;
  final NumberFormat currencyFormat;

  const AnalysisOptimizationSection({
    super.key,
    required this.opt,
    required this.l10n,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrecisionGlassCard(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.psychology_rounded,
                color: AppColors.getSecondary(context),
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiCoachSuggestion.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.getSecondary(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      opt.coachMessage,
                      style: TextStyle(
                        color: AppColors.getTextPrimary(context),
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...opt.cuts.map((cut) => _buildCutRowFluid(context, cut)),
      ],
    );
  }

  Widget _buildCutRowFluid(BuildContext context, CutSuggestion cut) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: PrecisionGlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cut.category,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cut.reason,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context).withValues(alpha: 0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${currencyFormat.format(cut.suggestedAmount.toInt())}',
                  style: TextStyle(
                    color: AppColors.getPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '← ₺${currencyFormat.format(cut.currentAmount.toInt())}',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context).withValues(alpha: 0.5),
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
