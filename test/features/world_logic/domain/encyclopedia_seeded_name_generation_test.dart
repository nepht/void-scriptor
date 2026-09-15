// Sprint 111.31 - Seeded Name Generation (domain-only).
//
// Acceptance canonical dipetakan:
// - explicit_seed        -> SeededNameRequest.seed wajib (no default) + guard seedBlank
// - batch_generation     -> SeededNameGenerator.generateBatch(count) + guard batas
// - reproducible_output  -> seed+input identik => teks identik (dua instance, dua waktu)
// - regenerate           -> batch.regenerate() seed turunan deterministik; nextSeed chain
// - accept_or_discard    -> batch.accept/discard immutable; status proposal
// - no_auto_canon        -> generate tidak pernah memutasi profil/spec/katalog input;
//                           accept() hanya menandai salinan batch, tak menulis kanon
//
// Domain murni: tanpa persistence, UI, locale, jaringan, wall-clock, dart:math Random.
// D-SCHEMA-01 tetap OPEN.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_seeded_name_generation.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_syllable_phonotactics.dart';

PhonotacticsSpec buildSpec({
  List<SyllablePattern>? patterns,
  List<ForbiddenSequence> forbidden = const <ForbiddenSequence>[],
  String languageId = 'elv-a',
}) {
  return PhonotacticsSpec.validated(
    id: 'spec-1',
    languageId: languageId,
    inventory: <SyllablePart>[
      SyllablePart.validated(
        symbol: 'a',
        slots: <SyllableSlot>[SyllableSlot.nucleus],
      ),
      SyllablePart.validated(
        symbol: 'e',
        slots: <SyllableSlot>[SyllableSlot.nucleus],
      ),
      SyllablePart.validated(
        symbol: 'i',
        slots: <SyllableSlot>[SyllableSlot.nucleus],
      ),
      SyllablePart.validated(
        symbol: 'k',
        slots: <SyllableSlot>[SyllableSlot.onset, SyllableSlot.coda],
      ),
      SyllablePart.validated(
        symbol: 'l',
        slots: <SyllableSlot>[SyllableSlot.onset, SyllableSlot.coda],
      ),
      SyllablePart.validated(
        symbol: 'm',
        slots: <SyllableSlot>[SyllableSlot.onset],
      ),
      SyllablePart.validated(
        symbol: 'n',
        slots: <SyllableSlot>[SyllableSlot.onset],
      ),
      SyllablePart.validated(
        symbol: 'r',
        slots: <SyllableSlot>[SyllableSlot.onset],
      ),
      SyllablePart.validated(
        symbol: 's',
        slots: <SyllableSlot>[SyllableSlot.onset],
      ),
      SyllablePart.validated(
        symbol: 't',
        slots: <SyllableSlot>[SyllableSlot.onset],
      ),
    ],
    patterns:
        patterns ??
        <SyllablePattern>[
          SyllablePattern.parse(id: 'cv', template: 'CV', weight: 3),
          SyllablePattern.parse(id: 'cvc', template: 'CVC', weight: 2),
          SyllablePattern.parse(id: 'cvd', template: 'CV(C)', weight: 1),
        ],
    forbidden: forbidden,
  );
}

CulturalNameProfile buildProfile({
  String languageId = 'elv-a',
  List<NameAffixRule> affixRules = const <NameAffixRule>[],
  List<NameTitle> titles = const <NameTitle>[],
}) {
  return CulturalNameProfile.validated(
    profileId: 'prof-elv',
    cultureId: 'c-elenar',
    languageId: languageId,
    entityTypes: <NameEntityType>{NameEntityType.person, NameEntityType.place},
    titles: titles,
    affixRules: affixRules,
  );
}

SeededNameRequest buildRequest({
  CulturalNameProfile? profile,
  PhonotacticsSpec? spec,
  NameEntityType entityType = NameEntityType.person,
  SocialContext? context,
  int syllableCount = 2,
  bool addTitle = false,
  bool addAffixes = true,
  required int seed,
}) {
  return SeededNameRequest.validated(
    profile: profile ?? buildProfile(),
    spec: spec ?? buildSpec(),
    entityType: entityType,
    context: context,
    syllableCount: syllableCount,
    addTitle: addTitle,
    addAffixes: addAffixes,
    seed: seed,
  );
}

