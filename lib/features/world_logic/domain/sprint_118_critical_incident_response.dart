/// Fail-closed critical incident response log for roadmap step 118.23 --
/// Critical Incident Response.
///
/// Objective (external canonical `sprint_118.json`): handle account takeover,
/// token leak, payment error, data loss, privacy leak, sync corruption, or
/// crash loop. The canonical required-output list is exactly eight items:
/// `containment`, `connector_disable`, `user_protection`, `root_cause`, `fix`,
/// `tests`, `advisory`, and `rollback`.
///
/// This is the response plan the delayed corrective path (Sprint 118 on
/// `GA_DELAYED`) keeps *before* any live incident arrives. The gate answers a
/// single question: does the declared plan carry, for every canonical incident
/// class, a response record with all eight required outputs non-blank, a known
/// owner, a committed readable evidence source -- and does every record stop
/// short of claiming a live incident response that no release ever ran?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A response plan
///   built on a baseline that did not freeze answers incidents nobody measured.
/// * The committed 118.2 charter anchor must be a genuine complete charter
///   (`pass` on `CHARTER_COMPLETE_LOCAL`). A plan written outside the frozen
///   stability charter has no window to belong to.
/// * The committed 117.6 support-incident-readiness witness must be a genuine
///   readiness pass (`SUPPORT_INCIDENT_READINESS_DEFINED_LOCAL`). A plan that
///   is not anchored to a committed severity/owner plan cannot be triaged.
/// * The plan's release state must agree with the baseline anchor.
/// * On the delayed path no live incident may be claimed: neither the committed
///   readiness witness may report an executed incident nor any response record
///   may claim a live response.
/// * Every canonical incident class must be present exactly once, and each
///   record must carry all eight required outputs non-blank, must name an
///   accountable owner, and must cite a committed, readable evidence source.
/// * **A response is never claimed live without a release.** Every record
///   declares a reference response, and the gate refuses any record that treats
///   that reference as a live incident response.
///
/// The owner vocabulary is *derived from the committed 117.6 readiness witness*
/// (its `owners`), and the response-output vocabulary is *grounded in the
/// committed 114.28 P0 critical security response witness* (its
/// `required_outputs`) and the committed 116.50 staged-beta rollout monitoring
/// witness (its provider kill-switch `scope` values), not copied by hand, so
/// the plan and its witnesses cannot drift apart silently.
///
/// Live incident execution, support channels, on-call rotation, provider
/// escalation, connector certification, provider exposure, release
/// authorization, and publication remain `DEFERRED-EXTERNAL`; this plan freezes
/// local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a response-plan evaluation can rest in. `blocked` is the
/// honest resting state for "this plan cannot yet be trusted", and it is
/// distinct from `fail`, which means the plan contradicts its own evidence.
enum Sprint118IncidentResponseState { pass, fail, blocked }

/// One response record: the declared plan for a single canonical incident class,
/// with the eight required outputs it must carry.
///
/// `liveIncidentClaimed` is deliberately *not* one of the eight required
/// outputs; it is the flag the gate refuses when set, so that a reference
/// response can be recorded while never being read as a live incident response.
class Sprint118IncidentResponseEntry {
  const Sprint118IncidentResponseEntry({
    required this.incidentClass,
    required this.incidentId,
    required this.containment,
    required this.connectorDisable,
    required this.userProtection,
    required this.rootCause,
    required this.fix,
    required this.tests,
    required this.advisory,
    required this.rollback,
    required this.owner,
    required this.evidence,
    this.liveIncidentClaimed = false,
  });

  /// The canonical incident class this record responds to, drawn from the class
  /// vocabulary.
  final String incidentClass;

  /// The stable identifier of the declared response. Stable and declared; no
  /// live incident is implied.
  final String incidentId;

  /// How the incident would be contained. On the delayed path this is the
  /// reference containment marker; no live containment ran.
  final String containment;

  /// How the offending connector would be disabled. On the delayed path this is
  /// the reference marker; no connector was disabled.
  final String connectorDisable;

  /// How affected users would be protected. On the delayed path this is the
  /// reference marker; no user was notified.
  final String userProtection;

  /// The determined root cause. On the delayed path this is the reference
  /// classification marker; no live root cause has been determined.
  final String rootCause;

  /// The fix. On the delayed path this is the reference marker; no fix shipped.
  final String fix;

  /// The tests that would prove the fix. On the delayed path this is the
  /// reference marker; no test executed.
  final String tests;

  /// The user advisory. On the delayed path this is the reference marker; no
  /// advisory was published.
  final String advisory;

