// Kontrak POV Knowledge Boundary (Step 109.34) — RED pertama.
//
// Acceptance kanonik sprint_109.json: knowledge_events, timeline_query,
// source_reference, uncertain_knowledge, secret_handling.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/pov/domain/knowledge_boundary.dart';

KnowledgeLedger _ledger() => KnowledgeLedger();

void main() {
  group('knowledge_events', () {
    test('peristiwa belajar terekam kronologis per karakter', () {
      final ledger = _ledger();
      ledger.learn(
        characterId: 'n-kael',
        factId: 'f-mira-pengkhianat',
        at: const KnowledgeTime.scene('sc-03'),
      );
      ledger.learn(
        characterId: 'n-kael',
        factId: 'f-lorong-timur',
        at: const KnowledgeTime.scene('sc-01'),
      );
      final facts = ledger
          .factsKnownBy('n-kael', at: const KnowledgeTime.scene('sc-05'))
          .map((f) => f.factId)
          .toList();
      // Kronologis berdasar urutan adegan.
      expect(facts.first, 'f-lorong-timur');
      expect(facts, contains('f-mira-pengkhianat'));
      // Twist Mira belum diketahui sebelum sc-03; fakta sc-01 sudah.
      final early = ledger
          .factsKnownBy('n-kael', at: const KnowledgeTime.scene('sc-02'))
          .map((f) => f.factId)
          .toList();
      expect(early, <String>['f-lorong-timur']);
      expect(early, isNot(contains('f-mira-pengkhianat')));
    });
  });

  group('timeline_query', () {
    test('kueri memotong garis waktu dengan tepat', () {
      final ledger = _ledger()
        ..learn(
          characterId: 'n-kael',
          factId: 'f-a',
          at: const KnowledgeTime.scene('sc-02'),
        )
        ..learn(
          characterId: 'n-kael',
          factId: 'f-b',
          at: const KnowledgeTime.scene('sc-07'),
        );
      // Pada adegan reveal itu sendiri fakta sudah diketahui.
      expect(
        ledger.knows(
          'n-kael',
          factId: 'f-b',
          at: const KnowledgeTime.scene('sc-07'),
        ),
        isTrue,
      );
      expect(
        ledger.knows(
          'n-kael',
          factId: 'f-b',
          at: const KnowledgeTime.scene('sc-06'),
        ),
        isFalse,
      );
    });
  });

  group('source_reference', () {
    test('setiap pengetahuan membawa rujukan sumbernya', () {
      final ledger = _ledger()
        ..learn(
          characterId: 'n-mira',
          factId: 'f-janjin-lama',
          at: const KnowledgeTime.scene('sc-04'),
          source: const KnowledgeSource(
            kind: KnowledgeSourceKind.conversation,
            reference: 'sc-04:dialog-2',
          ),
        );
      final fact = ledger
          .factsKnownBy('n-mira', at: const KnowledgeTime.scene('sc-09'))
          .single;
      expect(fact.source!.kind, KnowledgeSourceKind.conversation);
      expect(fact.source!.reference, contains('dialog-2'));
    });
  });

  group('uncertain_knowledge', () {
    test('dugaan tidak dihitung tahu pasti tapi tetap terlacak', () {
      final ledger = _ledger()
        ..learn(
          characterId: 'n-kael',
          factId: 'f-tebakan-besar',
          at: const KnowledgeTime.scene('sc-05'),
          certainty: Certainty.suspected,
        )
        ..learn(
          characterId: 'n-kael',
          factId: 'f-yakin',
          at: const KnowledgeTime.scene('sc-06'),
        );
      expect(
        ledger.knows(
          'n-kael',
          factId: 'f-tebakan-besar',
          at: const KnowledgeTime.scene('sc-08'),
        ),
        isFalse,
      );
      final suspects = ledger.factsKnownBy(
        'n-kael',
        at: const KnowledgeTime.scene('sc-08'),
        includeSuspected: true,
      );
      expect(suspects.map((f) => f.factId), contains('f-tebakan-besar'));
      expect(
        ledger.knows(
          'n-kael',
          factId: 'f-yakin',
          at: const KnowledgeTime.scene('sc-08'),
        ),
        isTrue,
      );
    });
  });

  group('secret_handling', () {
    test('fakta rahasia tak terlihat sampai titik bocornya', () {
      final ledger = _ledger()
        ..declareSecret(
          factId: 'f-rahasia-raja',
          leakedAt: const KnowledgeTime.scene('sc-20'),
        )
        ..learn(
          characterId: 'n-kael',
          factId: 'f-rahasia-raja',
          at: const KnowledgeTime.scene('sc-10'),
        );
      // Pembaca/pemeriksa lain belum boleh melihat fakta ini.
      expect(
        ledger.isSecretVisible(
          'f-rahasia-raja',
          at: const KnowledgeTime.scene('sc-19'),
        ),
        isFalse,
      );
      expect(
        ledger.isSecretVisible(
          'f-rahasia-raja',
          at: const KnowledgeTime.scene('sc-20'),
        ),
        isTrue,
      );
      // Yang bersangkutan tetap "tahu" (dia sumber kebocorannya).
      expect(
        ledger.knows(
          'n-kael',
          factId: 'f-rahasia-raja',
          at: const KnowledgeTime.scene('sc-12'),
        ),
        isTrue,
      );
      expect(
        () => ledger.declareSecret(
          factId: 'f-rahasia-raja',
          leakedAt: const KnowledgeTime.scene('sc-30'),
        ),
        throwsStateError,
      );
    });
  });
}
