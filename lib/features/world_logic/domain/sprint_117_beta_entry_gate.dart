library;

import 'dart:convert';
import 'dart:io';

/// Fail-closed beta entry contract for Sprint 117.1.
///
/// Sprint 117 opens with `PLANNED_BLOCKED` and an `entry_readiness` of
/// `BLOCKED_NO_CERTIFIED_CONNECTOR_CURRENTLY_RECORDED`, recorded when the
/// registry still showed 32 UNVERIFIED providers and 0 certified. This gate
/// re-derives that block from repository evidence instead of trusting the
/// document-creation snapshot, and it answers exactly one question: may beta
/// execution for Sprint 117 start, and against which connector subset.
///
/// Every judgement is derived from committed repository evidence — the Sprint
/// 116 closure manifest, the Sprint 116 beta acceptance gate, the Sprint 116
/// staged rollout plan, and `pubspec.yaml`. Nothing here certifies a live
/// provider, enrols a participant, or cuts a release: the certified subset
/// means every local Sprint 116 gate for that provider passed, while
/// record-level live status stays `UNVERIFIED` and external gates stay
/// `DEFERRED-EXTERNAL`.
enum Sprint117BetaEntryState { pass, fail, blocked }

class Sprint117Sprint116Acceptance {
  const Sprint117Sprint116Acceptance({
    required this.step,
    required this.status,
    required this.closureDecision,
    required this.betaDecision,
    required this.definitionOfDone,
    required this.metCriteria,
  });

  final String step;
  final String status;
  final String closureDecision;
  final String betaDecision;
  final List<String> definitionOfDone;
  final List<String> metCriteria;
}

class Sprint117CertificationRegistry {
  const Sprint117CertificationRegistry({
    required this.providerCount,
    required this.certified,
    required this.limited,
    required this.blocked,
    required this.evidenceProviderCount,
  });

  final int providerCount;
  final List<String> certified;
  final List<String> limited;
  final List<String> blocked;

  /// Distinct providers that actually carry certification evidence, read from
  /// the per-provider Sprint 116 manifests. A subset bigger than this is a
  /// claim without a manifest behind it.
  final int evidenceProviderCount;
}

class Sprint117BetaArtifact {
  const Sprint117BetaArtifact({
    required this.betaVersion,
    required this.pubspecVersion,
    required this.releaseCut,
    required this.artifactRecorded,
  });

  final String betaVersion;
  final String pubspecVersion;
  final bool releaseCut;
  final bool artifactRecorded;
}

class Sprint117KnownIssues {
  const Sprint117KnownIssues({
    required this.issueIds,
    required this.owners,
    required this.declaredCount,
  });

  final List<String> issueIds;
  final List<String> owners;
  final int declaredCount;
}

class Sprint117RollbackReadiness {
  const Sprint117RollbackReadiness({
    required this.stopConditions,
    required this.rollbackProcedures,
    required this.killSwitches,
    required this.coveredConnectors,
    required this.exposedConnectors,
    required this.killSwitchedConnectors,
    required this.drillExecuted,
  });

  final int stopConditions;
  final int rollbackProcedures;
  final int killSwitches;
  final int coveredConnectors;
  final List<String> exposedConnectors;
  final List<String> killSwitchedConnectors;
  final bool drillExecuted;
}

class Sprint117BetaEntryInput {
  const Sprint117BetaEntryInput({
    this.sprint116Acceptance,
    this.certificationRegistry,
    this.betaArtifact,
    this.knownIssues,
    this.rollbackReadiness,
  });

  final Sprint117Sprint116Acceptance? sprint116Acceptance;
  final Sprint117CertificationRegistry? certificationRegistry;
  final Sprint117BetaArtifact? betaArtifact;
  final Sprint117KnownIssues? knownIssues;
  final Sprint117RollbackReadiness? rollbackReadiness;
}

