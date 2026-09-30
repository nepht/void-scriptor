/// Canonical step 117.10 — Account Configuration Migration.
///
/// Objective (external canonical JSON): validate identity, provider configs,
/// secret references, storage settings, team, and billing metadata migration.
///
/// The six acceptance names read like a table of durable account state that
/// survives an upgrade. Nothing in the shipped code backs that reading, so the
/// check and the drill are deliberately separate classes:
///
/// * [Sprint117AccountConfigDrill] really writes and re-reads the two stores
///   that actually persist on this machine — the OS secure credential store
///   through the production vault key scheme, and the machine-local
///   `storage_locations.json` registry through [CustomStorageLocationStore].
///   It also really round-trips a provider connector manifest through its own
///   `toJson`/`fromJsonString`, and really scans every serialized account
///   surface for a live secret.
/// * [Sprint117AccountConfigLoader] reads the committed manifests and never
///   invents a check, a subject, or an owner.
/// * [Sprint117AccountConfigGate] decides whether the recorded evidence is
///   coherent, synchronously and without side effects.
///
/// The 117.5–117.9 distinction carries over unchanged. A check no drill has
/// ever executed is *undetermined* — an open item — while a check that is
/// executed and then contradicted is a violation. The identity, team, and
/// billing checks are executed, and they pass by *reporting that the subject
/// has no persistence seam at all* rather than by proving a migration works:
/// `LinkedIdentity`, `AccountCenterTeamCollaborationSummary`, and
/// `AccountCenterBillingSummary` are plain in-memory value types with no
/// `toJson`, no `fromJson`, and no consumer outside their own test file. There
/// is no account migration to validate because there is no account store.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_account_configuration_migration.dart';

