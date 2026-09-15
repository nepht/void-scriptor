// Sprint 111.36 — Idiom Consistency & Anachronism Checks (domain-only).
//
// Acceptance canonical: culture_check, character_check, era_check,
// meaning_check, explain_warning, manual_exception.
//
// Konsumsi:
//  - IdiomRegistry/IdiomRecord 111.33 (idiomId, normalizedText)
//  - IdiomUsageProfile/IdiomUsageCatalog 111.34 (predikat usedByCulture /
//    avoidedByCulture / activeAtMarker SUDAH ADA — validator ini hanya
//    mengemas isu + penjelasan + pengecualian manual)
//  - IdiomToneCatalog/CharacterVoiceProfile 111.35 (character_check)
//
// Domain-only: deterministik, tanpa persistence/UI/wall-clock/random.
// D-SCHEMA-01 tetap OPEN.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_consistency.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_registry.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_tone.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_usage.dart';

IdiomRecord _record(
  String id, {
  String text = 'Api tua tak membakar tangan',
  String meaning = 'ancaman lama kehilangan taringnya',
}) => IdiomRecord.validated(
  idiomId: id,
  type: IdiomType.proverb,
  originalText: text,
  literalTranslation: 'old fire does not burn the hand',
  meaning: meaning,
  languageId: 'void-tongue',
);

IdiomUsageProfile _profile(String idiomId) => IdiomUsageProfile.validated(
  idiomId: idiomId,
  eras: <IdiomEraRange>[
    IdiomEraRange.validated(
      eraId: 'era-perang',
      label: 'Era Perang',
      fromMarker: 'm050',
      toMarker: 'm100',
      sequence: 1,
    ),
  ],
  cultures: <IdiomCultureRef>[IdiomCultureRef.validated(cultureId: 'ash-kin')],
);

IdiomToneProfile _tone(String idiomId) => IdiomToneProfile.validated(
  idiomId: idiomId,
  tone: IdiomTone.mournful,
  connotation: IdiomConnotation.neutral,
  offenseRisk: OffenseRisk.harmless,
);

CharacterVoiceProfile _voice(
  String charId, {
  String? cultureId,
  Set<IdiomTone> avoidedTones = const <IdiomTone>{},
}) => CharacterVoiceProfile.validated(
  characterId: charId,
  cultureId: cultureId,
  avoidedTones: avoidedTones,
);

