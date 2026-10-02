/// Canonical step 117.20 — Security Center Workflow Validation.
///
/// Objective (external canonical JSON): test MFA, password, trusted devices,
/// sessions, revoke, alerts, secure-store health, and recovery.
///
/// The eight evidence items are the ways a security surface can report a
/// healthy account that is not one, so the check and the drill are separate
/// classes, exactly as 117.5-117.19 did:
///
/// * [Sprint117SecurityCenterWorkflowDrill] really executes the shipped
///   mechanisms in [AccountCenterSecuritySummary] and
///   [AccountCenterSessionDeviceManagement]. It writes nothing, opens no user
///   project, contacts no identity provider, and every session, device, and
///   alert it names is a locally constructed fixture.
/// * [Sprint117SecurityCenterWorkflowLoader] reads the committed manifests and
///   the external files they pin, and never invents a check or an outcome.
/// * [Sprint117SecurityCenterWorkflowGate] decides whether the recorded
///   evidence is coherent, synchronously and without side effects.
///
/// Four facts are measured rather than assumed, and all four shape the
/// verdict:
///
/// 1. `overallStatus` failed OPEN. It returned `healthy` as soon as any single
///    signal was healthy, so an account with MFA enrolled and four signals it
///    could not read at all — password, devices, sessions, secure store — was
///    reported as a fully healthy account. An `info` alert alone was enough to
///    reach the same verdict, because `info` maps to `healthy`. The drill
///    re-measures all of it, so a regression in either direction fails here.
/// 2. No shipped file aggregates the session seam into a session summary, so
///    `sessions.activeCount` / `suspiciousCount` are caller assertions. The
///    drill measures the seam directly and reports the missing aggregation.
/// 3. The session seam had no audit collection, so a refused revoke (revoking
///    the current session, force-logout without confirmation) and an attempt
///    never made were indistinguishable. That is exactly the gap the spec's
///    `audit_redaction` guarantee has nothing to apply to.
/// 4. `MfaSecuritySummary.recoveryCodesRemaining` is carried but nothing reads
///    it, so a drained recovery path is invisible. Reported as an open item
///    rather than dressed up as a delivered recovery flow.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:void_scriptor/features/account/domain/account_center_security_summary.dart';
import 'package:void_scriptor/features/account/domain/account_center_session_device_management.dart';

part 'sprint_117_security_center_workflow_drill.dart';

enum Sprint117SecurityCenterWorkflowState { pass, fail, blocked }

/// Immutable description of the contract, its sources, and its verdicts.
abstract final class Sprint117SecurityCenterWorkflowContract {
  static const String canonicalStep = '117.20';

  /// 115.32 supplies the Security Center summary: mfa, password health,
  /// trusted devices, sessions, secure-store health, alerts, actions.
  static const String securityCenterSummary =
      'docs/planning/v1.2/sprint_115_security_center_summary.json';

  /// 116.40 is the security certification gate the charter question for this
  /// step points at, so the area under test has a recorded standard.
  static const String securityCertificationGate =
      'docs/planning/v1.2/sprint_116_security_certification_gate.json';

  /// 115.33 supplies the session and device management seam the revoke and
  /// session checks exercise.
  static const String sessionDeviceManagement =
      'docs/planning/v1.2/sprint_115_session_device_management.json';

  /// Every committed source this validation decides from.
  static const List<String> sourceManifests = <String>[
    securityCenterSummary,
    securityCertificationGate,
    sessionDeviceManagement,
  ];

  /// The external files the committed manifests pin, with the sha256 they
  /// record. A pin that no longer matches is a contradiction of every decision
  /// derived from it, so it is measured, never assumed.
  static const Map<String, String> externalPins = <String, String>{
    'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
            'sprint_116.json':
        '94418211f73b9b318d57749a26bf8e6f1e92afb6c8942b2b003c99d6cef0e809',
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
            'referenced-chatgpt-conversation-this-is-an-2/outputs/'
            'account_cloud_center_spec.json':
        'f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a',
  };

  static const String passVerdict = 'SECURITY_CENTER_WORKFLOW_VALIDATED_LOCAL';
  static const String blockedVerdict =
      'SECURITY_CENTER_WORKFLOW_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'SECURITY_CENTER_WORKFLOW_INCONSISTENT';

  /// The eight evidence items canonical step 117.20 names, in canonical order.
  static const List<String> requiredChecks = <String>[
    'mfa',
    'password',
    'devices',
    'sessions',
    'revoke',
    'alerts',
    'secure_store',
    'recovery',
  ];
}

/// One canonical evidence row, as the committed manifests declare it.
class Sprint117SecurityCenterWorkflowCheck {
  Sprint117SecurityCenterWorkflowCheck({
    required this.checkId,
    required this.method,
    required this.expectedOutcome,
    required this.observedOutcome,
    required this.sourceManifest,
    required this.liveProviderResult,
    required this.drilledAgainstLiveProvider,
  });

  /// The canonical check identity, e.g. `secure_store`.
  final String checkId;

  /// The step this validation runs. Empty means the check only wishes for it.
  final String method;

  /// What the method is expected to produce locally.
  final String expectedOutcome;

  /// What the local drill actually produced. Null while no drill has run.
  final String? observedOutcome;

