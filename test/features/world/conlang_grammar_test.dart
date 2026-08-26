// Kontrak Conlang Grammar, Phonology & Script (Step 109.18) — RED pertama.
//
// Acceptance kanonik sprint_109.json: grammar_rules, phoneme_inventory,
// orthography_map, script_notes, version_history.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/conlang_grammar.dart';

void main() {
  group('grammar_rules', () {
    test('aturan tata bahasa terdokumentasi berurutan dan bisa direvisi', () {
      final doc = ConlangGrammarDoc(languageId: 'l-vessari');
      doc.upsertRule(
        const ConlangGrammarRule(
          id: 'gr-order',
          statement: 'Urutan dasar VSO.',
          category: 'word-order',
        ),
      );
      doc.upsertRule(
        const ConlangGrammarRule(
          id: 'gr-case',
          statement: 'Kasus genitif mengikuti nomina.',
          category: 'case',
        ),
      );
      expect(doc.rules.map((r) => r.id), <String>['gr-order', 'gr-case']);
      doc.upsertRule(
        const ConlangGrammarRule(
          id: 'gr-order',
          statement: 'Urutan dasar SVO pada register santai.',
          category: 'word-order',
        ),
      );
      expect(
        doc.rules.singleWhere((r) => r.id == 'gr-order').statement,
        contains('SVO'),
      );
      expect(
        () => doc.upsertRule(
          const ConlangGrammarRule(
            id: 'gr-x',
            statement: '   ',
            category: 'case',
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('phoneme_inventory', () {
    test('inventaris bunyi memilah konsonan-vokal dan menolak duplikat', () {
      final doc = ConlangGrammarDoc(languageId: 'l-vessari')
        ..addPhoneme(symbol: 'v', kind: ConlangPhonemeKind.consonant)
        ..addPhoneme(symbol: 'x', kind: ConlangPhonemeKind.consonant)
        ..addPhoneme(symbol: 'a', kind: ConlangPhonemeKind.vowel)
        ..addPhoneme(symbol: 'e', kind: ConlangPhonemeKind.vowel);
      expect(
        doc.phonemes(kind: ConlangPhonemeKind.consonant).map((p) => p.symbol),
        <String>['v', 'x'],
      );
      expect(
        doc.phonemes(kind: ConlangPhonemeKind.vowel).map((p) => p.symbol),
        <String>['a', 'e'],
      );
      expect(doc.allPhonemes.length, 4);
      expect(
        () => doc.addPhoneme(symbol: 'v', kind: ConlangPhonemeKind.consonant),
        throwsStateError,
      );
    });
  });

  group('orthography_map', () {
    test('peta grafem-fonem deterministik; entri kosong ditolak', () {
      final doc = ConlangGrammarDoc(languageId: 'l-vessari')
        ..setOrthography(grapheme: 'v', phoneme: 'v')
        ..setOrthography(grapheme: 'kh', phoneme: 'x', note: 'glotal kasar');
      expect(doc.phonemeFor(grapheme: 'kh'), 'x');
      expect(doc.phonemeFor(grapheme: 'zz'), isNull);
      doc.setOrthography(grapheme: 'kh', phoneme: 'q');
      expect(doc.phonemeFor(grapheme: 'kh'), 'q');
      expect(
        () => doc.setOrthography(grapheme: ' ', phoneme: 'v'),
        throwsArgumentError,
      );
      expect(
        () => doc.setOrthography(grapheme: 'c', phoneme: ''),
        throwsArgumentError,
      );
    });
  });

  group('script_notes', () {
    test('catatan sistem tulisan dapat diedit dengan nama tak kosong', () {
      final doc = ConlangGrammarDoc(languageId: 'l-vessari');
      expect(doc.script, isNull);
      doc.updateScript(
        scriptName: 'Aksara Vessari',
        direction: ConlangWritingDirection.leftToRight,
        notes: 'Ditulis dari batang daun ke ujung; huruf miring saat ritual.',
      );
      expect(doc.script?.name, 'Aksara Vessari');
      expect(doc.script?.direction, ConlangWritingDirection.leftToRight);
      doc.updateScript(
        scriptName: 'Aksara Vessari Ritual',
        direction: ConlangWritingDirection.topToBottom,
      );
      expect(doc.script?.direction, ConlangWritingDirection.topToBottom);
      expect(
        () => doc.updateScript(scriptName: '  ', direction: null),
        throwsArgumentError,
      );
    });
  });

  group('version_history', () {
    test('setiap mutasi mencatat revisi kronologis jam tersuntik', () {
      var tick = DateTime(2026, 8, 26, 8);
      final doc = ConlangGrammarDoc(
        languageId: 'l-vessari',
        clock: () {
          tick = tick.add(const Duration(minutes: 5));
          return tick;
        },
      );
      doc.upsertRule(
        const ConlangGrammarRule(
          id: 'gr-order',
          statement: 'Urutan dasar VSO.',
          category: 'word-order',
        ),
      );
      doc.addPhoneme(symbol: 'v', kind: ConlangPhonemeKind.consonant);
      doc.updateScript(scriptName: 'Aksara Vessari', direction: null);
      expect(doc.revisions.length, 3);
      expect(doc.revisions[0].summary, startsWith('rule:'));
      expect(doc.revisions[1].summary, startsWith('phoneme:'));
      expect(doc.revisions[2].summary, startsWith('script:'));
      expect(doc.revisions[0].at.isBefore(doc.revisions[1].at), isTrue);
      expect(doc.revisions[1].at.isBefore(doc.revisions[2].at), isTrue);
    });

    test('roundtrip JSON identik antar-rebuild', () {
      var tick = DateTime(2026, 8, 26, 8);
      final doc =
          ConlangGrammarDoc(
              languageId: 'l-vessari',
              clock: () {
                tick = tick.add(const Duration(hours: 1));
                return tick;
              },
            )
            ..upsertRule(
              const ConlangGrammarRule(
                id: 'gr-order',
                statement: 'Urutan dasar VSO.',
                category: 'word-order',
              ),
            )
            ..addPhoneme(symbol: 'a', kind: ConlangPhonemeKind.vowel)
            ..setOrthography(grapheme: 'kh', phoneme: 'x')
            ..updateScript(
              scriptName: 'Aksara Vessari',
              direction: ConlangWritingDirection.rightToLeft,
              notes: 'ukiran batu',
            );
      final restored = ConlangGrammarDoc.fromJson(
        jsonDecode(jsonEncode(doc.toJson())) as Map<String, Object?>,
      );
      expect(jsonEncode(restored.toJson()), jsonEncode(doc.toJson()));
      expect(restored.languageId, 'l-vessari');
      expect(restored.rules.single.statement, 'Urutan dasar VSO.');
      expect(restored.allPhonemes.single.symbol, 'a');
      expect(restored.phonemeFor(grapheme: 'kh'), 'x');
      expect(restored.script?.direction, ConlangWritingDirection.rightToLeft);
      expect(restored.revisions.length, doc.revisions.length);
    });
  });
}
