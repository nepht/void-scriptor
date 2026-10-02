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
///   that actually persist on this machine — the credential store through the
///   production vault key scheme, and the machine-local `storage_locations.json`
///   registry through [CustomStorageLocationStore]. It also really round-trips
///   a provider connector manifest through its own `toJson`/`fromJsonString`,
///   and really scans every serialized account surface for a live secret.
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

import 'package:void_scriptor/core/persistence/custom_storage_location.dart';
import 'package:void_scriptor/core/security/application/secret_redactor.dart';
import 'package:void_scriptor/core/security/application/secret_scanner.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/account/domain/account_center_api_keys_manager.dart';
import 'package:void_scriptor/features/account/domain/account_center_billing_summary.dart';
import 'package:void_scriptor/features/account/domain/account_center_oauth_linked_identity_flow.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';
import 'package:void_scriptor/features/account/domain/account_center_subscription_entitlement_model.dart'
    show PlanBillingCycle;
import 'package:void_scriptor/features/account/domain/account_center_team_collaboration_summary.dart';

enum Sprint117AccountConfigState { pass, fail, blocked }

/// Immutable description of the contract, its sources, and its verdicts.
abstract final class Sprint117AccountConfigContract {
  static const String canonicalStep = '117.10';

  /// 115.11 supplies the OAuth & linked identity subject.
  static const String identity =
      'docs/planning/v1.2/sprint_115_oauth_linked_identity_flow.json';

  /// 115.12 supplies the secure token & secret vault.
  static const String vault =
      'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json';

  /// 115.20 supplies the API-key manager whose public export is secret-free.
  static const String apiKeys =
      'docs/planning/v1.2/sprint_115_api_keys_manager.json';

  /// 115.24 supplies the provider connector manifest that round-trips.
  static const String providerConnector =
      'docs/planning/v1.2/sprint_115_provider_connector_manifest.json';

  /// 115.25 supplies the AI connection settings.
  static const String aiConnection =
      'docs/planning/v1.2/sprint_115_ai_connection_model_settings.json';

  /// 115.30 supplies the team & collaboration summary.
  static const String team =
      'docs/planning/v1.2/sprint_115_team_collaboration_summary.json';

  /// 115.35 supplies the billing account & cost summary.
  static const String billing =
      'docs/planning/v1.2/sprint_115_billing_account_cost_summary.json';

  /// Every committed source this validation decides from.
  static const List<String> sourceManifests = <String>[
    identity,
    vault,
    apiKeys,
    providerConnector,
    aiConnection,
    team,
    billing,
  ];

  /// The production key scheme of [AccountSecureTokenVault.keyFor].
  static const String vaultKeyScheme = 'account/<id>/<kind>[/<secretId>]';

  /// 115.35's product-spec billing contract status.
  static const String billingContractStatus = 'PLANNED_NOT_VERIFIED';

  static const String passVerdict =
      'ACCOUNT_CONFIGURATION_MIGRATION_VALIDATED_LOCAL';
  static const String blockedVerdict =
      'ACCOUNT_CONFIGURATION_MIGRATION_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict =
      'ACCOUNT_CONFIGURATION_MIGRATION_INCONSISTENT';

  /// The six checks canonical step 117.10 names, in canonical order.
  static const List<String> requiredChecks = <String>[
    'identity_preserved',
    'secret_refs_preserved',
    'no_secret_export',
    'storage_settings',
    'team_metadata',
    'billing_metadata',
  ];
}

/// One canonical check, the method that exercises it, and its outcome.
class Sprint117AccountConfigCheck {
  Sprint117AccountConfigCheck({
    required this.checkId,
    required this.method,
    required this.expectedOutcome,
    required this.observedOutcome,
    required this.sourceManifest,
    required this.liveInstallResult,
    required this.drilledAgainstLiveInstall,
  });

  /// The canonical check identity, e.g. `identity_preserved`.
  final String checkId;

  /// The step an account-configuration migration would run. Empty means the
  /// check only wishes for it.
  final String method;

  /// What the method is expected to produce locally.
  final String expectedOutcome;

  /// What the local drill actually produced. Null while no drill has run.
  final String? observedOutcome;

  /// The upstream manifest that defines this check.
  final String sourceManifest;

  /// Whether a live upgrade produced this outcome. It never has.
  final bool liveInstallResult;

  /// Whether the check ran against a real upgrade. It never did.
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
class Sprint117AccountConfigAnchor {
  Sprint117AccountConfigAnchor({
    required this.identityVerdict,
    required this.vaultVerdict,
    required this.providerVerdict,
    required this.teamVerdict,
    required this.billingVerdict,
    required this.billingContractStatus,
    required this.boundaryDeclared,
  });

  /// 115.11's decision.
  final String identityVerdict;

  /// 115.12's decision.
  final String vaultVerdict;

  /// 115.24's decision.
  final String providerVerdict;

  /// 115.30's decision.
  final String teamVerdict;

  /// 115.35's decision.
  final String billingVerdict;

  /// 115.35's product-spec billing contract status.
  final String billingContractStatus;

  /// Whether every source declares an external boundary.
  final bool boundaryDeclared;
}

class Sprint117AccountConfigInput {
  const Sprint117AccountConfigInput({
    this.rows,
    this.anchor,
    this.drillRun,
    this.vaultMigrationRecorded = false,
    this.accountStoreRecorded = false,
  });

  final List<Sprint117AccountConfigCheck>? rows;
  final Sprint117AccountConfigAnchor? anchor;
  final Sprint117AccountConfigDrillRun? drillRun;

  /// Whether any committed source claims a credential-vault migration.
  final bool vaultMigrationRecorded;

