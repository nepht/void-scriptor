/// Entry gate for roadmap step 118.1 -- Sprint Entry & Release-State Gate.
///
/// Objective (external canonical `sprint_118.json`): read Sprint 117's release
/// decision and select exactly one of `GA_RELEASED`, `GA_DELAYED`, or
/// `ROLLED_BACK` from evidence.
///
/// The canonical contract is blunt about what this step is *not*. Sprint 118 is
/// `PLANNED_BLOCKED` with `entry_readiness`
/// `BLOCKED_BY_SPRINT_117_AND_CONNECTOR_CERTIFICATION`, and its own
/// `execution_note` records that the sprint "tidak boleh dianggap aktif atau
/// selesai". So this gate answers exactly one question -- may Sprint 118
/// execution start -- and on committed evidence the honest answer is `blocked`.
///
/// The gate is fail-closed on four rules:
///
/// * It reads the committed Sprint 117 witnesses directly (the approval gate
///   117.45, the closure manifest 117.48, the registry reconciliation 117.41,
///   the observation handoff 117.47) instead of trusting any self-declared
///   readiness flag. A gate that believes a document's claim about itself can
///   be made to say `pass` by the very document it is meant to police.
/// * `GA_DELAYED` does not open the sprint. When 117 recorded a delay, entry
///   additionally requires an approved corrective scope; without that approval
///   the gate stays `blocked`. An absent approval is undetermined, never
///   permission.
/// * The two committed sources of the 117 decision must agree. If the approval
///   gate and the closure manifest disagree, the gate fails rather than
///   silently picking the convenient one.
/// * An unreadable witness or an unknown decision word keeps the gate closed.
///   The delayed corrective path may start without a certified connector or GA
///   authorization; those remain mandatory for the released path. Nothing here
///   releases, publishes, certifies, or activates anything.
library;

import 'dart:convert';
import 'dart:io';

/// The single outcome word step 118.1 is asked to select. `undetermined` is
/// the fail-closed resting state: an unreadable or unknown decision never
/// resolves to a release state.
enum Sprint118ReleaseState { gaReleased, gaDelayed, rolledBack, undetermined }

enum Sprint118EntryState { pass, fail, blocked }

/// The fixed vocabulary of step 118.1, kept in one place so the loader and the
/// gate cannot drift apart about what the step is made of.
abstract final class Sprint118EntryContract {
  const Sprint118EntryContract._();

  static const String canonicalStep = '118.1';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_entry_gate.json';

  /// Committed Sprint 117 witnesses. These are the evidence, not a summary of
  /// it: the gate re-derives the release state from these files every run.
  static const String approvalGatePath =
      'docs/planning/v1.3/sprint_117_ga_approval_gate.json';
  static const String closurePath =
      'docs/planning/v1.3/sprint_117_sprint_closure.json';
  static const String registryPath =
      'docs/evidence/sprint-117-41-manifest-20261002.json';
  static const String handoffPath =
      'docs/planning/v1.3/sprint_117_post_release_observation_handoff.json';
  static const String rollbackDrillPath =
      'docs/planning/v1.3/sprint_117_provider_rollback_drill.json';

  /// Where an approved corrective scope for a delayed 117 is recorded. Entry
  /// on a delayed release requires this explicit approval; a missing approval
  /// cannot be read as consent.
  static const String correctiveScopePath =
      'docs/planning/v1.3/sprint_118_corrective_scope_approval.json';

  static const String pubspecPath = 'pubspec.yaml';

  /// The release version Sprint 118 builds on (external canonical
  /// `sprint_118.json` -> `base_version`).
  static const String baseVersion = '1.3.0';

  /// The six canonical evidence items from `sprint_118.json` step 118.1.
  static const List<String> requiredEvidence = <String>[
    'sprint_117_decision',
    'release_state',
    'artifact_version',
    'visible_connector_subset',
    'known_issues',
    'rollback_state',
  ];

