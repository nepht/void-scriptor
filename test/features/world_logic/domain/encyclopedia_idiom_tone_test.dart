// Sprint 111.35 - Tone, Connotation & Dialogue Suggestions (domain-only).
//
// RED -> GREEN. Acceptance canonical sprint_111.json:
// tone, connotation, offense_risk, examples, character_fit,
// user_initiated_insert.
//
// Konsumsi: IdiomRecord 111.33 (idiomId sebagai kunci), IdiomUsageProfile +
// IdiomRegister + SocialContext 111.34/111.30 (konteks pemakaian untuk fit).
// Murni data + query deterministik; TIDAK ADA jalur tulis ke editor/naskah.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_tone.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_usage.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart'
    show SocialContext;

IdiomUsageExample ex(
  String id,
  String text, {
  String? translation,
  SocialContext? context,
  String note = '',
}) => IdiomUsageExample.validated(
  exampleId: id,
  text: text,
  translation: translation,
  context: context,
  note: note,
);

IdiomToneProfile profile(
  String idiomId, {
  IdiomTone tone = IdiomTone.neutral,
  IdiomConnotation connotation = IdiomConnotation.neutral,
  OffenseRisk offense = OffenseRisk.harmless,
  List<IdiomUsageExample> examples = const <IdiomUsageExample>[],
  IdiomRegister? registerHint,
  String note = '',
}) => IdiomToneProfile.validated(
  idiomId: idiomId,
  tone: tone,
  connotation: connotation,
  offenseRisk: offense,
  examples: examples,
  registerHint: registerHint,
  note: note,
);

CharacterVoiceProfile voice(
  String characterId, {
  Set<IdiomTone> preferred = const <IdiomTone>{},
  Set<IdiomTone> avoided = const <IdiomTone>{},
  OffenseRisk tolerance = OffenseRisk.moderate,
  String? cultureId,
  List<String> professions = const <String>[],
  String? displayName,
}) => CharacterVoiceProfile.validated(
  characterId: characterId,
  displayName: displayName,
  preferredTones: preferred,
  avoidedTones: avoided,
  offenseTolerance: tolerance,
  cultureId: cultureId,
  professionIds: professions,
);

IdiomUsageProfile usage(
  String idiomId, {
  List<IdiomCultureRef> cultures = const <IdiomCultureRef>[],
  List<IdiomContextUsage> contexts = const <IdiomContextUsage>[],
  List<IdiomEraRange> eras = const <IdiomEraRange>[],
}) => IdiomUsageProfile.validated(
  idiomId: idiomId,
  cultures: cultures,
  contexts: contexts,
  eras: eras,
);

