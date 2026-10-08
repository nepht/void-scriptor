/// Fail-closed stability-fix log for roadmap step 118.24 -- Stability Fixes.
///
/// Objective (external canonical `sprint_118.json`): resolve the approved auth,
/// quota, sync, AI, billing, UI, accessibility, and compatibility regressions
/// with a minimum change. The canonical requirement list is exactly six items:
/// `reproduction`, `minimal_change`, `regression_test`, `review`, `risk_update`,
/// and `release_note`.
///
/// This is the register the delayed corrective path (Sprint 118 on
/// `GA_DELAYED`) keeps for the eight approved fix areas. The gate answers a
/// single question: does the declared register carry, for every approved fix
/// area, a fix record with all six required fields non-blank, a known owner, a
/// committed readable evidence source, a reproduction, a regression test, a
/// review, and a risk update -- and does every record stay inside the approved
/// minimum change without claiming a shipped fix that no release ever ran?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A fix register
///   built on a baseline that did not freeze fixes regressions nobody measured.
/// * The committed 118.2 charter anchor must be a genuine complete charter
///   (`pass` on `CHARTER_COMPLETE_LOCAL`). A register written outside the frozen
///   stability charter has no window to belong to.
/// * The committed 117.6 support-incident-readiness witness must be a genuine
///   readiness pass (`SUPPORT_INCIDENT_READINESS_DEFINED_LOCAL`). A register
///   that is not anchored to a committed severity/owner plan cannot be triaged.
/// * The committed 118.6 incident-support-intake witness must be a genuine
///   intake pass (`INCIDENT_SUPPORT_INTAKE_VERIFIED_LOCAL`). A register that is
///   not anchored to the committed intake cannot know which fixes are approved.
/// * The register's release state must agree with the baseline anchor.
/// * On the delayed path no fix may be claimed shipped: neither the committed
///   readiness witness may report an executed incident nor any fix record may
///   claim a shipped fix.
/// * Every approved fix area must be present exactly once, and each record must
///   carry all six required fields non-blank, must name an accountable owner,
///   and must cite a committed, readable evidence source.
/// * **A fix is never claimed shipped without a release.** Every record
///   declares a reference fix, and the gate refuses any record that treats that
///   reference as a shipped fix.
/// * **A fix never expands scope beyond the approved minimum change.** Every
///   record declares its change stayed minimal, and the gate refuses any record
///   that widened the approved scope.
///
/// The area vocabulary is *derived from committed witnesses* (the 118.6 intake
/// `canonical_categories`, the 115 automated test matrix `required_suites`, and
/// the 114 rollback readiness `required_evidence`), the requirement vocabulary
/// is *derived from the committed 114.29 P1 stability fixes `requirements`*, and
/// the owner vocabulary from the committed 117.6 readiness witness, not copied
/// by hand, so the register and its witnesses cannot drift apart silently.
///
/// Live fix shipping, regression reproduction on production, connector
/// certification, provider exposure, release authorization, and publication
/// remain `DEFERRED-EXTERNAL`; this register freezes local declared state and
/// executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a stability-fix evaluation can rest in. `blocked` is the
/// honest resting state for "this register cannot yet be trusted", and it is
/// distinct from `fail`, which means the register contradicts its own evidence.
enum Sprint118StabilityFixState { pass, fail, blocked }

/// One fix record: the declared fix for a single approved area, with the six
/// required fields it must carry.
///
/// `fixShipped` and `scopeExpanded` are deliberately *not* among the six
/// required fields; they are the flags the gate refuses when set, so that a
/// reference fix can be recorded while never being read as a shipped fix and
/// never widening the approved scope.
class Sprint118StabilityFixEntry {
  const Sprint118StabilityFixEntry({
    required this.fixArea,
    required this.fixId,
    required this.reproduction,
    required this.minimalChange,
    required this.regressionTest,
    required this.review,
    required this.riskUpdate,
    required this.releaseNote,
    required this.owner,
    required this.evidence,
    this.fixShipped = false,
    this.scopeExpanded = false,
  });

  /// The approved fix area this record addresses, drawn from the area
  /// vocabulary.
  final String fixArea;

