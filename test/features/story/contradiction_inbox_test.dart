// Kontrak Contradiction Inbox (Step 109.14) — RED pertama.
//
// Acceptance kanonik sprint_109.json:
// severity_filter, entity_filter, jump_to_source, resolve_or_dismiss, history.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/contradiction_analysis.dart';
import 'package:void_scriptor/features/story/domain/contradiction_inbox.dart';
import 'package:void_scriptor/features/story/domain/contradiction_rule.dart';

ContradictionFinding _finding({
  required String id,
  required String ruleId,
  required String subjectId,
  ContradictionSeverity severity = ContradictionSeverity.violation,
  List<ContradictionSourceRef> sources = const <ContradictionSourceRef>[],
}) => ContradictionFinding(
  id: id,
  ruleId: ruleId,
  subjectId: subjectId,
  dimension: ContradictionDimension.time,
  severity: severity,
  confidence: DetectionConfidence.high,
  explanation: ContradictionExplanation(
    summary: 'ringkas',
    expectedValue: 'diharapkan',
    actualValue: 'nyata',
    sources: sources,
  ),
);

final DateTime t0 = DateTime.utc(2026, 8, 26, 3);

DateTime Function() makeClock(DateTime start) {
  var n = 0;
  return () => start.add(Duration(minutes: n++));
}

