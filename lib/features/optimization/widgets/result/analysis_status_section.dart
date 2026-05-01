import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../optimization_providers.dart';

class AnalysisStatusSection extends StatelessWidget {
  final AnalysisSnapshot snapshot;
  final AppLocalizations l10n;
  final NumberFormat currencyFormat;

  const AnalysisStatusSection({
    super.key,
    required this.snapshot,
    required this.l10n,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final onTrack = snapshot.isAlreadyOnTrack;
    final healthScore = onTrack
        ? 1.0
        : (snapshot.monthlySurplus / snapshot.requiredMonthlySaving).clamp(0.0, 1.0);

    return Column(
      children: [
        const SizedBox(height: 20),
        _buildExecutiveScoreFluid(context, healthScore, onTrack),
        const SizedBox(height: 40),
        Text(
          onTrack ? l10n.onTrackMessage : l10n.savingsNeeded,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 40),

        // Metrics Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              _vipMetricFluid(
                context,
                l10n.targetGap,
                currencyFormat.format(snapshot.gap.toInt()),
                Icons.flag_circle_rounded,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.getTextSecondary(context).withValues(alpha: 0.1),
              ),
              _vipMetricFluid(
                context,
                l10n.remainingTime,
                l10n.monthsToTargetLabel(snapshot.months),
                Icons.timelapse_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Main Value Display
        Container(
          padding: const EdgeInsets.all(32),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: (onTrack ? AppColors.getSuccess(context) : AppColors.getError(context)).withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                onTrack ? l10n.currentSurplus : l10n.requiredMonthlySavings,
                style: TextStyle(
                  color: AppColors.getTextSecondary(context).withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₺',
                    style: TextStyle(
                      color: onTrack ? AppColors.getSuccess(context) : AppColors.getError(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currencyFormat.format(
                      onTrack ? snapshot.monthlySurplus.toInt() : snapshot.requiredMonthlySaving.toInt(),
                    ),
                    style: TextStyle(
                      color: onTrack ? AppColors.getSuccess(context) : AppColors.getError(context),
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExecutiveScoreFluid(BuildContext context, double score, bool onTrack) {
    final color = onTrack
        ? AppColors.getSuccess(context)
        : (score < 0.4 ? AppColors.getError(context) : AppColors.getPrimary(context));
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(4, 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(-4, -4),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          width: 150,
          child: CircularProgressIndicator(
            value: score,
            strokeWidth: 12,
            backgroundColor: Colors.black.withValues(alpha: 0.05),
            color: color,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(score * 100).toInt()}',
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
            Text(
              l10n.score.toUpperCase(),
              style: TextStyle(
                color: AppColors.getTextSecondary(context).withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _vipMetricFluid(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: AppColors.getPrimary(context).withValues(alpha: 0.8),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.getTextSecondary(context).withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
