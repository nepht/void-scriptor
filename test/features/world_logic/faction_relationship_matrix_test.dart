// Sprint 110.23 - Faction Relationship Matrix.
//
// Domain-only contract for directed faction-to-faction relations with
// relationship type, intensity, validity ranges, and a per-tick matrix
// view. No persistence, UI, locale, network, wall clock, or random input.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/faction_relationship_matrix.dart';

void main() {
  group('FactionRelationshipMatrix.directedRelation', () {
    test('edge is directed from source to target (not symmetric)', () {
      final matrix = FactionRelationshipMatrix(
        nodes: const [
          FactionNode(id: 'a', name: 'A'),
          FactionNode(id: 'b', name: 'B'),
        ],
        edges: [
          FactionRelationship.validated(
            id: 'e1',
            kind: FactionRelationKind.ally,
            fromId: 'a',
            toId: 'b',
            intensity: 5,
            validFrom: 0,
          ),
        ],
      );

      expect(matrix.relationsBetween('a', 'b'), hasLength(1));
      expect(matrix.relationsBetween('b', 'a'), isEmpty);
    });

    test('self-relation is rejected by validated factory', () {
      expect(
        () => FactionRelationship.validated(
          id: 'e1',
          kind: FactionRelationKind.ally,
          fromId: 'a',
          toId: 'a',
          intensity: 5,
          validFrom: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('unknown faction id in edge is rejected at construction', () {
      expect(
        () => FactionRelationshipMatrix(
          nodes: const [FactionNode(id: 'a', name: 'A')],
          edges: [
            FactionRelationship.validated(
              id: 'e1',
              kind: FactionRelationKind.ally,
              fromId: 'a',
              toId: 'ghost',
              intensity: 5,
              validFrom: 0,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('FactionRelationshipMatrix.relationshipType', () {
    test('enum exposes ally/rival/enemy/neutral/vassal/overlord', () {
      const values = FactionRelationKind.values;
      expect(
        values,
        containsAll(<FactionRelationKind>[
          FactionRelationKind.ally,
          FactionRelationKind.rival,
          FactionRelationKind.enemy,
          FactionRelationKind.neutral,
          FactionRelationKind.vassal,
          FactionRelationKind.overlord,
        ]),
      );
    });

    test('relation kind is preserved on each edge', () {
      final matrix = FactionRelationshipMatrix(
        nodes: const [
          FactionNode(id: 'a', name: 'A'),
          FactionNode(id: 'b', name: 'B'),
          FactionNode(id: 'c', name: 'C'),
        ],
        edges: [
          FactionRelationship.validated(
            id: 'e1',
            kind: FactionRelationKind.enemy,
            fromId: 'a',
            toId: 'b',
            intensity: 9,
            validFrom: 0,
          ),
          FactionRelationship.validated(
            id: 'e2',
            kind: FactionRelationKind.vassal,
            fromId: 'c',
            toId: 'a',
            intensity: 6,
            validFrom: 0,
          ),
        ],
      );

      final fromA = matrix.relationsBetween('a', 'b');
      expect(fromA.single.kind, FactionRelationKind.enemy);
      final fromC = matrix.relationsBetween('c', 'a');
      expect(fromC.single.kind, FactionRelationKind.vassal);
    });
  });

  group('FactionRelationshipMatrix.intensity', () {
    test('intensity outside [0, 10] is rejected by validated factory', () {
      expect(
        () => FactionRelationship.validated(
          id: 'e1',
          kind: FactionRelationKind.ally,
          fromId: 'a',
          toId: 'b',
          intensity: -1,
          validFrom: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => FactionRelationship.validated(
          id: 'e2',
          kind: FactionRelationKind.ally,
          fromId: 'a',
          toId: 'b',
          intensity: 11,
          validFrom: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('intensity is preserved on each edge', () {
      final matrix = FactionRelationshipMatrix(
        nodes: const [
          FactionNode(id: 'a', name: 'A'),
          FactionNode(id: 'b', name: 'B'),
        ],
        edges: [
          FactionRelationship.validated(
            id: 'e1',
            kind: FactionRelationKind.ally,
            fromId: 'a',
            toId: 'b',
            intensity: 7,
            validFrom: 0,
          ),
        ],
      );

      expect(matrix.relationsBetween('a', 'b').single.intensity, 7);
    });
  });

  group('FactionRelationshipMatrix.validityRanges', () {
    test('empty id is rejected by validated factory', () {
      expect(
        () => FactionRelationship.validated(
          id: '',
          kind: FactionRelationKind.ally,
          fromId: 'a',
          toId: 'b',
          intensity: 5,
          validFrom: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('negative validFrom is rejected by validated factory', () {
      expect(
        () => FactionRelationship.validated(
          id: 'e1',
          kind: FactionRelationKind.ally,
          fromId: 'a',
          toId: 'b',
          intensity: 5,
          validFrom: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validUntil < validFrom is rejected', () {
      expect(
        () => FactionRelationship.validated(
          id: 'e1',
          kind: FactionRelationKind.ally,
          fromId: 'a',
          toId: 'b',
          intensity: 5,
          validFrom: 10,
          validUntil: 5,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('graph-level construction validates edges validity', () {
      expect(
        () => FactionRelationshipMatrix(
          nodes: const [
            FactionNode(id: 'a', name: 'A'),
            FactionNode(id: 'b', name: 'B'),
          ],
          edges: [
            const FactionRelationship(
              id: 'bad',
              kind: FactionRelationKind.ally,
              fromId: 'a',
              toId: 'b',
              intensity: 5,
              validFrom: -3,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('FactionRelationshipMatrix.matrixView', () {
    final matrix = FactionRelationshipMatrix(
      nodes: const [
        FactionNode(id: 'a', name: 'A'),
        FactionNode(id: 'b', name: 'B'),
        FactionNode(id: 'c', name: 'C'),
      ],
      edges: [
        FactionRelationship.validated(
          id: 'e1',
          kind: FactionRelationKind.ally,
          fromId: 'a',
          toId: 'b',
          intensity: 5,
          validFrom: 0,
          validUntil: 100,
        ),
        FactionRelationship.validated(
          id: 'e2',
          kind: FactionRelationKind.enemy,
          fromId: 'a',
          toId: 'c',
          intensity: 9,
          validFrom: 0,
          validUntil: 50,
        ),
        FactionRelationship.validated(
          id: 'e3',
          kind: FactionRelationKind.rival,
          fromId: 'a',
          toId: 'c',
          intensity: 4,
          validFrom: 60,
          validUntil: 200,
        ),
      ],
    );

    test('snapshotAt filters by active validity', () {
      final snapAt20 = matrix.snapshotAt(20);
      expect(snapAt20.relations, hasLength(2));
      final snapAt80 = matrix.snapshotAt(80);
      expect(snapAt80.relations, hasLength(2));
    });

    test('snapshotAt returns empty relation list for tick before all', () {
      final snap = matrix.snapshotAt(-1);
      expect(snap.relations, isEmpty);
      expect(snap.factionIds, hasLength(3));
    });

    test('snapshotAt returns empty relation list for tick after all', () {
      final snap = matrix.snapshotAt(300);
      expect(snap.relations, isEmpty);
      expect(snap.factionIds, hasLength(3));
    });

    test('snapshot exposes deterministic faction ids and node lookup', () {
      final snap = matrix.snapshotAt(20);
      expect(snap.factionIds.toSet(), {'a', 'b', 'c'});
      expect(snap.nodeById('a')?.name, 'A');
    });

    test('matrix exposes readonly views of nodes and edges', () {
      expect(() => matrix.nodes.clear(), throwsUnsupportedError);
      expect(() => matrix.edges.clear(), throwsUnsupportedError);
    });
  });
}
