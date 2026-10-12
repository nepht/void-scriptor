/// Fail-closed entry gate for Sprint 119.1.
///
/// Sprint 119 is an ecosystem/connector SDK expansion. Its canonical start
/// condition is stronger than a local Sprint 118 pass: the Account Center
/// must be stable and the built-in certification process must be proven. This
/// gate reads the committed witnesses and keeps the active sprint unchanged
/// when either condition is only documented or deferred externally.
library;

import 'dart:convert';
import 'dart:io';

import 'github_app_release_authorization.dart';

enum Sprint119EntryGateState { pass, fail, blocked }

/// The six evidence dimensions required by canonical Sprint 119 step 119.1.
abstract final class Sprint119EntryContract {
  const Sprint119EntryContract._();

  static const String canonicalStep = '119.1';
  static const String activeSprint = '118';
  static const String nextStep = canonicalStep;
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_entry_gate.json';
  static const String externalAccountCenterObservationPath =
      'docs/evidence/account-center-live-observation-20261011.json';
  static const String correctiveScopeApprovalPath =
      'docs/planning/v1.3/sprint_118_corrective_scope_approval.json';

  static const Set<String> correctiveOnlyBlockers = <String>{
    'sprint_118_readiness_not_expansion_ready',
    'stable_account_center_not_proven_external',
    'certification_examples_missing',
  };

  static const List<String> requiredEvidence = <String>[
    'sprint_118_readiness',
    'stable_account_center',
    'certification_examples',
    'incident_status',
    'security_constraints',
    'support_capacity',
  ];

  /// One canonical witness per dimension. The loader never treats a missing
  /// path as consent; an unreadable set blocks the entry.
  static const Map<String, String> requiredSources = <String, String>{
    'sprint_118_readiness': 'docs/planning/v1.3/sprint_119_readiness_gate.json',
    'stable_account_center':
        'docs/planning/v1.3/sprint_118_stability_expansion_report.json',
    'certification_examples':
        'docs/planning/v1.3/sprint_118_versioned_connector_certification.json',
    'incident_status':
        'docs/planning/v1.3/sprint_118_critical_incident_response.json',
    'security_constraints':
        'docs/planning/v1.2/sprint_116_security_certification_gate.json',
    'support_capacity':
        'docs/planning/v1.3/sprint_118_incident_support_intake.json',
  };

  static const String closurePath =
      'docs/planning/v1.3/sprint_118_sprint_closure.json';
  static const String snapshotPath =
      'docs/planning/v1.3/sprint_118_certified_connector_snapshot.json';
  static const String expansionAcceptancePath =
      'docs/planning/v1.3/sprint_118_expansion_acceptance_gate.json';
  static const String securityHealthPath =
      'docs/planning/v1.3/sprint_118_security_health_review.json';

  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.3/sprint_119_readiness_gate.json',
    'docs/planning/v1.3/sprint_118_stability_expansion_report.json',
    'docs/planning/v1.3/sprint_118_versioned_connector_certification.json',
    'docs/planning/v1.3/sprint_118_critical_incident_response.json',
    'docs/planning/v1.2/sprint_116_security_certification_gate.json',
    'docs/planning/v1.3/sprint_118_incident_support_intake.json',
    closurePath,
    snapshotPath,
    expansionAcceptancePath,
    securityHealthPath,
    'test/features/account/presentation/account_cloud_center_screen_test.dart',
    'test/features/account/presentation/account_cloud_center_visual_regression_test.dart',
    'test/features/account/application/account_cloud_connect_wiring_test.dart',
    correctiveScopeApprovalPath,
    externalAccountCenterObservationPath,
  ];
}

/// A loader result deliberately contains only facts that can be read from
/// committed witnesses. Synthetic all-proven evidence exists solely for unit
/// tests of the decision function; it is never used by the emitter.
class Sprint119EntryEvidence {
  const Sprint119EntryEvidence({
    required this.sprint118ReadinessProven,
    required this.stableAccountCenterProven,
    required this.certificationExamplesProven,
    required this.incidentStatusDocumented,
    required this.securityConstraintsDocumented,
    required this.supportCapacityDocumented,
    required this.certifiedProviderCount,
    required this.correctiveScopeApproved,
    required this.readinessDecision,
    required this.sourcePaths,
    this.notes = const <String>[],
  });

