import 'package:flutter/material.dart';

class VaultSnapScrollPhysics extends BouncingScrollPhysics {
  final double maxScrollExtent;

  const VaultSnapScrollPhysics({
    super.parent,
    required this.maxScrollExtent,
  });

  @override
  VaultSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return VaultSnapScrollPhysics(
      parent: buildParent(ancestor),
      maxScrollExtent: maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);
    final offset = position.pixels;

    // Eğer Kasa başlığının küçüldüğü bölgedeysek (0 ile maxScrollExtent arası)
    if (offset > 0.0 && offset < maxScrollExtent) {
      final double target;
      
      // Kullanıcı hızlı kaydırdıysa (flick), ivmeye göre yukarı veya aşağı yapıştır
      if (velocity.abs() > tolerance.velocity) {
        target = velocity > 0 ? maxScrollExtent : 0.0;
      } else {
        // Kullanıcı yavaş bıraktıysa, yarıyı geçtiği tarafa yapıştır
        target = offset > maxScrollExtent / 2 ? maxScrollExtent : 0.0;
      }
      
      return ScrollSpringSimulation(
        spring,
        offset,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    
    // Normal liste kaydırması için BouncingScrollPhysics'e bırak
    return super.createBallisticSimulation(position, velocity);
  }
}
