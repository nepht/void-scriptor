// Sprint 110.22 - Temporal Location & Route Validation.
//
// Domain-only contract that joins TemporalMapState (110.20) with
// RouteGraph (110.9). Rejects references to a location that does
// not exist at the requested tick, returns the canonical name
// active at that tick, verifies that referenced routes are usable
// at that tick, and surfaces scene-level warnings. No persistence,
// UI, wall clock, locale, or network. Deterministic.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/route_network.dart';
import 'package:void_scriptor/features/world_logic/domain/temporal_location_route_validator.dart';
import 'package:void_scriptor/features/world_logic/domain/temporal_map_state.dart';

void main() {
  group('TemporalLocationRouteValidator - location_validity', () {
    test('valid reference to an active location is accepted', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(
            id: 'loc-qowner',
            name: 'Qowner',
            validFrom: 0,
          ),
        ],
      );
      final validator = TemporalLocationRouteValidator(mapState: map);
      final result = validator.validateLocation(
        branchId: 'prime',
        locationId: 'loc-qowner',
        tick: 0,
      );
      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('unknown location id is rejected with unknown_location issue', () {
      final map = TemporalMapState(branchId: 'prime', locations: const []);
      final validator = TemporalLocationRouteValidator(mapState: map);
      final result = validator.validateLocation(
        branchId: 'prime',
        locationId: 'ghost',
        tick: 0,
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) => i.code == TemporalIssueCode.unknownLocation),
        isTrue,
      );
      expect(result.issues.first.message, contains('ghost'));
    });

    test('reference before validFrom is rejected with not_yet_active', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(
            id: 'loc-new',
            name: 'NewTown',
            validFrom: 100,
          ),
        ],
      );
      final validator = TemporalLocationRouteValidator(mapState: map);
      final result = validator.validateLocation(
        branchId: 'prime',
        locationId: 'loc-new',
        tick: 50,
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues.any(
          (i) => i.code == TemporalIssueCode.locationNotYetActive,
        ),
        isTrue,
      );
    });

    test('reference after validUntil is rejected with expired', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(
            id: 'loc-old',
            name: 'Ruins',
            validFrom: 0,
            validUntil: 10,
          ),
        ],
      );
      final validator = TemporalLocationRouteValidator(mapState: map);
      final result = validator.validateLocation(
        branchId: 'prime',
        locationId: 'loc-old',
        tick: 20,
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) => i.code == TemporalIssueCode.locationExpired),
        isTrue,
      );
    });

    test('hidden location is reported with hidden_status', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(
            id: 'loc-secret',
            name: 'Secret',
            validFrom: 0,
            statusHistory: [
              StatusChange.validated(
                id: 'sc-1',
                validFrom: 0,
                status: LocationStatus.hidden,
              ),
            ],
          ),
        ],
      );
      final validator = TemporalLocationRouteValidator(mapState: map);
      final result = validator.validateLocation(
        branchId: 'prime',
        locationId: 'loc-secret',
        tick: 5,
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) => i.code == TemporalIssueCode.locationHidden),
        isTrue,
      );
    });
  });

  group('TemporalLocationRouteValidator - name_at_time', () {
    test('returns canonical name for the requested tick', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(
            id: 'loc-capital',
            name: 'Old Capital',
            validFrom: 0,
          ),
        ],
      );
      final validator = TemporalLocationRouteValidator(mapState: map);
      final name = validator.nameAt(
        branchId: 'prime',
        locationId: 'loc-capital',
        tick: 5,
      );
      expect(name, 'Old Capital');
    });

    test('supplied name that differs from canonical name is flagged', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(
            id: 'loc-capital',
            name: 'New Capital',
            validFrom: 0,
          ),
        ],
      );
      final validator = TemporalLocationRouteValidator(mapState: map);
      final result = validator.validateLocation(
        branchId: 'prime',
        locationId: 'loc-capital',
        tick: 5,
        suppliedName: 'Old Capital',
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) => i.code == TemporalIssueCode.nameMismatch),
        isTrue,
      );
    });

    test('supplying matching canonical name passes name_at_time', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(
            id: 'loc-capital',
            name: 'New Capital',
            validFrom: 0,
          ),
        ],
      );
      final validator = TemporalLocationRouteValidator(mapState: map);
      final result = validator.validateLocation(
        branchId: 'prime',
        locationId: 'loc-capital',
        tick: 5,
        suppliedName: 'New Capital',
      );
      expect(result.isValid, isTrue);
    });

    test('querying name for an unknown location returns null', () {
      final map = TemporalMapState(branchId: 'prime', locations: const []);
      final validator = TemporalLocationRouteValidator(mapState: map);
      final name = validator.nameAt(
        branchId: 'prime',
        locationId: 'ghost',
        tick: 0,
      );
      expect(name, isNull);
    });
  });

  group('TemporalLocationRouteValidator - route_at_time', () {
    test('valid route referencing existing nodes is accepted', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(id: 'a', name: 'A', validFrom: 0),
          TemporalLocation.validated(id: 'b', name: 'B', validFrom: 0),
        ],
      );
      final graph = RouteGraph(
        nodes: const {
          'a': RouteNode(id: 'a', name: 'A'),
          'b': RouteNode(id: 'b', name: 'B'),
        },
        edges: [
          RouteEdge(
            id: 'e1',
            fromId: 'a',
            toId: 'b',
            distance: 10,
            source: const RouteSource(revision: 'r1', reason: 'canon'),
          ),
        ],
      );
      final validator = TemporalLocationRouteValidator(
        mapState: map,
        routeGraph: graph,
      );
      final result = validator.validateRoute(
        branchId: 'prime',
        edgeId: 'e1',
        tick: 5,
      );
      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('blocked route is rejected with route_blocked', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(id: 'a', name: 'A', validFrom: 0),
          TemporalLocation.validated(id: 'b', name: 'B', validFrom: 0),
        ],
      );
      final graph = RouteGraph(
        nodes: const {
          'a': RouteNode(id: 'a', name: 'A'),
          'b': RouteNode(id: 'b', name: 'B'),
        },
        edges: [
          RouteEdge(
            id: 'e1',
            fromId: 'a',
            toId: 'b',
            distance: 10,
            blocked: const BlockedRoute(reason: 'flood'),
          ),
        ],
      );
      final validator = TemporalLocationRouteValidator(
        mapState: map,
        routeGraph: graph,
      );
      final result = validator.validateRoute(
        branchId: 'prime',
        edgeId: 'e1',
        tick: 5,
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) => i.code == TemporalIssueCode.routeBlocked),
        isTrue,
      );
      expect(result.issues.first.message, contains('flood'));
    });

    test('route referencing unknown node is rejected', () {
      final map = TemporalMapState(branchId: 'prime', locations: const []);
      final graph = RouteGraph(
        nodes: const {
          'a': RouteNode(id: 'a', name: 'A'),
          'b': RouteNode(id: 'b', name: 'B'),
        },
        edges: [RouteEdge(id: 'e1', fromId: 'a', toId: 'b', distance: 10)],
      );
      final validator = TemporalLocationRouteValidator(
        mapState: map,
        routeGraph: graph,
      );
      final result = validator.validateRoute(
        branchId: 'prime',
        edgeId: 'e1',
        tick: 0,
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues.any(
          (i) => i.code == TemporalIssueCode.routeEndpointExpired,
        ),
        isTrue,
      );
    });

    test('unknown edge id is rejected with unknown_route', () {
      final map = TemporalMapState(branchId: 'prime', locations: const []);
      final graph = RouteGraph(
        nodes: const {'a': RouteNode(id: 'a', name: 'A')},
        edges: const [],
      );
      final validator = TemporalLocationRouteValidator(
        mapState: map,
        routeGraph: graph,
      );
      final result = validator.validateRoute(
        branchId: 'prime',
        edgeId: 'ghost-edge',
        tick: 0,
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) => i.code == TemporalIssueCode.unknownRoute),
        isTrue,
      );
    });

    test('route whose endpoints are expired at tick is rejected', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(
            id: 'a',
            name: 'A',
            validFrom: 0,
            validUntil: 10,
          ),
          TemporalLocation.validated(id: 'b', name: 'B', validFrom: 0),
        ],
      );
      final graph = RouteGraph(
        nodes: const {
          'a': RouteNode(id: 'a', name: 'A'),
          'b': RouteNode(id: 'b', name: 'B'),
        },
        edges: [RouteEdge(id: 'e1', fromId: 'a', toId: 'b', distance: 5)],
      );
      final validator = TemporalLocationRouteValidator(
        mapState: map,
        routeGraph: graph,
      );
      final result = validator.validateRoute(
        branchId: 'prime',
        edgeId: 'e1',
        tick: 20,
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues.any(
          (i) => i.code == TemporalIssueCode.routeEndpointExpired,
        ),
        isTrue,
      );
    });
  });

  group('TemporalLocationRouteValidator - scene_warning', () {
    test('validateScene aggregates per-reference issues', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(id: 'a', name: 'A', validFrom: 0),
          TemporalLocation.validated(id: 'b', name: 'B', validFrom: 0),
        ],
      );
      final graph = RouteGraph(
        nodes: const {
          'a': RouteNode(id: 'a', name: 'A'),
          'b': RouteNode(id: 'b', name: 'B'),
        },
        edges: [RouteEdge(id: 'e1', fromId: 'a', toId: 'b', distance: 5)],
      );
      final validator = TemporalLocationRouteValidator(
        mapState: map,
        routeGraph: graph,
      );
      final sceneResult = validator.validateScene(
        branchId: 'prime',
        tick: 0,
        references: const [
          SceneLocationReference(locationId: 'a', suppliedName: 'A'),
          SceneLocationReference(
            locationId: 'ghost',
            suppliedName: 'Ghost',
            edgeId: 'ghost-edge',
          ),
        ],
      );
      expect(sceneResult.locationResults, hasLength(2));
      expect(sceneResult.routeResults, hasLength(1));
      expect(sceneResult.overallIssues, isNotEmpty);
      expect(sceneResult.allValid, isFalse);
    });

    test('clean scene returns allValid=true and empty issue list', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(id: 'a', name: 'A', validFrom: 0),
          TemporalLocation.validated(id: 'b', name: 'B', validFrom: 0),
        ],
      );
      final graph = RouteGraph(
        nodes: const {
          'a': RouteNode(id: 'a', name: 'A'),
          'b': RouteNode(id: 'b', name: 'B'),
        },
        edges: [RouteEdge(id: 'e1', fromId: 'a', toId: 'b', distance: 5)],
      );
      final validator = TemporalLocationRouteValidator(
        mapState: map,
        routeGraph: graph,
      );
      final sceneResult = validator.validateScene(
        branchId: 'prime',
        tick: 0,
        references: const [
          SceneLocationReference(locationId: 'a', suppliedName: 'A'),
          SceneLocationReference(
            locationId: 'b',
            suppliedName: 'B',
            edgeId: 'e1',
          ),
        ],
      );
      expect(sceneResult.allValid, isTrue);
      expect(sceneResult.overallIssues, isEmpty);
    });

    test('empty reference list returns allValid=true', () {
      final map = TemporalMapState(branchId: 'prime', locations: const []);
      final validator = TemporalLocationRouteValidator(mapState: map);
      final sceneResult = validator.validateScene(
        branchId: 'prime',
        tick: 0,
        references: const [],
      );
      expect(sceneResult.allValid, isTrue);
      expect(sceneResult.overallIssues, isEmpty);
    });
  });

  group('TemporalLocationRouteValidator - source_evidence', () {
    test('route result includes source revision and reason', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(id: 'a', name: 'A', validFrom: 0),
          TemporalLocation.validated(id: 'b', name: 'B', validFrom: 0),
        ],
      );
      final graph = RouteGraph(
        nodes: const {
          'a': RouteNode(id: 'a', name: 'A'),
          'b': RouteNode(id: 'b', name: 'B'),
        },
        edges: [
          RouteEdge(
            id: 'e1',
            fromId: 'a',
            toId: 'b',
            distance: 5,
            source: const RouteSource(
              revision: 'r17',
              reason: 'surveyed 2026-01',
            ),
          ),
        ],
      );
      final validator = TemporalLocationRouteValidator(
        mapState: map,
        routeGraph: graph,
      );
      final result = validator.validateRoute(
        branchId: 'prime',
        edgeId: 'e1',
        tick: 0,
      );
      expect(result.sourceRevision, 'r17');
      expect(result.sourceReason, 'surveyed 2026-01');
    });

    test('default route source is reported when no explicit source given', () {
      final map = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(id: 'a', name: 'A', validFrom: 0),
          TemporalLocation.validated(id: 'b', name: 'B', validFrom: 0),
        ],
      );
      final graph = RouteGraph(
        nodes: const {
          'a': RouteNode(id: 'a', name: 'A'),
          'b': RouteNode(id: 'b', name: 'B'),
        },
        edges: [RouteEdge(id: 'e1', fromId: 'a', toId: 'b', distance: 5)],
      );
      final validator = TemporalLocationRouteValidator(
        mapState: map,
        routeGraph: graph,
      );
      final result = validator.validateRoute(
        branchId: 'prime',
        edgeId: 'e1',
        tick: 0,
      );
      expect(result.sourceRevision, isNotEmpty);
      expect(result.sourceReason, isNotEmpty);
    });
  });

  group('TemporalLocationRouteValidator - factory invariants', () {
    test('factory rejects null mapState', () {
      expect(
        () => TemporalLocationRouteValidator(mapState: null),
        throwsArgumentError,
      );
    });

    test('factory accepts no route graph for location-only validation', () {
      final map = TemporalMapState(branchId: 'prime', locations: const []);
      expect(
        () => TemporalLocationRouteValidator(mapState: map),
        returnsNormally,
      );
    });
  });
}