  final bool sprint118ReadinessProven;
  final bool stableAccountCenterProven;
  final bool certificationExamplesProven;
  final bool incidentStatusDocumented;
  final bool securityConstraintsDocumented;
  final bool supportCapacityDocumented;
  final int certifiedProviderCount;
  final bool correctiveScopeApproved;
  final String readinessDecision;
  final List<String> sourcePaths;
  final List<String> notes;

  factory Sprint119EntryEvidence.allProven({
    bool certificationExamplesProven = true,
    int certifiedProviderCount = 1,
    bool correctiveScopeApproved = false,
    String readinessDecision = 'CONNECTOR_ECOSYSTEM',
  }) {
    return Sprint119EntryEvidence(
      sprint118ReadinessProven: true,
      stableAccountCenterProven: true,
      certificationExamplesProven: certificationExamplesProven,
      incidentStatusDocumented: true,
      securityConstraintsDocumented: true,
      supportCapacityDocumented: true,
      certifiedProviderCount: certifiedProviderCount,
      correctiveScopeApproved: correctiveScopeApproved,
      readinessDecision: readinessDecision,
      sourcePaths: Sprint119EntryContract.canonicalSources,
    );
  }
}

class Sprint119EntryEvidenceLoader {
  const Sprint119EntryEvidenceLoader();