  static const List<String> requiredSources = <String>[
    approvalGatePath,
    closurePath,
    registryPath,
    handoffPath,
    rollbackDrillPath,
    pubspecPath,
  ];

  static const Set<String> releasedDecisions = <String>{
    'RELEASED',
    'RELEASE',
    'GA_RELEASED',
    'AUTHORIZED_FOR_RELEASE',
  };

  static const Set<String> delayedDecisions = <String>{'DELAY', 'DELAYED'};

  static const Set<String> rolledBackDecisions = <String>{
    'ROLLED_BACK',
    'ROLLBACK',
  };

  /// Every decision word this gate understands. An unlisted word is treated as
  /// unknown and fails the gate instead of being read optimistically.
  static const Set<String> decisionVocabulary = <String>{
    'RELEASED',
    'RELEASE',
    'GA_RELEASED',
    'AUTHORIZED_FOR_RELEASE',
    'DELAY',
    'DELAYED',
    'ROLLED_BACK',
    'ROLLBACK',
  };

  static bool isKnownDecision(String raw) =>
      decisionVocabulary.contains(raw.trim().toUpperCase());

  /// Map a recorded decision word to the release state it selects. An
  /// unrecognised word maps to `undetermined`, never to `gaReleased`.
  static Sprint118ReleaseState releaseStateFromText(String raw) {
    final word = raw.trim().toUpperCase();
    if (releasedDecisions.contains(word)) {
      return Sprint118ReleaseState.gaReleased;
    }
    if (delayedDecisions.contains(word)) {
      return Sprint118ReleaseState.gaDelayed;
    }
    if (rolledBackDecisions.contains(word)) {
      return Sprint118ReleaseState.rolledBack;
    }
    return Sprint118ReleaseState.undetermined;
  }

  /// The canonical word for a release state, used when recording the verdict.
  static String releaseStateWord(Sprint118ReleaseState state) {
    switch (state) {
      case Sprint118ReleaseState.gaReleased:
        return 'GA_RELEASED';
      case Sprint118ReleaseState.gaDelayed:
        return 'GA_DELAYED';
      case Sprint118ReleaseState.rolledBack:
        return 'ROLLED_BACK';
      case Sprint118ReleaseState.undetermined:
        return 'UNDETERMINED';
    }
  }
}

/// What the committed Sprint 117 witnesses actually say.
class Sprint118EntryEvidence {
  const Sprint118EntryEvidence({
    required this.approvalDecision,
    required this.closureDecision,
    required this.approvalState,
    required this.executionAuthorized,
    required this.releaseDecisionOwner,
    required this.certifiedCount,
    required this.limitedCount,
    required this.providerCount,
    required this.correctiveScopeApproved,
    required this.observationWindowActive,
    required this.artifactVersion,
    required this.knownIssues,
    required this.rollbackExecuted,
  });

  /// The decision word recorded by the approval gate (117.45).
  final String approvalDecision;

  /// The decision word recorded by the closure manifest (117.48). Kept
  /// separately so the gate can catch the two disagreeing.
  final String closureDecision;

  final String approvalState;
  final bool executionAuthorized;
  final String releaseDecisionOwner;

  final int certifiedCount;
  final int limitedCount;
  final int providerCount;

  /// Whether a corrective scope for a delayed 117 is approved. `null` when no
  /// approval is recorded -- undetermined, so the gate must not read it as
  /// consent.
  final bool? correctiveScopeApproved;

  /// Whether a released 117 has an active observation window (117.47).
  final bool observationWindowActive;

  final String artifactVersion;
  final List<String> knownIssues;
  final bool rollbackExecuted;

  int get certifiedOrLimited => certifiedCount + limitedCount;

  Sprint118ReleaseState get releaseState =>
      Sprint118EntryContract.releaseStateFromText(approvalDecision);
}

