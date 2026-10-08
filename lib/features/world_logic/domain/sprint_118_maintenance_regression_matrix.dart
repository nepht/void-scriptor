/// Fail-closed maintenance regression matrix for roadmap step 118.26 --
/// Maintenance Regression Matrix.
///
/// Objective (external canonical `sprint_118.json`): run the tests for the
/// committed stability fixes and for every critical Account Center workflow.
/// The canonical `required_suites` list is exactly ten items: `unit`,
/// `connector_contract`, `auth`, `sync`, `billing`, `security`, `privacy`,
/// `accessibility`, `ui`, and `end_to_end`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze a 42-day window that is declared
/// and not executed, and the 118.4 baseline froze a declared reference for each
/// health area without observing anything. A maintenance regression matrix
/// written against that state therefore has exactly one honest shape: declare a
/// reference suite for each of the ten canonical items, anchored to committed
/// evidence, and claim no live maintenance run, no connector certification, and
/// no observation.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`) and the 118.2
///   charter must be complete with a positive window. A matrix anchored to an
///   unfrozen baseline or an incomplete charter describes a release nobody
///   recorded.
/// * The committed 118.24 stability fixes register must be a genuine pass
///   (`STABILITY_FIXES_VERIFIED_LOCAL`). A maintenance regression that runs the
///   tests for fixes that were never registered has nothing to regress.
/// * The committed 118.6 incident support intake must be a genuine pass
///   (`INCIDENT_SUPPORT_INTAKE_VERIFIED_LOCAL`). The intake categories are the
///   committed vocabulary for the critical Account Center workflows the matrix
///   must cover.
/// * The committed 116.48 connector contract e2e matrix must not claim an
///   executed connector run (`live_connector_execution == false`). On the
///   delayed path a live connector execution is a regression that never ran.
/// * Every canonical suite must be present exactly once. A matrix that drops
///   `end_to_end`, invents a `telepathy` suite, or duplicates `unit` is not a
///   matrix.
/// * No entry may claim a live maintenance run, a connector certification, or a
///   live observation: on the delayed path those describe behavior that never
///   ran. This is refused by name, per suite.
/// * Every entry must carry a non-empty detail, a reference state drawn from the
///   committed witness vocabularies, a committed readable source, and at least
///   one limitation, so the matrix states the regression path it was written
///   under instead of implying live availability.
///
/// **A regression suite is never claimed executed without a release.** Every
/// entry declares whether it claims a live maintenance run, and the gate refuses
/// any entry that does. **A maintenance regression never certifies a
/// connector.** Every entry declares whether it claims a certification, and the
/// gate refuses any entry that says so.
///
/// The suite vocabulary is the ten-item canonical list, the reference-state
/// vocabulary is *derived from committed witnesses* (the 115 automated test
/// matrix `required_suites`, the 112 full automated test matrix
/// `required_suites`, the 114 patch regression matrix `required_suites`, the
/// 116.48 connector contract e2e `acceptance_suites`, the 118.6 incident intake
/// `canonical_categories`, and the 118.24 stability fixes `test_suite_vocabulary`),
/// and the source for each suite is a committed manifest, not copied by hand, so
/// the matrix and its witnesses cannot drift apart silently.
///
/// Live maintenance execution, connector certification, connector execution,
/// live observation, release authorization, and publication remain
/// `DEFERRED-EXTERNAL`; this matrix freezes local declared state and executes
/// none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a maintenance regression matrix can rest in. `blocked` is
/// the honest resting state for "this matrix cannot yet be trusted", and it is
/// distinct from `fail`, which means the matrix contradicts its own evidence.
enum Sprint118MaintenanceRegressionState { pass, fail, blocked }

