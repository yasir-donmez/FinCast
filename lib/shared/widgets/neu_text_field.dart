import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';
import 'neu_container.dart';

class NeuTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const NeuTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      isInnerShadow: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      borderRadius: AppSizes.radiusDefault,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(
          color: AppColors.getTextPrimary(context),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.getTextSecondary(context).withValues(alpha: 0.5),
          ),
          icon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: AppColors.getTextSecondary(context),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