  Sprint119EntryEvidence? load() {
    final readiness = _readJson(
      Sprint119EntryContract.requiredSources['sprint_118_readiness']!,
    );
    final stability = _readJson(
      Sprint119EntryContract.requiredSources['stable_account_center']!,
    );
    final certification = _readJson(
      Sprint119EntryContract.requiredSources['certification_examples']!,
    );
    final incident = _readJson(
      Sprint119EntryContract.requiredSources['incident_status']!,
    );
    final security = _readJson(
      Sprint119EntryContract.requiredSources['security_constraints']!,
    );
    final support = _readJson(
      Sprint119EntryContract.requiredSources['support_capacity']!,
    );
    final closure = _readJson(Sprint119EntryContract.closurePath);
    final snapshot = _readJson(Sprint119EntryContract.snapshotPath);
    final acceptance = _readJson(
      Sprint119EntryContract.expansionAcceptancePath,
    );
    final securityHealth = _readJson(Sprint119EntryContract.securityHealthPath);
    final correctiveScope = _readJson(
      Sprint119EntryContract.correctiveScopeApprovalPath,
    );
    final authorization = GithubAppReleaseAuthorization.load();
    final externalAccountCenter = _readJson(
      Sprint119EntryContract.externalAccountCenterObservationPath,
    );

    if (<Map<String, dynamic>?>[
      readiness,
      stability,
      certification,
      incident,
      security,
      support,
      closure,
      snapshot,
      acceptance,
      securityHealth,
      correctiveScope,
    ].any((value) => value == null)) {
      return null;
    }

    final readinessDoc = readiness!;
    final stabilityDoc = stability!;
    final certificationDoc = certification!;
    final incidentDoc = incident!;
    final securityDoc = security!;
    final supportDoc = support!;
    final closureDoc = closure!;
    final snapshotDoc = snapshot!;
    final acceptanceDoc = acceptance!;
    final securityHealthDoc = securityHealth!;
    final correctiveScopeDoc = correctiveScope!;

    final certifiedCount = _firstInt(<Object?>[
      certificationDoc['certified_count'],
      snapshotDoc['certified_count'],
      acceptanceDoc['certified_count'],
      readinessDoc['certified_count'],
    ]);

    final readinessDecision = readinessDoc['readiness_decision'];
    final correctiveScopeApproved =
        correctiveScopeDoc['status'] == 'CORRECTIVE_SCOPE_APPROVED' &&
        correctiveScopeDoc['corrective_scope_approved'] == true &&
        correctiveScopeDoc['release_state'] == 'GA_DELAYED';

    final readinessReady =
        readinessDoc['state'] == 'pass' &&
        readinessDoc['readiness_verified'] == true &&
        readinessDoc['readiness_decision'] == 'CONNECTOR_ECOSYSTEM' &&
        readinessDoc['execution_authorized'] == true &&
        readinessDoc['release_blocked'] != true;

    final stabilityReady =
        stabilityDoc['state'] == 'pass' &&
        (closureDoc['decision'] == 'closedLocal' ||
            closureDoc['decision'] == 'closedLocalDeferredExternal') &&
        _externalAccountCenterObservationReady(externalAccountCenter);

    final certificationReady =
        authorization != null &&
        certificationDoc['state'] == 'pass' &&
        certificationDoc['release_blocked'] != true &&
        certifiedCount > 0 &&
        acceptanceDoc['certified_count'] is num &&
        (acceptanceDoc['certified_count'] as num) > 0;

    final incidentDocumented =
        incidentDoc['state'] == 'pass' &&
        incidentDoc['live_incident_executed'] == false &&
        incidentDoc['response_count'] is num &&
        (incidentDoc['response_count'] as num) > 0;

    final securityDocumented =
        securityDoc['status'] == 'VERIFIED-LOCAL' &&
        securityDoc['live_security_verification'] == false &&
        securityHealthDoc['state'] == 'pass';

    final supportDocumented =
        supportDoc['state'] == 'pass' &&
        supportDoc['support_state'] == 'pass' &&
        _stringList(supportDoc['owners']).isNotEmpty;

    return Sprint119EntryEvidence(
      sprint118ReadinessProven: readinessReady,
      stableAccountCenterProven: stabilityReady,
      certificationExamplesProven: certificationReady,
      incidentStatusDocumented: incidentDocumented,
      securityConstraintsDocumented: securityDocumented,
      supportCapacityDocumented: supportDocumented,
      certifiedProviderCount: certifiedCount,
      correctiveScopeApproved: correctiveScopeApproved,
      readinessDecision: readinessDecision is String ? readinessDecision : '',
      sourcePaths: Sprint119EntryContract.canonicalSources,
      notes: <String>[
        if (readinessDoc['readiness_decision'] != 'CONNECTOR_ECOSYSTEM')
          'readiness_decision:${readinessDoc['readiness_decision']}',
        if (readinessDoc['certified_count'] == 0)
          'sprint_118_certified_count:0',
        if (stabilityDoc['release_blocked'] == true)
          'account_center_release_blocked:true',
        if (incidentDoc['live_incident_executed'] == false)
          'live_incident_execution:deferred_external',
        if (securityDoc['live_security_verification'] == false)
          'live_security_verification:deferred_external',
        if (_externalAccountCenterObservationReady(externalAccountCenter))
          'external_account_center_observation:present',
      ],
    );
  }

