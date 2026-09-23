/// Test for Release Blocker Triage (Step 113.30).
/// Validates the five canonical triage decisions against the blocker
/// definition, the consistency rules of a triage entry, the stop-ship /
/// rollback release gate, and the manifest.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/release_blocker_triage.dart';

void main() {
  final triage = ReleaseBlockerTriage();

  group('113.30 Release Blocker Triage', () {
    test('exposes the five canonical decision wire names', () {
      expect(TriageDecision.values, <TriageDecision>[
        TriageDecision.fixBeforeGa,
        TriageDecision.deferNonBlocker,
        TriageDecision.stopShip,
        TriageDecision.rollbackRc,
        TriageDecision.notReproducibleWithEvidence,
      ]);
      expect(TriageDecision.fixBeforeGa.wireName, 'FIX_BEFORE_GA');
      expect(TriageDecision.deferNonBlocker.wireName, 'DEFER_NON_BLOCKER');
      expect(TriageDecision.stopShip.wireName, 'STOP_SHIP');
      expect(TriageDecision.rollbackRc.wireName, 'ROLLBACK_RC');
      expect(
        TriageDecision.notReproducibleWithEvidence.wireName,
        'NOT_REPRODUCIBLE_WITH_EVIDENCE',
      );
    });

    test('empty triage is blocked pending classified issues', () {
      final decision = triage.evaluate();
      expect(decision.state, TriageState.blocked);
      expect(decision.entryCount, 0);
      expect(decision.limitations.join(' '), isNotEmpty);
    });

    test('consistent entries pass and keep their rationale', () {
      final consistent = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-401',
            meetsBlockerDefinition: true,
            reproducible: true,
            decision: TriageDecision.fixBeforeGa,
            rationale:
                'Kehilangan data saat export = melanggar definisi '
                'release blocker.',
            evidence: [
              'docs/evidence/sprint-113-26-test-release-regression.meta',
            ],
          ),
        )
        ..add(
          const TriageEntry(
            issueId: 'ISS-402',
            meetsBlockerDefinition: false,
            reproducible: true,
            decision: TriageDecision.deferNonBlocker,
            rationale: 'Cosmetic label saja, tidak menyentuh data.',
            evidence: ['docs/evidence/triage/iss-402-repro.md'],
          ),
        );

      final decision = consistent.evaluate();
      expect(decision.state, TriageState.pass);
      expect(decision.entryCount, 2);
      expect(decision.limitations.join(' '), contains('melanggar definisi'));
      expect(consistent.releaseBlocked, isFalse);
    });

    test('deferring an issue that meets the blocker definition fails', () {
      final contradictory = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-403',
            meetsBlockerDefinition: true,
            reproducible: true,
            decision: TriageDecision.deferNonBlocker,
            rationale: 'Ditunda dulu.',
            evidence: ['docs/evidence/triage/iss-403.md'],
          ),
        );

      final decision = contradictory.evaluate();
      expect(decision.state, TriageState.fail);
      expect(decision.limitations.join(' '), contains('ISS-403'));
      expect(decision.limitations.join(' '), contains('DEFER_NON_BLOCKER'));
    });

    test('stop-ship on a non-blocker fails the triage consistency', () {
      final overreach = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-404',
            meetsBlockerDefinition: false,
            reproducible: true,
            decision: TriageDecision.stopShip,
            rationale: 'Ini berhenti rilis.',
            evidence: ['docs/evidence/triage/iss-404.md'],
          ),
        );

      expect(overreach.evaluate().state, TriageState.fail);
    });

    test('NOT_REPRODUCIBLE_WITH_EVIDENCE requires evidence', () {
      final noEvidence = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-405',
            meetsBlockerDefinition: false,
            reproducible: false,
            decision: TriageDecision.notReproducibleWithEvidence,
            rationale: 'Tidak muncul di mesin manapun.',
            evidence: <String>[],
          ),
        );
      expect(noEvidence.evaluate().state, TriageState.fail);

      final withEvidence = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-406',
            meetsBlockerDefinition: false,
            reproducible: false,
            decision: TriageDecision.notReproducibleWithEvidence,
            rationale: 'Tidak muncul setelah 5 percobaan.',
            evidence: ['docs/evidence/triage/iss-406-attempts.log'],
          ),
        );
      expect(withEvidence.evaluate().state, TriageState.pass);
    });

    test('stop-ship and rollback gate the release', () {
      final gated = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-407',
            meetsBlockerDefinition: true,
            reproducible: true,
            decision: TriageDecision.stopShip,
            rationale: 'Corrupt database pada jalur restore.',
            evidence: ['docs/evidence/triage/iss-407.md'],
          ),
        );
      expect(gated.evaluate().state, TriageState.pass);
      expect(gated.releaseBlocked, isTrue);

      final rollback = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-408',
            meetsBlockerDefinition: true,
            reproducible: true,
            decision: TriageDecision.rollbackRc,
            rationale: 'RC memperkenalkan regresi schema.',
            evidence: ['docs/evidence/triage/iss-408.md'],
          ),
        );
      expect(rollback.releaseBlocked, isTrue);
    });

    test('blank rationale fails the triage entry', () {
      final blank = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-409',
            meetsBlockerDefinition: true,
            reproducible: true,
            decision: TriageDecision.fixBeforeGa,
            rationale: ' ',
            evidence: ['docs/evidence/triage/iss-409.md'],
          ),
        );
      final decision = blank.evaluate();
      expect(decision.state, TriageState.fail);
      expect(decision.limitations.join(' '), contains('ISS-409'));
    });

    test('manifest lists the five canonical decisions with live status', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_113_release_blocker_triage.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '113.30');
      final decisions = manifest['decisions'] as Map<String, dynamic>;
      expect(decisions.keys.toSet(), <String>{
        'FIX_BEFORE_GA',
        'DEFER_NON_BLOCKER',
        'STOP_SHIP',
        'ROLLBACK_RC',
        'NOT_REPRODUCIBLE_WITH_EVIDENCE',
      });
      for (final value in decisions.values) {
        final entry = value as Map<String, dynamic>;
        expect(entry['description'], isNotEmpty);
        expect(entry['status'], isNotEmpty);
      }
      expect(manifest['limits'], isNotEmpty);
      expect(manifest['decision'], isNotEmpty);
    });
  });
}