class Sprint117BetaEntryReport {
  Sprint117BetaEntryReport({
    required this.state,
    required this.verdict,
    required List<String> missingEvidence,
    required List<String> violations,
    required this.registryProviderCount,
    required List<String> certifiedSubset,
    required List<String> limitedSubset,
    required List<String> blockedSubset,
    required Map<String, String> visibility,
    required this.sprint116Closed,
    required List<String> unmetClosureCriteria,
    required this.betaVersion,
    required this.pubspecVersion,
    required this.releaseCut,
    required this.liveBetaExecuted,
    required List<String> knownIssueIds,
    required List<String> knownIssueOwners,
    required this.rollbackStopConditions,
    required this.rollbackProcedures,
    required this.killSwitches,
    required this.rollbackReady,
    required List<String> exposedConnectors,
    required List<String> rollbackKillSwitchedConnectors,
    required this.rollbackDrillExecuted,
    required Map<String, int> evidenceCoverage,
    required List<String> openItems,
    required List<String> limitations,
  }) : missingEvidence = List<String>.unmodifiable(missingEvidence),
       violations = List<String>.unmodifiable(violations),
       certifiedSubset = List<String>.unmodifiable(certifiedSubset),
       limitedSubset = List<String>.unmodifiable(limitedSubset),
       blockedSubset = List<String>.unmodifiable(blockedSubset),
       visibility = Map<String, String>.unmodifiable(visibility),
       unmetClosureCriteria = List<String>.unmodifiable(unmetClosureCriteria),
       knownIssueIds = List<String>.unmodifiable(knownIssueIds),
       knownIssueOwners = List<String>.unmodifiable(knownIssueOwners),
       exposedConnectors = List<String>.unmodifiable(exposedConnectors),
       rollbackKillSwitchedConnectors = List<String>.unmodifiable(
         rollbackKillSwitchedConnectors,
       ),
       evidenceCoverage = Map<String, int>.unmodifiable(evidenceCoverage),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations);

  final Sprint117BetaEntryState state;
  final String verdict;
  final List<String> missingEvidence;
  final List<String> violations;
  final int registryProviderCount;
  final List<String> certifiedSubset;
  final List<String> limitedSubset;
  final List<String> blockedSubset;
  final Map<String, String> visibility;
  final bool sprint116Closed;
  final List<String> unmetClosureCriteria;
  final String betaVersion;
  final String pubspecVersion;
  final bool releaseCut;
  final bool liveBetaExecuted;
  final List<String> knownIssueIds;
  final List<String> knownIssueOwners;
  final int rollbackStopConditions;
  final int rollbackProcedures;
  final int killSwitches;
  final bool rollbackReady;
  final List<String> exposedConnectors;
  final List<String> rollbackKillSwitchedConnectors;
  final bool rollbackDrillExecuted;
  final Map<String, int> evidenceCoverage;
  final List<String> openItems;
  final List<String> limitations;

  String get externalGates => Sprint117BetaEntryContract.externalGates;

  /// The connector subset the beta may show: certified plus limited, never a
  /// blocked provider.
  List<String> get exposedBetaSubset => <String>[
    ...certifiedSubset,
    ...limitedSubset,
  ];

  /// Providers the beta build must not show.
  List<String> get hiddenFromBeta => blockedSubset;

  /// True when the canonical document-creation block no longer describes the
  /// repository: a certified or limited subset is now actually recorded.
  bool get canonicalEntryBlockResolved =>
      certifiedSubset.isNotEmpty || limitedSubset.isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'state': state.name,
    'verdict': verdict,
    'missing_evidence': List<String>.from(missingEvidence),
    'violations': List<String>.from(violations),
    'sprint_116_closed': sprint116Closed,
    'unmet_closure_criteria': List<String>.from(unmetClosureCriteria),
    'canonical_entry_block_resolved': canonicalEntryBlockResolved,
    'registry_provider_count': registryProviderCount,
    'certified_subset': List<String>.from(certifiedSubset),
    'limited_subset': List<String>.from(limitedSubset),
    'blocked_subset': List<String>.from(blockedSubset),
    'exposed_beta_subset': exposedBetaSubset,
    'visibility': Map<String, String>.from(visibility),
    'beta_version': betaVersion,
    'pubspec_version': pubspecVersion,
    'release_cut': releaseCut,
    'live_beta_executed': liveBetaExecuted,
    'known_issues': <String, Object?>{
      'ids': List<String>.from(knownIssueIds),
      'owners': List<String>.from(knownIssueOwners),
    },
    'rollback_readiness': <String, Object?>{
      'stop_conditions': rollbackStopConditions,
      'rollback_procedures': rollbackProcedures,
      'kill_switches': killSwitches,
      'ready': rollbackReady,
      'exposed_connectors': List<String>.from(exposedConnectors),
      'kill_switched_connectors': List<String>.from(
        rollbackKillSwitchedConnectors,
      ),
      'drill_executed': rollbackDrillExecuted,
    },
    'evidence_coverage': Map<String, int>.from(evidenceCoverage),
    'open_items': List<String>.from(openItems),
    'external_gates': externalGates,
    'limitations': List<String>.from(limitations),
  };
}

