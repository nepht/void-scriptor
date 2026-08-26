// Kontrak Lore Graph Integrity Insights (Step 109.24) — RED pertama.
//
// Acceptance kanonik sprint_109.json: orphan_report, conflict_path,
// missing_relation_hint, explain_result, dismiss_hint.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/lore/domain/lore_graph.dart';
import 'package:void_scriptor/features/lore/domain/lore_integrity.dart';

LoreGraph _sample() {
  final graph = LoreGraph();
  // Terhubung: kael -sekutu-> mira ; zed ->kael (rantai tanpa relasi zed-mira)
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
      id: 'n-zed',
      label: 'Zed',
      domain: LoreDomain.character,
      projectId: 'p-void',
      canon: true,
      firstMention: 'ch-4',
    ),
  );
  // Yatim: pulau tanpa satu pun relasi.
  graph.addNode(
    const LoreNode(
      id: 'n-pulau',
      label: 'Pulau Tengah',
      domain: LoreDomain.location,
      projectId: 'p-void',
      canon: false,
      firstMention: 'ch-5',
    ),
  );
  graph
    ..addEdge(
      const LoreEdge(
        id: 'e-1',
        sourceId: 'n-kael',
        targetId: 'n-mira',
        relation: 'sekutu',
        atMention: 'ch-2',
      ),
    )
    ..addEdge(
      const LoreEdge(
        id: 'e-2',
        sourceId: 'n-zed',
        targetId: 'n-kael',
        relation: 'mentor',
        atMention: 'ch-4',
      ),
    );
  return graph;
}

void main() {
  group('orphan_report', () {
    test('node tanpa satu pun relasi dilaporkan yatim', () {
      final report = LoreIntegrityAnalyzer.analyzeStatic(_sample());
      final orphans = report.insights
          .where((i) => i.kind == LoreInsightKind.orphanNode)
          .toList();
      expect(orphans, hasLength(1));
      expect(orphans.single.subjectId, 'n-pulau');
      expect(orphans.single.id, 'orphan:n-pulau');
    });
  });

  group('conflict_path', () {
    test('relasi ganda identik pada pasangan sama dilaporkan konflik', () {
      final graph = _sample()
        ..addEdge(
          const LoreEdge(
            id: 'e-3',
            sourceId: 'n-kael',
            targetId: 'n-mira',
            relation: 'sekutu',
            atMention: 'ch-6',
          ),
        );
      final report = LoreIntegrityAnalyzer.analyzeStatic(graph);
      final conflicts = report.insights
          .where((i) => i.kind == LoreInsightKind.conflictingRelation)
          .toList();
      expect(conflicts, hasLength(1));
      expect(conflicts.single.id, 'conflict:n-kael>n-mira:sekutu');
      // Relasi berbeda pada pasangan sama BUKAN konflik duplikat.
      final varied = LoreIntegrityAnalyzer.analyzeStatic(
        _sample()..addEdge(
          const LoreEdge(
            id: 'e-4',
            sourceId: 'n-mira',
            targetId: 'n-kael',
            relation: 'saudara',
            atMention: 'ch-7',
          ),
        ),
      );
      expect(
        varied.insights.where(
          (i) => i.kind == LoreInsightKind.conflictingRelation,
        ),
        isEmpty,
      );
    });
  });

  group('missing_relation_hint', () {
    test('celah triadik rantai zed->kael->mira diberi petunjuk', () {
      final report = LoreIntegrityAnalyzer.analyzeStatic(_sample());
      final hints = report.insights
          .where((i) => i.kind == LoreInsightKind.missingRelation)
          .toList();
      expect(hints, hasLength(1));
      expect(hints.single.subjectId, 'n-zed');
      expect(hints.single.id, 'hint:n-zed>n-mira');
      // Segitiga tertutup tidak memunculkan petunjuk.
      final closed = _sample()
        ..addEdge(
          const LoreEdge(
            id: 'e-5',
            sourceId: 'n-zed',
            targetId: 'n-mira',
            relation: 'kenalan',
            atMention: 'ch-8',
          ),
        );
      expect(
        LoreIntegrityAnalyzer.analyzeStatic(
          closed,
        ).insights.where((i) => i.kind == LoreInsightKind.missingRelation),
        isEmpty,
      );
    });
  });

  group('explain_result', () {
    test('penjelasan deterministik menyebut subjek dan jenis temuan', () {
      final report = LoreIntegrityAnalyzer.analyzeStatic(_sample());
      final orphan = report.insights.singleWhere(
        (i) => i.kind == LoreInsightKind.orphanNode,
      );
      expect(orphan.explanation, contains('n-pulau'));
      expect(orphan.explanation, contains('yatim'));
      final hint = report.insights.singleWhere(
        (i) => i.kind == LoreInsightKind.missingRelation,
      );
      expect(hint.explanation, contains('n-zed'));
      expect(hint.explanation, contains('n-mira'));
      // Analisis ulang memberikan penjelasan identik (deterministik).
      final again = LoreIntegrityAnalyzer.analyzeStatic(_sample());
      expect(
        again.insights.map((i) => i.explanation),
        report.insights.map((i) => i.explanation),
      );
    });
  });

  group('dismiss_hint', () {
    test('abaikan dengan alasan tersimpan dan bertahan lintas analisis', () {
      final analyzer = LoreIntegrityAnalyzer();
      final first = analyzer.analyze(_sample());
      final hint = first.insights.singleWhere(
        (i) => i.kind == LoreInsightKind.missingRelation,
      );
      analyzer.dismiss(hint.id, reason: 'sudah dikonfirmasi penulis');
      final second = analyzer.analyze(_sample());
      expect(second.insights.any((i) => i.id == hint.id), isFalse);
      expect(second.dismissals, hasLength(1));
      expect(second.dismissals.single.reason, 'sudah dikonfirmasi penulis');
      expect(
        second.activeInsights.map((i) => i.id),
        contains('orphan:n-pulau'),
      );
      expect(
        () => analyzer.dismiss('tidak-ada', reason: 'x'),
        throwsStateError,
      );
    });
  });
}
