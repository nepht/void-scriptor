// Sprint 110.18 - Interactive Family & Dynasty Tree.
//
// RED tests for tree_layout, focus_person, time_filter, collapse_branches,
// keyboard_navigation, and large_tree_fallback. Domain-only contract over
// the existing GenealogyGraph from 110.17. No persistence, UI, locale,
// network, wall clock, or random input.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/family_dynasty_tree.dart';
import 'package:void_scriptor/features/world_logic/domain/genealogy_relationships.dart';

void main() {
  group('FamilyDynastyTree layout', () {
    test(
      'computeLayout assigns generation levels and per-generation x order',
      () {
        final graph = GenealogyGraph(
          nodes: const {
            'a': GenealogyNode(id: 'a', name: 'A'),
            'b': GenealogyNode(id: 'b', name: 'B'),
            'c': GenealogyNode(id: 'c', name: 'C'),
            'd': GenealogyNode(id: 'd', name: 'D'),
            'e': GenealogyNode(id: 'e', name: 'E'),
          },
          edges: const [
            GenealogyRelation(
              id: 'a-c',
              kind: GenealogyRelationKind.parentChild,
              fromId: 'a',
              toId: 'c',
              validFrom: 0,
            ),
            GenealogyRelation(
              id: 'b-c',
              kind: GenealogyRelationKind.parentChild,
              fromId: 'b',
              toId: 'c',
              validFrom: 0,
            ),
            GenealogyRelation(
              id: 'c-d',
              kind: GenealogyRelationKind.parentChild,
              fromId: 'c',
              toId: 'd',
              validFrom: 0,
            ),
            GenealogyRelation(
              id: 'c-e',
              kind: GenealogyRelationKind.parentChild,
              fromId: 'c',
              toId: 'e',
              validFrom: 0,
            ),
          ],
        );
        final layout = computeTreeLayout(graph: graph);
        final levels = layout.nodes.map((n) => n.generation).toList();
        expect(levels.where((g) => g == 0).length, 2);
        expect(levels.where((g) => g == 1).length, 1);
        expect(levels.where((g) => g == 2).length, 2);
        final level0Ids = layout.nodes
            .where((n) => n.generation == 0)
            .map((n) => n.nodeId)
            .toList();
        expect(level0Ids.toSet(), {'a', 'b'});
        final level2Ids = layout.nodes
            .where((n) => n.generation == 2)
            .map((n) => n.nodeId)
            .toList();
        expect(level2Ids.toSet(), {'d', 'e'});
      },
    );
    test('computeLayout respects time_filter tick', () {
      final graph = GenealogyGraph(
        nodes: const {
          'p': GenealogyNode(id: 'p', name: 'P'),
          'c': GenealogyNode(id: 'c', name: 'C'),
          'g': GenealogyNode(id: 'g', name: 'G'),
        },
        edges: const [
          GenealogyRelation(
            id: 'p-c',
            kind: GenealogyRelationKind.parentChild,
            fromId: 'p',
            toId: 'c',
            validFrom: 0,
          ),
          GenealogyRelation(
            id: 'c-g',
            kind: GenealogyRelationKind.parentChild,
            fromId: 'c',
            toId: 'g',
            validFrom: 10,
            validUntil: 15,
          ),
        ],
      );
      final early = computeTreeLayout(graph: graph, atTick: 5);
      expect(early.nodes.where((n) => n.generation == 2), isEmpty);
      final mid = computeTreeLayout(graph: graph, atTick: 12);
      expect(mid.nodes.where((n) => n.generation == 2).length, 1);
      final late = computeTreeLayout(graph: graph, atTick: 20);
      expect(late.nodes.where((n) => n.generation == 2), isEmpty);
    });
    test('computeLayout rejects empty graph', () {
      final empty = GenealogyGraph(nodes: const {}, edges: const []);
      expect(
        () => computeTreeLayout(graph: empty),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
  group('FamilyDynastyTree focus', () {
    final graph = GenealogyGraph(
      nodes: const {
        'a': GenealogyNode(id: 'a', name: 'A'),
        'b': GenealogyNode(id: 'b', name: 'B'),
        'c': GenealogyNode(id: 'c', name: 'C'),
      },
      edges: const [
        GenealogyRelation(
          id: 'a-c',
          kind: GenealogyRelationKind.parentChild,
          fromId: 'a',
          toId: 'c',
          validFrom: 0,
        ),
        GenealogyRelation(
          id: 'b-c',
          kind: GenealogyRelationKind.parentChild,
          fromId: 'b',
          toId: 'c',
          validFrom: 0,
        ),
      ],
    );
    test(
      'focusOnPerson centers a single node and reports ancestors + descendants',
      () {
        final focus = focusOnPerson(graph: graph, personId: 'c');
        expect(focus.personId, 'c');
        expect(focus.ancestorIds.toSet(), {'a', 'b'});
        expect(focus.descendantIds, isEmpty);
      },
    );
    test(
      'focusOnPerson returns empty ancestor/descendant lists for leaf root',
      () {
        final focus = focusOnPerson(graph: graph, personId: 'a');
        expect(focus.personId, 'a');
        expect(focus.ancestorIds, isEmpty);
        expect(focus.descendantIds, ['c']);
      },
    );
    test('focusOnPerson rejects unknown personId', () {
      expect(
        () => focusOnPerson(graph: graph, personId: 'ghost'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
  group('FamilyDynastyTree branch collapse', () {
    test('collapseBranch hides descendants under chosen ancestor', () {
      final graph = GenealogyGraph(
        nodes: const {
          'a': GenealogyNode(id: 'a', name: 'A'),
          'b': GenealogyNode(id: 'b', name: 'B'),
          'c': GenealogyNode(id: 'c', name: 'C'),
          'd': GenealogyNode(id: 'd', name: 'D'),
        },
        edges: const [
          GenealogyRelation(
            id: 'a-c',
            kind: GenealogyRelationKind.parentChild,
            fromId: 'a',
            toId: 'c',
            validFrom: 0,
          ),
          GenealogyRelation(
            id: 'c-d',
            kind: GenealogyRelationKind.parentChild,
            fromId: 'c',
            toId: 'd',
            validFrom: 0,
          ),
          GenealogyRelation(
            id: 'b-d',
            kind: GenealogyRelationKind.parentChild,
            fromId: 'b',
            toId: 'd',
            validFrom: 0,
          ),
        ],
      );
      final collapsed = collapseBranch(graph: graph, rootId: 'c');
      expect(collapsed.visibleNodeIds.contains('d'), isFalse);
      expect(collapsed.visibleNodeIds.contains('a'), isTrue);
      expect(collapsed.visibleNodeIds.contains('b'), isTrue);
      expect(collapsed.collapsedRootIds, ['c']);
    });
    test('expandBranch restores hidden descendants', () {
      final graph = GenealogyGraph(
        nodes: const {
          'a': GenealogyNode(id: 'a', name: 'A'),
          'd': GenealogyNode(id: 'd', name: 'D'),
        },
        edges: const [
          GenealogyRelation(
            id: 'a-d',
            kind: GenealogyRelationKind.parentChild,
            fromId: 'a',
            toId: 'd',
            validFrom: 0,
          ),
        ],
      );
      final collapsed = collapseBranch(graph: graph, rootId: 'a');
      expect(collapsed.visibleNodeIds.contains('d'), isFalse);
      final restored = expandBranch(collapsed: collapsed, rootId: 'a');
      expect(restored.visibleNodeIds.contains('d'), isTrue);
      expect(restored.collapsedRootIds, isEmpty);
    });
    test('collapseBranch rejects unknown rootId', () {
      final graph = GenealogyGraph(
        nodes: const {'a': GenealogyNode(id: 'a', name: 'A')},
        edges: const [],
      );
      expect(
        () => collapseBranch(graph: graph, rootId: 'ghost'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
  group('FamilyDynastyTree keyboard navigation', () {
    test(
      'navigateKey returns parent/child/ancestor/descendant ids per direction',
      () {
        final graph = GenealogyGraph(
          nodes: const {
            'a': GenealogyNode(id: 'a', name: 'A'),
            'b': GenealogyNode(id: 'b', name: 'B'),
            'c': GenealogyNode(id: 'c', name: 'C'),
            'd': GenealogyNode(id: 'd', name: 'D'),
          },
          edges: const [
            GenealogyRelation(
              id: 'a-c',
              kind: GenealogyRelationKind.parentChild,
              fromId: 'a',
              toId: 'c',
              validFrom: 0,
            ),
            GenealogyRelation(
              id: 'b-c',
              kind: GenealogyRelationKind.parentChild,
              fromId: 'b',
              toId: 'c',
              validFrom: 0,
            ),
            GenealogyRelation(
              id: 'c-d',
              kind: GenealogyRelationKind.parentChild,
              fromId: 'c',
              toId: 'd',
              validFrom: 0,
            ),
          ],
        );
        expect(
          navigateKey(
            graph: graph,
            personId: 'c',
            direction: TreeNavDirection.up,
          ),
          'a',
        );
        expect(
          navigateKey(
            graph: graph,
            personId: 'c',
            direction: TreeNavDirection.down,
          ),
          'd',
        );
        expect(
          navigateKey(
            graph: graph,
            personId: 'b',
            direction: TreeNavDirection.left,
          ),
          'a',
        );
        expect(
          navigateKey(
            graph: graph,
            personId: 'a',
            direction: TreeNavDirection.right,
          ),
          'b',
        );
      },
    );
    test(
      'navigateKey returns null when no neighbour in requested direction',
      () {
        final graph = GenealogyGraph(
          nodes: const {
            'a': GenealogyNode(id: 'a', name: 'A'),
            'c': GenealogyNode(id: 'c', name: 'C'),
          },
          edges: const [
            GenealogyRelation(
              id: 'a-c',
              kind: GenealogyRelationKind.parentChild,
              fromId: 'a',
              toId: 'c',
              validFrom: 0,
            ),
          ],
        );
        expect(
          navigateKey(
            graph: graph,
            personId: 'a',
            direction: TreeNavDirection.up,
          ),
          isNull,
        );
        expect(
          navigateKey(
            graph: graph,
            personId: 'c',
            direction: TreeNavDirection.down,
          ),
          isNull,
        );
        expect(
          navigateKey(
            graph: graph,
            personId: 'a',
            direction: TreeNavDirection.left,
          ),
          isNull,
        );
      },
    );
    test('navigateKey rejects unknown personId', () {
      final graph = GenealogyGraph(
        nodes: const {'a': GenealogyNode(id: 'a', name: 'A')},
        edges: const [],
      );
      expect(
        () => navigateKey(
          graph: graph,
          personId: 'ghost',
          direction: TreeNavDirection.up,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
  group('FamilyDynastyTree large tree fallback', () {
    test(
      'buildTreeLayout returns fallback when node count exceeds threshold',
      () {
        final nodes = <String, GenealogyNode>{};
        for (var i = 0; i < 12; i++) {
          nodes['n$i'] = GenealogyNode(id: 'n$i', name: 'N$i');
        }
        final edges = <GenealogyRelation>[];
        for (var i = 0; i < 11; i++) {
          edges.add(
            GenealogyRelation(
              id: 'e$i',
              kind: GenealogyRelationKind.parentChild,
              fromId: 'n$i',
              toId: 'n${i + 1}',
              validFrom: 0,
            ),
          );
        }
        final graph = GenealogyGraph(nodes: nodes, edges: edges);
        final result = buildTreeLayout(graph: graph, threshold: 10);
        expect(result.usedFallback, isTrue);
        expect(result.fallbackReason, isNotEmpty);
        expect(result.summary.totalNodes, 12);
      },
    );
    test('buildTreeLayout returns full layout when within threshold', () {
      final graph = GenealogyGraph(
        nodes: const {
          'a': GenealogyNode(id: 'a', name: 'A'),
          'b': GenealogyNode(id: 'b', name: 'B'),
        },
        edges: const [
          GenealogyRelation(
            id: 'a-b',
            kind: GenealogyRelationKind.parentChild,
            fromId: 'a',
            toId: 'b',
            validFrom: 0,
          ),
        ],
      );
      final result = buildTreeLayout(graph: graph, threshold: 50);
      expect(result.usedFallback, isFalse);
      expect(result.summary.totalNodes, 2);
    });
  });
}
