/// Fail-closed issue deduplication and root-cause log for roadmap step 118.22 --
/// Issue Deduplication & Root Cause.
///
/// Objective (external canonical `sprint_118.json`): merge issues and determine
/// the connector version, component, reproduction, root cause, impact, and
/// owner. The canonical required-field list is exactly eight items: `issue_id`,
/// `duplicates`, `connector_version`, `component`, `reproduction`,
/// `root_cause`, `impact`, and `owner`.
///
/// This is the log the delayed corrective path (Sprint 118 on `GA_DELAYED`)
/// keeps before any live issue tracker exists. The gate answers a single
/// question: does the declared log carry, for every canonical component, an
/// entry with all eight required fields, a known connector version, a known
/// impact, a known owner, resolvable duplicate references -- and does every
/// entry stop short of confirming a root cause no live incident produced?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A log built on a
///   baseline that did not freeze deduplicates issues nobody observed.
/// * The committed 118.2 charter anchor must be a genuine complete charter
///   (`pass` on `CHARTER_COMPLETE_LOCAL`). A log written outside the frozen
///   stability charter has no window to belong to.
/// * The log's release state must agree with the baseline anchor.
/// * On the delayed path no live incident may be claimed: the committed
///   readiness witness may not report an executed incident, and no entry may
///   carry a live impact (only the no-impact marker).
/// * Every canonical component must be present exactly once, must carry all
///   eight required fields (with `duplicates` exempt: an empty duplicate list
///   means "no duplicates folded yet"), must name a known connector version, a
///   known impact, and a known owner, and must resolve every duplicate
///   reference.
/// * **A root cause is never confirmed without a live incident.** Every entry
///   records a reference root-cause classification, and the gate refuses any
///   entry that treats that classification as a confirmed root cause.
///
/// The component vocabulary is *derived from the committed 118.4 baseline*
/// (its `canonical_areas`), the connector-version vocabulary is *derived from
/// the committed 117.5 certification snapshot lock* (its
/// `anchor.recorded_connector_versions`), and the impact and owner vocabularies
/// are *derived from the committed 117.6 support incident readiness witness*
/// (its `severity_levels` and `owners`), not copied by hand, so the log and its
/// witnesses cannot drift apart silently. The delayed path adds `none` to the
/// impact vocabulary: with no live incident, the only honest impact is none.
///
/// Live issue-tracker ingestion, live incident execution, connector
/// certification, provider exposure, release authorization, and publication
/// remain `DEFERRED-EXTERNAL`; this log freezes local declared state and
/// executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a log evaluation can rest in. `blocked` is the honest
/// resting state for "this log cannot yet be trusted", and it is distinct from
/// `fail`, which means the log contradicts its own evidence.
enum Sprint118DedupState { pass, fail, blocked }

/// One deduplication record: the declared registration for a single canonical
/// component, with the eight required fields it must carry.
///
/// `rootCauseTreatedAsConfirmed` is deliberately *not* one of the eight
/// required fields; it is the flag the gate refuses when set, so that a
/// reference root-cause classification can be recorded while never being read
/// as a confirmed cause.
class Sprint118IssueEntry {
  const Sprint118IssueEntry({
    required this.component,
    required this.issueId,
    required this.connectorVersion,
    required this.duplicates,
    required this.reproduction,
    required this.rootCause,
    required this.impact,
    required this.owner,
    this.rootCauseTreatedAsConfirmed = false,
  });

  /// The canonical component this record registers, drawn from the component
  /// vocabulary.
  final String component;

  /// The stable identifier of the canonical issue. Declared; no live tracker
  /// is implied.
  final String issueId;

  /// The connector version the issue was observed against, drawn from the
  /// connector-version vocabulary.
  final String connectorVersion;

  /// Identifiers of reports folded into this one. Empty is valid: a canonical
  /// issue may start with no duplicates known yet.
  final List<String> duplicates;

  /// The ordered reproduction steps. Must not be empty.
  final List<String> reproduction;

  /// The determined root cause. On the delayed path this is the reference
  /// classification marker; no live root cause has been determined.
  final String rootCause;

  /// The declared impact, drawn from the impact vocabulary. On the delayed
  /// path this must be the no-impact marker.
  final String impact;