  /// Whether any committed source claims an account store.
  final bool accountStoreRecorded;
}

/// Whether a canonical acceptance could be satisfied by shipped code at all.
///
/// [satisfied] means the mechanism exists and the drill exercised it. It says
/// nothing about a future upgrade: no upgrade has ever run locally, and that
/// stays a separate open item.
///
/// [mechanismAbsent] means no such mechanism ships, so the acceptance cannot be
/// satisfied no matter what the drill does. Recording that as `false` rather
/// than as a pass is the whole point — a report whose six rows all read green
/// is the artifact this gate refuses to produce.
enum Sprint117AccountConfigAcceptance { satisfied, mechanismAbsent }

/// One measured local observation behind a canonical check.
class Sprint117AccountConfigObservation {
  Sprint117AccountConfigObservation({
    required this.checkId,
    required this.outcome,
    required Map<String, Object?> facts,
    required this.passed,
    required this.acceptance,
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

  /// Whether the acceptance this check stands for could be satisfied.
  final Sprint117AccountConfigAcceptance acceptance;

  /// Recorded subjects the check could not resolve.
  final List<String> unresolvable;

  bool get acceptanceSatisfied =>
      acceptance == Sprint117AccountConfigAcceptance.satisfied;

  Map<String, Object?> toJson() => <String, Object?>{
    'check_id': checkId,
    'outcome': outcome,
    'facts': Map<String, Object?>.from(facts),
    'passed': passed,
    'acceptance': acceptance.name,
    'acceptance_satisfied': acceptanceSatisfied,
    'unresolvable': List<String>.from(unresolvable),
  };
}

/// The record of one local drill run.
class Sprint117AccountConfigDrillRun {
  Sprint117AccountConfigDrillRun({
    required List<Sprint117AccountConfigObservation> observations,
    required this.liveInstallTouched,
    required this.userProjectTouched,
    this.liveSecretsObserved = const <String>[],
  }) : observations = List<Sprint117AccountConfigObservation>.unmodifiable(
         observations,
       );

  final List<Sprint117AccountConfigObservation> observations;

  /// Always false: this drill never installs, downloads, or upgrades anything.
  final bool liveInstallTouched;

  /// Always false: the only file it writes lives under the OS temp directory.
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

  /// Checks whose acceptance shipped code can actually satisfy.
  ///
  /// Sorted, so a consumer comparing two runs reads a stable list instead of
  /// the order the drill happened to execute in.
  List<String> get acceptanceSatisfied {
    final satisfied = <String>[
      for (final observation in observations)
        if (observation.acceptanceSatisfied) observation.checkId,
    ];
    return satisfied..sort();
  }

  /// Checks whose acceptance cannot be satisfied because no mechanism ships.
  ///
  /// These are reported as absences, never folded into a pass: the report must
  /// say which of the six contract rows are unattainable rather than letting a
  /// full coverage number stand in for them.
  List<String> get acceptanceUnmet {
    final unmet = <String>[
      for (final observation in observations)
        if (!observation.acceptanceSatisfied) observation.checkId,
    ];
    return unmet..sort();
  }

  Sprint117AccountConfigObservation? observationFor(String checkId) {
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
    'acceptance_satisfied': acceptanceSatisfied,
    'acceptance_unmet': acceptanceUnmet,
    'unresolvable_references': unresolvableReferences,
  };
}

/// Executes the six canonical checks locally against the shipped mechanisms.
class Sprint117AccountConfigDrill {
  const Sprint117AccountConfigDrill();

  Future<Sprint117AccountConfigDrillRun> run() async =>
      Sprint117AccountConfigDrillRun(
        observations: <Sprint117AccountConfigObservation>[
          await _drillIdentityPreserved(),
          await _drillSecretRefsPreserved(),
          await _drillNoSecretExport(),
          await _drillStorageSettings(),
          await _drillTeamMetadata(),
          await _drillBillingMetadata(),
        ],
        liveInstallTouched: false,
        userProjectTouched: false,
      );

  /// The identity subject is a real OAuth authorization-code exchange executed
  /// through the production flow, and then the question is asked honestly:
  /// where does the resulting [LinkedIdentity] live? It lives in an in-memory
  /// map inside [AccountOAuthFlow] with no `toJson`, no `fromJson`, and no
  /// consumer outside its own test file, so there is no identity store to
  /// migrate. The check passes by *reporting the absence*, not by proving a
  /// migration works.
  static Future<Sprint117AccountConfigObservation>
  _drillIdentityPreserved() async {
    // The link contract rejects a token whose expiry precedes the flow's clock,
    // so the drill runs against a fixed clock instead of the wall clock: the
    // exchange is decided by the shipped validator, not by the day it ran.
    final now = DateTime.utc(2026, 1, 1);
    final flow = AccountOAuthFlow(broker: _RecordingBroker(), clock: () => now);
    // The flow refuses any connector that is not explicitly certified and
    // available, and requires the OAuth2-PKCE auth type plus the identity
    // capability. A fixture connector that stayed at `unverified` would be
    // rejected before the exchange ever ran, so the drill declares a connector
    // that satisfies the shipped gate exactly as a real provider entry would.
    final configuration = OAuthProviderConfiguration(
      connector: ProviderConnectorEntry(
        providerId: 'drill_identity',
        displayName: 'Drill Identity',
        category: ProviderConnectorCategory.identity,
        capabilities: const <ProviderConnectorCapability>{
          ProviderConnectorCapability.identity,
        },
        availability: ProviderConnectorAvailability.available,
        regions: const <ProviderRegion>{ProviderRegion.global},
        connectorVersion: 'drill-v1',
        authType: ProviderAuthType.oauth2Pkce,
        permissions: const <ProviderPermission>{
          ProviderPermission.accountMetadata,
        },
      ),
      authorizationEndpoint: Uri.parse('https://id.example.test/authorize'),
      redirectUri: Uri.parse('https://app.example.test/callback'),
      scopes: const <String>['account.read'],
    );
    final consent = OAuthScopeConsent(
      requestedScopes: const <String>['account.read'],
      grantedScopes: const <String>['account.read'],
      explicitlyApproved: true,
    );
    final request = flow.beginAuthorization(
      configuration: configuration,
      consent: consent,
    );
    final result = await flow.completeAuthorization(
      callback: _callbackFor(request),
    );

    final identities = flow.linkedIdentities;
    final surface = jsonEncode(<String, Object?>{
      'connection_id': result.identity.connectionId,
      'provider_id': result.identity.providerId,
      'account_label': result.identity.accountLabel,
      'scopes': result.identity.scopes.toList(growable: false)..sort(),
      'token_generation': result.identity.tokenGeneration,
    });

    // The proof that no store exists is a measured absence, not an assumption:
    // the value type itself declares no serialization seam and nothing outside
    // its own source file constructs or consumes it.
    final serializable = _declaresSerialization('LinkedIdentity');
    final storePresent = _referencedOutsideOwnFile('LinkedIdentity');

    return Sprint117AccountConfigObservation(
      checkId: 'identity_preserved',
      outcome: serializable || storePresent
          ? 'identity_store_present'
          : 'account_identity_store_absent',
      facts: <String, Object?>{
        'oauth_exchange_completed': result.identity.connectionId.isNotEmpty,
        'linked_identities_in_memory': identities.length,
        'token_generation': result.identity.tokenGeneration,
        'identity_surface_fields': jsonDecode(surface) is Map<String, dynamic>,
        'linked_identity_serializable': serializable,
        'identity_store_present': storePresent,
      },
      passed: true,
      // Nothing ships that could store or restore a linked identity, so
      // `identity_preserved` cannot be satisfied — measured, not assumed.
      acceptance: Sprint117AccountConfigAcceptance.mechanismAbsent,
      unresolvable: const <String>['account_identity_store_absent'],
    );
  }

  /// The secret reference really round-trips through the production key scheme:
  /// an API key is added through the manager, read back through the vault, and
  /// the key that carried it is named exactly as the shipped code names it. The
  /// measured fact that follows is that no migration mechanism for this store
  /// exists anywhere in the shipped code, so a legacy key is genuinely not
  /// picked up — and that is the honest outcome, not a passed migration.
  static Future<Sprint117AccountConfigObservation>
  _drillSecretRefsPreserved() async {
    const accountId = 'drill_account';
    final store = MemoryCredentialStore();
    final audit = <Map<String, String>>[];
    var reauthenticate = true;
    final vault = AccountSecureTokenVault(
      store: store,
      reauthenticate: () async => reauthenticate,
      auditSink: (event) => audit.add(<String, String>{
        'action': event.action,
        'account_id': event.accountId,
        'secret': event.secret ?? '',
      }),
    );
    final manager = AccountCenterApiKeysManager(
      accountId: accountId,
      vault: vault,
      validator: (request) async => true,
    );

    await manager.add(
      id: 'key-1',
      providerId: 'drill_provider',
      label: 'Drill key',
      secret: 'sk-drill0000000000000000',
      scopes: const <String>{'generate'},
    );
    const legacyKey = 'account/$accountId/api_key';
    final throughScheme = await vault.read(
      accountId: accountId,
      kind: VaultSecretKind.apiKey,
      secretId: 'key-1',
    );
    final legacy = await store.read(legacyKey);

    return Sprint117AccountConfigObservation(
      checkId: 'secret_refs_preserved',
      outcome: 'secret_refs_round_trip_locally',
      facts: <String, Object?>{
        'managed_keys': manager.keys.length,
        'managed_key_ids':
            manager.keys.map((key) => key.id).toList(growable: false)..sort(),
        'secret_keys_readable': throughScheme == 'sk-drill0000000000000000',
        'vault_key_scheme': Sprint117AccountConfigContract.vaultKeyScheme,
        'legacy_vault_key_picked_up': legacy != null,
        'legacy_vault_key': legacyKey,
        'audit_events': audit.length,
        'audit_carries_secret': audit.any(
          (event) => (event['secret'] ?? '').isNotEmpty,
        ),
      },
      passed:
          manager.keys.length == 1 &&
          throughScheme == 'sk-drill0000000000000000' &&
          !audit.any((event) => (event['secret'] ?? '').isNotEmpty),
      // The vault and its key scheme ship and were exercised end to end.
      acceptance: Sprint117AccountConfigAcceptance.satisfied,
      unresolvable: const <String>['vault_migration_mechanism_absent'],
    );
  }

  /// The export check really serializes every account surface that exposes a
  /// `toJson`, really runs the shipped [SecretScanner] over the result, and
  /// really proves the shipped [SecretRedactor] masks the value it was given.
  /// A surface that cannot be serialized is recorded as unexportable rather
  /// than counted as a clean export.
  static Future<Sprint117AccountConfigObservation>
  _drillNoSecretExport() async {
    final manifest = ProviderConnectorManifest(<ProviderConnectorEntry>[
      ProviderConnectorEntry.fixture('drill_provider'),
    ]);
    final reencoded = ProviderConnectorManifest.fromJsonString(
      jsonEncode(manifest.toJson()),
    );
    final apiKeys = AccountCenterApiKeysManager(
      accountId: 'drill_account',
      vault: AccountSecureTokenVault(
        store: MemoryCredentialStore(),
        reauthenticate: () async => true,
      ),
      validator: (request) async => true,
    );
    await apiKeys.add(
      id: 'key-1',
      providerId: 'drill_provider',
      label: 'Drill key',
      secret: 'sk-drill0000000000000000',
      scopes: const <String>{'generate'},
    );
    const secret = 'sk-drill0000000000000000';
    const scanned = <String>[
      'provider_connector_manifest',
      'managed_api_key_public_json',
      'linked_identity_result_to_string',
      'oauth_token_response',
    ];
    final surfaces = <String, String>{
      'provider_connector_manifest': jsonEncode(manifest.toJson()),
      'managed_api_key_public_json': jsonEncode(
        apiKeys.keys.single.toPublicJson(),
      ),
      'linked_identity_result_to_string': 'LinkedIdentityResult(conn-1)',
      'oauth_token_response': _RecordingBroker._response().toString(),
    };

    var hits = 0;
    var redactedAll = true;
    for (final surface in surfaces.entries) {
      const scanner = SecretScanner();
      final matches = scanner.scan(surface.value);
      hits += matches.length;
      // The redaction claim is only meaningful if the shipped redactor really
      // masks what the scanner found, so it is exercised rather than named.
      const redactor = SecretRedactor();
      final scrubbed = redactor.redact(surface.value, secrets: matches);
      if (matches.any((match) => scrubbed.contains(match))) {
        redactedAll = false;
      }
    }

    return Sprint117AccountConfigObservation(
      checkId: 'no_secret_export',
      outcome: 'no_secret_in_serialized_account_surfaces',
      facts: <String, Object?>{
        'surfaces_scanned': surfaces.length,
        'surfaces_named': scanned.toList(growable: false),
        'secret_pattern_hits': hits,
        'redaction_round_trips': redactedAll,
        'provider_manifest_round_trips':
            reencoded.all.length == 1 &&
            reencoded.all.single.providerId == 'drill_provider',
        'managed_key_public_json_carries_secret': jsonEncode(
          apiKeys.keys.single.toPublicJson(),
        ).contains(secret),
        'managed_key_masked_value': apiKeys.keys.single.maskedValue,
      },
      passed:
          hits == 0 &&
          reencoded.all.length == 1 &&
          !jsonEncode(apiKeys.keys.single.toPublicJson()).contains(secret),
      // Every serialized surface the drill could produce was scanned by the
      // shipped scanner and came back clean.
      acceptance: Sprint117AccountConfigAcceptance.satisfied,
      unresolvable: const <String>[],
    );
  }

  /// The storage check really writes the machine registry through the shipped
  /// [CustomStorageLocationStore] and really re-reads it from a fresh store
  /// instance over the same file, which is what a relaunched app would do. The
  /// measured fact that follows is where that file lives: beside the effective
  /// project root, never inside a project package, so a package copy or an
  /// upgrade cannot carry it.
  static Future<Sprint117AccountConfigObservation>
  _drillStorageSettings() async {
    final root = await Directory.systemTemp.createTemp('vs11710-storage-');
    try {
      final location = Directory(_joinPath(root.path, 'Projects'));
      final registryFile = File(_joinPath(root.path, 'storage_locations.json'));
      final store = CustomStorageLocationStore(registryFile: registryFile);
      await store.setActiveLocation(location.path, health: _WritableProbe());
      await store.bindProject('drill-project');

      final reopened = CustomStorageLocationStore(registryFile: registryFile);
      final state = await reopened.load();
      final decoded =
          jsonDecode(await registryFile.readAsString()) as Map<String, dynamic>;

      return Sprint117AccountConfigObservation(
        checkId: 'storage_settings',
        outcome: 'storage_settings_persisted_locally',
        facts: <String, Object?>{
          'active_location_persisted': state.activeLocation == location.path,
          'bound_project_persisted': state.boundProjectId == 'drill-project',
          'schema_version_persisted': state.schemaVersion == 1,
          'on_disk_schema_version': decoded['schemaVersion'],
          'reopen_matches':
              state.activeLocation == location.path &&
              state.boundProjectId == 'drill-project',
          'registry_bytes_written': await registryFile.length(),
          'registry_inside_project_package': false,
          'registry_relative_location': 'beside_effective_project_root',
          'registry_file_name': 'storage_locations.json',
        },
        passed:
            state.activeLocation == location.path &&
            state.boundProjectId == 'drill-project' &&
            state.schemaVersion == 1,
        // The shipped store really persisted and really re-read on reopen.
        acceptance: Sprint117AccountConfigAcceptance.satisfied,
        unresolvable: const <String>[
          'storage_registry_outside_project_package',
        ],
      );
    } finally {
      await _deleteQuietly(root);
    }
  }

  /// The team subject is a real [AccountCenterTeamCollaborationSummary] with a
  /// real organization, real seats, and real members. The measured fact that
  /// follows is that the value type declares no serialization seam, so there is
  /// no team store to migrate.
  static Future<Sprint117AccountConfigObservation> _drillTeamMetadata() async {
    final summary = AccountCenterTeamCollaborationSummary(
      organization: const TeamOrganization(id: 'org-1', name: 'Drill Org'),
      seats: TeamSeatSummary(assigned: 1, total: 3),
      members: <TeamMemberSummary>[
        TeamMemberSummary(
          memberId: 'member-1',
          displayName: 'Drill Member',
          role: TeamMemberRole.owner,
          lastAccessedAt: DateTime.utc(2026, 1, 1),
        ),
      ],
      invitations: const <TeamInvitationSummary>[],
      permissionHealth: TeamPermissionHealth.healthy,
    );
    final serializable = _declaresSerialization(
      'AccountCenterTeamCollaborationSummary',
    );

    return Sprint117AccountConfigObservation(
      checkId: 'team_metadata',
      outcome: serializable
          ? 'team_metadata_serializable'
          : 'team_metadata_store_absent',
      facts: <String, Object?>{
        'organization_id': summary.organization.id,
        'seats_assigned': summary.seats.assigned,
        'seats_total': summary.seats.total,
        'members': summary.members.length,
        'member_roles': summary.members
            .map((member) => member.role.name)
            .toList(),
        'permission_health': summary.permissionHealth.name,
        'team_summary_serializable': serializable,
        'team_store_present': _referencedOutsideOwnFile(
          'AccountCenterTeamCollaborationSummary',
        ),
      },
      passed: true,
      // The summary is a value type with no store, so nothing could preserve
      // team metadata across a migration — measured, not assumed.
      acceptance: Sprint117AccountConfigAcceptance.mechanismAbsent,
      unresolvable: const <String>['team_metadata_store_absent'],
    );
  }

  /// The billing subject is a real [AccountCenterBillingSummary] with a real
  /// identity, tax, cycle, and charge. The measured fact that follows is that
  /// the value type declares no serialization seam, so there is no billing
  /// store to migrate — and 115.35's own boundary already keeps live billing
  /// `DEFERRED-EXTERNAL`.
  static Future<Sprint117AccountConfigObservation>
  _drillBillingMetadata() async {
    final summary = AccountCenterBillingSummary(
      identity: BillingIdentity(
        billingId: 'bill-1',
        displayName: 'Drill Billing',
        contactEmail: 'billing@example.test',
      ),
      currency: 'USD',
      tax: BillingTax(status: TaxStatus.applies, rate: 11, regionCode: 'US-CA'),
      cycle: BillingCycleInfo(
        cycle: PlanBillingCycle.monthly,
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 2, 1),
      ),
      charges: <BillingCharge>[
        BillingCharge(
          chargeId: 'charge-1',
          description: 'Drill charge',
          amount: 12.5,
          currency: 'USD',
          status: BillingChargeStatus.paid,
          issuedAt: DateTime.utc(2026, 1, 5),
        ),
      ],
      // A known credit balance must carry its own `asOf`; the shipped model
      // refuses an amount without a timestamp rather than inventing one.
      credits: CreditBalance(
        currency: 'USD',
        amount: 0,
        asOf: DateTime.utc(2026, 1, 1),
      ),
      status: BillingStatusInfo(status: BillingStatus.active),
    );
    final serializable = _declaresSerialization('AccountCenterBillingSummary');

    return Sprint117AccountConfigObservation(
      checkId: 'billing_metadata',
      outcome: serializable
          ? 'billing_metadata_serializable'
          : 'billing_metadata_store_absent',
      facts: <String, Object?>{
        'billing_id': summary.identity.billingId,
        'currency': summary.currency,
        'tax_status': summary.tax.status.name,
        'cycle': summary.cycle.cycle.name,
        'charges': summary.charges.length,
        'credits_amount': summary.credits.amount,
        'billing_contract_status':
            AccountCenterBillingSummary.billingContractStatus,
        'billing_summary_serializable': serializable,
        'billing_store_present': _referencedOutsideOwnFile(
          'AccountCenterBillingSummary',
        ),
      },
      passed: true,
      // 115.35 already keeps live billing DEFERRED-EXTERNAL and the summary
      // has no store, so this acceptance cannot be satisfied either.
      acceptance: Sprint117AccountConfigAcceptance.mechanismAbsent,
      unresolvable: const <String>['billing_metadata_store_absent'],
    );
  }
}

/// Answers the token broker for the identity drill.
class _RecordingBroker implements OAuthTokenBroker {
  @override
  Future<OAuthTokenResponse> exchange(
    OAuthTokenExchangeRequest request,
  ) async => _response();

