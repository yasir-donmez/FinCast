import 'package:flutter/material.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../shared/widgets/precision_glass_card.dart';
import '../../../../shared/widgets/precision_button.dart';
import '../../../../l10n/app_localizations.dart';

class AnalysisFeedbackSection extends StatelessWidget {
  final AppLocalizations l10n;
  final bool? userApproval;
  final Function(bool) onSubmitFeedback;

  const AnalysisFeedbackSection({
    super.key,
    required this.l10n,
    required this.userApproval,
    required this.onSubmitFeedback,
  });

  @override
  Widget build(BuildContext context) {
    if (userApproval == null) {
      return PrecisionGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            Text(
              l10n.doYouLikeThisSuggestion,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(context).withValues(alpha: 0.7),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: PrecisionButton(
                    label: l10n.no,
                    onTap: () => onSubmitFeedback(false),
                    isPrimary: false,
                    height: 48,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrecisionButton(
                    label: l10n.yes,
                    onTap: () => onSubmitFeedback(true),
                    isPrimary: true,
                    height: 48,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      final approved = userApproval == true;
      return PrecisionGlassCard(
        color: (approved ? AppColors.getSuccess(context) : AppColors.getError(context)).withValues(alpha: 0.05),
        child: Row(
          children: [
            Icon(
              approved ? Icons.check_circle : Icons.cancel,
              color: approved ? AppColors.getSuccess(context) : AppColors.getError(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                approved ? l10n.financialIdentityUpdated : l10n.feedbackMemoized,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
  }
}
