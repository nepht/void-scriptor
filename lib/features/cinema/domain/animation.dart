/// Sprint 48 — Step 48.31–48.33 Animation Layers, Constraints.
class AnimationLayer {
  const AnimationLayer({
    required this.id,
    required this.name,
    required this.priority,
    required this.weight,
  });

  final String id;
  final String name;
  final int priority;
  final double weight;
}

class PerformanceConstraint {
  const PerformanceConstraint({
    required this.id,
    required this.constraint,
    required this.priority,
  });

  final String id;
  final String constraint;
  final int priority;
}