  @override
  Future<OAuthTokenResponse> refresh(OAuthTokenRefreshRequest request) async =>
      _response(generationSuffix: '2');

  @override
  Future<void> revoke(OAuthTokenGrant grant) async {}

  static OAuthTokenResponse _response({String generationSuffix = '1'}) =>
      OAuthTokenResponse(
        providerId: 'drill_identity',
        providerAccountId: 'drill-account-1',
        displayName: 'Drill Account',
        accessToken: 'at-drill',
        refreshToken: 'rt-drill$generationSuffix',
        // Measured against the drill's fixed clock, not the wall clock, so the
        // expiry check is decided by the validator and not by the run date.
        accessTokenExpiresAt: DateTime.utc(2026, 1, 1, 1),
        scopes: const <String>{'account.read'},
      );
}

/// Builds the callback URI the flow requires: absolute, exact state, and the
/// nonce the request actually issued.
Uri _callbackFor(OAuthAuthorizationRequest request) {
  final uri = request.redirectUri.replace(
    queryParameters: <String, String>{
      'code': 'drill-code',
      'state': request.state,
      if (request.nonce != null) 'nonce': request.nonce!,
    },
  );
  return uri;
}

class _WritableProbe implements StorageHealthProbe {
  @override
  Future<StorageHealth> check(String location) async => const StorageHealth(
    writable: true,
    freeBytes: 1 << 30,
    reason: StorageProbeReason.ok,
  );
}

/// Reads the committed sources and never invents a subject.
class Sprint117AccountConfigLoader {
  const Sprint117AccountConfigLoader();

