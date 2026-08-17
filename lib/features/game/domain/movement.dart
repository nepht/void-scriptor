/// Sprint 47 — Step 47.11–47.13 Player Controller, Movement State Machine.
enum MovementState {
  idle,
  walking,
  running,
  jumping,
  falling,
  climbing,
  swimming,
  dashing,
}

class PlayerController {
  const PlayerController({
    required this.id,
    required this.entityId,
    this.moveSpeed = 4.0,
    this.runMultiplier = 2.0,
    this.jumpVelocity = 8.0,
    this.state = MovementState.idle,
  });

  final String id;
  final String entityId;
  final double moveSpeed;
  final double runMultiplier;
  final double jumpVelocity;
  final MovementState state;

  PlayerController withState(MovementState next) => PlayerController(
    id: id,
    entityId: entityId,
    moveSpeed: moveSpeed,
    runMultiplier: runMultiplier,
    jumpVelocity: jumpVelocity,
    state: next,
  );
}

/// Step 47.14–47.16 Universal Input System.
class InputAction {
  const InputAction({
    required this.id,
    required this.name,
    required this.defaultKey,
    this.rebindable = true,
  });

  final String id;
  final String name;
  final String defaultKey;
  final bool rebindable;
}

class InputBinding {
  const InputBinding({required this.actionId, required this.key});

  final String actionId;
  final String key;
}

/// Step 47.17–47.19 Camera Modes.
enum CameraMode { orbit, thirdPerson, firstPerson, combat, cinematic }

class CameraConfig {
  const CameraConfig({required this.id, required this.mode, this.fov = 60.0});

  final String id;
  final CameraMode mode;
  final double fov;
}