  /// The upstream manifest that defines this check.
  final String sourceManifest;

  /// Whether a live provider produced this outcome. It never has.
  final bool liveProviderResult;

  /// Whether the check ran against a live provider. It never did.
  final bool drilledAgainstLiveProvider;

  bool get executed =>
      observedOutcome != null && observedOutcome!.trim().isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'check_id': checkId,
    'method': method,
    'expected_outcome': expectedOutcome,
    'observed_outcome': observedOutcome,
    'executed': executed,
    'source_manifest': sourceManifest,
    'live_provider_result': liveProviderResult,
    'drilled_against_live_provider': drilledAgainstLiveProvider,
  };
}

/// The evidence this validation is allowed to decide from.
class Sprint117SecurityCenterWorkflowAnchor {
  Sprint117SecurityCenterWorkflowAnchor({
    required Map<String, String> declaredContractSizes,
    required Map<String, bool> boundariesDeclared,
    required this.securityAcceptanceDeclared,
    required this.mfaAcceptanceDeclared,
    required this.passwordAcceptanceDeclared,
    required this.devicesAcceptanceDeclared,
    required this.sessionsAcceptanceDeclared,
    required this.secureStoreAcceptanceDeclared,
    required this.alertsAcceptanceDeclared,
    required this.actionsAcceptanceDeclared,
    required this.reauthBeforeSensitiveActionDeclared,
    required this.auditRedactionDeclared,
    required this.neverFullSecretDisplayDeclared,
    required this.clipboardTimeoutDeclared,
    required this.osSecureStoreDeclared,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
  }) : declaredContractSizes = Map<String, String>.unmodifiable(
         declaredContractSizes,
       ),
       boundariesDeclared = Map<String, bool>.unmodifiable(boundariesDeclared);

  /// How many contract items each committed source declares, by path.
  final Map<String, String> declaredContractSizes;

  /// Whether each committed source states where its own evidence stops.
  final Map<String, bool> boundariesDeclared;

  /// Whether 115.32 declares all seven of its own acceptance items.
  final bool securityAcceptanceDeclared;
  final bool mfaAcceptanceDeclared;
  final bool passwordAcceptanceDeclared;
  final bool devicesAcceptanceDeclared;
  final bool sessionsAcceptanceDeclared;
  final bool secureStoreAcceptanceDeclared;
  final bool alertsAcceptanceDeclared;
  final bool actionsAcceptanceDeclared;

  /// Whether the product spec declares reauth before a sensitive action.
  final bool reauthBeforeSensitiveActionDeclared;

  /// Whether the product spec declares audit redaction.
  final bool auditRedactionDeclared;

  /// Whether the product spec forbids displaying a full secret.
  final bool neverFullSecretDisplayDeclared;

  /// Whether the product spec declares a clipboard timeout.
  final bool clipboardTimeoutDeclared;

  /// Whether the product spec names the OS secure store.
  final bool osSecureStoreDeclared;

  final int externalPinsMatched;
  final int externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117SecurityCenterWorkflowContract.externalPins.length;

  bool get allExternalPinsMatch =>
      externalPinsResolved && externalPinsMatched == externalPinsChecked;
}

/// The decided-versus-observed input the gate reasons about.
class Sprint117SecurityCenterWorkflowInput {
  const Sprint117SecurityCenterWorkflowInput({
    this.rows,
    this.anchor,
    this.drillRun,
    this.externalPinDrift = false,
  });

  final List<Sprint117SecurityCenterWorkflowCheck>? rows;
  final Sprint117SecurityCenterWorkflowAnchor? anchor;
  final Sprint117SecurityCenterWorkflowDrillRun? drillRun;

  /// Whether an external pin no longer matches what its manifest recorded.
  final bool externalPinDrift;
}

/// Whether a canonical acceptance could be satisfied by shipped code at all.
enum Sprint117SecurityCenterWorkflowAcceptance { satisfied, mechanismAbsent }

/// One measured local observation behind a canonical check.
class Sprint117SecurityCenterWorkflowObservation {
  Sprint117SecurityCenterWorkflowObservation({
    required this.checkId,
    required this.outcome,
    required Map<String, Object?> facts,
    required this.passed,
    this.acceptance = Sprint117SecurityCenterWorkflowAcceptance.satisfied,
    this.unresolvable = const <String>[],
  }) : facts = Map<String, Object?>.unmodifiable(facts);

  /// The canonical check this observation decides.
  final String checkId;

  /// Exactly what the executed method produced.
  final String outcome;

  /// The measured values behind [outcome]. Never a restatement of the prose.
  final Map<String, Object?> facts;

  /// Whether the shipped mechanism behaved as the canonical source requires.
  final bool passed;

  /// Whether shipped code can satisfy this acceptance at all.
  final Sprint117SecurityCenterWorkflowAcceptance acceptance;

  /// References this validation could not resolve, reported rather than
  /// silently dropped.
  final List<String> unresolvable;

  Map<String, Object?> toJson() => <String, Object?>{
    'check_id': checkId,
    'outcome': outcome,
    'passed': passed,
    'acceptance': acceptance.name,
    'facts': Map<String, Object?>.from(facts),
    'unresolvable': List<String>.from(unresolvable),
  };
}

