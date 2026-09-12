import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/application/character_trait_extractor.dart';

/// Pure-domain contract tests: the extractor must parse provider JSON into
/// cited proposals without ever mutating anything, and must reject anything
/// that is not the strict schema. Text never leaves here; the UI applies
/// proposals only after the user ticks them.
void main() {
  group('CharacterTraitExtractor.parseProposals', () {
    test('parses full schema with citations and tags', () {
      const json = r'''
{
  "traits": [
    {"field": "hair", "value": "white with lavender streaks",
     "tag": "explicit",
     "citations": [{"chapter": 3, "quote": "rambut putihnya bersemu lavender"}]},
    {"field": "eyes", "value": "violet", "tag": "explicit",
     "citations": [{"chapter": 1, "quote": "mata violet menatap tajam"}]},
    {"field": "personality", "value": "cerewet tapi protektif",
     "tag": "inferred",
     "citations": [{"chapter": 2, "quote": "\"Kamu pikir aku diam saja?\""}]}
  ],
  "unknown": ["height", "voice"]
}
''';
      final result = CharacterTraitExtractor.parseProposals(json);
      expect(result.traits.length, 3);
      expect(result.traits.first.field, 'hair');
      expect(result.traits.first.tag, TraitEvidenceTag.explicit);
      expect(result.traits.first.citations.single.chapter, 3);
      expect(
        result.traits.first.citations.single.quote,
        'rambut putihnya bersemu lavender',
      );
      expect(result.traits[2].tag, TraitEvidenceTag.inferred);
      expect(result.unknownFields, containsAll(<String>['height', 'voice']));
    });

    test('tolak JSON di luar objek {traits,unknown}', () {
      expect(
        () => CharacterTraitExtractor.parseProposals('["bukan objek"]'),
        throwsFormatException,
      );
      expect(
        () => CharacterTraitExtractor.parseProposals('{"other": 1}'),
        throwsFormatException,
      );
    });

    test('trait tanpa sitasi ditolak — proposal wajib ber-kutipan', () {
      const json = '''
{"traits":[{"field":"hair","value":"pirang","tag":"explicit","citations":[]}]}
''';
      expect(
        () => CharacterTraitExtractor.parseProposals(json),
        throwsFormatException,
      );
    });

    test('field di luar whitelist profil ditolak', () {
      const json = '''
{"traits":[{"field":"biography","value":"panjang sekali",
  "tag":"explicit","citations":[{"chapter":1,"quote":"x"}]}]}
''';
      expect(
        () => CharacterTraitExtractor.parseProposals(json),
        throwsFormatException,
      );
    });

    test('tag tidak dikenal jatuh ke inferred, bukan explicit', () {
      const json = '''
{"traits":[{"field":"eyes","value":"hijau","tag":"pasti",
  "citations":[{"chapter":4,"quote":"mata hijau"}]}]}
''';
      final result = CharacterTraitExtractor.parseProposals(json);
      expect(result.traits.single.tag, TraitEvidenceTag.inferred);
    });

    test('markdown fence di sekitar JSON diterima (provider chatter)', () {
      const json = '''
```json
{"traits":[{"field":"hair","value":"hitam","tag":"explicit",
  "citations":[{"chapter":7,"quote":"rambut hitam"}]}],"unknown":[]}
```
''';
      final result = CharacterTraitExtractor.parseProposals(json);
      expect(result.traits.single.field, 'hair');
    });

    test('empty traits + unknown list is a valid honest result', () {
      final result = CharacterTraitExtractor.parseProposals(
        '{"traits":[],"unknown":["hair","eyes","voice"]}',
      );
      expect(result.traits, isEmpty);
      expect(result.unknownFields.length, 3);
    });
  });

  group('buildExtractionPrompt', () {
    test('mencakup nama karakter, whitelist field, dan mandat sitasi', () {
      final prompt = CharacterTraitExtractor.buildExtractionPrompt(
        characterName: 'Narenya',
        manuscript: 'Bab 1 ...',
      );
      expect(prompt, contains('Narenya'));
      for (final field in CharacterTraitExtractor.profileFields) {
        expect(prompt, contains(field));
      }
      expect(prompt, contains('explicit'));
      expect(prompt, contains('inferred'));
      expect(prompt, contains('unknown'));
      expect(prompt, contains('chapter'));
    });

    test('manuskrip kosong ditolak (jangan kirim prompt kosong ke API)', () {
      expect(
        () => CharacterTraitExtractor.buildExtractionPrompt(
          characterName: 'X',
          manuscript: '   ',
        ),
        throwsArgumentError,
      );
    });
  });
}
