/// Sprint 47 — Step 47.5–47.7 Runtime Architecture, Entity Component.
class RuntimeModule {
  const RuntimeModule({
    required this.id,
    required this.name,
    required this.enabled,
  });

  final String id;
  final String name;
  final bool enabled;
}

class EntityComponent {
  const EntityComponent({
    required this.id,
    required this.entityId,
    required this.type,
    this.data = const {},
  });

  final String id;
  final String entityId;
  final String type;
  final Map<String, Object> data;
}

class GameEntity {
  const GameEntity({
    required this.id,
    required this.name,
    this.components = const [],
  });

  final String id;
  final String name;
  final List<EntityComponent> components;
}
