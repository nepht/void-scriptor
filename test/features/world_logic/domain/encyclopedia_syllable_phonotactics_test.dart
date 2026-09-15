// Sprint 111.29 - Syllable Pool & Phonotactic Rules (domain-only).
//
// Acceptance canonical dipetakan:
// - syllable_parts      -> SyllablePart/SyllableSlot (onset, nucleus, coda)
// - patterns            -> SyllablePattern.parse (template C/V, grup opsional)
// - weights             -> SyllablePattern.weight + massa derivatif SyllableMass
// - stress_rules        -> StressRule/StressKind, indeks deterministik
// - forbidden_sequences -> ForbiddenSequence.occursIn + spec.violationsIn
// - conlang_links       -> PhonotacticsConlangLink + resolveLanguageLinks
//
// Domain murni: tanpa persistence, UI, locale, jaringan, wall-clock, random.
// D-SCHEMA-01 tetap OPEN.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_syllable_phonotactics.dart';

SyllablePart part(String symbol, List<SyllableSlot> slots) =>
    SyllablePart.validated(symbol: symbol, slots: slots);

SyllablePattern pattern(String id, String template, {int weight = 1}) =>
    SyllablePattern.parse(id: id, template: template, weight: weight);

PhonotacticsSpec buildSpec({
  String defaultStressRuleId = 'stress-latin',
  List<StressRule> stressRules = const [],
  List<ForbiddenSequence> forbidden = const [],
  List<PhonotacticsConlangLink> links = const [],
}) {
  return PhonotacticsSpec.validated(
    id: 'spec-void-tongue',
    languageId: 'lang-voidish',
    inventory: <SyllablePart>[
      part('k', <SyllableSlot>[SyllableSlot.onset, SyllableSlot.coda]),
      part('t', <SyllableSlot>[SyllableSlot.onset, SyllableSlot.coda]),
      part('r', <SyllableSlot>[SyllableSlot.onset]),
      part('a', <SyllableSlot>[SyllableSlot.nucleus]),
      part('i', <SyllableSlot>[SyllableSlot.nucleus]),
    ],
    patterns: <SyllablePattern>[
      pattern('cv', 'CV'),
      pattern('cvc', 'CVC', weight: 2),
      pattern('open', '(C)V(C)', weight: 1),
    ],
    stressRules: <StressRule>[
      if (stressRules.isNotEmpty)
        ...stressRules
      else
        StressRule(id: 'stress-initial', kind: StressKind.initial),
      StressRule(id: 'stress-latin', kind: StressKind.latinPenult),
    ],
    defaultStressRuleId: defaultStressRuleId.isEmpty
        ? null
        : defaultStressRuleId,
    forbidden: forbidden,
    conlangLinks: links.isEmpty
        ? <PhonotacticsConlangLink>[
            PhonotacticsConlangLink(
              targetLanguageId: 'lang-voidish',
              kind: ConlangLinkKind.primary,
            ),
          ]
        : links,
  );
}

