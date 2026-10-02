/// Sprint 117.38 — Issue Deduplication & Triage regression guards.
///
/// The canonical step requires that duplicate issues are merged and that a
/// blocker is cut with one of six decisions. These tests pin the seam that
/// actually performs both, because both were fail-open: a decision could
/// contradict the record it was derived from, a report could be folded into
/// itself, and a deduplication call could leave both reports live.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/issue_deduplication_root_cause.dart';
import 'package:void_scriptor/features/world_logic/domain/issue_deduplication_root_cause_v114.dart'
    as v114;
import 'package:void_scriptor/features/world_logic/domain/release_blocker_triage.dart';

void main() {
  group(
    '117.38 deduplication and triage must not contradict its own record',
    () {
      test(
        'not reproducible is rejected when the record says it reproduces',
        () {
          final log = ReleaseBlockerTriage()
            ..add(
              const TriageEntry(
                issueId: 'ISS-REPRO-CONTRADICTION',
                meetsBlockerDefinition: false,
                reproducible: true,
                decision: TriageDecision.notReproducibleWithEvidence,
                rationale:
                    'Keputusan menyatakan tidak reproducible, sementara '
                    'record menyatakan ia reproducible.',
                evidence: <String>['docs/evidence/triage/iss-repro.log'],
              ),
            );

          final decision = log.evaluate();
          expect(decision.state, TriageState.fail);
          expect(
            decision.limitations.join(' '),
            contains('NOT_REPRODUCIBLE_WITH_EVIDENCE'),
          );
        },
      );

      test(
        'not reproducible is rejected when the record says it is a blocker',
        () {
          final log = ReleaseBlockerTriage()
            ..add(
              const TriageEntry(
                issueId: 'ISS-REPRO-BLOCKER',
                meetsBlockerDefinition: true,
                reproducible: true,
                decision: TriageDecision.notReproducibleWithEvidence,
                rationale:
                    'Isu yang memenuhi definisi blocker tidak dapat ditutup '
                    'dengan keputusan tidak reproducible.',
                evidence: <String>['docs/evidence/triage/iss-blocker.log'],
              ),
            );

          expect(log.evaluate().state, TriageState.fail);
        },
      );

      test(
        'a blocker issue that is not reproducible still cannot be deferred',
        () {
          final log = ReleaseBlockerTriage()
            ..add(
              const TriageEntry(
                issueId: 'ISS-NOT-REPRO-BLOCKER',
                meetsBlockerDefinition: true,
                reproducible: false,
                decision: TriageDecision.deferNonBlocker,
                rationale:
                    'Tidak reproducible, tapi tetap memenuhi definisi '
                    'release blocker sehingga tidak boleh ditunda.',
                evidence: <String>['docs/evidence/triage/iss-not-repro.log'],
              ),
            );

          expect(log.evaluate().state, TriageState.fail);
        },
      );

      test('an untriaged release reports blocked, not unblocked', () {
        final log = ReleaseBlockerTriage();
        // Nothing triaged is not the same fact as nothing blocking the
        // release: the first is an undecided state, the second is a decision.
        expect(log.evaluate().state, TriageState.blocked);
        expect(log.releaseBlocked, isFalse);
      });

      test('a report cannot be folded into itself', () {
        final registry = IssueRegistry()
          ..add(
            const IssueReport(
              issueId: 'ISS-SELF',
              duplicates: <String>[],
              reproduction: <String>['langkah A'],
              component: 'c',
              rootCause: 'r',
              affectedVersions: <String>['1.3.0'],
              owner: 'o',
            ),
          );

        Object? thrown;
        try {
          registry.mergeDuplicates('ISS-SELF', <String>['ISS-SELF']);
        } catch (error) {
          thrown = error;
        }

        expect(thrown, isA<ArgumentError>());
        // The fold must be refused, not recorded as a successful merge.
        expect(registry.duplicateTargets, isEmpty);
        expect(registry.reports.single.duplicates, isEmpty);
        expect(registry.evaluate().decision, IssueDecision.pass);
      });

      test('a v114 record cannot be folded into itself either', () {
        final register = v114.IssueRegister()
          ..add(
            const v114.IssueRecord(
              issueId: 'ISS-SELF-114',
              duplicates: <String>[],
              reproduction: <String>['langkah A'],
              affectedVersions: <String>['1.3.0'],
              rootCause: 'r',
              owner: 'o',
              fixPath: 'lib/fix.dart',
            ),
          );

        Object? thrown;
        try {
          register.mergeDuplicates('ISS-SELF-114', <String>['ISS-SELF-114']);
        } catch (error) {
          thrown = error;
        }

        expect(thrown, isA<ArgumentError>());
        expect(register.evaluate().status, v114.IssueStatus.pass);
      });

      test('a fold that cannot complete leaves every report live', () {
        // Resolving the targets one at a time means a missing target throws
        // after the earlier ones were already removed. The report that was
        // removed is then gone from the live set and from the canonical's
        // duplicate list, so its reproduction steps and versions are lost and
        // the decision still reports pass with no limitation.
        final registry = IssueRegistry()
          ..add(
            const IssueReport(
              issueId: 'ISS-PARTIAL-CANON',
              duplicates: <String>[],
              reproduction: <String>['langkah kanon'],
              component: 'c',
              rootCause: 'r',
              affectedVersions: <String>['1.3.0'],
              owner: 'o',
            ),
          )
          ..add(
            const IssueReport(
              issueId: 'ISS-PARTIAL-DUP',
              duplicates: <String>[],
              reproduction: <String>['langkah duplikat'],
              component: 'c',
              rootCause: 'r',
              affectedVersions: <String>['1.3.0'],
              owner: 'o',
            ),
          );

        Object? thrown;
        try {
          registry.mergeDuplicates('ISS-PARTIAL-CANON', <String>[
            'ISS-PARTIAL-DUP',
            'ISS-NOT-REGISTERED',
          ]);
        } catch (error) {
          thrown = error;
        }

        expect(thrown, isA<ArgumentError>());
        // Nothing was folded, so nothing may be missing from the live set.
        expect(
          registry.reports.map((report) => report.issueId).toList(),
          containsAll(<String>['ISS-PARTIAL-CANON', 'ISS-PARTIAL-DUP']),
        );
        expect(registry.duplicateTargets, isEmpty);
        final canonical = registry.reports.firstWhere(
          (report) => report.issueId == 'ISS-PARTIAL-CANON',
        );
        expect(canonical.duplicates, isEmpty);
        expect(canonical.reproduction, <String>['langkah kanon']);
      });

      test('a v114 fold that cannot complete leaves every issue live', () {
        final register = v114.IssueRegister()
          ..add(
            const v114.IssueRecord(
              issueId: 'ISS-PARTIAL-CANON-114',
              duplicates: <String>[],
              reproduction: <String>['langkah kanon'],
              affectedVersions: <String>['1.3.0'],
              rootCause: 'r',
              owner: 'o',
              fixPath: 'lib/fix.dart',
            ),
          )
          ..add(
            const v114.IssueRecord(
              issueId: 'ISS-PARTIAL-DUP-114',
              duplicates: <String>[],
              reproduction: <String>['langkah duplikat'],
              affectedVersions: <String>['1.3.0'],
              rootCause: 'r',
              owner: 'o',
              fixPath: 'lib/fix.dart',
            ),
          );

        Object? thrown;
        try {
          register.mergeDuplicates('ISS-PARTIAL-CANON-114', <String>[
            'ISS-PARTIAL-DUP-114',
            'ISS-NOT-REGISTERED-114',
          ]);
        } catch (error) {
          thrown = error;
        }

        expect(thrown, isA<ArgumentError>());
        expect(
          register.evaluate().issueCount,
          2,
          reason: 'a failed fold must not remove a registered issue',
        );
      });

      test('mergeWith states which report was folded instead of silently '
          'combining them', () {
        const a = IssueReport(
          issueId: 'ISS-A',
          duplicates: <String>[],
          reproduction: <String>['langkah A'],
          component: 'c',
          rootCause: 'r',
          affectedVersions: <String>['1.3.0'],
          owner: 'o',
        );
        const b = IssueReport(
          issueId: 'ISS-B',
          duplicates: <String>[],
          reproduction: <String>['langkah B'],
          component: 'c',
          rootCause: 'r',
          affectedVersions: <String>['1.3.0'],
          owner: 'o',
        );

        final merged = a.mergeWith(b);
        // A caller that deduplicates two reports must be able to see which
        // report is now the duplicate; otherwise the merge is invisible and
        // the registry keeps both live.
        expect(merged.duplicates, contains('ISS-B'));
        expect(merged.reproduction, <String>['langkah A', 'langkah B']);
      });
    },
  );
}