  /// The rollback plan. On the delayed path this is the reference marker; no
  /// rollback executed.
  final String rollback;

  /// Who owns the response, drawn from the owner vocabulary.
  final String owner;

  /// The committed evidence source for this class. Must be readable.
  final String evidence;

  /// Whether this record claims a live incident response. The gate refuses
  /// `true`: a response is never claimed live without a release.
  final bool liveIncidentClaimed;

  /// The eight required outputs as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get outputs => <String, String>{
    'containment': containment,
    'connector_disable': connectorDisable,
    'user_protection': userProtection,
    'root_cause': rootCause,
    'fix': fix,
    'tests': tests,
    'advisory': advisory,
    'rollback': rollback,
  };
}

/// The declared response plan. `entries` is the response surface for the
/// delayed corrective path; on that path no record may claim a live response.
class Sprint118IncidentResponsePlan {
  const Sprint118IncidentResponsePlan({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118IncidentResponseEntry> entries;

  List<String> get incidentClasses => <String>[
    for (final entry in entries) entry.incidentClass,
  ];

  List<String> get incidentIds => <String>[
    for (final entry in entries) entry.incidentId,
  ];
}

/// What the committed witnesses actually say. A plan is only as honest as the
/// witnesses it reads.
class Sprint118IncidentResponseAnchor {
  const Sprint118IncidentResponseAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.readinessState,
    required this.readinessVerdict,
    required this.liveIncidentExecuted,
    required this.owners,
    required this.p0Outputs,
    required this.connectorDisableScopes,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final String readinessState;
  final String readinessVerdict;

  /// Whether the committed readiness witness claims an incident was executed.
  /// On the delayed path this must stay `false`.
  final bool liveIncidentExecuted;

  /// The owner vocabulary the committed 117.6 readiness witness declares.
  final List<String> owners;

  /// The response-output vocabulary the committed 114.28 P0 critical security
  /// response witness declares.
  final List<String> p0Outputs;

  /// The connector-disable scope vocabulary the committed 116.50 staged-beta
  /// rollout monitoring witness declares.
  final List<String> connectorDisableScopes;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the plan is well-formed; `blocked` means
/// it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118IncidentResponseReport {
  const Sprint118IncidentResponseReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingOutputs = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredClasses = const <String>[],
    this.responseCount = 0,
  });

  final Sprint118IncidentResponseState state;
  final String verdict;
  final String releaseState;
  final List<String> missingOutputs;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredClasses;
  final int responseCount;

  /// Whether the plan may be treated as well-formed. Only a genuine `pass`
  /// allows it.
  bool get planVerified => state == Sprint118IncidentResponseState.pass;

  String get externalGates => Sprint118IncidentResponseContract.externalGates;
}