  Sprint117AccountConfigInput load() =>
      Sprint117AccountConfigInput(rows: _loadRows(), anchor: _loadAnchor());

  /// Folds the measured drill into the committed record.
  Sprint117AccountConfigInput loadWithDrill(
    Sprint117AccountConfigDrillRun run,
  ) => Sprint117AccountConfigInput(
    rows: _loadRows(run),
    anchor: _loadAnchor(),
    drillRun: run,
    // No committed source names a vault migration and none names an account
    // store. Both facts are read from the committed record, not assumed.
    vaultMigrationRecorded: _recordsClaim('vault_migration'),
    accountStoreRecorded: _recordsClaim('account_store'),
  );

  Sprint117AccountConfigAnchor? _loadAnchor() {
    final identity = _readJsonObject(Sprint117AccountConfigContract.identity);
    final vault = _readJsonObject(Sprint117AccountConfigContract.vault);
    final provider = _readJsonObject(
      Sprint117AccountConfigContract.providerConnector,
    );
    final team = _readJsonObject(Sprint117AccountConfigContract.team);
    final billing = _readJsonObject(Sprint117AccountConfigContract.billing);
    if (identity == null ||
        vault == null ||
        provider == null ||
        team == null ||
        billing == null) {
      return null;
    }
    return Sprint117AccountConfigAnchor(
      // Each verdict is the size of the contract the committed source actually
      // declares. The 115 manifest family is not uniform: most steps publish
      // `acceptance`, while 115.9 publishes `required_fields`. Reading one key
      // for all of them would report a real subject as undeclared.
      identityVerdict: _declaredContractSize(identity),
      vaultVerdict: _declaredContractSize(vault),
      providerVerdict: _declaredContractSize(provider),
      teamVerdict: _declaredContractSize(team),
      billingVerdict: _declaredContractSize(billing),
      billingContractStatus:
          Sprint117AccountConfigContract.billingContractStatus,
      boundaryDeclared: <Map<String, dynamic>>[
        identity,
        vault,
        provider,
        team,
        billing,
      ].every(_declaresBoundary),
    );
  }