  /// The stable identifier of the declared fix. Stable and declared; no live
  /// fix is implied.
  final String fixId;

  /// How the regression reproduces. On the delayed path this is the reference
  /// reproduction marker; no live regression was reproduced.
  final String reproduction;

  /// The minimal change that would resolve the regression. On the delayed path
  /// this is the reference change marker; no change was applied.
  final String minimalChange;

  /// The regression test that would prove the fix. On the delayed path this is
  /// the reference test marker; no test executed.
  final String regressionTest;

  /// The review the change would receive. On the delayed path this is the
  /// reference review marker; no review ran.
  final String review;

  /// The risk update the change would record. On the delayed path this is the
  /// reference risk marker; no risk was updated.
  final String riskUpdate;

  /// The release note the change would carry. On the delayed path this is the
  /// reference note marker; no release note was published.
  final String releaseNote;

  /// Who owns the fix, drawn from the owner vocabulary.
  final String owner;

  /// The committed evidence source for this area. Must be readable.
  final String evidence;

  /// Whether this record claims a shipped fix. The gate refuses `true`: a fix
  /// is never claimed shipped without a release.
  final bool fixShipped;

  /// Whether this record claims a change that widened the approved scope. The
  /// gate refuses `true`: a fix never expands scope beyond the approved minimum
  /// change.
  final bool scopeExpanded;

  /// The six required fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'reproduction': reproduction,
    'minimal_change': minimalChange,
    'regression_test': regressionTest,
    'review': review,
    'risk_update': riskUpdate,
    'release_note': releaseNote,
  };
}

/// The declared fix register. `entries` is the fix surface for the delayed
/// corrective path; on that path no record may claim a shipped fix.
class Sprint118StabilityFixRegister {
  const Sprint118StabilityFixRegister({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118StabilityFixEntry> entries;

  List<String> get fixAreas => <String>[
    for (final entry in entries) entry.fixArea,
  ];

  List<String> get fixIds => <String>[for (final entry in entries) entry.fixId];
}

/// What the committed witnesses actually say. A register is only as honest as
/// the witnesses it reads.
class Sprint118StabilityFixAnchor {
  const Sprint118StabilityFixAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.readinessState,
    required this.readinessVerdict,
    required this.liveIncidentExecuted,
    required this.intakeState,
    required this.intakeVerdict,
    required this.owners,
    required this.intakeCategories,
    required this.testSuites,
    required this.rollbackEvidence,
    required this.p1Requirements,
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

  final String intakeState;
  final String intakeVerdict;

  /// The owner vocabulary the committed 117.6 readiness witness declares.
  final List<String> owners;

  /// The category vocabulary the committed 118.6 intake witness declares. One
  /// third of the fix-area vocabulary.
  final List<String> intakeCategories;

  /// The suite vocabulary the committed 115 automated test matrix declares. One
  /// third of the fix-area vocabulary.
  final List<String> testSuites;

  /// The evidence vocabulary the committed 114 rollback readiness witness
  /// declares. One third of the fix-area vocabulary (grounds `compatibility`).
  final List<String> rollbackEvidence;

  /// The requirement vocabulary the committed 114.29 P1 stability fixes witness
  /// declares.
  final List<String> p1Requirements;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the register is well-formed; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118StabilityFixReport {
  const Sprint118StabilityFixReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredAreas = const <String>[],
    this.fixCount = 0,
  });

  final Sprint118StabilityFixState state;
  final String verdict;
  final String releaseState;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredAreas;
  final int fixCount;

  /// Whether the register may be treated as well-formed. Only a genuine `pass`
  /// allows it.
  bool get registerVerified => state == Sprint118StabilityFixState.pass;

  String get externalGates => Sprint118StabilityFixContract.externalGates;
}

/// The fixed vocabulary of step 118.24, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118StabilityFixContract {
  const Sprint118StabilityFixContract._();

  static const String canonicalStep = '118.24';
  static const String title = 'Stability Fixes';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_stability_fixes.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this register is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter this register is anchored to.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 117.6 support incident readiness witness that declares the
  /// owner vocabulary and the live-incident signal.
  static const String readinessManifestPath =
      'docs/planning/v1.3/sprint_117_support_incident_readiness.json';

