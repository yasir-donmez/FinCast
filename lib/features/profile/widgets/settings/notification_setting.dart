import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/dashboard_providers.dart';
import '../profile_list_items.dart';

class NotificationSetting extends ConsumerWidget {
  const NotificationSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAiEnabled = ref.watch(settingsProvider.select((s) => s.isAiNotificationsEnabled));
    final activeColor = ref.watch(rotaryColorProvider);
    final l10n = AppLocalizations.of(context)!;

    return ProfileListItems.buildToggle(
      icon: Icons.notifications_active_rounded,
      title: l10n.aiNotifications,
      value: isAiEnabled,
      onChanged: (val) => ref.read(settingsProvider.notifier).toggleAiNotifications(val),
      activeColor: activeColor,
      context: context,
      activeIcon: Icons.notifications_active_rounded,
      inactiveIcon: Icons.notifications_off_rounded,
    );
  }
}