/// Everything one measured run produced.
class Sprint117SecurityCenterWorkflowDrillRun {
  Sprint117SecurityCenterWorkflowDrillRun({
    required List<Sprint117SecurityCenterWorkflowObservation> observations,
    required this.liveProviderTouched,
    required this.userProjectTouched,
    required this.liveCredentialObserved,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
    this.productionCallerPresent = true,
    this.securitySummaryProductionCallSites = -1,
    this.sessionManagementProductionCallSites = -1,
    this.revocationAuditPresent = true,
    this.recoveryCodeLifecycleCallSites = -1,
    this.sessionSummaryAggregatedSomewhere = true,
    this.passwordStalenessComputedSomewhere = true,
    this.deviceTrustAggregatedSomewhere = true,
  }) : observations =
           List<Sprint117SecurityCenterWorkflowObservation>.unmodifiable(
             observations,
           );

  final List<Sprint117SecurityCenterWorkflowObservation> observations;

  /// Whether any identity provider or network endpoint was contacted. Never.
  final bool liveProviderTouched;

  /// Whether any user project was opened. It never is.
  final bool userProjectTouched;

  /// Whether any real credential was observed. It never is.
  final bool liveCredentialObserved;

  final int externalPinsMatched;
  final int externalPinsChecked;

  /// Whether any production file outside this acceptance harness imports the
  /// security summary this slice validates.
  ///
  /// Defaults to true so a hand-built run is never charged with an integration
  /// gap it never measured; only the repository scan can clear it.
  final bool productionCallerPresent;

  /// Measured call sites for the security summary, or -1 when unmeasured.
  final int securitySummaryProductionCallSites;

  /// Measured call sites for the session seam, or -1 when unmeasured.
  final int sessionManagementProductionCallSites;

  /// Whether any shipped file records a session revocation.
  final bool revocationAuditPresent;

  /// Measured recovery-code lifecycle call sites, or -1 when unmeasured.
  final int recoveryCodeLifecycleCallSites;

  /// Whether any shipped file aggregates the session seam into a
  /// `SessionSecuritySummary`.
  final bool sessionSummaryAggregatedSomewhere;

  /// Whether any shipped file decides a password date is stale.
  final bool passwordStalenessComputedSomewhere;

  /// Whether any shipped file builds a device summary from session trust.
  final bool deviceTrustAggregatedSomewhere;

  /// The aggregation gaps this run measured, by name.
  ///
  /// Derived from the scans above rather than written as prose in the report, so
  /// the two can never disagree: a gap that the scan says is still absent is
  /// always reported, and a gap that the scan says is closed never is.
  List<String> get measuredAggregationGaps => <String>[
    if (!passwordStalenessComputedSomewhere)
      'password_staleness_not_computed_in_lib',
    if (!deviceTrustAggregatedSomewhere) 'device_trust_not_aggregated_in_lib',
    if (!sessionSummaryAggregatedSomewhere)
      'session_summary_caller_supplied_not_computed',
  ];

  bool get allPassed => observations.every((entry) => entry.passed);

  bool get allExternalPinsMatchForDrill =>
      externalPinsChecked > 0 && externalPinsMatched == externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117SecurityCenterWorkflowContract.externalPins.length;

  List<String> get acceptanceSatisfied => <String>[
    for (final entry in observations)
      if (entry.acceptance ==
          Sprint117SecurityCenterWorkflowAcceptance.satisfied)
        entry.checkId,
  ];

  List<String> get acceptanceUnmet => <String>[
    for (final entry in observations)
      if (entry.acceptance ==
          Sprint117SecurityCenterWorkflowAcceptance.mechanismAbsent)
        entry.checkId,
  ];

  List<String> get unresolvableReferences => <String>[
    for (final entry in observations) ...entry.unresolvable,
  ];

  Sprint117SecurityCenterWorkflowObservation? observationFor(String checkId) {
    for (final entry in observations) {
      if (entry.checkId == checkId) return entry;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'live_provider_touched': liveProviderTouched,
    'user_project_touched': userProjectTouched,
    'live_credential_observed': liveCredentialObserved,
    'external_pins_matched': externalPinsMatched,
    'external_pins_checked': externalPinsChecked,
    'production_caller_present': productionCallerPresent,
    'security_summary_production_call_sites':
        securitySummaryProductionCallSites,
    'session_management_production_call_sites':
        sessionManagementProductionCallSites,
    'revocation_audit_present': revocationAuditPresent,
    'recovery_code_lifecycle_call_sites': recoveryCodeLifecycleCallSites,
    'session_summary_aggregated_somewhere': sessionSummaryAggregatedSomewhere,
    'password_staleness_computed_somewhere': passwordStalenessComputedSomewhere,
    'device_trust_aggregated_somewhere': deviceTrustAggregatedSomewhere,
    'measured_aggregation_gaps': List<String>.from(measuredAggregationGaps),
    'observations': <Map<String, Object?>>[
      for (final entry in observations) entry.toJson(),
    ],
  };
}

/// Reads the committed manifests and never invents a subject.
class Sprint117SecurityCenterWorkflowLoader {
  const Sprint117SecurityCenterWorkflowLoader();

