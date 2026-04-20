import 'package:flutter/material.dart';
import '../../../shared/widgets/fluid_container.dart';

class VaultFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const VaultFilterChip({
    super.key,
    required this.label, 
    required this.isActive, 
    required this.onTap, 
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FluidContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 16,
        isGlass: true,
        borderWidth: isActive ? 2 : 1,
        color: isActive ? activeColor.withValues(alpha: 0.1) : null,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: isActive ? activeColor : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
