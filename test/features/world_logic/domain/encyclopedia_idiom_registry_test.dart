// Sprint 111.33 - Idiom, Proverb & Saying Registry (domain-only).
//
// Acceptance canonical dipetakan:
// - original_text       -> IdiomRecord.originalText trim non-kosong, dinormalisasi
//                          untuk pencarian; varian tak boleh meniru teks kanon
// - literal_translation -> wajib non-kosong pada record; opsional per varian
// - meaning             -> wajib non-kosong, terpisah dari terjemahan literal
// - type                -> IdiomType berlabel (idiom..other), default idiom
// - variants            -> IdiomVariant bersistem id unik + teks unik-ternormalisasi
// - language_links      -> IdiomLanguageLink reuse pola PhonotacticsConlangLink
//                          111.29 (target non-kosong, kind, max satu `original`,
//                          pasangan target+kind unik)
//
// Domain murni deterministik: tanpa persistence, UI, locale, jaringan,
// wall-clock, atau dart:math Random. D-SCHEMA-01 tetap OPEN.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_registry.dart';

// ---------------------------------------------------------------- fixtures

IdiomVariant _variant(
  String id,
  String text, {
  String? literalTranslation,
  String note = '',
}) => IdiomVariant.validated(
  variantId: id,
  text: text,
  literalTranslation: literalTranslation,
  note: note,
);

IdiomLanguageLink _link(
  String targetLanguageId,
  IdiomLinkKind kind, {
  String note = '',
}) => IdiomLanguageLink(
  targetLanguageId: targetLanguageId,
  kind: kind,
  note: note,
);

IdiomRecord buildRecord({
  String idiomId = 'id-1',
  IdiomType type = IdiomType.proverb,
  String originalText = 'Air beriak tanda tak dalam',
  String literalTranslation = 'Rippling water marks shallowness',
  String meaning = 'People who boast are usually incompetent',
  String languageId = 'elv-a',
  List<IdiomVariant> variants = const <IdiomVariant>[],
  List<IdiomLanguageLink> links = const <IdiomLanguageLink>[],
  String note = '',
}) => IdiomRecord.validated(
  idiomId: idiomId,
  type: type,
  originalText: originalText,
  literalTranslation: literalTranslation,
  meaning: meaning,
  languageId: languageId,
  variants: variants,
  links: links,
  note: note,
);

IdiomRegistry buildRegistry() {
  return IdiomRegistry.withRecords(<IdiomRecord>[
    buildRecord(
      idiomId: 'id-b',
      variants: <IdiomVariant>[
        _variant(
          'v-1',
          '  Banyu   beriak TAK jero ',
          literalTranslation: 'water rippling shows no depth',
        ),
      ],
      links: <IdiomLanguageLink>[_link('elv-b', IdiomLinkKind.cognate)],
    ),
    buildRecord(
      idiomId: 'id-a',
      type: IdiomType.idiom,
      originalText: 'Memakan kata-kata sendiri',
      literalTranslation: 'Eat ones own words',
      meaning: 'Being forced to retract a previous statement',
      languageId: 'elv-b',
      links: <IdiomLanguageLink>[
        _link('elv-b', IdiomLinkKind.original),
        _link('elv-c', IdiomLinkKind.borrowed, note: 'pinjaman sastrawi'),
      ],
    ),
    buildRecord(
      idiomId: 'id-c',
      type: IdiomType.maxim,
      originalText: 'Sedikit tapi rutin',
      literalTranslation: 'Little but steady',
      meaning: 'Consistency beats intensity',
      languageId: 'elv-a',
    ),
  ]);
}

