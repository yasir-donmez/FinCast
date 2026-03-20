import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';
import 'fluid_container.dart';

/// FinCast Yeni Nesil "Sıvı & Organik" Metin Alanı (Fluid Text Field).
/// Glassmorphism dokulu, odaklanıldığında (focus) parlayan ve yumuşak geçişli yapı.
class FluidTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final Function(String)? onSubmitted;
  final String? errorText;
  final Widget? suffixIcon;

  const FluidTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.errorText,
    this.suffixIcon,
  });

  @override
  State<FluidTextField> createState() => _FluidTextFieldState();
}

class _FluidTextFieldState extends State<FluidTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.getPrimary(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault * 1.5),
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.3),
                  blurRadius: 15,
                  spreadRadius: -2,
                ),
            ],
          ),
          child: FluidContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            borderRadius: AppSizes.radiusDefault * 1.5,
            isGlass: true,
            blur: 12,
            color: _isFocused 
                ? primaryColor.withValues(alpha: isDark ? 0.05 : 0.08) 
                : null,
            child: Row(
              children: [
                if (widget.prefixIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _isFocused 
                          ? primaryColor 
                          : AppColors.getTextSecondary(context).withValues(alpha: 0.7),
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    onChanged: widget.onChanged,
                    onEditingComplete: widget.onEditingComplete,
                    onSubmitted: widget.onSubmitted,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: AppColors.getTextSecondary(context).withValues(alpha: 0.4),
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                if (widget.suffixIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: widget.suffixIcon,
                  ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: widget.errorText != null
                ? Padding(
                    key: ValueKey(widget.errorText),
                    padding: const EdgeInsets.only(top: 6, left: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 12, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.errorText!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
