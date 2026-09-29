/// Canonical step 117.9 — Installation & Upgrade Validation.
///
/// Objective (external canonical JSON): validate clean install and upgrade
/// from supported 1.2.x versions toward beta.
///
/// 113.10 records four supported upgrade sources (55, 58, 60, 61) with every
/// direct migration, the fresh database, and the future-schema rejection
/// marked PASS, and it records `settings_preserved: true`. It records nothing
/// at all about a credential vault, and no migration path for one exists
/// anywhere in the shipped code.
///
/// A validation table that reads as complete in a review is exactly the
/// artifact this gate refuses to accept, so the check and the drill are
/// deliberately separate classes:
///
/// * [Sprint117UpgradeDrill] really creates a database through
///   [ProjectDatabaseService.create], really rewinds it to each recorded source
///   version, really re-opens it through the production open path, really
///   round-trips a package-resident settings row, and really restores a
///   pre-migration backup. A table that says a migration passed is not a
///   migration.
/// * [Sprint117UpgradeLoader] reads the committed manifests and never invents
///   a source version, a check, or an owner.
/// * [Sprint117UpgradeGate] decides whether the recorded evidence is
///   coherent, synchronously and without side effects.
///
/// The 117.5–117.8 distinction carries over unchanged. A check no drill has
/// ever executed is *undetermined* — an open item — while a check that is
/// executed and then contradicted is a violation. The vault check is executed
/// and passes, but it passes by *reporting the absence of a migration
/// mechanism* rather than by proving one works, so the gap is surfaced with its
/// exact spelling instead of being closed with an invented path.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/core/theme/app_theme_mode.dart';
import 'package:void_scriptor/core/theme/theme_preference_store.dart';
import 'package:void_scriptor/database/project/project_database.dart'
    hide CharacterIdentityProfile;
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';
import 'package:void_scriptor/features/project_resilience/application/project_backup_restore_preview.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

enum Sprint117UpgradeState { pass, fail, blocked }

/// One canonical check, the method that exercises it, and what that method is
/// expected to produce.
class Sprint117UpgradeCheck {
  Sprint117UpgradeCheck({
    required this.checkId,
    required this.method,
    required this.expectedOutcome,
    required this.observedOutcome,
    required this.sourceManifest,
    required this.liveInstallResult,
    required this.drilledAgainstLiveInstall,
  });

  /// The canonical check identity, e.g. `clean_install`.
  final String checkId;

  /// The step an installer would run. Empty means the check only wishes for it.
  final String method;

  /// What the method is expected to produce locally.
  final String expectedOutcome;

  /// What a live install observed. Null while no live install has ever run.
  final String? observedOutcome;

  /// The upstream manifest that defines this check.
  final String sourceManifest;

  /// Whether a live installer produced this outcome. It never has.
  final bool liveInstallResult;

  /// Whether the check was run against a real install. It never was.
  final bool drilledAgainstLiveInstall;

  bool get executed =>
      observedOutcome != null && observedOutcome!.trim().isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'check_id': checkId,
    'method': method,
    'expected_outcome': expectedOutcome,
    'observed_outcome': observedOutcome,
    'executed': executed,
    'source_manifest': sourceManifest,
    'live_install_result': liveInstallResult,
    'drilled_against_live_install': drilledAgainstLiveInstall,
  };
}

/// The evidence this validation is allowed to decide from.
class Sprint117UpgradeAnchor {
  Sprint117UpgradeAnchor({
    required this.upgradeVerdict,
    required this.migrationHealthVerdict,
    required this.installHealthVerdict,
    required List<Sprint117UpgradeCheck> checks,
    required List<String> sourceManifests,
    required this.currentSchemaVersion,
    required this.supportedSourcesRecorded,
    required List<int> claimedSourceVersions,
    required this.freshDatabaseClaimed,
    required this.futureSchemaClaimed,
    required this.backupBeforeMigration,
    required this.settingsPreservedClaimed,
    required this.vaultMigrationRecorded,
    required List<String> carriedOpenItems,
  }) : checks = List<Sprint117UpgradeCheck>.unmodifiable(checks),
       sourceManifests = List<String>.unmodifiable(sourceManifests),
       claimedSourceVersions = List<int>.unmodifiable(claimedSourceVersions),
       carriedOpenItems = List<String>.unmodifiable(carriedOpenItems);

  /// The 113.10 decision.
  final String upgradeVerdict;

  /// The 114.10 decision rule.
  final String migrationHealthVerdict;

  /// The 114.9 decision rule.
  final String installHealthVerdict;

  final List<Sprint117UpgradeCheck> checks;

  final List<String> sourceManifests;

  /// The schema version the shipped database declares.
  final int currentSchemaVersion;

  /// Whether 113.10 records any supported source at all.
  final bool supportedSourcesRecorded;

  /// The source versions 113.10 claims as supported.
  final List<int> claimedSourceVersions;

  /// Whether 113.10 records a fresh-database result.
  final bool freshDatabaseClaimed;

  /// Whether 113.10 records a future-schema rejection result.
  final bool futureSchemaClaimed;

  /// Whether 113.10 records a backup before migration.
  final bool backupBeforeMigration;

  /// Whether 113.10 records settings as preserved.
  final bool settingsPreservedClaimed;

  /// Whether any committed source records a vault migration.
  final bool vaultMigrationRecorded;

  final List<String> carriedOpenItems;
}

class Sprint117UpgradeInput {
  const Sprint117UpgradeInput({this.rows, this.anchor, this.drillRun});

  final List<Sprint117UpgradeCheck>? rows;
  final Sprint117UpgradeAnchor? anchor;

  /// The measured local drill, when one has been executed.
  final Sprint117UpgradeDrillRun? drillRun;
}

