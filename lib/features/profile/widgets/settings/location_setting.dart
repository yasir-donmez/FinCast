import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../dashboard/dashboard_providers.dart';
import '../profile_list_items.dart';

class LocationSetting extends ConsumerWidget {
  const LocationSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocationEnabled = ref.watch(settingsProvider.select((s) => s.isLocationEnabled));
    final activeColor = ref.watch(rotaryColorProvider);

    return ProfileListItems.buildToggle(
      icon: Icons.location_on_rounded,
      title: "Konum Servisleri", // TODO: Add to L10n if needed
      value: isLocationEnabled,
      onChanged: (val) => ref.read(settingsProvider.notifier).toggleLocation(val),
      activeColor: activeColor,
      context: context,
      activeIcon: Icons.location_on_rounded,
      inactiveIcon: Icons.location_off_rounded,
    );
  }
}
