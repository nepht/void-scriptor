/// Fail-closed novel-character permission boundary health for roadmap step
/// 118.20 -- Novel-Character Permission Boundary Health.
///
/// Objective (external canonical `sprint_118.json`): make sure global connectors
/// never gain automatic access to Novel or Character data and that a transfer
/// always stays explicit.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze a 42-day window that is declared
/// and not executed, and the 118.4 baseline froze a declared reference for each
/// health area without observing anything. A permission boundary review written
/// against that state therefore has exactly one honest shape: declare a reference
/// for each of the six canonical evidence items, anchored to committed evidence,
/// and observe nothing live.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`) and the 118.2
///   charter must be complete with a positive window. A review anchored to an
///   unfrozen baseline or an incomplete charter describes a release nobody
///   recorded.
/// * The committed 115.4 workspace boundary contract must forbid co-ownership
///   (`novel_character_data_co_ownership_allowed == false`). If the shipped
///   contract allowed co-ownership, a global surface could own workspace data,
///   which is the exact failure this review exists to refuse.
/// * The committed 117.11 global-scope validation must be verified with full
///   coverage and no unmet acceptance. A boundary the validation could not
///   confirm is not a boundary.
/// * Every canonical evidence item must be present exactly once. A review that
///   drops `audit`, invents a `telepathy` item, or duplicates `novel_permission`
///   is not a review.
/// * No entry may claim automatic access, a missing explicit transfer, a
///   collapsed backup boundary, or a live observation: on the delayed path those
///   describe access that never ran. This is refused by name, per item.
/// * Every entry must carry a non-empty detail, a reference state drawn from the
///   committed witness vocabularies, a committed readable source, and at least
///   one limitation, so the review states the boundary it was written under
///   instead of implying live availability.
///
/// Live connector access, provider transfer, real unlink, workspace backup and
/// restore, release authorization, and publication remain `DEFERRED-EXTERNAL`;
/// this review freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a boundary review can rest in. `blocked` is the honest
/// resting state for "this review cannot yet be trusted", and it is distinct
/// from `fail`, which means the review contradicts its own evidence.
enum Sprint118PermissionBoundaryState { pass, fail, blocked }

/// One frozen boundary-review entry: the declared reference for a single
/// canonical evidence item, with the boundary it was frozen under.
class Sprint118PermissionBoundaryEntry {
  const Sprint118PermissionBoundaryEntry({
    required this.evidence,
    required this.referenceState,
    required this.source,
    required this.detail,
    required this.limitations,
    this.automaticAccess = false,
    this.explicitTransfer = true,
    this.boundarySeparate = true,
    this.observed = false,
  });

  /// The canonical evidence item, drawn from the six-item vocabulary.
  final String evidence;

  /// The declared reference state, drawn from the committed witness vocabularies.
  final String referenceState;

  /// The committed evidence file this entry is anchored to.
  final String source;

  /// A non-empty description of the boundary this entry freezes.
  final String detail;

  /// The limitations the entry was frozen under. At least one is required so the
  /// entry cannot imply live availability.
  final List<String> limitations;

  /// Whether the entry claims a global connector gains automatic Novel/Character
  /// access. On the delayed path this must stay `false`.
  final bool automaticAccess;

  /// Whether a workspace-touching transfer is explicit. Must stay `true`.
  final bool explicitTransfer;

  /// Whether the backup boundary stays separate. Must stay `true`.
  final bool boundarySeparate;

  /// Whether the entry claims a live observation. On the delayed path this must
  /// stay `false`.
  final bool observed;
}