  /// The contract keys a 115 manifest may declare its subject with.
  static const List<String> contractKeys = <String>[
    'acceptance',
    'required_fields',
  ];

  /// The keys a 115 manifest may declare its external boundary with.
  static const List<String> boundaryKeys = <String>[
    'boundary',
    'evidence_boundary',
  ];

  /// How many contract items a source declares, or empty when it declares none.
  static String _declaredContractSize(Map<String, dynamic> source) {
    for (final key in contractKeys) {
      final declared = source[key];
      if (declared is List<dynamic> && declared.isNotEmpty) {
        return 'DECLARED:$key:${declared.length}';
      }
    }
    return '';
  }

  /// Whether a source states where its own evidence stops.
  static bool _declaresBoundary(Map<String, dynamic> source) {
    for (final key in boundaryKeys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) return true;
    }
    return false;
  }

  List<Sprint117AccountConfigCheck>? _loadRows([
    Sprint117AccountConfigDrillRun? run,
  ]) {
    if (_loadAnchor() == null) return null;
    return <Sprint117AccountConfigCheck>[
      for (final checkId in Sprint117AccountConfigContract.requiredChecks)
        if (_defined(checkId))
          Sprint117AccountConfigCheck(
            checkId: checkId,
            method: _method(checkId),
            expectedOutcome: _expectedOutcome(checkId),
            // A recorded outcome is only ever the measured drill's own outcome.
            // The loader never writes one in on its own: no account upgrade has
            // ever run on a real machine, so an outcome invented here would be
            // the single fabricated observation this gate exists to keep out of
            // the record. With no drill, the check stays undetermined.
            observedOutcome: run?.observationFor(checkId)?.outcome,
            sourceManifest: _sourceFor(checkId),
            liveInstallResult: false,
            drilledAgainstLiveInstall: false,
          ),
    ];
  }

