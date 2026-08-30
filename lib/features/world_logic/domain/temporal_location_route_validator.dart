// Sprint 110.22 - Temporal Location & Route Validation.
//
// Domain-only contract that joins TemporalMapState (110.20) with
// RouteGraph (110.9). Validates a location reference at a given tick
// (existence, validity range, name match, hidden status), validates
// a route reference at a given tick (existence, block, endpoint
// validity), and aggregates per-reference issues for a scene. Source
// evidence is propagated from RouteSource. No persistence, UI, wall
// clock, locale, or network. Deterministic.

library;

import 'route_network.dart';
import 'temporal_map_state.dart';

enum TemporalIssueCode {
  unknownLocation,
  locationNotYetActive,
  locationExpired,
  locationHidden,
  nameMismatch,
  unknownRoute,
  routeBlocked,
  routeNodeMissing,
  routeEndpointExpired,
}

class TemporalIssue {
  const TemporalIssue({
    required this.code,
    required this.message,
    this.locationId,
    this.edgeId,
  });

  final TemporalIssueCode code;
  final String message;
  final String? locationId;
  final String? edgeId;
}

class TemporalLocationResult {
  const TemporalLocationResult({
    required this.locationId,
    required this.tick,
    required this.isValid,
    required this.issues,
    this.canonicalName,
  });

  final String locationId;
  final int tick;
  final bool isValid;
  final List<TemporalIssue> issues;
  final String? canonicalName;
}

class TemporalRouteResult {
  const TemporalRouteResult({
    required this.edgeId,
    required this.tick,
    required this.isValid,
    required this.issues,
    required this.sourceRevision,
    required this.sourceReason,
  });

  final String edgeId;
  final int tick;
  final bool isValid;
  final List<TemporalIssue> issues;
  final String sourceRevision;
  final String sourceReason;
}

class SceneLocationReference {
  const SceneLocationReference({
    required this.locationId,
    this.suppliedName,
    this.edgeId,
  });

  final String locationId;
  final String? suppliedName;
  final String? edgeId;
}

class TemporalSceneResult {
  const TemporalSceneResult({
    required this.tick,
    required this.locationResults,
    required this.routeResults,
    required this.overallIssues,
    required this.allValid,
  });

  final int tick;
  final List<TemporalLocationResult> locationResults;
  final List<TemporalRouteResult> routeResults;
  final List<TemporalIssue> overallIssues;
  final bool allValid;
}

class TemporalLocationRouteValidator {
  TemporalLocationRouteValidator({Object? mapState, this.routeGraph})
    : mapState = (mapState is TemporalMapState)
          ? mapState
          : (throw ArgumentError.value(
              mapState,
              'mapState',
              'mapState is required and must be a TemporalMapState',
            )) {
    // no-op
  }

  final TemporalMapState mapState;
  final RouteGraph? routeGraph;

  String? nameAt({
    required String branchId,
    required String locationId,
    required int tick,
  }) {
    final locations = mapState.locationsFor(branchId);
    for (final loc in locations) {
      if (loc.id != locationId) continue;
      if (!loc.isActiveAt(tick)) return null;
      return loc.name;
    }
    return null;
  }

  TemporalLocationResult validateLocation({
    required String branchId,
    required String locationId,
    required int tick,
    String? suppliedName,
  }) {
    final issues = <TemporalIssue>[];
    final locations = mapState.locationsFor(branchId);
    TemporalLocation? target;
    for (final loc in locations) {
      if (loc.id == locationId) {
        target = loc;
        break;
      }
    }
    if (target == null) {
      issues.add(
        TemporalIssue(
          code: TemporalIssueCode.unknownLocation,
          message:
              "location '$locationId' is not declared on branch '$branchId'",
          locationId: locationId,
        ),
      );
      return TemporalLocationResult(
        locationId: locationId,
        tick: tick,
        isValid: false,
        issues: List.unmodifiable(issues),
      );
    }
    if (tick < target.validFrom) {
      issues.add(
        TemporalIssue(
          code: TemporalIssueCode.locationNotYetActive,
          message:
              "location '$locationId' is not yet active at tick $tick "
              "(validFrom=${target.validFrom})",
          locationId: locationId,
        ),
      );
    } else if (target.validUntil != null && tick > target.validUntil!) {
      issues.add(
        TemporalIssue(
          code: TemporalIssueCode.locationExpired,
          message:
              "location '$locationId' has expired by tick $tick "
              "(validUntil=${target.validUntil})",
          locationId: locationId,
        ),
      );
    } else if (target.statusAt(tick) == LocationStatus.hidden) {
      issues.add(
        TemporalIssue(
          code: TemporalIssueCode.locationHidden,
          message: "location '$locationId' is hidden at tick $tick",
          locationId: locationId,
        ),
      );
    }
    if (suppliedName != null && target.isActiveAt(tick)) {
      if (suppliedName != target.name) {
        issues.add(
          TemporalIssue(
            code: TemporalIssueCode.nameMismatch,
            message:
                "supplied name '$suppliedName' does not match canonical "
                "name '${target.name}' for location '$locationId' at tick $tick",
            locationId: locationId,
          ),
        );
      }
    }
    return TemporalLocationResult(
      locationId: locationId,
      tick: tick,
      isValid: issues.isEmpty,
      issues: List.unmodifiable(issues),
      canonicalName: target.isActiveAt(tick) ? target.name : null,
    );
  }