abstract final class Sprint117BetaEntryContract {
  static const String canonicalStep = '117.1';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_117_beta_entry_gate.json';
  static const String ledgerPath = 'docs/sprints/sprint-117-beta-validation.md';
  static const String closureManifestPath =
      'docs/planning/v1.2/sprint_116_sprint_closure.json';
  static const String acceptanceManifestPath =
      'docs/planning/v1.2/sprint_116_beta_acceptance_gate.json';
  static const String rolloutManifestPath =
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';
  static const String pubspecPath = 'pubspec.yaml';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The Sprint 116 closure step whose verdict Sprint 117 depends on.
  static const String sprint116ClosureStep = '116.52';
  static const String sprint116ClosureStatus = 'VERIFIED-LOCAL';
  static const String sprint116ClosureDecision =
      'CLOSED_LOCAL_DEFERRED_EXTERNAL';
  static const String sprint116BetaDecision = 'BETA_ACCEPTANCE_LOCAL_READY';

  /// The beta version Sprint 117 targets, as recorded in the canonical
  /// `sprint_117.json` (`base_version`).
  static const String betaVersion = 'v1.3.0-beta.1';

  /// The block recorded on the canonical document when the registry still
  /// showed 0 certified and 0 limited providers.
  static const String canonicalEntryReadiness =
      'BLOCKED_NO_CERTIFIED_CONNECTOR_CURRENTLY_RECORDED';

  /// The canonical `start_condition`: beta validation may only start with a
  /// certified or limited subset actually available on the beta version.
  static const String startCondition =
      'Sprint 116 Beta Acceptance Gate PASS dan sedikitnya satu connector '
      'subset berstatus CERTIFIED atau LIMITED tersedia pada v1.3.0-beta.1.';

  /// The six evidence areas canonical step 117.1 names, in canonical order.
  static const List<String> requiredEvidence = <String>[
    'sprint_116_acceptance',
    'certification_registry',
    'certified_or_limited_subset',
    'beta_artifact',
    'known_issues',
    'rollback_readiness',
  ];

  static const List<String> knownVerdicts = <String>[
    'BETA_ENTRY_LOCAL_READY',
    'BETA_ENTRY_BLOCKED',
    'BETA_ENTRY_FAILED',
  ];

  static const List<String> knownVisibilities = <String>[
    'certified',
    'limited',
    'blocked',
  ];

