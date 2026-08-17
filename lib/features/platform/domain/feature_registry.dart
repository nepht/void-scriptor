/// Sprint 50 — Step 50.1–50.4 Feature Scope, Readiness Matrix, Product Boundary.
enum FeatureStatus { frozen, inProgress, ready, verified, released }

class FeatureEntry {
  const FeatureEntry({
    required this.id,
    required this.name,
    required this.status,
    this.ownerModule,
  });

  final String id;
  final String name;
  final FeatureStatus status;
  final String? ownerModule;

  FeatureEntry markVerified() => FeatureEntry(
    id: id,
    name: name,
    status: FeatureStatus.verified,
    ownerModule: ownerModule,
  );
}

/// Step 50.9–50.10 Module Boundaries, Dependency Audit.
class ModuleBoundary {
  const ModuleBoundary({
    required this.id,
    required this.module,
    this.dependsOn = const [],
  });

  final String id;
  final String module;
  final List<String> dependsOn;

  bool hasCircularDependency(Map<String, ModuleBoundary> all) {
    for (final dep in dependsOn) {
      final depBoundary = all[dep];
      if (depBoundary != null && depBoundary.dependsOn.contains(module)) {
        return true;
      }
    }
    return false;
  }
}

/// Step 50.11–50.12 Unified Event Bus, Event Scope.
enum EventScope { global, project, session, local }

class PlatformEvent {
  const PlatformEvent({
    required this.id,
    required this.type,
    required this.scope,
  });

  final String id;
  final String type;
  final EventScope scope;
}