void main() {
  group('IdiomType & IdiomLinkKind labels', () {
    test('setiap tipe punya label stabil non-kosong dan unik', () {
      final labels = IdiomType.values.map((t) => t.label).toList();
      expect(labels.toSet().length, IdiomType.values.length);
      expect(labels.every((l) => l.trim().isNotEmpty), isTrue);
      expect(IdiomType.values, contains(IdiomType.proverb));
      expect(IdiomType.values, contains(IdiomType.saying));
      expect(IdiomType.values, contains(IdiomType.other));
    });

    test('kind link punya label dan tepat satu kind `original`', () {
      expect(
        IdiomLinkKind.values.map((k) => k.label).toSet().length,
        IdiomLinkKind.values.length,
      );
      expect(
        IdiomLinkKind.values.where((k) => k == IdiomLinkKind.original),
        hasLength(1),
      );
    });
  });

  group('original_text / literal_translation / meaning wajib', () {
    test('record valid terbentuk dengan teks ternormalisasi (trim)', () {
      final r = buildRecord(originalText: ' spaces   here ');
      expect(r.originalText, 'spaces   here');
      expect(r.normalizedText, 'spaces here');
      expect(normalizeIdiomText('  A   B  '), 'a b');
      expect(r.idiomId, 'id-1');
      expect(r.type, IdiomType.proverb);
    });

    test('originalText kosong hanya spasi ditolak', () {
      expect(
        () => buildRecord(originalText: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'literalTranslation kosong ditolak (acceptance literal_translation)',
      () {
        expect(
          () => buildRecord(literalTranslation: '  '),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('meaning kosong ditolak dan dibedakan dari literalTranslation', () {
      expect(() => buildRecord(meaning: ''), throwsA(isA<ArgumentError>()));
    });

    test('languageId kosong ditolak', () {
      expect(
        () => buildRecord(languageId: ' \t '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('idiomId kosong ditolak', () {
      expect(() => buildRecord(idiomId: ''), throwsA(isA<ArgumentError>()));
    });

    test('note opsional, dipangkas; collections default immutable kosong', () {
      final r = buildRecord(note: ' text ' * 1);
      expect(r.note, 'text');
      expect(
        () => (r.variants as List).add(_variant('x', 'y')),
        throwsUnsupportedError,
      );
      expect(
        () => (r.links as List).add(_link('z', IdiomLinkKind.reference)),
        throwsUnsupportedError,
      );
    });
  });

  group('variants', () {
    test('variantId + text wajib non-kosong', () {
      expect(() => _variant('', 'text'), throwsA(isA<ArgumentError>()));
      expect(() => _variant('v', '   '), throwsA(isA<ArgumentError>()));
    });

    test('literalTranslation varian opsional', () {
      final v = _variant('v-1', 'bentuk lain');
      expect(v.hasLiteralTranslation, isFalse);
      expect(v.literalTranslation, isNull);
      final withLt = _variant('v-2', 'bentuk lain', literalTranslation: 'lt');
      expect(withLt.hasLiteralTranslation, isTrue);
    });

    test('variantId duplikat dalam satu record ditolak', () {
      expect(
        () => buildRecord(
          variants: <IdiomVariant>[
            _variant('v-dup', 'satu'),
            _variant('v-dup', 'dua'),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('teks varian sama dengan teks kanon (ternormalisasi) ditolak', () {
      expect(
        () => buildRecord(
          originalText: 'Air beriak tanda tak dalam',
          variants: <IdiomVariant>[
            _variant('v-1', '  AIR  beriak   tanda tak DALAM '),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('dua varian sesama teks identik ternormalisasi ditolak', () {
      expect(
        () => buildRecord(
          variants: <IdiomVariant>[
            _variant('v-1', 'bentuk A'),
            _variant('v-2', 'BENTUK   a'),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('lookup varian per teks toleran trim/kasus/whitespace', () {
      final r = buildRecord(
        variants: <IdiomVariant>[
          _variant('v-1', 'bentuk A'),
          _variant('v-2', 'bentuk B'),
        ],
      );
      expect(r.variantForText(' Bentuk   a ')?.variantId, 'v-1');
      expect(r.variantForText('tidak ada'), isNull);
    });
  });

  group('language_links (pola PhonotacticsConlangLink 111.29)', () {
    test('targetLanguageId wajib non-kosong dan dipangkas', () {
      final l = _link('  elv-x  ', IdiomLinkKind.cognate);
      expect(l.targetLanguageId, 'elv-x');
      expect(
        () => _link(' ', IdiomLinkKind.cognate),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('tepat satu link `original`; lebih dari satu ditolak', () {
      expect(
        () => buildRecord(
          links: <IdiomLanguageLink>[
            _link('elv-a', IdiomLinkKind.original),
            _link('elv-b', IdiomLinkKind.original),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('pasangan target+kind duplikat ditolak', () {
      expect(
        () => buildRecord(
          links: <IdiomLanguageLink>[
            _link('elv-b', IdiomLinkKind.cognate),
            _link(' elv-b ', IdiomLinkKind.cognate),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('target berbeda untuk kind sama boleh; linkFor/linksOfKind', () {
      final r = buildRecord(
        links: <IdiomLanguageLink>[
          _link('elv-b', IdiomLinkKind.cognate),
          _link('elv-c', IdiomLinkKind.cognate),
          _link('elv-d', IdiomLinkKind.original),
        ],
      );
      expect(
        r.linksOfKind(IdiomLinkKind.cognate).map((l) => l.targetLanguageId),
        <String>['elv-b', 'elv-c'],
      );
      expect(r.originalSourceLanguageId, 'elv-d');
      expect(r.linkTo('ELV-C')?.kind, IdiomLinkKind.cognate);
      expect(r.linkTo('elv-zz'), isNull);
    });

    test('record tanpa link: originalSourceLanguageId null', () {
      expect(buildRecord().originalSourceLanguageId, isNull);
      expect(buildRecord().links, isEmpty);
    });
  });

  group('JSON roundtrip', () {
    test('record penuh roundtrip byte-identik', () {
      final r = buildRecord(
        variants: <IdiomVariant>[
          _variant('v-1', 'bentuk A', literalTranslation: 'lt A', note: 'n'),
        ],
        links: <IdiomLanguageLink>[
          _link('elv-b', IdiomLinkKind.original, note: 'asal'),
        ],
        note: 'catatan',
      );
      final json = r.toJson();
      final encoded = jsonEncode(json);
      final back = IdiomRecord.fromJson(
        jsonDecode(encoded) as Map<String, Object?>,
      );
      expect(jsonEncode(back.toJson()), encoded);
      expect(back, r);
    });

    test('registry roundtrip mempertahankan urutan record', () {
      final reg = buildRegistry();
      final back = IdiomRegistry.fromJson(
        jsonDecode(jsonEncode(reg.toJson())) as Map<String, Object?>,
      );
      expect(jsonEncode(back.toJson()), jsonEncode(reg.toJson()));
      expect(back.idiomIds, reg.idiomIds);
    });
  });

  group('IdiomRegistry', () {
    test('empty bersih', () {
      final reg = IdiomRegistry.empty();
      expect(reg.recordCount, 0);
      expect(reg.records, isEmpty);
      expect(reg.totalVariantCount, 0);
      expect(reg.totalLinkCount, 0);
    });

    test('idiomId duplikat ditolak', () {
      expect(
        () => IdiomRegistry.withRecords(<IdiomRecord>[
          buildRecord(idiomId: 'x'),
          buildRecord(idiomId: 'x'),
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('records sorted by id immutable', () {
      final reg = buildRegistry();
      expect(reg.idiomIds, <String>['id-a', 'id-b', 'id-c']);
      expect(
        () => (reg.records as List).add(buildRecord(idiomId: 'zz')),
        throwsUnsupportedError,
      );
    });

    test('recordFor trim-tolerant, unknown null', () {
      final reg = buildRegistry();
      expect(reg.recordFor('  id-b  ')?.type, IdiomType.proverb);
      expect(reg.recordFor('nope'), isNull);
    });

    test('recordsOfType & recordsInLanguage sorted by id', () {
      final reg = buildRegistry();
      expect(
        reg.recordsOfType(IdiomType.proverb).map((r) => r.idiomId),
        <String>['id-b'],
      );
      expect(reg.recordsInLanguage(' ELV-A ').map((r) => r.idiomId), <String>[
        'id-b',
        'id-c',
      ]);
      expect(reg.recordsOfType(IdiomType.catchphrase), isEmpty);
    });

    test('agregat counts + languageIds', () {
      final reg = buildRegistry();
      expect(reg.recordCount, 3);
      expect(reg.totalVariantCount, 1);
      expect(reg.totalLinkCount, 3);
      expect(reg.languageIds, <String>['elv-a', 'elv-b']);
    });

    test('recordsLinkingTo mencakup target link lintas record sorted', () {
      final reg = buildRegistry();
      expect(reg.recordsLinkingTo('elv-b').map((r) => r.idiomId), <String>[
        'id-a',
        'id-b',
      ]);
    });

    test('findByNormalizedText exact match toleran whitespace/kasus', () {
      final reg = buildRegistry();
      expect(
        reg.findByNormalizedText('  Sedikit   tapi   RUTIN ')?.idiomId,
        'id-c',
      );
      expect(reg.findByNormalizedText('tidak ada'), isNull);
    });

    test('variantId duplikat LINTAS record ditolak (id varian global)', () {
      expect(
        () => IdiomRegistry.withRecords(<IdiomRecord>[
          buildRecord(
            idiomId: 'p',
            variants: <IdiomVariant>[_variant('v-global', 'a')],
          ),
          buildRecord(
            idiomId: 'q',
            variants: <IdiomVariant>[_variant('v-global', 'b')],
          ),
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('withRecords memvalidasi tiap record saat masuk', () {
      expect(
        () => IdiomRegistry.withRecords(<IdiomRecord>[
          buildRecord(),
          buildRecord(idiomId: 'id-1'),
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('IdiomQuery', () {
    test('query kosong == semua record, sorted', () {
      const q = IdiomQuery();
      expect(q.isEmpty, isTrue);
      expect(q.apply(buildRegistry()).map((r) => r.idiomId), <String>[
        'id-a',
        'id-b',
        'id-c',
      ]);
    });

    test('filter type + languageId digabung (AND)', () {
      const q = IdiomQuery(type: IdiomType.proverb, languageId: 'elv-a');
      expect(q.apply(buildRegistry()).map((r) => r.idiomId), <String>['id-b']);
      const miss = IdiomQuery(type: IdiomType.proverb, languageId: 'elv-b');
      expect(miss.apply(buildRegistry()), isEmpty);
    });

    test('textContains memakai normalisasi, kena varian juga', () {
      const q = IdiomQuery(textContains: 'TAK   dalam');
      final hits = q.apply(buildRegistry()).map((r) => r.idiomId).toList();
      expect(hits, <String>['id-b']);
    });

    test('requireVariant / requireLink filter keberadaan', () {
      const rv = IdiomQuery(requireVariant: true);
      expect(rv.apply(buildRegistry()).map((r) => r.idiomId), <String>['id-b']);
      const rl = IdiomQuery(requireLinkKind: IdiomLinkKind.original);
      expect(rl.apply(buildRegistry()).map((r) => r.idiomId), <String>['id-a']);
    });

    test(
      'describe menyebut filter aktif dan isEmpty true saat tanpa filter',
      () {
        expect(const IdiomQuery().describe(), contains('semua'));
        final d = const IdiomQuery(type: IdiomType.maxim).describe();
        expect(d, contains('Maxim'));
        expect(d, contains('type='));
      },
    );
  });
}