void main() {
  const step = Sprint117AccountConfigContract.canonicalStep;

  group('contract surface', () {
    test('covers the six canonical checks in canonical order', () {
      expect(Sprint117AccountConfigContract.requiredChecks, <String>[
        'identity_preserved',
        'secret_refs_preserved',
        'no_secret_export',
        'storage_settings',
        'team_metadata',
        'billing_metadata',
      ]);
    });

    test('declares the canonical step as 117.10', () {
      expect(step, '117.10');
    });

    test('every source manifest it depends on is a committed file', () {
      for (final path in Sprint117AccountConfigContract.sourceManifests) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'source manifest $path must exist to be a real source',
        );
      }
    });
  });

  group('drill', () {
    late Sprint117AccountConfigDrillRun run;

    setUpAll(() async {
      run = await const Sprint117AccountConfigDrill().run();
    });

    test('produces exactly one observation per canonical check', () {
      expect(
        run.observations.map((observation) => observation.checkId).toList(),
        Sprint117AccountConfigContract.requiredChecks,
      );
    });

    test('every observation passes', () {
      expect(
        run.allPassed,
        isTrue,
        reason: 'a failing observation names the local mechanism that broke',
      );
    });

    test('never touches a live install, a user project, or a live secret', () {
      expect(run.liveInstallTouched, isFalse);
      expect(run.userProjectTouched, isFalse);
      expect(run.liveSecretsObserved, isEmpty);
    });

    test('identity check reports the absent persistence seam, not a pass '
        'on an invented migration', () {
      final observation = run.observationFor('identity_preserved')!;
      expect(observation.passed, isTrue);
      expect(observation.facts['linked_identity_serializable'], isFalse);
      expect(observation.facts['identity_store_present'], isFalse);
      expect(
        observation.unresolvable,
        contains('account_identity_store_absent'),
      );
    });

    test('secret reference check round-trips the real vault key scheme', () {
      final observation = run.observationFor('secret_refs_preserved')!;
      expect(observation.passed, isTrue);
      expect(observation.facts['secret_keys_readable'], isTrue);
      expect(
        observation.facts['vault_key_scheme'],
        'account/<id>/<kind>[/<secretId>]',
      );
      expect(observation.facts['legacy_vault_key_picked_up'], isFalse);
      expect(
        observation.unresolvable,
        contains('vault_migration_mechanism_absent'),
      );
    });

    test('no-secret-export check finds no live secret in any serializable '
        'account surface', () {
      final observation = run.observationFor('no_secret_export')!;
      expect(observation.passed, isTrue);
      expect(observation.facts['secret_pattern_hits'], 0);
      expect(observation.facts['surfaces_scanned']! as int, greaterThan(0));
      expect(observation.facts['redaction_round_trips'], isTrue);
    });

    test('storage check really persists and re-reads the machine registry', () {
      final observation = run.observationFor('storage_settings')!;
      expect(observation.passed, isTrue);
      expect(observation.facts['active_location_persisted'], isTrue);
      expect(observation.facts['bound_project_persisted'], isTrue);
      expect(observation.facts['schema_version_persisted'], isTrue);
      expect(observation.facts['reopen_matches'], isTrue);
      expect(observation.facts['registry_inside_project_package'], isFalse);
      expect(
        observation.unresolvable,
        contains('storage_registry_outside_project_package'),
      );
    });

    test('team and billing checks report the absent store rather than '
        'claiming a metadata migration', () {
      final team = run.observationFor('team_metadata')!;
      expect(team.passed, isTrue);
      expect(team.facts['team_summary_serializable'], isFalse);
      expect(team.unresolvable, contains('team_metadata_store_absent'));

      final billing = run.observationFor('billing_metadata')!;
      expect(billing.passed, isTrue);
      expect(billing.facts['billing_summary_serializable'], isFalse);
      expect(billing.unresolvable, contains('billing_metadata_store_absent'));
    });

    test('records the exact spelling of every unresolved reference', () {
      expect(run.unresolvableReferences, <String>[
        'account_identity_store_absent',
        'billing_metadata_store_absent',
        'storage_registry_outside_project_package',
        'team_metadata_store_absent',
        'vault_migration_mechanism_absent',
      ]);
    });

    test(
      'every open item uses the 117.5-117.9 decided-vs-coherent spelling',
      () {
        final run_ = run;
        for (final observation in run_.observations) {
          for (final reference in observation.unresolvable) {
            expect(
              reference,
              matches(RegExp(r'^[a-z0-9_]+$')),
              reason: 'unresolvable references stay a flat exact token',
            );
          }
        }
      },
    );

    test('separates acceptances shipped code can satisfy from the ones it '
        'cannot, so full coverage never reads as six green rows', () {
      // Three subjects have no mechanism at all. Reporting all six as
      // satisfied would be the fabricated table this gate exists to refuse.
      expect(run.acceptanceSatisfied, <String>[
        'no_secret_export',
        'secret_refs_preserved',
        'storage_settings',
      ]);
      expect(run.acceptanceUnmet, <String>[
        'billing_metadata',
        'identity_preserved',
        'team_metadata',
      ]);
      for (final checkId in run.acceptanceUnmet) {
        expect(
          run.observationFor(checkId)!.passed,
          isTrue,
          reason: 'an absent mechanism is measured cleanly, not a defect',
        );
      }
    });

    test('serializes to JSON with string keys everywhere', () {
      final encoded = jsonEncode(run.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['all_passed'], isTrue);
      expect(
        (decoded['observations'] as List<dynamic>).length,
        Sprint117AccountConfigContract.requiredChecks.length,
      );
    });
  });

  group('gate', () {
    late Sprint117AccountConfigDrillRun drill;

    setUpAll(() async {
      drill = await const Sprint117AccountConfigDrill().run();
    });

    test('passes on the measured drill run', () async {
      final report = await const Sprint117AccountConfigGate().evaluateWithDrill(
        drill,
      );
      expect(report.status, Sprint117AccountConfigState.pass);
      expect(report.verdict, 'ACCOUNT_CONFIGURATION_MIGRATION_VALIDATED_LOCAL');
      expect(report.violations, isEmpty);
      expect(report.missingFields, isEmpty);
      expect(report.unmappedChecks, isEmpty);
      expect(report.coverage, 1);
      expect(report.undeterminedChecks, isEmpty);
      // Coverage is decision, not satisfaction: the report must still name the
      // three rows no shipped mechanism can satisfy.
      expect(report.acceptanceSatisfied, <String>[
        'no_secret_export',
        'secret_refs_preserved',
        'storage_settings',
      ]);
      expect(report.acceptanceUnmet, <String>[
        'billing_metadata',
        'identity_preserved',
        'team_metadata',
      ]);
      expect(
        report.openItems,
        contains('check_acceptance_unmet:identity_preserved'),
      );
      expect(
        report.openItems,
        contains('check_acceptance_unmet:team_metadata'),
      );
      expect(
        report.openItems,
        contains('check_acceptance_unmet:billing_metadata'),
      );
    });

    test('blocks when no drill has ever run', () {
      final report = const Sprint117AccountConfigGate().evaluate();
      expect(report.status, Sprint117AccountConfigState.blocked);
      expect(
        report.verdict,
        'ACCOUNT_CONFIGURATION_MIGRATION_BLOCKED_NO_LOCAL_EVIDENCE',
      );
      expect(report.missingFields, contains('drill_run'));
      expect(report.coverage, 0);
      // Nothing has been decided, so nothing may read as satisfied either.
      expect(report.acceptanceSatisfied, isEmpty);
      expect(report.acceptanceUnmet, isEmpty);
    });

    test('refuses a check whose observed outcome contradicts the drill', () {
      final rows = const Sprint117AccountConfigLoader()
          .loadWithDrill(drill)
          .rows!;
      final tampered = <Sprint117AccountConfigCheck>[
        for (final row in rows)
          if (row.checkId == 'storage_settings')
            Sprint117AccountConfigCheck(
              checkId: row.checkId,
              method: row.method,
              expectedOutcome: row.expectedOutcome,
              observedOutcome: 'storage_registry_migrated',
              sourceManifest: row.sourceManifest,
              liveInstallResult: false,
              drilledAgainstLiveInstall: false,
            )
          else
            row,
      ];
      final report = const Sprint117AccountConfigGate().evaluateWith(
        Sprint117AccountConfigInput(rows: tampered, drillRun: drill),
      );
      expect(report.status, Sprint117AccountConfigState.fail);
      expect(
        report.violations,
        contains('check_outcome_contradicts_drill:storage_settings'),
      );
    });

    test('refuses a claim that a vault migration mechanism exists', () {
      final rows = const Sprint117AccountConfigLoader()
          .loadWithDrill(drill)
          .rows!;
      final report = const Sprint117AccountConfigGate().evaluateWith(
        Sprint117AccountConfigInput(
          rows: rows,
          drillRun: drill,
          vaultMigrationRecorded: true,
        ),
      );
      expect(report.status, Sprint117AccountConfigState.fail);
      expect(
        report.violations,
        contains('vault_migration_claimed_without_mechanism'),
      );
    });

    test('refuses a secret observed by a drill that claims no secrets', () {
      final rows = const Sprint117AccountConfigLoader()
          .loadWithDrill(drill)
          .rows!;
      final leaky = Sprint117AccountConfigDrillRun(
        observations: drill.observations,
        liveInstallTouched: false,
        userProjectTouched: false,
        liveSecretsObserved: const <String>['drill-secret'],
      );
      final report = const Sprint117AccountConfigGate().evaluateWith(
        Sprint117AccountConfigInput(rows: rows, drillRun: leaky),
      );
      expect(report.status, Sprint117AccountConfigState.fail);
      expect(report.violations, contains('live_secret_observed'));
    });

    test('refuses an account store that appeared without a migration path', () {
      final report = const Sprint117AccountConfigGate().evaluateWith(
        Sprint117AccountConfigInput(
          rows: const Sprint117AccountConfigLoader().loadWithDrill(drill).rows,
          drillRun: drill,
          accountStoreRecorded: true,
        ),
      );
      expect(report.status, Sprint117AccountConfigState.fail);
      expect(
        report.violations,
        contains('account_store_claimed_without_migration_path'),
      );
    });
  });
}
