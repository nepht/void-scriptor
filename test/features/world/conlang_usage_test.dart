// Kontrak Conlang Usage Consistency (Step 109.19) — RED pertama.
//
// Acceptance kanonik sprint_109.json: dictionary_lookup,
// unknown_term_warning, variant_awareness, jump_to_occurrence,
// user_override. Prinsip warisan 109.16: naskah TIDAK PERNAH diubah
// otomatis — temuan hanya merujuk entri kamus, bukan teks pengganti.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/conlang_registry.dart';
import 'package:void_scriptor/features/world/domain/conlang_usage.dart';

ConlangRegistry _registry() => ConlangRegistry()
  ..upsertLanguage(const ConlangLanguage(id: 'l-vessari', name: 'Vessari'))
  ..upsertWord(
    const ConlangWord(
      id: 'w-veth',
      languageId: 'l-vessari',
      term: "veth'ka",
      meaning: 'perjanjian yang disegel darah',
      partOfSpeech: ConlangPartOfSpeech.noun,
    ),
  )
  ..addVariant(
    wordId: 'w-veth',
    variant: const ConlangVariantForm(
      id: 'vf-veth-1',
      form: 'vethka',
      gloss: 'bentuk santai',
    ),
  )
  ..upsertWord(
    const ConlangWord(
      id: 'w-zeph',
      languageId: 'l-vessari',
      term: 'zeph',
      meaning: 'angin utara',
      partOfSpeech: ConlangPartOfSpeech.noun,
    ),
  );

void main() {
  group('dictionary_lookup', () {
    test('istilah kamus ditemukan dengan referensi kata dan offset', () {
      final checker = ConlangUsageChecker(registry: _registry());
      final findings = checker.check("Ia mengucap veth'ka lalu diam.");
      final known = findings.where(
        (f) => f.kind == ConlangFindingKind.knownTerm,
      );
      expect(known, hasLength(1));
      expect(known.single.wordId, 'w-veth');
      expect(known.single.offset, 12);
      expect(known.single.length, 7);
      expect(known.single.matchedForm, "veth'ka");
      expect(checker.check('Kalimat biasa tanpa istilah.'), isEmpty);
      expect(checker.check(''), isEmpty);
    });
  });

  group('unknown_term_warning', () {
    test('ejaan menyimpang diperingatkan; cek murni tanpa mutasi', () {
      final checker = ConlangUsageChecker(registry: _registry());
      final findings = checker.check('Ia bersumpah dengan vethkq tersegel.');
      final warnings = findings.where(
        (f) => f.kind == ConlangFindingKind.unknownTerm,
      );
      expect(warnings, hasLength(1));
      expect(warnings.single.wordId, 'w-veth');
      expect(warnings.single.offset, 20);
      expect(warnings.single.length, 6);
      expect(warnings.single.suggestions, <String>['vethka']);
      final again = checker.check('Ia bersumpah dengan vethkq tersegel.');
      expect(
        again.map((f) => '${f.kind}:${f.offset}').toList(),
        findings.map((f) => '${f.kind}:${f.offset}').toList(),
      );
    });
  });

  group('variant_awareness', () {
    test('varian bentuk dihitung sebagai kemunculan kata induknya', () {
      final checker = ConlangUsageChecker(registry: _registry());
      final findings = checker.check('Kata vethka dipakai santai.');
      final known = findings.where(
        (f) => f.kind == ConlangFindingKind.knownTerm,
      );
      expect(known, hasLength(1));
      expect(known.single.wordId, 'w-veth');
      expect(known.single.matchedForm, 'vethka');
    });

    test('salah eja varian juga mendapat saran dari bentuk varian', () {
      final checker = ConlangUsageChecker(registry: _registry());
      final findings = checker.check('Kata vethkb dipakai santai.');
      final warnings = findings.where(
        (f) => f.kind == ConlangFindingKind.unknownTerm,
      );
      expect(warnings.single.suggestions, <String>['vethka']);
      expect(warnings.single.wordId, 'w-veth');
    });
  });

  group('jump_to_occurrence', () {
    test('dua kemunculan menghasilkan offset naik dan cuplikan verbatim', () {
      final checker = ConlangUsageChecker(registry: _registry());
      const text = "veth'ka dan VETH'KA disebut dua kali.";
      final known = checker
          .check(text)
          .where((f) => f.kind == ConlangFindingKind.knownTerm);
      expect(known.map((f) => f.offset).toList(), <int>[0, 12]);
      expect(known.map((f) => f.length).toList(), <int>[7, 7]);
      expect(known.first.snippet, "veth'ka");
      expect(known.last.snippet, "VETH'KA");
    });
  });

  group('user_override', () {
    test(
      'istilah yang diabaikan senyap; pelanggaran lain tetap terdeteksi',
      () {
        final checker = ConlangUsageChecker(registry: _registry())
          ..ignoreTerm('vethkq');
        expect(
          checker
              .check('berbisik vethkq pelan')
              .where((f) => f.kind == ConlangFindingKind.unknownTerm),
          isEmpty,
        );
        final others = checker.check('berbisik zephh pelan');
        expect(others.single.kind, ConlangFindingKind.unknownTerm);
        expect(others.single.wordId, 'w-zeph');
      },
    );
  });

  group('meaning_consistency', () {
    test('glos kurung yang cocok senyap; yang berbeda diperingatkan', () {
      final checker = ConlangUsageChecker(registry: _registry());
      final ok = checker.check('Angin zeph (angin utara) berembus.');
      expect(
        ok.where((f) => f.kind == ConlangFindingKind.meaningMismatch),
        isEmpty,
      );
      final bad = checker.check('Angin zeph (napas leluhur) berembus.');
      final mismatches = bad
          .where((f) => f.kind == ConlangFindingKind.meaningMismatch)
          .toList();
      expect(mismatches, hasLength(1));
      expect(mismatches.single.wordId, 'w-zeph');
      expect(mismatches.single.expectedMeaning, 'angin utara');
      expect(mismatches.single.foundGloss, 'napas leluhur');
      expect(mismatches.single.offset, 6);
    });
  });
}
