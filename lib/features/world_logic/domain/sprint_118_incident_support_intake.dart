/// Fail-closed incident and support intake for roadmap step 118.6 --
/// Incident & Support Intake.
///
/// Objective (external canonical `sprint_118.json`): combine support, crash,
/// auth, quota, sync, AI, billing, security, privacy, and accessibility
/// incidents. The canonical required-field list is exactly eight items:
/// `incident_id`, `source`, `provider`, `version`, `impact`, `reproduction`,
/// `evidence`, and `owner`.
///
/// This is the intake schema that the delayed corrective path (Sprint 118 on
/// `GA_DELAYED`) registers *before* any live incident arrives. The gate answers
/// a single question: does the declared intake carry, for every canonical
/// incident category, a record with all eight required fields, a known impact
/// level, an accountable owner, and a committed, readable evidence source?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). An intake built on
///   a baseline that did not freeze describes incidents nobody measured.
/// * The committed 117.6 support-incident-readiness witness must be a genuine
///   readiness pass (`SUPPORT_INCIDENT_READINESS_DEFINED_LOCAL`). An intake that
///   is not anchored to a committed severity/owner plan cannot be triaged.
/// * The intake's release state must agree with the baseline anchor.
/// * On the delayed path no live incident may be claimed: neither the witness
///   may report an executed incident nor any entry may carry a live impact.
/// * Every canonical category must be present exactly once, must carry all
///   eight required fields non-blank, must name a known impact level and an
///   accountable owner, and must cite a committed, readable evidence source.
///
/// The impact vocabulary and the owner vocabulary are *derived from the
/// committed 117.6 readiness witness* (its `severity_levels` and `owners`), not
/// copied by hand, so the intake and the readiness plan cannot drift apart
/// silently. The delayed path adds `none` to the impact vocabulary: with no live
/// incident, the only honest impact is that there is none.
///
/// Live incident handling, support channels, on-call rotation, provider
/// escalation, connector certification, provider exposure, release
/// authorization, and publication remain `DEFERRED-EXTERNAL`; this intake
/// freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states an intake evaluation can rest in. `blocked` is the honest
/// resting state for "this intake cannot yet be trusted", and it is distinct
/// from `fail`, which means the intake contradicts its own evidence.
enum Sprint118IntakeState { pass, fail, blocked }

/// One incident intake record: the declared registration for a single canonical
/// incident category, with the eight required fields it must carry.
class Sprint118IncidentIntakeEntry {
  const Sprint118IncidentIntakeEntry({
    required this.category,
    required this.incidentId,
    required this.source,
    required this.provider,
    required this.version,
    required this.impact,
    required this.reproduction,
    required this.evidence,
    required this.owner,
  });

  /// The canonical incident category this record registers, drawn from the
  /// category vocabulary.
  final String category;

  /// The intake identifier. Stable and declared; no live incident is implied.
  final String incidentId;

  /// The intake source (the surface the incident arrived on).
  final String source;

  /// The provider the incident concerns, or `unassigned` before triage.
  final String provider;

  /// The product version the incident was observed on.
  final String version;

  /// The declared impact level. On the delayed path this must be `none`; any
  /// live severity is refused because no release ran.
  final String impact;

  /// How the incident is reproduced, or the declared deferral marker.
  final String reproduction;

  /// The committed evidence source for this category. Must be readable.
  final String evidence;

  /// The accountable owner, drawn from the committed readiness owner
  /// vocabulary.
  final String owner;

  /// The eight required fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get fields => <String, String>{
    'incident_id': incidentId,
    'source': source,
    'provider': provider,
    'version': version,
    'impact': impact,
    'reproduction': reproduction,
    'evidence': evidence,
    'owner': owner,
  };
}

/// The declared intake. `entries` is the intake surface for the delayed
/// corrective path; on that path no entry may register a live incident.
class Sprint118IncidentIntake {
  const Sprint118IncidentIntake({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118IncidentIntakeEntry> entries;

  List<String> get categories => <String>[
    for (final entry in entries) entry.category,
  ];
}

/// What the committed 118.4 baseline and 117.6 support-incident-readiness
/// witness actually say. An intake is only as honest as the witnesses it reads.
class Sprint118IncidentIntakeAnchor {
  const Sprint118IncidentIntakeAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.supportState,
    required this.supportVerdict,
    required this.liveIncidentExecuted,
    required this.severityLevels,
    required this.owners,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String supportState;
  final String supportVerdict;

  /// Whether the committed readiness witness claims an incident was executed.
  /// On the delayed path this must stay `false`.
  final bool liveIncidentExecuted;

  /// The severity vocabulary the committed readiness witness declares.
  final List<String> severityLevels;

  /// The owner vocabulary the committed readiness witness declares.
  final List<String> owners;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the intake is well-formed; `blocked` means
/// it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118IncidentIntakeReport {
  const Sprint118IncidentIntakeReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredCategories = const <String>[],
    this.incidentCount = 0,
    this.severityLevels = const <String>[],
  });

