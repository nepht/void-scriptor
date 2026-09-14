// Regresi vs-hunt-20260914-content CT-BUG-03 (LoreIntegrityAnalyzer).
//
// Kontrak missing_relation_hint: tiap celah triadik A->B->C tanpa relasi
// langsung A-C diberi petunjuk. Dedup lama memakai himpunan tujuan `c`
// saja sehingga celah dari SUMBER lain ke tujuan yang sama hilang.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/lore/domain/lore_graph.dart';
import 'package:void_scriptor/features/lore/domain/lore_integrity.dart';

LoreNode _n(String id) => LoreNode(
  id: id,
  label: id,
  domain: LoreDomain.character,
  projectId: 'p-void',
  canon: true,
  firstMention: 'ch-1',
);

void main() {
  group('missing_relation_hint dedup identitas (CT-BUG-03)', () {
    test(
      'dua sumber berbeda ke tujuan sama lewat perantara sama: dua hint',
      () {
        // a->b, d->b, b->c. Celah: a->c DAN d->c (keduanya absen).
        final graph = LoreGraph()
          ..addNode(_n('a'))
          ..addNode(_n('b'))
          ..addNode(_n('c'))
          ..addNode(_n('d'))
          ..addEdge(
            const LoreEdge(
              id: 'e1',
              sourceId: 'a',
              targetId: 'b',
              relation: 'sekutu',
              atMention: 'ch-1',
            ),
          )
          ..addEdge(
            const LoreEdge(
              id: 'e2',
              sourceId: 'd',
              targetId: 'b',
              relation: 'musuh',
              atMention: 'ch-1',
            ),
          )
          ..addEdge(
            const LoreEdge(
              id: 'e3',
              sourceId: 'b',
              targetId: 'c',
              relation: 'wali',
              atMention: 'ch-1',
            ),
          );
        final hints = LoreIntegrityAnalyzer.analyzeStatic(graph).insights
            .where((i) => i.kind == LoreInsightKind.missingRelation)
            .map((i) => i.id)
            .toSet();
        expect(hints, containsAll(<String>['hint:a>c', 'hint:d>c']));
      },
    );

    test('sumber yang sama tidak menghasilkan hint ganda lintas perantara', () {
      // a->b, a->d, b->c, d->c: hanya satu celah a->c.
      final graph = LoreGraph()
        ..addNode(_n('a'))
        ..addNode(_n('b'))
        ..addNode(_n('c'))
        ..addNode(_n('d'))
        ..addEdge(
          const LoreEdge(
            id: 'e1',
            sourceId: 'a',
            targetId: 'b',
            relation: 'sekutu',
            atMention: 'ch-1',
          ),
        )
        ..addEdge(
          const LoreEdge(
            id: 'e2',
            sourceId: 'a',
            targetId: 'd',
            relation: 'guru',
            atMention: 'ch-1',
          ),
        )
        ..addEdge(
          const LoreEdge(
            id: 'e3',
            sourceId: 'b',
            targetId: 'c',
            relation: 'wali',
            atMention: 'ch-1',
          ),
        )
        ..addEdge(
          const LoreEdge(
            id: 'e4',
            sourceId: 'd',
            targetId: 'c',
            relation: 'rekan',
            atMention: 'ch-1',
          ),
        );
      final hints = LoreIntegrityAnalyzer.analyzeStatic(graph).insights
          .where((i) => i.kind == LoreInsightKind.missingRelation)
          .map((i) => i.id)
          .toList();
      expect(hints.where((id) => id == 'hint:a>c').length, 1);
    });
  });
}
