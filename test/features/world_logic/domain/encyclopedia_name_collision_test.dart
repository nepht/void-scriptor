// Sprint 111.32 - Name Collision & Cultural Consistency (domain-only).
//
// Acceptance canonical dipetakan:
// - exact_collision    -> kandidat identik (ternormalisasi) dengan nama
//                         terdaftar / kandidat sebelumnya => issue blocking
// - similarity_warning -> jarak Levenshtein ternormalisasi >= threshold =>
//                         issue non-blocking (peringatan, bukan blokir)
// - phonotactic_check  -> simbol tak dikenal inventory + ForbiddenSequence
//                         via spec.violationsIn => issue blocking
// - culture_check      -> cultureId/languageId kandidat vs profil aktif +
//                         whitelist entityType => issue blocking
// - reserved_names     -> teks ternormalisasi masuk daftar cadangan registry
//                         => issue blocking
// - manual_accept      -> NameManualAcceptance (candidateId, kind) menekan
//                         issue, pola konsisten ArtifactManualException 111.23
//
// Domain murni deterministik: tanpa persistence, UI, locale, jaringan,
// wall-clock, atau dart:math Random. D-SCHEMA-01 tetap OPEN.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_collision.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_seeded_name_generation.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_syllable_phonotactics.dart';

// ---------------------------------------------------------------- fixtures

SyllablePart _v(String symbol, List<SyllableSlot> slots) =>
    SyllablePart.validated(symbol: symbol, slots: slots);

const List<SyllableSlot> _allSlots = <SyllableSlot>[
  SyllableSlot.onset,
  SyllableSlot.nucleus,
  SyllableSlot.coda,
];

PhonotacticsSpec buildSpec({String languageId = 'elv-a'}) {
  return PhonotacticsSpec.validated(
    id: 'spec-elv',
    languageId: languageId,
    inventory: <SyllablePart>[
      _v('a', <SyllableSlot>[SyllableSlot.nucleus]),
      _v('e', <SyllableSlot>[SyllableSlot.nucleus]),
      _v('i', <SyllableSlot>[SyllableSlot.nucleus]),
      _v('l', _allSlots),
      _v('m', _allSlots),
      _v('n', _allSlots),
      _v('r', _allSlots),
      _v('s', _allSlots),
      _v('t', _allSlots),
    ],
    patterns: <SyllablePattern>[
      SyllablePattern.parse(id: 'cv', template: 'CV'),
    ],
    forbidden: <ForbiddenSequence>[
      ForbiddenSequence.validated(id: 'no-rr', symbols: <String>['r', 'r']),
    ],
  );
}

CulturalNameProfile buildProfile({
  String profileId = 'prof-elv',
  String cultureId = 'eldar',
  String languageId = 'elv-a',
  Set<NameEntityType>? entityTypes,
}) {
  return CulturalNameProfile.validated(
    profileId: profileId,
    cultureId: cultureId,
    languageId: languageId,
    entityTypes:
        entityTypes ??
        <NameEntityType>{NameEntityType.person, NameEntityType.place},
  );
}

NameCandidate candidate(
  String id,
  String text, {
  String cultureId = 'eldar',
  String languageId = 'elv-a',
  NameEntityType entityType = NameEntityType.person,
}) {
  return NameCandidate.validated(
    candidateId: id,
    text: text,
    cultureId: cultureId,
    languageId: languageId,
    entityType: entityType,
  );
}

CanonicalNameRecord record(
  String id,
  String text, {
  String cultureId = 'eldar',
  String languageId = 'elv-a',
  NameEntityType entityType = NameEntityType.person,
}) {
  return CanonicalNameRecord.validated(
    recordId: id,
    text: text,
    cultureId: cultureId,
    languageId: languageId,
    entityType: entityType,
  );
}

CanonicalNameRegistry registry({
  List<CanonicalNameRecord> records = const <CanonicalNameRecord>[],
  Set<String> reserved = const <String>{},
}) =>
    CanonicalNameRegistry.validated(records: records, reservedNames: reserved);

