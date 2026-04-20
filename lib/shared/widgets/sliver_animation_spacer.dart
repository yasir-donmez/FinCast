import 'package:flutter/material.dart';

/// A sliver that adds enough space at the bottom of a [CustomScrollView] 
/// to ensure that pinned headers can fully collapse even when there is little content.
class SliverAnimationSpacer extends StatelessWidget {
  final double minHeaderHeight;

  const SliverAnimationSpacer({
    super.key,
    this.minHeaderHeight = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;
    
    // We provide enough height to allow the scroll view to scroll 
    // the distance required to collapse the header.
    // Generally, providing a generous bottom space also helps the UI "breathe".
    return SliverToBoxAdapter(
      child: SizedBox(height: viewportHeight - minHeaderHeight),
    );
  }
}