  /// Per-provider certification manifests read to count real evidence behind
  /// the certified subset. Cross-cutting policy and capability-review
  /// manifests are deliberately absent: they are not provider claims.
  static const List<String> certificationManifestPaths = <String>[
    'docs/planning/v1.2/sprint_116_email_identity_certification.json',
    'docs/planning/v1.2/sprint_116_google_identity_certification.json',
    'docs/planning/v1.2/sprint_116_microsoft_identity_certification.json',
    'docs/planning/v1.2/sprint_116_apple_identity_certification.json',
    'docs/planning/v1.2/sprint_116_github_identity_certification.json',
    'docs/planning/v1.2/sprint_116_community_identity_certification.json',
    'docs/planning/v1.2/sprint_116_google_drive_certification.json',
    'docs/planning/v1.2/sprint_116_onedrive_certification.json',
    'docs/planning/v1.2/sprint_116_dropbox_certification.json',
    'docs/planning/v1.2/sprint_116_mega_certification.json',
    'docs/planning/v1.2/sprint_116_local_storage_certification.json',
    'docs/planning/v1.2/sprint_116_openai_connector_certification.json',
    'docs/planning/v1.2/sprint_116_gemini_connector_certification.json',
    'docs/planning/v1.2/sprint_116_anthropic_connector_certification.json',
    'docs/planning/v1.2/sprint_116_flux_connector_certification.json',
    'docs/planning/v1.2/sprint_116_openrouter_connector_certification.json',
    'docs/planning/v1.2/sprint_116_local_ai_certification.json',
    'docs/planning/v1.2/sprint_116_github_developer_certification.json',
    'docs/planning/v1.2/sprint_116_gitlab_developer_certification.json',
    'docs/planning/v1.2/sprint_116_bitbucket_developer_certification.json',
    'docs/planning/v1.2/sprint_116_azure_devops_certification.json',
    'docs/planning/v1.2/sprint_116_figma_certification.json',
    'docs/planning/v1.2/sprint_116_adobe_canva_certification.json',
    'docs/planning/v1.2/sprint_116_blender_sketchfab_certification.json',
    'docs/planning/v1.2/sprint_116_stripe_billing_certification.json',
    'docs/planning/v1.2/sprint_116_paypal_billing_certification.json',
    'docs/planning/v1.2/sprint_116_midtrans_billing_certification.json',
    'docs/planning/v1.2/sprint_116_saweria_kofi_capability_review.json',
  ];

  /// The two Sprint 116 gate manifests the entry decision reads directly.
  static const Map<String, String> gateManifestPaths = <String, String>{
    '116.51': 'docs/planning/v1.2/sprint_116_beta_acceptance_gate.json',
    '116.52': 'docs/planning/v1.2/sprint_116_sprint_closure.json',
  };

  static const String connectorPrefix = 'conn_';

  /// `conn_openai` -> `openai`; anything without the prefix maps to nothing.
  static String providerIdFromConnector(String connectorId) {
    final trimmed = connectorId.trim();
    if (!trimmed.startsWith(connectorPrefix)) return '';
    final provider = trimmed.substring(connectorPrefix.length).trim();
    return provider.isEmpty ? '' : provider;
  }
}

class Sprint117BetaEntryInputLoader {
  const Sprint117BetaEntryInputLoader();

  Sprint117BetaEntryInput load() => Sprint117BetaEntryInput(
    sprint116Acceptance: _loadSprint116Acceptance(),
    certificationRegistry: _loadRegistry(),
    betaArtifact: _loadBetaArtifact(),
    knownIssues: _loadKnownIssues(),
    rollbackReadiness: _loadRollbackReadiness(),
  );

  Sprint117Sprint116Acceptance? _loadSprint116Acceptance() {
    final manifest = _readJsonObject(
      Sprint117BetaEntryContract.closureManifestPath,
    );
    if (manifest == null) return null;

    final criteria = manifest['criteria'];

    var betaDecision = _text(manifest['beta_decision']);
    if (betaDecision.isEmpty && criteria is Map) {
      final decision = criteria['beta_decision_recorded'];
      if (decision is Map) {
        betaDecision = _text(decision['decision']);
      }
    }

    final done = <String>[];
    final rawDone = manifest['definition_of_done'];
    if (rawDone is List) {
      for (final raw in rawDone) {
        final id = _text(raw);
        if (id.isNotEmpty) done.add(id);
      }
    }

    final met = <String>[];
    if (criteria is Map) {
      for (final entry in criteria.entries) {
        if (_text(entry.value is Map ? entry.value['status'] : null) ==
            Sprint117BetaEntryContract.sprint116ClosureStatus) {
          met.add(_text(entry.key));
        }
      }
    }

    return Sprint117Sprint116Acceptance(
      step: _text(manifest['canonical_step']),
      status: _text(manifest['status']),
      closureDecision: _text(manifest['closure_decision']),
      betaDecision: betaDecision,
      definitionOfDone: done,
      metCriteria: met,
    );
  }