  Sprint117SecurityCenterWorkflowInput load() =>
      Sprint117SecurityCenterWorkflowInput(
        rows: _loadRows(null),
        anchor: _loadAnchor(),
      );

  Sprint117SecurityCenterWorkflowInput loadWithDrill(
    Sprint117SecurityCenterWorkflowDrillRun run,
  ) => Sprint117SecurityCenterWorkflowInput(
    rows: _loadRows(run),
    anchor: _loadAnchor(),
    drillRun: run,
    externalPinDrift:
        run.externalPinsResolved && !run.allExternalPinsMatchForDrill,
  );

  /// One row per canonical check, sourced from the committed manifests.
  ///
  /// A manifest that cannot be read yields no row for its checks, so the gate
  /// reports them unmapped rather than the harness inventing a green row.
  ///
  /// The measured outcome is folded in here rather than only in the gate: a row
  /// whose outcome is never populated reports every canonical check as
  /// undetermined and holds coverage at 0.0 even after a real drill has run.
  static List<Sprint117SecurityCenterWorkflowCheck> _loadRows(
    Sprint117SecurityCenterWorkflowDrillRun? run,
  ) {
    final summary = _readJsonFile(
      Sprint117SecurityCenterWorkflowContract.securityCenterSummary,
    );
    final gate = _readJsonFile(
      Sprint117SecurityCenterWorkflowContract.securityCertificationGate,
    );
    final sessions = _readJsonFile(
      Sprint117SecurityCenterWorkflowContract.sessionDeviceManagement,
    );

    // Which committed manifest speaks for each canonical check, and which of
    // the source acceptance items it must actually declare. Both are measured
    // below rather than asserted, so a manifest that stops declaring its own
    // acceptance is reported instead of being trusted.
    const owner = <String, String>{
      'mfa': Sprint117SecurityCenterWorkflowContract.securityCenterSummary,
      'password': Sprint117SecurityCenterWorkflowContract.securityCenterSummary,
      'devices': Sprint117SecurityCenterWorkflowContract.securityCenterSummary,
      'sessions': Sprint117SecurityCenterWorkflowContract.securityCenterSummary,
      'revoke': Sprint117SecurityCenterWorkflowContract.sessionDeviceManagement,
      'alerts': Sprint117SecurityCenterWorkflowContract.securityCenterSummary,
      'secure_store':
          Sprint117SecurityCenterWorkflowContract.securityCenterSummary,
      'recovery': Sprint117SecurityCenterWorkflowContract.securityCenterSummary,
    };

    final acceptanceOf = <String, List<String>>{
      Sprint117SecurityCenterWorkflowContract.securityCenterSummary:
          (summary?['acceptance'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>(),
      Sprint117SecurityCenterWorkflowContract.securityCertificationGate:
          (gate?['acceptance'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>(),
      Sprint117SecurityCenterWorkflowContract.sessionDeviceManagement:
          (sessions?['acceptance'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>(),
    };

    final declaredBy = <String, bool>{};
    for (final entry in acceptanceOf.entries) {
      for (final item in entry.value) {
        declaredBy[item] = true;
      }
    }

    final methodBy = <String, String>{
      'mfa': 'execute_shipped_mfa_summary',
      'password': 'execute_shipped_password_summary',
      'devices': 'execute_shipped_device_summary',
      'sessions': 'execute_shipped_session_seam',
      'revoke': 'execute_shipped_revoke_path',
      'alerts': 'execute_shipped_overall_status',
      'secure_store': 'execute_shipped_secure_store_summary',
      'recovery': 'execute_shipped_recovery_signal',
    };

    final rows = <Sprint117SecurityCenterWorkflowCheck>[];
    for (final checkId
        in Sprint117SecurityCenterWorkflowContract.requiredChecks) {
      final manifest = owner[checkId]!;
      if (!declaredBy.containsKey(_acceptanceItemFor(checkId))) {
        // The owning manifest is unreadable or no longer declares this item;
        // the row stays undetermined so coverage cannot be claimed.
        continue;
      }
      rows.add(
        Sprint117SecurityCenterWorkflowCheck(
          checkId: checkId,
          method: methodBy[checkId]!,
          expectedOutcome: 'measured_${checkId}_from_shipped_mechanism',
          observedOutcome: run?.observationFor(checkId)?.outcome,
          sourceManifest: manifest,
          liveProviderResult: false,
          drilledAgainstLiveProvider: false,
        ),
      );
    }
    return rows;
  }

  /// How many contract items a source declares, or empty when it declares none.
  ///
  /// Key names are read from the sources themselves, so a manifest that spells
  /// its coverage `acceptance_areas` is not reported as declaring nothing.
  static String _declaredContractSize(Map<String, dynamic> source) {
    for (final key in const <String>[
      'acceptance',
      'acceptance_areas',
      'acceptance_invariants',
      'acceptance_coverage',
      'required_fields',
      'required_states',
      'required_outputs',
      'sections',
    ]) {
      final declared = source[key];
      if (declared is List<dynamic> && declared.isNotEmpty) {
        return 'DECLARED:$key:${declared.length}';
      }
      if (declared is Map<String, dynamic> && declared.isNotEmpty) {
        return 'DECLARED:$key:${declared.length}';
      }
    }
    final records = source['records'];
    if (records is List<dynamic> && records.isNotEmpty) {
      return 'DECLARED:records:${records.length}';
    }
    return '';
  }

  /// Whether a source states where its own evidence stops.
  ///
  /// A manifest that never says where its evidence stops cannot be used to
  /// decide that a check is complete, and 116.45 spells that limit
  /// `limitations` where 115.32 and 115.33 spell it `boundary`.
  static bool _declaresBoundary(Map<String, dynamic> source) {
    for (final key in const <String>[
      'boundary',
      'evidence_boundary',
      'external_gates',
      'limitations',
    ]) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) return true;
      if (value is List<dynamic> && value.isNotEmpty) return true;
      if (value is Map<String, dynamic> && value.isNotEmpty) return true;
    }
    for (final key in const <String>[
      'evidence_limits',
      'deferred_scope',
      'deferred_external',
    ]) {
      final value = source[key];
      if (value is List<dynamic> && value.isNotEmpty) return true;
      if (value is Map<String, dynamic> && value.isNotEmpty) return true;
    }
    return false;
  }

  /// The source acceptance item a canonical check maps to, read from the
  /// committed manifest rather than invented here.
  static String _acceptanceItemFor(String checkId) => switch (checkId) {
    'mfa' => 'mfa',
    'password' => 'password_health',
    'devices' => 'trusted_devices',
    'sessions' => 'sessions',
    'revoke' => 'sessions',
    'alerts' => 'alerts',
    'secure_store' => 'secure_store_health',
    'recovery' => 'mfa',
    // A new canonical check must not silently borrow another check's contract
    // item: an unmapped id has to show up as unmapped instead of deciding
    // itself from whatever the last case happened to name.
    _ => throw ArgumentError.value(
      checkId,
      'checkId',
      'No source acceptance item is mapped for this canonical check.',
    ),
  };

  static Sprint117SecurityCenterWorkflowAnchor? _loadAnchor() {
    final summary = _readJsonFile(
      Sprint117SecurityCenterWorkflowContract.securityCenterSummary,
    );
    final gate = _readJsonFile(
      Sprint117SecurityCenterWorkflowContract.securityCertificationGate,
    );
    final sessions = _readJsonFile(
      Sprint117SecurityCenterWorkflowContract.sessionDeviceManagement,
    );
    if (summary == null || gate == null || sessions == null) return null;

    final spec = _readJsonFile(
      Sprint117SecurityCenterWorkflowContract.externalPins.keys.last,
    );
    final contract =
        (spec?['security_contract'] as Map<String, dynamic>?) ?? const {};
    final secrets = (contract['secrets'] as List<dynamic>? ?? const <dynamic>[])
        .cast<String>();
    final sensitive =
        (contract['sensitive_actions'] as List<dynamic>? ?? const <dynamic>[])
            .cast<String>();
    // Read rather than discarded: the guarantees above are what the spec
    // promises for every one of these actions, so an empty list would mean the
    // guarantees are attached to nothing.
    if (sensitive.isEmpty) {
      return null;
    }

    final declaredSizes = <String, String>{};
    final boundaries = <String, bool>{};
    for (final entry in <String, Map<String, dynamic>?>{
      Sprint117SecurityCenterWorkflowContract.securityCenterSummary: summary,
      Sprint117SecurityCenterWorkflowContract.securityCertificationGate: gate,
      Sprint117SecurityCenterWorkflowContract.sessionDeviceManagement: sessions,
    }.entries) {
      final manifest = entry.value!;
      // Key names are read from the sources themselves, not from the names
      // this harness first guessed: 116.45 spells its coverage
      // `acceptance_areas` and its limits `limitations`, while 115.32 and
      // 115.33 spell theirs `acceptance` and `boundary`. Demanding one shape
      // of all three reported a healthy manifest as silent — the same false
      // zero 117.16, 117.17 and 117.19 each hit on this harness family.
      declaredSizes[entry.key] = _declaredContractSize(manifest);
      boundaries[entry.key] = _declaresBoundary(manifest);
    }

    final summaryAcceptance =
        (summary['acceptance'] as List<dynamic>?)?.cast<String>() ??
        const <String>[];

    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117SecurityCenterWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }

    return Sprint117SecurityCenterWorkflowAnchor(
      declaredContractSizes: declaredSizes,
      boundariesDeclared: boundaries,
      securityAcceptanceDeclared: summaryAcceptance.length == 7,
      mfaAcceptanceDeclared: summaryAcceptance.contains('mfa'),
      passwordAcceptanceDeclared: summaryAcceptance.contains('password_health'),
      devicesAcceptanceDeclared: summaryAcceptance.contains('trusted_devices'),
      sessionsAcceptanceDeclared: summaryAcceptance.contains('sessions'),
      secureStoreAcceptanceDeclared: summaryAcceptance.contains(
        'secure_store_health',
      ),
      alertsAcceptanceDeclared: summaryAcceptance.contains('alerts'),
      actionsAcceptanceDeclared: summaryAcceptance.contains('actions'),
      reauthBeforeSensitiveActionDeclared: secrets.contains(
        'reauth_before_sensitive_action',
      ),
      auditRedactionDeclared: secrets.contains('audit_redaction'),
      neverFullSecretDisplayDeclared: secrets.contains(
        'never_full_secret_display',
      ),
      clipboardTimeoutDeclared: secrets.contains('clipboard_timeout'),
      osSecureStoreDeclared: secrets.contains('os_secure_store'),
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }
}

/// Decides coherence. Synchronous, side-effect free.
class Sprint117SecurityCenterWorkflowGate {
  const Sprint117SecurityCenterWorkflowGate();

  /// Runs the drill, then decides from its measured output.
  Future<Sprint117SecurityCenterWorkflowReport> evaluateWithDrill([
    Sprint117SecurityCenterWorkflowDrillRun? run,
  ]) async {
    final measured =
        run ?? await const Sprint117SecurityCenterWorkflowDrill().run();
    return evaluateWith(
      const Sprint117SecurityCenterWorkflowLoader().loadWithDrill(measured),
    );
  }

  Sprint117SecurityCenterWorkflowReport evaluate() =>
      evaluateWith(const Sprint117SecurityCenterWorkflowLoader().load());

  Sprint117SecurityCenterWorkflowReport evaluateWith(
    Sprint117SecurityCenterWorkflowInput input,
  ) {
    final missing = <String>{};
    final violations = <String>{};

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('security_center_anchor');
    } else {
      for (final entry in anchor.declaredContractSizes.entries) {
        if (entry.value.trim().isEmpty) {
          missing.add('contract_not_declared:${entry.key}');
        }
      }
      for (final entry in anchor.boundariesDeclared.entries) {
        if (!entry.value) {
          violations.add('external_boundary_not_declared:${entry.key}');
        }
      }
      if (!anchor.securityAcceptanceDeclared) {
        missing.add('security_center_acceptance');
      }
      if (!anchor.mfaAcceptanceDeclared) missing.add('mfa_acceptance');
      if (!anchor.passwordAcceptanceDeclared) {
        missing.add('password_health_acceptance');
      }
      if (!anchor.devicesAcceptanceDeclared) {
        missing.add('trusted_devices_acceptance');
      }
      if (!anchor.sessionsAcceptanceDeclared) {
        missing.add('sessions_acceptance');
      }
      if (!anchor.secureStoreAcceptanceDeclared) {
        missing.add('secure_store_health_acceptance');
      }
      if (!anchor.alertsAcceptanceDeclared) missing.add('alerts_acceptance');
      if (!anchor.actionsAcceptanceDeclared) missing.add('actions_acceptance');
      if (!anchor.reauthBeforeSensitiveActionDeclared) {
        missing.add('reauth_before_sensitive_action_acceptance');
      }
      if (!anchor.auditRedactionDeclared) {
        missing.add('audit_redaction_acceptance');
      }
      if (!anchor.neverFullSecretDisplayDeclared) {
        missing.add('never_full_secret_display_acceptance');
      }
      if (!anchor.clipboardTimeoutDeclared) {
        missing.add('clipboard_timeout_acceptance');
      }
      if (!anchor.osSecureStoreDeclared) {
        missing.add('os_secure_store_acceptance');
      }
      if (!anchor.externalPinsResolved) {
        missing.add('external_pin_unreadable');
      } else if (!anchor.allExternalPinsMatch) {
        violations.add('external_source_drift');
      }
    }

    // An external file whose hash no longer matches the committed pin
    // contradicts every decision derived from it, whether the loader saw it
    // or only the drill did.
    if (input.externalPinDrift) violations.add('external_source_drift');

    final drillRun = input.drillRun;
    if (drillRun == null) {
      // Without a measured run there is no observed outcome to decide from, so
      // the report is blocked rather than passed on prose.
      missing.add('drill_run');
    } else {
      if (drillRun.liveProviderTouched) violations.add('live_provider_touched');
      if (drillRun.userProjectTouched) violations.add('user_project_touched');
      if (drillRun.liveCredentialObserved) {
        violations.add('live_credential_observed');
      }
      if (drillRun.externalPinsResolved &&
          !drillRun.allExternalPinsMatchForDrill) {
        violations.add('external_source_drift');
      }
      if (!drillRun.allPassed) {
        for (final observation in drillRun.observations) {
          if (!observation.passed) {
            violations.add('drill_observation_failed:${observation.checkId}');
            violations.add('drill_outcome:${observation.outcome}');
          }
        }
      }
      // A check whose own recorded fact says the mechanism is absent must not
      // also be reported as acceptance-satisfied: the two claims contradict.
      for (final observation in drillRun.observations) {
        if (!observation.passed) continue;
        final mechanism = observation.facts['acceptance_mechanism_present'];
        if (mechanism == false &&
            observation.acceptance ==
                Sprint117SecurityCenterWorkflowAcceptance.satisfied) {
          violations.add(
            'acceptance_claimed_without_mechanism:${observation.checkId}',
          );
        }
      }
    }

    final rows = input.rows;
    final rowIds = <String>{};
    final checks = <Sprint117SecurityCenterWorkflowCheck>[];
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
        if (!row.executed) {
          undetermined.add(checkId);
          if (drillRun != null) {
            missing.add('check_observed_outcome:$checkId');
          }
        }
      }
    }

    final unmapped = <String>[];
    if (anchor != null && !missing.contains('security_center_anchor')) {
      for (final checkId
          in Sprint117SecurityCenterWorkflowContract.requiredChecks) {
        if (!rowIds.contains(checkId)) unmapped.add(checkId);
      }
      for (final checkId in unmapped) {
        violations.add('check_unmapped:$checkId');
      }
    }

    // Coverage counts canonical checks the evidence has actually decided, not
    // rows a manifest happened to declare. Without an anchor nothing is bound
    // to a committed source, so nothing counts as decided however green the
    // rows look: a full-coverage report would otherwise be reachable while the
    // evidence it claims to rest on is unreadable.
    final anchorResolved =
        anchor != null && !missing.contains('security_center_anchor');
    var decidedCount = 0;
    for (final row in checks) {
      if (row.executed && anchorResolved) decidedCount += 1;
    }
    final total = Sprint117SecurityCenterWorkflowContract.requiredChecks.length;
    final coverage = total == 0 ? 0.0 : decidedCount / total;

    final complete = missing.isEmpty && violations.isEmpty;
    final state = violations.isNotEmpty
        ? Sprint117SecurityCenterWorkflowState.fail
        : (complete
              ? Sprint117SecurityCenterWorkflowState.pass
              : Sprint117SecurityCenterWorkflowState.blocked);

    return Sprint117SecurityCenterWorkflowReport(
      status: state,
      verdict: switch (state) {
        Sprint117SecurityCenterWorkflowState.pass =>
          Sprint117SecurityCenterWorkflowContract.passVerdict,
        Sprint117SecurityCenterWorkflowState.fail =>
          Sprint117SecurityCenterWorkflowContract.failVerdict,
        Sprint117SecurityCenterWorkflowState.blocked =>
          Sprint117SecurityCenterWorkflowContract.blockedVerdict,
      },
      missingFields: missing.toList(growable: false)..sort(),
      violations: violations.toList(growable: false)..sort(),
      // Canonical order, not alphabetical, so a reader can match the report
      // against the canonical evidence list position by position.
      unmappedChecks: _inCanonicalOrderOf(unmapped),
      undeterminedChecks: _inCanonicalOrderOf(undetermined),
      coverage: coverage,
      // Canonical order for both, so a reader can line the report up against
      // the canonical evidence list position by position instead of comparing
      // two differently sorted lists.
      acceptanceSatisfied: _inCanonicalOrderOf(
        drillRun?.acceptanceSatisfied ?? const <String>[],
      ),
      acceptanceUnmet: _inCanonicalOrderOf(
        drillRun?.acceptanceUnmet ?? const <String>[],
      ),
      checks: checks,
      anchor: anchor,
      openItems: _openItems(drillRun, anchor),
    );
  }

  static void _checkCheck(
    Sprint117SecurityCenterWorkflowCheck row,
    Sprint117SecurityCenterWorkflowDrillRun? drillRun,
    Set<String> missing,
    Set<String> violations,
  ) {
    if (row.method.trim().isEmpty) {
      missing.add('check_method:${row.checkId}');
    }
    if (row.expectedOutcome.trim().isEmpty) {
      missing.add('check_expected_outcome:${row.checkId}');
    }
    if (row.sourceManifest.trim().isEmpty) {
      missing.add('check_source_manifest:${row.checkId}');
    }
    // A row that claims a live provider result, or a drill that claims to
    // have run against one, is a claim this local validation cannot make.
    if (row.liveProviderResult) {
      violations.add('check_live_provider_claimed:${row.checkId}');
    }
    if (row.drilledAgainstLiveProvider) {
      violations.add('check_drill_live_provider_claimed:${row.checkId}');
    }
    if (drillRun != null && row.executed) {
      final observation = drillRun.observationFor(row.checkId);
      if (observation == null) {
        missing.add('check_observation_absent:${row.checkId}');
      } else if (!observation.passed) {
        violations.add('check_observation_failed:${row.checkId}');
      }
    }
  }

  /// Every external gate this validation cannot close locally, plus every
  /// measured integration gap, reported rather than folded into a pass.
  static List<String> _openItems(
    Sprint117SecurityCenterWorkflowDrillRun? drillRun,
    Sprint117SecurityCenterWorkflowAnchor? anchor,
  ) {
    final items = <String>[
      'live_identity_provider_mfa_enrollment',
      'live_secure_store_backend_verification',
      'live_session_inventory_and_revoke_propagation',
      'force_logout_execution_against_real_sessions',
      'alert_delivery_channel',
      'recovery_code_issue_and_consume_lifecycle',
      'hosted_ci_signing_publication',
    ];
    // Every gap the drill measured is carried on the run itself, so an open
    // item can be derived from a measured fact rather than from prose. A gap
    // that is measured and then left out of the report is one that gets
    // forgotten, so the two aggregation gaps are named explicitly here and the
    // drill records whether each is still absent.
    for (final gap in drillRun?.measuredAggregationGaps ?? const <String>[]) {
      items.add(gap);
    }
    if (drillRun != null) {
      if (!drillRun.productionCallerPresent) {
        items.add('security_summary_defined_not_reachable_from_lib');
      }
      if (drillRun.securitySummaryProductionCallSites > 0) {
        items.add('security_summary_production_call_sites_measured');
      }
      if (drillRun.sessionManagementProductionCallSites > 0) {
        items.add('session_seam_production_call_sites_measured');
      }
      if (!drillRun.revocationAuditPresent) {
        items.add('session_revocation_audit_absent_in_repository');
      }
      if (drillRun.recoveryCodeLifecycleCallSites > 0) {
        items.add('recovery_code_lifecycle_call_sites_measured');
      }
      if (!drillRun.sessionSummaryAggregatedSomewhere) {
        items.add('session_summary_caller_supplied_not_computed');
      }
    }
    if (anchor != null && anchor.allExternalPinsMatch) {
      items.add('external_pins_match');
    }
    return items;
  }

  static List<String> _inCanonicalOrderOf(List<String> ids) {
    final wanted = ids.toSet();
    return <String>[
      for (final id in Sprint117SecurityCenterWorkflowContract.requiredChecks)
        if (wanted.contains(id)) id,
    ];
  }
}

class Sprint117SecurityCenterWorkflowReport {
  Sprint117SecurityCenterWorkflowReport({
    required this.status,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required List<String> unmappedChecks,
    required List<String> undeterminedChecks,
    required this.coverage,
    required List<String> acceptanceSatisfied,
    required List<String> acceptanceUnmet,
    required List<Sprint117SecurityCenterWorkflowCheck> checks,
    required this.anchor,
    required List<String> openItems,
  }) : acceptanceSatisfied = List<String>.unmodifiable(acceptanceSatisfied),
       acceptanceUnmet = List<String>.unmodifiable(acceptanceUnmet),
       missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       unmappedChecks = List<String>.unmodifiable(unmappedChecks),
       undeterminedChecks = List<String>.unmodifiable(undeterminedChecks),
       checks = List<Sprint117SecurityCenterWorkflowCheck>.unmodifiable(checks),
       openItems = List<String>.unmodifiable(openItems);