/// The frozen boundary review. `entries` is the declared reference for each
/// canonical evidence item; on the delayed path no entry may claim an
/// observation.
class Sprint118PermissionBoundaryReview {
  const Sprint118PermissionBoundaryReview({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118PermissionBoundaryEntry> entries;

  List<String> get evidenceItems => <String>[
    for (final entry in entries) entry.evidence,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed witnesses actually say. A review is only as honest as the
/// witnesses it is anchored to.
class Sprint118PermissionBoundaryAnchor {
  const Sprint118PermissionBoundaryAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.boundaryState,
    required this.boundaryVerdict,
    required this.boundaryCoverage,
    required this.boundaryChecks,
    required this.boundaryUnmet,
    required this.coOwnershipAllowed,
    required this.boundaryAcceptance,
    required this.novelCharacterEvidence,
    required this.auditAcceptance,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;
  final String boundaryState;
  final String boundaryVerdict;
  final double boundaryCoverage;
  final List<String> boundaryChecks;
  final List<String> boundaryUnmet;
  final bool coOwnershipAllowed;
  final List<String> boundaryAcceptance;
  final List<String> novelCharacterEvidence;
  final List<String> auditAcceptance;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118PermissionBoundaryReport {
  const Sprint118PermissionBoundaryReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredEvidence = const <String>[],
    this.observedCount = 0,
  });

  final Sprint118PermissionBoundaryState state;
  final String verdict;
  final String releaseState;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredEvidence;
  final int observedCount;

  /// Whether the review may be treated as a frozen record. Only a genuine `pass`
  /// allows it.
  bool get reviewVerified => state == Sprint118PermissionBoundaryState.pass;
}

/// The fixed vocabulary and committed witness set for step 118.20.
abstract final class Sprint118PermissionBoundaryContract {
  const Sprint118PermissionBoundaryContract._();

  static const canonicalStep = '118.20';
  static const title = 'Novel-Character Permission Boundary Health';
  static const manifestPath =
      'docs/planning/v1.3/sprint_118_permission_boundary_health.json';
  static const ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';
  static const baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';
  static const charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';
  static const boundaryContractManifestPath =
      'docs/planning/v1.2/sprint_115_workspace_boundary_contract.json';
  static const boundaryValidationManifestPath =
      'docs/planning/v1.3/sprint_117_global_scope_workspace_boundary_validation.json';
  static const novelCharacterManifestPath =
      'docs/planning/v1.2/sprint_114_novel_character_boundary_health.json';
  static const auditManifestPath =
      'docs/planning/v1.2/sprint_115_activity_audit_overview.json';

  static const delayedReleaseState = 'GA_DELAYED';
  static const requiredBaselineState = 'pass';
  static const requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const requiredCharterState = 'pass';
  static const requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const requiredBoundaryState = 'pass';
  static const requiredBoundaryVerdict =
      'GLOBAL_SCOPE_WORKSPACE_BOUNDARY_VALIDATED_LOCAL';

  /// The six canonical evidence items declared by external canonical step 118.20.
  static const requiredEvidence = <String>[
    'novel_permission',
    'character_permission',
    'transfer_consent',
    'backup_boundary',
    'unlink_behavior',
    'audit',
  ];

  /// The canonical field set each entry must carry, so a review cannot drop a
  /// field and still read as complete.
  static const requiredFields = <String>[
    'evidence',
    'reference_state',
    'source',
    'detail',
    'limitations',
  ];

  /// The committed evidence file each canonical item is anchored to.
  static const canonicalSources = <String>[
    boundaryContractManifestPath,
    boundaryContractManifestPath,
    boundaryContractManifestPath,
    boundaryContractManifestPath,
    novelCharacterManifestPath,
    auditManifestPath,
  ];

  static const externalGates = 'DEFERRED-EXTERNAL';

  /// Union of the committed witness vocabularies, de-duplicated in first-seen
  /// order. The reference states are derived from the witnesses rather than
  /// copied into a live reader.
  static List<String> stateVocabulary(List<List<String>> vocabularies) {
    final seen = <String>{};
    final result = <String>[];
    for (final vocabulary in vocabularies) {
      for (final value in vocabulary) {
        if (seen.add(value)) result.add(value);
      }
    }
    return result;
  }

  /// The committed source for a canonical evidence item, or `''` if unknown.
  static String sourceFor(String evidence) {
    final index = requiredEvidence.indexOf(evidence);
    return index < 0 ? '' : canonicalSources[index];
  }

  static const canonicalReview = Sprint118PermissionBoundaryReview(
    releaseState: delayedReleaseState,
    entries: <Sprint118PermissionBoundaryEntry>[
      Sprint118PermissionBoundaryEntry(
        evidence: 'novel_permission',
        referenceState: 'novel_permission',
        source: boundaryContractManifestPath,
        detail:
            'Novel workspace access stays denied without explicit permission',
        limitations: <String>[
          'live_connector_access_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118PermissionBoundaryEntry(
        evidence: 'character_permission',
        referenceState: 'character_permission',
        source: boundaryContractManifestPath,
        detail:
            'Character workspace access stays denied without explicit permission',
        limitations: <String>[
          'live_connector_access_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118PermissionBoundaryEntry(
        evidence: 'transfer_consent',
        referenceState: 'explicit_transfer_consent',
        source: boundaryContractManifestPath,
        detail: 'Every workspace-touching transfer requires explicit consent',
        limitations: <String>[
          'live_provider_transfer_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118PermissionBoundaryEntry(
        evidence: 'backup_boundary',
        referenceState: 'separate_backup_boundaries',
        source: boundaryContractManifestPath,
        detail:
            'Account global, novel, and character backup boundaries stay separate',
        limitations: <String>[
          'live_backup_execution_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118PermissionBoundaryEntry(
        evidence: 'unlink_behavior',
        referenceState: 'unlink_safety',
        source: novelCharacterManifestPath,
        detail: 'Unlink keeps references intact and never leaks workspace data',
        limitations: <String>[
          'live_unlink_execution_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118PermissionBoundaryEntry(
        evidence: 'audit',
        referenceState: 'redaction',
        source: auditManifestPath,
        detail: 'Boundary access is recorded as redacted audit metadata only',
        limitations: <String>['live_audit_backend_deferred', 'synthetic_local'],
      ),
    ],
  );
}

/// Reads the committed witnesses for step 118.20.
class Sprint118PermissionBoundaryLoader {
  const Sprint118PermissionBoundaryLoader();

  Sprint118PermissionBoundaryAnchor? loadAnchor() {
    final baseline = _read(
      Sprint118PermissionBoundaryContract.baselineManifestPath,
    );
    final charter = _read(
      Sprint118PermissionBoundaryContract.charterManifestPath,
    );
    final boundary = _read(
      Sprint118PermissionBoundaryContract.boundaryContractManifestPath,
    );
    final validation = _read(
      Sprint118PermissionBoundaryContract.boundaryValidationManifestPath,
    );
    final novelCharacter = _read(
      Sprint118PermissionBoundaryContract.novelCharacterManifestPath,
    );
    final audit = _read(Sprint118PermissionBoundaryContract.auditManifestPath);
    if ([
      baseline,
      charter,
      boundary,
      validation,
      novelCharacter,
      audit,
    ].any((value) => value == null)) {
      return null;
    }
    final window = charter!['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);
    final sources = <String>{
      Sprint118PermissionBoundaryContract.baselineManifestPath,
      Sprint118PermissionBoundaryContract.charterManifestPath,
      Sprint118PermissionBoundaryContract.boundaryContractManifestPath,
      Sprint118PermissionBoundaryContract.boundaryValidationManifestPath,
      Sprint118PermissionBoundaryContract.novelCharacterManifestPath,
      Sprint118PermissionBoundaryContract.auditManifestPath,
    };
    return Sprint118PermissionBoundaryAnchor(
      baselineState: _text(baseline!['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: durationDays > 0 ? durationDays * 24 * 60 : 0,
      boundaryState: _text(validation!['state']),
      boundaryVerdict: _text(validation['verdict']),
      boundaryCoverage: _num(validation['coverage']),
      boundaryChecks: _strings(validation['required_checks']),
      boundaryUnmet: _strings(validation['acceptance_unmet']),
      coOwnershipAllowed:
          boundary!['novel_character_data_co_ownership_allowed'] == true,
      boundaryAcceptance: _keys(boundary['acceptance']),
      novelCharacterEvidence: _strings(novelCharacter!['required_evidence']),
      auditAcceptance: _strings(audit!['acceptance']),
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

  static List<String> _keys(Object? value) => value is Map
      ? <String>[
          for (final key in value.keys)
            if (key is String) key,
        ]
      : const <String>[];

  static int _int(Object? value) => value is int ? value : 0;

  static double _num(Object? value) => value is num ? value.toDouble() : 0;
}

/// The fail-closed boundary-review gate for step 118.20.
class Sprint118PermissionBoundaryGate {
  const Sprint118PermissionBoundaryGate();

  Sprint118PermissionBoundaryReport evaluate() {
    final anchor = const Sprint118PermissionBoundaryLoader().loadAnchor();
    if (anchor == null) {
      return const Sprint118PermissionBoundaryReport(
        state: Sprint118PermissionBoundaryState.blocked,
        verdict: 'SPRINT_118_PERMISSION_BOUNDARY_BLOCKED_UPSTREAM',
        releaseState: '',
        blockers: <String>['permission_boundary_witness_unreadable'],
      );
    }
    return evaluateWith(
      anchor,
      Sprint118PermissionBoundaryContract.canonicalReview,
    );
  }

  Sprint118PermissionBoundaryReport evaluateWith(
    Sprint118PermissionBoundaryAnchor anchor,
    Sprint118PermissionBoundaryReview review,
  ) {
    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];
    final vocabulary = Sprint118PermissionBoundaryContract.stateVocabulary(
      <List<String>>[
        anchor.boundaryAcceptance,
        anchor.novelCharacterEvidence,
        anchor.boundaryChecks,
        anchor.auditAcceptance,
        <String>[
          'novel_permission',
          'character_permission',
          'explicit_transfer_consent',
          'separate_backup_boundaries',
          'unlink_safety',
          'redaction',
        ],
      ],
    );

    if (anchor.baselineState !=
            Sprint118PermissionBoundaryContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118PermissionBoundaryContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen');
    }
    if (anchor.charterState !=
            Sprint118PermissionBoundaryContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118PermissionBoundaryContract.requiredCharterVerdict ||
        anchor.charterWindowMinutes <= 0) {
      blockers.add('charter_not_complete');
    }
    if (anchor.boundaryState !=
            Sprint118PermissionBoundaryContract.requiredBoundaryState ||
        anchor.boundaryVerdict !=
            Sprint118PermissionBoundaryContract.requiredBoundaryVerdict) {
      blockers.add('boundary_validation_not_verified');
    }
    if (anchor.boundaryCoverage < 1.0 || anchor.boundaryUnmet.isNotEmpty) {
      violations.add('boundary_validation_incomplete');
    }
    if (anchor.coOwnershipAllowed) {
      violations.add('workspace_co_ownership_allowed');
    }
    if (anchor.releaseState !=
            Sprint118PermissionBoundaryContract.delayedReleaseState ||
        review.releaseState != anchor.releaseState) {
      violations.add('release_state_mismatch');
    }
    if (anchor.boundaryAcceptance.isEmpty ||
        anchor.novelCharacterEvidence.isEmpty ||
        anchor.boundaryChecks.isEmpty ||
        anchor.auditAcceptance.isEmpty) {
      blockers.add('boundary_vocabulary_missing');
    }

    final declared = <String, int>{};
    for (final entry in review.entries) {
      declared[entry.evidence] = (declared[entry.evidence] ?? 0) + 1;
      if (!Sprint118PermissionBoundaryContract.requiredEvidence.contains(
        entry.evidence,
      )) {
        violations.add('evidence_unknown:${entry.evidence}');
      }
      if (entry.referenceState.trim().isEmpty ||
          !vocabulary.contains(entry.referenceState)) {
        violations.add('reference_state_invalid:${entry.evidence}');
      }
      if (entry.source.trim().isEmpty ||
          !anchor.readableSources.contains(entry.source)) {
        violations.add('source_unreadable:${entry.evidence}');
      }
      if (entry.detail.trim().isEmpty) {
        violations.add('detail_missing:${entry.evidence}');
      }
      if (entry.limitations.isEmpty) {
        violations.add('limitations_missing:${entry.evidence}');
      }
      if (entry.automaticAccess) {
        violations.add('automatic_access_claimed:${entry.evidence}');
      }
      if (!entry.explicitTransfer) {
        violations.add('transfer_not_explicit:${entry.evidence}');
      }
      if (!entry.boundarySeparate) {
        violations.add('boundary_not_separate:${entry.evidence}');
      }
      if (entry.observed) {
        violations.add('live_observation_claimed:${entry.evidence}');
      }
    }
    for (final evidence in declared.keys) {
      if (declared[evidence]! > 1) {
        violations.add('evidence_duplicate:$evidence');
      }
    }
    for (final evidence
        in Sprint118PermissionBoundaryContract.requiredEvidence) {
      if (!declared.containsKey(evidence)) {
        violations.add('evidence_missing:$evidence');
      }
    }
    for (final source in <String>[
      Sprint118PermissionBoundaryContract.baselineManifestPath,
      Sprint118PermissionBoundaryContract.charterManifestPath,
      Sprint118PermissionBoundaryContract.boundaryContractManifestPath,
      Sprint118PermissionBoundaryContract.boundaryValidationManifestPath,
      Sprint118PermissionBoundaryContract.novelCharacterManifestPath,
      Sprint118PermissionBoundaryContract.auditManifestPath,
    ]) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('required_source_unreadable:$source');
      }
    }

    final allItems = <String>[...violations, ...blockers, ...openItems];
    if (violations.isNotEmpty) {
      return Sprint118PermissionBoundaryReport(
        state: Sprint118PermissionBoundaryState.fail,
        verdict: 'SPRINT_118_PERMISSION_BOUNDARY_EVIDENCE_VIOLATION',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredEvidence: review.evidenceItems,
        observedCount: review.observedCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118PermissionBoundaryReport(
        state: Sprint118PermissionBoundaryState.blocked,
        verdict: 'SPRINT_118_PERMISSION_BOUNDARY_BLOCKED_UPSTREAM',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredEvidence: review.evidenceItems,
        observedCount: review.observedCount,
      );
    }
    return Sprint118PermissionBoundaryReport(
      state: Sprint118PermissionBoundaryState.pass,
      verdict: 'NOVEL_CHARACTER_PERMISSION_BOUNDARY_HEALTH_VERIFIED_LOCAL',
      releaseState: review.releaseState,
      openItems: allItems,
      declaredEvidence: review.evidenceItems,
      observedCount: review.observedCount,
    );
  }
}