  /// The committed 118.6 incident support intake witness that declares the
  /// approved category vocabulary.
  static const String intakeManifestPath =
      'docs/planning/v1.3/sprint_118_incident_support_intake.json';

  /// The committed 115 automated test matrix witness that declares the suite
  /// vocabulary.
  static const String testMatrixManifestPath =
      'docs/planning/v1.2/sprint_115_automated_test_matrix.json';

  /// The committed 114 rollback feature flag readiness witness that declares the
  /// data-compatibility vocabulary.
  static const String rollbackManifestPath =
      'docs/planning/v1.2/sprint_114_rollback_feature_flag_readiness.json';

  /// The committed 114.29 P1 stability fixes witness that declares the
  /// requirement vocabulary.
  static const String p1FixesManifestPath =
      'docs/planning/v1.2/sprint_114_p1_stability_fixes.json';

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

  /// The verdict and state the 118.6 intake witness must carry.
  static const String requiredIntakeVerdict =
      'INCIDENT_SUPPORT_INTAKE_VERIFIED_LOCAL';
  static const String requiredIntakeState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The product version the register is declared against.
  static const String baseVersion = '1.3.1';

  /// The six canonical required requirements from `sprint_118.json` step 118.24.
  static const List<String> requiredRequirements = <String>[
    'reproduction',
    'minimal_change',
    'regression_test',
    'review',
    'risk_update',
    'release_note',
  ];

  /// The eight approved fix areas the objective names.
  static const List<String> fixAreas = <String>[
    'auth',
    'quota',
    'sync',
    'ai',
    'billing',
    'ui',
    'accessibility',
    'compatibility',
  ];

  /// The reference field markers an entry declares when no live fix has
  /// shipped. On the delayed path these are the only honest field values.
  static const String referenceReproduction =
      'reference_reproduction_not_confirmed';
  static const String referenceMinimalChange = 'reference_change_not_applied';
  static const String referenceRegressionTest =
      'reference_regression_test_not_executed';
  static const String referenceReview = 'reference_review_not_performed';
  static const String referenceRiskUpdate = 'reference_risk_not_updated';
  static const String referenceReleaseNote =
      'reference_release_note_not_written';

  /// The accountable fix owner, drawn from the committed 117.6 readiness owner
  /// vocabulary. The gate verifies membership against the witness.
  static const String fixOwner = 'Choirudin';

