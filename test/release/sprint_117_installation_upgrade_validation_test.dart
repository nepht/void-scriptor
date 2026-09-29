/// Canonical step 117.9 — Installation & Upgrade Validation.
///
/// Objective (external canonical JSON): validate clean install and upgrade
/// from supported 1.2.x versions toward beta.
///
/// 113.10 records four supported upgrade sources (55, 58, 60, 61) with every
/// direct migration, the fresh database, and the future-schema rejection marked
/// PASS, and it records `settings_preserved: true`. It records nothing at all
/// about a credential vault.
///
/// A validation table that reads as complete in a review is exactly the
/// artifact this gate refuses to accept, so every check here is decided from
/// the shipped implementation or the filesystem, never from the prose:
///
/// * [Sprint117UpgradeDrill] really creates a database through
///   [ProjectDatabaseService.create], really rewinds it to each recorded source
///   version, really re-opens it through the production open path, and really
///   round-trips a package-resident settings row through a backup and restore.
/// * The rollback check really creates a pre-migration backup and really
///   restores it into a throwaway destination.
/// * The vault check reports the absence of a migration path instead of
///   inventing one.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_installation_upgrade_validation.dart';

void main() {
  const step = Sprint117UpgradeContract.canonicalStep;

  group('contract surface', () {
    test('covers the six canonical checks in canonical order', () {
      expect(Sprint117UpgradeContract.requiredChecks, <String>[
        'clean_install',
        'source_versions',
        'upgrade_results',
        'settings_migration',
        'vault_migration',
        'rollback',
      ]);
    });

    test('declares the canonical step as 117.9', () {
      expect(step, '117.9');
    });

    test('every source manifest it depends on is a committed file', () {
      for (final path in Sprint117UpgradeContract.sourceManifests) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'source manifest $path must exist to be a real source',
        );
      }
    });
  });

  group('live upgrade drill', () {
    late Sprint117UpgradeReport report;
    late Sprint117UpgradeDrillRun run;

    setUpAll(() async {
      // Run the shipped mechanisms first, then decide the committed record
      // with the measured drill folded in.
      run = await const Sprint117UpgradeDrill().run();
      report = const Sprint117UpgradeGate().evaluateWith(
        const Sprint117UpgradeLoader().loadWithDrill(run),
      );
    });

    test('reaches a decided verdict on the committed evidence', () {
      expect(
        report.state,
        Sprint117UpgradeState.pass,
        reason:
            'live violations=${report.violations} '
            'missing=${report.missingFields}',
      );
      expect(report.verdict, Sprint117UpgradeContract.passVerdict);
      expect(report.violations, isEmpty);
      expect(report.missingFields, isEmpty);
    });

    test('every canonical check is mapped exactly once', () {
      expect(report.unmappedChecks, isEmpty);
      for (final entry in report.checkCoverage.entries) {
        expect(entry.value, 1, reason: '${entry.key} must map 1:1');
      }
    });

    test('no check claims a live install or a real user upgrade', () {
      expect(report.liveInstallClaimed, isFalse);
      for (final check in report.checks) {
        expect(check.liveInstallResult, isFalse);
        expect(check.drilledAgainstLiveInstall, isFalse);
      }
    });

    test('clean install really creates a database at the current schema', () {
      final observation = run.observationFor('clean_install');
      expect(observation, isNotNull);
      expect(observation!.passed, isTrue);
      expect(observation.facts['created_schema_version'], 62);
      expect(observation.facts['reopen_schema_version'], 62);
      expect(observation.facts['reopen_was_no_op'], isTrue);
      expect(observation.facts['used_production_create_path'], isTrue);
    });

    test('every recorded source version is really older than current', () {
      final observation = run.observationFor('source_versions');
      expect(observation, isNotNull);
      expect(observation!.passed, isTrue);
      final versions = observation.facts['versions']! as List<Object?>;
      expect(versions, <int>[55, 58, 60, 61]);
      expect(observation.facts['current_schema_version'], 62);
      expect(observation.facts['all_older_than_current'], isTrue);
    });

    test('every recorded source version really migrates forward', () {
      final observation = run.observationFor('upgrade_results');
      expect(observation, isNotNull);
      expect(observation!.passed, isTrue);
      final detail = observation.facts['per_version']! as Map<Object?, Object?>;
      expect(detail.keys.toSet(), <String>{'55', '58', '60', '61'});
      for (final entry in detail.entries) {
        final row = entry.value! as Map<Object?, Object?>;
        expect(
          row['reached_current'],
          isTrue,
          reason: 'v${entry.key} did not migrate to current',
        );
        expect(row['core_rows_preserved'], isTrue);
        expect(row['dropped_objects_applied'], isTrue);
      }
      // 113.10 records a future-schema rejection; the drill proves it.
      expect(observation.facts['future_schema_rejected'], isTrue);
    });

    test('package-resident settings really round-trip through a backup', () {
      final observation = run.observationFor('settings_migration');
      expect(observation, isNotNull);
      expect(observation!.passed, isTrue);
      expect(observation.facts['security_settings_preserved'], isTrue);
      expect(observation.facts['manifest_preserved'], isTrue);
      expect(observation.facts['kdf_iterations_preserved'], isTrue);
    });

    test(
      'settings stored outside the package are reported as not migrated',
      () {
        final observation = run.observationFor('settings_migration');
        expect(observation!.passed, isTrue);
        expect(observation.facts['package_copies_appearance_store'], isFalse);
        expect(
          observation.facts['unresolvable'],
          contains('appearance_store_outside_project_package'),
        );
      },
    );

    test(
      'vault round-trips through the real store over its real key scheme',
      () async {
        final observation = run.observationFor('vault_migration');
        expect(observation, isNotNull);
        expect(observation!.passed, isTrue);
        expect(observation.facts['round_trip_read_back'], isTrue);
        expect(observation.facts['audit_carried_secret'], isFalse);
        expect(observation.facts['legacy_key_picked_up'], isFalse);
      },
    );

    test('the absent vault migration path is reported, not invented', () {
      final observation = run.observationFor('vault_migration');
      expect(observation!.facts['migration_mechanism_present'], isFalse);
      expect(
        observation.facts['unresolvable'],
        contains('vault_migration_mechanism_absent'),
      );
      expect(
        report.openItems,
        contains('unresolvable_reference:vault_migration_mechanism_absent'),
      );
    });

    test('rollback really restores a pre-migration backup', () {
      final observation = run.observationFor('rollback');
      expect(observation, isNotNull);
      expect(observation!.passed, isTrue);
      expect(observation.facts['pre_migration_backup_created'], isTrue);
      expect(observation.facts['restored_to_alternate_destination'], isTrue);
      expect(observation.facts['live_package_untouched'], isTrue);
      expect(observation.facts['restored_schema_version'], 62);
    });

    test('the drill touched no user project and no live credential store', () {
      expect(run.liveInstallTouched, isFalse);
      expect(run.userProjectTouched, isFalse);
      expect(run.liveSecretsObserved, isEmpty);
    });

    test('every drill observation passed', () {
      expect(run.allPassed, isTrue);
      for (final observation in run.observations) {
        expect(
          observation.passed,
          isTrue,
          reason: '${observation.checkId} facts=${observation.facts}',
        );
      }
    });
  });

  group('fail-closed gate', () {
    test('a missing anchor blocks instead of deciding an empty claim', () {
      final report = const Sprint117UpgradeGate().evaluateWith(
        const Sprint117UpgradeInput(rows: null, anchor: null, drillRun: null),
      );
      expect(report.state, Sprint117UpgradeState.blocked);
      expect(report.missingFields, contains('upgrade_anchor'));
      expect(report.missingFields, contains('check_rows'));
      expect(report.unmappedChecks, Sprint117UpgradeContract.requiredChecks);
    });

    test('a live install claim is a violation, never an open item', () {
      const loader = Sprint117UpgradeLoader();
      final rows = loader
          .load()
          .rows!
          .map(
            (row) => Sprint117UpgradeCheck(
              checkId: row.checkId,
              method: row.method,
              expectedOutcome: row.expectedOutcome,
              observedOutcome: row.observedOutcome,
              sourceManifest: row.sourceManifest,
              liveInstallResult: row.checkId == 'clean_install',
              drilledAgainstLiveInstall: false,
            ),
          )
          .toList(growable: false);
      final report = const Sprint117UpgradeGate().evaluateWith(
        Sprint117UpgradeInput(
          rows: rows,
          anchor: loader.load().anchor,
          drillRun: null,
        ),
      );
      expect(report.state, Sprint117UpgradeState.fail);
      expect(
        report.violations,
        contains('check_live_install_claim:clean_install'),
      );
    });

    test('every check stays undetermined and open, never violated', () {
      // No machine has ever installed an upgrade from these source versions, so
      // no check carries an observed outcome. That is the honest state for all
      // six, and it belongs in openItems rather than in violations.
      final report = const Sprint117UpgradeGate().evaluate();
      expect(report.state, Sprint117UpgradeState.pass);
      expect(report.violations, isEmpty);
      expect(
        report.undeterminedChecks,
        Sprint117UpgradeContract.requiredChecks,
      );
      for (final checkId in Sprint117UpgradeContract.requiredChecks) {
        expect(
          report.openItems,
          contains('check_observed_outcome_null:$checkId'),
        );
      }
      expect(report.openItems, contains('install_defined_not_executed'));
    });
  });
}
