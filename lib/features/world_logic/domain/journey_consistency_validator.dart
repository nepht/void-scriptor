/// Sprint 110.12 - Journey Consistency Validation.
///
/// Deterministic, domain-only validator that reports warnings about a planned
/// journey (route existence, segment contiguity, time feasibility, supply
/// sufficiency, route closures, and explainable diagnostics). No persistence,
/// UI, hidden wall clock, locale, or random input.
library;

import "route_network.dart";
import "travel_mode_profiles.dart";
import "travel_supplies.dart";

enum JourneyWarningSeverity { info, warning, error }

class JourneyWarningCodes {
  const JourneyWarningCodes._();
  static const String sceneRouteCheck = "scene_route_check";
  static const String timeFeasibility = "time_feasibility";
  static const String supplyWarning = "supply_warning";
  static const String routeClosureAwareness = "route_closure_awareness";
  static const String explainWarning = "explain_warning";
}

class JourneyWarning {
  const JourneyWarning({
    required this.code,
    required this.message,
    this.severity = JourneyWarningSeverity.warning,
    this.edgeId,
    this.segmentIndex,
  });

  final String code;
  final String message;
  final JourneyWarningSeverity severity;
  final String? edgeId;
  final int? segmentIndex;

  @override
  bool operator ==(Object other) =>
      other is JourneyWarning &&
      other.code == code &&
      other.message == message &&
      other.severity == severity &&
      other.edgeId == edgeId &&
      other.segmentIndex == segmentIndex;

  @override
  int get hashCode =>
      Object.hash(code, message, severity, edgeId, segmentIndex);
}

class JourneySpec {
  const JourneySpec({
    required this.graph,
    required this.originId,
    required this.destinationId,
    required this.segments,
    required this.mode,
    required this.season,
    required this.partySize,
    required this.loadout,
    required this.claimedDurationHours,
    required this.restHours,
  });

  final RouteGraph graph;
  final String originId;
  final String destinationId;
  final List<String> segments;
  final TravelModeProfile mode;
  final Season season;
  final int partySize;
  final SupplyLoadout loadout;
  final double claimedDurationHours;
  final double restHours;
}

class JourneyValidationResult {
  const JourneyValidationResult({
    required this.warnings,
    required this.computedTravelHours,
    required this.computedDistance,
  });

  final List<JourneyWarning> warnings;
  final double computedTravelHours;
  final double computedDistance;
}

class JourneyConsistencyValidator {
  const JourneyConsistencyValidator();

