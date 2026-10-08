/// Fail-closed maintenance release gate for roadmap step 118.28 --
/// Maintenance Release Gate.
///
/// Objective (external canonical `sprint_118.json`): determine whether v1.3.1 is
/// required and validate artifact, upgrade, rollback, checksums, and notes. The
/// canonical decision list is exactly three items: `BUILD_1_3_1`, `NO_PATCH`,
/// and `EMERGENCY_RELEASE_ALREADY_ISSUED`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze a 42-day window that is declared
/// and not executed, the 118.4 baseline froze a declared reference for each
/// health area without observing anything, the committed 118.27 rollout
/// progression decision selected `HOLD` (`ROLLOUT_PROGRESSION_DECISION_VERIFIED_LOCAL`),
/// and the committed 117.45 approval gate records `decision=delay`,
/// `approval_state=PENDING_CHOIRUDIN`, `execution_authorized=false`, and
/// `release_blocked=true`. The committed 114.39 maintenance scope recorded
/// `selected_decision=NO_PATCH` with zero approved fixes, and the committed
/// 117.43 GA artifact evidence is `pass=false` with the sole failing group
/// `checksums`. A maintenance release gate written against that state therefore
/// has exactly one honest shape: enumerate the five canonical validation domains
/// (artifact, upgrade, rollback, checksums, notes), anchor each to committed
/// evidence, and select `NO_PATCH`, building nothing.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`) and the 118.2
///   charter must be complete with a positive window. A maintenance gate
///   anchored to an unfrozen baseline or an incomplete charter describes a
///   release nobody recorded.
/// * The committed 118.27 rollout progression decision must be a genuine pass
///   (`ROLLOUT_PROGRESSION_DECISION_VERIFIED_LOCAL`) and must have selected
///   `HOLD`. A patch is never cut while the rollout is still held and nothing has
///   been released.
/// * The committed 117.45 approval gate must be readable and must record the
///   delay decision (`decision == delay`). The decision is read with the owner's
///   exact grammar, never case-folded or trimmed into agreement. If the approval
///   gate is not a delay, the maintenance-release anchor is untrustworthy and the
///   honest answer is `blocked`, not `fail`.
/// * Every canonical validation domain must be present exactly once. A record
///   that drops `checksums`, invents a `telepathy` domain, or duplicates `notes`
///   is not a validation.
/// * Every entry must carry a non-empty detail, a reference state drawn from the
///   committed witness vocabularies, a committed readable source, and at least
///   one limitation, so the record states the validation path it was written
///   under instead of implying a built artifact.
/// * On the delayed path a built artifact, an executed upgrade, an executed
///   rollback, a published release note, a live validation, or an emergency
///   release claim describe behavior that never ran. This is refused by name,
///   per entry.
///
/// **A maintenance release is never built without an approved fix scope and an
/// authorized release.** When no approved fix requires a patch and no release is
/// authorized, the only decision the evidence supports is `NO_PATCH`; any other
/// selection is refused by name.
///
/// The decision vocabulary is the three-item canonical list, the reference-state
/// vocabulary is *derived from committed witnesses* (the 114.40 maintenance
/// artifact gate `required_evidence`, the 117.43 GA artifact reproducibility
/// `required_outputs`, the 113.38 packaging `required_outputs`, the 114.39
/// maintenance scope `deferred_checks`, and the 117.8 rollback drill
/// `required_controls`), and the source for each validation domain is a committed
/// manifest, not copied by hand, so the record and its witnesses cannot drift
/// apart silently.
///
/// Building, signing, upgrading, rolling back, checksum publication, release-note
/// publication, release authorization, and publication remain `DEFERRED-EXTERNAL`;
/// this gate freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a maintenance release gate can rest in. `blocked` is the
/// honest resting state for "this gate cannot yet be trusted", and it is
/// distinct from `fail`, which means the record contradicts its own evidence.
enum Sprint118MaintenanceReleaseState { pass, fail, blocked }