  static Map<String, dynamic>? _readJson(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final value = jsonDecode(file.readAsStringSync());
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  static int _firstInt(Iterable<Object?> values) {
    for (final value in values) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  static bool _externalAccountCenterObservationReady(
    Map<String, dynamic>? document,
  ) {
    if (document == null ||
        document['status'] != 'OBSERVED_EXTERNAL_NOT_CERTIFICATION') {
      return false;
    }
    final observedAt = document['observed_at'];
    if (observedAt is! String) return false;
    final observedTime = DateTime.tryParse(observedAt);
    if (observedTime == null || observedTime.isAfter(DateTime.now().toUtc())) {
      return false;
    }

    final observations = document['observations'];
    if (observations is! Map) return false;
    if (observations['account_state'] != 'AKTIF' ||
        observations['desktop_release_label'] !=
            'Aplikasi Windows RC2 tersedia') {
      return false;
    }
    final connected = observations['connected_accounts'];
    if (connected is! Map ||
        connected['google'] != 'Terhubung' ||
        connected['github'] != 'Terhubung') {
      return false;
    }

    final activity = document['activity_log_observations'];
    if (activity is! List || activity.any((item) => item is! String)) {
      return false;
    }
    final entries = activity.cast<String>();
    final sessionsCreated = entries
        .where((entry) => entry.contains('Sesi perangkat dibuat'))
        .length;
    final sessionsRevoked = entries
        .where((entry) => entry.contains('Sesi perangkat dicabut'))
        .length;
    final hasGoogleLogin = entries.any(
      (entry) =>
          entry.contains('Masuk ke akun') && entry.contains('Provider: Google'),
    );
    final hasGithubLink = entries.any(
      (entry) =>
          entry.contains('Provider terhubung') && entry.contains('GitHub'),
    );
    final boundary = document['activity_log_boundary'];
    return boundary is String &&
        boundary.contains('token') &&
        sessionsCreated >= 3 &&
        sessionsRevoked >= 3 &&
        hasGoogleLogin &&
        hasGithubLink;
  }
}

class Sprint119EntryCriterion {
  const Sprint119EntryCriterion({
    required this.key,
    required this.status,
    required this.entrySatisfied,
    required this.evidence,
    required this.detail,
  });

  final String key;
  final String status;
  final bool entrySatisfied;
  final List<String> evidence;
  final String detail;

  Map<String, Object?> toJson() => <String, Object?>{
    'key': key,
    'status': status,
    'entry_satisfied': entrySatisfied,
    'evidence': evidence,
    'detail': detail,
  };
}

class Sprint119EntryReport {
  const Sprint119EntryReport({
    required this.state,
    required this.verdict,
    required this.criteria,
    required this.blockers,
    required this.missingEvidence,
    required this.violations,
    required this.notes,
    required this.correctiveExecutionAllowed,
  });

  final Sprint119EntryGateState state;
  final String verdict;
  final List<Sprint119EntryCriterion> criteria;
  final List<String> blockers;
  final List<String> missingEvidence;
  final List<String> violations;
  final List<String> notes;
  final bool correctiveExecutionAllowed;

  bool get executionAllowed => state == Sprint119EntryGateState.pass;
  String get executionMode {
    if (executionAllowed) return 'EXPANSION_LOCAL_ENTRY';
    if (correctiveExecutionAllowed) return 'CORRECTIVE_ONLY';
    return 'BLOCKED';
  }

  String get activeSprintUnchanged => Sprint119EntryContract.activeSprint;
  int get satisfiedCount =>
      criteria.where((criterion) => criterion.entrySatisfied).length;
  int get blockedCount => criteria.length - satisfiedCount;
}

class Sprint119EntryGate {
  const Sprint119EntryGate();

  Sprint119EntryReport evaluate() =>
      evaluateWith(const Sprint119EntryEvidenceLoader().load());

  Sprint119EntryReport evaluateWith(Sprint119EntryEvidence? evidence) {
    if (evidence == null) {
      return Sprint119EntryReport(
        state: Sprint119EntryGateState.blocked,
        verdict: 'SPRINT_119_ENTRY_EVIDENCE_UNREADABLE',
        criteria: const <Sprint119EntryCriterion>[],
        blockers: const <String>['committed_entry_evidence_unreadable'],
        missingEvidence: List<String>.from(
          Sprint119EntryContract.requiredEvidence,
        ),
        violations: const <String>[],
        notes: const <String>[
          'active_sprint_unchanged:118',
          'sprint_119_execution:deferred_external',
        ],
        correctiveExecutionAllowed: false,
      );
    }

    final criteria = <Sprint119EntryCriterion>[
      Sprint119EntryCriterion(
        key: 'sprint_118_readiness',
        status: evidence.sprint118ReadinessProven ? 'proven' : 'blocked',
        entrySatisfied: evidence.sprint118ReadinessProven,
        evidence: <String>[
          Sprint119EntryContract.requiredSources['sprint_118_readiness']!,
        ],
        detail: evidence.sprint118ReadinessProven
            ? 'Sprint 118 readiness permits ecosystem entry.'
            : 'Sprint 118 remains GA_DELAYED/CORRECTIVE_STABILIZATION.',
      ),
      Sprint119EntryCriterion(
        key: 'stable_account_center',
        status: evidence.stableAccountCenterProven ? 'proven' : 'blocked',
        entrySatisfied: evidence.stableAccountCenterProven,
        evidence: <String>[
          Sprint119EntryContract.requiredSources['stable_account_center']!,
          Sprint119EntryContract.closurePath,
          Sprint119EntryContract.externalAccountCenterObservationPath,
        ],
        detail: evidence.stableAccountCenterProven
            ? 'Account Center local closure is backed by a measured live observation; release and expansion remain separately gated.'
            : 'Only local corrective evidence exists; external stability is not proven.',
      ),
      Sprint119EntryCriterion(
        key: 'certification_examples',
        status: evidence.certificationExamplesProven ? 'proven' : 'blocked',
        entrySatisfied: evidence.certificationExamplesProven,
        evidence: <String>[
          Sprint119EntryContract.requiredSources['certification_examples']!,
          Sprint119EntryContract.snapshotPath,
          Sprint119EntryContract.expansionAcceptancePath,
        ],
        detail: evidence.certificationExamplesProven
            ? 'At least one connector certification example is proven.'
            : 'No certified connector example is recorded.',
      ),
      Sprint119EntryCriterion(
        key: 'incident_status',
        status: evidence.incidentStatusDocumented ? 'documented' : 'missing',
        entrySatisfied: evidence.incidentStatusDocumented,
        evidence: <String>[
          Sprint119EntryContract.requiredSources['incident_status']!,
        ],
        detail: evidence.incidentStatusDocumented
            ? 'Incident and safe-response status is documented; live execution remains deferred.'
            : 'Incident status witness is incomplete.',
      ),
      Sprint119EntryCriterion(
        key: 'security_constraints',
        status: evidence.securityConstraintsDocumented
            ? 'documented'
            : 'missing',
        entrySatisfied: evidence.securityConstraintsDocumented,
        evidence: <String>[
          Sprint119EntryContract.requiredSources['security_constraints']!,
        ],
        detail: evidence.securityConstraintsDocumented
            ? 'Security constraints are documented locally; live verification remains deferred.'
            : 'Security constraint witness is incomplete.',
      ),
      Sprint119EntryCriterion(
        key: 'support_capacity',
        status: evidence.supportCapacityDocumented ? 'documented' : 'missing',
        entrySatisfied: evidence.supportCapacityDocumented,
        evidence: <String>[
          Sprint119EntryContract.requiredSources['support_capacity']!,
        ],
        detail: evidence.supportCapacityDocumented
            ? 'Support owners and intake are documented locally.'
            : 'Support capacity witness is incomplete.',
      ),
    ];

    final blockers = <String>[];
    if (!evidence.sprint118ReadinessProven) {
      blockers.add('sprint_118_readiness_not_expansion_ready');
    }
    if (!evidence.stableAccountCenterProven) {
      blockers.add('stable_account_center_not_proven_external');
    }
    if (!evidence.certificationExamplesProven ||
        evidence.certifiedProviderCount == 0) {
      blockers.add('certification_examples_missing');
    }
    if (!evidence.incidentStatusDocumented) {
      blockers.add('incident_status_missing');
    }
    if (!evidence.securityConstraintsDocumented) {
      blockers.add('security_constraints_missing');
    }
    if (!evidence.supportCapacityDocumented) {
      blockers.add('support_capacity_missing');
    }

    if (blockers.isNotEmpty) {
      final correctiveExecutionAllowed =
          evidence.correctiveScopeApproved &&
          evidence.readinessDecision == 'CORRECTIVE_STABILIZATION' &&
          blockers.every(
            Sprint119EntryContract.correctiveOnlyBlockers.contains,
          );
      return Sprint119EntryReport(
        state: Sprint119EntryGateState.blocked,
        verdict: 'SPRINT_119_ENTRY_BLOCKED_UPSTREAM',
        criteria: criteria,
        blockers: blockers,
        missingEvidence: const <String>[],
        violations: const <String>[],
        notes: evidence.notes,
        correctiveExecutionAllowed: correctiveExecutionAllowed,
      );
    }

    return Sprint119EntryReport(
      state: Sprint119EntryGateState.pass,
      verdict: 'SPRINT_119_ENTRY_READY_LOCAL',
      criteria: criteria,
      blockers: const <String>[],
      missingEvidence: const <String>[],
      violations: const <String>[],
      notes: evidence.notes,
      correctiveExecutionAllowed: false,
    );
  }
}