  final Sprint118IntakeState state;
  final String verdict;
  final String releaseState;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredCategories;
  final int incidentCount;
  final List<String> severityLevels;

  /// Whether the intake may be treated as well-formed. Only a genuine `pass`
  /// allows it.
  bool get intakeVerified => state == Sprint118IntakeState.pass;

  String get externalGates => Sprint118IncidentIntakeContract.externalGates;
}

/// The fixed vocabulary of step 118.6, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118IncidentIntakeContract {
  const Sprint118IncidentIntakeContract._();

  static const String canonicalStep = '118.6';
  static const String title = 'Incident & Support Intake';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_incident_support_intake.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this intake is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 117.6 support-incident-readiness witness that declares the
  /// severity vocabulary, the owner vocabulary, and whether an incident ran.
  static const String supportReadinessManifestPath =
      'docs/planning/v1.3/sprint_117_support_incident_readiness.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 117.6 support-readiness witness must carry.
  static const String requiredSupportVerdict =
      'SUPPORT_INCIDENT_READINESS_DEFINED_LOCAL';
  static const String requiredSupportState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The product version the intake is declared against.
  static const String baseVersion = '1.3.1';

  /// The eight canonical required fields from `sprint_118.json` step 118.6.
  static const List<String> requiredFields = <String>[
    'incident_id',
    'source',
    'provider',
    'version',
    'impact',
    'reproduction',
    'evidence',
    'owner',
  ];

  /// The ten canonical incident categories the objective names.
  static const List<String> incidentCategories = <String>[
    'support',
    'crash',
    'auth',
    'quota',
    'sync',
    'ai',
    'billing',
    'security',
    'privacy',
    'accessibility',
  ];

  /// The impact an entry declares when no live incident has occurred. On the
  /// delayed path this is the only honest impact.
  static const String noImpact = 'none';

  /// The provider an untriaged entry carries.
  static const String unassignedProvider = 'unassigned';

  /// The reproduction marker an untriaged entry carries.
  static const String declaredReproduction = 'deferred_external';

  /// The accountable incident owner, drawn from the committed 117.6 readiness
  /// owner vocabulary. The gate verifies membership against the witness.
  static const String incidentOwner = 'Choirudin';

  /// The committed evidence source registered for each canonical category.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.3/sprint_117_support_incident_readiness.json',
    'docs/planning/v1.2/sprint_114_crash_startup_health.json',
    'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
    'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
    'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json',
    'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json',
    'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
    'docs/planning/v1.2/sprint_116_security_certification_gate.json',
    'docs/planning/v1.3/sprint_118_privacy_safe_observation.json',
    'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json',
  ];

  /// The impact vocabulary derived from the committed readiness witness: the
  /// declared severity levels plus the no-impact marker.
  static List<String> impactVocabulary(List<String> severityLevels) => <String>[
    ...severityLevels,
    noImpact,
  ];

  /// The evidence source registered for a canonical category.
  static String sourceFor(String category) {
    final index = incidentCategories.indexOf(category);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// The canonical intake, declared here as the single source of truth. The gate
  /// evaluates exactly this object, and the emitter writes exactly this object,
  /// so the record cannot be made to agree with itself. With the release
  /// delayed, every entry registers a reference and claims no live incident.
  static const Sprint118IncidentIntake
  canonicalIntake = Sprint118IncidentIntake(
    releaseState: delayedReleaseState,
    entries: <Sprint118IncidentIntakeEntry>[
      Sprint118IncidentIntakeEntry(
        category: 'support',
        incidentId: 'INTAKE-SUPPORT-REF',
        source: 'support',
        provider: unassignedProvider,
        version: baseVersion,
        impact: noImpact,
        reproduction: declaredReproduction,
        evidence:
            'docs/planning/v1.3/sprint_117_support_incident_readiness.json',
        owner: incidentOwner,
      ),
      Sprint118IncidentIntakeEntry(
        category: 'crash',
        incidentId: 'INTAKE-CRASH-REF',
        source: 'crash',
        provider: unassignedProvider,
        version: baseVersion,
        impact: noImpact,
        reproduction: declaredReproduction,
        evidence: 'docs/planning/v1.2/sprint_114_crash_startup_health.json',
        owner: incidentOwner,
      ),
      Sprint118IncidentIntakeEntry(
        category: 'auth',
        incidentId: 'INTAKE-AUTH-REF',
        source: 'auth',
        provider: unassignedProvider,
        version: baseVersion,
        impact: noImpact,
        reproduction: declaredReproduction,
        evidence:
            'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
        owner: incidentOwner,
      ),
      Sprint118IncidentIntakeEntry(
        category: 'quota',
        incidentId: 'INTAKE-QUOTA-REF',
        source: 'quota',
        provider: unassignedProvider,
        version: baseVersion,
        impact: noImpact,
        reproduction: declaredReproduction,
        evidence:
            'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
        owner: incidentOwner,
      ),
      Sprint118IncidentIntakeEntry(
        category: 'sync',
        incidentId: 'INTAKE-SYNC-REF',
        source: 'sync',
        provider: unassignedProvider,
        version: baseVersion,
        impact: noImpact,
        reproduction: declaredReproduction,
        evidence:
            'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json',
        owner: incidentOwner,
      ),
      Sprint118IncidentIntakeEntry(
        category: 'ai',
        incidentId: 'INTAKE-AI-REF',
        source: 'ai',
        provider: unassignedProvider,
        version: baseVersion,
        impact: noImpact,
        reproduction: declaredReproduction,
        evidence:
            'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json',
        owner: incidentOwner,
      ),
      Sprint118IncidentIntakeEntry(
        category: 'billing',
        incidentId: 'INTAKE-BILLING-REF',
        source: 'billing',
        provider: unassignedProvider,
        version: baseVersion,
        impact: noImpact,
        reproduction: declaredReproduction,
        evidence:
            'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
        owner: incidentOwner,
      ),
      Sprint118IncidentIntakeEntry(
        category: 'security',
        incidentId: 'INTAKE-SECURITY-REF',
        source: 'security',
        provider: unassignedProvider,
        version: baseVersion,
        impact: noImpact,
        reproduction: declaredReproduction,
        evidence:
            'docs/planning/v1.2/sprint_116_security_certification_gate.json',
        owner: incidentOwner,
      ),
      Sprint118IncidentIntakeEntry(
        category: 'privacy',
        incidentId: 'INTAKE-PRIVACY-REF',
        source: 'privacy',
        provider: unassignedProvider,
        version: baseVersion,
        impact: noImpact,
        reproduction: declaredReproduction,
        evidence: 'docs/planning/v1.3/sprint_118_privacy_safe_observation.json',
        owner: incidentOwner,
      ),
      Sprint118IncidentIntakeEntry(
        category: 'accessibility',
        incidentId: 'INTAKE-ACCESSIBILITY-REF',
        source: 'accessibility',
        provider: unassignedProvider,
        version: baseVersion,
        impact: noImpact,
        reproduction: declaredReproduction,
        evidence:
            'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json',
        owner: incidentOwner,
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline and 117.6 support-incident-readiness
/// witness. Never invents: an unreadable witness yields `null`, which the gate
/// reports as blocked rather than as a pass.
class Sprint118IncidentIntakeLoader {
  const Sprint118IncidentIntakeLoader();

  Sprint118IncidentIntakeAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118IncidentIntakeContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final support = _readJsonObject(
      Sprint118IncidentIntakeContract.supportReadinessManifestPath,
    );
    if (support == null) return null;

    final readable = <String>[
      for (final source in Sprint118IncidentIntakeContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118IncidentIntakeAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      supportState: _text(support['state']),
      supportVerdict: _text(support['verdict']),
      liveIncidentExecuted: support['live_incident_executed'] == true,
      severityLevels: _stringList(support['severity_levels']),
      owners: _stringList(support['owners']),
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

class Sprint118IncidentIntakeGate {
  const Sprint118IncidentIntakeGate();

  /// Evaluate the canonical intake against committed evidence. This is the entry
  /// point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118IncidentIntakeReport evaluate() => evaluateWith(
    const Sprint118IncidentIntakeLoader().loadAnchor(),
    Sprint118IncidentIntakeContract.canonicalIntake,
  );

  Sprint118IncidentIntakeReport evaluateWith(
    Sprint118IncidentIntakeAnchor? anchor,
    Sprint118IncidentIntake intake,
  ) {
    if (anchor == null) {
      return Sprint118IncidentIntakeReport(
        state: Sprint118IntakeState.blocked,
        verdict: 'SPRINT_118_INTAKE_EVIDENCE_UNREADABLE',
        releaseState: intake.releaseState,
        missingFields: List<String>.from(
          Sprint118IncidentIntakeContract.requiredFields,
        ),
        blockers: const <String>['committed_intake_evidence_unreadable'],
        openItems: const <String>['committed_intake_evidence_unreadable'],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. An intake
    // written against an unfrozen baseline describes incidents nobody measured.
    if (anchor.baselineState !=
            Sprint118IncidentIntakeContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118IncidentIntakeContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 117.6 support-readiness witness must be a genuine pass. An intake
    // that is not anchored to a committed severity/owner plan cannot be triaged.
    if (anchor.supportState !=
            Sprint118IncidentIntakeContract.requiredSupportState ||
        anchor.supportVerdict !=
            Sprint118IncidentIntakeContract.requiredSupportVerdict) {
      blockers.add('support_intake_not_ready:${anchor.supportVerdict}');
    }

    // (3) The release state must agree with the baseline anchor.
    if (anchor.releaseState != intake.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'intake=${intake.releaseState}',
      );
    }

    // (4) On the delayed path no live incident may be claimed.
    final delayed =
        intake.releaseState ==
        Sprint118IncidentIntakeContract.delayedReleaseState;
    if (delayed && anchor.liveIncidentExecuted) {
      violations.add('live_incident_claimed_executed_without_release');
    }

    // (5) The readiness vocabulary must actually be present, so the intake has
    // something to derive its impact and owner vocabularies from.
    if (anchor.severityLevels.isEmpty) {
      openItems.add('upstream_severity_vocabulary_missing');
    }
    if (anchor.owners.isEmpty) {
      openItems.add('upstream_owner_vocabulary_missing');
    }

    // (6) Every canonical category must be present exactly once, and each entry
    // must carry all eight required fields non-blank.
    final declared = <String, int>{};
    for (final entry in intake.entries) {
      declared[entry.category] = (declared[entry.category] ?? 0) + 1;
    }
    final impactVocabulary = Sprint118IncidentIntakeContract.impactVocabulary(
      anchor.severityLevels,
    );
    for (final entry in intake.entries) {
      final category = entry.category;
      if (!Sprint118IncidentIntakeContract.incidentCategories.contains(
        category,
      )) {
        violations.add('category_unknown:$category');
      }
      for (final field in Sprint118IncidentIntakeContract.requiredFields) {
        final value = entry.fields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$category');
        }
      }
      if (!impactVocabulary.contains(entry.impact)) {
        violations.add('entry_unknown_impact:$category:${entry.impact}');
      }
      if (delayed && entry.impact != Sprint118IncidentIntakeContract.noImpact) {
        violations.add(
          'incident_claims_live_impact_without_release:$category:'
          '${entry.impact}',
        );
      }
      if (!anchor.owners.contains(entry.owner)) {
        violations.add('entry_unknown_owner:$category:${entry.owner}');
      }
      if (!anchor.readableSources.contains(entry.evidence)) {
        violations.add('entry_unreadable_evidence:$category:${entry.evidence}');
      }
    }
    for (final category in declared.keys) {
      if (declared[category]! > 1) {
        violations.add('category_duplicate:$category');
      }
    }
    for (final category in Sprint118IncidentIntakeContract.incidentCategories) {
      if (!declared.containsKey(category)) {
        violations.add('category_missing:$category');
      }
    }

    // (7) Every committed intake-evidence source must be readable.
    for (final source in Sprint118IncidentIntakeContract.canonicalSources) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final categories = intake.categories;

    if (violations.isNotEmpty) {
      return Sprint118IncidentIntakeReport(
        state: Sprint118IntakeState.fail,
        verdict: 'SPRINT_118_INCIDENT_INTAKE_VIOLATION',
        releaseState: intake.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredCategories: categories,
        incidentCount: intake.entries.length,
        severityLevels: anchor.severityLevels,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118IncidentIntakeReport(
        state: Sprint118IntakeState.blocked,
        verdict: 'SPRINT_118_INTAKE_BLOCKED_UPSTREAM',
        releaseState: intake.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredCategories: categories,
        incidentCount: intake.entries.length,
        severityLevels: anchor.severityLevels,
      );
    }
    return Sprint118IncidentIntakeReport(
      state: Sprint118IntakeState.pass,
      verdict: 'INCIDENT_SUPPORT_INTAKE_VERIFIED_LOCAL',
      releaseState: intake.releaseState,
      openItems: allOpen,
      declaredCategories: categories,
      incidentCount: intake.entries.length,
      severityLevels: anchor.severityLevels,
    );
  }
}