void main() {
  const adviser = IdiomDialogueAdviser();

  group('IdiomTone', () {
    test('memiliki label untuk tiap nada', () {
      for (final tone in IdiomTone.values) {
        expect(tone.label.trim(), isNotEmpty);
      }
      expect(IdiomTone.values, hasLength(10));
    });

    test('fromName roundtrip untuk semua nilai', () {
      for (final tone in IdiomTone.values) {
        expect(IdiomTone.fromName(tone.name), same(tone));
      }
    });
  });

  group('IdiomConnotation', () {
    test('valence: positive +1, negative -1, netral/ambivalen 0', () {
      expect(IdiomConnotation.positive.valence, 1);
      expect(IdiomConnotation.negative.valence, -1);
      expect(IdiomConnotation.neutral.valence, 0);
      expect(IdiomConnotation.ambivalent.valence, 0);
    });

    test('hanya ambivalent yang bersisi ganda', () {
      for (final c in IdiomConnotation.values) {
        expect(c.isDoubleEdged, c == IdiomConnotation.ambivalent);
      }
    });
  });

  group('OffenseRisk', () {
    test('tangga bobot strictly increasing', () {
      for (var i = 1; i < OffenseRisk.values.length; i++) {
        expect(
          OffenseRisk.values[i].weight,
          greaterThan(OffenseRisk.values[i - 1].weight),
        );
      }
    });

    test('atLeast refleksif dan tertata pada tangga', () {
      expect(OffenseRisk.moderate.atLeast(OffenseRisk.moderate), isTrue);
      expect(OffenseRisk.high.atLeast(OffenseRisk.moderate), isTrue);
      expect(OffenseRisk.mild.atLeast(OffenseRisk.moderate), isFalse);
    });

    test('blockingInSacred hanya untuk high/severe', () {
      expect(OffenseRisk.harmless.blockingInSacred, isFalse);
      expect(OffenseRisk.moderate.blockingInSacred, isFalse);
      expect(OffenseRisk.high.blockingInSacred, isTrue);
      expect(OffenseRisk.severe.blockingInSacred, isTrue);
    });
  });

  group('IdiomUsageExample.validated', () {
    test('mempangkas field teks', () {
      final e = ex(' e1 ', '  Payah seperti lembu ke pasar.  ', note: ' hi ');
      expect(e.exampleId, 'e1');
      expect(e.text, 'Payah seperti lembu ke pasar.');
      expect(e.note, 'hi');
    });

    test('menolak exampleId kosong', () {
      expect(() => ex('   ', 'teks'), throwsArgumentError);
    });

    test('menolak text kosong', () {
      expect(() => ex('e1', '   '), throwsArgumentError);
    });

    test('translation blank menjadi null, non-blank dipangkas', () {
      final a = ex('e1', 'teks', translation: '   ');
      final b = ex('e2', 'teks', translation: '  literal  ');
      expect(a.hasTranslation, isFalse);
      expect(a.translation, isNull);
      expect(b.hasTranslation, isTrue);
      expect(b.translation, 'literal');
    });

    test('context boleh null (umum) dan dipertahankan saat terisi', () {
      expect(ex('e1', 't').context, isNull);
      expect(
        ex('e1', 't', context: SocialContext.everyday).context,
        SocialContext.everyday,
      );
    });

    test('equality struktural dan hashCode', () {
      expect(ex('e1', 't', note: 'n'), ex('e1', 't', note: 'n'));
      expect(ex('e1', 't').hashCode, ex('e1', 't').hashCode);
      expect(ex('e1', 't'), isNot(ex('e1', 'lain')));
    });

    test('JSON roundtrip byte-identik', () {
      final e = ex(
        'e1',
        'teks',
        translation: 'lit',
        context: SocialContext.formal,
        note: 'n',
      );
      final back = IdiomUsageExample.fromJson(
        jsonDecode(jsonEncode(e.toJson())) as Map<String, Object?>,
      );
      expect(jsonEncode(back.toJson()), jsonEncode(e.toJson()));
    });
  });

  group('IdiomToneProfile.validated', () {
    test('menolak idiomId kosong', () {
      expect(
        () => IdiomToneProfile.validated(
          idiomId: '  ',
          tone: IdiomTone.playful,
          connotation: IdiomConnotation.neutral,
          offenseRisk: OffenseRisk.harmless,
        ),
        throwsArgumentError,
      );
    });

    test('guard duplikat exampleId', () {
      expect(
        () => profile(
          'i1',
          examples: <IdiomUsageExample>[ex('a', 'x'), ex('a', 'y')],
        ),
        throwsArgumentError,
      );
    });

    test('koleksi examples immutable', () {
      final p = profile('i1', examples: <IdiomUsageExample>[ex('a', 'x')]);
      expect(() => p.examples.add(ex('b', 'y')), throwsUnsupportedError);
    });

    test('exampleCount dan hasExamples', () {
      expect(profile('i1').exampleCount, 0);
      expect(profile('i1').hasExamples, isFalse);
      final p = profile('i1', examples: <IdiomUsageExample>[ex('a', 'x')]);
      expect(p.exampleCount, 1);
      expect(p.hasExamples, isTrue);
    });

    test('registerHint null berarti tanpa petunjuk', () {
      expect(profile('i1').registerHint, isNull);
      expect(
        profile('i1', registerHint: IdiomRegister.vulgar).registerHint,
        IdiomRegister.vulgar,
      );
    });

    test('exampleForContext: contoh umum (context null) selalu lolos', () {
      final p = profile(
        'i1',
        examples: <IdiomUsageExample>[
          ex('e2', 'umum'),
          ex('e1', 'formal-only', context: SocialContext.formal),
        ],
      );
      expect(
        p.exampleForContext(SocialContext.formal).map((e) => e.exampleId),
        <String>['e1', 'e2'],
      );
      expect(
        p.exampleForContext(SocialContext.everyday).map((e) => e.exampleId),
        <String>['e2'],
      );
    });

    test('examplesForAll terurut exampleId dan immutable', () {
      final p = profile(
        'i1',
        examples: <IdiomUsageExample>[ex('z', 'x'), ex('a', 'y')],
      );
      expect(p.examplesForAll.map((e) => e.exampleId), <String>['a', 'z']);
      expect(() => p.examplesForAll.add(ex('m', 'q')), throwsUnsupportedError);
    });

    test('equality struktural membandingkan examples', () {
      final a = profile('i1', examples: <IdiomUsageExample>[ex('e', 't')]);
      final b = profile('i1', examples: <IdiomUsageExample>[ex('e', 't')]);
      final c = profile('i1', examples: <IdiomUsageExample>[ex('e', 'lain')]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('JSON roundtrip byte-identik untuk profil penuh', () {
      final p = profile(
        'i1',
        tone: IdiomTone.mocking,
        connotation: IdiomConnotation.negative,
        offense: OffenseRisk.moderate,
        examples: <IdiomUsageExample>[
          ex('e1', 'teks', translation: 'lit', context: SocialContext.sacred),
          ex('e2', 'teks dua'),
        ],
        registerHint: IdiomRegister.colloquial,
        note: 'catatan',
      );
      final back = IdiomToneProfile.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, Object?>,
      );
      expect(jsonEncode(back.toJson()), jsonEncode(p.toJson()));
      expect(back, p);
    });
  });

  group('IdiomToneCatalog', () {
    test('empty memiliki nol profil', () {
      expect(IdiomToneCatalog.empty().profileCount, 0);
      expect(IdiomToneCatalog.empty().idiomIds, isEmpty);
    });

    test('guard duplikat idiomId lintas profil', () {
      expect(
        () => IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
          profile('i1'),
          profile('i1'),
        ]),
        throwsArgumentError,
      );
    });

    test('profil tersimpan terurut idiomId dan immutable', () {
      final c = IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
        profile('b'),
        profile('a'),
      ]);
      expect(c.idiomIds, <String>['a', 'b']);
      expect(() => c.profiles.add(profile('c')), throwsUnsupportedError);
    });

    test('profileFor toleran whitespace dan null saat tak ada', () {
      final c = IdiomToneCatalog.withProfiles(<IdiomToneProfile>[profile('a')]);
      expect(c.profileFor('  a  '), isNotNull);
      expect(c.profileFor('zz'), isNull);
      expect(c.profileFor('  '), isNull);
    });

    test('idiomIdsAtOrAboveOffense menyaring berdasar tangga', () {
      final c = IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
        profile('low', offense: OffenseRisk.mild),
        profile('mid', offense: OffenseRisk.moderate),
        profile('high', offense: OffenseRisk.severe),
      ]);
      expect(c.idiomIdsAtOrAboveOffense(OffenseRisk.moderate), <String>[
        'high',
        'mid',
      ]);
    });

    test('mostOffensiveIdiomId: tie-break idiomId asc, null saat kosong', () {
      final c = IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
        profile('zz', offense: OffenseRisk.high),
        profile('aa', offense: OffenseRisk.high),
        profile('mm', offense: OffenseRisk.mild),
      ]);
      expect(c.mostOffensiveIdiomId(), 'aa');
      expect(IdiomToneCatalog.empty().mostOffensiveIdiomId(), isNull);
    });

    test('totalExampleCount menjumlah semua profil', () {
      final c = IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
        profile('a', examples: <IdiomUsageExample>[ex('1', 'x'), ex('2', 'y')]),
        profile('b', examples: <IdiomUsageExample>[ex('3', 'z')]),
      ]);
      expect(c.totalExampleCount, 3);
    });

    test('tonesInUse terurut index enum dan dedup', () {
      final c = IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
        profile('a', tone: IdiomTone.mocking),
        profile('b', tone: IdiomTone.mocking),
        profile('c', tone: IdiomTone.neutral),
      ]);
      expect(c.tonesInUse(), <IdiomTone>[IdiomTone.neutral, IdiomTone.mocking]);
    });

    test('JSON roundtrip mempertahankan urutan katalog', () {
      final c = IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
        profile('b', tone: IdiomTone.solemn),
        profile('a', tone: IdiomTone.warm),
      ]);
      final back = IdiomToneCatalog.fromJson(
        jsonDecode(jsonEncode(c.toJson())) as Map<String, Object?>,
      );
      expect(jsonEncode(back.toJson()), jsonEncode(c.toJson()));
      expect(back.idiomIds, <String>['a', 'b']);
    });
  });

  group('CharacterVoiceProfile.validated', () {
    test('menolak characterId kosong', () {
      expect(
        () => CharacterVoiceProfile.validated(characterId: '  '),
        throwsArgumentError,
      );
    });

    test('offenseTolerance default moderate', () {
      expect(
        CharacterVoiceProfile.validated(characterId: 'c1').offenseTolerance,
        OffenseRisk.moderate,
      );
    });

    test('displayName dan cultureId blank menjadi null', () {
      final p = CharacterVoiceProfile.validated(
        characterId: 'c1',
        displayName: '  ',
        cultureId: '   ',
      );
      expect(p.displayName, isNull);
      expect(p.cultureId, isNull);
    });

    test('tone yang sama di preferred dan avoided ditolak', () {
      expect(
        () => CharacterVoiceProfile.validated(
          characterId: 'c1',
          preferredTones: <IdiomTone>{IdiomTone.playful},
          avoidedTones: <IdiomTone>{IdiomTone.playful},
        ),
        throwsArgumentError,
      );
    });

    test('professionIds dipangkas, didedup, terurut, immutable', () {
      final p = CharacterVoiceProfile.validated(
        characterId: 'c1',
        professionIds: <String>[' notaris ', 'pelaut', 'pelaut'],
      );
      expect(p.professionIds, <String>['notaris', 'pelaut']);
      expect(() => p.professionIds.add('x'), throwsUnsupportedError);
    });

    test('menolak professionId whitespace-only eksplisit', () {
      expect(
        () => CharacterVoiceProfile.validated(
          characterId: 'c1',
          professionIds: <String>['   '],
        ),
        throwsArgumentError,
      );
    });

    test('prefersTone/avoidsTone membaca set nada', () {
      final p = CharacterVoiceProfile.validated(
        characterId: 'c1',
        preferredTones: <IdiomTone>{IdiomTone.bitter},
        avoidedTones: <IdiomTone>{IdiomTone.solemn},
      );
      expect(p.prefersTone(IdiomTone.bitter), isTrue);
      expect(p.prefersTone(IdiomTone.warm), isFalse);
      expect(p.avoidsTone(IdiomTone.solemn), isTrue);
    });

    test('JSON roundtrip byte-identik', () {
      final p = voice(
        'c1',
        displayName: 'Naya',
        preferred: <IdiomTone>{IdiomTone.mocking, IdiomTone.bitter},
        avoided: <IdiomTone>{IdiomTone.mournful},
        tolerance: OffenseRisk.high,
        cultureId: 'pantai',
        professions: <String>['pelaut'],
      );
      final back = CharacterVoiceProfile.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, Object?>,
      );
      expect(jsonEncode(back.toJson()), jsonEncode(p.toJson()));
      expect(back, p);
    });
  });

  group('CharacterFitVerdict', () {
    test('rank terurut dari ideal ke inappropriate', () {
      expect(CharacterFitVerdict.ideal.rank, 0);
      expect(CharacterFitVerdict.comfortable.rank, 1);
      expect(CharacterFitVerdict.strained.rank, 2);
      expect(CharacterFitVerdict.inappropriate.rank, 3);
    });
  });

  group('adviser.fitFor (character_fit)', () {
    test('nada disukai + offense dalam toleransi = skor 3 ideal', () {
      final f = adviser.fitFor(
        profile: profile('i1', tone: IdiomTone.playful),
        character: voice(
          'c1',
          preferred: <IdiomTone>{IdiomTone.playful},
          tolerance: OffenseRisk.moderate,
        ),
        offense: OffenseRisk.mild,
      );
      expect(f.score, 3);
      expect(f.verdict, CharacterFitVerdict.ideal);
      expect(f.reasons, hasLength(2));
    });

    test('nada dihindari mem-floor verdict ke inappropriate', () {
      final f = adviser.fitFor(
        profile: profile('i1', tone: IdiomTone.mournful),
        character: voice('c1', avoided: <IdiomTone>{IdiomTone.mournful}),
      );
      expect(f.verdict, CharacterFitVerdict.inappropriate);
      expect(f.isBlockedByAvoidedTone, isTrue);
    });

    test('offense melewati toleransi memberi -2', () {
      final f = adviser.fitFor(
        profile: profile('i1', tone: IdiomTone.neutral),
        character: voice('c1', tolerance: OffenseRisk.mild),
        offense: OffenseRisk.severe,
      );
      expect(f.score, -2);
      expect(f.verdict, CharacterFitVerdict.inappropriate);
    });

    test('tanpa preferensi: skor 1 comfortable (hanya bonus toleransi)', () {
      final f = adviser.fitFor(
        profile: profile('i1'),
        character: voice('c1'),
        offense: OffenseRisk.harmless,
      );
      expect(f.score, 1);
      expect(f.verdict, CharacterFitVerdict.comfortable);
    });

    test('budaya menghindari lewat usage 111.34 mem-floor', () {
      final u = usage(
        'i1',
        cultures: <IdiomCultureRef>[
          IdiomCultureRef.validated(
            cultureId: 'pegunungan',
            stance: IdiomUseStance.avoided,
          ),
        ],
      );
      final f = adviser.fitFor(
        profile: profile('i1'),
        character: voice('c1', cultureId: 'pegunungan'),
        usage: u,
      );
      expect(f.verdict, CharacterFitVerdict.inappropriate);
      expect(f.isBlockedByAvoidedTone, isFalse);
      expect(
        f.reasons.any((r) => r.contains('budaya')),
        isTrue,
        reason: 'alasan budaya-penghindar harus disebut',
      );
    });

    test('budaya memakai memberi +1', () {
      final u = usage(
        'i1',
        cultures: <IdiomCultureRef>[
          IdiomCultureRef.validated(cultureId: 'pantai'),
        ],
      );
      final f = adviser.fitFor(
        profile: profile('i1'),
        character: voice('c1', cultureId: 'pantai'),
        usage: u,
      );
      expect(f.score, 2);
      expect(f.verdict, CharacterFitVerdict.comfortable);
    });

    test('konteks tak lazim menurut usage memberi -2', () {
      final u = usage(
        'i1',
        contexts: <IdiomContextUsage>[
          IdiomContextUsage.validated(
            context: SocialContext.everyday,
            register: IdiomRegister.colloquial,
          ),
        ],
      );
      final f = adviser.fitFor(
        profile: profile('i1'),
        character: voice('c1'),
        usage: u,
        context: SocialContext.sacred,
      );
      expect(f.score, -1);
      expect(f.verdict, CharacterFitVerdict.strained);
    });

    test('offense tinggi di konteks sakral menambah alasan blocking', () {
      final f = adviser.fitFor(
        profile: profile('i1', offense: OffenseRisk.high),
        character: voice('c1', tolerance: OffenseRisk.severe),
        context: SocialContext.sacred,
      );
      expect(
        f.reasons.any((r) => r.contains('sakral')),
        isTrue,
        reason: 'risiko tinggi di konteks sakral wajib dijelaskan',
      );
      expect(f.score, lessThan(0));
    });

    test('era tak aktif menurut usage memberi -2', () {
      final u = usage(
        'i1',
        eras: <IdiomEraRange>[
          IdiomEraRange.validated(
            eraId: 'e1',
            label: 'Lama',
            fromMarker: 'm01',
            toMarker: 'm02',
          ),
        ],
      );
      final f = adviser.fitFor(
        profile: profile('i1'),
        character: voice('c1'),
        usage: u,
        atMarker: 'm09',
      );
      expect(f.score, -1);
    });

    test('describe memuat idiomId, characterId, dan verdict', () {
      final f = adviser.fitFor(
        profile: profile('i1', tone: IdiomTone.warm),
        character: voice('c1'),
      );
      expect(f.idiomId, 'i1');
      expect(f.characterId, 'c1');
      expect(f.describe(), contains('i1'));
      expect(f.describe(), contains('c1'));
    });

    test('assessment immutable dan JSON roundtrip', () {
      final f = adviser.fitFor(
        profile: profile('i1', tone: IdiomTone.ironic),
        character: voice('c1', preferred: <IdiomTone>{IdiomTone.ironic}),
      );
      expect(() => f.reasons.add('x'), throwsUnsupportedError);
      final back = CharacterFitAssessment.fromJson(
        jsonDecode(jsonEncode(f.toJson())) as Map<String, Object?>,
      );
      expect(jsonEncode(back.toJson()), jsonEncode(f.toJson()));
    });
  });

  group('DialogueSuggestion & user_initiated_insert', () {
    final fit = CharacterFitAssessment.of(
      idiomId: 'i1',
      characterId: 'c1',
      score: 3,
      reasons: <String>['r1'],
    );
    final suggestion = DialogueSuggestion.of(
      profile: profile('i1', tone: IdiomTone.mocking),
      example: ex('e1', 'Mengelak bagai kucing kena air.', translation: 'lit'),
      fit: fit,
    );

    test('suggestion membawa idiom, contoh, dan verdict', () {
      expect(suggestion.idiomId, 'i1');
      expect(suggestion.exampleId, 'e1');
      expect(suggestion.text, 'Mengelak bagai kucing kena air.');
      expect(suggestion.verdict, CharacterFitVerdict.ideal);
    });

    test('insertionRequest menghasilkan data userInitiated eksplisit', () {
      final req = suggestion.insertionRequest();
      expect(req.origin, 'userInitiated');
      expect(req.idiomId, 'i1');
      expect(req.exampleId, 'e1');
      expect(req.text, suggestion.text);
    });

    test('insertionRequest deterministik: dua panggilan setara', () {
      expect(suggestion.insertionRequest(), suggestion.insertionRequest());
    });

    test('idiomId suggestion wajib sama dengan fit.idiomId', () {
      expect(
        () => DialogueSuggestion.of(
          profile: profile('i1'),
          example: ex('e1', 'x'),
          fit: CharacterFitAssessment.of(
            idiomId: 'i2',
            characterId: 'c1',
            score: 0,
            reasons: const <String>[],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('ExplicitInsertionRequest JSON roundtrip', () {
      final req = suggestion.insertionRequest();
      final back = ExplicitInsertionRequest.fromJson(
        jsonDecode(jsonEncode(req.toJson())) as Map<String, Object?>,
      );
      expect(back, req);
      expect(jsonEncode(back.toJson()), jsonEncode(req.toJson()));
    });
  });

  group('adviser.suggestionsFor', () {
    final toneCatalog = IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
      profile(
        'z-bitter',
        tone: IdiomTone.bitter,
        examples: <IdiomUsageExample>[ex('b1', 'payah'), ex('b0', 'aceran')],
      ),
      profile(
        'a-warm',
        tone: IdiomTone.warm,
        examples: <IdiomUsageExample>[ex('w1', 'hangat')],
      ),
      profile(
        'm-taboo',
        tone: IdiomTone.warm,
        offense: OffenseRisk.severe,
        examples: <IdiomUsageExample>[ex('s1', 'terlarang')],
      ),
    ]);
    final character = voice(
      'c1',
      preferred: <IdiomTone>{IdiomTone.warm},
      tolerance: OffenseRisk.moderate,
    );

    test('nada yang disukai karakter menempati saran teratas', () {
      final out = adviser.suggestionsFor(
        catalog: toneCatalog,
        character: character,
        maxResults: 1,
      );
      expect(out, hasLength(1));
      expect(out.first.idiomId, 'a-warm');
    });

    test('verdict inappropriate dikecualikan dari saran', () {
      final out = adviser.suggestionsFor(
        catalog: toneCatalog,
        character: voice('c2', tolerance: OffenseRisk.harmless),
      );
      expect(out.map((s) => s.idiomId), isNot(contains('m-taboo')));
    });

    test('seri verdict: idiomId asc lalu exampleId asc', () {
      final out = adviser.suggestionsFor(
        catalog: toneCatalog,
        character: voice('c3'),
        maxResults: 10,
      );
      expect(out.first.idiomId, 'a-warm');
      final bitter = out.where((s) => s.idiomId == 'z-bitter').toList();
      expect(bitter.map((s) => s.exampleId), <String>['b0', 'b1']);
    });

    test('usageCatalog: konteks sacred menyingkirkan yang tak lazim', () {
      final usageCatalog = IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
        usage(
          'a-warm',
          contexts: <IdiomContextUsage>[
            IdiomContextUsage.validated(
              context: SocialContext.everyday,
              register: IdiomRegister.colloquial,
            ),
          ],
        ),
      ]);
      final out = adviser.suggestionsFor(
        catalog: toneCatalog,
        character: character,
        context: SocialContext.sacred,
        usageCatalog: usageCatalog,
      );
      expect(out.map((s) => s.idiomId), isNot(contains('a-warm')));
    });

    test('atMarker menyingkirkan ungkapan non-aktif di era', () {
      final usageCatalog = IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
        usage(
          'a-warm',
          eras: <IdiomEraRange>[
            IdiomEraRange.validated(
              eraId: 'e1',
              label: 'Lama',
              fromMarker: 'm05',
              toMarker: 'm06',
            ),
          ],
        ),
      ]);
      final outNow = adviser.suggestionsFor(
        catalog: toneCatalog,
        character: character,
        atMarker: 'm09',
        usageCatalog: usageCatalog,
      );
      final outThen = adviser.suggestionsFor(
        catalog: toneCatalog,
        character: character,
        atMarker: 'm05',
        usageCatalog: usageCatalog,
      );
      expect(outNow.map((s) => s.idiomId), isNot(contains('a-warm')));
      expect(outThen.map((s) => s.idiomId), contains('a-warm'));
    });

    test('profil tanpa contoh lolos-konteks tidak menghasilkan saran', () {
      final out = adviser.suggestionsFor(
        catalog: IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
          profile('no-examples'),
        ]),
        character: voice('c1'),
      );
      expect(out, isEmpty);
    });

    test('maxResults divalidasi 1..512', () {
      expect(
        adviser.suggestionsFor(
          catalog: toneCatalog,
          character: voice('c1'),
          maxResults: 1,
        ),
        hasLength(1),
      );
      expect(
        () => adviser.suggestionsFor(
          catalog: toneCatalog,
          character: voice('c1'),
          maxResults: 0,
        ),
        throwsArgumentError,
      );
    });

    test('katalog kosong menghasilkan list kosong', () {
      expect(
        adviser.suggestionsFor(
          catalog: IdiomToneCatalog.empty(),
          character: voice('c1'),
        ),
        isEmpty,
      );
    });

    test('user_initiated_insert: saran dan request TIDAK memutasi input', () {
      final catalogJson = jsonEncode(toneCatalog.toJson());
      final voiceJson = jsonEncode(character.toJson());
      final out = adviser.suggestionsFor(
        catalog: toneCatalog,
        character: character,
      );
      for (final s in out) {
        s.insertionRequest();
      }
      expect(jsonEncode(toneCatalog.toJson()), catalogJson);
      expect(jsonEncode(character.toJson()), voiceJson);
    });

    test('determinisme: input sama -> output byte-identik', () {
      final a = adviser
          .suggestionsFor(catalog: toneCatalog, character: voice('c9'))
          .map((s) => s.insertionRequest().toJson())
          .toList();
      final b = adviser
          .suggestionsFor(catalog: toneCatalog, character: voice('c9'))
          .map((s) => s.insertionRequest().toJson())
          .toList();
      expect(a, isNotEmpty);
      expect(jsonEncode(a), jsonEncode(b));
    });
  });
}