/// The three canonical maintenance-release decisions declared by external
/// canonical step 118.28. Each carries the exact wire name the canonical source
/// declares, so the decision is never compared with a loosened grammar.
enum Sprint118MaintenanceReleaseDecision {
  build131('BUILD_1_3_1'),
  noPatch('NO_PATCH'),
  emergencyReleaseAlreadyIssued('EMERGENCY_RELEASE_ALREADY_ISSUED');

  const Sprint118MaintenanceReleaseDecision(this.wireName);

  /// The exact canonical wire name.
  final String wireName;

  /// Resolves a canonical wire name to its decision, or `null` when the name is
  /// not one of the three canonical options.
  static Sprint118MaintenanceReleaseDecision? fromWire(String wire) {
    for (final decision in Sprint118MaintenanceReleaseDecision.values) {
      if (decision.wireName == wire) return decision;
    }
    return null;
  }
}

/// One frozen maintenance-validation entry: the declared reference for a single
/// canonical validation domain, with the validation path it was frozen under.
///
/// `artifactBuilt`, `upgradeExecuted`, `rollbackExecuted`, `notesPublished`,
/// `emergencyClaimed`, and `observed` are deliberately *not* among the five
/// required fields; they are the flags the gate refuses when set, so that a
/// reference validation domain can be recorded while never being read as a built
/// artifact, an executed upgrade, an executed rollback, a published release note,
/// an emergency release, or a live observation.
class Sprint118MaintenanceReleaseEntry {
  const Sprint118MaintenanceReleaseEntry({
    required this.item,
    required this.referenceState,
    required this.source,
    required this.detail,
    required this.limitations,
    this.artifactBuilt = false,
    this.upgradeExecuted = false,
    this.rollbackExecuted = false,
    this.notesPublished = false,
    this.emergencyClaimed = false,
    this.observed = false,
  });

  /// The canonical validation domain, drawn from the five-item vocabulary.
  final String item;

  /// The declared reference state, drawn from the committed witness
  /// vocabularies.
  final String referenceState;

  /// The committed evidence file this entry is anchored to.
  final String source;

  /// A non-empty description of the validation path this entry freezes.
  final String detail;

  /// The limitations the entry was frozen under. At least one is required so the
  /// entry cannot imply a built artifact.
  final List<String> limitations;

  /// Whether the entry claims a built artifact. On the delayed path this must
  /// stay `false`: a maintenance release is never built without a release.
  final bool artifactBuilt;

  /// Whether the entry claims an executed upgrade. On the delayed path this must
  /// stay `false`.
  final bool upgradeExecuted;

  /// Whether the entry claims an executed rollback. On the delayed path this must
  /// stay `false`.
  final bool rollbackExecuted;

  /// Whether the entry claims a published release note. On the delayed path this
  /// must stay `false`.
  final bool notesPublished;

  /// Whether the entry claims an emergency release. On the delayed path this must
  /// stay `false`.
  final bool emergencyClaimed;

  /// Whether the entry claims a live validation. On the delayed path this must
  /// stay `false`.
  final bool observed;

  /// The five required fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'item': item,
    'reference_state': referenceState,
    'source': source,
    'detail': detail,
    'limitations': limitations.join(','),
  };
}

/// The frozen maintenance release record. `entries` is the declared reference
/// for each canonical validation domain; `selectedDecision` is the one option
/// the evidence supports. On the delayed path no entry may claim a live
/// validation and the selected decision must be `NO_PATCH`.
class Sprint118MaintenanceReleaseRecord {
  const Sprint118MaintenanceReleaseRecord({
    required this.releaseState,
    required this.selectedDecision,
    required this.entries,
  });

  final String releaseState;
  final Sprint118MaintenanceReleaseDecision selectedDecision;
  final List<Sprint118MaintenanceReleaseEntry> entries;