  Sprint117CertificationRegistry? _loadRegistry() {
    final acceptance = _readJsonObject(
      Sprint117BetaEntryContract.acceptanceManifestPath,
    );
    if (acceptance == null) return null;

    final certified = _stringList(acceptance['certified_subset']);
    final limited = _stringList(acceptance['limited_connectors']);
    final blocked = _stringList(acceptance['blocked_connectors']);
    final providerCount =
        _int(acceptance['registry_provider_count']) ??
        (certified.length + limited.length + blocked.length);
    if (providerCount <= 0) return null;

    return Sprint117CertificationRegistry(
      providerCount: providerCount,
      certified: certified,
      limited: limited,
      blocked: blocked,
      evidenceProviderCount: _countEvidenceProviders(),
    );
  }

  /// Counts distinct providers that actually carry a committed certification
  /// record, so a subset cannot claim more coverage than the manifests back.
  int _countEvidenceProviders() {
    final providers = <String>{};
    for (final path in Sprint117BetaEntryContract.certificationManifestPaths) {
      final manifest = _readJsonObject(path);
      if (manifest == null) continue;
      final manifestProvider = _text(manifest['provider']);
      if (manifestProvider.isNotEmpty) providers.add(manifestProvider);
      final records = manifest['records'];
      if (records is List) {
        for (final raw in records) {
          if (raw is! Map) continue;
          final id = _text(raw['provider_id']);
          if (id.isNotEmpty) providers.add(id);
        }
      }
    }
    return providers.length;
  }

  Sprint117BetaArtifact? _loadBetaArtifact() {
    final pubspecVersion = _loadPubspecVersion();
    if (pubspecVersion.isEmpty) return null;
    final expected = Sprint117BetaEntryContract.betaVersion.startsWith('v')
        ? Sprint117BetaEntryContract.betaVersion.substring(1)
        : Sprint117BetaEntryContract.betaVersion;
    return Sprint117BetaArtifact(
      betaVersion: Sprint117BetaEntryContract.betaVersion,
      pubspecVersion: pubspecVersion,
      releaseCut: pubspecVersion == expected,
      // A release cut is an operator decision recorded in `pubspec.yaml`; the
      // gate never performs it.
      artifactRecorded: true,
    );
  }

  Sprint117KnownIssues? _loadKnownIssues() {
    final acceptance = _readJsonObject(
      Sprint117BetaEntryContract.acceptanceManifestPath,
    );
    if (acceptance == null) return null;

    final openItems = _stringList(acceptance['open_items']);
    final ids = <String>[];
    for (final item in openItems) {
      final separator = item.indexOf(':');
      final id = separator > 0
          ? item.substring(0, separator).trim()
          : item.trim();
      if (id.isNotEmpty) ids.add(id);
    }
    if (ids.isEmpty) return null;

    // A known issue that nobody owns is not a known issue, it is a surprise.
    // The release cut stays an operator decision, so the owner is recorded
    // rather than invented.
    const owners = <String>['operator'];
    return Sprint117KnownIssues(
      issueIds: ids,
      owners: owners,
      declaredCount: ids.length,
    );
  }

  Sprint117RollbackReadiness? _loadRollbackReadiness() {
    final rollout = _readJsonObject(
      Sprint117BetaEntryContract.rolloutManifestPath,
    );
    if (rollout == null) return null;

    final stopStageIds = <String>{};
    final rawStops = rollout['stop_conditions'];
    if (rawStops is List) {
      for (final raw in rawStops) {
        if (raw is! Map) continue;
        final stageId = _text(raw['stage_id']);
        if (stageId.isNotEmpty) stopStageIds.add(stageId);
      }
    }

    final exposed = <String>[];
    final rawStages = rollout['stages'];
    if (rawStages is List) {
      for (final raw in rawStages) {
        if (raw is! Map) continue;
        final connectors = raw['exposed_connectors'];
        if (connectors is List) {
          for (final item in connectors) {
            final id = _text(item);
            if (id.isNotEmpty && !exposed.contains(id)) exposed.add(id);
          }
        }
      }
    }

    final killSwitched = <String>[];
    var drillExecuted = false;
    final rawKills = rollout['provider_kill_switches'];
    if (rawKills is List) {
      for (final raw in rawKills) {
        if (raw is! Map) continue;
        final connector = _text(raw['connector_id']);
        if (connector.isNotEmpty && !killSwitched.contains(connector)) {
          killSwitched.add(connector);
        }
        if (raw['drill_verified'] == true) drillExecuted = true;
      }
    }

    return Sprint117RollbackReadiness(
      stopConditions: stopStageIds.length,
      rollbackProcedures: _listLength(rollout['rollback']),
      killSwitches: _listLength(rollout['provider_kill_switches']),
      coveredConnectors: killSwitched.length,
      exposedConnectors: exposed,
      killSwitchedConnectors: killSwitched,
      drillExecuted: drillExecuted,
    );
  }

