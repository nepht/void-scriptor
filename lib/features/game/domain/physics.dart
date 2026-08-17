/// Sprint 47 — Step 47.69–47.73 Physics Layer, Gameplay ↔ Simulation.
class GameplayPhysics {
  const GameplayPhysics({required this.gravity, required this.maxFallSpeed});

  final double gravity;
  final double maxFallSpeed;

  double applyGravity({
    required double velocity,
    required double deltaSeconds,
  }) {
    final next = velocity + gravity * deltaSeconds;
    return next.clamp(-maxFallSpeed, maxFallSpeed);
  }
}

class PhysicsRule {
  const PhysicsRule({
    required this.id,
    required this.name,
    required this.enabled,
  });

  final String id;
  final String name;
  final bool enabled;
}
