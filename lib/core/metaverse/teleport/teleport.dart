import '../registry/world_registry.dart';
import '../presence/presence.dart';

/// Teleport a presence across zones (Step 42.10–42.12).
class Teleport {
  Teleport({required this.registry});

  final WorldRegistry registry;

  void move(Presence presence, String targetZoneId) {
    if (registry.zone(targetZoneId) == null) {
      throw StateError('Unknown zone: $targetZoneId');
    }
    presence.moveTo(targetZoneId);
  }
}
