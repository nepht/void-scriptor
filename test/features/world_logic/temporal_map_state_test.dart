// Sprint 110.20 - Temporal Map State Model.
//
// Domain-only contract for storing locations, boundaries, names, control,
// and status across time. Supports validity ranges, boundary versioning,
// control history, location status, and parallel branch awareness.
// No persistence, UI, locale, network, wall clock, or random input.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/temporal_map_state.dart';

void main() {
  group('TemporalMapState - validity_ranges', () {
    test('location with validFrom=0, validUntil=null is active at tick 0', () {
      final state = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(id: 'loc-1', name: 'Qowner', validFrom: 0),
        ],
      );
      final snapshot = state.snapshotAt(branchId: 'prime', tick: 0);
      expect(snapshot.locations, hasLength(1));
      expect(snapshot.locations.first.id, 'loc-1');
    });

    test('location with validUntil expires after that tick', () {
      final state = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(
            id: 'loc-ancient',
            name: 'Ruins',
            validFrom: 0,
            validUntil: 10,
          ),
        ],
      );
      expect(
        state.snapshotAt(branchId: 'prime', tick: 5).locations,
        hasLength(1),
      );
      expect(state.snapshotAt(branchId: 'prime', tick: 11).locations, isEmpty);
    });

    test('validFrom < 0 throws ArgumentError', () {
      expect(
        () => TemporalLocation.validated(
          id: 'loc-bad',
          name: 'Bad',
          validFrom: -1,
        ),
        throwsArgumentError,
      );
    });

    test('validUntil < validFrom throws ArgumentError', () {
      expect(
        () => TemporalLocation.validated(
          id: 'loc-bad',
          name: 'Bad',
          validFrom: 10,
          validUntil: 5,
        ),
        throwsArgumentError,
      );
    });

    test('empty id throws ArgumentError', () {
      expect(
        () => TemporalLocation.validated(id: '', name: 'X', validFrom: 0),
        throwsArgumentError,
      );
    });
  });

  group('TemporalMapState - boundary_versions', () {
    test('boundary change records supersede prior polygon at tick', () {
      final state = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(
            id: 'loc-1',
            name: 'Qowner',
            validFrom: 0,
            boundaries: [
              BoundaryVersion.validated(
                id: 'bv-1',
                validFrom: 0,
                vertices: const [
                  MapPoint(x: 0, y: 0),
                  MapPoint(x: 10, y: 0),
                  MapPoint(x: 10, y: 10),
                ],
              ),
              BoundaryVersion.validated(
                id: 'bv-2',
                validFrom: 100,
                vertices: const [
                  MapPoint(x: 0, y: 0),
                  MapPoint(x: 20, y: 0),
                  MapPoint(x: 20, y: 20),
                ],
              ),
            ],
          ),
        ],
      );

      final atTick50 = state.snapshotAt(branchId: 'prime', tick: 50);
      expect(atTick50.locations.first.activeBoundary!.id, 'bv-1');

      final atTick150 = state.snapshotAt(branchId: 'prime', tick: 150);
      expect(atTick150.locations.first.activeBoundary!.id, 'bv-2');
    });

    test('boundary with validFrom < 0 throws ArgumentError', () {
      expect(
        () => BoundaryVersion.validated(
          id: 'bv',
          validFrom: -1,
          vertices: const [MapPoint(x: 0, y: 0)],
        ),
        throwsArgumentError,
      );
    });

    test('boundary with empty vertex list throws ArgumentError', () {
      expect(
        () => BoundaryVersion.validated(
          id: 'bv',
          validFrom: 0,
          vertices: const [],
        ),
        throwsArgumentError,
      );
    });

    test(
      'boundary before its parent location validFrom yields no boundary',
      () {
        final state = TemporalMapState(
          branchId: 'prime',
          locations: [
            TemporalLocation.validated(
              id: 'loc-1',
              name: 'Qowner',
              validFrom: 50,
              boundaries: [
                BoundaryVersion.validated(
                  id: 'bv-1',
                  validFrom: 0,
                  vertices: const [MapPoint(x: 0, y: 0)],
                ),
              ],
            ),
          ],
        );
        final snap = state.snapshotAt(branchId: 'prime', tick: 30);
        expect(snap.locations, isEmpty);
      },
    );
  });

  group('TemporalMapState - control_history', () {
    test('control change transfers faction at tick', () {
      final state = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(
            id: 'loc-1',
            name: 'Qowner',
            validFrom: 0,
            controlHistory: [
              ControlChange.validated(
                id: 'cc-1',
                validFrom: 0,
                factionId: 'fac-void',
              ),
              ControlChange.validated(
                id: 'cc-2',
                validFrom: 200,
                factionId: 'fac-holders',
              ),
            ],
          ),
        ],
      );

      final atTick100 = state.snapshotAt(branchId: 'prime', tick: 100);
      expect(atTick100.locations.first.controllingFactionId, 'fac-void');

      final atTick250 = state.snapshotAt(branchId: 'prime', tick: 250);
      expect(atTick250.locations.first.controllingFactionId, 'fac-holders');
    });

    test('location without controlHistory reports null faction', () {
      final state = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(id: 'loc-1', name: 'Wild', validFrom: 0),
        ],
      );
      final snap = state.snapshotAt(branchId: 'prime', tick: 0);
      expect(snap.locations.first.controllingFactionId, isNull);
    });
  });

  group('TemporalMapState - location_status', () {
    test('status change updates at tick (active -> ruined -> abandoned)', () {
      final state = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(
            id: 'loc-1',
            name: 'Qowner',
            validFrom: 0,
            statusHistory: [
              StatusChange.validated(
                id: 'sc-1',
                validFrom: 0,
                status: LocationStatus.active,
              ),
              StatusChange.validated(
                id: 'sc-2',
                validFrom: 50,
                status: LocationStatus.ruined,
              ),
              StatusChange.validated(
                id: 'sc-3',
                validFrom: 100,
                status: LocationStatus.abandoned,
              ),
            ],
          ),
        ],
      );

      expect(
        state.snapshotAt(branchId: 'prime', tick: 25).locations.first.status,
        LocationStatus.active,
      );
      expect(
        state.snapshotAt(branchId: 'prime', tick: 75).locations.first.status,
        LocationStatus.ruined,
      );
      expect(
        state.snapshotAt(branchId: 'prime', tick: 150).locations.first.status,
        LocationStatus.abandoned,
      );
    });

    test('location without statusHistory defaults to active', () {
      final state = TemporalMapState(
        branchId: 'prime',
        locations: [
          TemporalLocation.validated(id: 'loc-1', name: 'X', validFrom: 0),
        ],
      );
      expect(
        state.snapshotAt(branchId: 'prime', tick: 0).locations.first.status,
        LocationStatus.active,
      );
    });
  });

  group('TemporalMapState - branch_awareness', () {
    test(
      'same location can exist in multiple branches with different state',
      () {
        final state = TemporalMapState(
          branchId: 'prime',
          locations: [
            TemporalLocation.validated(
              id: 'loc-1',
              name: 'Qowner',
              validFrom: 0,
              controlHistory: [
                ControlChange.validated(
                  id: 'cc-1',
                  validFrom: 0,
                  factionId: 'fac-void',
                ),
              ],
            ),
          ],
          branches: {
            'alt-fork': [
              TemporalLocation.validated(
                id: 'loc-1',
                name: 'Qowner',
                validFrom: 0,
                controlHistory: [
                  ControlChange.validated(
                    id: 'cc-alt-1',
                    validFrom: 0,
                    factionId: 'fac-holders',
                  ),
                ],
              ),
            ],
          },
        );

        expect(
          state
              .snapshotAt(branchId: 'prime', tick: 0)
              .locations
              .first
              .controllingFactionId,
          'fac-void',
        );
        expect(
          state
              .snapshotAt(branchId: 'alt-fork', tick: 0)
              .locations
              .first
              .controllingFactionId,
          'fac-holders',
        );
      },
    );

    test('snapshot for unknown branch throws ArgumentError', () {
      final state = TemporalMapState(branchId: 'prime', locations: const []);
      expect(
        () => state.snapshotAt(branchId: 'ghost', tick: 0),
        throwsArgumentError,
      );
    });

    test('default branch must match state.branchId', () {
      expect(
        () => TemporalMapState(branchId: 'prime', locations: const []),
        returnsNormally,
      );
    });
  });

  group('TemporalMapState - MapPoint validation', () {
    test('equal MapPoints considered equal for lookup', () {
      expect(const MapPoint(x: 1, y: 2), const MapPoint(x: 1, y: 2));
    });

    test('hashCode consistent with equality', () {
      expect(
        const MapPoint(x: 1, y: 2).hashCode,
        const MapPoint(x: 1, y: 2).hashCode,
      );
    });
  });
}