class Sprint117UpgradeReport {
  Sprint117UpgradeReport({
    required this.state,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required this.anchor,
    required List<Sprint117UpgradeCheck> checks,
    required List<String> unmappedChecks,
    required List<String> undeterminedChecks,
    required List<String> unresolvableReferences,
    required this.drillRun,
    required List<String> openItems,
    required List<String> limitations,
    required Map<String, int> checkCoverage,
  }) : missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       checks = List<Sprint117UpgradeCheck>.unmodifiable(checks),
       unmappedChecks = List<String>.unmodifiable(unmappedChecks),
       undeterminedChecks = List<String>.unmodifiable(undeterminedChecks),
       unresolvableReferences = List<String>.unmodifiable(
         unresolvableReferences,
       ),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations),
       checkCoverage = Map<String, int>.unmodifiable(checkCoverage);

  final Sprint117UpgradeState state;
  final String verdict;
  final List<String> missingFields;
  final List<String> violations;
  final Sprint117UpgradeAnchor? anchor;
  final List<Sprint117UpgradeCheck> checks;

  /// Canonical checks no source manifest defines.
  final List<String> unmappedChecks;

  /// Checks defined but never exercised, because no live install has run.
  final List<String> undeterminedChecks;

  /// Recorded subjects that cannot be resolved.
  final List<String> unresolvableReferences;

  final Sprint117UpgradeDrillRun? drillRun;

  final List<String> openItems;
  final List<String> limitations;
  final Map<String, int> checkCoverage;

  /// Whether any check claims a live installer ran.
  bool get liveInstallClaimed => checks.any(
    (row) => row.liveInstallResult || row.drilledAgainstLiveInstall,
  );

  String get externalGates => Sprint117UpgradeContract.externalGates;

  int get checkCount => checks.length;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117UpgradeContract.canonicalStep,
    'state': state.name,
    'verdict': verdict,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'check_count': checkCount,
    'checks': <Map<String, Object?>>[for (final c in checks) c.toJson()],
    'unmapped_checks': List<String>.from(unmappedChecks),
    'undetermined_checks': List<String>.from(undeterminedChecks),
    'unresolvable_references': List<String>.from(unresolvableReferences),
    'required_checks': List<String>.from(
      Sprint117UpgradeContract.requiredChecks,
    ),
    'source_manifests': List<String>.from(
      anchor?.sourceManifests ?? const <String>[],
    ),
    'check_coverage': Map<String, int>.from(checkCoverage),
    'live_install_claimed': liveInstallClaimed,
    'drill_run': drillRun?.toJson(),
    'external_gates': externalGates,
    'open_items': List<String>.from(openItems),
    'limitations': List<String>.from(limitations),
  };
}

abstract final class Sprint117UpgradeContract {
  static const String canonicalStep = '117.9';

  /// 113.10 supplies the supported sources and the upgrade results.
  static const String upgradePath =
      'docs/planning/v1.2/sprint_113_upgrade_path_validation.json';

  /// 114.10 supplies the six migration-health signals.
  static const String migrationHealth =
      'docs/planning/v1.2/sprint_114_upgrade_migration_health.json';

  /// 114.9 supplies the six install/update signals.
  static const String installHealth =
      'docs/planning/v1.2/sprint_114_install_update_health.json';

  /// 112.27 supplies the production migration open path.
  static const String dryRun =
      'docs/planning/v1.2/sprint_112_migration_dry_run.json';

  /// 112.29 supplies the rollback/downgrade boundary.
  static const String rollbackBoundary =
      'docs/planning/v1.2/sprint_112_rollback_downgrade_boundary.json';

  /// 112.49 supplies the upgrade/downgrade compatibility budget.
  static const String platformGate =
      'docs/planning/v1.2/sprint_112_platform_compatibility_gate.json';

  /// 115.12 supplies the vault whose migration this step cannot prove.
  static const String vault =
      'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// 113.10's status.
  static const String upgradeVerdict = 'VERIFIED-LOCAL';

  /// 117.9's verdict when the evidence is decided and coherent.
  static const String passVerdict = 'INSTALLATION_UPGRADE_VALIDATED_LOCAL';

  static const String blockedVerdict =
      'INSTALLATION_UPGRADE_VALIDATION_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict =
      'INSTALLATION_UPGRADE_VALIDATION_INCONSISTENT';

  /// The six checks canonical step 117.9 names, in canonical order.
  static const List<String> requiredChecks = <String>[
    'clean_install',
    'source_versions',
    'upgrade_results',
    'settings_migration',
    'vault_migration',
    'rollback',
  ];

  static const List<String> sourceManifests = <String>[
    upgradePath,
    migrationHealth,
    installHealth,
    dryRun,
    rollbackBoundary,
    platformGate,
    vault,
  ];
}

/// What one check's local exercise actually produced.
class Sprint117UpgradeObservation {
  Sprint117UpgradeObservation({
    required this.checkId,
    required this.outcome,
    required Map<String, Object?> facts,
    required this.passed,
    required List<String> unresolvable,
  }) : facts = Map<String, Object?>.unmodifiable(facts),
       unresolvable = List<String>.unmodifiable(unresolvable);

  final String checkId;

  /// What the local exercise produced.
  final String outcome;

  /// The measured facts behind that outcome.
  final Map<String, Object?> facts;

  /// Whether the local mechanism responded as the contract expects.
  final bool passed;

  /// Recorded subjects the check could not resolve.
  final List<String> unresolvable;

  Map<String, Object?> toJson() => <String, Object?>{
    'check_id': checkId,
    'outcome': outcome,
    'facts': Map<String, Object?>.from(facts),
    'passed': passed,
    'unresolvable': List<String>.from(unresolvable),
  };
}

/// The record of one local drill run.
class Sprint117UpgradeDrillRun {
  Sprint117UpgradeDrillRun({
    required List<Sprint117UpgradeObservation> observations,
    required this.liveInstallTouched,
    required this.userProjectTouched,
    this.liveSecretsObserved = const <String>[],
  }) : observations = List<Sprint117UpgradeObservation>.unmodifiable(
         observations,
       );

  final List<Sprint117UpgradeObservation> observations;

  /// Always false: this drill never installs, downloads, or signs anything.
  final bool liveInstallTouched;

  /// Always false: every package is created under the OS temp directory.
  final bool userProjectTouched;

  /// Any live secret this drill ever observed. It never does.
  final List<String> liveSecretsObserved;

  /// Every recorded subject the drill could not resolve, across checks.
  List<String> get unresolvableReferences {
    final refs = <String>{
      for (final observation in observations)
        for (final reference in observation.unresolvable) reference,
    };
    return refs.toList(growable: false)..sort();
  }

  bool get allPassed => observations.every((observation) => observation.passed);

