import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/precision_action.dart';
import '../../../../shared/widgets/precision_toggle.dart';
import '../../../../shared/widgets/precision_animated_icon.dart';
import '../../../dashboard/dashboard_providers.dart';

final _notifExpandedProvider = StateProvider.autoDispose<bool>((ref) => false);

class NotificationSetting extends ConsumerWidget {
  const NotificationSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAiEnabled = ref.watch(settingsProvider.select((s) => s.isAiNotificationsEnabled));
    final activeColor = ref.watch(rotaryColorProvider);
    final l10n = AppLocalizations.of(context)!;
    final isExpanded = ref.watch(_notifExpandedProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrecisionAction(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(_notifExpandedProvider.notifier).state = !isExpanded;
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: PrecisionAnimatedIcon(
                    isActive: isAiEnabled,
                    activeIcon: Icons.notifications_active_rounded,
                    inactiveIcon: Icons.notifications_off_rounded,
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
                        l10n.aiNotifications,
                        style: TextStyle(
                          color: AppColors.getTextPrimary(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        isExpanded ? "Yapay zeka asistanı bilgilendirmeleri." : (isAiEnabled ? "Aktif" : "Kapalı"),
                        style: TextStyle(
                          color: AppColors.getTextSecondary(context).withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PrecisionToggle(
                  value: isAiEnabled,
                  onChanged: (val) {
                    HapticFeedback.mediumImpact();
                    ref.read(settingsProvider.notifier).toggleAiNotifications(val);
                  },
                  activeColor: activeColor,
                  activeIcon: Icons.notifications_active_rounded,
                  inactiveIcon: Icons.notifications_off_rounded,
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: activeColor.withValues(alpha: isExpanded ? 1.0 : 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
          child: isExpanded
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.getInnerSurface(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Finansal durumunuzdaki kritik değişimler, bütçe aşımları ve yapay zeka optimizasyon "
                      "önerileri hakkında anlık bildirimler almanızı sağlar.",
                      style: TextStyle(
                        color: AppColors.getTextSecondary(context),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