NameCheckReport run(
  List<NameCandidate> candidates, {
  CanonicalNameRegistry? reg,
  CulturalNameProfile? profile,
  PhonotacticsSpec? spec,
  double similarityThreshold = 0.75,
  List<NameManualAcceptance> acceptances = const <NameManualAcceptance>[],
}) {
  return const NameConsistencyValidator().validate(
    candidates: candidates,
    registry: reg ?? registry(),
    profile: profile,
    spec: spec,
    similarityThreshold: similarityThreshold,
    acceptances: acceptances,
  );
}

// ---------------------------------------------------------------- suite

void main() {
  group('NameCheckKind & labels', () {
    test('ada tepat lima kind dengan label non-kosong unik', () {
      expect(NameCheckKind.values.length, 5);
      expect(
        NameCheckKind.values.map((k) => k.label).toSet().length,
        NameCheckKind.values.length,
      );
      for (final k in NameCheckKind.values) {
        expect(k.label.trim(), isNotEmpty);
      }
    });

    test(
      'blocking classification: hanya similarityWarning yang non-blocking',
      () {
        for (final k in NameCheckKind.values) {
          expect(
            k.isBlocking,
            k != NameCheckKind.similarityWarning,
            reason: k.name,
          );
        }
      },
    );
  });

  group('CanonicalNameRecord & normalization', () {
    test('field dipangkas; kosong ditolak', () {
      final r = record('r1', '  Aelindis ');
      expect(r.recordId, 'r1');
      expect(r.text, 'Aelindis');
      expect(() => record(' ', 'x'), throwsArgumentError);
      expect(() => record('r2', '  '), throwsArgumentError);
      expect(() => record('r2', 'x', cultureId: ''), throwsArgumentError);
    });

    test('normalizedText = lowercase, trim, whitespace dikolaps', () {
      expect(
        record('r1', '  Aelindis   the  Wise ').normalizedText,
        'aelindis the wise',
      );
    });
  });

  group('CanonicalNameRegistry', () {
    test('recordId duplikat ditolak; reservedNames dinormalisasi', () {
      expect(
        () => registry(
          records: <CanonicalNameRecord>[record('r1', 'A'), record('r1', 'B')],
        ),
        throwsArgumentError,
      );
      final reg = registry(reserved: <String>{' The  Void '});
      expect(reg.reservedNames, <String>{'the void'});
    });

    test('records getter immutable dan sorted-by-recordId', () {
      final reg = registry(
        records: <CanonicalNameRecord>[record('r2', 'B'), record('r1', 'A')],
      );
      expect(reg.records.map((r) => r.recordId), <String>['r1', 'r2']);
      expect(() => reg.records.add(record('r3', 'C')), throwsUnsupportedError);
    });
  });

  group('exact_collision', () {
    test('teks identik dengan record terdaftar (case/whitespace beda) => '
        'issue exactCollision blocking', () {
      final report = run(
        <NameCandidate>[candidate('c1', 'aelindis')],
        reg: registry(records: <CanonicalNameRecord>[record('r1', 'Aelindis')]),
        profile: buildProfile(),
        spec: buildSpec(),
      );
      final issues = report.issuesOf(NameCheckKind.exactCollision);
      expect(issues, hasLength(1));
      expect(issues.single.candidateId, 'c1');
      expect(issues.single.relatedId, 'r1');
      expect(report.hasBlockingIssues, isTrue);
    });

    test(
      'dua kandidat identik dalam satu batch => kandidat kedua menabrak',
      () {
        final report = run(
          <NameCandidate>[
            candidate('c1', 'Aelindis'),
            candidate('c2', 'aelindis'),
          ],
          reg: registry(records: <CanonicalNameRecord>[record('r9', 'Lërien')]),
        );
        final issues = report.issuesOf(NameCheckKind.exactCollision);
        expect(issues, hasLength(1));
        expect(issues.single.candidateId, 'c2');
        expect(issues.single.relatedId, 'c1');
      },
    );

    test('tanpa tabrakan => nol exactCollision', () {
      final report = run(<NameCandidate>[
        candidate('c1', 'Aelindis'),
      ], reg: registry(records: <CanonicalNameRecord>[record('r1', 'Cirion')]));
      expect(report.issuesOf(NameCheckKind.exactCollision), isEmpty);
    });
  });

  group('similarity_warning', () {
    test(
      'Aelindis vs Aelindis2 (jarak 1) => similarityWarning non-blocking',
      () {
        final report = run(
          <NameCandidate>[candidate('c1', 'Aelindis')],
          reg: registry(
            records: <CanonicalNameRecord>[record('r1', 'Aelindis2')],
          ),
        );
        final issues = report.issuesOf(NameCheckKind.similarityWarning);
        expect(issues, hasLength(1));
        expect(issues.single.relatedId, 'r1');
        expect(report.hasBlockingIssues, isFalse);
        expect(report.hasIssues, isTrue);
      },
    );

    test('di bawah threshold tidak diperingatkan', () {
      final report = run(<NameCandidate>[
        candidate('c1', 'Aelindis'),
      ], reg: registry(records: <CanonicalNameRecord>[record('r1', 'Tulka')]));
      expect(report.issues, isEmpty);
    });

    test('threshold custom 0.9 merestruksi peringatan jadi lolos', () {
      // 'aelindis' vs 'aelindir' -> jarak 1, panjang 8 => 0.875.
      final withLow = run(
        <NameCandidate>[candidate('c1', 'Aelindis')],
        reg: registry(records: <CanonicalNameRecord>[record('r1', 'Aelindir')]),
        similarityThreshold: 0.75,
      );
      expect(withLow.issuesOf(NameCheckKind.similarityWarning), hasLength(1));
      final withHigh = run(
        <NameCandidate>[candidate('c1', 'Aelindis')],
        reg: registry(records: <CanonicalNameRecord>[record('r1', 'Aelindir')]),
        similarityThreshold: 0.95,
      );
      expect(withHigh.issuesOf(NameCheckKind.similarityWarning), isEmpty);
    });

    test('threshold di luar (0,1] ditolak', () {
      expect(
        () =>
            run(<NameCandidate>[candidate('c1', 'x')], similarityThreshold: 0),
        throwsArgumentError,
      );
      expect(
        () => run(<NameCandidate>[
          candidate('c1', 'x'),
        ], similarityThreshold: 1.5),
        throwsArgumentError,
      );
    });

    test(
      'record budaya sama dihitung mirip; exact tetap menang (tanpa dupel)',
      () {
        // Exact match tidak boleh sekaligus menghasilkan similarityWarning.
        final report = run(
          <NameCandidate>[candidate('c1', 'Aelindis')],
          reg: registry(
            records: <CanonicalNameRecord>[record('r1', 'Aelindis')],
          ),
        );
        expect(report.issuesOf(NameCheckKind.similarityWarning), isEmpty);
        expect(report.issuesOf(NameCheckKind.exactCollision), hasLength(1));
      },
    );
  });

  group('phonotactic_check', () {
    test('simbol di luar inventory => phonotacticViolation', () {
      final report = run(
        <NameCandidate>[candidate('c1', 'Azoth')],
        profile: buildProfile(),
        spec: buildSpec(),
      );
      final issues = report.issuesOf(NameCheckKind.phonotacticViolation);
      expect(issues, hasLength(1));
      expect(issues.single.message, contains('z'));
      expect(report.hasBlockingIssues, isTrue);
    });

    test('ForbiddenSequence berlaku atas kandidat (huruf di-lowercase)', () {
      final report = run(
        <NameCandidate>[candidate('c1', 'Arrisen')],
        profile: buildProfile(),
        spec: buildSpec(),
      );
      final issues = report.issuesOf(NameCheckKind.phonotacticViolation);
      expect(issues, hasLength(1));
      expect(issues.single.message, contains('no-rr'));
    });

    test('kandidat sah => nol phonotacticViolation', () {
      final report = run(
        <NameCandidate>[candidate('c1', 'Melinen')],
        profile: buildProfile(),
        spec: buildSpec(),
      );
      expect(report.issuesOf(NameCheckKind.phonotacticViolation), isEmpty);
    });

    test('spec null => check dilewati (tidak bisa mengklaim legalitas)', () {
      final report = run(<NameCandidate>[
        candidate('c1', 'Azoth'),
      ], profile: buildProfile());
      expect(report.issuesOf(NameCheckKind.phonotacticViolation), isEmpty);
    });
  });

  group('culture_check', () {
    test('cultureId beda dari profil aktif => cultureMismatch', () {
      final report = run(
        <NameCandidate>[candidate('c1', 'Aelindis', cultureId: 'men')],
        profile: buildProfile(),
        spec: buildSpec(),
      );
      final issues = report.issuesOf(NameCheckKind.cultureMismatch);
      expect(issues, hasLength(1));
      expect(issues.single.message, contains('eldar'));
    });

    test('languageId beda dari profil aktif => cultureMismatch', () {
      final report = run(
        <NameCandidate>[candidate('c1', 'Aelindis', languageId: 'khuz')],
        profile: buildProfile(),
        spec: buildSpec(),
      );
      expect(report.issuesOf(NameCheckKind.cultureMismatch), hasLength(1));
    });

    test('entityType di luar whitelist profil => cultureMismatch', () {
      final report = run(
        <NameCandidate>[
          candidate('c1', 'Aelindis', entityType: NameEntityType.deity),
        ],
        profile: buildProfile(),
        spec: buildSpec(),
      );
      expect(report.issuesOf(NameCheckKind.cultureMismatch), hasLength(1));
    });

    test('record terdaftar beda budaya ikut dilaporkan saat tipe sama', () {
      final report = run(
        <NameCandidate>[candidate('c1', 'Azog')],
        reg: registry(
          records: <CanonicalNameRecord>[
            record('r1', 'Azog', cultureId: 'men'),
          ],
        ),
        profile: buildProfile(),
      );
      // Culture check kandidat vs profil aktif: kandidat mengaku eldar dan
      // cocok profil; tabrakan budaya muncul dari record kanon.
      final issues = report.issuesOf(NameCheckKind.cultureMismatch);
      expect(issues, hasLength(1));
      expect(issues.single.relatedId, 'r1');
    });

    test('profile null => culture check terhadap kandidat dilewati', () {
      final report = run(<NameCandidate>[
        candidate('c1', 'Aelindis', cultureId: 'siapa'),
      ]);
      expect(report.issuesOf(NameCheckKind.cultureMismatch), isEmpty);
    });
  });

  group('reserved_names', () {
    test('teks ternormalisasi masuk reserved => issue blocking', () {
      final report = run(
        <NameCandidate>[candidate('c1', 'The Void')],
        reg: registry(reserved: <String>{'the void'}),
        profile: buildProfile(),
        spec: buildSpec(),
      );
      final issues = report.issuesOf(NameCheckKind.reservedName);
      expect(issues, hasLength(1));
      expect(report.hasBlockingIssues, isTrue);
    });

    test('reserved hanya dibandingkan ternormalisasi (case-insensitive)', () {
      final report = run(<NameCandidate>[
        candidate('c1', 'THE   VOID'),
      ], reg: registry(reserved: <String>{'The Void'}));
      expect(report.issuesOf(NameCheckKind.reservedName), hasLength(1));
    });

    test('nama tidak reserved lolos', () {
      final report = run(
        <NameCandidate>[candidate('c1', 'Melinen')],
        reg: registry(reserved: <String>{'the void'}),
        profile: buildProfile(),
        spec: buildSpec(),
      );
      expect(report.issuesOf(NameCheckKind.reservedName), isEmpty);
    });
  });

  group('manual_accept', () {
    test('acceptance (candidateId, kind) menekan issue-nya saja', () {
      final cands = <NameCandidate>[candidate('c1', 'The Void')];
      final reg = registry(reserved: <String>{'the void'});
      final before = run(cands, reg: reg);
      expect(before.issuesOf(NameCheckKind.reservedName), hasLength(1));

      final after = run(
        cands,
        reg: reg,
        acceptances: <NameManualAcceptance>[
          NameManualAcceptance.validated(
            acceptanceId: 'ma1',
            candidateId: 'c1',
            kind: NameCheckKind.reservedName,
            reason: 'Dipakai untuk entitas kanon, keputusan penulis.',
          ),
        ],
      );
      expect(after.issuesOf(NameCheckKind.reservedName), isEmpty);
      expect(after.hasIssues, isFalse);
    });

    test('acceptance untuk kind lain tidak berlaku', () {
      final report = run(
        <NameCandidate>[candidate('c1', 'The Void')],
        reg: registry(reserved: <String>{'the void'}),
        acceptances: <NameManualAcceptance>[
          NameManualAcceptance.validated(
            acceptanceId: 'ma1',
            candidateId: 'c1',
            kind: NameCheckKind.exactCollision,
            reason: 'salah kind',
          ),
        ],
      );
      expect(report.issuesOf(NameCheckKind.reservedName), hasLength(1));
    });

    test('acceptance field wajib non-kosong dan duplikat id ditolak', () {
      expect(
        () => NameManualAcceptance.validated(
          acceptanceId: 'ma1',
          candidateId: 'c1',
          kind: NameCheckKind.reservedName,
          reason: '  ',
        ),
        throwsArgumentError,
      );
      expect(
        () => run(
          <NameCandidate>[candidate('c1', 'The Void')],
          reg: registry(reserved: <String>{'the void'}),
          acceptances: <NameManualAcceptance>[
            NameManualAcceptance.validated(
              acceptanceId: 'ma',
              candidateId: 'c1',
              kind: NameCheckKind.reservedName,
              reason: 'r1',
            ),
            NameManualAcceptance.validated(
              acceptanceId: 'ma',
              candidateId: 'c1',
              kind: NameCheckKind.exactCollision,
              reason: 'r2',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('matches() hanya tepat pasangan (candidateId, kind)', () {
      final a = NameManualAcceptance.validated(
        acceptanceId: 'ma1',
        candidateId: 'c1',
        kind: NameCheckKind.reservedName,
        reason: 'r',
      );
      expect(a.matches('c1', NameCheckKind.reservedName), isTrue);
      expect(a.matches('c2', NameCheckKind.reservedName), isFalse);
      expect(a.matches('c1', NameCheckKind.exactCollision), isFalse);
    });
  });

  group('laporan & determinisme', () {
    test('issueId unik, laporan terurut issueId, describe() menyebut kind', () {
      final report = run(
        <NameCandidate>[
          candidate('c1', 'Ilinen Tal'),
          candidate('c2', 'Melinen'),
        ],
        reg: registry(
          records: <CanonicalNameRecord>[record('r1', 'Melinen')],
          reserved: <String>{'Ilinen Tal'},
        ),
        profile: buildProfile(),
        spec: buildSpec(),
      );
      expect(report.issueCount, 2, reason: report.describe());
      expect(report.issues.map((i) => i.issueId).toSet().length, 2);
      final sorted = report.issues.map((i) => i.issueId).toList();
      final copy = List<String>.of(sorted)..sort();
      expect(sorted, copy);
      expect(report.describe(), contains('Reserved name'));
      expect(report.describe(), contains('Exact collision'));
    });

    test('validate deterministik: dua run => JSON laporan identik', () {
      final cands = <NameCandidate>[
        candidate('c1', 'The Void'),
        candidate('c2', 'Aelindis'),
        candidate('c3', 'Arrisen'),
      ];
      final reg = registry(
        records: <CanonicalNameRecord>[record('r1', 'Aelindis')],
        reserved: <String>{'the void'},
      );
      final a = run(
        cands,
        reg: reg,
        profile: buildProfile(),
        spec: buildSpec(),
      );
      final b = run(
        cands,
        reg: reg,
        profile: buildProfile(),
        spec: buildSpec(),
      );
      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
    });

    test('kandidat bersih nol issues', () {
      final report = run(
        <NameCandidate>[candidate('c1', 'Melinen')],
        reg: registry(records: <CanonicalNameRecord>[record('r1', 'Cirion')]),
        profile: buildProfile(),
        spec: buildSpec(),
      );
      expect(report.hasIssues, isFalse);
      expect(report.issueCount, 0);
      expect(report.describe(), contains('No name'));
    });

    test('candidates kosong ditolak', () {
      expect(() => run(<NameCandidate>[]), throwsArgumentError);
    });

    test('issue JSON roundtrip mempertahankan field kunci', () {
      final report = run(<NameCandidate>[
        candidate('c1', 'The Void'),
      ], reg: registry(reserved: <String>{'the void'}));
      final issue = report.issues.single;
      final back = NameCheckIssue.fromJson(
        jsonDecode(jsonEncode(issue.toJson())) as Map<String, Object?>,
      );
      expect(back.issueId, issue.issueId);
      expect(back.candidateId, issue.candidateId);
      expect(back.kind, issue.kind);
      expect(back.relatedId, issue.relatedId);
      expect(back.blocking, issue.blocking);
    });
  });

  group('integrasi 111.31 seeded proposals', () {
    test('NameCandidate.fromProposal memakai request.profile + entityType', () {
      final request = SeededNameRequest.validated(
        profile: buildProfile(),
        spec: buildSpec(),
        entityType: NameEntityType.person,
        seed: 42,
      );
      final batch = SeededNameGenerator.generateBatch(
        request: request,
        count: 3,
      );
      final candidates = batch.proposals
          .map((p) => NameCandidate.fromProposal(p, request))
          .toList();
      expect(candidates.length, 3);
      for (var i = 0; i < candidates.length; i++) {
        expect(candidates[i].candidateId, batch.proposals[i].proposalId);
        expect(candidates[i].text, batch.proposals[i].text);
        expect(candidates[i].cultureId, 'eldar');
        expect(candidates[i].languageId, 'elv-a');
        expect(candidates[i].entityType, NameEntityType.person);
      }
    });

    test('proposal yang ditabrakkan ke dirinya sendiri (record idem) tidak '
        'self-collision: related id beda => collision tetap dilaporkan', () {
      final request = SeededNameRequest.validated(
        profile: buildProfile(),
        spec: buildSpec(),
        entityType: NameEntityType.person,
        seed: 7,
      );
      final proposal = SeededNameGenerator.generateOne(request: request);
      final c = NameCandidate.fromProposal(proposal, request);
      // Candidate id = proposalId; record id berbeda => tabrakan nyata.
      final report = run(
        <NameCandidate>[c],
        reg: registry(
          records: <CanonicalNameRecord>[record('canon-1', proposal.text)],
        ),
        profile: request.profile,
        spec: buildSpec(),
      );
      expect(report.issuesOf(NameCheckKind.exactCollision), hasLength(1));
      // Self-comparison: candidateId == recordId => tidak tabrakan.
      final selfReport = run(
        <NameCandidate>[c],
        reg: registry(
          records: <CanonicalNameRecord>[record(c.candidateId, proposal.text)],
        ),
        profile: request.profile,
        spec: buildSpec(),
      );
      expect(selfReport.issuesOf(NameCheckKind.exactCollision), isEmpty);
    });

    test('satu batch penuh lolos validator terhadap registry kosong', () {
      final request = SeededNameRequest.validated(
        profile: buildProfile(),
        spec: buildSpec(),
        entityType: NameEntityType.person,
        seed: 123,
      );
      final batch = SeededNameGenerator.generateBatch(
        request: request,
        count: 10,
      );
      final report = run(
        batch.proposals
            .map((p) => NameCandidate.fromProposal(p, request))
            .toList(),
        profile: buildProfile(),
        spec: buildSpec(),
      );
      expect(report.hasIssues, isFalse, reason: report.describe());
    });
  });
}