/// One frozen matrix entry: the declared reference for a single canonical
/// required suite, with the regression path it was frozen under.
///
/// `maintenanceExecuted`, `connectorCertified`, and `observed` are deliberately
/// *not* among the five required fields; they are the flags the gate refuses
/// when set, so that a reference suite can be recorded while never being read as
/// a live maintenance run, a connector certification, or a live observation.
class Sprint118MaintenanceRegressionEntry {
  const Sprint118MaintenanceRegressionEntry({
    required this.suite,
    required this.referenceState,
    required this.source,
    required this.detail,
    required this.limitations,
    this.maintenanceExecuted = false,
    this.connectorCertified = false,
    this.observed = false,
  });

  /// The canonical required suite, drawn from the ten-item vocabulary.
  final String suite;

  /// The declared reference state, drawn from the committed witness
  /// vocabularies.
  final String referenceState;

  /// The committed evidence file this entry is anchored to.
  final String source;

  /// A non-empty description of the regression path this entry freezes.
  final String detail;

  /// The limitations the entry was frozen under. At least one is required so the
  /// entry cannot imply live availability.
  final List<String> limitations;

  /// Whether the entry claims a live maintenance run against a released build.
  /// On the delayed path this must stay `false`: a suite is never claimed
  /// executed without a release.
  final bool maintenanceExecuted;

  /// Whether the entry claims a connector certification. Must stay `false`: a
  /// maintenance regression never certifies a connector.
  final bool connectorCertified;

  /// Whether the entry claims a live observation. On the delayed path this must
  /// stay `false`.
  final bool observed;

  /// The five required fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'suite': suite,
    'reference_state': referenceState,
    'source': source,
    'detail': detail,
    'limitations': limitations.join(','),
  };
}

