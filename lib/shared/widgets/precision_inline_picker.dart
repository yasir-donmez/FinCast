import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrecisionInlinePicker extends StatefulWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double width;
  final double scalingFactor;

  const PrecisionInlinePicker({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.width = 120.0,
    this.scalingFactor = 1.0,
  });

  @override
  State<PrecisionInlinePicker> createState() => _PrecisionInlinePickerState();
}

class _PrecisionInlinePickerState extends State<PrecisionInlinePicker> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(PrecisionInlinePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _controller.jumpToItem(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 64 * widget.scalingFactor,
      width: widget.width * widget.scalingFactor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vurgu Çizgileri
          Container(
            width: widget.width * widget.scalingFactor,
            height: 34 * widget.scalingFactor,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: activeColor.withValues(alpha: 0.1), width: 0.8),
                bottom: BorderSide(color: activeColor.withValues(alpha: 0.1), width: 0.8),
              ),
            ),
          ),
          
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 32 * widget.scalingFactor,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.006,
            diameterRatio: 1.0,
            overAndUnderCenterOpacity: 0.5,
            useMagnifier: true,
            magnification: 1.15,
            onSelectedItemChanged: (index) {
              if (index != widget.selectedIndex) {
                HapticFeedback.selectionClick();
                widget.onChanged(index);
              }
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.items.length,
              builder: (context, index) {
                final isSelected = index == widget.selectedIndex;
                final onSurface = Theme.of(context).colorScheme.onSurface;
                
                return Center(
                  child: Text(
                    widget.items[index],
                    style: TextStyle(
                      fontSize: 14 * widget.scalingFactor,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                      color: isSelected 
                          ? onSurface 
                          : onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