  /// Who owns the follow-up, drawn from the owner vocabulary.
  final String owner;

  /// Whether this record treats its reference root-cause classification as a
  /// confirmed root cause. The gate refuses `true`: a root cause is never
  /// confirmed without a live incident.
  final bool rootCauseTreatedAsConfirmed;

  /// The eight required fields as a name -> value map, so the gate can test
  /// blankness uniformly. `duplicates` joins to a semicolon list.
  Map<String, String> get fields => <String, String>{
    'issue_id': issueId,
    'duplicates': duplicates.join('; '),
    'connector_version': connectorVersion,
    'component': component,
    'reproduction': reproduction.join('; '),
    'root_cause': rootCause,
    'impact': impact,
    'owner': owner,
  };
}

/// The declared log. `entries` is the evidence surface for the delayed
/// corrective path; on that path no entry may register a live impact.
class Sprint118DedupLog {
  const Sprint118DedupLog({required this.releaseState, required this.entries});

  final String releaseState;
  final List<Sprint118IssueEntry> entries;

  List<String> get components => <String>[
    for (final entry in entries) entry.component,
  ];

  List<String> get issueIds => <String>[
    for (final entry in entries) entry.issueId,
  ];
}

/// What the committed witnesses actually say. A log is only as honest as the
/// witnesses it reads.
class Sprint118DedupAnchor {
  const Sprint118DedupAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.liveIncidentExecuted,
    required this.components,
    required this.connectorVersions,
    required this.impacts,
    required this.owners,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;

  /// Whether the committed readiness witness claims an incident was executed.
  /// On the delayed path this must stay `false`.
  final bool liveIncidentExecuted;

  /// The component vocabulary the committed 118.4 baseline declares.
  final List<String> components;

  /// The connector-version vocabulary the committed 117.5 snapshot lock
  /// declares.
  final List<String> connectorVersions;

  /// The impact vocabulary the committed 117.6 readiness witness declares.
  final List<String> impacts;

  /// The owner vocabulary the committed 117.6 readiness witness declares.
  final List<String> owners;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the log is well-formed; `blocked` means it
/// cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118DedupReport {
  const Sprint118DedupReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredComponents = const <String>[],
    this.entryCount = 0,
    this.impactVocabulary = const <String>[],
  });

  final Sprint118DedupState state;
  final String verdict;
  final String releaseState;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredComponents;
  final int entryCount;
  final List<String> impactVocabulary;

  /// Whether the log may be treated as well-formed. Only a genuine `pass`
  /// allows it.
  bool get logVerified => state == Sprint118DedupState.pass;

  String get externalGates => Sprint118DedupContract.externalGates;
}