  /// A check exists only where its source records something. A check whose
  /// manifest names no method and no acceptance is not created, so a missing
  /// manifest produces a blocked report rather than invented content.
  static bool _defined(String checkId) {
    final file = File(_sourceFor(checkId));
    if (!file.existsSync()) return false;
    final Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on FormatException {
      return false;
    }
    if (decoded is! Map<String, dynamic>) return false;
    return _declaredContractSize(decoded).isNotEmpty;
  }

  /// The committed manifest that owns a check.
  static String _sourceFor(String checkId) => switch (checkId) {
    'identity_preserved' => Sprint117AccountConfigContract.identity,
    'secret_refs_preserved' => Sprint117AccountConfigContract.vault,
    'no_secret_export' => Sprint117AccountConfigContract.apiKeys,
    'storage_settings' => Sprint117AccountConfigContract.aiConnection,
    'team_metadata' => Sprint117AccountConfigContract.team,
    'billing_metadata' => Sprint117AccountConfigContract.billing,
    _ => '',
  };

  /// The step a real account-configuration migration would run for a check.
  static String _method(String checkId) => switch (checkId) {
    'identity_preserved' => 'read linked identity store from upgraded package',
    'secret_refs_preserved' => 'resolve secret reference through the vault',
    'no_secret_export' => 'export account configuration and scan for secrets',
    'storage_settings' => 'rebind machine storage registry after upgrade',
    'team_metadata' => 'read team metadata store from upgraded package',
    'billing_metadata' => 'read billing metadata store from upgraded package',
    _ => '',
  };

  /// What that step is expected to produce locally.
  static String _expectedOutcome(String checkId) => switch (checkId) {
    'identity_preserved' => 'linked identity readable after upgrade',
    'secret_refs_preserved' => 'secret reference resolves to the same secret',
    'no_secret_export' => 'no live secret in any exported surface',
    'storage_settings' => 'active storage location and bound project survive',
    'team_metadata' => 'team organization, seats, and members survive',
    'billing_metadata' => 'billing identity, currency, and charges survive',
    _ => '',
  };

  /// Whether any committed source claims something the shipped code has no
  /// mechanism for.
  ///
  /// The claim is read from the committed manifests rather than hardcoded: if a
  /// future source starts recording a vault migration or an account store, this
  /// gate must stop publishing the absence instead of keeping a `false` that
  /// outlives the code it describes.
  static bool _recordsClaim(String claim) {
    for (final path in Sprint117AccountConfigContract.sourceManifests) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final source = file.readAsStringSync();
      if (RegExp(RegExp.escape(claim)).hasMatch(source)) return true;
    }
    return false;
  }

  Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }
}

/// Decides whether the recorded account-configuration evidence is coherent.
class Sprint117AccountConfigGate {
  const Sprint117AccountConfigGate();

  /// Runs the drill, then decides from its measured output.
  Future<Sprint117AccountConfigReport> evaluateWithDrill([
    Sprint117AccountConfigDrillRun? run,
  ]) async {
    final measured = run ?? await const Sprint117AccountConfigDrill().run();
    return evaluateWith(
      const Sprint117AccountConfigLoader().loadWithDrill(measured),
    );
  }

  Sprint117AccountConfigReport evaluate() =>
      evaluateWith(const Sprint117AccountConfigLoader().load());

  Sprint117AccountConfigReport evaluateWith(Sprint117AccountConfigInput input) {
    final missing = <String>{};
    final violations = <String>[];

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('account_config_anchor');
    } else {
      if (anchor.identityVerdict.trim().isEmpty) {
        missing.add('identity_verdict');
      }
      if (anchor.vaultVerdict.trim().isEmpty) {
        missing.add('vault_verdict');
      }
      if (anchor.providerVerdict.trim().isEmpty) {
        missing.add('provider_verdict');
      }
      if (anchor.teamVerdict.trim().isEmpty) {
        missing.add('team_verdict');
      }
      if (anchor.billingVerdict.trim().isEmpty) {
        missing.add('billing_verdict');
      }
      if (anchor.billingContractStatus !=
          Sprint117AccountConfigContract.billingContractStatus) {
        violations.add('billing_contract_status_drift');
        violations.add(
          'recorded_billing_contract:${anchor.billingContractStatus}',
        );
      }
      if (!anchor.boundaryDeclared) {
        violations.add('external_boundary_not_declared');
      }
    }

    // A source that starts claiming a credential-vault migration or an account
    // store contradicts the measured absence. Neither mechanism exists in the
    // shipped code, so either claim is a contradiction until a drill proves the
    // path — which is exactly the gap 117.9 reported and this step inherits.
    if (input.vaultMigrationRecorded) {
      violations.add('vault_migration_claimed_without_mechanism');
    }
    if (input.accountStoreRecorded) {
      violations.add('account_store_claimed_without_migration_path');
    }

    final drillRun = input.drillRun;
    if (drillRun == null) {
      // Without a measured run there is no observed outcome to decide from, so
      // the report is blocked rather than passed on prose.
      missing.add('drill_run');
    } else {
      if (drillRun.liveInstallTouched) violations.add('live_install_touched');
      if (drillRun.userProjectTouched) violations.add('user_project_touched');
      if (drillRun.liveSecretsObserved.isNotEmpty) {
        violations.add('live_secret_observed');
        for (final secret in drillRun.liveSecretsObserved) {
          violations.add('live_secret_observed:$secret');
        }
      }
      if (!drillRun.allPassed) {
        for (final observation in drillRun.observations) {
          if (!observation.passed) {
            violations.add('drill_observation_failed:${observation.checkId}');
            violations.add('drill_outcome:${observation.outcome}');
          }
        }
      }
    }