  final Sprint117SecurityCenterWorkflowState status;

  /// The decision this report carries.
  final String verdict;

  final List<String> missingFields;
  final List<String> violations;
  final List<String> unmappedChecks;

  /// Checks that are defined but that no drill has decided yet.
  final List<String> undeterminedChecks;

  /// Fraction of the canonical checks the evidence decided.
  final double coverage;

  /// Canonical acceptances shipped code satisfies.
  final List<String> acceptanceSatisfied;

  /// Canonical acceptances shipped code cannot satisfy, reported rather than
  /// folded into a passing row.
  final List<String> acceptanceUnmet;

  final List<Sprint117SecurityCenterWorkflowCheck> checks;
  final Sprint117SecurityCenterWorkflowAnchor? anchor;

  /// What this report leaves open, including every deferred external gate.
  final List<String> openItems;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117SecurityCenterWorkflowContract.canonicalStep,
    'status': status.name,
    'verdict': verdict,
    'coverage': coverage,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'unmapped_checks': List<String>.from(unmappedChecks),
    'undetermined_checks': List<String>.from(undeterminedChecks),
    'acceptance_satisfied': List<String>.from(acceptanceSatisfied),
    'acceptance_unmet': List<String>.from(acceptanceUnmet),
    'open_items': List<String>.from(openItems),
    'checks': <Map<String, Object?>>[
      for (final entry in checks) entry.toJson(),
    ],
    'anchor': anchor == null
        ? null
        : <String, Object?>{
            'declared_contract_sizes': Map<String, String>.from(
              anchor!.declaredContractSizes,
            ),
            'boundaries_declared': Map<String, bool>.from(
              anchor!.boundariesDeclared,
            ),
            'security_acceptance_declared': anchor!.securityAcceptanceDeclared,
            'mfa_acceptance_declared': anchor!.mfaAcceptanceDeclared,
            'password_acceptance_declared': anchor!.passwordAcceptanceDeclared,
            'devices_acceptance_declared': anchor!.devicesAcceptanceDeclared,
            'sessions_acceptance_declared': anchor!.sessionsAcceptanceDeclared,
            'secure_store_acceptance_declared':
                anchor!.secureStoreAcceptanceDeclared,
            'alerts_acceptance_declared': anchor!.alertsAcceptanceDeclared,
            'actions_acceptance_declared': anchor!.actionsAcceptanceDeclared,
            'reauth_before_sensitive_action_declared':
                anchor!.reauthBeforeSensitiveActionDeclared,
            'audit_redaction_declared': anchor!.auditRedactionDeclared,
            'never_full_secret_display_declared':
                anchor!.neverFullSecretDisplayDeclared,
            'clipboard_timeout_declared': anchor!.clipboardTimeoutDeclared,
            'os_secure_store_declared': anchor!.osSecureStoreDeclared,
            'external_pins_matched': anchor!.externalPinsMatched,
            'external_pins_checked': anchor!.externalPinsChecked,
          },
  };
}

Map<String, dynamic>? _readJsonFile(String path) {
  if (path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

String? _sha256OfFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    return sha256.convert(file.readAsBytesSync()).toString();
  } on FileSystemException {
    return null;
  }
}