/// Reads the committed witnesses. Never invents: an unreadable witness yields
/// `null`, which the gate reports as undetermined.
class Sprint118EntryLoader {
  const Sprint118EntryLoader();

  Sprint118EntryEvidence? load() {
    final approval = _readJsonObject(Sprint118EntryContract.approvalGatePath);
    final closure = _readJsonObject(Sprint118EntryContract.closurePath);
    final registry = _readJsonObject(Sprint118EntryContract.registryPath);
    final pubspec = _readText(Sprint118EntryContract.pubspecPath);
    if (approval == null ||
        closure == null ||
        registry == null ||
        pubspec == null) {
      return null;
    }

    final approvalBlock = _asObject(approval['approval']);
    final approvalDecision = _text(
      approvalBlock?['decision'] ?? approval['decision'],
    );
    final approvalState = _text(
      approvalBlock?['approval_state'] ?? approval['approval_state'],
    );
    final executionAuthorized =
        (approvalBlock?['execution_authorized'] ??
            approval['execution_authorized']) ==
        true;

    final closureDecision = _text(
      closure['release_decision'] ?? closure['decision'],
    );
    final owner = _text(closure['release_decision_owner']);

    final statusCounts =
        _asObject(registry['status_counts']) ?? const <String, dynamic>{};
    final certified = _int(statusCounts['CERTIFIED']);
    final limited = _int(statusCounts['LIMITED']);
    final providerCount = _int(registry['provider_count']);

    final corrective = _readJsonObject(
      Sprint118EntryContract.correctiveScopePath,
    );
    final bool? correctiveApproved = corrective == null
        ? null
        : (corrective['corrective_scope_approved'] == true ||
              _text(corrective['status']).toUpperCase() ==
                  'CORRECTIVE_SCOPE_APPROVED');

    final handoff = _readJsonObject(Sprint118EntryContract.handoffPath);
    final observationWindowActive =
        handoff != null && handoff['live_release_observed'] == true;

    final drill = _readJsonObject(Sprint118EntryContract.rollbackDrillPath);
    final rollbackExecuted = drill != null && drill['drill_executed'] == true;

    return Sprint118EntryEvidence(
      approvalDecision: approvalDecision,
      closureDecision: closureDecision,
      approvalState: approvalState,
      executionAuthorized: executionAuthorized,
      releaseDecisionOwner: owner,
      certifiedCount: certified,
      limitedCount: limited,
      providerCount: providerCount,
      correctiveScopeApproved: correctiveApproved,
      observationWindowActive: observationWindowActive,
      artifactVersion: _pubspecVersion(pubspec),
      knownIssues: _stringList(closure['open_items']),
      rollbackExecuted: rollbackExecuted,
    );
  }

  static String _pubspecVersion(String pubspec) {
    for (final line in const LineSplitter().convert(pubspec)) {
      final trimmed = line.trim();
      if (trimmed.startsWith('version:')) {
        return trimmed.substring('version:'.length).trim();
      }
    }
    return '';
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

  static String? _readText(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      return null;
    }
  }

  static Map<String, dynamic>? _asObject(Object? value) =>
      value is Map<String, dynamic> ? value : null;

  static String _text(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

class Sprint118EntryReport {
  const Sprint118EntryReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingEvidence = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
  });

  final Sprint118EntryState state;
  final String verdict;

  /// The release state the gate selected from evidence.
  final Sprint118ReleaseState releaseState;

  final List<String> missingEvidence;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;

  /// Whether Sprint 118 execution may start. Only a genuine `pass` allows it;
  /// `blocked` and `fail` both forbid it.
  bool get executionAllowed => state == Sprint118EntryState.pass;

  String get releaseStateWord =>
      Sprint118EntryContract.releaseStateWord(releaseState);
}

class Sprint118EntryGate {
  const Sprint118EntryGate();

