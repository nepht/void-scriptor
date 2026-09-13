// Kontrak Conlang Registry & Dictionary (Step 109.17) — RED pertama.
//
// Acceptance kanonik sprint_109.json: multiple_languages,
// dictionary_search, variant_forms, usage_examples, import_export.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/conlang_registry.dart';

ConlangWord vethWord() => const ConlangWord(
  id: 'w-veth',
  languageId: 'l-vessari',
  term: "veth'ka",
  meaning: 'perjanjian darah',
  partOfSpeech: ConlangPartOfSpeech.noun,
);

void main() {
  group('multiple_languages', () {
    test('daftar bahasa bisa didaftarkan dan dicari berurutan', () {
      final registry = ConlangRegistry();
      registry
        ..upsertLanguage(
          const ConlangLanguage(id: 'l-vessari', name: 'Vessari'),
        )
        ..upsertLanguage(const ConlangLanguage(id: 'l-orun', name: 'Orunai'));
      expect(registry.languages.map((l) => l.id), <String>[
        'l-vessari',
        'l-orun',
      ]);
      registry.upsertLanguage(
        const ConlangLanguage(id: 'l-vessari', name: 'Vessari Lama'),
      );
      expect(
        registry.languages.singleWhere((l) => l.id == 'l-vessari').name,
        'Vessari Lama',
      );
      expect(registry.languages.length, 2);
      expect(() => registry.upsertWord(vethWord()), returnsNormally);
    });

    test('kata wajib milik bahasa terdaftar; duplikat istilah ditolak', () {
      final registry = ConlangRegistry()
        ..upsertLanguage(
          const ConlangLanguage(id: 'l-vessari', name: 'Vessari'),
        );
      const orphan = ConlangWord(
        id: 'w-orphan',
        languageId: 'l-tak-terdaftar',
        term: 'zeph',
        meaning: 'kata yatim',
        partOfSpeech: ConlangPartOfSpeech.particle,
      );
      expect(() => registry.upsertWord(orphan), throwsArgumentError);
      registry.upsertWord(vethWord());
      const renamed = ConlangWord(
        id: 'w-veth',
        languageId: 'l-vessari',
        term: "veth'ka",
        meaning: 'perjanjian yang disegel darah',
        partOfSpeech: ConlangPartOfSpeech.noun,
      );
      registry.upsertWord(renamed);
      expect(registry.words(languageId: 'l-vessari').length, 1);
      expect(registry.words().single.meaning, 'perjanjian yang disegel darah');
    });
  });

  group('dictionary_search', () {
    test('cari per bahasa, case-insensitive, istilah lalu arti', () {
      final registry = _seeded();
      expect(registry.search(term: "veth").map((w) => w.id), <String>[
        'w-veth',
      ]);
      expect(registry.search(term: 'DARAH').map((w) => w.id), <String>[
        'w-veth',
      ]);
      expect(registry.search(languageId: 'l-orun', term: 'veth'), isEmpty);
      final all = registry.search();
      expect(all.length, 3);
    });
  });

  group('variant_forms', () {
    test('varian bentuk tersimpan dan terindeks untuk pencarian', () {
      final registry = _seeded();
      const plural = ConlangVariantForm(
        id: 'vf-veth-pl',
        form: 'vethkan',
        gloss: 'bentuk jamak hormat',
      );
      registry.addVariant(wordId: 'w-veth', variant: plural);
      expect(registry.wordById('w-veth').variants.single.form, 'vethkan');
      expect(registry.search(term: 'vethkan').single.id, 'w-veth');
    });
  });

  group('usage_examples', () {
    test('contoh penggunaan tersimpan berurutan per kata', () {
      final registry = _seeded();
      registry.addExample(
        wordId: 'w-veth',
        example: const ConlangUsageExample(
          text: "Sera o veth'ka tun.",
          translation: 'Ia melanggar perjanjian darah itu.',
        ),
      );
      registry.addExample(
        wordId: 'w-veth',
        example: const ConlangUsageExample(
          text: "Veth'ka nai.",
          translation: 'Perjanjian itu abadi.',
        ),
      );
      expect(registry.wordById('w-veth').examples.length, 2);
      expect(
        registry.wordById('w-veth').examples.first.translation,
        'Ia melanggar perjanjian darah itu.',
      );
    });
  });

  group('import_export', () {
    test('roundtrip JSON identik antar-rebuild', () {
      final registry = _seeded()
        ..addVariant(
          wordId: 'w-veth',
          variant: const ConlangVariantForm(id: 'vf-1', form: 'vethkan'),
        )
        ..addExample(
          wordId: 'w-veth',
          example: const ConlangUsageExample(text: "veth'ka nai"),
        );
      final restored = ConlangRegistry.fromJson(
        jsonDecode(jsonEncode(registry.toJson())) as Map<String, Object?>,
      );
      expect(jsonEncode(restored.toJson()), jsonEncode(registry.toJson()));
      expect(restored.languages.length, 2);
      expect(restored.words().length, 3);
      expect(restored.wordById('w-veth').variants.single.form, 'vethkan');
    });

    test('registry kosong valid dan roundtrip stabil', () {
      final restored = ConlangRegistry.fromJson(
        jsonDecode(jsonEncode(ConlangRegistry().toJson()))
            as Map<String, Object?>,
      );
      expect(restored.languages, isEmpty);
      expect(restored.words(), isEmpty);
    });
  });

  // vs-hunt-20260913-world WLD-PARENT-03: dokumentasi publik berjanji
  // "[StateError] bila ID tak dikenal"; implementasi lama melempar TypeError
  // dari `_words[id]!`. Test ini mengunci kontrak terdokumentasi.
  group('unknown_word_id_contract (WLD-PARENT-03)', () {
    test('wordById ID tak dikenal melempar StateError, bukan TypeError', () {
      final registry = _seeded();
      expect(() => registry.wordById('w-tak-ada'), throwsA(isA<StateError>()));
    });

    test('addVariant kata tak dikenal melempar StateError', () {
      final registry = _seeded();
      expect(
        () => registry.addVariant(
          wordId: 'w-tak-ada',
          variant: const ConlangVariantForm(id: 'vf-x', form: 'x'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('addExample kata tak dikenal melempar StateError', () {
      final registry = _seeded();
      expect(
        () => registry.addExample(
          wordId: 'w-tak-ada',
          example: const ConlangUsageExample(text: 'x'),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

ConlangRegistry _seeded() {
  final registry = ConlangRegistry()
    ..upsertLanguage(const ConlangLanguage(id: 'l-vessari', name: 'Vessari'))
    ..upsertLanguage(const ConlangLanguage(id: 'l-orun', name: 'Orunai'))
    ..upsertWord(vethWord())
    ..upsertWord(
      const ConlangWord(
        id: 'w-sera',
        languageId: 'l-vessari',
        term: 'sera',
        meaning: 'ia; orang asing yang dihormati',
        partOfSpeech: ConlangPartOfSpeech.pronoun,
      ),
    )
    ..upsertWord(
      const ConlangWord(
        id: 'w-kalith',
        languageId: 'l-orun',
        term: 'kalith',
        meaning: 'badai abadi',
        partOfSpeech: ConlangPartOfSpeech.adjective,
      ),
    );
  return registry;
}