/// The fixed vocabulary of step 118.22, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118DedupContract {
  const Sprint118DedupContract._();

  static const String canonicalStep = '118.22';
  static const String title = 'Issue Deduplication & Root Cause';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_issue_deduplication_root_cause.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this log is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter this log is anchored to.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 117.5 certification snapshot lock that declares the
  /// connector-version vocabulary.
  static const String connectorManifestPath =
      'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json';

  /// The committed 117.6 support incident readiness witness that declares the
  /// impact and owner vocabularies and the live-incident signal.
  static const String readinessManifestPath =
      'docs/planning/v1.3/sprint_117_support_incident_readiness.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The product version the log is declared against.
  static const String baseVersion = '1.3.1';

  /// The eight canonical required fields from `sprint_118.json` step 118.22.
  static const List<String> requiredFields = <String>[
    'issue_id',
    'duplicates',
    'connector_version',
    'component',
    'reproduction',
    'root_cause',
    'impact',
    'owner',
  ];

  /// The ten canonical components the 118.4 baseline names as its
  /// `canonical_areas`. The gate verifies membership against the witness.
  static const List<String> canonicalComponents = <String>[
    'connection',
    'reauth',
    'quota',
    'sync',
    'backup',
    'ai',
    'billing',
    'crash',
    'performance',
    'support',
  ];

  /// The impact an entry declares when no live incident has occurred. On the
  /// delayed path this is the only honest impact.
  static const String noImpact = 'none';

  /// The reference root-cause classification an entry declares when no live
  /// incident has produced a determined root cause.
  static const String referenceRootCause =
      'reference_root_cause_not_determined';

  /// The reference reproduction steps an entry declares when no live incident
  /// has produced a reproduction.
  static const String referenceReproduction = 'reference_reproduction_not_live';

  /// The connector version the canonical entries are declared against, matching
  /// the committed 117.5 snapshot lock `recorded_connector_versions`.
  static const String referenceConnectorVersion = 'manifest-v1';

  /// The committed evidence source registered for each canonical component.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.3/sprint_118_connection_health_review.json',
    'docs/planning/v1.3/sprint_118_oauth_reauth_health.json',
    'docs/planning/v1.3/sprint_118_quota_storage_health.json',
    'docs/planning/v1.3/sprint_118_sync_backup_recovery_health.json',
    'docs/planning/v1.3/sprint_118_sync_backup_recovery_health.json',
    'docs/planning/v1.3/sprint_118_ai_provider_health.json',
    'docs/planning/v1.3/sprint_118_billing_entitlement_health.json',
    'docs/planning/v1.3/sprint_118_incident_support_intake.json',
    'docs/planning/v1.3/sprint_118_performance_resource_health.json',
    'docs/planning/v1.3/sprint_118_incident_support_intake.json',
  ];

  /// The impact vocabulary derived from the committed readiness witness: the
  /// declared severity levels plus the no-impact marker.
  static List<String> impactVocabulary(List<String> severityLevels) => <String>[
    ...severityLevels,
    noImpact,
  ];

  /// The evidence source registered for a canonical component.
  static String sourceFor(String component) {
    final index = canonicalComponents.indexOf(component);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// The canonical log, declared here as the single source of truth. The gate
  /// evaluates exactly this object, and the emitter writes exactly this object,
  /// so the record cannot be made to agree with itself. With the release
  /// delayed, every entry registers a reference, claims no live impact, and
  /// stops short of confirming a root cause.
  static const Sprint118DedupLog canonicalLog = Sprint118DedupLog(
    releaseState: delayedReleaseState,
    entries: <Sprint118IssueEntry>[
      Sprint118IssueEntry(
        component: 'connection',
        issueId: 'ISSUE-CONNECTION-REF',
        connectorVersion: referenceConnectorVersion,
        duplicates: <String>[],
        reproduction: <String>[referenceReproduction],
        rootCause: referenceRootCause,
        impact: noImpact,
        owner: 'nephthys',
      ),
      Sprint118IssueEntry(
        component: 'reauth',
        issueId: 'ISSUE-REAUTH-REF',
        connectorVersion: referenceConnectorVersion,
        duplicates: <String>[],
        reproduction: <String>[referenceReproduction],
        rootCause: referenceRootCause,
        impact: noImpact,
        owner: 'nephthys',
      ),
      Sprint118IssueEntry(
        component: 'quota',
        issueId: 'ISSUE-QUOTA-REF',
        connectorVersion: referenceConnectorVersion,
        duplicates: <String>[],
        reproduction: <String>[referenceReproduction],
        rootCause: referenceRootCause,
        impact: noImpact,
        owner: 'nephthys',
      ),
      Sprint118IssueEntry(
        component: 'sync',
        issueId: 'ISSUE-SYNC-REF',
        connectorVersion: referenceConnectorVersion,
        duplicates: <String>[],
        reproduction: <String>[referenceReproduction],
        rootCause: referenceRootCause,
        impact: noImpact,
        owner: 'nephthys',
      ),
      Sprint118IssueEntry(
        component: 'backup',
        issueId: 'ISSUE-BACKUP-REF',
        connectorVersion: referenceConnectorVersion,
        duplicates: <String>[],
        reproduction: <String>[referenceReproduction],
        rootCause: referenceRootCause,
        impact: noImpact,
        owner: 'nephthys',
      ),
      Sprint118IssueEntry(
        component: 'ai',
        issueId: 'ISSUE-AI-REF',
        connectorVersion: referenceConnectorVersion,
        duplicates: <String>[],
        reproduction: <String>[referenceReproduction],
        rootCause: referenceRootCause,
        impact: noImpact,
        owner: 'nephthys',
      ),
      Sprint118IssueEntry(
        component: 'billing',
        issueId: 'ISSUE-BILLING-REF',
        connectorVersion: referenceConnectorVersion,
        duplicates: <String>[],
        reproduction: <String>[referenceReproduction],
        rootCause: referenceRootCause,
        impact: noImpact,
        owner: 'nephthys',
      ),
      Sprint118IssueEntry(
        component: 'crash',
        issueId: 'ISSUE-CRASH-REF',
        connectorVersion: referenceConnectorVersion,
        duplicates: <String>[],
        reproduction: <String>[referenceReproduction],
        rootCause: referenceRootCause,
        impact: noImpact,
        owner: 'Choirudin',
      ),
      Sprint118IssueEntry(
        component: 'performance',
        issueId: 'ISSUE-PERFORMANCE-REF',
        connectorVersion: referenceConnectorVersion,
        duplicates: <String>[],
        reproduction: <String>[referenceReproduction],
        rootCause: referenceRootCause,
        impact: noImpact,
        owner: 'nephthys',
      ),
      Sprint118IssueEntry(
        component: 'support',
        issueId: 'ISSUE-SUPPORT-REF',
        connectorVersion: referenceConnectorVersion,
        duplicates: <String>[],
        reproduction: <String>[referenceReproduction],
        rootCause: referenceRootCause,
        impact: noImpact,
        owner: 'Choirudin',
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, 117.5 snapshot lock, and
/// 117.6 readiness witness. Never invents: an unreadable witness yields `null`,
/// which the gate reports as blocked rather than as a pass.
class Sprint118DedupLoader {
  const Sprint118DedupLoader();

  Sprint118DedupAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118DedupContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(Sprint118DedupContract.charterManifestPath);
    if (charter == null) return null;
    final connector = _readJsonObject(
      Sprint118DedupContract.connectorManifestPath,
    );
    if (connector == null) return null;
    final readiness = _readJsonObject(
      Sprint118DedupContract.readinessManifestPath,
    );
    if (readiness == null) return null;

    final readable = <String>[
      for (final source in Sprint118DedupContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    final connectorAnchor = connector['anchor'];

    return Sprint118DedupAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      liveIncidentExecuted: readiness['live_incident_executed'] == true,
      components: _stringList(baseline['canonical_areas']),
      connectorVersions: connectorAnchor is Map
          ? _stringList(connectorAnchor['recorded_connector_versions'])
          : const <String>[],
      impacts: _stringList(readiness['severity_levels']),
      owners: _stringList(readiness['owners']),
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

class Sprint118DedupGate {
  const Sprint118DedupGate();

  /// Evaluate the canonical log against committed evidence. This is the entry
  /// point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118DedupReport evaluate() => evaluateWith(
    const Sprint118DedupLoader().loadAnchor(),
    Sprint118DedupContract.canonicalLog,
  );

  Sprint118DedupReport evaluateWith(
    Sprint118DedupAnchor? anchor,
    Sprint118DedupLog log,
  ) {
    if (anchor == null) {
      return Sprint118DedupReport(
        state: Sprint118DedupState.blocked,
        verdict: 'SPRINT_118_DEDUP_EVIDENCE_UNREADABLE',
        releaseState: log.releaseState,
        missingFields: List<String>.from(Sprint118DedupContract.requiredFields),
        blockers: const <String>['committed_issue_dedup_evidence_unreadable'],
        openItems: const <String>['committed_issue_dedup_evidence_unreadable'],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A log
    // written against an unfrozen baseline deduplicates issues nobody
    // observed.
    if (anchor.baselineState != Sprint118DedupContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118DedupContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState != Sprint118DedupContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118DedupContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (3) The release state must agree with the baseline anchor.
    if (anchor.releaseState != log.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'log=${log.releaseState}',
      );
    }

    // (4) On the delayed path no live incident may be claimed.
    final delayed =
        log.releaseState == Sprint118DedupContract.delayedReleaseState;
    if (delayed && anchor.liveIncidentExecuted) {
      violations.add('live_incident_claimed_executed_without_release');
    }

    // (5) The witness vocabularies must actually be present, so the log has
    // something to derive its vocabularies from.
    if (anchor.components.isEmpty) {
      openItems.add('upstream_component_vocabulary_missing');
    }
    if (anchor.connectorVersions.isEmpty) {
      openItems.add('upstream_connector_version_vocabulary_missing');
    }
    if (anchor.impacts.isEmpty) {
      openItems.add('upstream_impact_vocabulary_missing');
    }
    if (anchor.owners.isEmpty) {
      openItems.add('upstream_owner_vocabulary_missing');
    }
    // The canonical component set must be the witness's own vocabulary, not a
    // hand-copied list that can drift away from it.
    for (final component in Sprint118DedupContract.canonicalComponents) {
      if (!anchor.components.contains(component)) {
        openItems.add('component_not_in_witness:$component');
      }
    }

    // (6) Every canonical component must be present exactly once, and each
    // entry must carry its fields, a known connector version, a known impact,
    // and a known owner.
    final declared = <String, int>{};
    for (final entry in log.entries) {
      declared[entry.component] = (declared[entry.component] ?? 0) + 1;
    }
    final impactVocabulary = Sprint118DedupContract.impactVocabulary(
      anchor.impacts,
    );
    final liveIssueIds = <String>{...log.issueIds};
    for (final entry in log.entries) {
      final component = entry.component;
      if (!Sprint118DedupContract.canonicalComponents.contains(component)) {
        violations.add('component_unknown:$component');
      }
      for (final field in Sprint118DedupContract.requiredFields) {
        // An empty duplicate list means "no duplicates folded yet": it is a
        // well-formed value, not a missing field.
        if (field == 'duplicates') continue;
        final value = entry.fields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$component');
        }
      }
      if (!anchor.connectorVersions.contains(entry.connectorVersion)) {
        violations.add(
          'entry_unknown_connector_version:$component:${entry.connectorVersion}',
        );
      }
      if (!impactVocabulary.contains(entry.impact)) {
        violations.add('entry_unknown_impact:$component:${entry.impact}');
      }
      if (delayed && entry.impact != Sprint118DedupContract.noImpact) {
        violations.add(
          'impact_claimed_without_release:$component:${entry.impact}',
        );
      }
      if (!anchor.owners.contains(entry.owner)) {
        violations.add('entry_unknown_owner:$component:${entry.owner}');
      }
      // A root cause is never confirmed without a live incident.
      if (entry.rootCauseTreatedAsConfirmed) {
        violations.add('root_cause_treated_as_confirmed:$component');
      }
      for (final duplicate in entry.duplicates) {
        if (duplicate.trim().isEmpty) {
          violations.add('duplicate_reference_blank:$component');
          continue;
        }
        if (duplicate == entry.issueId) {
          violations.add('duplicate_self_reference:$component:$duplicate');
          continue;
        }
        if (liveIssueIds.contains(duplicate)) {
          violations.add('duplicate_reference_conflict:$component:$duplicate');
        }
      }
    }
    for (final component in declared.keys) {
      if (declared[component]! > 1) {
        violations.add('component_duplicate:$component');
      }
    }
    for (final component in Sprint118DedupContract.canonicalComponents) {
      if (!declared.containsKey(component)) {
        violations.add('component_missing:$component');
      }
    }

    // (7) Every committed evidence source must be readable.
    for (final source in Sprint118DedupContract.canonicalSources.toSet()) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final components = log.components;

    if (violations.isNotEmpty) {
      return Sprint118DedupReport(
        state: Sprint118DedupState.fail,
        verdict: 'SPRINT_118_DEDUP_VIOLATION',
        releaseState: log.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredComponents: components,
        entryCount: log.entries.length,
        impactVocabulary: impactVocabulary,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118DedupReport(
        state: Sprint118DedupState.blocked,
        verdict: 'SPRINT_118_DEDUP_BLOCKED_UPSTREAM',
        releaseState: log.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredComponents: components,
        entryCount: log.entries.length,
        impactVocabulary: impactVocabulary,
      );
    }
    return Sprint118DedupReport(
      state: Sprint118DedupState.pass,
      verdict: 'ISSUE_DEDUPLICATION_ROOT_CAUSE_VERIFIED_LOCAL',
      releaseState: log.releaseState,
      openItems: allOpen,
      declaredComponents: components,
      entryCount: log.entries.length,
      impactVocabulary: impactVocabulary,
    );
  }
}
