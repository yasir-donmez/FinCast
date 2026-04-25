import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/dashboard_providers.dart';

class RetentionSetting extends ConsumerWidget {
  const RetentionSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final activeColor = ref.watch(rotaryColorProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            l10n.dataRetentionDesc,
            style: TextStyle(
              color: AppColors.getTextSecondary(context),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _retentionBubble(context, ref, l10n.oneMonth, 30, settings.dataRetentionDays, activeColor),
            _retentionBubble(context, ref, l10n.threeMonths, 90, settings.dataRetentionDays, activeColor),
            _retentionBubble(context, ref, l10n.sixMonths, 180, settings.dataRetentionDays, activeColor),
            _retentionBubble(context, ref, l10n.oneYear, 365, settings.dataRetentionDays, activeColor),
            _retentionBubble(context, ref, l10n.infinite, -1, settings.dataRetentionDays, activeColor),
          ],
        ),
      ],
    );
  }

  Widget _retentionBubble(
    BuildContext context,
    WidgetRef ref,
    String label,
    int days,
    int currentDays,
    Color activeColor,
  ) {
    final isActive = currentDays == days;
    return GestureDetector(
      onTap: () => ref.read(settingsProvider.notifier).setDataRetention(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor
              : AppColors.getSurface(context).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
          border: Border.all(
            color: isActive
                ? activeColor
                : Colors.white.withValues(alpha: 0.05),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.black
                : AppColors.getTextSecondary(context),
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
