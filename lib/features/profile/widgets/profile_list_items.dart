import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/precision_clickable.dart';
import '../../../shared/widgets/fluid_switch.dart';

class ProfileListItems {
  static Widget buildSectionTitle(String title, Color activeColor, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: activeColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildSetting({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
    required Color activeColor,
    required BuildContext context,
    bool isAction = false,
  }) {
    return PrecisionClickable(
      onTap: onTap,
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
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 22, color: activeColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (trailing == null && !isAction)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.getTextSecondary(context).withValues(alpha: 0.3),
              ),
            if (isAction)
              Icon(
                Icons.arrow_outward_rounded,
                color: activeColor.withValues(alpha: 0.5),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildToggle({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
    required BuildContext context,
    IconData? activeIcon,
    IconData? inactiveIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: activeColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(icon, color: activeColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FluidSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            activeIcon: activeIcon,
            inactiveIcon: inactiveIcon,
          ),
        ],
      ),
    );
  }

  static Widget buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 20,
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
    );
  }
}
