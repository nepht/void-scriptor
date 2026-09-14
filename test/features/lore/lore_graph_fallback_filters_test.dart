// Regresi vs-hunt-20260914-content CT-BUG-01/CT-BUG-02 (LoreGraph).
//
// CT-BUG-02: doc addNode menjanjikan menambah/memperbarui; putIfAbsent
// membuat pembaruan id sama dibuang diam-diam.
// CT-BUG-01: kontrak large_graph_fallback tidak mengizinkan filter
// domain/canon/project/relation dilanggar fallback; pusat fallback wajib
// berasal dari node yang lolos filter.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/lore/domain/lore_graph.dart';

LoreNode _node(
  String id, {
  LoreDomain domain = LoreDomain.location,
  bool canon = true,
  String project = 'p-void',
  String firstMention = 'ch-1',
}) => LoreNode(
  id: id,
  label: 'L-$id',
  domain: domain,
  projectId: project,
  canon: canon,
  firstMention: firstMention,
);

LoreEdge _edge(String id, String from, String to, String relation) => LoreEdge(
  id: id,
  sourceId: from,
  targetId: to,
  relation: relation,
  atMention: 'ch-1',
);

/// Graf > maxRenderNodes: 40 location (p-void) + 5 language (p-lain).
LoreGraph _bigGraph() {
  final graph = LoreGraph();
  for (var i = 0; i < 40; i++) {
    graph.addNode(_node('x$i'));
  }
  for (var i = 0; i < 5; i++) {
    graph.addNode(
      _node('lang$i', domain: LoreDomain.language, project: 'p-lain'),
    );
  }
  for (var i = 1; i < 40; i++) {
    graph.addEdge(_edge('xe$i', 'x${i - 1}', 'x$i', 'bersebelahan'));
  }
  // Jembatan dari simpul tengah rantai ke node domain lain.
  graph.addEdge(_edge('bridge', 'x20', 'lang0', 'diterjemahkan'));
  return graph;
}

void main() {
  group('addNode contract (CT-BUG-02)', () {
    test('node baru menambah tanpa mengubah yang ada', () {
      final graph = LoreGraph()..addNode(_node('a'));
      graph.addNode(_node('b', domain: LoreDomain.character));
      expect(graph.nodeCount, 2);
      expect(graph.nodes.map((n) => n.id), <String>['a', 'b']);
    });

    test('id sama memperbarui label/domain/canon/project; posisi tetap', () {
      final graph = LoreGraph()
        ..addNode(_node('a'))
        ..addNode(_node('b'))
        ..addNode(
          _node(
            'a',
            domain: LoreDomain.item,
            canon: false,
            project: 'p-lain',
            firstMention: 'ch-9',
          ),
        );
      // Pembaruan harus terlihat.
      expect(graph.nodeCount, 2);
      final a = graph.nodes.firstWhere((n) => n.id == 'a');
      expect(a.domain, LoreDomain.item);
      expect(a.canon, isFalse);
      expect(a.projectId, 'p-lain');
      expect(a.firstMention, 'ch-9');
      // Posisi penyusunan asli dipertahankan.
      expect(graph.nodes.map((n) => n.id), <String>['a', 'b']);
    });
  });

  group('buildView large-graph fallback (CT-BUG-01)', () {
    test(
      'graf besar tanpa filter jatuh ke satu lingkungan dan menandai fallback',
      () {
        final view = _bigGraph().buildView();
        expect(view.fallbackActive, isTrue);
        expect(view.focusNodeId, isNotNull);
        expect(view.nodes.length, lessThan(45));
      },
    );

    test('fallback menghormati domainFilter: nol node non-lokasi', () {
      final view = _bigGraph().buildView(domainFilter: LoreDomain.location);
      expect(view.fallbackActive, isTrue);
      expect(
        view.nodes.every((n) => n.domain == LoreDomain.location),
        isTrue,
        reason:
            'fallback tidak boleh mengembalikan node di luar domain terfilter',
      );
    });

    test('fallback menghormati projectFilter: hanya project terfilter', () {
      final view = _bigGraph().buildView(projectFilter: 'p-lain');
      expect(view.nodes, isNotEmpty);
      expect(view.nodes.every((n) => n.projectId == 'p-lain'), isTrue);
      expect(view.edges, isEmpty);
    });

    test('fallback menghormati relationFilter: edge wajib cocok relasi', () {
      final view = _bigGraph().buildView(relationFilter: 'diterjemahkan');
      expect(
        view.edges.every((e) => e.relation == 'diterjemahkan'),
        isTrue,
        reason: 'relationFilter tidak boleh diabaikan saat fallback',
      );
    });

    test('fallback deterministik: panggilan ulang identik', () {
      final g = _bigGraph();
      final first = g.buildView();
      final second = g.buildView();
      expect(first.nodes.map((n) => n.id), second.nodes.map((n) => n.id));
      expect(first.edges.map((e) => e.id), second.edges.map((e) => e.id));
      expect(first.focusNodeId, second.focusNodeId);
    });
  });
}