  TemporalRouteResult validateRoute({
    required String branchId,
    required String edgeId,
    required int tick,
  }) {
    final issues = <TemporalIssue>[];
    final graph = routeGraph;
    if (graph == null) {
      issues.add(
        TemporalIssue(
          code: TemporalIssueCode.unknownRoute,
          message: "no route graph supplied; cannot validate route '$edgeId'",
          edgeId: edgeId,
        ),
      );
      return TemporalRouteResult(
        edgeId: edgeId,
        tick: tick,
        isValid: false,
        issues: List.unmodifiable(issues),
        sourceRevision: '',
        sourceReason: '',
      );
    }
    RouteEdge? edge;
    for (final e in graph.edges) {
      if (e.id == edgeId) {
        edge = e;
        break;
      }
    }
    if (edge == null) {
      issues.add(
        TemporalIssue(
          code: TemporalIssueCode.unknownRoute,
          message: "route '$edgeId' is not declared in the route graph",
          edgeId: edgeId,
        ),
      );
      return TemporalRouteResult(
        edgeId: edgeId,
        tick: tick,
        isValid: false,
        issues: List.unmodifiable(issues),
        sourceRevision: '',
        sourceReason: '',
      );
    }
    if (edge.blocked != null) {
      issues.add(
        TemporalIssue(
          code: TemporalIssueCode.routeBlocked,
          message:
              "route '$edgeId' is blocked at tick $tick "
              "(${edge.blocked!.reason})",
          edgeId: edgeId,
        ),
      );
    }
    final locations = mapState.locationsFor(branchId);
    final fromActive = _activeLocation(locations, edge.fromId, tick);
    final toActive = _activeLocation(locations, edge.toId, tick);
    if (!fromActive || !toActive) {
      issues.add(
        TemporalIssue(
          code: TemporalIssueCode.routeEndpointExpired,
          message:
              "route '$edgeId' references node that is not active at "
              "tick $tick (from=$edge.fromId active=$fromActive, "
              "to=$edge.toId active=$toActive)",
          edgeId: edgeId,
        ),
      );
    }
    return TemporalRouteResult(
      edgeId: edgeId,
      tick: tick,
      isValid: issues.isEmpty,
      issues: List.unmodifiable(issues),
      sourceRevision: edge.source.revision,
      sourceReason: edge.source.reason,
    );
  }

  static bool _activeLocation(
    List<TemporalLocation> locations,
    String id,
    int tick,
  ) {
    for (final loc in locations) {
      if (loc.id == id) return loc.isActiveAt(tick);
    }
    return false;
  }

  TemporalSceneResult validateScene({
    required String branchId,
    required int tick,
    required List<SceneLocationReference> references,
  }) {
    final locResults = <TemporalLocationResult>[];
    final routeResults = <TemporalRouteResult>[];
    final seenEdges = <String>{};
    for (final ref in references) {
      locResults.add(
        validateLocation(
          branchId: branchId,
          locationId: ref.locationId,
          tick: tick,
          suppliedName: ref.suppliedName,
        ),
      );
      if (ref.edgeId != null && seenEdges.add(ref.edgeId!)) {
        routeResults.add(
          validateRoute(branchId: branchId, edgeId: ref.edgeId!, tick: tick),
        );
      }
    }
    final all = <TemporalIssue>[];
    for (final r in locResults) {
      all.addAll(r.issues);
    }
    for (final r in routeResults) {
      all.addAll(r.issues);
    }
    return TemporalSceneResult(
      tick: tick,
      locationResults: List.unmodifiable(locResults),
      routeResults: List.unmodifiable(routeResults),
      overallIssues: List.unmodifiable(all),
      allValid: all.isEmpty,
    );
  }
}