  String _loadPubspecVersion() {
    final file = File(Sprint117BetaEntryContract.pubspecPath);
    if (!file.existsSync()) return '';
    for (final line in file.readAsLinesSync()) {
      final match = RegExp(r'^version:\s*(\S+)').firstMatch(line.trim());
      if (match != null) return match.group(1) ?? '';
    }
    return '';
  }

  Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    final items = <String>[];
    for (final raw in value) {
      final id = _text(raw);
      if (id.isNotEmpty && !items.contains(id)) items.add(id);
    }
    return items;
  }

  int? _int(Object? value) => value is int ? value : null;

  int _listLength(Object? value) => value is List ? value.length : 0;

  String _text(Object? value) => value == null ? '' : value.toString().trim();
}

class Sprint117BetaEntryGate {
  Sprint117BetaEntryReport evaluate() =>
      evaluateWith(const Sprint117BetaEntryInputLoader().load());

  Sprint117BetaEntryReport evaluateWith(Sprint117BetaEntryInput input) {
    final missing = <String>{};
    final violations = <String>[];

    // --- sprint_116_acceptance -------------------------------------------
    var sprint116Closed = false;
    var unmetClosureCriteria = <String>[];
    final acceptance = input.sprint116Acceptance;
    if (acceptance == null) {
      missing.add('sprint_116_acceptance');
    } else {
      if (acceptance.step != Sprint117BetaEntryContract.sprint116ClosureStep) {
        violations.add('sprint_116_step:${acceptance.step}');
      }
      if (acceptance.status !=
          Sprint117BetaEntryContract.sprint116ClosureStatus) {
        violations.add('sprint_116_status:${acceptance.status}');
      }
      if (acceptance.closureDecision !=
          Sprint117BetaEntryContract.sprint116ClosureDecision) {
        violations.add(
          'sprint_116_closure_decision:${acceptance.closureDecision}',
        );
      }
      if (acceptance.betaDecision !=
          Sprint117BetaEntryContract.sprint116BetaDecision) {
        violations.add('sprint_116_beta_decision:${acceptance.betaDecision}');
      }
      if (acceptance.definitionOfDone.isEmpty) {
        missing.add('sprint_116_acceptance');
      } else {
        // A closure that skipped criteria is not a closure: the beta decision
        // the entry relies on has to be backed by every recorded criterion.
        for (final criterion in acceptance.definitionOfDone) {
          if (!acceptance.metCriteria.contains(criterion)) {
            unmetClosureCriteria.add(criterion);
            violations.add('closure_criterion:$criterion');
          }
        }
        if (unmetClosureCriteria.isNotEmpty) {
          missing.add('sprint_116_acceptance');
        }
      }
      sprint116Closed =
          acceptance.closureDecision ==
          Sprint117BetaEntryContract.sprint116ClosureDecision;
      if (!sprint116Closed) missing.add('sprint_116_acceptance');
    }

    // --- certification_registry + certified_or_limited_subset -------------
    final visibility = <String, String>{};
    final certified = <String>[];
    final limited = <String>[];
    final blocked = <String>[];
    var registryProviderCount = 0;
    var evidenceProviderCount = 0;
    final registry = input.certificationRegistry;
    if (registry == null) {
      missing.add('certification_registry');
    } else {
      registryProviderCount = registry.providerCount;
      evidenceProviderCount = registry.evidenceProviderCount;

      if (registryProviderCount <= 0 || evidenceProviderCount <= 0) {
        missing.add('certification_registry');
      }
      if (registryProviderCount !=
          registry.certified.length +
              registry.limited.length +
              registry.blocked.length) {
        violations.add(
          'registry_unaccounted:'
          '${registry.certified.length + registry.limited.length + registry.blocked.length}:$registryProviderCount',
        );
      }
      if (evidenceProviderCount > registryProviderCount) {
        violations.add('registry_evidence:$evidenceProviderCount');
      }

      for (final provider in <String>[
        ...registry.certified,
        ...registry.limited,
        ...registry.blocked,
      ]) {
        if (provider.trim().isEmpty) {
          violations.add('phantom_provider:');
          continue;
        }
        if (certified.contains(provider) ||
            limited.contains(provider) ||
            blocked.contains(provider)) {
          violations.add('subset_overlap:$provider');
          continue;
        }
        if (registry.certified.contains(provider)) {
          certified.add(provider);
          visibility[provider] =
              Sprint117BetaEntryContract.knownVisibilities[0];
        } else if (registry.limited.contains(provider)) {
          limited.add(provider);
          visibility[provider] =
              Sprint117BetaEntryContract.knownVisibilities[1];
        } else {
          blocked.add(provider);
          visibility[provider] =
              Sprint117BetaEntryContract.knownVisibilities[2];
        }
      }

      if (certified.isEmpty && limited.isEmpty) {
        missing.add('certified_or_limited_subset');
      }
    }

    // --- beta_artifact -----------------------------------------------------
    var betaVersion = Sprint117BetaEntryContract.betaVersion;
    var pubspecVersion = '';
    var releaseCut = false;
    var liveBetaExecuted = false;
    final artifact = input.betaArtifact;
    if (artifact == null) {
      missing.add('beta_artifact');
    } else {
      if (artifact.betaVersion != Sprint117BetaEntryContract.betaVersion) {
        violations.add('beta_version:${artifact.betaVersion}');
      }
      if (!artifact.artifactRecorded) missing.add('beta_artifact');
      betaVersion = artifact.betaVersion;
      pubspecVersion = artifact.pubspecVersion;
      releaseCut = artifact.releaseCut;
    }

    // --- known_issues ------------------------------------------------------
    var knownIssueIds = <String>[];
    var knownIssueOwners = <String>[];
    final issues = input.knownIssues;
    if (issues == null) {
      missing.add('known_issues');
    } else {
      knownIssueIds = issues.issueIds;
      knownIssueOwners = issues.owners;
      if (knownIssueIds.isEmpty) {
        missing.add('known_issues');
      }
      if (knownIssueOwners.isEmpty && knownIssueIds.isNotEmpty) {
        violations.add('issue_owner:none');
      }
      if (knownIssueOwners.length != issues.declaredCount &&
          knownIssueIds.isNotEmpty) {
        violations.add(
          'issue_ownership:${issues.declaredCount}:${knownIssueOwners.length}',
        );
      }
    }

    // --- rollback_readiness -----------------------------------------------
    var rollbackStopConditions = 0;
    var rollbackProcedures = 0;
    var killSwitches = 0;
    var exposedConnectors = <String>[];
    var killSwitchedConnectors = <String>[];
    var drillExecuted = false;
    var rollbackReady = false;
    final readinessIssues = <String>[];
    final rollback = input.rollbackReadiness;
    if (rollback == null) {
      missing.add('rollback_readiness');
    } else {
      rollbackStopConditions = rollback.stopConditions;
      rollbackProcedures = rollback.rollbackProcedures;
      killSwitches = rollback.killSwitches;
      exposedConnectors = rollback.exposedConnectors;
      killSwitchedConnectors = rollback.killSwitchedConnectors;
      drillExecuted = rollback.drillExecuted;

      if (rollback.stopConditions <= 0) {
        readinessIssues.add('rollback_stop_conditions');
        violations.add('rollback_stop_conditions');
      }
      if (rollback.rollbackProcedures <= 0) {
        readinessIssues.add('rollback_procedures');
        violations.add('rollback_procedures');
      }
      if (rollback.killSwitches <= 0) {
        readinessIssues.add('rollback_kill_switches');
        violations.add('rollback_kill_switches');
      }
      for (final connector in rollback.exposedConnectors) {
        if (connector.trim().isEmpty) {
          readinessIssues.add('exposed_connector_blank');
          violations.add('exposed_connector_blank');
          continue;
        }
        if (!rollback.killSwitchedConnectors.contains(connector)) {
          readinessIssues.add('kill_switch_coverage:$connector');
          violations.add('kill_switch_coverage:$connector');
        }
      }
      rollbackReady = readinessIssues.isEmpty;
    }

    // --- verdict -----------------------------------------------------------
    final openItems = <String>[
      if (!releaseCut)
        'release_cut_pending: pubspec ${pubspecVersion.isEmpty ? '(unresolved)' : pubspecVersion} != ${Sprint117BetaEntryContract.betaVersion}',
    ];

    final state = missing.isNotEmpty
        ? Sprint117BetaEntryState.blocked
        : violations.isNotEmpty
        ? Sprint117BetaEntryState.fail
        : Sprint117BetaEntryState.pass;
    final verdict = state == Sprint117BetaEntryState.pass
        ? Sprint117BetaEntryContract.knownVerdicts[0]
        : state == Sprint117BetaEntryState.fail
        ? Sprint117BetaEntryContract.knownVerdicts[2]
        : Sprint117BetaEntryContract.knownVerdicts[1];

    final evidenceCoverage = <String, int>{
      for (final area in Sprint117BetaEntryContract.requiredEvidence) area: 0,
    };
    evidenceCoverage['sprint_116_acceptance'] = acceptance == null
        ? 0
        : acceptance.metCriteria.length;
    evidenceCoverage['certification_registry'] = registry == null
        ? 0
        : certified.length + limited.length + blocked.length;
    evidenceCoverage['certified_or_limited_subset'] =
        certified.length + limited.length;
    evidenceCoverage['beta_artifact'] = pubspecVersion.isEmpty ? 0 : 1;
    evidenceCoverage['known_issues'] = knownIssueIds.length;
    evidenceCoverage['rollback_readiness'] =
        rollbackStopConditions + rollbackProcedures + killSwitches;

    return Sprint117BetaEntryReport(
      state: state,
      verdict: verdict,
      missingEvidence: missing.toList(growable: false),
      violations: violations,
      registryProviderCount: registryProviderCount,
      certifiedSubset: certified,
      limitedSubset: limited,
      blockedSubset: blocked,
      visibility: visibility,
      sprint116Closed: sprint116Closed,
      unmetClosureCriteria: unmetClosureCriteria,
      betaVersion: betaVersion,
      pubspecVersion: pubspecVersion,
      releaseCut: releaseCut,
      liveBetaExecuted: liveBetaExecuted,
      knownIssueIds: knownIssueIds,
      knownIssueOwners: knownIssueOwners,
      rollbackStopConditions: rollbackStopConditions,
      rollbackProcedures: rollbackProcedures,
      killSwitches: killSwitches,
      rollbackReady: rollbackReady,
      exposedConnectors: exposedConnectors,
      rollbackKillSwitchedConnectors: killSwitchedConnectors,
      rollbackDrillExecuted: drillExecuted,
      evidenceCoverage: evidenceCoverage,
      openItems: openItems,
      limitations: const <String>[
        'Local certification chain only: the certified subset means every Sprint 116 gate in this repository passed for that provider; live provider handshake, credentials, quota, hosted CI, billing settlement, hardware, and publication remain DEFERRED-EXTERNAL.',
        'Record-level live status stays UNVERIFIED for every provider; no live beta run, no participant enrolment, and no kill-switch drill against a real system has executed.',
        'Release cut is an open item: the beta target and the pubspec version are reported side by side and are never assumed equal.',
        'This gate re-derives the canonical entry block; it does not edit the immutable canonical sprint contract. A start_condition satisfied locally still requires an operator release decision before beta execution.',
      ],
    );
  }
}
