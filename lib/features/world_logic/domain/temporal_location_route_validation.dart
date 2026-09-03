/// Sprint 110.22 - Temporal Location & Route Validation.
///
/// Domain-only validator atop ValidityRange (110.17), RouteNetwork
/// (110.9), and ResultOrigin (110.7). Surfaces a `LocationRegistry`
/// for places with temporal existence, a `RouteRegistry` for routes
/// that may be opened, closed, or ruined, and `validateSceneRequest`
/// which produces a list of `TemporalValidationFinding` for an ad-hoc
/// scene reference set at a given tick.
///
/// Deterministic, no persistence, UI, wall clock, locale, or random
/// input.
library;

import 'genealogy_relationship_rules.dart' show ValidityRange;
import 'route_network.dart' show RouteSource, defaultRouteSource;

class LocationName {
  const LocationName({required this.value, this.validity});

  final String value;
  final ValidityRange? validity;
}

class LocationRecord {
  const LocationRecord({
    required this.id,
    required this.names,
    required this.validity,
    this.source = defaultRouteSource,
  });

  final String id;
  final List<LocationName> names;
  final ValidityRange validity;
  final RouteSource source;

  bool isActiveAt(int tick) {
    if (validity.fromTick > tick) return false;
    final to = validity.toTick;
    if (to == null) return true;
    return tick <= to;
  }

  LocationName? nameAtTick(int tick) {
    LocationName? best;
    int bestFrom = -1;
    for (final n in names) {
      final v = n.validity;
      final to = v?.toTick;
      final active = v == null
          ? true
          : (v.fromTick <= tick && (to == null || tick <= to));
      if (!active) continue;
      final from = v?.fromTick ?? 0;
      if (from >= bestFrom) {
        best = n;
        bestFrom = from;
      }
    }
    return best;
  }
}

class LocationRegistry {
  final Map<String, LocationRecord> _records = <String, LocationRecord>{};

  void upsert(LocationRecord record) {
    if (record.id.isEmpty) {
      throw ArgumentError.value(record.id, 'id', 'location id cannot be empty');
    }
    _records[record.id] = record;
  }

  LocationRecord? locationAt(String id, int tick) {
    final r = _records[id];
    if (r == null) return null;
    return r.isActiveAt(tick) ? r : null;
  }

  String? nameAtTick(String id, int tick) {
    final rec = locationAt(id, tick);
    if (rec == null) return null;
    return rec.nameAtTick(tick)?.value;
  }
}

class RouteEdgeLike {
  const RouteEdgeLike({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.distance,
    required this.validity,
    this.source = defaultRouteSource,
  });

  final String id;
  final String fromId;
  final String toId;
  final int distance;
  final ValidityRange validity;
  final RouteSource source;

  bool isActiveAt(int tick) {
    if (validity.fromTick > tick) return false;
    final to = validity.toTick;
    if (to == null) return true;
    return tick <= to;
  }
}

class RouteRegistry {
  final Map<String, RouteEdgeLike> _edges = <String, RouteEdgeLike>{};

  void upsert(RouteEdgeLike edge) {
    if (edge.id.isEmpty) {
      throw ArgumentError.value(edge.id, 'id', 'edge id cannot be empty');
    }
    _edges[edge.id] = edge;
  }

  RouteEdgeLike? edgeAtTick(String id, int tick) {
    final e = _edges[id];
    if (e == null) return null;
    return e.isActiveAt(tick) ? e : null;
  }
}

class SceneRequest {
  const SceneRequest({required this.locationIds, required this.routeIds});

  final List<String> locationIds;
  final List<String> routeIds;
}

class TemporalValidationFinding {
  const TemporalValidationFinding({
    required this.code,
    required this.evidenceId,
    required this.message,
  });

  final String code;
  final String evidenceId;
  final String message;
}

class TemporalValidationResult {
  const TemporalValidationResult({required this.findings});

  final List<TemporalValidationFinding> findings;
}

TemporalValidationResult validateSceneRequest({
  required int tick,
  required SceneRequest scene,
  required LocationRegistry locations,
  required RouteRegistry routes,
}) {
  final findings = <TemporalValidationFinding>[];

  for (final locId in scene.locationIds) {
    final rec = locations.locationAt(locId, tick);
    if (rec == null) {
      findings.add(
        TemporalValidationFinding(
          code: 'location_unknown_or_out_of_range',
          evidenceId: locId,
          message: 'Location $locId is unknown or not active at tick=$tick',
        ),
      );
    }
  }

  for (final routeId in scene.routeIds) {
    final edge = routes.edgeAtTick(routeId, tick);
    if (edge == null) {
      findings.add(
        TemporalValidationFinding(
          code: 'route_out_of_validity',
          evidenceId: routeId,
          message: 'Route $routeId is unknown or not active at tick=$tick',
        ),
      );
      continue;
    }
    if (locations.locationAt(edge.fromId, tick) == null ||
        locations.locationAt(edge.toId, tick) == null) {
      findings.add(
        TemporalValidationFinding(
          code: 'route_references_unknown_location',
          evidenceId: routeId,
          message:
              'Route $routeId references a location that is unknown at tick=$tick',
        ),
      );
    }
  }

  return TemporalValidationResult(findings: List.unmodifiable(findings));
}