/// The fixed vocabulary of step 118.23, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118IncidentResponseContract {
  const Sprint118IncidentResponseContract._();

  static const String canonicalStep = '118.23';
  static const String title = 'Critical Incident Response';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_critical_incident_response.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this plan is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter this plan is anchored to.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 117.6 support incident readiness witness that declares the
  /// owner vocabulary and the live-incident signal.
  static const String readinessManifestPath =
      'docs/planning/v1.3/sprint_117_support_incident_readiness.json';

  /// The committed 114.28 P0 critical security response witness that declares
  /// the response-output vocabulary.
  static const String p0ManifestPath =
      'docs/planning/v1.2/sprint_114_p0_critical_security_response.json';

  /// The committed 116.50 staged-beta rollout monitoring witness that declares
  /// the connector-disable scope vocabulary.
  static const String rolloutManifestPath =
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  /// The verdict and state the 117.6 readiness witness must carry.
  static const String requiredReadinessVerdict =
      'SUPPORT_INCIDENT_READINESS_DEFINED_LOCAL';
  static const String requiredReadinessState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The product version the plan is declared against.
  static const String baseVersion = '1.3.1';

  /// The eight canonical required outputs from `sprint_118.json` step 118.23.
  static const List<String> requiredOutputs = <String>[
    'containment',
    'connector_disable',
    'user_protection',
    'root_cause',
    'fix',
    'tests',
    'advisory',
    'rollback',
  ];

  /// The seven canonical incident classes the objective names.
  static const List<String> incidentClasses = <String>[
    'account_takeover',
    'token_leak',
    'payment_error',
    'data_loss',
    'privacy_leak',
    'sync_corruption',
    'crash_loop',
  ];

  /// The reference output markers an entry declares when no live incident has
  /// occurred. On the delayed path these are the only honest outputs.
  static const String referenceContainment = 'reference_containment_not_live';
  static const String referenceConnectorDisable =
      'reference_connector_disable_not_live';
  static const String referenceUserProtection =
      'reference_user_protection_not_live';
  static const String referenceRootCause =
      'reference_root_cause_not_determined';
  static const String referenceFix = 'reference_fix_not_applied';
  static const String referenceTests = 'reference_tests_not_executed';
  static const String referenceAdvisory = 'reference_advisory_not_published';
  static const String referenceRollback = 'reference_rollback_not_executed';

  /// The accountable incident-response owner, drawn from the committed 117.6
  /// readiness owner vocabulary. The gate verifies membership against the
  /// witness.
  static const String responseOwner = 'Choirudin';

  /// The committed evidence source registered for each canonical class.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
    'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json',
    'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
    'docs/planning/v1.2/sprint_113_incident_stop_ship_protocol.json',
    'docs/planning/v1.3/sprint_118_privacy_safe_observation.json',
    'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json',
    'docs/planning/v1.2/sprint_114_crash_startup_health.json',
  ];

  /// The evidence source registered for a canonical class.
  static String sourceFor(String incidentClass) {
    final index = incidentClasses.indexOf(incidentClass);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// Whether a witness vocabulary grounds a canonical output. A witness grounds
  /// an output when it names it exactly, when one of its compound tokens is the
  /// output (e.g. `rollback_or_patch` grounds `rollback`), or when it contains
  /// the output as a substring (e.g. the `connector_disable` kill-switch
  /// scope).
  static bool grounds(List<String> vocabulary, String output) {
    for (final token in vocabulary) {
      if (token == output) return true;
      if (token.contains(output)) return true;
      if (token.split('_').contains(output)) return true;
    }
    return false;
  }

  /// The canonical response plan, declared here as the single source of truth.
  /// The gate evaluates exactly this object, and the emitter writes exactly
  /// this object, so the record cannot be made to agree with itself. With the
  /// release delayed, every record registers a reference response and claims no
  /// live incident.
  static const Sprint118IncidentResponsePlan
  canonicalPlan = Sprint118IncidentResponsePlan(
    releaseState: delayedReleaseState,
    entries: <Sprint118IncidentResponseEntry>[
      Sprint118IncidentResponseEntry(
        incidentClass: 'account_takeover',
        incidentId: 'RESPONSE-ACCOUNT-TAKEOVER-REF',
        containment: referenceContainment,
        connectorDisable: referenceConnectorDisable,
        userProtection: referenceUserProtection,
        rootCause: referenceRootCause,
        fix: referenceFix,
        tests: referenceTests,
        advisory: referenceAdvisory,
        rollback: referenceRollback,
        owner: responseOwner,
        evidence:
            'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
      ),
      Sprint118IncidentResponseEntry(
        incidentClass: 'token_leak',
        incidentId: 'RESPONSE-TOKEN-LEAK-REF',
        containment: referenceContainment,
        connectorDisable: referenceConnectorDisable,
        userProtection: referenceUserProtection,
        rootCause: referenceRootCause,
        fix: referenceFix,
        tests: referenceTests,
        advisory: referenceAdvisory,
        rollback: referenceRollback,
        owner: responseOwner,
        evidence:
            'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json',
      ),
      Sprint118IncidentResponseEntry(
        incidentClass: 'payment_error',
        incidentId: 'RESPONSE-PAYMENT-ERROR-REF',
        containment: referenceContainment,
        connectorDisable: referenceConnectorDisable,
        userProtection: referenceUserProtection,
        rootCause: referenceRootCause,
        fix: referenceFix,
        tests: referenceTests,
        advisory: referenceAdvisory,
        rollback: referenceRollback,
        owner: responseOwner,
        evidence:
            'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
      ),
      Sprint118IncidentResponseEntry(
        incidentClass: 'data_loss',
        incidentId: 'RESPONSE-DATA-LOSS-REF',
        containment: referenceContainment,
        connectorDisable: referenceConnectorDisable,
        userProtection: referenceUserProtection,
        rootCause: referenceRootCause,
        fix: referenceFix,
        tests: referenceTests,
        advisory: referenceAdvisory,
        rollback: referenceRollback,
        owner: responseOwner,
        evidence:
            'docs/planning/v1.2/sprint_113_incident_stop_ship_protocol.json',
      ),
      Sprint118IncidentResponseEntry(
        incidentClass: 'privacy_leak',
        incidentId: 'RESPONSE-PRIVACY-LEAK-REF',
        containment: referenceContainment,
        connectorDisable: referenceConnectorDisable,
        userProtection: referenceUserProtection,
        rootCause: referenceRootCause,
        fix: referenceFix,
        tests: referenceTests,
        advisory: referenceAdvisory,
        rollback: referenceRollback,
        owner: responseOwner,
        evidence: 'docs/planning/v1.3/sprint_118_privacy_safe_observation.json',
      ),
      Sprint118IncidentResponseEntry(
        incidentClass: 'sync_corruption',
        incidentId: 'RESPONSE-SYNC-CORRUPTION-REF',
        containment: referenceContainment,
        connectorDisable: referenceConnectorDisable,
        userProtection: referenceUserProtection,
        rootCause: referenceRootCause,
        fix: referenceFix,
        tests: referenceTests,
        advisory: referenceAdvisory,
        rollback: referenceRollback,
        owner: responseOwner,
        evidence:
            'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json',
      ),
      Sprint118IncidentResponseEntry(
        incidentClass: 'crash_loop',
        incidentId: 'RESPONSE-CRASH-LOOP-REF',
        containment: referenceContainment,
        connectorDisable: referenceConnectorDisable,
        userProtection: referenceUserProtection,
        rootCause: referenceRootCause,
        fix: referenceFix,
        tests: referenceTests,
        advisory: referenceAdvisory,
        rollback: referenceRollback,
        owner: responseOwner,
        evidence: 'docs/planning/v1.2/sprint_114_crash_startup_health.json',
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, 117.6 readiness witness,
/// 114.28 P0 response witness, and 116.50 rollout monitoring witness. Never
/// invents: an unreadable witness yields `null`, which the gate reports as
/// blocked rather than as a pass.
class Sprint118IncidentResponseLoader {
  const Sprint118IncidentResponseLoader();

  Sprint118IncidentResponseAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118IncidentResponseContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(
      Sprint118IncidentResponseContract.charterManifestPath,
    );
    if (charter == null) return null;
    final readiness = _readJsonObject(
      Sprint118IncidentResponseContract.readinessManifestPath,
    );
    if (readiness == null) return null;
    final p0 = _readJsonObject(
      Sprint118IncidentResponseContract.p0ManifestPath,
    );
    if (p0 == null) return null;
    final rollout = _readJsonObject(
      Sprint118IncidentResponseContract.rolloutManifestPath,
    );
    if (rollout == null) return null;

    final readable = <String>[
      for (final source in Sprint118IncidentResponseContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118IncidentResponseAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      readinessState: _text(readiness['state']),
      readinessVerdict: _text(readiness['verdict']),
      liveIncidentExecuted: readiness['live_incident_executed'] == true,
      owners: _stringList(readiness['owners']),
      p0Outputs: _stringList(p0['required_outputs']),
      connectorDisableScopes: _killSwitchScopes(
        rollout['provider_kill_switches'],
      ),
      readableSources: readable,
    );
  }

  static List<String> _killSwitchScopes(Object? value) {
    if (value is List) {
      return <String>[
        for (final item in value)
          if (item is Map && item['scope'] is String) item['scope'] as String,
      ];
    }
    return const <String>[];
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return <String>[
        for (final item in value)
          if (item is String) item,
      ];
    }
    return const <String>[];
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

  static String _text(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }
}

class Sprint118IncidentResponseGate {
  const Sprint118IncidentResponseGate();

  /// Evaluate the canonical plan against committed evidence. This is the entry
  /// point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118IncidentResponseReport evaluate() => evaluateWith(
    const Sprint118IncidentResponseLoader().loadAnchor(),
    Sprint118IncidentResponseContract.canonicalPlan,
  );

  Sprint118IncidentResponseReport evaluateWith(
    Sprint118IncidentResponseAnchor? anchor,
    Sprint118IncidentResponsePlan plan,
  ) {
    if (anchor == null) {
      return Sprint118IncidentResponseReport(
        state: Sprint118IncidentResponseState.blocked,
        verdict: 'SPRINT_118_RESPONSE_EVIDENCE_UNREADABLE',
        releaseState: plan.releaseState,
        missingOutputs: List<String>.from(
          Sprint118IncidentResponseContract.requiredOutputs,
        ),
        blockers: const <String>['committed_response_evidence_unreadable'],
        openItems: const <String>['committed_response_evidence_unreadable'],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A plan
    // written against an unfrozen baseline answers incidents nobody measured.
    if (anchor.baselineState !=
            Sprint118IncidentResponseContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118IncidentResponseContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState !=
            Sprint118IncidentResponseContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118IncidentResponseContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (3) The 117.6 readiness witness must be a genuine pass. A plan that is
    // not anchored to a committed severity/owner plan cannot be triaged.
    if (anchor.readinessState !=
            Sprint118IncidentResponseContract.requiredReadinessState ||
        anchor.readinessVerdict !=
            Sprint118IncidentResponseContract.requiredReadinessVerdict) {
      blockers.add('readiness_not_defined:${anchor.readinessVerdict}');
    }

    // (4) The release state must agree with the baseline anchor.
    if (anchor.releaseState != plan.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'plan=${plan.releaseState}',
      );
    }

    // (5) On the delayed path no live incident may be claimed.
    final delayed =
        plan.releaseState ==
        Sprint118IncidentResponseContract.delayedReleaseState;
    if (delayed && anchor.liveIncidentExecuted) {
      violations.add('live_incident_claimed_executed_without_release');
    }

    // (6) The witness vocabularies must actually be present, so the plan has
    // something to derive its owner and output vocabularies from.
    if (anchor.owners.isEmpty) {
      openItems.add('upstream_owner_vocabulary_missing');
    }
    if (anchor.p0Outputs.isEmpty) {
      openItems.add('upstream_p0_output_vocabulary_missing');
    }
    if (anchor.connectorDisableScopes.isEmpty) {
      openItems.add('upstream_connector_disable_vocabulary_missing');
    }
    // Every canonical output must be grounded in a committed witness, not a
    // hand-copied list that can drift away from it.
    for (final output in Sprint118IncidentResponseContract.requiredOutputs) {
      final grounded =
          Sprint118IncidentResponseContract.grounds(anchor.p0Outputs, output) ||
          Sprint118IncidentResponseContract.grounds(
            anchor.connectorDisableScopes,
            output,
          );
      if (!grounded) {
        openItems.add('output_not_grounded_in_witness:$output');
      }
    }

    // (7) Every canonical class must be present exactly once, and each record
    // must carry all eight required outputs non-blank, a known owner, and a
    // committed readable evidence source.
    final declared = <String, int>{};
    for (final entry in plan.entries) {
      declared[entry.incidentClass] = (declared[entry.incidentClass] ?? 0) + 1;
    }
    for (final entry in plan.entries) {
      final incidentClass = entry.incidentClass;
      if (!Sprint118IncidentResponseContract.incidentClasses.contains(
        incidentClass,
      )) {
        violations.add('response_class_unknown:$incidentClass');
      }
      for (final output in Sprint118IncidentResponseContract.requiredOutputs) {
        final value = entry.outputs[output] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$output:$incidentClass');
        }
      }
      if (!anchor.owners.contains(entry.owner)) {
        violations.add('entry_unknown_owner:$incidentClass:${entry.owner}');
      }
      if (!anchor.readableSources.contains(entry.evidence)) {
        violations.add(
          'entry_unreadable_evidence:$incidentClass:${entry.evidence}',
        );
      }
      // A response is never claimed live without a release.
      if (entry.liveIncidentClaimed) {
        violations.add('live_incident_claimed_without_release:$incidentClass');
      }
    }
    for (final incidentClass in declared.keys) {
      if (declared[incidentClass]! > 1) {
        violations.add('response_class_duplicate:$incidentClass');
      }
    }
    for (final incidentClass
        in Sprint118IncidentResponseContract.incidentClasses) {
      if (!declared.containsKey(incidentClass)) {
        violations.add('response_class_missing:$incidentClass');
      }
    }

    // (8) Every committed evidence source must be readable.
    for (final source
        in Sprint118IncidentResponseContract.canonicalSources.toSet()) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final classes = plan.incidentClasses;

    if (violations.isNotEmpty) {
      return Sprint118IncidentResponseReport(
        state: Sprint118IncidentResponseState.fail,
        verdict: 'SPRINT_118_CRITICAL_INCIDENT_RESPONSE_VIOLATION',
        releaseState: plan.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredClasses: classes,
        responseCount: plan.entries.length,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118IncidentResponseReport(
        state: Sprint118IncidentResponseState.blocked,
        verdict: 'SPRINT_118_RESPONSE_BLOCKED_UPSTREAM',
        releaseState: plan.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredClasses: classes,
        responseCount: plan.entries.length,
      );
    }
    return Sprint118IncidentResponseReport(
      state: Sprint118IncidentResponseState.pass,
      verdict: 'CRITICAL_INCIDENT_RESPONSE_VERIFIED_LOCAL',
      releaseState: plan.releaseState,
      openItems: allOpen,
      declaredClasses: classes,
      responseCount: plan.entries.length,
    );
  }
}