void main() {
  group('SyllablePart (syllable_parts)', () {
    test('menyimpan symbol dengan daftar slot canonically ordered', () {
      final p = part('k', <SyllableSlot>[
        SyllableSlot.coda,
        SyllableSlot.onset,
        SyllableSlot.coda,
      ]);
      expect(p.slots, <SyllableSlot>[SyllableSlot.onset, SyllableSlot.coda]);
      expect(p.canOccurIn(SyllableSlot.onset), isTrue);
      expect(p.canOccurIn(SyllableSlot.nucleus), isFalse);
    });

    test('symbol dipangkas dan tidak boleh kosong', () {
      expect(
        () => part('  ', <SyllableSlot>[SyllableSlot.onset]),
        throwsArgumentError,
      );
      final p = part(' k ', <SyllableSlot>[SyllableSlot.onset]);
      expect(p.symbol, 'k');
    });

    test('slot kosong ditolak', () {
      expect(() => part('k', <SyllableSlot>[]), throwsArgumentError);
    });

    test('koleksi slot immutable', () {
      final p = part('k', <SyllableSlot>[SyllableSlot.onset]);
      expect(() => p.slots.add(SyllableSlot.coda), throwsUnsupportedError);
    });
  });

  group('SyllablePattern (patterns)', () {
    test('parse template murni C/V menjadi posisi slot', () {
      final p = pattern('cvc', 'CVC');
      expect(p.positions.map((e) => e.slot), <SyllableSlot>[
        SyllableSlot.onset,
        SyllableSlot.nucleus,
        SyllableSlot.coda,
      ]);
      expect(p.positions.every((e) => !e.optional), isTrue);
      expect(p.template, 'CVC');
    });

    test('grup kurung menandai posisi opsional', () {
      final p = pattern('open', '(C)V(C)');
      expect(p.positions.length, 3);
      expect(p.positions[0].optional, isTrue);
      expect(p.positions[1].optional, isFalse);
      expect(p.positions[2].optional, isTrue);
      expect(p.template, '(C)V(C)');
    });

    test('template tanpa vokal ditolak', () {
      expect(() => pattern('bad', 'CC'), throwsArgumentError);
    });

    test('karakter tak dikenal dan kurung tak seimbang ditolak', () {
      expect(() => pattern('bad', 'CXV'), throwsArgumentError);
      expect(() => pattern('bad', '(CVC'), throwsArgumentError);
      expect(() => pattern('bad', ''), throwsArgumentError);
    });

    test('id kosong ditolak', () {
      expect(() => pattern('  ', 'CV'), throwsArgumentError);
    });

    test('weight negatif ditolak', () {
      expect(() => pattern('cv', 'CV', weight: -1), throwsArgumentError);
    });

    test('matches menerima urutan slot yang cocok persis', () {
      final p = pattern('cvc', 'CVC');
      expect(
        p.matches(const <SyllableSlot>[
          SyllableSlot.onset,
          SyllableSlot.nucleus,
          SyllableSlot.coda,
        ]),
        isTrue,
      );
      expect(
        p.matches(const <SyllableSlot>[
          SyllableSlot.onset,
          SyllableSlot.nucleus,
        ]),
        isFalse,
      );
      expect(
        p.matches(const <SyllableSlot>[
          SyllableSlot.nucleus,
          SyllableSlot.nucleus,
          SyllableSlot.coda,
        ]),
        isFalse,
      );
    });

    test('matches melewati posisi opsional yang absen', () {
      final p = pattern('open', '(C)V(C)');
      expect(p.matches(const <SyllableSlot>[SyllableSlot.nucleus]), isTrue);
      expect(
        p.matches(const <SyllableSlot>[
          SyllableSlot.onset,
          SyllableSlot.nucleus,
        ]),
        isTrue,
      );
      expect(
        p.matches(const <SyllableSlot>[
          SyllableSlot.nucleus,
          SyllableSlot.coda,
        ]),
        isTrue,
      );
      expect(
        p.matches(const <SyllableSlot>[
          SyllableSlot.onset,
          SyllableSlot.nucleus,
          SyllableSlot.coda,
        ]),
        isTrue,
      );
    });

    test('matches menolak slot berlebih dibanding posisi', () {
      final p = pattern('open', '(C)V(C)');
      expect(
        p.matches(const <SyllableSlot>[
          SyllableSlot.onset,
          SyllableSlot.nucleus,
          SyllableSlot.coda,
          SyllableSlot.coda,
        ]),
        isFalse,
      );
    });
  });

  group('SyllableMass (weights)', () {
    test('CV tanpa coda = light', () {
      expect(pattern('cv', 'CV').mass, SyllableMass.light);
    });

    test('satu coda = heavy', () {
      expect(pattern('cvc', 'CVC').mass, SyllableMass.heavy);
    });

    test('nukleus ganda (vokal panjang/diftong) = heavy', () {
      expect(pattern('cvv', 'CVV').mass, SyllableMass.heavy);
    });

    test('coda ganda = superheavy', () {
      expect(pattern('cvcc', 'CVCC').mass, SyllableMass.superheavy);
    });

    test('nukleus ganda dengan coda = superheavy', () {
      expect(pattern('cvvc', 'CVVC').mass, SyllableMass.superheavy);
    });

    test('weight numerik tersimpan dan ikut terserialisasi', () {
      final p = pattern('cvc', 'CVC', weight: 3);
      expect(p.weight, 3);
      expect(p.toJson()['weight'], 3);
    });

    test('urutan massa increasing deterministik via index', () {
      expect(SyllableMass.light.index < SyllableMass.heavy.index, isTrue);
      expect(SyllableMass.heavy.index < SyllableMass.superheavy.index, isTrue);
    });
  });

  group('StressRule (stress_rules)', () {
    test('initial selalu indeks 0', () {
      final r = StressRule(id: 's', kind: StressKind.initial);
      expect(
        r.stressedIndex(const <SyllableMass>[
          SyllableMass.light,
          SyllableMass.heavy,
        ]),
        0,
      );
    });

    test('ultimate selalu indeks terakhir', () {
      final r = StressRule(id: 's', kind: StressKind.ultimate);
      expect(
        r.stressedIndex(const <SyllableMass>[
          SyllableMass.light,
          SyllableMass.light,
          SyllableMass.heavy,
        ]),
        2,
      );
    });

    test('penult dengan fallback untuk kata pendek', () {
      final r = StressRule(id: 's', kind: StressKind.penult);
      expect(r.stressedIndex(const <SyllableMass>[SyllableMass.light]), 0);
      expect(
        r.stressedIndex(const <SyllableMass>[
          SyllableMass.light,
          SyllableMass.light,
          SyllableMass.light,
        ]),
        1,
      );
    });

    test('antepenult dengan clamp indeks', () {
      final r = StressRule(id: 's', kind: StressKind.antepenult);
      expect(r.stressedIndex(const <SyllableMass>[SyllableMass.light]), 0);
      expect(
        r.stressedIndex(const <SyllableMass>[
          SyllableMass.light,
          SyllableMass.light,
          SyllableMass.light,
          SyllableMass.light,
        ]),
        1,
      );
    });

    test('latinPenult: penult berat menang, selainnya antepenult', () {
      final r = StressRule(id: 's', kind: StressKind.latinPenult);
      expect(
        r.stressedIndex(const <SyllableMass>[
          SyllableMass.light,
          SyllableMass.heavy,
          SyllableMass.light,
        ]),
        1,
      );
      expect(
        r.stressedIndex(const <SyllableMass>[
          SyllableMass.light,
          SyllableMass.light,
          SyllableMass.light,
        ]),
        0,
      );
      expect(
        r.stressedIndex(const <SyllableMass>[
          SyllableMass.light,
          SyllableMass.superheavy,
        ]),
        0,
      );
    });

    test('rightmostHeavyOrFinal: kanan-terberat, fallback akhir', () {
      final r = StressRule(id: 's', kind: StressKind.rightmostHeavyOrFinal);
      expect(
        r.stressedIndex(const <SyllableMass>[
          SyllableMass.heavy,
          SyllableMass.light,
          SyllableMass.superheavy,
          SyllableMass.light,
        ]),
        2,
      );
      expect(
        r.stressedIndex(const <SyllableMass>[
          SyllableMass.light,
          SyllableMass.light,
        ]),
        1,
      );
    });

    test(' daftar kosong melempar StateError', () {
      final r = StressRule(id: 's', kind: StressKind.initial);
      expect(() => r.stressedIndex(const <SyllableMass>[]), throwsStateError);
    });

    test('id kosong ditolak', () {
      expect(
        () => StressRule(id: ' ', kind: StressKind.initial),
        throwsArgumentError,
      );
    });
  });

  group('ForbiddenSequence (forbidden_sequences)', () {
    ForbiddenSequence seq(String id, List<String> symbols) =>
        ForbiddenSequence.validated(id: id, symbols: symbols);

    test('symbols dipangkas dan minimal satu, tidak boleh kosong', () {
      final s = seq('no-kt', <String>[' k ', 't']);
      expect(s.symbols, <String>['k', 't']);
      expect(() => seq('x', <String>[]), throwsArgumentError);
      expect(() => seq('x', <String>[' ']), throwsArgumentError);
    });

    test('note kosong diizinkan dan dipangkas', () {
      final s = ForbiddenSequence.validated(
        id: 'x',
        symbols: const <String>['k'],
        note: '  larangan koda  ',
      );
      expect(s.note, 'larangan koda');
      final bare = ForbiddenSequence.validated(
        id: 'y',
        symbols: const <String>['k'],
      );
      expect(bare.note, '');
    });

    test('occursIn mendeteksi sub-list berurutan', () {
      final s = seq('no-kt', <String>['k', 't']);
      expect(s.occursIn(const <String>['a', 'k', 't', 'a']), isTrue);
      expect(s.occursIn(const <String>['a', 'k', 'a', 't']), isFalse);
      expect(s.occursIn(const <String>[]), isFalse);
    });

    test('immutable', () {
      final s = seq('no-kt', <String>['k', 't']);
      expect(() => s.symbols.add('r'), throwsUnsupportedError);
    });
  });

  group('PhonotacticsConlangLink (conlang_links)', () {
    test('target kosong ditolak', () {
      expect(
        () => PhonotacticsConlangLink(
          targetLanguageId: ' ',
          kind: ConlangLinkKind.primary,
        ),
        throwsArgumentError,
      );
    });

    test('toJson/fromJson stabil', () {
      final l = PhonotacticsConlangLink(
        targetLanguageId: 'lang-old-void',
        kind: ConlangLinkKind.cognate,
        note: 'bahasa leluhur',
      );
      final back = PhonotacticsConlangLink.fromJson(l.toJson());
      expect(back.targetLanguageId, 'lang-old-void');
      expect(back.kind, ConlangLinkKind.cognate);
      expect(back.note, 'bahasa leluhur');
    });
  });

  group('PhonotacticsSpec.validated (integritas agregat)', () {
    test('spesimen sehat lolos validasi', () {
      final spec = buildSpec();
      expect(spec.patternCount, 3);
      expect(spec.inventoryCount, 5);
    });

    test('id dan languageId wajib tidak kosong', () {
      expect(
        () => PhonotacticsSpec.validated(
          id: '',
          languageId: 'l',
          inventory: buildSpec().inventory,
          patterns: buildSpec().patterns,
        ),
        throwsArgumentError,
      );
      expect(
        () => PhonotacticsSpec.validated(
          id: 's',
          languageId: '  ',
          inventory: buildSpec().inventory,
          patterns: buildSpec().patterns,
        ),
        throwsArgumentError,
      );
    });

    test('patterns minimal satu', () {
      final spec = buildSpec();
      expect(
        () => PhonotacticsSpec.validated(
          id: 's',
          languageId: 'l',
          inventory: spec.inventory,
          patterns: const <SyllablePattern>[],
        ),
        throwsArgumentError,
      );
    });

    test('duplikat symbol inventaris ditolak', () {
      final spec = buildSpec();
      expect(
        () => PhonotacticsSpec.validated(
          id: 's',
          languageId: 'l',
          inventory: <SyllablePart>[
            ...spec.inventory,
            part('k', <SyllableSlot>[SyllableSlot.onset]),
          ],
          patterns: spec.patterns,
        ),
        throwsArgumentError,
      );
    });

    test('duplikat id pattern ditolak', () {
      final spec = buildSpec();
      expect(
        () => PhonotacticsSpec.validated(
          id: 's',
          languageId: 'l',
          inventory: spec.inventory,
          patterns: <SyllablePattern>[...spec.patterns, pattern('cv', 'CVC')],
        ),
        throwsArgumentError,
      );
    });

    test('setiap slot yang dipakai pattern harus punya bagian inventaris', () {
      expect(
        () => PhonotacticsSpec.validated(
          id: 's',
          languageId: 'l',
          inventory: <SyllablePart>[
            part('k', <SyllableSlot>[SyllableSlot.onset]),
          ],
          patterns: <SyllablePattern>[pattern('cv', 'CV')],
        ),
        throwsArgumentError,
      );
    });

    test('defaultStressRuleId wajib menunjuk aturan terdaftar', () {
      final spec = buildSpec();
      expect(
        () => PhonotacticsSpec.validated(
          id: 's',
          languageId: 'l',
          inventory: spec.inventory,
          patterns: spec.patterns,
          stressRules: spec.stressRules,
          defaultStressRuleId: 'stress-unknown',
        ),
        throwsArgumentError,
      );
    });

    test('duplikat id stress rule dan forbidden sequence ditolak', () {
      final spec = buildSpec();
      expect(
        () => PhonotacticsSpec.validated(
          id: 's',
          languageId: 'l',
          inventory: spec.inventory,
          patterns: spec.patterns,
          stressRules: <StressRule>[
            StressRule(id: 'a', kind: StressKind.initial),
            StressRule(id: 'a', kind: StressKind.ultimate),
          ],
          defaultStressRuleId: null,
        ),
        throwsArgumentError,
      );
      expect(
        () => PhonotacticsSpec.validated(
          id: 's',
          languageId: 'l',
          inventory: spec.inventory,
          patterns: spec.patterns,
          defaultStressRuleId: null,
          forbidden: <ForbiddenSequence>[
            ForbiddenSequence.validated(id: 'f', symbols: const <String>['k']),
            ForbiddenSequence.validated(id: 'f', symbols: const <String>['t']),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('simbol forbidden wajib anggota inventaris', () {
      final spec = buildSpec();
      expect(
        () => PhonotacticsSpec.validated(
          id: 's',
          languageId: 'l',
          inventory: spec.inventory,
          patterns: spec.patterns,
          defaultStressRuleId: null,
          forbidden: <ForbiddenSequence>[
            ForbiddenSequence.validated(
              id: 'f',
              symbols: const <String>['k', 'z'],
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('lebih dari satu link primary ditolak', () {
      final spec = buildSpec();
      expect(
        () => PhonotacticsSpec.validated(
          id: 's',
          languageId: 'l',
          inventory: spec.inventory,
          patterns: spec.patterns,
          defaultStressRuleId: null,
          conlangLinks: <PhonotacticsConlangLink>[
            PhonotacticsConlangLink(
              targetLanguageId: 'a',
              kind: ConlangLinkKind.primary,
            ),
            PhonotacticsConlangLink(
              targetLanguageId: 'b',
              kind: ConlangLinkKind.primary,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('duplikat target link ditolak', () {
      final spec = buildSpec();
      expect(
        () => PhonotacticsSpec.validated(
          id: 's',
          languageId: 'l',
          inventory: spec.inventory,
          patterns: spec.patterns,
          defaultStressRuleId: null,
          conlangLinks: <PhonotacticsConlangLink>[
            PhonotacticsConlangLink(
              targetLanguageId: 'a',
              kind: ConlangLinkKind.primary,
            ),
            PhonotacticsConlangLink(
              targetLanguageId: 'a',
              kind: ConlangLinkKind.cognate,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('PhonotacticsSpec query surface', () {
    test('partsForSlot dan parts terurut symbol', () {
      final spec = buildSpec();
      expect(
        spec.partsForSlot(SyllableSlot.nucleus).map((p) => p.symbol),
        <String>['a', 'i'],
      );
      expect(spec.inventory.map((p) => p.symbol), <String>[
        'a',
        'i',
        'k',
        'r',
        't',
      ]);
    });

    test('koleksi agregat immutable', () {
      final spec = buildSpec();
      expect(
        () => spec.patterns.add(pattern('x', 'CV')),
        throwsUnsupportedError,
      );
      expect(
        () =>
            spec.stressRules.add(StressRule(id: 'x', kind: StressKind.initial)),
        throwsUnsupportedError,
      );
    });

    test('patternsOfMass terurut id deterministik', () {
      final spec = buildSpec();
      expect(
        spec.patternsOfMass(SyllableMass.light).map((p) => p.id),
        contains('cv'),
      );
      expect(
        spec.patternsOfMass(SyllableMass.heavy).map((p) => p.id),
        containsAll(<String>['cvc']),
      );
      expect(spec.patternsOfMass(SyllableMass.superheavy), isEmpty);
    });

    test('patternById dan stressRuleById lookup trim-tolerant', () {
      final spec = buildSpec();
      expect(spec.patternById(' cvc ')?.id, 'cvc');
      expect(spec.patternById('nope'), isNull);
      expect(spec.stressRuleById('stress-latin')?.kind, StressKind.latinPenult);
      expect(spec.stressRuleById(''), isNull);
    });

    test('violationsIn mengembalikan id terurut dan isWordLegal', () {
      final spec = buildSpec(
        forbidden: <ForbiddenSequence>[
          ForbiddenSequence.validated(
            id: 'no-kt',
            symbols: const <String>['k', 't'],
          ),
          ForbiddenSequence.validated(
            id: 'no-rr',
            symbols: const <String>['r', 'r'],
          ),
        ],
      );
      expect(
        spec.violationsIn(const <String>['a', 'k', 't', 'r', 'r']),
        <String>['no-kt', 'no-rr'],
      );
      expect(spec.violationsIn(const <String>['k', 'a', 't']), isEmpty);
      expect(spec.isWordLegal(const <String>['k', 'a', 't']), isTrue);
      expect(spec.isWordLegal(const <String>['k', 't']), isFalse);
    });

    test('stressedIndex memakai aturan default; tanpa default StateError', () {
      final spec = buildSpec();
      expect(
        spec.stressedIndex(const <SyllableMass>[
          SyllableMass.light,
          SyllableMass.heavy,
          SyllableMass.light,
        ]),
        1,
      );
      final noDefault = buildSpec(defaultStressRuleId: '');
      expect(
        () => noDefault.stressedIndex(const <SyllableMass>[SyllableMass.light]),
        throwsStateError,
      );
    });

    test('resolveLanguageLinks memisahkan target tak dikenal', () {
      final spec = buildSpec(
        links: <PhonotacticsConlangLink>[
          PhonotacticsConlangLink(
            targetLanguageId: 'lang-voidish',
            kind: ConlangLinkKind.primary,
          ),
          PhonotacticsConlangLink(
            targetLanguageId: 'lang-known',
            kind: ConlangLinkKind.cognate,
          ),
          PhonotacticsConlangLink(
            targetLanguageId: 'lang-ghost',
            kind: ConlangLinkKind.contact,
          ),
        ],
      );
      expect(
        spec.resolveLanguageLinks(const <String>{'lang-voidish', 'lang-known'}),
        <String>['lang-ghost'],
      );
      expect(
        spec.resolveLanguageLinks(const <String>{
          'lang-voidish',
          'lang-known',
          'lang-ghost',
        }),
        isEmpty,
      );
    });
  });

  group('PhonotacticsSpec JSON roundtrip', () {
    test('toJson -> fromJson -> toJson identik byte-identik', () {
      final spec = buildSpec(
        forbidden: <ForbiddenSequence>[
          ForbiddenSequence.validated(
            id: 'no-kt',
            symbols: const <String>['k', 't'],
            note: 'cluster terlarang',
          ),
        ],
      );
      final first = jsonEncode(spec.toJson());
      final back = PhonotacticsSpec.fromJson(
        jsonDecode(first) as Map<String, Object?>,
      );
      expect(jsonEncode(back.toJson()), first);
      expect(back.id, spec.id);
      expect(back.languageId, spec.languageId);
      expect(back.inventoryCount, spec.inventoryCount);
      expect(back.patternCount, spec.patternCount);
      expect(back.defaultStressRuleId, 'stress-latin');
      expect(back.violationsIn(const <String>['k', 't']), <String>['no-kt']);
    });
  });
}