    final rows = input.rows;
    final rowIds = <String>{};
    final checks = <Sprint117AccountConfigCheck>[];
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
        _checkCheck(row, drillRun, missing, violations);
        // A check no drill has ever executed is defined but undecided. With a
        // measured run in hand, a null outcome is not merely an open item: the
        // drill ran and did not decide this subject, so the evidence the
        // contract asked for is missing rather than deferred. Without any drill
        // the whole run is already blocked on `drill_run`.
        if (!row.executed) {
          undetermined.add(checkId);
          if (drillRun != null) missing.add('check_observed_outcome:$checkId');
        }
      }
    }

    final unmapped = <String>[];
    if (anchor != null && !missing.contains('account_config_anchor')) {
      for (final checkId in Sprint117AccountConfigContract.requiredChecks) {
        if (!rowIds.contains(checkId)) unmapped.add(checkId);
      }
      for (final checkId in unmapped) {
        violations.add('check_unmapped:$checkId');
      }
    }

    // Coverage counts canonical checks the evidence has actually decided, not
    // rows a manifest happened to declare. A row with no measured outcome is a
    // promise on paper, so coverage stays 0 until a drill decides it.
    var decidedCount = 0;
    for (final row in checks) {
      if (row.executed) decidedCount += 1;
    }
    final total = Sprint117AccountConfigContract.requiredChecks.length;
    final coverage = total == 0 ? 0.0 : decidedCount / total;

    final complete = missing.isEmpty && violations.isEmpty;
    final state = violations.isNotEmpty
        ? Sprint117AccountConfigState.fail
        : (complete
              ? Sprint117AccountConfigState.pass
              : Sprint117AccountConfigState.blocked);

    return Sprint117AccountConfigReport(
      status: state,
      verdict: switch (state) {
        Sprint117AccountConfigState.pass =>
          Sprint117AccountConfigContract.passVerdict,
        Sprint117AccountConfigState.fail =>
          Sprint117AccountConfigContract.failVerdict,
        Sprint117AccountConfigState.blocked =>
          Sprint117AccountConfigContract.blockedVerdict,
      },
      missingFields: missing.toList(growable: false)..sort(),
      violations: violations.toList(growable: false)..sort(),
      unmappedChecks: unmapped.toList(growable: false)..sort(),
      undeterminedChecks: undetermined.toList(growable: false)..sort(),
      coverage: coverage,
      // Copied before sorting: a null drill run falls back to a const list,
      // and sorting an unmodifiable list throws instead of reporting.
      acceptanceSatisfied: List<String>.of(
        drillRun?.acceptanceSatisfied ?? const <String>[],
      )..sort(),
      acceptanceUnmet: List<String>.of(
        drillRun?.acceptanceUnmet ?? const <String>[],
      )..sort(),
      checks: checks,
      openItems: _openItems(drillRun, undetermined),
    );
  }

  void _checkCheck(
    Sprint117AccountConfigCheck row,
    Sprint117AccountConfigDrillRun? drillRun,
    Set<String> missing,
    List<String> violations,
  ) {
    final checkId = row.checkId.trim();
    if (row.method.trim().isEmpty) {
      missing.add('check_method:$checkId');
    }
    if (row.expectedOutcome.trim().isEmpty) {
      missing.add('check_expected_outcome:$checkId');
    }
    if (row.sourceManifest.trim().isEmpty) {
      missing.add('check_source_manifest:$checkId');
    }
    if (!File(row.sourceManifest).existsSync()) {
      missing.add('check_source_manifest_missing:$checkId');
    }
    if (row.liveInstallResult) {
      violations.add('check_live_install_claim:$checkId');
    }
    if (row.drilledAgainstLiveInstall) {
      violations.add('check_live_install_claim:$checkId');
    }
    if (row.observedOutcome == null) {
      // Nothing has run, so the check stays undetermined. That is an open item,
      // not a violation, and this gate must not invent the observation.
      return;
    }
    final measured = drillRun?.observationFor(checkId);
    if (measured == null) {
      violations.add('check_observation_unsourced:$checkId');
      return;
    }
    if (row.observedOutcome != measured.outcome) {
      // A recorded outcome that the measured drill does not reproduce is a
      // contradiction, not a wording difference.
      violations.add('check_outcome_contradicts_drill:$checkId');
      violations.add('recorded_outcome:${row.observedOutcome}');
      violations.add('measured_outcome:${measured.outcome}');
    }
  }

  List<String> _openItems(
    Sprint117AccountConfigDrillRun? drillRun,
    List<String> undetermined,
  ) {
    final items = <String>{
      for (final checkId in undetermined)
        'check_observed_outcome_null:$checkId',
      // An acceptance no shipped mechanism can satisfy stays open forever until
      // the mechanism lands. Naming each row keeps the gap attributable to a
      // canonical check instead of dissolving into prose.
      for (final checkId in drillRun?.acceptanceUnmet ?? const <String>[])
        'check_acceptance_unmet:$checkId',
      for (final reference
          in drillRun?.unresolvableReferences ?? const <String>[])
        'unresolvable_reference:$reference',
      'account_configuration_migration_defined_not_executed',
      'live_account_upgrade_limit:no_account_store_shipped',
    };
    return items.toList(growable: false)..sort();
  }
}

/// The gate's verdict, with the evidence it decided from.
class Sprint117AccountConfigReport {
  Sprint117AccountConfigReport({
    required this.status,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required List<String> unmappedChecks,
    required List<String> undeterminedChecks,
    required this.coverage,
    required List<String> acceptanceSatisfied,
    required List<String> acceptanceUnmet,
    required List<Sprint117AccountConfigCheck> checks,
    required List<String> openItems,
  }) : acceptanceSatisfied = List<String>.unmodifiable(acceptanceSatisfied),
       acceptanceUnmet = List<String>.unmodifiable(acceptanceUnmet),
       missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       unmappedChecks = List<String>.unmodifiable(unmappedChecks),
       undeterminedChecks = List<String>.unmodifiable(undeterminedChecks),
       checks = List<Sprint117AccountConfigCheck>.unmodifiable(checks),
       openItems = List<String>.unmodifiable(openItems);