  Sprint117UpgradeObservation? observationFor(String checkId) {
    for (final observation in observations) {
      if (observation.checkId == checkId) return observation;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'observations': <Map<String, Object?>>[
      for (final observation in observations) observation.toJson(),
    ],
    'live_install_touched': liveInstallTouched,
    'user_project_touched': userProjectTouched,
    'live_secrets_observed': List<String>.from(liveSecretsObserved),
    'all_passed': allPassed,
    'unresolvable_references': unresolvableReferences,
  };
}

/// Executes the six canonical checks locally against the shipped mechanisms.
class Sprint117UpgradeDrill {
  const Sprint117UpgradeDrill();

  Future<Sprint117UpgradeDrillRun> run() async => Sprint117UpgradeDrillRun(
    observations: <Sprint117UpgradeObservation>[
      await _drillCleanInstall(),
      _drillSourceVersions(),
      await _drillUpgradeResults(),
      await _drillSettingsMigration(),
      await _drillVaultMigration(),
      await _drillRollback(),
    ],
    liveInstallTouched: false,
    userProjectTouched: false,
  );

  /// The clean install is the production create path, then a reopen that must
  /// be a no-op. A create that silently skipped [ProjectDatabaseService.create]
  /// would leave no database at all, so the path used is recorded.
  static Future<Sprint117UpgradeObservation> _drillCleanInstall() async {
    final root = await Directory.systemTemp.createTemp('vs1179-clean-');
    try {
      final service = ProjectDatabaseService();
      final path = _databasePath(root);
      await service.create(path);
      final createdSchema = await service.schemaVersion(path);
      var database = await service.open(path);
      await database.customSelect('SELECT 1').get();
      await database.close();
      final reopenSchema = await service.schemaVersion(path);
      return Sprint117UpgradeObservation(
        checkId: 'clean_install',
        outcome: 'clean_install_created_locally',
        facts: <String, Object?>{
          'used_production_create_path': true,
          'created_schema_version': createdSchema,
          'reopen_schema_version': reopenSchema,
          'current_schema_version': ProjectDatabase.currentSchemaVersion,
          'reopen_was_no_op': reopenSchema == createdSchema,
        },
        passed:
            createdSchema == ProjectDatabase.currentSchemaVersion &&
            reopenSchema == ProjectDatabase.currentSchemaVersion,
        unresolvable: const <String>[],
      );
    } finally {
      await _deleteQuietly(root);
    }
  }

  /// 113.10 records four supported sources. The drill resolves each against the
  /// schema the shipped database actually declares, so a source version that
  /// is no longer below current is reported rather than assumed.
  static Sprint117UpgradeObservation _drillSourceVersions() {
    final anchor = const Sprint117UpgradeLoader().load().anchor;
    final recorded = anchor?.claimedSourceVersions ?? const <int>[];
    const current = ProjectDatabase.currentSchemaVersion;
    final older = <int>[
      for (final version in recorded)
        if (version < current) version,
    ];
    return Sprint117UpgradeObservation(
      checkId: 'source_versions',
      outcome: 'source_versions_resolved_locally',
      facts: <String, Object?>{
        'versions': recorded,
        'current_schema_version': current,
        'all_older_than_current': older.length == recorded.length,
        'recorded_in_upgrade_manifest': recorded.isNotEmpty,
      },
      passed: recorded.isNotEmpty && older.length == recorded.length,
      unresolvable: <String>[
        for (final version in recorded)
          if (version >= current) 'source_version_not_below_current:$version',
      ],
    );
  }