void main() {
  group('IdiomUsageEvent.validated', () {
    test('memangkas teks dan menolak field wajib kosong', () {
      final e = IdiomUsageEvent.validated(
        eventId: ' ev1 ',
        idiomId: 'id1',
        atMarker: ' m075 ',
        text: '  Api tua tak membakar tangan  ',
        characterId: ' ch1 ',
        cultureId: ' ash-kin ',
      );
      expect(e.eventId, 'ev1');
      expect(e.idiomId, 'id1');
      expect(e.atMarker, 'm075');
      expect(e.text, 'Api tua tak membakar tangan');
      expect(e.characterId, 'ch1');
      expect(e.cultureId, 'ash-kin');
      expect(e.hasOccurrence, isTrue);
      expect(
        () => IdiomUsageEvent.validated(eventId: '', idiomId: 'id1'),
        throwsArgumentError,
      );
      expect(
        () => IdiomUsageEvent.validated(eventId: 'e', idiomId: '  '),
        throwsArgumentError,
      );
      expect(
        () => IdiomUsageEvent.validated(
          eventId: 'e',
          idiomId: 'id1',
          text: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('matchedTextId: canonical, varian, lalu null', () {
      final rec = IdiomRecord.validated(
        idiomId: 'id1',
        type: IdiomType.proverb,
        originalText: 'Api tua tak membakar tangan',
        literalTranslation: 'old fire does not burn the hand',
        meaning: 'ancaman lama kehilangan taringnya',
        languageId: 'void-tongue',
        variants: <IdiomVariant>[
          IdiomVariant.validated(
            variantId: 'v1',
            text: 'api jaman dulu tak membakar tangan',
          ),
        ],
      );
      final canonical = IdiomUsageEvent.validated(
        eventId: 'e1',
        idiomId: 'id1',
        text: 'API TUA  tak membakar tangan',
      );
      expect(canonical.matchedTextId(rec), 'canonical');
      final variant = IdiomUsageEvent.validated(
        eventId: 'e2',
        idiomId: 'id1',
        text: 'Api jaman dulu tak membakar tangan',
      );
      expect(variant.matchedTextId(rec), 'v1');
      final miss = IdiomUsageEvent.validated(
        eventId: 'e3',
        idiomId: 'id1',
        text: 'ungkapan lain sama sekali',
      );
      expect(miss.matchedTextId(rec), isNull);
    });

    test('JSON roundtrip stabil', () {
      final e = IdiomUsageEvent.validated(
        eventId: 'e1',
        idiomId: 'id1',
        atMarker: 'm075',
        text: 'Api tua tak membakar tangan',
        characterId: 'ch1',
        cultureId: 'ash-kin',
      );
      expect(
        IdiomUsageEvent.fromJson(
          jsonDecode(jsonEncode(e)) as Map<String, Object?>,
        ),
        e,
      );
    });
  });

  group('IdiomUsageLedger', () {
    test('denganRecords menegakkan keunikan eventId dan idiom terdaftar', () {
      final records = IdiomRegistry.withRecords(<IdiomRecord>[_record('id1')]);
      expect(
        () => IdiomUsageLedger.withRecords(
          records: records,
          events: <IdiomUsageEvent>[
            IdiomUsageEvent.validated(eventId: 'e', idiomId: 'id1'),
            IdiomUsageEvent.validated(eventId: 'e', idiomId: 'id1'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => IdiomUsageLedger.withRecords(
          records: records,
          events: <IdiomUsageEvent>[
            IdiomUsageEvent.validated(eventId: 'e', idiomId: 'nope'),
          ],
        ),
        throwsArgumentError,
      );
      final ledger = IdiomUsageLedger.withRecords(
        records: records,
        events: <IdiomUsageEvent>[
          IdiomUsageEvent.validated(
            eventId: 'e2',
            idiomId: 'id1',
            atMarker: 'm075',
          ),
          IdiomUsageEvent.validated(
            eventId: 'e1',
            idiomId: 'id1',
            atMarker: 'm060',
          ),
        ],
      );
      expect(ledger.eventCount, 2);
      // kejadian tanpa text = posisi saja -> bukan occurrence
      expect(ledger.hasOccurrences, isFalse);
      // eventsFor terurut (marker, eventId)
      expect(
        ledger.eventsFor('id1').map((e) => e.eventId),
        orderedEquals(<String>['e1', 'e2']),
      );
      expect(ledger.eventsFor('unknown'), isEmpty);
      final empty = IdiomUsageLedger.withRecords(records: records);
      expect(empty.hasOccurrences, isFalse);
      expect(empty.eventCount, 0);
      final withText = IdiomUsageLedger.withRecords(
        records: records,
        events: <IdiomUsageEvent>[
          IdiomUsageEvent.validated(
            eventId: 'e9',
            idiomId: 'id1',
            text: 'api tua tak membakar tangan',
          ),
        ],
      );
      expect(withText.hasOccurrences, isTrue);
    });

    test('ledger kosong = legal (checks struktural tetap jalan)', () {
      final empty = IdiomUsageLedger.empty();
      expect(empty.records.recordCount, 0);
      expect(empty.eventsFor('id1'), isEmpty);
    });
  });

  group('IdiomConsistencyIssue.validated', () {
    test('issueId stabil dan tidak bergantung urutan penyusun', () {
      final a = IdiomConsistencyIssue.validated(
        idiomId: 'id1',
        kind: IdiomConsistencyKind.culture,
        message: 'pesan',
        relatedId: 'ash',
      );
      final again = IdiomConsistencyIssue.validated(
        idiomId: 'id1',
        kind: IdiomConsistencyKind.culture,
        message: 'pesan',
        relatedId: 'ash',
      );
      expect(a.issueId, again.issueId);
      expect(a.issueId.startsWith('ici-'), isTrue);
      final other = IdiomConsistencyIssue.validated(
        idiomId: 'id1',
        kind: IdiomConsistencyKind.culture,
        message: 'pesan',
        relatedId: 'lain',
      );
      expect(other.issueId, isNot(a.issueId));
      expect(a.toJson()['suppressed'], isFalse);
    });

    test('fromJson menolak issueId yang tidak cocok turunan', () {
      final a = IdiomConsistencyIssue.validated(
        idiomId: 'id1',
        kind: IdiomConsistencyKind.meaning,
        message: 'pesan',
      );
      final bad = <String, Object?>{...a.toJson(), 'issueId': 'ici-deadbeef'};
      expect(() => IdiomConsistencyIssue.fromJson(bad), throwsArgumentError);
      expect(IdiomConsistencyIssue.fromJson(a.toJson()), a);
    });
  });

  group('IdiomManualException', () {
    test('matches presisi (idiomId, kind); eventScope opsional', () {
      final e = IdiomManualException.validated(
        exceptionId: 'x1',
        idiomId: 'id1',
        kind: IdiomConsistencyKind.era,
        reason: 'dipakai sebagai kutipan liturgis',
        eventScope: 'e1',
      );
      expect(e.matches('id1', IdiomConsistencyKind.era), isTrue);
      expect(e.matches('id1', IdiomConsistencyKind.culture), isFalse);
      expect(e.matches('  ID1 ', IdiomConsistencyKind.era), isTrue);
      expect(e.matches('id2', IdiomConsistencyKind.era), isFalse);
      // eventScope: hanya isu pada kejadian itu yang tercakup
      final withScope = e.forEvent('e1');
      expect(withScope.suppresses('e1', IdiomConsistencyKind.era), isTrue);
      expect(withScope.suppresses('e2', IdiomConsistencyKind.era), isFalse);
      final broad = IdiomManualException.validated(
        exceptionId: 'x2',
        idiomId: 'id1',
        kind: IdiomConsistencyKind.era,
        reason: 'semua kejadian',
      );
      expect(broad.suppresses('e9', IdiomConsistencyKind.era), isTrue);
      expect(broad.eventScope, isNull);
      expect(
        () => IdiomManualException.validated(
          exceptionId: 'x',
          idiomId: 'id1',
          kind: IdiomConsistencyKind.era,
          reason: '  ',
        ),
        throwsArgumentError,
      );
      final json = IdiomManualException.fromJson(
        jsonDecode(jsonEncode(withScope)) as Map<String, Object?>,
      );
      expect(json, withScope);
    });
  });

  group('IdiomConsistencyValidator — precondition', () {
    final usage = IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
      _profile('id1'),
    ]);
    final tone = IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
      _tone('id1'),
    ]);
    final events = IdiomUsageLedger.withRecords(
      records: IdiomRegistry.withRecords(<IdiomRecord>[_record('id1')]),
      events: <IdiomUsageEvent>[
        IdiomUsageEvent.validated(eventId: 'e1', idiomId: 'id1'),
      ],
    );

    test('usage wajib terisi dan harus subset registry', () {
      expect(
        () => IdiomConsistencyValidator.validate(
          usage: IdiomUsageCatalog.empty(),
          tone: tone,
          characters: const <CharacterVoiceProfile>[],
          events: events,
        ),
        throwsArgumentError,
      );
      expect(
        () => IdiomConsistencyValidator.validate(
          usage: IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
            _profile('hantu'),
          ]),
          tone: tone,
          characters: const <CharacterVoiceProfile>[],
          events: events,
        ),
        throwsArgumentError,
      );
    });

    test('tone boleh null; characters/eventScope idiom wajib terdaftar', () {
      final r = IdiomConsistencyValidator.validate(
        usage: usage,
        tone: null,
        characters: const <CharacterVoiceProfile>[],
        events: events,
      );
      expect(r.issueCount, 0);
      expect(
        () => IdiomConsistencyValidator.validate(
          usage: usage,
          characters: <CharacterVoiceProfile>[
            _voice('ch1', cultureId: 'hantu'),
          ],
          events: IdiomUsageLedger.withRecords(
            records: events.records,
            events: <IdiomUsageEvent>[
              IdiomUsageEvent.validated(eventId: 'e1', idiomId: 'id1'),
            ],
          ),
          eventScope: const <String>{'tidak-ada'},
        ),
        throwsArgumentError,
      );
    });
  });

  group('IdiomConsistencyValidator — checks struktural', () {
    final rec1 = _record('id1');
    final rec2 = _record(
      'id2',
      text: 'Gelar dibeli, kehormatan disewa',
      meaning: 'titel bisa dibeli, integritas tidak',
    );
    final usageBoth = IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
      _profile('id1'),
      _profile('id2'),
    ]);
    final toneBoth = IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
      _tone('id1'),
      _tone('id2'),
    ]);
    test('meaning_check: tabrakan makna terdeteksi', () {
      final colliding = IdiomRegistry.withRecords(<IdiomRecord>[
        rec1,
        _record(
          'id2',
          text: 'ungkapan beda total',
          meaning: 'Ancaman Lama Kehilangan Taringnya',
        ),
      ]);
      final report = IdiomConsistencyValidator.validate(
        usage: IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
          _profile('id1'),
          _profile('id2'),
        ]),
        tone: IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
          _tone('id1'),
          _tone('id2'),
        ]),
        characters: const <CharacterVoiceProfile>[],
        events: IdiomUsageLedger.withRecords(records: colliding),
      );
      final hits = report.issuesOf(IdiomConsistencyKind.meaning);
      expect(hits.length, 2);
      expect(hits.map((i) => i.idiomId).toSet(), <String>{'id1', 'id2'});
      expect(
        hits.firstWhere((i) => i.idiomId == 'id1').message,
        contains('terkait: id2'),
      );
    });

    test(
      'meaning_check: tabrakan dengan idiom tanpa profil usage tetap LINTAS',
      () {
        final colliding = IdiomRegistry.withRecords(<IdiomRecord>[
          _record('id1'),
          _record(
            'id2',
            text: 'ungkapan beda total',
            meaning: 'ancaman lama kehilangan taringnya',
          ),
        ]);
        final report = IdiomConsistencyValidator.validate(
          usage: IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
            _profile('id1'),
          ]),
          tone: null,
          characters: const <CharacterVoiceProfile>[],
          events: IdiomUsageLedger.withRecords(records: colliding),
        );
        expect(report.issuesOf(IdiomConsistencyKind.meaning).length, 2);
      },
    );

    test('meaning_check: meaning hampa -> satu isu per idiom', () {
      final report = IdiomConsistencyValidator.validate(
        usage: usageBoth,
        tone: toneBoth,
        characters: const <CharacterVoiceProfile>[],
        events: IdiomUsageLedger.withRecords(
          records: IdiomRegistry.withRecords(<IdiomRecord>[
            _record('id1', meaning: '?'),
            rec2,
          ]),
        ),
      );
      final hits = report.issuesOf(IdiomConsistencyKind.meaning);
      expect(hits.length, 1);
      expect(hits.single.idiomId, 'id1');
      expect(hits.single.message, contains('Arti tidak tercatat'));
    });

    test('exact duplicate text lintas idiom -> dua isu meaning', () {
      final dup = IdiomRegistry.withRecords(<IdiomRecord>[
        _record('id1'),
        _record(
          'id2',
          text: 'api tua TAK membakar tangan',
          meaning: 'meaning sama yang sama',
        ),
      ]);
      final usage = IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
        _profile('id1'),
        _profile('id2'),
      ]);
      final report = IdiomConsistencyValidator.validate(
        usage: usage,
        tone: toneBoth,
        characters: const <CharacterVoiceProfile>[],
        events: IdiomUsageLedger.withRecords(records: dup),
      );
      final hits = report.issuesOf(IdiomConsistencyKind.meaning);
      expect(hits.length, 2);
      expect(hits.first.message, contains('Teks identical'));
      expect(hits.first.message, isNot(contains('terkait')));
    });

    test('meaning hampa + tabrakan: dua isu beda idiom tetap muncul', () {
      final dup = IdiomRegistry.withRecords(<IdiomRecord>[
        _record('id1', meaning: '?'),
        _record('id2', text: 'api tua tak membakar tangan', meaning: '?'),
      ]);
      final report = IdiomConsistencyValidator.validate(
        usage: usageBoth,
        tone: toneBoth,
        characters: const <CharacterVoiceProfile>[],
        events: IdiomUsageLedger.withRecords(records: dup),
      );
      final hits = report.issuesOf(IdiomConsistencyKind.meaning);
      expect(hits.length, 4, reason: '2 blank + 2 identical');
      expect(hits.map((i) => i.issueId).toSet().length, 4);
    });
  });

  group('IdiomConsistencyValidator — checks berbasis kejadian', () {
    IdiomConsistencyReport run({
      String marker = 'm075',
      String? cultureId,
      String? charId,
      String? text,
      List<IdiomCultureRef> cultures = const <IdiomCultureRef>[],
      List<IdiomEraRange> eras = const <IdiomEraRange>[],
      List<CharacterVoiceProfile> characters = const <CharacterVoiceProfile>[],
      Set<String>? eventScope,
    }) {
      final registry = IdiomRegistry.withRecords(<IdiomRecord>[_record('id1')]);
      return IdiomConsistencyValidator.validate(
        usage: IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
          IdiomUsageProfile.validated(
            idiomId: 'id1',
            cultures: cultures,
            eras: eras,
          ),
        ]),
        tone: IdiomToneCatalog.withProfiles(<IdiomToneProfile>[_tone('id1')]),
        characters: characters,
        events: IdiomUsageLedger.withRecords(
          records: registry,
          events: <IdiomUsageEvent>[
            IdiomUsageEvent.validated(
              eventId: 'e1',
              idiomId: 'id1',
              atMarker: marker,
              characterId: charId,
              cultureId: cultureId,
              text: text,
            ),
          ],
        ),
        eventScope: eventScope,
      );
    }

    test('bersih tanpa pelanggaran', () {
      final r = run(
        cultures: <IdiomCultureRef>[
          IdiomCultureRef.validated(cultureId: 'ash-kin'),
        ],
        eras: <IdiomEraRange>[
          IdiomEraRange.validated(
            eraId: 'era-perang',
            label: 'Era Perang',
            fromMarker: 'm050',
            toMarker: 'm100',
          ),
        ],
      );
      expect(r.hasIssues, isFalse);
      expect(r.describe(), contains('Tanpa isu'));
    });

    test(
      'era_check: pemakaian di luar rentang era -> isu era pada eventScope',
      () {
        final r = run(
          marker: 'm200',
          eras: <IdiomEraRange>[
            IdiomEraRange.validated(
              eraId: 'era-perang',
              label: 'Era Perang',
              fromMarker: 'm050',
              toMarker: 'm100',
            ),
          ],
        );
        final hits = r.issuesOf(IdiomConsistencyKind.era);
        expect(hits.length, 1);
        expect(hits.single.idiomId, 'id1');
        expect(hits.single.relatedId, 'e1');
        expect(r.eventScope, contains('e1'));
        expect(hits.single.message, contains('Era Perang'));
      },
    );

    test('culture_check: whitelist tidak memuat budaya kejadian', () {
      final r = run(
        cultureId: 'frost-kin',
        cultures: <IdiomCultureRef>[
          IdiomCultureRef.validated(cultureId: 'ash-kin'),
        ],
      );
      final hits = r.issuesOf(IdiomConsistencyKind.culture);
      expect(hits.length, 1);
      expect(hits.single.relatedId, 'e1');
      expect(hits.single.message, contains('tidak tercatat memakai'));
    });

    test('culture_check: budaya yang menghindari -> isu budaya', () {
      final r = run(
        cultureId: 'ash-kin',
        cultures: <IdiomCultureRef>[
          IdiomCultureRef.validated(
            cultureId: 'ash-kin',
            stance: IdiomUseStance.avoided,
          ),
        ],
      );
      expect(r.issuesOf(IdiomConsistencyKind.culture).length, 1);
    });

    test(
      'character_check: karakter budaya luar memakai ungkapan ber-whitelist',
      () {
        final r = run(
          charId: 'ch-frost',
          cultures: <IdiomCultureRef>[
            IdiomCultureRef.validated(cultureId: 'ash-kin'),
          ],
          characters: <CharacterVoiceProfile>[
            _voice('ch-frost', cultureId: 'frost-kin'),
          ],
        );
        final hits = r.issuesOf(IdiomConsistencyKind.character);
        expect(hits.length, 1);
        expect(hits.single.message, contains('ch-frost'));
      },
    );

    test('character_check: karakter menghindari nada ungkapan', () {
      final r = run(
        charId: 'ch1',
        characters: <CharacterVoiceProfile>[
          _voice('ch1', avoidedTones: <IdiomTone>{IdiomTone.mournful}),
        ],
      );
      final hits = r.issuesOf(IdiomConsistencyKind.character);
      expect(hits.length, 1);
      expect(hits.single.message, contains('Mournful'));
    });

    test(
      'character_check: karakter tidak terdaftar -> tanpa isu (konservatif)',
      () {
        final r = run(charId: 'ch-unknown');
        expect(r.issuesOf(IdiomConsistencyKind.character), isEmpty);
      },
    );

    test('meaning_check: teks kejadian tak cocok canonical/varian', () {
      final r = run(text: 'ungkapan lain sama sekali');
      final hits = r.issuesOf(IdiomConsistencyKind.meaning);
      expect(hits.length, 1);
      expect(hits.single.message, contains('tidak cocok'));
    });

    test('meaning_check: varian sah tidak memicu isu', () {
      final registry = IdiomRegistry.withRecords(<IdiomRecord>[
        IdiomRecord.validated(
          idiomId: 'id1',
          type: IdiomType.proverb,
          originalText: 'Api tua tak membakar tangan',
          literalTranslation: 'old fire does not burn the hand',
          meaning: 'ancaman lama kehilangan taringnya',
          languageId: 'void-tongue',
          variants: <IdiomVariant>[
            IdiomVariant.validated(
              variantId: 'v1',
              text: 'api jaman dulu tak membakar tangan',
            ),
          ],
        ),
      ]);
      final r = IdiomConsistencyValidator.validate(
        usage: IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
          IdiomUsageProfile.validated(idiomId: 'id1'),
        ]),
        tone: null,
        characters: const <CharacterVoiceProfile>[],
        events: IdiomUsageLedger.withRecords(
          records: registry,
          events: <IdiomUsageEvent>[
            IdiomUsageEvent.validated(
              eventId: 'e1',
              idiomId: 'id1',
              text: 'Api jaman dulu tak membakar tangan',
            ),
          ],
        ),
      );
      expect(r.issuesOf(IdiomConsistencyKind.meaning), isEmpty);
    });

    test('eventScope membatasi hanya kejadian terpilih', () {
      final registry = IdiomRegistry.withRecords(<IdiomRecord>[_record('id1')]);
      final r = IdiomConsistencyValidator.validate(
        usage: IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
          IdiomUsageProfile.validated(
            idiomId: 'id1',
            eras: <IdiomEraRange>[
              IdiomEraRange.validated(
                eraId: 'era-perang',
                label: 'P',
                fromMarker: 'm050',
                toMarker: 'm100',
              ),
            ],
          ),
        ]),
        tone: null,
        characters: const <CharacterVoiceProfile>[],
        events: IdiomUsageLedger.withRecords(
          records: registry,
          events: <IdiomUsageEvent>[
            IdiomUsageEvent.validated(
              eventId: 'e1',
              idiomId: 'id1',
              atMarker: 'm200',
            ),
            IdiomUsageEvent.validated(
              eventId: 'e2',
              idiomId: 'id1',
              atMarker: 'm300',
            ),
          ],
        ),
        eventScope: const <String>{'e2'},
      );
      final hits = r.issuesOf(IdiomConsistencyKind.era);
      expect(hits.map((i) => i.relatedId), <String>['e2']);
      expect(r.eventScope, orderedEquals(<String>['e2']));
    });
  });

  group('IdiomConsistencyReport', () {
    final usage = IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
      _profile('id1'),
    ]);
    final tone = IdiomToneCatalog.withProfiles(<IdiomToneProfile>[
      _tone('id1'),
    ]);
    final registry = IdiomRegistry.withRecords(<IdiomRecord>[_record('id1')]);
    final events = IdiomUsageLedger.withRecords(
      records: registry,
      events: <IdiomUsageEvent>[
        IdiomUsageEvent.validated(
          eventId: 'e1',
          idiomId: 'id1',
          atMarker: 'm075',
        ),
      ],
    );

    IdiomConsistencyReport validate({
      List<IdiomManualException> exceptions = const <IdiomManualException>[],
    }) => IdiomConsistencyValidator.validate(
      usage: usage,
      tone: tone,
      characters: const <CharacterVoiceProfile>[],
      events: events,
      exceptions: exceptions,
    );

    test('baseline bersih lalu era_check memicu isu', () {
      expect(validate().hasIssues, isFalse);
      final dirty = IdiomConsistencyValidator.validate(
        usage: IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
          IdiomUsageProfile.validated(
            idiomId: 'id1',
            eras: <IdiomEraRange>[
              IdiomEraRange.validated(
                eraId: 'era-perang',
                label: 'P',
                fromMarker: 'm050',
                toMarker: 'm060',
              ),
            ],
          ),
        ]),
        tone: tone,
        characters: const <CharacterVoiceProfile>[],
        events: events,
      );
      expect(dirty.hasIssues, isTrue);
      expect(dirty.hasViolations(IdiomConsistencyKind.era), isTrue);
    });

    test('manual_exception scope penuh menekan isu', () {
      final dirty = IdiomConsistencyValidator.validate(
        usage: IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
          IdiomUsageProfile.validated(
            idiomId: 'id1',
            eras: <IdiomEraRange>[
              IdiomEraRange.validated(
                eraId: 'era-perang',
                label: 'P',
                fromMarker: 'm050',
                toMarker: 'm060',
              ),
            ],
          ),
        ]),
        tone: tone,
        characters: const <CharacterVoiceProfile>[],
        events: events,
        exceptions: <IdiomManualException>[
          IdiomManualException.validated(
            exceptionId: 'x1',
            idiomId: 'id1',
            kind: IdiomConsistencyKind.era,
            reason: 'kilas balik sahnya',
          ),
        ],
      );
      expect(dirty.activeIssues, isEmpty);
      expect(dirty.suppressedIssues.length, 1);
      expect(dirty.suppressedIssues.single.suppressed, isTrue);
      expect(dirty.hasViolations(IdiomConsistencyKind.era), isFalse);
      expect(dirty.suppressedCount(IdiomConsistencyKind.era), 1);
      expect(dirty.describe(), contains('ditekan pengecualian manual'));
    });

    test('exception idiom/kind berbeda tidak menekan', () {
      final dirty = IdiomConsistencyValidator.validate(
        usage: IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
          IdiomUsageProfile.validated(
            idiomId: 'id1',
            eras: <IdiomEraRange>[
              IdiomEraRange.validated(
                eraId: 'era-perang',
                label: 'P',
                fromMarker: 'm050',
                toMarker: 'm060',
              ),
            ],
          ),
        ]),
        tone: tone,
        characters: const <CharacterVoiceProfile>[],
        events: events,
        exceptions: <IdiomManualException>[
          // kind benar tapi eventScope tak pernah menjadi relatedId isu era
          // e1 (= 'e1') -> tidak menekan.
          IdiomManualException.validated(
            exceptionId: 'x1',
            idiomId: 'id1',
            kind: IdiomConsistencyKind.era,
            reason: 'scope salah kejadian',
            eventScope: 'e-tak-terpakai',
          ),
          IdiomManualException.validated(
            exceptionId: 'x2',
            idiomId: 'id1',
            kind: IdiomConsistencyKind.culture,
            reason: 'salah kind',
          ),
        ],
      );
      expect(dirty.activeIssues.length, 1);
      expect(dirty.suppressedIssues, isEmpty);
    });

    test('exception ber-eventScope hanya menekan kejadian itu', () {
      final eventsTwo = IdiomUsageLedger.withRecords(
        records: registry,
        events: <IdiomUsageEvent>[
          IdiomUsageEvent.validated(
            eventId: 'e1',
            idiomId: 'id1',
            atMarker: 'm075',
          ),
          // e1 sengaja di dalam rentang era di bawah (m050..m100).
          IdiomUsageEvent.validated(
            eventId: 'eA',
            idiomId: 'id1',
            atMarker: 'm200',
          ),
          IdiomUsageEvent.validated(
            eventId: 'eB',
            idiomId: 'id1',
            atMarker: 'm300',
          ),
        ],
      );
      final r = IdiomConsistencyValidator.validate(
        usage: IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
          IdiomUsageProfile.validated(
            idiomId: 'id1',
            eras: <IdiomEraRange>[
              IdiomEraRange.validated(
                eraId: 'era-perang',
                label: 'P',
                fromMarker: 'm050',
                toMarker: 'm100',
              ),
            ],
          ),
        ]),
        tone: tone,
        characters: const <CharacterVoiceProfile>[],
        events: eventsTwo,
        exceptions: <IdiomManualException>[
          IdiomManualException.validated(
            exceptionId: 'x1',
            idiomId: 'id1',
            kind: IdiomConsistencyKind.era,
            reason: 'eA sah sebagai kilas balik',
            eventScope: 'eA',
          ),
        ],
      );
      final active = r.issuesOf(IdiomConsistencyKind.era);
      expect(active.map((i) => i.relatedId), <String>['eB']);
      expect(r.suppressedIssues.map((i) => i.relatedId), <String>['eA']);
    });

    test('exception tidak dikenal -> ArgumentError', () {
      final registryOther = IdiomRegistry.withRecords(<IdiomRecord>[
        _record('lain'),
      ]);
      expect(
        () => IdiomConsistencyValidator.validate(
          usage: IdiomUsageCatalog.withProfiles(<IdiomUsageProfile>[
            IdiomUsageProfile.validated(idiomId: 'lain'),
          ]),
          tone: null,
          characters: const <CharacterVoiceProfile>[],
          events: IdiomUsageLedger.withRecords(records: registryOther),
          exceptions: <IdiomManualException>[
            IdiomManualException.validated(
              exceptionId: 'x1',
              idiomId: 'id1',
              kind: IdiomConsistencyKind.era,
              reason: 'idiom tidak terdaftar',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test(
      'laporan: urutan deterministik, json roundtrip, tanpa mutasi sumber',
      () {
        final srcJson = jsonEncode(usage.toJson());
        final eventsJson = jsonEncode(events.toJson());
        final r = IdiomConsistencyValidator.validate(
          usage: usage,
          tone: tone,
          characters: const <CharacterVoiceProfile>[],
          events: events,
        );
        expect(r.issues, orderedEquals(r.issues.toList()));
        expect(r.describe(), contains('Tanpa isu'));
        expect(r.suggestionFor('id1'), isEmpty);
        expect(jsonDecode(jsonEncode(r)) is Map<String, Object?>, isTrue);
        final back = IdiomConsistencyReport.fromJson(
          jsonDecode(jsonEncode(r)) as Map<String, Object?>,
        );
        expect(back.issueCount, r.issueCount);
        expect(jsonEncode(back.toJson()), jsonEncode(r.toJson()));
        expect(jsonEncode(usage.toJson()), srcJson);
        expect(jsonEncode(events.toJson()), eventsJson);
      },
    );
  });

  test('semua kind punya label dan dariName stabil', () {
    for (final k in IdiomConsistencyKind.values) {
      expect(k.label, isNotEmpty);
      expect(IdiomConsistencyKind.fromName(k.name), k);
    }
  });

  test('Ledger.fromJson memakai konvensi IdiomRegistry.toJson', () {
    final registry = IdiomRegistry.withRecords(<IdiomRecord>[_record('id1')]);
    final ledger = IdiomUsageLedger.withRecords(
      records: registry,
      events: <IdiomUsageEvent>[
        IdiomUsageEvent.validated(
          eventId: 'e1',
          idiomId: 'id1',
          atMarker: 'm075',
          text: 'x',
        ),
      ],
    );
    final back = IdiomUsageLedger.fromJson(
      jsonDecode(jsonEncode(ledger)) as Map<String, Object?>,
    );
    expect(back.eventCount, 1);
    expect(back.records.recordCount, 1);
    expect(back.eventsFor('id1').single, ledger.eventsFor('id1').single);
  });
}
