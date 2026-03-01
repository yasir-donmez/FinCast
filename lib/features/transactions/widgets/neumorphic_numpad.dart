import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/neu_button.dart';

/// FinCast işlemleri (Esnek Bütçeleme) için hazırlanan özel Neumorphic Tuş Takımı
class NeumorphicNumpad extends StatelessWidget {
  final Function(String) onNumberTapped;
  final VoidCallback onBackspaceTapped;
  final VoidCallback onDoneTapped;

  const NeumorphicNumpad({
    super.key,
    required this.onNumberTapped,
    required this.onBackspaceTapped,
    required this.onDoneTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: AppSizes.paddingMedium),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: AppSizes.paddingMedium),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: AppSizes.paddingMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionKey(
              icon: Icons.backspace_rounded,
              color: AppColors.error,
              onTap: onBackspaceTapped,
            ),
            _buildNumberKey('0'),
            _buildActionKey(
              icon: Icons.check_rounded,
              color: AppColors.primary,
              onTap: onDoneTapped,
              isPrimary: true, // "Tamamla" butonu neon parlasın
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((numberVal) => _buildNumberKey(numberVal)).toList(),
    );
  }

  Widget _buildNumberKey(String number) {
    return NeuButton(
      width: 70,
      height: 70,
      borderRadius: 35, // Tam yuvarlak tuşlar
      onTap: () {
        HapticFeedback.lightImpact(); // Tuş hissiyatı
        onNumberTapped(number);
      },
      child: Text(
        number,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return NeuButton(
      width: 70,
      height: 70,
      borderRadius: 35,
      isPrimary: isPrimary,
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Icon(icon, color: color, size: 28),
    );
  }
}