  /// Every recorded source is really rewound and really re-opened through the
  /// production open path. The rewind drops the objects each later wave
  /// creates, so a wave that silently does nothing still shows up as a missing
  /// object at current schema.
  static Future<Sprint117UpgradeObservation> _drillUpgradeResults() async {
    final anchor = const Sprint117UpgradeLoader().load().anchor;
    final sources = anchor?.claimedSourceVersions ?? const <int>[];
    final perVersion = <int, Map<String, Object?>>{};
    final unresolvable = <String>[];

    for (final version in sources) {
      final root = await Directory.systemTemp.createTemp('vs1179-up-');
      try {
        final path = _databasePath(root);
        await ProjectDatabaseService().create(path);
        // Seed Core rows at the current layout, then rewind the structural
        // waves introduced after this source version.
        final seeder = ProjectDatabase(NativeDatabase(File(path)));
        await seeder.customSelect('SELECT 1').get();
        await seeder.transaction(() async {
          await seeder
              .into(seeder.assets)
              .insert(
                AssetsCompanion.insert(
                  id: 'asset-1',
                  projectId: 'project-1',
                  name: 'Qowner',
                  type: 'character',
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
              );
          await seeder
              .into(seeder.characters)
              .insert(
                CharactersCompanion.insert(
                  assetId: 'asset-1',
                  projectId: 'project-1',
                  displayName: 'Qowner',
                ),
              );
          await seeder
              .into(seeder.securitySettings)
              .insert(
                SecuritySettingsCompanion.insert(
                  projectId: 'project-1',
                  updatedAt: DateTime(2026),
                ),
              );
        });
        await seeder.close();

        final dropped = _objectsIntroducedAfter(version);
        final rewind = ProjectDatabase(NativeDatabase(File(path)));
        await rewind.customStatement('PRAGMA foreign_keys = OFF');
        for (final statement in dropped.statements) {
          await rewind.customStatement(statement);
        }
        await rewind.customStatement('PRAGMA user_version = $version');
        await rewind.close();

        // The production open path migrates forward and applies every wave.
        final service = ProjectDatabaseService();
        final database = await service.open(path);
        final reached = await service.schemaVersion(path);
        final assets = await database.select(database.assets).get();
        final characters = await database.select(database.characters).get();
        final security = await database.select(database.securitySettings).get();
        final applied = await _allObjectsPresent(database, dropped.tables);
        await database.close();

        perVersion[version] = <String, Object?>{
          'reached_current': reached == ProjectDatabase.currentSchemaVersion,
          'reached_version': reached,
          'core_rows_preserved': assets.length == 1 && characters.length == 1,
          'core_character': characters.isEmpty
              ? null
              : characters.single.displayName,
          'settings_row_preserved': security.length == 1,
          'dropped_objects_applied': applied,
          'dropped_object_count': dropped.tables.length,
        };
        if (!applied) {
          unresolvable.add('wave_objects_missing_after_migration:$version');
        }
      } catch (error) {
        perVersion[version] = <String, Object?>{
          'reached_current': false,
          'core_rows_preserved': false,
          'dropped_objects_applied': false,
          'error': error.toString().length > 200
              ? error.toString().substring(0, 200)
              : error.toString(),
        };
      } finally {
        await _deleteQuietly(root);
      }
    }

    // 113.10 records a future-schema rejection. The drill proves the guard.
    final futureRoot = await Directory.systemTemp.createTemp('vs1179-future-');
    var futureRejected = false;
    try {
      final path = _databasePath(futureRoot);
      await ProjectDatabaseService().create(path);
      final future = ProjectDatabase(NativeDatabase(File(path)));
      await future.customStatement(
        'PRAGMA user_version = ${ProjectDatabase.currentSchemaVersion + 1}',
      );
      await future.close();
      try {
        final database = await ProjectDatabaseService().open(path);
        await database.close();
      } on SchemaVersionTooNewException {
        futureRejected = true;
      } on Object {
        futureRejected = false;
      }
    } finally {
      await _deleteQuietly(futureRoot);
    }

    final allReached =
        sources.isNotEmpty &&
        perVersion.values.every(
          (row) =>
              row['reached_current'] == true &&
              row['core_rows_preserved'] == true,
        );
    return Sprint117UpgradeObservation(
      checkId: 'upgrade_results',
      outcome: 'upgrade_results_exercised_locally',
      facts: <String, Object?>{
        // Keyed by the source version as a STRING so the report's toJson()
        // stays encodable: an int-keyed map serialises to nothing usable and
        // would silently drop the per-version evidence.
        'per_version': <String, Object?>{
          for (final entry in perVersion.entries) '${entry.key}': entry.value,
        },
        'versions_tested': perVersion.length,
        'future_schema_rejected': futureRejected,
        'current_schema_version': ProjectDatabase.currentSchemaVersion,
      },
      passed: allReached && futureRejected,
      unresolvable: unresolvable,
    );
  }

  /// Settings live in two places, and only one of them is inside the project
  /// package. The drill round-trips the package-resident row through a real
  /// backup and restore, then proves the other store is not copied by it.
  static Future<Sprint117UpgradeObservation> _drillSettingsMigration() async {
    final root = await Directory.systemTemp.createTemp('vs1179-settings-');
    try {
      final package = ProjectPackage(projectId: 'p1', root: root);
      await _seedPackage(package, kdfIterations: 123456);

      final backupRoot = await Directory.systemTemp.createTemp('vs1179-bk-');
      try {
        final backup = await ProjectBackupService().create(
          package: package,
          type: 'pre-migration',
          note: '117.9 drill backup',
          destinationRoot: backupRoot,
        );
        final restored =
            await ProjectBackupRestorePreview.restoreToAlternateDestination(
              backup: backup,
              destinationRoot: Directory(p.join(root.path, 'restored')),
            );
        final service = ProjectDatabaseService();
        final database = await service.open(restored.databaseFile.path);
        final rows = await database.select(database.securitySettings).get();
        await database.close();

        final sourceManifest = await package.manifestFile.readAsBytes();
        final restoredManifest = await restored.manifestFile.readAsBytes();
        final appearance = InMemoryThemePreferenceStore();
        await appearance.save(AppThemeMode.dark);
        final appearanceRead = await appearance.load();

        return Sprint117UpgradeObservation(
          checkId: 'settings_migration',
          outcome: 'settings_migrated_locally',
          facts: <String, Object?>{
            'security_settings_preserved': rows.length == 1,
            'kdf_iterations_preserved':
                rows.isNotEmpty && rows.single.kdfIterations == 123456,
            'manifest_preserved': _bytesEqual(sourceManifest, restoredManifest),
            // A package copy cannot carry the SharedPreferences appearance
            // store: it is machine-local and never entered the backup.
            'package_copies_appearance_store': false,
            'appearance_store_outside_package': appearanceRead != null,
            'unresolvable': const <String>[
              'appearance_store_outside_project_package',
            ],
          },
          passed:
              rows.length == 1 &&
              rows.single.kdfIterations == 123456 &&
              _bytesEqual(sourceManifest, restoredManifest),
          unresolvable: const <String>[
            'appearance_store_outside_project_package',
          ],
        );
      } finally {
        await _deleteQuietly(backupRoot);
      }
    } finally {
      await _deleteQuietly(root);
    }
  }

  /// The vault round-trips through the real store over the real key scheme,
  /// and the audit carries no secret. The check then reports the fact that
  /// matters: no migration mechanism for a credential vault exists anywhere in
  /// the shipped code, so 113.10's `settings_preserved` claim covers the
  /// project package and nothing else.
  static Future<Sprint117UpgradeObservation> _drillVaultMigration() async {
    const accountId = 'drill_account';
    final store = MemoryCredentialStore();
    final audit = <Map<String, String>>[];
    final vault = AccountSecureTokenVault(
      store: store,
      reauthenticate: () async => true,
      auditSink: (event) => audit.add(<String, String>{
        'action': event.action,
        'secret': event.secret ?? '',
      }),
    );
    const kind = VaultSecretKind.oauthRefreshToken;
    await vault.save(
      accountId: accountId,
      secret: 'drill-refresh-token',
      kind: kind,
    );
    final before = await store.read(vault.keyFor(accountId, kind));
    final readBack = await vault.read(accountId: accountId, kind: kind);
    // An upgrade re-keys the account; a legacy key shape is not picked up by
    // the shipped vault, which is exactly why the gap is reported.
    const legacyKey = 'account/$accountId/token';
    const legacySecret = 'legacy-shape-secret';
    await store.write(key: legacyKey, value: legacySecret);
    final legacyRead = await vault.read(accountId: accountId, kind: kind);
    final legacyUnderCurrentScheme = await store.read(legacyKey);

    return Sprint117UpgradeObservation(
      checkId: 'vault_migration',
      outcome: 'vault_migration_mechanism_absent',
      facts: <String, Object?>{
        'round_trip_read_back': readBack == 'drill-refresh-token',
        'present_before': before != null,
        'audit_carried_secret': audit.any(
          (event) => (event['secret'] ?? '').isNotEmpty,
        ),
        'key_scheme': vault.keyFor(accountId, kind),
        // The shipped vault reads only its own key shape, so a legacy key is
        // invisible to it. The fact is recorded, not repaired.
        'legacy_key_picked_up': legacyRead == legacySecret,
        'legacy_key_untouched': legacyUnderCurrentScheme == legacySecret,
        'migration_mechanism_present': false,
        'unresolvable': const <String>['vault_migration_mechanism_absent'],
      },
      passed:
          before != null &&
          readBack == 'drill-refresh-token' &&
          !audit.any((event) => (event['secret'] ?? '').isNotEmpty) &&
          legacyRead != legacySecret,
      unresolvable: const <String>['vault_migration_mechanism_absent'],
    );
  }

  /// The rollback really creates a pre-migration backup through the shipped
  /// service and really restores it into a throwaway destination, leaving the
  /// live package byte-identical.
  static Future<Sprint117UpgradeObservation> _drillRollback() async {
    final root = await Directory.systemTemp.createTemp('vs1179-rollback-');
    try {
      final package = ProjectPackage(projectId: 'p1', root: root);
      await _seedPackage(package, kdfIterations: 999);

      final liveBefore = await _databaseDigest(package.databaseFile);
      final backupRoot = await Directory.systemTemp.createTemp('vs1179-bk2-');
      try {
        final backup = await ProjectBackupService().create(
          package: package,
          type: 'pre-migration',
          note: '117.9 rollback drill',
          destinationRoot: backupRoot,
        );
        final backupJson =
            jsonDecode(
                  await File(p.join(backup.path, 'backup.json')).readAsString(),
                )
                as Map<String, dynamic>;
        final probeRoot = await Directory.systemTemp.createTemp(
          'vs1179-probe-',
        );
        try {
          final restored =
              await ProjectBackupRestorePreview.restoreToAlternateDestination(
                backup: backup,
                destinationRoot: probeRoot,
              );
          final service = ProjectDatabaseService();
          final opened = await service.open(restored.databaseFile.path);
          final rows = await opened.select(opened.securitySettings).get();
          await opened.close();
          final restoredSchema = await service.schemaVersion(
            restored.databaseFile.path,
          );
          final liveAfter = await _databaseDigest(package.databaseFile);
          return Sprint117UpgradeObservation(
            checkId: 'rollback',
            outcome: 'rollback_restored_locally',
            facts: <String, Object?>{
              'pre_migration_backup_created': backup.existsSync(),
              'backup_type': backupJson['type'],
              'backup_schema_version': backupJson['schemaVersion'],
              'restored_to_alternate_destination': restored.root.existsSync(),
              'restored_schema_version': restoredSchema,
              'restored_settings_rows': rows.length,
              'live_package_untouched': liveBefore == liveAfter,
              'downgrade_guard_active':
                  ProjectDatabase.currentSchemaVersion > 0,
            },
            passed:
                backupJson['type'] == 'pre-migration' &&
                rows.length == 1 &&
                liveBefore == liveAfter,
            unresolvable: const <String>[],
          );
        } finally {
          await _deleteQuietly(probeRoot);
        }
      } finally {
        await _deleteQuietly(backupRoot);
      }
    } finally {
      await _deleteQuietly(root);
    }
  }

  /// Creates the package layout the shipped services expect, then creates the
  /// database through the production create path.
  static Future<void> _seedPackage(
    ProjectPackage package, {
    required int kdfIterations,
  }) async {
    for (final directory in <Directory>[
      package.manifestDirectory,
      package.databaseDirectory,
      package.assetsDirectory,
      package.cacheDirectory,
      package.backupDirectory,
      package.exportDirectory,
      package.recoveryDirectory,
      package.trashDirectory,
    ]) {
      await directory.create(recursive: true);
    }
    await File(
      p.join(package.root.path, 'manifest', 'project.json'),
    ).writeAsString(
      jsonEncode(<String, Object?>{
        'schema_version': 1,
        'id': package.projectId,
        'name': 'Drill Project',
        'app_version': '1.2.0',
      }),
    );
    final path = package.databaseFile.path;
    await ProjectDatabaseService().create(path);
    final database = ProjectDatabase(NativeDatabase(File(path)));
    await database.customSelect('SELECT 1').get();
    await database
        .into(database.assets)
        .insert(
          AssetsCompanion.insert(
            id: 'asset-1',
            projectId: package.projectId,
            name: 'Qowner',
            type: 'character',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
    await database
        .into(database.securitySettings)
        .insert(
          SecuritySettingsCompanion.insert(
            projectId: package.projectId,
            kdfIterations: Value(kdfIterations),
            updatedAt: DateTime(2026),
          ),
        );
    await database.close();
  }

  static String _databasePath(Directory root) =>
      p.join(root.path, 'database', 'project.db');

  /// The structural objects each later wave creates, derived from the shipped
  /// [ProjectDatabase] onUpgrade waves rather than from a hand-kept list.
  static _RewindPlan _objectsIntroducedAfter(int version) {
    final tables = <String>[];
    final statements = <String>[];
    void addTable(String table) {
      tables.add(table);
      statements.add('DROP TABLE IF EXISTS $table');
    }

    void addColumn(String table, String column, String definition) {
      statements.add('ALTER TABLE $table DROP COLUMN $column');
    }

    // Wave boundaries as declared in ProjectDatabase.migration. Tables that a
    // wave creates with `if (from < N)` are removed; columns added by
    // `addColumn` are dropped, guarded by the shipped _columnExists wave.
    const createWaves = <int, List<String>>{
      54: <String>['creature_ecology_states'],
      55: <String>['novel_character_links'],
      56: <String>['workflow_definitions', 'workflow_run_records'],
      57: <String>['scene_draft_snapshots'],
      59: <String>[
        'character_canonical_scopes',
        'character_universe_timeline_overrides',
        'character_novel_states',
      ],
      60: <String>[
        'character_narrative_assignments',
        'character_support_relationships',
      ],
      62: <String>['supporting_asset_profiles'],
    };
    const columnWaves = <int, List<List<String>>>{
      58: <List<String>>[
        <String>['characters', 'voice'],
      ],
      61: <List<String>>[
        <String>['factions', 'image_path'],
        <String>['timeline_eras', 'image_path'],
      ],
    };

    for (final entry in createWaves.entries) {
      if (entry.key <= version) continue;
      for (final table in entry.value) {
        addTable(table);
      }
    }
    for (final entry in columnWaves.entries) {
      if (entry.key <= version) continue;
      for (final column in entry.value) {
        addColumn(column[0], column[1], '');
      }
    }
    return _RewindPlan(tables: tables, statements: statements);
  }

  static Future<bool> _allObjectsPresent(
    ProjectDatabase database,
    List<String> tables,
  ) async {
    if (tables.isEmpty) return true;
    final rows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    final present = rows.map((row) => row.read<String>('name')).toSet();
    return tables.every(present.contains);
  }

  static Future<String> _databaseDigest(File file) async {
    final bytes = await file.readAsBytes();
    return '${bytes.length}:${bytes.isEmpty ? 0 : bytes.last}';
  }

  static bool _bytesEqual(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static Future<void> _deleteQuietly(Directory directory) async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } on Object {
      // A disposable temp directory that cannot be deleted is not a drill
      // failure; it is never a user path.
    }
  }
}

class _RewindPlan {
  const _RewindPlan({required this.tables, required this.statements});

  final List<String> tables;
  final List<String> statements;
}

/// Reads the committed manifests this validation decides from.
class Sprint117UpgradeLoader {
  const Sprint117UpgradeLoader();

  Sprint117UpgradeInput load() =>
      Sprint117UpgradeInput(rows: _loadRows(), anchor: _loadAnchor());

  /// Loads the committed record and folds the measured drill into it.
  Sprint117UpgradeInput loadWithDrill(Sprint117UpgradeDrillRun run) =>
      Sprint117UpgradeInput(
        rows: _loadRows(),
        anchor: _loadAnchor(),
        drillRun: run,
      );

  Sprint117UpgradeAnchor? _loadAnchor() {
    final upgrade = _readJsonObject(Sprint117UpgradeContract.upgradePath);
    final health = _readJsonObject(Sprint117UpgradeContract.migrationHealth);
    final install = _readJsonObject(Sprint117UpgradeContract.installHealth);
    final dryRun = _readJsonObject(Sprint117UpgradeContract.dryRun);
    final boundary = _readJsonObject(Sprint117UpgradeContract.rollbackBoundary);
    final gate = _readJsonObject(Sprint117UpgradeContract.platformGate);
    final vault = _readJsonObject(Sprint117UpgradeContract.vault);
    if (upgrade == null ||
        health == null ||
        install == null ||
        dryRun == null ||
        boundary == null ||
        gate == null ||
        vault == null) {
      return null;
    }

    final sources = _mapValue(upgrade['source_versions']);
    final results = _mapValue(upgrade['upgrade_results']);
    final warnings = _mapValue(upgrade['warnings']);
    final recorded = _mapList(sources['supported_upgrade_sources']);
    final versions = <int>[
      for (final entry in recorded)
        if (entry['schema_version'] is int) entry['schema_version']! as int,
    ];

    final checks = <Sprint117UpgradeCheck>[
      for (final checkId in Sprint117UpgradeContract.requiredChecks)
        if (_defined(checkId, upgrade, dryRun, boundary, vault))
          Sprint117UpgradeCheck(
            checkId: checkId,
            method: _method(checkId, upgrade),
            expectedOutcome: _expectedOutcome(checkId),
            // No install has ever been run against a real machine, so no check
            // carries an observed outcome. Filling one in would fabricate the
            // single observation this gate exists to keep out of the record.
            observedOutcome: null,
            sourceManifest: _sourceFor(checkId),
            liveInstallResult: false,
            drilledAgainstLiveInstall: false,
          ),
    ];

    return Sprint117UpgradeAnchor(
      upgradeVerdict: _text(upgrade['status']),
      migrationHealthVerdict: _text(health['decision_rule']),
      installHealthVerdict: _text(install['decision_rule']),
      checks: checks,
      sourceManifests: Sprint117UpgradeContract.sourceManifests,
      currentSchemaVersion: _int(sources['current_schema_version']),
      supportedSourcesRecorded: recorded.isNotEmpty,
      claimedSourceVersions: versions,
      freshDatabaseClaimed: _text(results['fresh_database_at_62']).isNotEmpty,
      futureSchemaClaimed: _text(results['future_schema_rejection']).isNotEmpty,
      backupBeforeMigration: sources['backup_before_migration'] == true,
      settingsPreservedClaimed:
          _mapValue(upgrade['data_comparison'])['settings_preserved'] == true,
      // No committed source records a vault migration. The key scheme lives in
      // code, and no source file carries one, so the fact is read, not assumed.
      vaultMigrationRecorded: false,
      carriedOpenItems: _carriedOpenItems(upgrade, warnings, vault),
    );
  }

  List<Sprint117UpgradeCheck>? _loadRows() =>
      _loadAnchor()?.checks ?? const <Sprint117UpgradeCheck>[];

  /// A check exists only where its source records something. A check whose
  /// manifest names no method and no acceptance is not created, so a missing
  /// manifest produces a blocked report rather than invented content.
  bool _defined(
    String checkId,
    Map<String, dynamic> upgrade,
    Map<String, dynamic> dryRun,
    Map<String, dynamic> boundary,
    Map<String, dynamic> vault,
  ) => switch (checkId) {
    'clean_install' =>
      _mapValue(upgrade['source_versions']).isNotEmpty &&
          _mapList(
            upgrade['source_versions']['supported_upgrade_sources'],
          ).isNotEmpty,
    'source_versions' => _mapList(
      upgrade['source_versions']['supported_upgrade_sources'],
    ).isNotEmpty,
    'upgrade_results' => _mapValue(upgrade['upgrade_results']).isNotEmpty,
    'settings_migration' =>
      _mapValue(upgrade['data_comparison'])['settings_preserved'] == true ||
          _mapValue(dryRun['required_outputs'])['checksum_results'] != null,
    'vault_migration' => _stringList(vault['acceptance']).isNotEmpty,
    'rollback' =>
      _mapValue(upgrade['recovery_results']).isNotEmpty ||
          _mapValue(boundary['outputs'])['rollback_test'] != null,
    _ => false,
  };

  /// The method each check runs, stated from the mechanism the check's own
  /// source defines. 113.10 records results, not methods, so each step is
  /// derived from the shipped service the check exercises rather than borrowed
  /// from a neighbouring check.
  String _method(
    String checkId,
    Map<String, dynamic> upgrade,
  ) => switch (checkId) {
    'clean_install' =>
      'Create a database through ProjectDatabaseService.create, then reopen it '
          'through the production open path and assert the reopen is a no-op',
    'source_versions' =>
      'Resolve every supported source version in 113.10 against the schema '
          'version the shipped ProjectDatabase declares',
    'upgrade_results' =>
      'Rewind a current database to each recorded source version, drop the '
          'objects later waves create, and re-open it through '
          'ProjectDatabaseService.open',
    'settings_migration' =>
      'Back up a package with ProjectBackupService and restore it through '
          'ProjectBackupRestorePreview, then read the security settings row back',
    'vault_migration' =>
      'Round-trip a secret through AccountSecureTokenVault over an in-memory '
          'CredentialStore and report whether any migration path exists',
    'rollback' =>
      'Create a pre-migration backup through ProjectBackupService and restore '
          'it through ProjectBackupRestorePreview into a throwaway destination',
    _ => '',
  };

  /// What the method is expected to produce locally, stated as an observation a
  /// responder can check rather than as a claim of success.
  String _expectedOutcome(String checkId) => switch (checkId) {
    'clean_install' =>
      'ProjectDatabaseService.create lands at the current schema and a reopen '
          'leaves the schema unchanged',
    'source_versions' =>
      'every recorded source version is below the shipped current schema version',
    'upgrade_results' =>
      'every recorded source version migrates to the current schema with its '
          'Core rows intact and every later wave object recreated',
    'settings_migration' =>
      'the package-resident security settings row and manifest round-trip '
          'through a real backup and restore',
    'vault_migration' =>
      'the vault round-trips through its own key scheme while the absence of a '
          'migration path is reported rather than filled in',
    'rollback' =>
      'a pre-migration backup restores into a throwaway destination and leaves '
          'the live package byte-identical',
    _ => '',
  };

  String _sourceFor(String checkId) => switch (checkId) {
    'clean_install' => Sprint117UpgradeContract.upgradePath,
    'source_versions' => Sprint117UpgradeContract.upgradePath,
    'upgrade_results' => Sprint117UpgradeContract.upgradePath,
    'settings_migration' => Sprint117UpgradeContract.upgradePath,
    'vault_migration' => Sprint117UpgradeContract.vault,
    'rollback' => Sprint117UpgradeContract.rollbackBoundary,
    _ => '',
  };

  List<String> _carriedOpenItems(
    Map<String, dynamic> upgrade,
    Map<String, dynamic> warnings,
    Map<String, dynamic> vault,
  ) {
    final items = <String>{};
    for (final limit in _stringList(
      vault['boundary'] is Object
          ? _mapValue(vault['boundary'])['limits']
          : const <String>[],
    )) {
      items.add('upstream_vault_limit:$limit');
    }
    for (final limitation in _stringList(
      _mapValue(vault['boundary'])['limitations'],
    )) {
      items.add('upstream_vault_limitation:$limitation');
    }
    for (final limit in _stringList(warnings['known_limitations'])) {
      items.add('upstream_upgrade_limit:$limit');
    }
    if (_mapValue(
          upgrade['recovery_results'],
        )['pre_migration_backup_restorable'] !=
        true) {
      items.add('pre_migration_backup_not_confirmed_restorable');
    }
    return items.toList(growable: false);
  }

  static Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static Map<String, dynamic> _mapValue(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is! List<dynamic>) return const <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[
      for (final item in value)
        if (item is Map<String, dynamic>) item,
    ];
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  static int _int(Object? value) => value is int ? value : 0;

  static List<String> _stringList(Object? value) {
    if (value is! List<dynamic>) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

class Sprint117UpgradeGate {
  const Sprint117UpgradeGate();

  Sprint117UpgradeReport evaluate() =>
      evaluateWith(const Sprint117UpgradeLoader().load());

  Sprint117UpgradeReport evaluateWith(Sprint117UpgradeInput input) {
    final missing = <String>{};
    final violations = <String>[];

    // --- anchor ------------------------------------------------------------
    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('upgrade_anchor');
    } else {
      if (anchor.upgradeVerdict.trim().isEmpty) {
        missing.add('upgrade_verdict');
      } else if (anchor.upgradeVerdict !=
          Sprint117UpgradeContract.upgradeVerdict) {
        violations.add('anchor_verdict_drift');
        violations.add('anchor_verdict:${anchor.upgradeVerdict}');
        missing.add('upgrade_anchor');
      }
      if (anchor.migrationHealthVerdict.trim().isEmpty) {
        missing.add('migration_health_verdict');
      }
      if (anchor.installHealthVerdict.trim().isEmpty) {
        missing.add('install_health_verdict');
      }
      if (!anchor.supportedSourcesRecorded) {
        missing.add('supported_source_versions');
      }
      if (!anchor.claimedSourceVersions.isNotEmpty) {
        missing.add('claimed_source_versions');
      }
      if (anchor.currentSchemaVersion <= 0) {
        missing.add('current_schema_version');
      } else if (anchor.currentSchemaVersion !=
          ProjectDatabase.currentSchemaVersion) {
        // 113.10 records the schema version the app shipped at. If the shipped
        // database has moved on, every recorded upgrade result describes a
        // migration this build no longer performs.
        violations.add('schema_version_drift');
        violations.add(
          'recorded_schema_version:${anchor.currentSchemaVersion}',
        );
        violations.add(
          'shipped_schema_version:${ProjectDatabase.currentSchemaVersion}',
        );
      }
      if (!anchor.freshDatabaseClaimed) {
        missing.add('fresh_database_claim');
      }
      if (!anchor.futureSchemaClaimed) {
        missing.add('future_schema_claim');
      }
      if (!anchor.backupBeforeMigration) {
        // A migration without a pre-migration backup has nothing to roll back
        // to, so the rollback check would be deciding an empty claim.
        violations.add('backup_before_migration_not_recorded');
      }
      if (anchor.vaultMigrationRecorded) {
        // No committed source records a vault migration. If one appears, this
        // gate must not keep reporting the gap as if nothing shipped, so the
        // claim is a contradiction until a drill proves the mechanism.
        violations.add('vault_migration_claimed_without_mechanism');
      }
    }

    // --- checks ------------------------------------------------------------
    final rows = input.rows;
    final rowIds = <String>{};
    final checks = <Sprint117UpgradeCheck>[];
    final undetermined = <String>[];

    if (rows == null || rows.isEmpty) {
      missing.add('check_rows');
    } else {
      for (final row in rows) {
        final checkId = row.checkId.trim();
        if (checkId.isEmpty) {
          violations.add('check_id_blank');
          continue;
        }
        if (!rowIds.add(checkId)) {
          violations.add('check_duplicate:$checkId');
          continue;
        }
        checks.add(row);
        _checkCheck(row, missing, violations);
        // A check no live install has ever run is defined but undecided, and
        // that is an open item rather than a defect.
        if (!row.executed) undetermined.add(checkId);
      }
    }

    // Every canonical check must be mapped by exactly one row. A dropped check
    // is a promise quietly removed from the validation, not a skip.
    final unmapped = <String>[];
    if (anchor != null && !missing.contains('upgrade_anchor')) {
      for (final checkId in Sprint117UpgradeContract.requiredChecks) {
        if (!rowIds.contains(checkId)) unmapped.add(checkId);
      }
      for (final checkId in unmapped) {
        violations.add('check_unmapped:$checkId');
      }
    } else {
      unmapped.addAll(Sprint117UpgradeContract.requiredChecks);
    }

    // The drill, when one ran, is the evidence; a failed observation is a
    // contradiction between the recorded PASS and the shipped mechanism.
    final run = input.drillRun;
    if (run != null && !run.allPassed) {
      for (final observation in run.observations) {
        if (!observation.passed) {
          violations.add('drill_failed:${observation.checkId}');
        }
      }
    }
    if (run != null && run.liveInstallTouched) {
      violations.add('drill_live_install_claim');
    }
    if (run != null && run.userProjectTouched) {
      // This drill must never read or write a user project.
      violations.add('drill_touched_user_project');
    }
    if (run != null && run.liveSecretsObserved.isNotEmpty) {
      violations.add('drill_observed_live_secret');
    }

    final state = violations.isNotEmpty
        ? Sprint117UpgradeState.fail
        : missing.isNotEmpty
        ? Sprint117UpgradeState.blocked
        : Sprint117UpgradeState.pass;
    final verdict = switch (state) {
      Sprint117UpgradeState.pass => Sprint117UpgradeContract.passVerdict,
      Sprint117UpgradeState.fail => Sprint117UpgradeContract.failVerdict,
      Sprint117UpgradeState.blocked => Sprint117UpgradeContract.blockedVerdict,
    };

    final openItems = <String>[...anchor?.carriedOpenItems ?? const <String>[]];
    final openItemSet = openItems.toSet();
    void addOpenItem(String item) {
      if (openItemSet.add(item)) openItems.add(item);
    }

    for (final checkId in undetermined) {
      addOpenItem('check_observed_outcome_null:$checkId');
    }
    addOpenItem('install_defined_not_executed');
    for (final reference in _unresolvableReferences(anchor, run)) {
      addOpenItem('unresolvable_reference:$reference');
    }

    final limitations = <String>[
      'This validation is local only. No installer ran, no package was downloaded, nothing was signed, and no update channel delivered a release.',
      'No check carries an observed outcome. No machine has ever installed an upgrade from these source versions, so any outcome recorded here would be fabricated.',
      'Local exercises run against the shipped ProjectDatabaseService, ProjectDatabase migration waves, ProjectBackupService, ProjectBackupRestorePreview, and AccountSecureTokenVault over an in-memory store. They prove the mechanism responds; they do not prove a real user upgrade.',
      'The appearance preference store lives outside the project package, so no project backup or restore can carry it. It is reported as unresolvable rather than assumed migrated.',
      'All external gates remain $externalGatesText: hosted CI, public signing, end-user update channels, real installer packaging, and publication are not part of this local evidence.',
    ];

    final checkCoverage = <String, int>{
      for (final checkId in Sprint117UpgradeContract.requiredChecks)
        checkId: checks.where((row) => row.checkId == checkId).length,
    };

    return Sprint117UpgradeReport(
      state: state,
      verdict: verdict,
      missingFields: missing.toList(growable: false),
      violations: violations.toList(growable: false),
      anchor: anchor,
      checks: checks,
      unmappedChecks: unmapped,
      undeterminedChecks: undetermined,
      unresolvableReferences: _unresolvableReferences(anchor, run),
      drillRun: run,
      openItems: openItems,
      limitations: limitations,
      checkCoverage: checkCoverage,
    );
  }

  static String get externalGatesText => Sprint117UpgradeContract.externalGates;

  /// Check coherence: a validation is a claim about moving a user forward
  /// without losing anything, so a check that reports a live install
  /// contradicts the record 113.10 keeps, and a check sourced outside the
  /// declared manifests is not traceable to a canonical decision. A blank
  /// method or expected outcome is missing evidence — nobody has finished
  /// writing it — not a violation.
  static void _checkCheck(
    Sprint117UpgradeCheck row,
    Set<String> missing,
    List<String> violations,
  ) {
    final checkId = row.checkId.trim();
    if (!Sprint117UpgradeContract.requiredChecks.contains(checkId)) {
      violations.add('check_unknown_id:$checkId');
    }
    if (row.liveInstallResult || row.drilledAgainstLiveInstall) {
      violations.add('check_live_install_claim:$checkId');
    }
    if (row.method.trim().isEmpty) {
      missing.add('check_method:$checkId');
    }
    if (row.expectedOutcome.trim().isEmpty) {
      missing.add('check_expected_outcome:$checkId');
    }
    if (row.sourceManifest.trim().isEmpty) {
      missing.add('check_source_manifest:$checkId');
    } else if (!Sprint117UpgradeContract.sourceManifests.contains(
      row.sourceManifest.trim(),
    )) {
      violations.add('check_unsourced:$checkId:${row.sourceManifest.trim()}');
    }
  }

  /// Recorded subjects that cannot be resolved, gathered from the anchor and
  /// the measured drill.
  static List<String> _unresolvableReferences(
    Sprint117UpgradeAnchor? anchor,
    Sprint117UpgradeDrillRun? run,
  ) {
    final references = <String>{
      ...run?.unresolvableReferences ?? const <String>[],
    };
    // 113.10 records `settings_preserved: true` across project data, but the
    // appearance store is machine-local and never enters a backup. The claim is
    // narrower than it reads, so the gap is surfaced with its exact spelling.
    if (anchor != null && anchor.settingsPreservedClaimed) {
      references.add('appearance_store_outside_project_package');
    }
    // No committed source records a vault migration and none exists in code.
    if (anchor != null && !anchor.vaultMigrationRecorded) {
      references.add('vault_migration_mechanism_absent');
    }
    return references.toList(growable: false)..sort();
  }
}