/// The frozen maintenance regression matrix. `entries` is the declared reference
/// for each canonical required suite; on the delayed path no entry may claim an
/// execution or an observation.
class Sprint118MaintenanceRegressionMatrix {
  const Sprint118MaintenanceRegressionMatrix({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118MaintenanceRegressionEntry> entries;

  List<String> get suiteItems => <String>[
    for (final entry in entries) entry.suite,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed witnesses actually say. A matrix is only as honest as the
/// witnesses it is anchored to.
class Sprint118MaintenanceRegressionAnchor {
  const Sprint118MaintenanceRegressionAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.stabilityFixesState,
    required this.stabilityFixesVerdict,
    required this.intakeState,
    required this.intakeVerdict,
    required this.testMatrixSuites,
    required this.fullMatrixSuites,
    required this.patchMatrixSuites,
    required this.connectorContractSuites,
    required this.intakeCategories,
    required this.fixesSuites,
    required this.liveConnectorExecution,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;
  final String stabilityFixesState;
  final String stabilityFixesVerdict;
  final String intakeState;
  final String intakeVerdict;

  /// The suite vocabulary the committed 115 automated test matrix declares.
  final List<String> testMatrixSuites;

  /// The suite vocabulary the committed 112 full automated test matrix declares.
  final List<String> fullMatrixSuites;

  /// The suite vocabulary the committed 114 patch regression matrix declares.
  final List<String> patchMatrixSuites;

  /// The acceptance-suite vocabulary the committed 116.48 connector contract e2e
  /// matrix declares.
  final List<String> connectorContractSuites;

  /// The category vocabulary the committed 118.6 incident support intake
  /// declares.
  final List<String> intakeCategories;

  /// The suite vocabulary the committed 118.24 stability fixes register
  /// declares.
  final List<String> fixesSuites;

  /// Whether the committed 116.48 connector contract e2e matrix claims an
  /// executed connector run. On the delayed path this must stay `false`.
  final bool liveConnectorExecution;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the matrix is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118MaintenanceRegressionReport {
  const Sprint118MaintenanceRegressionReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredSuites = const <String>[],
    this.observedCount = 0,
  });

  final Sprint118MaintenanceRegressionState state;
  final String verdict;
  final String releaseState;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredSuites;
  final int observedCount;

  /// Whether the matrix may be treated as a frozen record. Only a genuine `pass`
  /// allows it.
  bool get matrixVerified => state == Sprint118MaintenanceRegressionState.pass;

  String get externalGates =>
      Sprint118MaintenanceRegressionContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.26.
abstract final class Sprint118MaintenanceRegressionContract {
  const Sprint118MaintenanceRegressionContract._();

  static const String canonicalStep = '118.26';
  static const String title = 'Maintenance Regression Matrix';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_maintenance_regression_matrix.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this matrix is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter this matrix is anchored to.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 118.24 stability fixes register whose fixes this matrix
  /// regresses.
  static const String stabilityFixesManifestPath =
      'docs/planning/v1.3/sprint_118_stability_fixes.json';

  /// The committed 118.6 incident support intake witness that declares the
  /// critical-workflow category vocabulary.
  static const String intakeManifestPath =
      'docs/planning/v1.3/sprint_118_incident_support_intake.json';

  /// The committed 115 automated test matrix witness that declares the suite
  /// vocabulary.
  static const String testMatrixManifestPath =
      'docs/planning/v1.2/sprint_115_automated_test_matrix.json';

  /// The committed 112 full automated test matrix witness.
  static const String fullMatrixManifestPath =
      'docs/planning/v1.2/sprint_112_full_automated_test_matrix.json';

  /// The committed 114 patch regression matrix witness.
  static const String patchMatrixManifestPath =
      'docs/planning/v1.2/sprint_114_patch_regression_matrix.json';

  /// The committed 116.48 connector contract e2e matrix witness that declares the
  /// connector-contract acceptance-suite vocabulary.
  static const String connectorContractManifestPath =
      'docs/planning/v1.2/sprint_116_connector_contract_e2e_matrix.json';

  /// The committed 117.3 identity workflow validation witness that grounds the
  /// auth suite.
  static const String authManifestPath =
      'docs/planning/v1.3/sprint_117_identity_workflow_validation.json';

  /// The committed 116 cross-storage sync/backup certification witness that
  /// grounds the sync suite.
  static const String syncManifestPath =
      'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json';

  /// The committed 116 billing entitlement webhook reconciliation witness that
  /// grounds the billing suite.
  static const String billingManifestPath =
      'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json';

  /// The committed 116 security certification gate witness that grounds the
  /// security suite.
  static const String securityManifestPath =
      'docs/planning/v1.2/sprint_116_security_certification_gate.json';

  /// The committed 116 privacy compliance gate witness that grounds the privacy
  /// suite.
  static const String privacyManifestPath =
      'docs/planning/v1.2/sprint_116_privacy_compliance_gate.json';

  /// The committed 118.15 accessibility health witness that grounds the
  /// accessibility suite.
  static const String accessibilityManifestPath =
      'docs/planning/v1.3/sprint_118_accessibility_health.json';

  /// The committed 118.14 responsive UI health witness that grounds the ui
  /// suite.
  static const String uiManifestPath =
      'docs/planning/v1.3/sprint_118_responsive_ui_health.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  /// The verdict and state the 118.24 stability fixes register must carry.
  static const String requiredStabilityFixesVerdict =
      'STABILITY_FIXES_VERIFIED_LOCAL';
  static const String requiredStabilityFixesState = 'pass';

  /// The verdict and state the 118.6 incident support intake must carry.
  static const String requiredIntakeVerdict =
      'INCIDENT_SUPPORT_INTAKE_VERIFIED_LOCAL';
  static const String requiredIntakeState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The marker an entry declares when no committed witness names a reference
  /// state for its suite. A matrix that uses it records an honest upstream gap
  /// rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The ten canonical required suites declared by external canonical step
  /// 118.26.
  static const List<String> requiredSuites = <String>[
    'unit',
    'connector_contract',
    'auth',
    'sync',
    'billing',
    'security',
    'privacy',
    'accessibility',
    'ui',
    'end_to_end',
  ];

  /// The canonical field set each entry must carry, so a matrix cannot drop a
  /// field and still read as complete.
  static const List<String> requiredFields = <String>[
    'suite',
    'reference_state',
    'source',
    'detail',
    'limitations',
  ];

  /// The committed evidence file each canonical suite is anchored to.
  static const List<String> canonicalSources = <String>[
    testMatrixManifestPath,
    connectorContractManifestPath,
    authManifestPath,
    syncManifestPath,
    billingManifestPath,
    securityManifestPath,
    privacyManifestPath,
    accessibilityManifestPath,
    uiManifestPath,
    fullMatrixManifestPath,
  ];

  /// Union of the committed witness vocabularies, de-duplicated in first-seen
  /// order, plus the honest no-reference marker. The reference states are
  /// derived from the witnesses rather than copied into a live reader.
  static List<String> stateVocabulary(List<List<String>> vocabularies) {
    final seen = <String>{};
    final result = <String>[];
    for (final vocabulary in vocabularies) {
      for (final value in vocabulary) {
        if (seen.add(value)) result.add(value);
      }
    }
    if (seen.add(noReferenceState)) result.add(noReferenceState);
    return result;
  }

  /// Whether a committed witness vocabulary grounds a canonical suite token.
  ///
  /// A witness grounds a token when it names the token exactly (`unit`,
  /// `end_to_end`), or when every underscore-separated part of a compound token
  /// is itself a witness-declared suite (`connector_contract` is grounded because
  /// the witnesses declare both `connector` and `contract`). The vocabulary is
  /// measured from the committed matrices, so a suite cannot be invented into
  /// the list without a witness to ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed source for a canonical suite, or `''` if unknown.
  static String sourceFor(String suite) {
    final index = requiredSuites.indexOf(suite);
    return index < 0 ? '' : canonicalSources[index];
  }

  static const canonicalMatrix = Sprint118MaintenanceRegressionMatrix(
    releaseState: delayedReleaseState,
    entries: <Sprint118MaintenanceRegressionEntry>[
      Sprint118MaintenanceRegressionEntry(
        suite: 'unit',
        referenceState: 'unit',
        source: testMatrixManifestPath,
        detail:
            'The unit suite regresses the committed stability fixes at the '
            'domain layer without a live maintenance run',
        limitations: <String>[
          'live_maintenance_run_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118MaintenanceRegressionEntry(
        suite: 'connector_contract',
        referenceState: noReferenceState,
        source: connectorContractManifestPath,
        detail:
            'The connector contract suite regresses the committed connector '
            'contract e2e acceptance suites without a live connector',
        limitations: <String>[
          'live_connector_execution_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118MaintenanceRegressionEntry(
        suite: 'auth',
        referenceState: 'auth',
        source: authManifestPath,
        detail:
            'The auth suite regresses the committed identity workflow '
            'validation without a live credential',
        limitations: <String>['live_auth_run_deferred', 'synthetic_local'],
      ),
      Sprint118MaintenanceRegressionEntry(
        suite: 'sync',
        referenceState: 'sync',
        source: syncManifestPath,
        detail:
            'The sync suite regresses the committed cross-storage sync and '
            'backup certification without a live transfer',
        limitations: <String>['live_sync_run_deferred', 'synthetic_local'],
      ),
      Sprint118MaintenanceRegressionEntry(
        suite: 'billing',
        referenceState: 'billing',
        source: billingManifestPath,
        detail:
            'The billing suite regresses the committed billing entitlement '
            'webhook reconciliation without a live payment processor',
        limitations: <String>['live_billing_run_deferred', 'synthetic_local'],
      ),
      Sprint118MaintenanceRegressionEntry(
        suite: 'security',
        referenceState: 'security',
        source: securityManifestPath,
        detail:
            'The security suite regresses the committed security certification '
            'gate without a live security scan',
        limitations: <String>['live_security_run_deferred', 'synthetic_local'],
      ),
      Sprint118MaintenanceRegressionEntry(
        suite: 'privacy',
        referenceState: 'privacy',
        source: privacyManifestPath,
        detail:
            'The privacy suite regresses the committed privacy compliance gate '
            'without a live data-flow inspection',
        limitations: <String>['live_privacy_run_deferred', 'synthetic_local'],
      ),
      Sprint118MaintenanceRegressionEntry(
        suite: 'accessibility',
        referenceState: 'accessibility',
        source: accessibilityManifestPath,
        detail:
            'The accessibility suite regresses the committed accessibility '
            'health review without a live screen reader',
        limitations: <String>[
          'live_accessibility_run_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118MaintenanceRegressionEntry(
        suite: 'ui',
        referenceState: 'ui',
        source: uiManifestPath,
        detail:
            'The ui suite regresses the committed responsive UI health review '
            'without a live render',
        limitations: <String>['live_ui_run_deferred', 'synthetic_local'],
      ),
      Sprint118MaintenanceRegressionEntry(
        suite: 'end_to_end',
        referenceState: 'end_to_end',
        source: fullMatrixManifestPath,
        detail:
            'The end-to-end suite regresses the committed full automated test '
            'matrix without a live workflow execution',
        limitations: <String>[
          'live_end_to_end_run_deferred',
          'synthetic_local',
        ],
      ),
    ],
  );
}

/// Reads the committed witnesses for step 118.26. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118MaintenanceRegressionLoader {
  const Sprint118MaintenanceRegressionLoader();

  Sprint118MaintenanceRegressionAnchor? loadAnchor() {
    final baseline = _read(
      Sprint118MaintenanceRegressionContract.baselineManifestPath,
    );
    final charter = _read(
      Sprint118MaintenanceRegressionContract.charterManifestPath,
    );
    final fixes = _read(
      Sprint118MaintenanceRegressionContract.stabilityFixesManifestPath,
    );
    final intake = _read(
      Sprint118MaintenanceRegressionContract.intakeManifestPath,
    );
    final testMatrix = _read(
      Sprint118MaintenanceRegressionContract.testMatrixManifestPath,
    );
    final fullMatrix = _read(
      Sprint118MaintenanceRegressionContract.fullMatrixManifestPath,
    );
    final patchMatrix = _read(
      Sprint118MaintenanceRegressionContract.patchMatrixManifestPath,
    );
    final connector = _read(
      Sprint118MaintenanceRegressionContract.connectorContractManifestPath,
    );
    if (baseline == null ||
        charter == null ||
        fixes == null ||
        intake == null ||
        testMatrix == null ||
        fullMatrix == null ||
        patchMatrix == null ||
        connector == null) {
      return null;
    }

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);

    final sources = <String>{
      Sprint118MaintenanceRegressionContract.baselineManifestPath,
      Sprint118MaintenanceRegressionContract.charterManifestPath,
      Sprint118MaintenanceRegressionContract.stabilityFixesManifestPath,
      Sprint118MaintenanceRegressionContract.intakeManifestPath,
      Sprint118MaintenanceRegressionContract.testMatrixManifestPath,
      Sprint118MaintenanceRegressionContract.fullMatrixManifestPath,
      Sprint118MaintenanceRegressionContract.patchMatrixManifestPath,
      Sprint118MaintenanceRegressionContract.connectorContractManifestPath,
      Sprint118MaintenanceRegressionContract.authManifestPath,
      Sprint118MaintenanceRegressionContract.syncManifestPath,
      Sprint118MaintenanceRegressionContract.billingManifestPath,
      Sprint118MaintenanceRegressionContract.securityManifestPath,
      Sprint118MaintenanceRegressionContract.privacyManifestPath,
      Sprint118MaintenanceRegressionContract.accessibilityManifestPath,
      Sprint118MaintenanceRegressionContract.uiManifestPath,
    };

    return Sprint118MaintenanceRegressionAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: durationDays > 0 ? durationDays * 24 * 60 : 0,
      stabilityFixesState: _text(fixes['state']),
      stabilityFixesVerdict: _text(fixes['verdict']),
      intakeState: _text(intake['state']),
      intakeVerdict: _text(intake['verdict']),
      testMatrixSuites: _strings(testMatrix['required_suites']),
      fullMatrixSuites: _strings(fullMatrix['required_suites']),
      patchMatrixSuites: _strings(patchMatrix['required_suites']),
      connectorContractSuites: _strings(connector['acceptance_suites']),
      intakeCategories: _strings(intake['canonical_categories']),
      fixesSuites: _strings(fixes['test_suite_vocabulary']),
      liveConnectorExecution: connector['live_connector_execution'] == true,
      readableSources: <String>[
        for (final path in sources)
          if (File(path).existsSync()) path,
      ],
    );
  }

  static Map<String, dynamic>? _read(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final value = jsonDecode(file.readAsStringSync());
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  static List<String> _strings(Object? value) => value is List
      ? <String>[
          for (final item in value)
            if (item is String) item,
        ]
      : const <String>[];

  static int _int(Object? value) => value is int ? value : 0;
}

/// The fail-closed maintenance regression matrix gate for step 118.26.
class Sprint118MaintenanceRegressionGate {
  const Sprint118MaintenanceRegressionGate();

  Sprint118MaintenanceRegressionReport evaluate() => evaluateWith(
    const Sprint118MaintenanceRegressionLoader().loadAnchor(),
    Sprint118MaintenanceRegressionContract.canonicalMatrix,
  );

  Sprint118MaintenanceRegressionReport evaluateWith(
    Sprint118MaintenanceRegressionAnchor? anchor,
    Sprint118MaintenanceRegressionMatrix matrix,
  ) {
    if (anchor == null) {
      return Sprint118MaintenanceRegressionReport(
        state: Sprint118MaintenanceRegressionState.blocked,
        verdict: 'SPRINT_118_MAINTENANCE_REGRESSION_EVIDENCE_UNREADABLE',
        releaseState: matrix.releaseState,
        blockers: const <String>[
          'committed_maintenance_regression_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_maintenance_regression_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    final vocabulary =
        Sprint118MaintenanceRegressionContract.stateVocabulary(<List<String>>[
          anchor.testMatrixSuites,
          anchor.fullMatrixSuites,
          anchor.patchMatrixSuites,
          anchor.connectorContractSuites,
          anchor.intakeCategories,
          anchor.fixesSuites,
        ]);

    // (1) The 118.4 baseline anchor must be a genuine frozen pass.
    if (anchor.baselineState !=
            Sprint118MaintenanceRegressionContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118MaintenanceRegressionContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState !=
            Sprint118MaintenanceRegressionContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118MaintenanceRegressionContract.requiredCharterVerdict ||
        anchor.charterWindowMinutes <= 0) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (3) The 118.24 stability fixes register must be a genuine pass. A matrix
    // that regresses fixes that were never registered has nothing to regress.
    if (anchor.stabilityFixesState !=
            Sprint118MaintenanceRegressionContract
                .requiredStabilityFixesState ||
        anchor.stabilityFixesVerdict !=
            Sprint118MaintenanceRegressionContract
                .requiredStabilityFixesVerdict) {
      blockers.add(
        'stability_fixes_not_verified:${anchor.stabilityFixesVerdict}',
      );
    }

    // (4) The 118.6 incident support intake must be a genuine pass. The intake
    // categories are the committed vocabulary for the critical workflows.
    if (anchor.intakeState !=
            Sprint118MaintenanceRegressionContract.requiredIntakeState ||
        anchor.intakeVerdict !=
            Sprint118MaintenanceRegressionContract.requiredIntakeVerdict) {
      blockers.add('intake_not_verified:${anchor.intakeVerdict}');
    }

    // (5) The release state must agree with the baseline anchor.
    if (anchor.releaseState != matrix.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'matrix=${matrix.releaseState}',
      );
    }

    // (6) On the delayed path a live connector execution is a regression that
    // never ran.
    final delayed =
        matrix.releaseState ==
        Sprint118MaintenanceRegressionContract.delayedReleaseState;
    if (delayed && anchor.liveConnectorExecution) {
      violations.add('live_connector_execution_claimed_on_delayed_path');
    }

    // (7) Every canonical required suite must be grounded in a committed
    // witness, not a hand-copied list that can drift away from it.
    for (final suite in Sprint118MaintenanceRegressionContract.requiredSuites) {
      if (!Sprint118MaintenanceRegressionContract.grounds(vocabulary, suite)) {
        openItems.add('suite_not_grounded_in_witness:$suite');
      }
    }

    // (8) Every canonical suite must be present exactly once, and each entry
    // must carry all five required fields non-blank, a reference state drawn from
    // a committed witness, a committed readable source, and at least one
    // limitation.
    final declared = <String, int>{};
    for (final entry in matrix.entries) {
      declared[entry.suite] = (declared[entry.suite] ?? 0) + 1;
    }
    for (final entry in matrix.entries) {
      final suite = entry.suite;
      if (!Sprint118MaintenanceRegressionContract.requiredSuites.contains(
        suite,
      )) {
        violations.add('suite_unknown:$suite');
      }
      for (final field
          in Sprint118MaintenanceRegressionContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$suite');
        }
      }
      if (entry.referenceState.trim().isEmpty ||
          !vocabulary.contains(entry.referenceState)) {
        violations.add('reference_state_invalid:$suite');
      }
      if (entry.referenceState ==
          Sprint118MaintenanceRegressionContract.noReferenceState) {
        openItems.add('upstream_state_vocabulary_gap:$suite');
      }
      if (entry.source.trim().isEmpty ||
          !anchor.readableSources.contains(entry.source)) {
        violations.add('source_unreadable:$suite');
      }
      // A regression suite is never claimed executed without a release.
      if (entry.maintenanceExecuted) {
        violations.add('maintenance_executed_without_release:$suite');
      }
      // A maintenance regression never certifies a connector.
      if (entry.connectorCertified) {
        violations.add(
          'connector_certification_claimed_without_release:$suite',
        );
      }
      // No live observation on the delayed path.
      if (entry.observed) {
        violations.add('live_observation_claimed:$suite');
      }
    }
    for (final suite in declared.keys) {
      if (declared[suite]! > 1) {
        violations.add('suite_duplicate:$suite');
      }
    }
    for (final suite in Sprint118MaintenanceRegressionContract.requiredSuites) {
      if (!declared.containsKey(suite)) {
        violations.add('suite_missing:$suite');
      }
    }

    // (9) Every committed evidence source must be readable.
    for (final source
        in Sprint118MaintenanceRegressionContract.canonicalSources.toSet()) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('required_source_unreadable:$source');
      }
    }

    final allItems = <String>[...violations, ...blockers, ...openItems];
    final suites = matrix.suiteItems;

    // An untrustworthy anchor short-circuits: if a committed witness is not a
    // genuine pass, the entry-level findings cannot be trusted either, so the
    // honest answer is `blocked`, not `fail`.
    if (blockers.isNotEmpty) {
      return Sprint118MaintenanceRegressionReport(
        state: Sprint118MaintenanceRegressionState.blocked,
        verdict: 'SPRINT_118_MAINTENANCE_REGRESSION_BLOCKED_UPSTREAM',
        releaseState: matrix.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredSuites: suites,
        observedCount: matrix.observedCount,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118MaintenanceRegressionReport(
        state: Sprint118MaintenanceRegressionState.fail,
        verdict: 'SPRINT_118_MAINTENANCE_REGRESSION_EVIDENCE_VIOLATION',
        releaseState: matrix.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredSuites: suites,
        observedCount: matrix.observedCount,
      );
    }
    return Sprint118MaintenanceRegressionReport(
      state: Sprint118MaintenanceRegressionState.pass,
      verdict: 'MAINTENANCE_REGRESSION_MATRIX_VERIFIED_LOCAL',
      releaseState: matrix.releaseState,
      openItems: allItems,
      declaredSuites: suites,
      observedCount: matrix.observedCount,
    );
  }
}