void main() {
  setUp(() {});

  group('severity_and_entity_filters', () {
    test('set kosong berarti semua; dua sumbu filter bekerja secara AND', () {
      final inbox = ContradictionInbox()
        ..sync(<ContradictionFinding>[
          _finding(id: 'r1::c-a', ruleId: 'r1', subjectId: 'c-a'),
          _finding(
            id: 'r2::c-b',
            ruleId: 'r2',
            subjectId: 'c-b',
            severity: ContradictionSeverity.warning,
          ),
          _finding(
            id: 'r3::c-a',
            ruleId: 'r3',
            subjectId: 'c-a',
            severity: ContradictionSeverity.info,
          ),
        ]);
      expect(inbox.open().length, 3);
      expect(
        inbox
            .open(
              severities: <ContradictionSeverity>{
                ContradictionSeverity.violation,
              },
            )
            .map((f) => f.id),
        <String>['r1::c-a'],
      );
      expect(inbox.open(subjectIds: <String>{'c-a'}).map((f) => f.id), <String>[
        'r1::c-a',
        'r3::c-a',
      ]);
      expect(inbox.open(subjectIds: <String>{'tidak-ada'}), isEmpty);
      expect(
        inbox
            .open(
              severities: <ContradictionSeverity>{
                ContradictionSeverity.warning,
              },
              subjectIds: <String>{'c-b'},
            )
            .single
            .id,
        'r2::c-b',
      );
    });
  });

  group('jump_to_source', () {
    test('mengembalikan sitasi verbatim berurutan; id tak dikenal kosong', () {
      final sources = <ContradictionSourceRef>[
        const ContradictionSourceRef(
          sourceId: 's-9',
          label: 'Bab 1 · Pembukaan',
        ),
        const ContradictionSourceRef(sourceId: 's-2', label: 'Bab 2'),
      ];
      final inbox = ContradictionInbox()
        ..sync(<ContradictionFinding>[
          _finding(
            id: 'r1::c-a',
            ruleId: 'r1',
            subjectId: 'c-a',
            sources: sources,
          ),
        ]);
      expect(inbox.jumpTargets('r1::c-a').map((s) => s.sourceId), <String>[
        's-9',
        's-2',
      ]);
      expect(inbox.jumpTargets('tak-ada'), isEmpty);
    });
  });

  group('resolve_or_dismiss', () {
    test(
      'dismiss mencatat suppression pada store bersama dan mengosongkan open',
      () {
        final store = ContradictionDismissalStore();
        final inbox =
            ContradictionInbox(dismissals: store, clock: makeClock(t0))
              ..sync(<ContradictionFinding>[
                _finding(id: 'r1::c-a', ruleId: 'r1', subjectId: 'c-a'),
              ]);
        final record = inbox.dismiss(
          'r1::c-a',
          reason: 'disengaja',
          actor: 'choi',
        );
        expect(record, isNotNull);
        expect(record!.reason, 'disengaja');
        expect(store.isDismissed(ruleId: 'r1', subjectId: 'c-a'), isTrue);
        expect(inbox.open(), isEmpty);
        expect(inbox.statusOf('r1::c-a'), ContradictionInboxStatus.dismissed);
      },
    );

    test('alasan kosong ditolak untuk dismiss maupun resolve', () {
      final inbox = ContradictionInbox(clock: makeClock(t0))
        ..sync(<ContradictionFinding>[
          _finding(id: 'r1::c-a', ruleId: 'r1', subjectId: 'c-a'),
        ]);
      expect(
        () => inbox.dismiss('r1::c-a', reason: '   '),
        throwsArgumentError,
      );
      expect(() => inbox.resolve('r1::c-a', note: ''), throwsArgumentError);
      expect(inbox.open().length, 1);
    });

    test('resolve menandai selesai tanpa menyentuh dismissal store', () {
      final store = ContradictionDismissalStore();
      final inbox = ContradictionInbox(dismissals: store, clock: makeClock(t0))
        ..sync(<ContradictionFinding>[
          _finding(id: 'r1::c-a', ruleId: 'r1', subjectId: 'c-a'),
        ]);
      final event = inbox.resolve('r1::c-a', note: 'sudah dibenarkan');
      expect(event, isNotNull);
      expect(store.isEmpty, isTrue);
      expect(inbox.open(), isEmpty);
      expect(inbox.statusOf('r1::c-a'), ContradictionInboxStatus.resolved);
    });

    test('aksi pada temuan non-open tidak menggandakan efek', () {
      final inbox = ContradictionInbox(clock: makeClock(t0))
        ..sync(<ContradictionFinding>[
          _finding(id: 'r1::c-a', ruleId: 'r1', subjectId: 'c-a'),
        ]);
      expect(inbox.dismiss('r1::c-a', reason: 'ok'), isNotNull);
      expect(inbox.dismiss('r1::c-a', reason: 'lagi'), isNull);
      expect(inbox.resolve('r1::c-a', note: 'juga'), isNull);
      expect(inbox.history.length, 1);
    });

    test('restore membuka kembali temuan yang di-dismiss', () {
      final store = ContradictionDismissalStore();
      final inbox = ContradictionInbox(dismissals: store, clock: makeClock(t0))
        ..sync(<ContradictionFinding>[
          _finding(id: 'r1::c-a', ruleId: 'r1', subjectId: 'c-a'),
        ]);
      inbox.dismiss('r1::c-a', reason: 'sementara');
      expect(inbox.restore('r1::c-a'), isTrue);
      expect(store.isDismissed(ruleId: 'r1', subjectId: 'c-a'), isFalse);
      expect(inbox.open().length, 1);
      expect(inbox.history.length, 2);
      expect(inbox.restore('r1::c-a'), isFalse);
    });
  });

  group('rescan_sync', () {
    test(
      'sync ulang mempertahankan status pasangan lama; id baru mulai open',
      () {
        final inbox = ContradictionInbox(clock: makeClock(t0));
        final first = <ContradictionFinding>[
          _finding(id: 'r1::c-a', ruleId: 'r1', subjectId: 'c-a'),
          _finding(id: 'r2::c-b', ruleId: 'r2', subjectId: 'c-b'),
        ];
        inbox.sync(first);
        inbox.dismiss('r1::c-a', reason: 'disengaja');

        inbox.sync(<ContradictionFinding>[
          ...first,
          _finding(id: 'r3::c-c', ruleId: 'r3', subjectId: 'c-c'),
        ]);

        expect(inbox.open().map((f) => f.id), <String>['r2::c-b', 'r3::c-c']);
        expect(inbox.statusOf('r1::c-a'), ContradictionInboxStatus.dismissed);
      },
    );
  });

  group('integrasi_pipeline', () {
    test('scan → inbox → dismiss → rescan menekan pasangan yang sama', () {
      final clock = makeClock(t0);
      final pipeline = ContradictionAnalysisPipeline(clock: clock);
      final inbox = ContradictionInbox(
        dismissals: pipeline.dismissals,
        clock: clock,
      );
      const rules = <ContradictionRule>[
        ContradictionRule(
          id: 'r-age',
          projectId: 'p-1',
          title: 'Usia wajar',
          dimension: ContradictionDimension.age,
          subjectKind: 'character',
          attributeKey: 'age',
          comparator: ContradictionComparator.withinRange,
          expectedValues: <String>['15', '40'],
        ),
      ];
      const subjects = <SubjectSnapshot>[
        SubjectSnapshot(
          subjectKind: 'character',
          subjectId: 'c-muda',
          attributes: <String, String>{'age': '9'},
        ),
      ];

      var result = pipeline.scan(rules: rules, subjects: subjects);
      inbox.sync(result.findings);
      expect(inbox.open().length, 1);

      inbox.dismiss('r-age::c-muda', reason: 'belum relevan', actor: 'u');
      result = pipeline.scan(rules: rules, subjects: subjects);
      expect(result.findings, isEmpty);
      inbox.sync(result.findings);
      expect(inbox.open(), isEmpty);
      expect(
        inbox.statusOf('r-age::c-muda'),
        ContradictionInboxStatus.dismissed,
      );
    });
  });

  group('history_dan_persistensi', () {
    test('riwayat kronologis dengan jam tersuntik; JSON antar-run identik', () {
      ContradictionInbox build() {
        final inbox = ContradictionInbox(clock: makeClock(t0))
          ..sync(<ContradictionFinding>[
            _finding(id: 'r1::c-a', ruleId: 'r1', subjectId: 'c-a'),
          ]);
        inbox.dismiss('r1::c-a', reason: 'x', actor: 'u');
        return inbox;
      }

      final a = build();
      final b = build();
      expect(a.history.length, 1);
      expect(a.history.single.at, t0);
      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
    });

    test('roundtrip toJson/fromJson memulihkan status dan riwayat', () {
      final inbox = ContradictionInbox(clock: makeClock(t0))
        ..sync(<ContradictionFinding>[
          _finding(id: 'r1::c-a', ruleId: 'r1', subjectId: 'c-a'),
          _finding(id: 'r2::c-b', ruleId: 'r2', subjectId: 'c-b'),
        ]);
      inbox.dismiss('r1::c-a', reason: 'x', actor: 'u');

      final restored = ContradictionInbox.fromJson(
        inbox.toJson(),
        clock: makeClock(t0),
      );

      expect(restored.statusOf('r1::c-a'), ContradictionInboxStatus.dismissed);
      expect(restored.statusOf('r2::c-b'), isNull);
      expect(restored.history.length, inbox.history.length);
      expect(jsonEncode(restored.toJson()), jsonEncode(inbox.toJson()));

      restored.sync(<ContradictionFinding>[
        _finding(id: 'r1::c-a', ruleId: 'r1', subjectId: 'c-a'),
        _finding(id: 'r2::c-b', ruleId: 'r2', subjectId: 'c-b'),
      ]);
      expect(restored.open().map((f) => f.id), <String>['r2::c-b']);
    });
  });
}
