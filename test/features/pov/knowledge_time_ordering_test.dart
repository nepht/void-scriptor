// Regresi vs-hunt-20260914-content CT-BUG-06 (KnowledgeTime.compareTo).
//
// Kontrak timeline_query menuntut pemotongan garis waktu TEPAT.
// Perbandingan leksikografis mentah salah untuk id tanpa padding
// numerik ('sc-10' mendahului 'sc-2'), dan tipe scene vs chapter tidak
// memiliki ordinal bersama — hasil lama menyesatkan, bukan unsupported.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/pov/domain/knowledge_boundary.dart';

void main() {
  group('KnowledgeTime ordering numerik (CT-BUG-06)', () {
    test('sc-2 sebelum sc-10 tanpa nol-padding', () {
      const early = KnowledgeTime.scene('sc-2');
      const late = KnowledgeTime.scene('sc-10');
      expect(early.compareTo(late), lessThan(0));
      expect(late.compareTo(early), greaterThan(0));
    });

    test('padding tetap konsisten dengan yang tidak dipad', () {
      expect(
        const KnowledgeTime.scene(
          'sc-02',
        ).compareTo(const KnowledgeTime.scene('sc-010')),
        lessThan(0),
      );
    });

    test('sesama chapter juga numerik', () {
      expect(
        const KnowledgeTime.chapter(
          'ch-9',
        ).compareTo(const KnowledgeTime.chapter('ch-11')),
        lessThan(0),
      );
    });

    test('id tanpa angka akhir jatuh ke urutan leksikografis', () {
      expect(
        const KnowledgeTime.scene(
          'sc-alpha',
        ).compareTo(const KnowledgeTime.scene('sc-beta')),
        lessThan(0),
      );
    });

    test('campuran scene vs chapter ditolak eksplisit, bukan hasil palsu', () {
      expect(
        () => const KnowledgeTime.scene(
          'sc-2',
        ).compareTo(const KnowledgeTime.chapter('ch-1')),
        throwsUnsupportedError,
      );
    });

    test('kontrak lama: id sama menghasilkan 0 (order stabil)', () {
      expect(
        const KnowledgeTime.scene(
          'sc-07',
        ).compareTo(const KnowledgeTime.scene('sc-07')),
        0,
      );
    });
  });

  group('ledger tetap kronologis dengan id non-padded', () {
    test('factsKnownBy mengurutkan sc-2 sebelum sc-10', () {
      final ledger = KnowledgeLedger()
        ..learn(
          characterId: 'n-kael',
          factId: 'f-late',
          at: const KnowledgeTime.scene('sc-10'),
        )
        ..learn(
          characterId: 'n-kael',
          factId: 'f-early',
          at: const KnowledgeTime.scene('sc-2'),
        );
      final facts = ledger
          .factsKnownBy('n-kael', at: const KnowledgeTime.scene('sc-12'))
          .map((e) => e.factId)
          .toList();
      expect(facts, <String>['f-early', 'f-late']);
      // Pemotongan tepat: pada sc-5 fakta sc-10 belum diketahui.
      expect(
        ledger.knows(
          'n-kael',
          factId: 'f-late',
          at: const KnowledgeTime.scene('sc-5'),
        ),
        isFalse,
      );
    });
  });
}
