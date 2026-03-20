import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/fluid_button.dart';

/// FinCast işlemleri için hazırlanan yeni nesil Fluid (Akışkan) Tuş Takımı.
/// Neumorphic yapının yerini alan, daha modern ve cam dokulu tasarım.
class FluidNumpad extends StatelessWidget {
  final Function(String) onNumberTapped;
  final VoidCallback onBackspaceTapped;
  final VoidCallback onDoneTapped;
  final Color? activeColor;

  const FluidNumpad({
    super.key,
    required this.onNumberTapped,
    required this.onBackspaceTapped,
    required this.onDoneTapped,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(context, ['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(context, ['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(context, ['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionKey(
              context: context,
              icon: Icons.backspace_rounded,
              color: AppColors.getError(context),
              onTap: onBackspaceTapped,
            ),
            _buildNumberKey(context, '0'),
            _buildActionKey(
              context: context,
              icon: Icons.check_rounded,
              color: activeColor ?? AppColors.getPrimary(context),
              onTap: onDoneTapped,
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((numberVal) => _buildNumberKey(context, numberVal)).toList(),
    );
  }

  Widget _buildNumberKey(BuildContext context, String number) {
    return FluidButton(
      width: 72,
      height: 72,
      borderRadius: 36, // Tam yuvarlak
      isSecondary: true, // Cam dokusu için
      onTap: () {
        HapticFeedback.lightImpact();
        onNumberTapped(number);
      },
      child: Text(
        number,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.getTextPrimary(context),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return FluidButton(
      width: 72,
      height: 72,
      borderRadius: 36,
      isSecondary: !isPrimary,
      color: isPrimary ? color : null,
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Icon(
        icon, 
        color: isPrimary ? Colors.white : color, 
        size: 28
      ),
    );
  }
}
