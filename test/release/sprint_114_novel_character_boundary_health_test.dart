import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/novel_character_boundary_health.dart';

void main() {
  group('114.13 Novel-Character Boundary Health', () {
    test('absent observations are blocked without health claims', () {
      final report = NovelCharacterBoundaryHealth().evaluate(null);

      expect(report.state, NovelCharacterBoundaryState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete signal coverage fails with signals invalid field', () {
      final report = NovelCharacterBoundaryHealth()
          .evaluate(<NovelCharacterBoundaryObservation>[
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.distinctNamespaces,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Novel and character archives use separate namespaces.',
            ),
          ]);

      expect(report.state, NovelCharacterBoundaryState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <NovelCharacterBoundarySignal>[
        NovelCharacterBoundarySignal.distinctNamespaces,
      ]);
    });

    test('observation without a note is invalid evidence', () {
      final report = NovelCharacterBoundaryHealth()
          .evaluate(<NovelCharacterBoundaryObservation>[
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.distinctNamespaces,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Novel and character archives use separate namespaces.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.referenceIntegrity,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Cross-workspace references resolve cleanly.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.overrideIsolation,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'No override crossed a workspace boundary.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.unlinkSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Unlink removed only the targeted link.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.deleteSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Delete touched only its owning workspace.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.permissionBoundary,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Permission checks held at the workspace edge.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.restoreResults,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: '',
            ),
          ]);

      expect(report.state, NovelCharacterBoundaryState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('namespace collision surviving restore is unrecovered', () {
      final report = NovelCharacterBoundaryHealth()
          .evaluate(<NovelCharacterBoundaryObservation>[
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.distinctNamespaces,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Character export overwrote the novel namespace slot.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.referenceIntegrity,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Cross-workspace references resolve cleanly.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.overrideIsolation,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'No override crossed a workspace boundary.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.unlinkSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Unlink removed only the targeted link.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.deleteSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Delete touched only its owning workspace.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.permissionBoundary,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Permission checks held at the workspace edge.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.restoreResults,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Restore replayed the colliding namespace unchanged.',
            ),
          ]);

      expect(report.state, NovelCharacterBoundaryState.fail);
      expect(report.violations, contains('namespaces_unrecovered'));
    });

    test('unsafe unlink that breaks references is reported', () {
      final report = NovelCharacterBoundaryHealth()
          .evaluate(<NovelCharacterBoundaryObservation>[
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.distinctNamespaces,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Novel and character archives use separate namespaces.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.referenceIntegrity,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Scene->character references dangle after unlink.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.overrideIsolation,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'No override crossed a workspace boundary.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.unlinkSafety,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Unlink cascade touched records outside its scope.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.deleteSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Delete touched only its owning workspace.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.permissionBoundary,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Permission checks held at the workspace edge.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.restoreResults,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'No restore required in window.',
            ),
          ]);

      expect(report.state, NovelCharacterBoundaryState.fail);
      expect(report.violations, contains('unlink_broke_references'));
    });

    test('broken references without successful restore are unrepaired', () {
      final report = NovelCharacterBoundaryHealth()
          .evaluate(<NovelCharacterBoundaryObservation>[
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.distinctNamespaces,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Novel and character archives use separate namespaces.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.referenceIntegrity,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Migration left cross-workspace references dangling.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.overrideIsolation,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'No override crossed a workspace boundary.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.unlinkSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Unlink removed only the targeted link.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.deleteSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Delete touched only its owning workspace.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.permissionBoundary,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Permission checks held at the workspace edge.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.restoreResults,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Restore declined the corrupt journal.',
            ),
          ]);

      expect(report.state, NovelCharacterBoundaryState.fail);
      expect(report.violations, contains('references_unrepaired'));
    });

    test('unsafe delete without successful restore is unrecovered', () {
      final report = NovelCharacterBoundaryHealth()
          .evaluate(<NovelCharacterBoundaryObservation>[
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.distinctNamespaces,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Novel and character archives use separate namespaces.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.referenceIntegrity,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Cross-workspace references resolve cleanly.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.overrideIsolation,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'No override crossed a workspace boundary.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.unlinkSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Unlink removed only the targeted link.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.deleteSafety,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Delete removed records from the sibling workspace.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.permissionBoundary,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Permission checks held at the workspace edge.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.restoreResults,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Restore rollback aborted mid-transaction.',
            ),
          ]);

      expect(report.state, NovelCharacterBoundaryState.fail);
      expect(report.violations, contains('delete_unrecovered'));
    });

    test('override leak past the permission boundary is uncontained', () {
      final report = NovelCharacterBoundaryHealth()
          .evaluate(<NovelCharacterBoundaryObservation>[
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.distinctNamespaces,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Novel and character archives use separate namespaces.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.referenceIntegrity,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Cross-workspace references resolve cleanly.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.overrideIsolation,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Character override wrote into novel content slots.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.unlinkSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Unlink removed only the targeted link.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.deleteSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Delete touched only its owning workspace.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.permissionBoundary,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Permission gate accepted the cross-workspace write.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.restoreResults,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'No restore required in window.',
            ),
          ]);

      expect(report.state, NovelCharacterBoundaryState.fail);
      expect(report.violations, contains('override_leak_uncontained'));
    });

    test('permission breach without successful restore is unrepaired', () {
      final report = NovelCharacterBoundaryHealth()
          .evaluate(<NovelCharacterBoundaryObservation>[
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.distinctNamespaces,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Novel and character archives use separate namespaces.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.referenceIntegrity,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Cross-workspace references resolve cleanly.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.overrideIsolation,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'No override crossed a workspace boundary.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.unlinkSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Unlink removed only the targeted link.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.deleteSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Delete touched only its owning workspace.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.permissionBoundary,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Permission gate accepted the cross-workspace write.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.restoreResults,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Restore rollback aborted mid-transaction.',
            ),
          ]);

      expect(report.state, NovelCharacterBoundaryState.fail);
      expect(report.violations, contains('permission_breach_unrepaired'));
    });

    test('detected boundary failures with honest restore recovers', () {
      final report = NovelCharacterBoundaryHealth()
          .evaluate(<NovelCharacterBoundaryObservation>[
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.distinctNamespaces,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Character export overwrote the novel namespace slot.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.referenceIntegrity,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Migration left cross-workspace references dangling.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.overrideIsolation,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'No override crossed a workspace boundary.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.unlinkSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Unlink removed only the targeted link.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.deleteSafety,
              outcome: NovelCharacterBoundaryOutcome.failed,
              note: 'Delete removed records from the sibling workspace.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.permissionBoundary,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Permission checks held at the workspace edge.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.restoreResults,
              outcome: NovelCharacterBoundaryOutcome.recovered,
              note:
                  'Restore repartitioned namespaces and rebuilt every '
                  'cross-workspace reference.',
            ),
          ]);

      expect(report.state, NovelCharacterBoundaryState.pass);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('fully covered consistent record verifies all seven signals', () {
      final report = NovelCharacterBoundaryHealth()
          .evaluate(<NovelCharacterBoundaryObservation>[
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.distinctNamespaces,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Novel and character archives use separate namespaces.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.referenceIntegrity,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Cross-workspace references resolve cleanly.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.overrideIsolation,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'No override crossed a workspace boundary.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.unlinkSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Unlink removed only the targeted link.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.deleteSafety,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Delete touched only its owning workspace.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.permissionBoundary,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'Permission checks held at the workspace edge.',
            ),
            const NovelCharacterBoundaryObservation(
              signal: NovelCharacterBoundarySignal.restoreResults,
              outcome: NovelCharacterBoundaryOutcome.ok,
              note: 'No restore required in window.',
            ),
          ]);

      expect(report.state, NovelCharacterBoundaryState.pass);
      expect(report.coveredSignals, <NovelCharacterBoundarySignal>[
        NovelCharacterBoundarySignal.distinctNamespaces,
        NovelCharacterBoundarySignal.referenceIntegrity,
        NovelCharacterBoundarySignal.overrideIsolation,
        NovelCharacterBoundarySignal.unlinkSafety,
        NovelCharacterBoundarySignal.deleteSafety,
        NovelCharacterBoundarySignal.permissionBoundary,
        NovelCharacterBoundarySignal.restoreResults,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_novel_character_boundary_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.13');
      expect(document['required_evidence'], <dynamic>[
        'distinct_namespaces',
        'reference_integrity',
        'override_isolation',
        'unlink_safety',
        'delete_safety',
        'permission_boundary',
        'restore_results',
      ]);
      expect(document['live_boundary_telemetry'], 'DEFERRED-EXTERNAL');
      expect(document['external_boundary_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}