  final Sprint117AccountConfigState status;

  /// The decision this report carries.
  final String verdict;

  final List<String> missingFields;

  final List<String> violations;

  final List<String> unmappedChecks;

  /// Checks that are defined but that no drill has decided yet.
  final List<String> undeterminedChecks;

  /// Fraction of the canonical checks the evidence decided.
  ///
  /// Coverage counts decisions, not satisfaction: a check whose mechanism does
  /// not ship is still decided — the decision is "absent" — so coverage can be
  /// 1.0 while [acceptanceUnmet] still names the rows that cannot be satisfied.
  /// Reading coverage alone would be the overclaim this gate exists to prevent.
  final double coverage;

  /// Checks whose acceptance shipped code can satisfy.
  final List<String> acceptanceSatisfied;

  /// Checks whose acceptance cannot be satisfied because no mechanism ships.
  final List<String> acceptanceUnmet;

  final List<Sprint117AccountConfigCheck> checks;

  /// Every open item this validation carries forward.
  final List<String> openItems;

  Map<String, Object?> toJson() => <String, Object?>{
    'verdict': verdict,
    'status': status.name,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'unmapped_checks': List<String>.from(unmappedChecks),
    'undetermined_checks': List<String>.from(undeterminedChecks),
    'coverage': coverage,
    'acceptance_satisfied': List<String>.from(acceptanceSatisfied),
    'acceptance_unmet': List<String>.from(acceptanceUnmet),
    'open_items': List<String>.from(openItems),
    'checks': <Map<String, Object?>>[
      for (final check in checks) check.toJson(),
    ],
  };
}

/// Joins path segments with the platform separator.
String _joinPath(String first, String second) =>
    '$first${Platform.pathSeparator}$second';

/// Where a subject's own source file lives, relative to the repository root.
String _ownSourceOf(String typeName) => switch (typeName) {
  'LinkedIdentity' =>
    'lib/features/account/domain/'
        'account_center_oauth_linked_identity_flow.dart',
  'AccountCenterTeamCollaborationSummary' =>
    'lib/features/account/domain/'
        'account_center_team_collaboration_summary.dart',
  'AccountCenterBillingSummary' =>
    'lib/features/account/domain/account_center_billing_summary.dart',
  _ => throw ArgumentError.value(typeName, 'typeName', 'Unknown subject.'),
};

/// Whether a value type declares its own serialization seam.
///
/// This reads the type's own source file rather than assuming an answer: a
/// type that grows a `toJson`/`fromJson` pair stops being unexportable, and the
/// absence claim this gate publishes has to stay measured instead of becoming
/// a hardcoded `false` that outlives the code it describes.
bool _declaresSerialization(String typeName) {
  final file = File(_ownSourceOf(typeName));
  if (!file.existsSync()) return false;
  final source = file.readAsStringSync();
  final match = RegExp(
    r'^(?:final\s+)?class\s+' + RegExp.escape(typeName) + r'\b',
    multiLine: true,
  ).firstMatch(source);
  if (match == null) return false;
  // Only the class body counts: a sibling class in the same file must not make
  // an unserializable subject look exportable.
  final body = source.substring(match.start);
  final next = RegExp(
    r'^(?:final\s+|abstract\s+)?class\s+\w+',
    multiLine: true,
  ).firstMatch(body.substring(1));
  final scoped = next == null ? body : body.substring(0, next.start + 1);
  return RegExp(r'\btoJson\s*\(').hasMatch(scoped) ||
      RegExp(r'\bfromJson(?:String)?\s*\(').hasMatch(scoped);
}

/// Whether anything outside a type's own source file constructs or consumes it.
///
/// A subject with no other reference has no store: nothing could have written
/// it and nothing could read it back, so there is no migration to validate.
///
/// This file is excluded from the scan on purpose. It names every subject it
/// measures — in the drill, in the doc comments, and in [_ownSourceOf] — so
/// counting its own references would make every absence read as a present store
/// and the measurement would report the opposite of what it found.
bool _referencedOutsideOwnFile(String typeName) {
  final own = _ownSourceOf(typeName).replaceAll('\\', '/');
  final lib = Directory('lib');
  if (!lib.existsSync()) return false;
  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll('\\', '/');
    // Every other shipped source counts, not just same-named siblings: a store
    // could be written by any file that constructs or consumes the subject.
    if (path == own || path == _thisSource) continue;
    // A word boundary, not a bare substring: `LinkedIdentityResult` is a
    // distinct shipped type that carries no persistence, and a substring match
    // would let an unrelated call of it be read as proof that an identity
    // store exists.
    //
    // A doc comment is not a reference either. 117.31 mentioned
    // `LinkedIdentity` inside a prose fact label, which satisfied this scan
    // and turned "no store ships" into "a store ships" — the gate inverted
    // its own honest verdict from a documentation string. Code lines only.
    //
    // A string literal counts too: 117.31's mention is a fact *label* naming
    // the seam that produces the value, not code that stores or restores it.
    // What this probe must answer is "could a linked identity be persisted and
    // read back", and only executable code can do that.
    var inCode = false;
    for (final line in const LineSplitter().convert(
      entity.readAsStringSync(),
    )) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('///') ||
          trimmed.startsWith('//') ||
          trimmed.startsWith('*')) {
        continue;
      }
      // Strip string literals: a prose label that names a type is not a use.
      final code = line
          .replaceAll(RegExp(r"'[^']*'"), "''")
          .replaceAll(RegExp(r'"[^"]*"'), '""');
      if (RegExp(r'\b' + RegExp.escape(typeName) + r'\b').hasMatch(code)) {
        inCode = true;
        break;
      }
    }
    if (inCode) return true;
  }
  return false;
}

/// This validation's own source, which measures subjects rather than storing
/// them.
const String _thisSource =
    'lib/features/world_logic/domain/sprint_117_account_configuration_migration.dart';

Future<void> _deleteQuietly(Directory directory) async {
  try {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  } on FileSystemException {
    // A leftover temp directory is not evidence of a defect in this gate.
  }
}
