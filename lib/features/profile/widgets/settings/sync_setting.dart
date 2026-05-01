import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../dashboard/dashboard_providers.dart';
import '../profile_list_items.dart';

class SyncSetting extends ConsumerWidget {
  const SyncSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncEnabled = ref.watch(settingsProvider.select((s) => s.isSyncEnabled));
    final activeColor = ref.watch(rotaryColorProvider);

    return ProfileListItems.buildToggle(
      icon: Icons.cloud_sync_rounded,
      title: "Bulut Senkronizasyonu",
      value: isSyncEnabled,
      onChanged: (val) => ref.read(settingsProvider.notifier).toggleSync(val),
      activeColor: activeColor,
      context: context,
      activeIcon: Icons.cloud_done_rounded,
      inactiveIcon: Icons.cloud_off_rounded,
    );
  }
}