  /// Evaluate against committed evidence. This is the entry point that makes
  /// the answer trustworthy: the verdict is bound to the witnesses on disk.
  Sprint118EntryReport evaluate() =>
      evaluateWith(const Sprint118EntryLoader().load());

  Sprint118EntryReport evaluateWith(Sprint118EntryEvidence? evidence) {
    if (evidence == null) {
      return Sprint118EntryReport(
        state: Sprint118EntryState.blocked,
        verdict: 'SPRINT_118_ENTRY_EVIDENCE_UNREADABLE',
        releaseState: Sprint118ReleaseState.undetermined,
        missingEvidence: List<String>.from(
          Sprint118EntryContract.requiredEvidence,
        ),
        blockers: const <String>['committed_entry_evidence_unreadable'],
        openItems: const <String>['committed_entry_evidence_unreadable'],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final missing = <String>[];

    // The two committed sources of the 117 decision must agree. A gate that
    // silently prefers one of two disagreeing records is not measuring.
    if (evidence.approvalDecision.isEmpty || evidence.closureDecision.isEmpty) {
      missing.add('sprint_117_decision');
    } else if (evidence.approvalDecision.toUpperCase() !=
        evidence.closureDecision.toUpperCase()) {
      violations.add(
        'decision_source_disagreement:'
        '${evidence.approvalDecision}:${evidence.closureDecision}',
      );
    }

    // An unknown decision word is drift, not a pass.
    if (!Sprint118EntryContract.isKnownDecision(evidence.approvalDecision)) {
      violations.add('unknown_release_decision:${evidence.approvalDecision}');
    }

    final releaseState = evidence.releaseState;
    if (releaseState == Sprint118ReleaseState.undetermined) {
      violations.add('release_state_undetermined');
    }

    if (releaseState == Sprint118ReleaseState.gaReleased) {
      // A released 117 opens the provider-stabilisation path only when there
      // is a certified/limited connector and the release was explicitly
      // authorised. These are release-path requirements, not requirements for
      // the delayed corrective path below.
      if (evidence.certifiedOrLimited == 0) {
        blockers.add('no_certified_or_limited_connector');
      }
      if (!evidence.executionAuthorized) {
        blockers.add(
          'execution_authorization_pending:${evidence.approvalState}',
        );
      }
      // A released 117 opens 118 only while its observation window is active.
      if (!evidence.observationWindowActive) {
        blockers.add('observation_window_not_active');
      }
    } else if (releaseState == Sprint118ReleaseState.gaDelayed) {
      // A delayed 117 opens the local corrective path only against an approved
      // scope. It intentionally does not require a live connector or release
      // authorization: those belong to the GA release path, which remains
      // closed. An absent approval is undetermined, never permission.
      if (evidence.correctiveScopeApproved != true) {
        blockers.add('corrective_scope_not_approved');
      }
    } else if (releaseState == Sprint118ReleaseState.rolledBack) {
      if (evidence.correctiveScopeApproved != true) {
        blockers.add('corrective_scope_not_approved');
      }
      blockers.add('release_rolled_back');
    }

    final openItems = <String>[...violations, ...blockers];

    if (violations.isNotEmpty) {
      return Sprint118EntryReport(
        state: Sprint118EntryState.fail,
        verdict: 'SPRINT_118_ENTRY_EVIDENCE_VIOLATION',
        releaseState: releaseState,
        missingEvidence: missing,
        violations: violations,
        blockers: blockers,
        openItems: openItems,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118EntryReport(
        state: Sprint118EntryState.blocked,
        verdict: 'SPRINT_118_ENTRY_BLOCKED_UPSTREAM',
        releaseState: releaseState,
        missingEvidence: missing,
        violations: violations,
        blockers: blockers,
        openItems: openItems,
      );
    }
    return Sprint118EntryReport(
      state: Sprint118EntryState.pass,
      verdict: 'SPRINT_118_ENTRY_READY',
      releaseState: releaseState,
    );
  }
}
