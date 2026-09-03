// Sprint 110.22 - Temporal Location & Route Validation (RED tests).
//
// Domain-only atop ValidityRange (110.17), RouteNetwork (110.9), and
// ResultOrigin (110.7). No persistence, UI, wall clock, locale, or
// random input.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/genealogy_relationship_rules.dart'
    show ValidityRange;
import 'package:void_scriptor/features/world_logic/domain/route_network.dart'
    show RouteSource, defaultRouteSource;
import 'package:void_scriptor/features/world_logic/domain/temporal_location_route_validation.dart';

void main() {
  group('LocationRecord validity (location_validity)', () {
    test('location exists when ValidityRange covers the tick', () {
      final reg = LocationRegistry()
        ..upsert(
          const LocationRecord(
            id: 'loc.capital',
            names: [LocationName(value: 'Old Capital', validity: null)],
            validity: ValidityRange(fromTick: 0, toTick: 100),
          ),
        );
      expect(reg.locationAt('loc.capital', 50)?.id, 'loc.capital');
      expect(reg.locationAt('loc.capital', 100)?.id, 'loc.capital');
    });
    test('location returns null before its fromTick', () {
      final reg = LocationRegistry()
        ..upsert(
          const LocationRecord(
            id: 'loc.future',
            names: [LocationName(value: 'New City', validity: null)],
            validity: ValidityRange(fromTick: 200, toTick: 500),
          ),
        );
      expect(reg.locationAt('loc.future', 50), isNull);
      expect(reg.locationAt('loc.future', 199), isNull);
      expect(reg.locationAt('loc.future', 200)?.id, 'loc.future');
    });
    test('location returns null after its toTick', () {
      final reg = LocationRegistry()
        ..upsert(
          const LocationRecord(
            id: 'loc.collapsed',
            names: [LocationName(value: 'Ruins', validity: null)],
            validity: ValidityRange(fromTick: 0, toTick: 80),
          ),
        );
      expect(reg.locationAt('loc.collapsed', 80)?.id, 'loc.collapsed');
      expect(reg.locationAt('loc.collapsed', 81), isNull);
      expect(reg.locationAt('loc.collapsed', 999), isNull);
    });
    test('null toTick keeps the location open-ended', () {
      final reg = LocationRegistry()
        ..upsert(
          const LocationRecord(
            id: 'loc.eternal',
            names: [LocationName(value: 'Eternal', validity: null)],
            validity: ValidityRange(fromTick: 10, toTick: null),
          ),
        );
      expect(reg.locationAt('loc.eternal', 10)?.id, 'loc.eternal');
      expect(reg.locationAt('loc.eternal', 99999)?.id, 'loc.eternal');
    });
  });
  group('Name at time (name_at_time)', () {
    test('nameAtTick returns the name whose validity is active', () {
      final reg = LocationRegistry()
        ..upsert(
          const LocationRecord(
            id: 'loc.renamed',
            names: [
              LocationName(
                value: 'Old Name',
                validity: ValidityRange(fromTick: 0, toTick: 100),
              ),
              LocationName(
                value: 'New Name',
                validity: ValidityRange(fromTick: 100, toTick: null),
              ),
            ],
            validity: ValidityRange(fromTick: 0, toTick: null),
          ),
        );
      expect(reg.nameAtTick('loc.renamed', 0), 'Old Name');
      expect(reg.nameAtTick('loc.renamed', 50), 'Old Name');
      expect(reg.nameAtTick('loc.renamed', 100), 'New Name');
      expect(reg.nameAtTick('loc.renamed', 99999), 'New Name');
    });
    test('nameAtTick returns null when location does not exist at tick', () {
      final reg = LocationRegistry()
        ..upsert(
          const LocationRecord(
            id: 'loc.collapsed',
            names: [LocationName(value: 'Ruins', validity: null)],
            validity: ValidityRange(fromTick: 0, toTick: 80),
          ),
        );
      expect(reg.nameAtTick('loc.collapsed', 81), isNull);
    });
    test('nameAtTick falls back to the only entry when no other is active', () {
      final reg = LocationRegistry()
        ..upsert(
          const LocationRecord(
            id: 'loc.solo',
            names: [LocationName(value: 'Solo', validity: null)],
            validity: ValidityRange(fromTick: 0, toTick: null),
          ),
        );
      expect(reg.nameAtTick('loc.solo', 1), 'Solo');
    });
  });
  group('Route at time (route_at_time)', () {
    test('RouteEdgeLike.isActiveAt honours the validity window', () {
      const edge = RouteEdgeLike(
        id: 'edge.north',
        fromId: 'a',
        toId: 'b',
        distance: 12,
        validity: ValidityRange(fromTick: 10, toTick: 100),
      );
      expect(edge.isActiveAt(5), isFalse);
      expect(edge.isActiveAt(10), isTrue);
      expect(edge.isActiveAt(99), isTrue);
      expect(edge.isActiveAt(100), isTrue);
      expect(edge.isActiveAt(101), isFalse);
    });
    test(
      'RouteRegistry.edgeAtTick resolves active edge and null otherwise',
      () {
        final reg = RouteRegistry()
          ..upsert(
            const RouteEdgeLike(
              id: 'edge.legacy',
              fromId: 'a',
              toId: 'b',
              distance: 8,
              validity: ValidityRange(fromTick: 0, toTick: 50),
            ),
          );
        expect(reg.edgeAtTick('edge.legacy', 25)?.id, 'edge.legacy');
        expect(reg.edgeAtTick('edge.legacy', 51), isNull);
        expect(reg.edgeAtTick('edge.missing', 25), isNull);
      },
    );
  });
  group('Scene warning (scene_warning)', () {
    test('validateSceneRequest reports missing location', () {
      final locations = LocationRegistry();
      final routes = RouteRegistry();
      final result = validateSceneRequest(
        tick: 50,
        scene: const SceneRequest(
          locationIds: ['loc.ghost'],
          routeIds: ['edge.north'],
        ),
        locations: locations,
        routes: routes,
      );
      expect(result.findings, isNotEmpty);
      expect(
        result.findings
            .where((f) => f.code == 'location_unknown_or_out_of_range')
            .length,
        1,
      );
    });
    test('validateSceneRequest reports route references unknown location', () {
      final locations = LocationRegistry()
        ..upsert(
          const LocationRecord(
            id: 'loc.capital',
            names: [LocationName(value: 'Capital', validity: null)],
            validity: ValidityRange(fromTick: 0, toTick: null),
          ),
        );
      final routes = RouteRegistry()
        ..upsert(
          const RouteEdgeLike(
            id: 'edge.north',
            fromId: 'a',
            toId: 'b',
            distance: 10,
            validity: ValidityRange(fromTick: 0, toTick: null),
          ),
        );
      final result = validateSceneRequest(
        tick: 50,
        scene: const SceneRequest(
          locationIds: ['loc.capital'],
          routeIds: ['edge.north'],
        ),
        locations: locations,
        routes: routes,
      );
      expect(
        result.findings
            .where((f) => f.code == 'route_references_unknown_location')
            .length,
        1,
      );
    });
    test('validateSceneRequest reports a clean scene with no findings', () {
      final locations = LocationRegistry()
        ..upsert(
          const LocationRecord(
            id: 'loc.a',
            names: [LocationName(value: 'A', validity: null)],
            validity: ValidityRange(fromTick: 0, toTick: null),
          ),
        )
        ..upsert(
          const LocationRecord(
            id: 'loc.b',
            names: [LocationName(value: 'B', validity: null)],
            validity: ValidityRange(fromTick: 0, toTick: null),
          ),
        );
      final routes = RouteRegistry()
        ..upsert(
          const RouteEdgeLike(
            id: 'edge.ab',
            fromId: 'loc.a',
            toId: 'loc.b',
            distance: 10,
            validity: ValidityRange(fromTick: 0, toTick: null),
          ),
        );
      final result = validateSceneRequest(
        tick: 50,
        scene: const SceneRequest(
          locationIds: ['loc.a', 'loc.b'],
          routeIds: ['edge.ab'],
        ),
        locations: locations,
        routes: routes,
      );
      expect(result.findings, isEmpty);
    });
    test('validateSceneRequest reports route out of validity window', () {
      final locations = LocationRegistry()
        ..upsert(
          const LocationRecord(
            id: 'loc.a',
            names: [LocationName(value: 'A', validity: null)],
            validity: ValidityRange(fromTick: 0, toTick: null),
          ),
        )
        ..upsert(
          const LocationRecord(
            id: 'loc.b',
            names: [LocationName(value: 'B', validity: null)],
            validity: ValidityRange(fromTick: 0, toTick: null),
          ),
        );
      final routes = RouteRegistry()
        ..upsert(
          const RouteEdgeLike(
            id: 'edge.collapsed',
            fromId: 'loc.a',
            toId: 'loc.b',
            distance: 10,
            validity: ValidityRange(fromTick: 0, toTick: 30),
          ),
        );
      final result = validateSceneRequest(
        tick: 50,
        scene: const SceneRequest(
          locationIds: ['loc.a', 'loc.b'],
          routeIds: ['edge.collapsed'],
        ),
        locations: locations,
        routes: routes,
      );
      expect(
        result.findings.where((f) => f.code == 'route_out_of_validity').length,
        1,
      );
    });
  });
  group('Source evidence (source_evidence)', () {
    test('LocationRecord carries an explicit RouteSource', () {
      const src = RouteSource(
        revision: 'world.chapter-3',
        reason: 'introduced in chapter 3',
      );
      final reg = LocationRegistry()
        ..upsert(
          const LocationRecord(
            id: 'loc.sourced',
            names: [LocationName(value: 'Sourced', validity: null)],
            validity: ValidityRange(fromTick: 0, toTick: null),
            source: src,
          ),
        );
      final rec = reg.locationAt('loc.sourced', 0);
      expect(rec?.source.revision, 'world.chapter-3');
    });
    test('RouteEdgeLike default source falls back to defaultRouteSource', () {
      final reg = RouteRegistry()
        ..upsert(
          const RouteEdgeLike(
            id: 'edge.default',
            fromId: 'a',
            toId: 'b',
            distance: 1,
            validity: ValidityRange(fromTick: 0, toTick: null),
          ),
        );
      final rec = reg.edgeAtTick('edge.default', 0);
      expect(rec?.source.revision, defaultRouteSource.revision);
    });
    test(
      'TemporalValidationFinding includes the evidence id that triggered it',
      () {
        const src = RouteSource(revision: 'world.test', reason: 'unit test');
        final locations = LocationRegistry()
          ..upsert(
            const LocationRecord(
              id: 'loc.a',
              names: [LocationName(value: 'A', validity: null)],
              validity: ValidityRange(fromTick: 0, toTick: null),
              source: src,
            ),
          );
        final routes = RouteRegistry();
        final result = validateSceneRequest(
          tick: 50,
          scene: const SceneRequest(
            locationIds: ['loc.a', 'loc.ghost'],
            routeIds: <String>[],
          ),
          locations: locations,
          routes: routes,
        );
        final finding = result.findings.firstWhere(
          (f) => f.code == 'location_unknown_or_out_of_range',
        );
        expect(finding.evidenceId, 'loc.ghost');
      },
    );
  });
}