  JourneyValidationResult validate({required JourneySpec spec}) {
    final warnings = <JourneyWarning>[];
    final segments = spec.segments;

    if (segments.isEmpty) {
      warnings.add(
        const JourneyWarning(
          code: JourneyWarningCodes.sceneRouteCheck,
          message: "journey has no segments",
          severity: JourneyWarningSeverity.error,
        ),
      );
      return JourneyValidationResult(
        warnings: List.unmodifiable(warnings),
        computedTravelHours: 0.0,
        computedDistance: 0.0,
      );
    }

    final originKnown = spec.graph.nodes.containsKey(spec.originId);
    final destKnown = spec.graph.nodes.containsKey(spec.destinationId);
    if (!originKnown) {
      warnings.add(
        JourneyWarning(
          code: JourneyWarningCodes.sceneRouteCheck,
          message: "origin node ${spec.originId} is not in the route graph",
          severity: JourneyWarningSeverity.error,
        ),
      );
    }
    if (!destKnown) {
      warnings.add(
        JourneyWarning(
          code: JourneyWarningCodes.sceneRouteCheck,
          message:
              "destination node ${spec.destinationId} is not in the route graph",
          severity: JourneyWarningSeverity.error,
        ),
      );
    }

    String? expectedFrom = originKnown ? spec.originId : null;
    var distance = 0.0;
    var blockedFound = false;
    for (var i = 0; i < segments.length; i++) {
      final segId = segments[i];
      RouteEdge? edge;
      for (final e in spec.graph.edges) {
        if (e.id == segId) {
          edge = e;
          break;
        }
      }
      if (edge == null) {
        warnings.add(
          JourneyWarning(
            code: JourneyWarningCodes.sceneRouteCheck,
            message: "segment $segId is not in the route graph",
            severity: JourneyWarningSeverity.error,
            edgeId: segId,
            segmentIndex: i,
          ),
        );
        expectedFrom = null;
        continue;
      }
      if (expectedFrom != null && edge.fromId != expectedFrom) {
        warnings.add(
          JourneyWarning(
            code: JourneyWarningCodes.sceneRouteCheck,
            message:
                "segment $segId departs from ${edge.fromId} but previous segment arrives at $expectedFrom",
            severity: JourneyWarningSeverity.error,
            edgeId: segId,
            segmentIndex: i,
          ),
        );
      }
      expectedFrom = edge.toId;
      distance += edge.distance;
      if (edge.blocked != null) {
        blockedFound = true;
        warnings.add(
          JourneyWarning(
            code: JourneyWarningCodes.routeClosureAwareness,
            message: "segment $segId is blocked: ${edge.blocked!.reason}",
            severity: JourneyWarningSeverity.error,
            edgeId: segId,
            segmentIndex: i,
          ),
        );
      }
    }
    if (originKnown &&
        destKnown &&
        expectedFrom != null &&
        expectedFrom != spec.destinationId) {
      warnings.add(
        JourneyWarning(
          code: JourneyWarningCodes.sceneRouteCheck,
          message:
              "last segment arrives at $expectedFrom but destination is ${spec.destinationId}",
          severity: JourneyWarningSeverity.error,
        ),
      );
    }

    if (blockedFound) {
      return JourneyValidationResult(
        warnings: List.unmodifiable(warnings),
        computedTravelHours: 0.0,
        computedDistance: distance,
      );
    }

    final hours = _computeTravelHours(spec: spec, distance: distance);
    final lowerBound = hours + spec.restHours;
    if (lowerBound.isFinite && spec.claimedDurationHours + 1e-9 < lowerBound) {
      warnings.add(
        JourneyWarning(
          code: JourneyWarningCodes.timeFeasibility,
          message:
              "claimed duration ${spec.claimedDurationHours.toStringAsFixed(2)}h is below minimum ${lowerBound.toStringAsFixed(2)}h (travel ${hours.toStringAsFixed(2)}h + rest ${spec.restHours.toStringAsFixed(2)}h)",
          severity: JourneyWarningSeverity.warning,
        ),
      );
    }

    SupplyPlanResult supplyResult;
    try {
      supplyResult = const SupplyPlanner().plan(
        graph: spec.graph,
        segments: segments,
        mode: spec.mode,
        season: spec.season,
        partySize: spec.partySize,
        loadout: spec.loadout,
      );
    } on RouteBlockedException {
      return JourneyValidationResult(
        warnings: List.unmodifiable(warnings),
        computedTravelHours: hours,
        computedDistance: distance,
      );
    }
    if (supplyResult.status == SupplyStatus.insufficient) {
      for (final s in supplyResult.shortages) {
        warnings.add(
          JourneyWarning(
            code: JourneyWarningCodes.supplyWarning,
            message:
                "supply shortage for ${s.kind.name}: short by ${s.shortBy.toStringAsFixed(2)} (${s.reasonCode})",
            severity: JourneyWarningSeverity.warning,
          ),
        );
      }
    }

    if (warnings.isNotEmpty) {
      warnings.add(
        JourneyWarning(
          code: JourneyWarningCodes.explainWarning,
          message:
              "journey has ${warnings.length.toString()} finding(s); review codes above",
          severity: JourneyWarningSeverity.info,
        ),
      );
    }

    return JourneyValidationResult(
      warnings: List.unmodifiable(warnings),
      computedTravelHours: hours,
      computedDistance: distance,
    );
  }

  double _computeTravelHours({
    required JourneySpec spec,
    required double distance,
  }) {
    if (distance <= 0) return 0.0;
    final terrainKind = _mapTerrain(spec);
    if (!spec.mode.canTraverse(terrainKind)) {
      return double.infinity;
    }
    var speed = spec.mode.baseSpeedKmPerHour;
    final seasonMult = _seasonAccessMultiplier(spec.season);
    speed = speed / seasonMult;
    return distance / speed;
  }

  TerrainKind _mapTerrain(JourneySpec spec) {
    if (spec.segments.isEmpty) return TerrainKind.plain;
    final segId = spec.segments.first;
    for (final e in spec.graph.edges) {
      if (e.id == segId) {
        switch (e.terrain) {
          case Terrain.plain:
            return TerrainKind.plain;
          case Terrain.forest:
            return TerrainKind.forest;
          case Terrain.mountain:
            return TerrainKind.mountain;
          case Terrain.desert:
            return TerrainKind.desert;
          case Terrain.swamp:
            return TerrainKind.swamp;
        }
      }
    }
    return TerrainKind.plain;
  }

  double _seasonAccessMultiplier(Season s) {
    switch (s) {
      case Season.spring:
        return 1.0;
      case Season.summer:
        return 1.0;
      case Season.autumn:
        return 1.1;
      case Season.winter:
        return 1.4;
    }
  }
}