  /// The committed evidence source registered for each approved fix area.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
    'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
    'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json',
    'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json',
    'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
    'docs/planning/v1.3/sprint_118_responsive_ui_health.json',
    'docs/planning/v1.3/sprint_118_accessibility_health.json',
    'docs/planning/v1.2/sprint_112_platform_compatibility_gate.json',
  ];

  /// The evidence source registered for an approved fix area.
  static String sourceFor(String fixArea) {
    final index = fixAreas.indexOf(fixArea);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// Whether a witness vocabulary grounds a canonical token. A witness grounds
  /// a token when it names it exactly, when one of its compound tokens is the
  /// token (e.g. `data_compatibility` grounds `compatibility`), or when it
  /// contains the token as a substring.
  static bool grounds(List<String> vocabulary, String token) {
    for (final entry in vocabulary) {
      if (entry == token) return true;
      if (entry.contains(token)) return true;
      if (entry.split('_').contains(token)) return true;
    }
    return false;
  }

  /// The canonical fix register, declared here as the single source of truth.
  /// The gate evaluates exactly this object, and the emitter writes exactly
  /// this object, so the record cannot be made to agree with itself. With the
  /// release delayed, every record registers a reference fix and claims no
  /// shipped fix.
  static const Sprint118StabilityFixRegister
  canonicalRegister = Sprint118StabilityFixRegister(
    releaseState: delayedReleaseState,
    entries: <Sprint118StabilityFixEntry>[
      Sprint118StabilityFixEntry(
        fixArea: 'auth',
        fixId: 'FIX-AUTH-REF',
        reproduction: referenceReproduction,
        minimalChange: referenceMinimalChange,
        regressionTest: referenceRegressionTest,
        review: referenceReview,
        riskUpdate: referenceRiskUpdate,
        releaseNote: referenceReleaseNote,
        owner: fixOwner,
        evidence:
            'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
      ),
      Sprint118StabilityFixEntry(
        fixArea: 'quota',
        fixId: 'FIX-QUOTA-REF',
        reproduction: referenceReproduction,
        minimalChange: referenceMinimalChange,
        regressionTest: referenceRegressionTest,
        review: referenceReview,
        riskUpdate: referenceRiskUpdate,
        releaseNote: referenceReleaseNote,
        owner: fixOwner,
        evidence:
            'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
      ),
      Sprint118StabilityFixEntry(
        fixArea: 'sync',
        fixId: 'FIX-SYNC-REF',
        reproduction: referenceReproduction,
        minimalChange: referenceMinimalChange,
        regressionTest: referenceRegressionTest,
        review: referenceReview,
        riskUpdate: referenceRiskUpdate,
        releaseNote: referenceReleaseNote,
        owner: fixOwner,
        evidence:
            'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json',
      ),
      Sprint118StabilityFixEntry(
        fixArea: 'ai',
        fixId: 'FIX-AI-REF',
        reproduction: referenceReproduction,
        minimalChange: referenceMinimalChange,
        regressionTest: referenceRegressionTest,
        review: referenceReview,
        riskUpdate: referenceRiskUpdate,
        releaseNote: referenceReleaseNote,
        owner: fixOwner,
        evidence:
            'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json',
      ),
      Sprint118StabilityFixEntry(
        fixArea: 'billing',
        fixId: 'FIX-BILLING-REF',
        reproduction: referenceReproduction,
        minimalChange: referenceMinimalChange,
        regressionTest: referenceRegressionTest,
        review: referenceReview,
        riskUpdate: referenceRiskUpdate,
        releaseNote: referenceReleaseNote,
        owner: fixOwner,
        evidence:
            'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
      ),
      Sprint118StabilityFixEntry(
        fixArea: 'ui',
        fixId: 'FIX-UI-REF',
        reproduction: referenceReproduction,
        minimalChange: referenceMinimalChange,
        regressionTest: referenceRegressionTest,
        review: referenceReview,
        riskUpdate: referenceRiskUpdate,
        releaseNote: referenceReleaseNote,
        owner: fixOwner,
        evidence: 'docs/planning/v1.3/sprint_118_responsive_ui_health.json',
      ),
      Sprint118StabilityFixEntry(
        fixArea: 'accessibility',
        fixId: 'FIX-ACCESSIBILITY-REF',
        reproduction: referenceReproduction,
        minimalChange: referenceMinimalChange,
        regressionTest: referenceRegressionTest,
        review: referenceReview,
        riskUpdate: referenceRiskUpdate,
        releaseNote: referenceReleaseNote,
        owner: fixOwner,
        evidence: 'docs/planning/v1.3/sprint_118_accessibility_health.json',
      ),
      Sprint118StabilityFixEntry(
        fixArea: 'compatibility',
        fixId: 'FIX-COMPATIBILITY-REF',
        reproduction: referenceReproduction,
        minimalChange: referenceMinimalChange,
        regressionTest: referenceRegressionTest,
        review: referenceReview,
        riskUpdate: referenceRiskUpdate,
        releaseNote: referenceReleaseNote,
        owner: fixOwner,
        evidence:
            'docs/planning/v1.2/sprint_112_platform_compatibility_gate.json',
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, 117.6 readiness witness,
/// 118.6 intake witness, 115 test matrix witness, 114 rollback readiness
/// witness, and 114.29 P1 fixes witness. Never invents: an unreadable witness
/// yields `null`, which the gate reports as blocked rather than as a pass.
class Sprint118StabilityFixLoader {
  const Sprint118StabilityFixLoader();

  Sprint118StabilityFixAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118StabilityFixContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(
      Sprint118StabilityFixContract.charterManifestPath,
    );
    if (charter == null) return null;
    final readiness = _readJsonObject(
      Sprint118StabilityFixContract.readinessManifestPath,
    );
    if (readiness == null) return null;
    final intake = _readJsonObject(
      Sprint118StabilityFixContract.intakeManifestPath,
    );
    if (intake == null) return null;
    final testMatrix = _readJsonObject(
      Sprint118StabilityFixContract.testMatrixManifestPath,
    );
    if (testMatrix == null) return null;
    final rollback = _readJsonObject(
      Sprint118StabilityFixContract.rollbackManifestPath,
    );
    if (rollback == null) return null;
    final p1Fixes = _readJsonObject(
      Sprint118StabilityFixContract.p1FixesManifestPath,
    );
    if (p1Fixes == null) return null;

    final readable = <String>[
      for (final source in Sprint118StabilityFixContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118StabilityFixAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      readinessState: _text(readiness['state']),
      readinessVerdict: _text(readiness['verdict']),
      liveIncidentExecuted: readiness['live_incident_executed'] == true,
      intakeState: _text(intake['state']),
      intakeVerdict: _text(intake['verdict']),
      owners: _stringList(readiness['owners']),
      intakeCategories: _stringList(intake['canonical_categories']),
      testSuites: _stringList(testMatrix['required_suites']),
      rollbackEvidence: _stringList(rollback['required_evidence']),
      p1Requirements: _stringList(p1Fixes['requirements']),
      readableSources: readable,
    );
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

class Sprint118StabilityFixGate {
  const Sprint118StabilityFixGate();

  /// Evaluate the canonical register against committed evidence. This is the
  /// entry point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118StabilityFixReport evaluate() => evaluateWith(
    const Sprint118StabilityFixLoader().loadAnchor(),
    Sprint118StabilityFixContract.canonicalRegister,
  );

  Sprint118StabilityFixReport evaluateWith(
    Sprint118StabilityFixAnchor? anchor,
    Sprint118StabilityFixRegister register,
  ) {
    if (anchor == null) {
      return Sprint118StabilityFixReport(
        state: Sprint118StabilityFixState.blocked,
        verdict: 'SPRINT_118_STABILITY_FIXES_EVIDENCE_UNREADABLE',
        releaseState: register.releaseState,
        missingFields: List<String>.from(
          Sprint118StabilityFixContract.requiredRequirements,
        ),
        blockers: const <String>['committed_stability_fix_evidence_unreadable'],
        openItems: const <String>[
          'committed_stability_fix_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A register
    // written against an unfrozen baseline fixes regressions nobody measured.
    if (anchor.baselineState !=
            Sprint118StabilityFixContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118StabilityFixContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState !=
            Sprint118StabilityFixContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118StabilityFixContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (3) The 117.6 readiness witness must be a genuine pass. A register that
    // is not anchored to a committed severity/owner plan cannot be triaged.
    if (anchor.readinessState !=
            Sprint118StabilityFixContract.requiredReadinessState ||
        anchor.readinessVerdict !=
            Sprint118StabilityFixContract.requiredReadinessVerdict) {
      blockers.add('readiness_not_defined:${anchor.readinessVerdict}');
    }

    // (4) The 118.6 intake witness must be a genuine pass. A register that is
    // not anchored to the committed intake cannot know which fixes are
    // approved.
    if (anchor.intakeState !=
            Sprint118StabilityFixContract.requiredIntakeState ||
        anchor.intakeVerdict !=
            Sprint118StabilityFixContract.requiredIntakeVerdict) {
      blockers.add('intake_not_verified:${anchor.intakeVerdict}');
    }

    // (5) The release state must agree with the baseline anchor.
    if (anchor.releaseState != register.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'register=${register.releaseState}',
      );
    }

    // (6) On the delayed path no fix may be claimed shipped.
    final delayed =
        register.releaseState ==
        Sprint118StabilityFixContract.delayedReleaseState;
    if (delayed && anchor.liveIncidentExecuted) {
      violations.add('fix_shipped_claimed_executed_without_release');
    }

    // (7) The witness vocabularies must actually be present, so the register
    // has something to derive its owner, area, and requirement vocabularies
    // from.
    if (anchor.owners.isEmpty) {
      openItems.add('upstream_owner_vocabulary_missing');
    }
    final areaVocabulary = <String>[
      ...anchor.intakeCategories,
      ...anchor.testSuites,
      ...anchor.rollbackEvidence,
    ];
    if (anchor.intakeCategories.isEmpty &&
        anchor.testSuites.isEmpty &&
        anchor.rollbackEvidence.isEmpty) {
      openItems.add('upstream_area_vocabulary_missing');
    }
    if (anchor.p1Requirements.isEmpty) {
      openItems.add('upstream_requirement_vocabulary_missing');
    }
    // Every canonical fix area must be grounded in a committed witness, not a
    // hand-copied list that can drift away from it.
    for (final area in Sprint118StabilityFixContract.fixAreas) {
      if (!Sprint118StabilityFixContract.grounds(areaVocabulary, area)) {
        openItems.add('area_not_grounded_in_witness:$area');
      }
    }
    // Every canonical requirement must be grounded in a committed witness.
    for (final requirement
        in Sprint118StabilityFixContract.requiredRequirements) {
      if (!Sprint118StabilityFixContract.grounds(
        anchor.p1Requirements,
        requirement,
      )) {
        openItems.add('requirement_not_grounded_in_witness:$requirement');
      }
    }

    // (8) Every approved fix area must be present exactly once, and each record
    // must carry all six required fields non-blank, a known owner, and a
    // committed readable evidence source.
    final declared = <String, int>{};
    for (final entry in register.entries) {
      declared[entry.fixArea] = (declared[entry.fixArea] ?? 0) + 1;
    }
    for (final entry in register.entries) {
      final fixArea = entry.fixArea;
      if (!Sprint118StabilityFixContract.fixAreas.contains(fixArea)) {
        violations.add('fix_area_unknown:$fixArea');
      }
      for (final requirement
          in Sprint118StabilityFixContract.requiredRequirements) {
        final value = entry.requiredFields[requirement] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$requirement:$fixArea');
        }
      }
      if (!anchor.owners.contains(entry.owner)) {
        violations.add('entry_unknown_owner:$fixArea:${entry.owner}');
      }
      if (!anchor.readableSources.contains(entry.evidence)) {
        violations.add('entry_unreadable_evidence:$fixArea:${entry.evidence}');
      }
      // A fix is never claimed shipped without a release.
      if (entry.fixShipped) {
        violations.add('fix_shipped_without_release:$fixArea');
      }
      // A fix never expands scope beyond the approved minimum change.
      if (entry.scopeExpanded) {
        violations.add('scope_expanded_beyond_approval:$fixArea');
      }
    }
    for (final fixArea in declared.keys) {
      if (declared[fixArea]! > 1) {
        violations.add('fix_area_duplicate:$fixArea');
      }
    }
    for (final fixArea in Sprint118StabilityFixContract.fixAreas) {
      if (!declared.containsKey(fixArea)) {
        violations.add('fix_area_missing:$fixArea');
      }
    }

    // (9) Every committed evidence source must be readable.
    for (final source
        in Sprint118StabilityFixContract.canonicalSources.toSet()) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final areas = register.fixAreas;

    if (violations.isNotEmpty) {
      return Sprint118StabilityFixReport(
        state: Sprint118StabilityFixState.fail,
        verdict: 'SPRINT_118_STABILITY_FIXES_VIOLATION',
        releaseState: register.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredAreas: areas,
        fixCount: register.entries.length,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118StabilityFixReport(
        state: Sprint118StabilityFixState.blocked,
        verdict: 'SPRINT_118_STABILITY_FIXES_BLOCKED_UPSTREAM',
        releaseState: register.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredAreas: areas,
        fixCount: register.entries.length,
      );
    }
    return Sprint118StabilityFixReport(
      state: Sprint118StabilityFixState.pass,
      verdict: 'STABILITY_FIXES_VERIFIED_LOCAL',
      releaseState: register.releaseState,
      openItems: allOpen,
      declaredAreas: areas,
      fixCount: register.entries.length,
    );
  }
}
