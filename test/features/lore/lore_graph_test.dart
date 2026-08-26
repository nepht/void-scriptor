// Kontrak Writer-Focused Lore Graph (Step 109.23) — RED pertama.
//
// Acceptance kanonik sprint_109.json: filter_nodes, filter_edges,
// focus_entity, source_navigation, large_graph_fallback.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/lore/domain/lore_graph.dart';

LoreGraph _sample() {
  final graph = LoreGraph();
  graph.addNode(
    const LoreNode(
      id: 'n-kael',
      label: 'Kael',
      domain: LoreDomain.character,
      projectId: 'p-void',
      canon: true,
      firstMention: 'ch-1',
    ),
  );
  graph.addNode(
    const LoreNode(
      id: 'n-mira',
      label: 'Mira',
      domain: LoreDomain.character,
      projectId: 'p-void',
      canon: true,
      firstMention: 'ch-2',
    ),
  );
  graph.addNode(
    const LoreNode(
      id: 'n-vessari',
      label: 'Bahasa Vessari',
      domain: LoreDomain.language,
      projectId: 'p-void',
      canon: false,
      firstMention: 'ch-3',
    ),
  );
  graph.addEdge(
    const LoreEdge(
      id: 'e-1',
      sourceId: 'n-kael',
      targetId: 'n-mira',
      relation: 'sekutu',
      atMention: 'ch-2',
    ),
  );
  graph.addEdge(
    const LoreEdge(
      id: 'e-2',
      sourceId: 'n-mira',
      targetId: 'n-vessari',
      relation: 'penutur',
      atMention: 'ch-3',
    ),
  );
  return graph;
}

void main() {
  group('filter_nodes', () {
    test('node terfiltrasi domain/canon/project secara independen', () {
      final view = _sample().buildView();
      expect(
        view.nodes.map((n) => n.id),
        containsAll(<String>['n-kael', 'n-mira', 'n-vessari']),
      );
      expect(
        _sample()
            .buildView(domainFilter: LoreDomain.character)
            .nodes
            .map((n) => n.id),
        <String>['n-kael', 'n-mira'],
      );
      expect(
        _sample().buildView(canonOnly: true).nodes.map((n) => n.id),
        <String>['n-kael', 'n-mira'],
      );
      expect(_sample().buildView(projectFilter: 'p-lain').nodes, isEmpty);
    });
  });

  group('filter_edges', () {
    test('edge mengikuti filtrasi node dan relasinya sendiri', () {
      final onlyLanguage = _sample().buildView(
        domainFilter: LoreDomain.language,
      );
      expect(onlyLanguage.edges, isEmpty);
      final full = _sample().buildView();
      expect(full.edges.map((e) => e.id), <String>['e-1', 'e-2']);
      expect(
        _sample().buildView(relationFilter: 'penutur').edges.map((e) => e.id),
        <String>['e-2'],
      );
    });
  });

  group('focus_entity', () {
    test('fokus memuat tetangga langsung saja dan menandai pusat', () {
      final view = _sample().buildFocus(entityId: 'n-mira');
      expect(view.focusNodeId, 'n-mira');
      expect(view.nodes.map((n) => n.id), <String>[
        'n-mira',
        'n-kael',
        'n-vessari',
      ]);
      expect(view.edges.map((e) => e.id), <String>['e-1', 'e-2']);
      expect(() => _sample().buildFocus(entityId: 'n-hantu'), throwsStateError);
    });
  });

  group('source_navigation', () {
    test('setiap node dan edge membawa rujukan sumber bab', () {
      final view = _sample().buildView();
      final vessari = view.nodes.singleWhere((n) => n.id == 'n-vessari');
      expect(vessari.firstMention, 'ch-3');
      final e2 = view.edges.singleWhere((e) => e.id == 'e-2');
      expect(e2.atMention, 'ch-3');
    });
  });

  group('large_graph_fallback', () {
    test('graf besar memakai fokus otomatis dan melapor fallback', () {
      final graph = LoreGraph();
      for (var i = 0; i < 40; i++) {
        graph.addNode(
          LoreNode(
            id: 'x$i',
            label: 'X$i',
            domain: LoreDomain.location,
            projectId: 'p-big',
            canon: true,
            firstMention: 'ch-1',
          ),
        );
      }
      for (var i = 1; i < 40; i++) {
        graph.addEdge(
          LoreEdge(
            id: 'xe$i',
            sourceId: 'x${i - 1}',
            targetId: 'x$i',
            relation: 'bersebelahan',
            atMention: 'ch-1',
          ),
        );
      }
      expect(graph.nodeCount, 40);
      final view = graph.buildView();
      expect(view.fallbackActive, isTrue);
      expect(view.nodes.length, lessThan(40));
      final focused = graph.buildFocus(entityId: 'x20');
      expect(focused.fallbackActive, isFalse);
      expect(focused.nodes.map((n) => n.id), <String>['x20', 'x19', 'x21']);
    });
  });
}