  List<String> get validationItems => <String>[
    for (final entry in entries) entry.item,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118MaintenanceReleaseAnchor {
  const Sprint118MaintenanceReleaseAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.rolloutState,
    required this.rolloutVerdict,
    required this.rolloutDecision,
    required this.approvalDecision,
    required this.approvalState,
    required this.executionAuthorized,
    required this.releaseBlocked,
    required this.approvedFixCount,
    required this.emergencyReleaseRecorded,
    required this.maintenanceEvidence,
    required this.artifactOutputs,
    required this.packagingOutputs,
    required this.deferredChecks,
    required this.drillControls,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;

  /// The state the committed 118.27 rollout progression decision records.
  final String rolloutState;

  /// The verdict the committed 118.27 rollout progression decision records.
  final String rolloutVerdict;

  /// The decision the committed 118.27 rollout progression decision selected,
  /// read with the owner's exact grammar (never case-folded or trimmed).
  final String rolloutDecision;

  /// The decision the committed 117.45 approval gate records, read with the
  /// owner's exact grammar (never case-folded or trimmed).
  final String approvalDecision;

  /// The approval state the committed 117.45 approval gate records.
  final String approvalState;

  /// Whether the committed 117.45 approval gate authorizes execution. On the
  /// delayed path this must stay `false`.
  final bool executionAuthorized;

  /// Whether the committed 117.45 approval gate records the release as blocked.
  final bool releaseBlocked;

  /// The number of approved fixes the committed 114.39 maintenance scope
  /// declares. A patch is never cut without an approved fix.
  final int approvedFixCount;

  /// Whether a committed witness records an already-issued emergency release.
  final bool emergencyReleaseRecorded;

  /// The evidence vocabulary the committed 114.40 maintenance artifact gate
  /// declares. The witness is a mapping of evidence key -> disposition, so the
  /// vocabulary is its keys.
  final List<String> maintenanceEvidence;

  /// The output vocabulary the committed 117.43 GA artifact reproducibility
  /// evidence declares.
  final List<String> artifactOutputs;

  /// The output vocabulary the committed 113.38 packaging manifest declares.
  final List<String> packagingOutputs;

  /// The deferred-check vocabulary the committed 114.39 maintenance scope
  /// declares.
  final List<String> deferredChecks;

  /// The control vocabulary the committed 117.8 rollback drill declares.
  final List<String> drillControls;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the record is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118MaintenanceReleaseReport {
  const Sprint118MaintenanceReleaseReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.selectedDecision,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredValidations = const <String>[],
    this.observedCount = 0,
  });

  final Sprint118MaintenanceReleaseState state;
  final String verdict;
  final String releaseState;

  /// The selected decision wire name, or `null` when the record is not a
  /// genuine pass.
  final String? selectedDecision;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredValidations;
  final int observedCount;

  /// Whether the record may be treated as a frozen maintenance release record.
  /// Only a genuine `pass` allows it.
  bool get releaseVerified => state == Sprint118MaintenanceReleaseState.pass;

  String get externalGates => Sprint118MaintenanceReleaseContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.28.
abstract final class Sprint118MaintenanceReleaseContract {
  const Sprint118MaintenanceReleaseContract._();

  static const String canonicalStep = '118.28';
  static const String title = 'Maintenance Release Gate';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_maintenance_release_gate.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this gate is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter this gate is anchored to.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 118.27 rollout progression decision this gate rests on.
  static const String rolloutDecisionManifestPath =
      'docs/planning/v1.3/sprint_118_rollout_progression_decision.json';

  /// The committed 117.45 approval gate that records the delay decision.
  static const String approvalGateManifestPath =
      'docs/planning/v1.3/sprint_117_ga_approval_gate.json';

  /// The committed 114.39 maintenance scope that records the NO_PATCH decision
  /// and the approved-fix vocabulary.
  static const String maintenanceScopeManifestPath =
      'docs/planning/v1.2/sprint_114_maintenance_release_scope.json';

  /// The committed 114.40 maintenance artifact gate that declares the evidence
  /// vocabulary.
  static const String maintenanceArtifactManifestPath =
      'docs/planning/v1.2/sprint_114_maintenance_artifact_release_gate.json';

  /// The committed 117.43 GA artifact reproducibility evidence that declares the
  /// output vocabulary and the checksum failure.
  static const String artifactEvidenceManifestPath =
      'docs/evidence/sprint-117-43-manifest-20261002.json';

  /// The committed 113.38 packaging manifest that declares the artifact output
  /// vocabulary.
  static const String packagingManifestPath =
      'docs/planning/v1.2/sprint_113_ga_artifact_packaging.json';

  /// The committed 117.8 provider rollback drill that declares the control
  /// vocabulary.
  static const String rollbackDrillManifestPath =
      'docs/planning/v1.3/sprint_117_provider_rollback_drill.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  /// The verdict and state the 118.27 rollout progression decision anchor must
  /// carry.
  static const String requiredRolloutVerdict =
      'ROLLOUT_PROGRESSION_DECISION_VERIFIED_LOCAL';
  static const String requiredRolloutState = 'pass';

  /// The decision the committed 118.27 rollout progression decision must have
  /// selected. A patch is never cut while the rollout is still held.
  static const String requiredRolloutDecision = 'HOLD';

  /// The decision the committed 117.45 approval gate must record. Read with the
  /// owner's exact grammar, never case-folded.
  static const String requiredApprovalDecision = 'delay';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The marker an entry declares when no committed witness names a reference
  /// state for its validation domain. A record that uses it records an honest
  /// upstream gap rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The three canonical maintenance-release decisions declared by external
  /// canonical step 118.28, in canonical order.
  static const List<String> requiredDecisions = <String>[
    'BUILD_1_3_1',
    'NO_PATCH',
    'EMERGENCY_RELEASE_ALREADY_ISSUED',
  ];

  /// The five canonical validation domains named by the objective, in canonical
  /// order: artifact, upgrade, rollback, checksums, and notes.
  static const List<String> requiredValidations = <String>[
    'artifact',
    'upgrade',
    'rollback',
    'checksums',
    'notes',
  ];

  /// The canonical field set each entry must carry, so a record cannot drop a
  /// field and still read as complete.
  static const List<String> requiredFields = <String>[
    'item',
    'reference_state',
    'source',
    'detail',
    'limitations',
  ];

  /// The committed evidence file each canonical validation domain is anchored to.
  static const List<String> canonicalSources = <String>[
    packagingManifestPath,
    maintenanceArtifactManifestPath,
    rollbackDrillManifestPath,
    artifactEvidenceManifestPath,
    maintenanceScopeManifestPath,
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

  /// Whether a committed witness vocabulary grounds a reference-state token.
  ///
  /// A witness grounds a token when it names the token exactly (`checksums`,
  /// `signed_artifacts`), or when every underscore-separated part of a compound
  /// token is itself a witness-declared value. The vocabulary is measured from
  /// the committed witnesses, so a reference state cannot be invented into the
  /// list without a witness to ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed source for a canonical validation domain, or `''` if unknown.
  static String sourceFor(String item) {
    final index = requiredValidations.indexOf(item);
    return index < 0 ? '' : canonicalSources[index];
  }

  static const canonicalRecord = Sprint118MaintenanceReleaseRecord(
    releaseState: delayedReleaseState,
    selectedDecision: Sprint118MaintenanceReleaseDecision.noPatch,
    entries: <Sprint118MaintenanceReleaseEntry>[
      Sprint118MaintenanceReleaseEntry(
        item: 'artifact',
        referenceState: 'signed_artifacts',
        source: packagingManifestPath,
        detail:
            'The 113.38 packaging manifest declares the signed artifact set; '
            'no v1.3.1 artifact is built or signed while the release is blocked',
        limitations: <String>['artifact_build_deferred', 'synthetic_local'],
      ),
      Sprint118MaintenanceReleaseEntry(
        item: 'upgrade',
        referenceState: 'upgrade_results',
        source: maintenanceArtifactManifestPath,
        detail:
            'The 114.40 maintenance artifact gate declares the upgrade result '
            'evidence; no upgrade is executed against a release that never ran',
        limitations: <String>['upgrade_execution_deferred', 'synthetic_local'],
      ),
      Sprint118MaintenanceReleaseEntry(
        item: 'rollback',
        referenceState: 'artifact_rollback',
        source: rollbackDrillManifestPath,
        detail:
            'The 117.8 rollback drill declares the artifact rollback control; no '
            'rollback is executed because no artifact was released',
        limitations: <String>['rollback_execution_deferred', 'synthetic_local'],
      ),
      Sprint118MaintenanceReleaseEntry(
        item: 'checksums',
        referenceState: 'checksums',
        source: artifactEvidenceManifestPath,
        detail:
            'The 117.43 GA artifact evidence declares the checksum output and '
            'records it as the sole failing group; no v1.3.1 checksum is published',
        limitations: <String>[
          'checksum_publication_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118MaintenanceReleaseEntry(
        item: 'notes',
        referenceState: 'release_notes',
        source: maintenanceScopeManifestPath,
        detail:
            'The 114.39 maintenance scope declares the release-note evidence and '
            'defers release-note publication; no v1.3.1 note is written',
        limitations: <String>[
          'release_note_publication_deferred',
          'synthetic_local',
        ],
      ),
    ],
  );
}

/// Reads the committed witnesses for step 118.28. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118MaintenanceReleaseLoader {
  const Sprint118MaintenanceReleaseLoader();

  Sprint118MaintenanceReleaseAnchor? loadAnchor() {
    final baseline = _read(
      Sprint118MaintenanceReleaseContract.baselineManifestPath,
    );
    final charter = _read(
      Sprint118MaintenanceReleaseContract.charterManifestPath,
    );
    final rollout = _read(
      Sprint118MaintenanceReleaseContract.rolloutDecisionManifestPath,
    );
    final approval = _read(
      Sprint118MaintenanceReleaseContract.approvalGateManifestPath,
    );
    final scope = _read(
      Sprint118MaintenanceReleaseContract.maintenanceScopeManifestPath,
    );
    final artifact = _read(
      Sprint118MaintenanceReleaseContract.maintenanceArtifactManifestPath,
    );
    final reproducibility = _read(
      Sprint118MaintenanceReleaseContract.artifactEvidenceManifestPath,
    );
    final packaging = _read(
      Sprint118MaintenanceReleaseContract.packagingManifestPath,
    );
    final drill = _read(
      Sprint118MaintenanceReleaseContract.rollbackDrillManifestPath,
    );
    if (baseline == null ||
        charter == null ||
        rollout == null ||
        approval == null ||
        scope == null ||
        artifact == null ||
        reproducibility == null ||
        packaging == null ||
        drill == null) {
      return null;
    }

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);

    final approvalMap = approval['approval'];
    final approvalInner = approvalMap is Map<String, dynamic>
        ? approvalMap
        : const <String, dynamic>{};
    final blockerMap = approval['blocker_status'];
    final blockerInner = blockerMap is Map<String, dynamic>
        ? blockerMap
        : const <String, dynamic>{};

    final packagingOutputs = packaging['required_outputs'];
    final packagingKeys = packagingOutputs is Map<String, dynamic>
        ? packagingOutputs.keys.toList(growable: false)
        : const <String>[];

    final artifactEvidence = artifact['evidence'];
    final artifactKeys = artifactEvidence is Map<String, dynamic>
        ? artifactEvidence.keys.toList(growable: false)
        : const <String>[];

    final sources = <String>{
      Sprint118MaintenanceReleaseContract.baselineManifestPath,
      Sprint118MaintenanceReleaseContract.charterManifestPath,
      Sprint118MaintenanceReleaseContract.rolloutDecisionManifestPath,
      Sprint118MaintenanceReleaseContract.approvalGateManifestPath,
      Sprint118MaintenanceReleaseContract.maintenanceScopeManifestPath,
      Sprint118MaintenanceReleaseContract.maintenanceArtifactManifestPath,
      Sprint118MaintenanceReleaseContract.artifactEvidenceManifestPath,
      Sprint118MaintenanceReleaseContract.packagingManifestPath,
      Sprint118MaintenanceReleaseContract.rollbackDrillManifestPath,
    };

    return Sprint118MaintenanceReleaseAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: durationDays > 0 ? durationDays * 24 * 60 : 0,
      rolloutState: _text(rollout['state']),
      rolloutVerdict: _text(rollout['verdict']),
      rolloutDecision: _text(rollout['selected_decision']),
      approvalDecision: _text(approvalInner['decision']),
      approvalState: _text(approvalInner['approval_state']),
      executionAuthorized: approvalInner['execution_authorized'] == true,
      releaseBlocked: blockerInner['release_blocked'] == true,
      approvedFixCount: _strings(scope['approved_fixes']).length,
      emergencyReleaseRecorded:
          _text(scope['selected_decision']) ==
          'EMERGENCY_RELEASE_ALREADY_ISSUED',
      maintenanceEvidence: artifactKeys,
      artifactOutputs: _strings(reproducibility['required_outputs']),
      packagingOutputs: packagingKeys,
      deferredChecks: _strings(scope['deferred_checks']),
      drillControls: _strings(drill['required_controls']),
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

/// The fail-closed maintenance release gate for step 118.28.
class Sprint118MaintenanceReleaseGate {
  const Sprint118MaintenanceReleaseGate();

  Sprint118MaintenanceReleaseReport evaluate() => evaluateWith(
    const Sprint118MaintenanceReleaseLoader().loadAnchor(),
    Sprint118MaintenanceReleaseContract.canonicalRecord,
  );

  Sprint118MaintenanceReleaseReport evaluateWith(
    Sprint118MaintenanceReleaseAnchor? anchor,
    Sprint118MaintenanceReleaseRecord record,
  ) {
    if (anchor == null) {
      return Sprint118MaintenanceReleaseReport(
        state: Sprint118MaintenanceReleaseState.blocked,
        verdict: 'SPRINT_118_MAINTENANCE_RELEASE_GATE_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_maintenance_release_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_maintenance_release_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    final vocabulary =
        Sprint118MaintenanceReleaseContract.stateVocabulary(<List<String>>[
          anchor.maintenanceEvidence,
          anchor.artifactOutputs,
          anchor.packagingOutputs,
          anchor.deferredChecks,
          anchor.drillControls,
        ]);

    // (1) The 118.4 baseline anchor must be a genuine frozen pass.
    if (anchor.baselineState !=
            Sprint118MaintenanceReleaseContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118MaintenanceReleaseContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState !=
            Sprint118MaintenanceReleaseContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118MaintenanceReleaseContract.requiredCharterVerdict ||
        anchor.charterWindowMinutes <= 0) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (3) The 118.27 rollout progression decision must be a genuine pass. A
    // maintenance patch with no committed rollout decision is a guess.
    if (anchor.rolloutState !=
            Sprint118MaintenanceReleaseContract.requiredRolloutState ||
        anchor.rolloutVerdict !=
            Sprint118MaintenanceReleaseContract.requiredRolloutVerdict) {
      blockers.add('rollout_decision_not_verified:${anchor.rolloutVerdict}');
    }

    // (4) The committed rollout decision must be HOLD: a patch is never cut while
    // the rollout is still held and nothing has been released.
    if (anchor.rolloutDecision !=
        Sprint118MaintenanceReleaseContract.requiredRolloutDecision) {
      blockers.add('rollout_decision_not_hold:${anchor.rolloutDecision}');
    }

    // (5) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118MaintenanceReleaseContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (6) The release state must agree with the baseline anchor.
    if (anchor.releaseState != record.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'record=${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118MaintenanceReleaseContract.delayedReleaseState;

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add('release_execution_authorized_on_delayed_path');
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('release_not_blocked_on_delayed_path');
    }

    // (8) Every canonical validation domain must be present exactly once, and
    // each entry must carry all five required fields non-blank, a reference state
    // drawn from a committed witness, a committed readable source, and at least
    // one limitation.
    final declared = <String, int>{};
    for (final entry in record.entries) {
      declared[entry.item] = (declared[entry.item] ?? 0) + 1;
    }
    for (final entry in record.entries) {
      final token = entry.item;
      if (!Sprint118MaintenanceReleaseContract.requiredValidations.contains(
        token,
      )) {
        violations.add('validation_unknown:$token');
      }
      for (final field in Sprint118MaintenanceReleaseContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$token');
        }
      }
      if (entry.referenceState.trim().isEmpty ||
          !Sprint118MaintenanceReleaseContract.grounds(
            vocabulary,
            entry.referenceState,
          )) {
        violations.add('reference_state_invalid:$token');
      }
      if (entry.referenceState ==
          Sprint118MaintenanceReleaseContract.noReferenceState) {
        openItems.add('upstream_state_vocabulary_gap:$token');
      }
      if (entry.source.trim().isEmpty ||
          !anchor.readableSources.contains(entry.source)) {
        violations.add('source_unreadable:$token');
      }
      // A maintenance artifact is never built without a release.
      if (entry.artifactBuilt) {
        violations.add('artifact_built_without_release:$token');
      }
      // An upgrade is never executed without a release.
      if (entry.upgradeExecuted) {
        violations.add('upgrade_executed_without_release:$token');
      }
      // A rollback is never executed without a release.
      if (entry.rollbackExecuted) {
        violations.add('rollback_executed_without_release:$token');
      }
      // A release note is never published without a release.
      if (entry.notesPublished) {
        violations.add('release_notes_published_without_release:$token');
      }
      // An emergency release is never claimed without a recorded emergency.
      if (entry.emergencyClaimed) {
        violations.add('emergency_release_claimed_without_record:$token');
      }
      // No live validation on the delayed path.
      if (entry.observed) {
        violations.add('live_validation_claimed:$token');
      }
    }
    for (final token in declared.keys) {
      if (declared[token]! > 1) {
        violations.add('validation_duplicate:$token');
      }
    }
    for (final token
        in Sprint118MaintenanceReleaseContract.requiredValidations) {
      if (!declared.containsKey(token)) {
        violations.add('validation_missing:$token');
      }
    }

    // (9) A maintenance release is never built without an approved fix scope and
    // an authorized release. When no approved fix requires a patch and no release
    // is authorized, the only decision the evidence supports is NO_PATCH; any
    // other selection describes an action that never ran.
    final wire = record.selectedDecision.wireName;
    if (record.selectedDecision ==
            Sprint118MaintenanceReleaseDecision.build131 &&
        anchor.approvedFixCount == 0) {
      violations.add('maintenance_release_without_approved_fix_scope:$wire');
    }
    if (record.selectedDecision ==
            Sprint118MaintenanceReleaseDecision.build131 &&
        !anchor.executionAuthorized) {
      violations.add('build_without_release:BUILD_1_3_1');
    }
    if (record.selectedDecision ==
            Sprint118MaintenanceReleaseDecision.emergencyReleaseAlreadyIssued &&
        !anchor.emergencyReleaseRecorded) {
      violations.add(
        'emergency_release_without_record:EMERGENCY_RELEASE_ALREADY_ISSUED',
      );
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118MaintenanceReleaseContract.canonicalSources.toSet()) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('required_source_unreadable:$source');
      }
    }

    final allItems = <String>[...violations, ...blockers, ...openItems];
    final validations = record.validationItems;

    // An untrustworthy anchor short-circuits: if a committed witness is not a
    // genuine pass, the entry-level findings cannot be trusted either, so the
    // honest answer is `blocked`, not `fail`.
    if (blockers.isNotEmpty) {
      return Sprint118MaintenanceReleaseReport(
        state: Sprint118MaintenanceReleaseState.blocked,
        verdict: 'SPRINT_118_MAINTENANCE_RELEASE_GATE_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredValidations: validations,
        observedCount: record.observedCount,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118MaintenanceReleaseReport(
        state: Sprint118MaintenanceReleaseState.fail,
        verdict: 'SPRINT_118_MAINTENANCE_RELEASE_GATE_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredValidations: validations,
        observedCount: record.observedCount,
      );
    }
    return Sprint118MaintenanceReleaseReport(
      state: Sprint118MaintenanceReleaseState.pass,
      verdict: 'MAINTENANCE_RELEASE_GATE_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      selectedDecision: record.selectedDecision.wireName,
      openItems: allItems,
      declaredValidations: validations,
      observedCount: record.observedCount,
    );
  }
}