void main() {
  group('SeededNameRequest - explicit seed + validasi', () {
    test('seed non-kosong wajib ada (no default) dan tersimpan persis', () {
      final r = buildRequest(seed: 12345);
      expect(r.seed, 12345);
    });

    test('seed=0 sah secara numerik namun ditolak sebagai seedBlank', () {
      expect(
        () => buildRequest(seed: 0),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('seed'),
          ),
        ),
      );
    });

    test('syllableCount di luar 1..8 ditolak', () {
      expect(
        () => buildRequest(seed: 1, syllableCount: 0),
        throwsArgumentError,
      );
      expect(
        () => buildRequest(seed: 1, syllableCount: 9),
        throwsArgumentError,
      );
      expect(buildRequest(seed: 1, syllableCount: 1).syllableCount, 1);
      expect(buildRequest(seed: 1, syllableCount: 8).syllableCount, 8);
    });

    test('entityType di luar whitelist profil ditolak', () {
      expect(
        () => buildRequest(seed: 1, entityType: NameEntityType.deity),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('whitelist'),
          ),
        ),
      );
    });

    test('languageId spec harus sama dengan profil (guard salah bahasa)', () {
      expect(
        () => buildRequest(seed: 1, spec: buildSpec(languageId: 'dva-b')),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('language'),
          ),
        ),
      );
    });

    test('context null jatuh ke defaultContext profil', () {
      final r = buildRequest(seed: 1);
      expect(r.context, SocialContext.everyday);
      final f = buildRequest(seed: 1, context: SocialContext.formal);
      expect(f.context, SocialContext.formal);
    });

    test('copyWith seed menghasilkan permintaan baru, yang lama utuh', () {
      final a = buildRequest(seed: 10);
      final b = a.copyWith(seed: 20);
      expect(a.seed, 10);
      expect(b.seed, 20);
      expect(b.entityType, a.entityType);
      expect(b.syllableCount, a.syllableCount);
    });

    test('JSON roundtrip mempertahankan seed + pilihan', () {
      final r = buildRequest(seed: 777, syllableCount: 3, addTitle: true);
      final back = SeededNameRequest.fromJson(
        jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,
      );
      expect(back.seed, 777);
      expect(back.syllableCount, 3);
      expect(back.addTitle, isTrue);
      expect(back.entityType, NameEntityType.person);
      expect(back.profile.profileId, 'prof-elv');
      expect(back.spec, isNotNull);
      expect(back.spec!.id, 'spec-1');
    });

    test('request tanpa spec sah (hanya profil)', () {
      final r = SeededNameRequest.validated(
        profile: buildProfile(),
        entityType: NameEntityType.person,
        syllableCount: 2,
        seed: 5,
      );
      expect(r.spec, isNull);
    });
  });

  group('SeededNameGenerator - reproducible_output', () {
    test('seed + input identik menghasilkan teks batch identik', () {
      final a = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 42),
        count: 6,
      );
      final b = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 42),
        count: 6,
      );
      expect(b.texts, a.texts);
      expect(b.proposals, a.proposals);
    });

    test('seed berbeda menghasilkan teks berbeda', () {
      final a = SeededNameGenerator.generateOne(
        request: buildRequest(seed: 42),
      );
      final b = SeededNameGenerator.generateOne(
        request: buildRequest(seed: 43),
      );
      expect(a.text, isNot(b.text));
    });

    test(
      'determinisme stabil lintas 50 iterasi (tanpa wall-clock/random global)',
      () {
        final baseline = SeededNameGenerator.generateBatch(
          request: buildRequest(seed: 90210, syllableCount: 3),
          count: 5,
        ).texts;
        for (var i = 0; i < 50; i++) {
          final again = SeededNameGenerator.generateBatch(
            request: buildRequest(seed: 90210, syllableCount: 3),
            count: 5,
          ).texts;
          expect(again, baseline, reason: 'iterasi $i menyimpang');
        }
      },
    );

    test(
      'setiap index batch memakai anak-seed berbeda (teks tidak seragam)',
      () {
        final batch = SeededNameGenerator.generateBatch(
          request: buildRequest(seed: 7, syllableCount: 3),
          count: 4,
        );
        expect(batch.texts.toSet().length, greaterThan(1));
        expect(batch.proposals.map((p) => p.index).toList(), <int>[0, 1, 2, 3]);
      },
    );

    test('proposal id unik dalam batch dan deterministik', () {
      final batch = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 55),
        count: 8,
      );
      final ids = batch.proposals.map((p) => p.proposalId).toList();
      expect(ids.toSet().length, 8);
      final other = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 55),
        count: 8,
      );
      expect(other.proposals.map((p) => p.proposalId).toList(), ids);
    });

    test('teks hasil tidak kosong dan hanya memakai simbol pool', () {
      final allowed = <String>{
        'a',
        'e',
        'i',
        'k',
        'l',
        'm',
        'n',
        'r',
        's',
        't',
      };
      for (final seed in <int>[1, 2, 3, 555, 9999]) {
        final batch = SeededNameGenerator.generateBatch(
          request: buildRequest(seed: seed),
          count: 5,
        );
        for (final p in batch.proposals) {
          expect(p.text.trim(), isNotEmpty);
          for (final syl in p.syllables) {
            for (final ch in syl.split('')) {
              expect(allowed, contains(ch), reason: 'huruf $ch di luar pool');
            }
          }
        }
      }
    });

    test('request tanpa spec tetap menghasilkan nama non-empty', () {
      final p = SeededNameGenerator.generateOne(
        request: SeededNameRequest.validated(
          profile: buildProfile(),
          entityType: NameEntityType.person,
          syllableCount: 2,
          seed: 12,
        ),
      );
      expect(p.text.trim(), isNotEmpty);
    });
  });

  group('SeededNameGenerator - batch_generation', () {
    test('count wajib >= 1 dan dibatasi maksimum generator', () {
      expect(
        () => SeededNameGenerator.generateBatch(
          request: buildRequest(seed: 1),
          count: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SeededNameGenerator.generateBatch(
          request: buildRequest(seed: 1),
          count: SeededNameGenerator.maxBatchSize + 1,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('maxBatchSize'),
          ),
        ),
      );
    });

    test('batch melaporkan request asal, seed, dan jumlah', () {
      final req = buildRequest(seed: 31);
      final batch = SeededNameGenerator.generateBatch(request: req, count: 3);
      expect(batch.count, 3);
      expect(batch.seed, 31);
      expect(batch.request.seed, 31);
      expect(batch.proposals.length, 3);
    });

    test('generateOne = batch count 1 dan proposal status proposed', () {
      final p = SeededNameGenerator.generateOne(
        request: buildRequest(seed: 88),
      );
      expect(p.status, NameProposalStatus.proposed);
      expect(p.index, 0);
      expect(p.statusLabel, isNotEmpty);
    });

    test('jumlah suku kata sesuai syllableCount (pola CV murni)', () {
      final spec = buildSpec(
        patterns: <SyllablePattern>[
          SyllablePattern.parse(id: 'cv', template: 'CV', weight: 1),
        ],
      );
      final p = SeededNameGenerator.generateOne(
        request: buildRequest(seed: 4, syllableCount: 4, spec: spec),
      );
      expect(p.syllables.length, 4);
    });

    test(
      'seluruh nama sah secara fonotaktik dengan bobot penuh + larangan',
      () {
        final spec = buildSpec(
          patterns: <SyllablePattern>[
            SyllablePattern.parse(id: 'cv', template: 'CV', weight: 1),
            SyllablePattern.parse(id: 'cvc', template: 'CVC', weight: 1),
          ],
          forbidden: <ForbiddenSequence>[
            ForbiddenSequence.validated(
              id: 'no-ai',
              symbols: <String>['a', 'i'],
            ),
          ],
        );
        for (final seed in <int>[100, 200, 300, 400]) {
          final batch = SeededNameGenerator.generateBatch(
            request: buildRequest(seed: seed, syllableCount: 3, spec: spec),
            count: 5,
          );
          for (final p in batch.proposals) {
            final symbols = p.syllables.expand((s) => s.split('')).toList();
            expect(
              spec.isWordLegal(symbols),
              isTrue,
              reason: '${p.text} melanggar larangan pada seed $seed',
            );
          }
        }
      },
    );

    test('spasi tidak pernah muncul di tengah inti nama', () {
      final batch = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 77),
        count: 10,
      );
      for (final p in batch.proposals) {
        expect(p.text.contains(' '), isFalse);
      }
    });
  });

  group('SeededNameGenerator - afiks, gelar, dan kanon 111.30', () {
    test(
      'afiks mandatory saja: teks == decorateName (huruf besar diabaikan)',
      () {
        final profile = buildProfile(
          affixRules: <NameAffixRule>[
            NameAffixRule.validated(
              id: 'a-on',
              kind: NameAffixKind.suffix,
              text: 'on',
              entityTypes: <NameEntityType>{NameEntityType.person},
              contexts: <SocialContext>{SocialContext.everyday},
            ),
          ],
        );
        final batch = SeededNameGenerator.generateBatch(
          request: buildRequest(seed: 21, profile: profile),
          count: 5,
        );
        for (final p in batch.proposals) {
          final core = p.syllables.join();
          expect(
            p.text.toLowerCase(),
            profile.decorateName(core, NameEntityType.person),
          );
        }
      },
    );

    test(
      'afiks optional dapat muncul atau tidak, tapi deterministik per seed',
      () {
        final profile = buildProfile(
          affixRules: <NameAffixRule>[
            NameAffixRule.validated(
              id: 'a-i',
              kind: NameAffixKind.prefix,
              text: 'i',
              entityTypes: <NameEntityType>{NameEntityType.person},
              contexts: <SocialContext>{SocialContext.everyday},
              optional: true,
            ),
          ],
        );
        final batch = SeededNameGenerator.generateBatch(
          request: buildRequest(seed: 64, profile: profile),
          count: 10,
        );
        final withPrefix = batch.texts.where(
          (t) => t.toLowerCase().startsWith('i'),
        );
        final without = batch.texts.where(
          (t) => !t.toLowerCase().startsWith('i'),
        );
        expect(withPrefix, isNotEmpty);
        expect(without, isNotEmpty);
        final repeat = SeededNameGenerator.generateBatch(
          request: buildRequest(seed: 64, profile: profile),
          count: 10,
        );
        expect(repeat.texts, batch.texts);
      },
    );

    test('addAffixes false melewati seluruh afiks', () {
      final profile = buildProfile(
        affixRules: <NameAffixRule>[
          NameAffixRule.validated(
            id: 'a-on',
            kind: NameAffixKind.suffix,
            text: 'on',
            entityTypes: <NameEntityType>{NameEntityType.person},
            contexts: <SocialContext>{SocialContext.everyday},
          ),
        ],
      );
      final p = SeededNameGenerator.generateOne(
        request: buildRequest(seed: 33, profile: profile, addAffixes: false),
      );
      expect(p.text.toLowerCase(), p.syllables.join());
    });

    test('addTitle true memakai gelar yang terdaftar saja', () {
      final titles = <NameTitle>[
        NameTitle.validated(
          id: 't-lady',
          text: 'Lady',
          position: TitlePosition.preName,
          entityTypes: <NameEntityType>{NameEntityType.person},
          contexts: <SocialContext>{SocialContext.everyday},
        ),
        NameTitle.validated(
          id: 't-wise',
          text: 'the Wise',
          position: TitlePosition.postName,
          entityTypes: <NameEntityType>{NameEntityType.person},
          contexts: <SocialContext>{SocialContext.everyday},
        ),
      ];
      final profile = buildProfile(titles: titles);
      final batch = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 5, profile: profile, addTitle: true),
        count: 6,
      );
      for (final p in batch.proposals) {
        expect(p.text.contains('Lady') || p.text.contains('the Wise'), isTrue);
      }
      final plain = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 5, profile: profile, addTitle: false),
        count: 6,
      );
      for (final p in plain.proposals) {
        expect(p.text.contains('Lady'), isFalse);
      }
    });

    test('tambah gelar pada tipe yang tidak memakainya = tanpa gelar', () {
      final profile = buildProfile(
        titles: <NameTitle>[
          NameTitle.validated(
            id: 't-lord',
            text: 'Lord',
            position: TitlePosition.preName,
            entityTypes: <NameEntityType>{NameEntityType.person},
            contexts: <SocialContext>{SocialContext.formal},
          ),
        ],
      );
      final p = SeededNameGenerator.generateOne(
        request: buildRequest(
          seed: 9,
          profile: profile,
          entityType: NameEntityType.place,
          context: SocialContext.everyday,
          addTitle: true,
        ),
      );
      expect(p.text.contains('Lord'), isFalse);
    });

    test('huruf pertama nama inti dikapitalisasi', () {
      final p = SeededNameGenerator.generateOne(request: buildRequest(seed: 2));
      final first = p.text.codeUnitAt(0);
      expect(first >= 0x41 && first <= 0x5A, isTrue, reason: p.text);
    });
  });

  group('SeededNameBatch - regenerate', () {
    test('regenerate() memakai seed turunan dan menghasilkan batch baru', () {
      final batch = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 11),
        count: 4,
      );
      final next = batch.regenerate();
      expect(next.seed, isNot(batch.seed));
      expect(next.count, batch.count);
      expect(next.texts.length, batch.texts.length);
    });

    test('regenerate deterministik: chain seed dari seed awal identik', () {
      final a = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 11),
        count: 3,
      ).regenerate().regenerate();
      final b = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 11),
        count: 3,
      ).regenerate().regenerate();
      expect(b.texts, a.texts);
      expect(b.seed, a.seed);
    });

    test(
      'nextSeed deterministik dan tidak mengulang seed awal dalam 100 lompatan',
      () {
        var s = 11;
        final seen = <int>{s};
        for (var i = 0; i < 100; i++) {
          s = SeededNameGenerator.nextSeed(s);
          expect(
            seen.add(s),
            isTrue,
            reason: 'rantai seed mengulang di langkah $i',
          );
        }
        expect(
          SeededNameGenerator.nextSeed(11),
          SeededNameGenerator.nextSeed(11),
        );
      },
    );

    test('regenerate mengeksekusi ulang budget legalitas tanpa StateError', () {
      final spec = buildSpec(
        patterns: <SyllablePattern>[
          SyllablePattern.parse(id: 'cv', template: 'CV', weight: 1),
          SyllablePattern.parse(id: 'vc', template: 'VC', weight: 1),
        ],
        forbidden: <ForbiddenSequence>[
          ForbiddenSequence.validated(id: 'no-ae', symbols: <String>['a', 'e']),
        ],
      );
      final batch = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 202, spec: spec, syllableCount: 3),
        count: 3,
      );
      final regen = batch.regenerate();
      for (final p in regen.proposals) {
        final symbols = p.text.toLowerCase().split('');
        expect(spec.isWordLegal(symbols), isTrue, reason: p.text);
      }
    });
  });

  group('SeededNameBatch - accept_or_discard + no_auto_canon', () {
    test('accept mengubah status pada salinan, batch asal tetap proposed', () {
      final batch = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 40),
        count: 3,
      );
      final id = batch.proposals.first.proposalId;
      final accepted = batch.accept(id);
      expect(accepted.proposals.first.status, NameProposalStatus.accepted);
      expect(batch.proposals.first.status, NameProposalStatus.proposed);
      expect(accepted.acceptedCount, 1);
      expect(accepted.proposedCount, 2);
    });

    test('discard menandai dibuang; asal tak berubah', () {
      final batch = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 41),
        count: 2,
      );
      final d = batch.discard(batch.proposals.last.proposalId);
      expect(d.proposals.last.status, NameProposalStatus.discarded);
      expect(batch.proposals.last.status, NameProposalStatus.proposed);
      expect(d.discardedCount, 1);
    });

    test('accept id tidak dikenal melempar StateError', () {
      final batch = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 42),
        count: 2,
      );
      expect(() => batch.accept('tidak-ada'), throwsStateError);
    });

    test('decide ulang proposal yang sudah diputus ditolak', () {
      final batch = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 43),
        count: 2,
      );
      final id = batch.proposals.first.proposalId;
      final accepted = batch.accept(id);
      expect(
        () => accepted.discard(id),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('already'),
          ),
        ),
      );
    });

    test('no_auto_canon: generate tidak memutasi profil maupun spec input', () {
      final profile = buildProfile();
      final spec = buildSpec();
      final profileJson = jsonEncode(profile.toJson());
      final specJson = jsonEncode(spec.toJson());
      final batch = SeededNameGenerator.generateBatch(
        request: buildRequest(seed: 51, profile: profile, spec: spec),
        count: 5,
      );
      batch.accept(batch.proposals.first.proposalId);
      expect(jsonEncode(profile.toJson()), profileJson);
      expect(jsonEncode(spec.toJson()), specJson);
    });

    test(
      'no_auto_canon: generate tidak pernah menambah/mengubah profil katalog',
      () {
        final catalog = NameProfileCatalog.validated(
          profiles: <CulturalNameProfile>[buildProfile()],
        );
        final before = jsonEncode([
          for (final p in catalog.profiles) p.toJson(),
        ]);
        SeededNameGenerator.generateBatch(
          request: buildRequest(seed: 52),
          count: 4,
        );
        final after = jsonEncode([
          for (final p in catalog.profiles) p.toJson(),
        ]);
        expect(after, before);
        expect(catalog.count, 1);
      },
    );

    test('proposal immutable: syllables tidak bisa dimutasi', () {
      final p = SeededNameGenerator.generateOne(
        request: buildRequest(seed: 60),
      );
      expect(() => p.syllables.add('zz'), throwsUnsupportedError);
      expect(() => p.syllables.clear(), throwsUnsupportedError);
    });

    test('equality proposal struktural untuk perbandingan batch', () {
      final a = SeededNameGenerator.generateOne(
        request: buildRequest(seed: 61),
      );
      final b = SeededNameGenerator.generateOne(
        request: buildRequest(seed: 61),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
