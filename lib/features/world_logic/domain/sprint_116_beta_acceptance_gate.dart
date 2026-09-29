library;

import 'dart:convert';
import 'dart:io';

/// Fail-closed beta acceptance contract for Sprint 116.51.
///
/// The gate answers one question for `v1.3.0-beta.1`: which providers may the
/// beta show, and which must stay hidden until they pass. Every judgement is
/// derived from repository evidence — the provider certification manifests,
/// the active sprint ledger, the beta cohort plan, and the staged rollout
/// plan. Nothing here certifies a live provider: the certified subset means
/// every local Sprint 116 gate for that provider passed, while record-level
/// live status stays `UNVERIFIED` and external gates stay `DEFERRED-EXTERNAL`.
enum Sprint116BetaAcceptanceStatus { pass, fail, blocked }

class Sprint116CertificationFinding {
  const Sprint116CertificationFinding({
    required this.providerId,
    required this.step,
    required this.sourcePath,
    required this.manifestStatus,
    required this.recordStatus,
    required this.connectorVerdict,
    required this.recordCount,
  });

  final String providerId;
  final String step;
  final String sourcePath;
  final String manifestStatus;
  final String recordStatus;
  final String connectorVerdict;
  final int recordCount;
}

class Sprint116LedgerGateStatus {
  const Sprint116LedgerGateStatus({required this.step, required this.status});

  final String step;
  final String status;
}

class Sprint116BetaCoverageEntry {
  const Sprint116BetaCoverageEntry({
    required this.providerId,
    required this.connectorId,
    required this.stage,
    required this.consentRef,
  });

  final String providerId;
  final String connectorId;
  final String stage;
  final String consentRef;
}

class Sprint116BetaConsentEntry {
  const Sprint116BetaConsentEntry({
    required this.consentId,
    required this.cohortId,
  });

  final String consentId;
  final String cohortId;
}

class Sprint116BetaCoveragePlan {
  const Sprint116BetaCoveragePlan({
    required this.cohorts,
    required this.coverage,
    required this.consents,
  });

  final List<String> cohorts;
  final List<Sprint116BetaCoverageEntry> coverage;
  final List<Sprint116BetaConsentEntry> consents;
}

class Sprint116BetaStage {
  const Sprint116BetaStage({
    required this.stageId,
    required this.exposedConnectors,
  });

  final String stageId;
  final List<String> exposedConnectors;
}

class Sprint116BetaFlag {
  const Sprint116BetaFlag({required this.flagKey, required this.defaultState});

  final String flagKey;
  final String defaultState;
}

class Sprint116BetaRollback {
  const Sprint116BetaRollback({
    required this.rollbackId,
    required this.targetScope,
    required this.targetId,
    required this.touchesLocalData,
  });

  final String rollbackId;
  final String targetScope;
  final String targetId;
  final bool touchesLocalData;
}

class Sprint116BetaKillSwitch {
  const Sprint116BetaKillSwitch({
    required this.killId,
    required this.providerId,
    required this.connectorId,
    required this.stages,
  });

  final String killId;
  final String providerId;
  final String connectorId;
  final List<String> stages;
}

class Sprint116RolloutPlan {
  const Sprint116RolloutPlan({
    required this.stages,
    required this.flags,
    required this.stopStageIds,
    required this.rollbacks,
    required this.killSwitches,
  });

  final List<Sprint116BetaStage> stages;
  final List<Sprint116BetaFlag> flags;
  final List<String> stopStageIds;
  final List<Sprint116BetaRollback> rollbacks;
  final List<Sprint116BetaKillSwitch> killSwitches;
}

class Sprint116BetaAcceptanceInput {
  const Sprint116BetaAcceptanceInput({
    this.registryCounts = const <String, int>{},
    this.findings = const <Sprint116CertificationFinding>[],
    this.ledgerGates = const <Sprint116LedgerGateStatus>[],
    this.gateManifests = const <String, String?>{},
    this.coveragePlan,
    this.rolloutPlan,
    this.pubspecVersion = '',
    this.betaTarget = Sprint116BetaAcceptanceContract.betaTarget,
  });

  final Map<String, int> registryCounts;
  final List<Sprint116CertificationFinding> findings;
  final List<Sprint116LedgerGateStatus> ledgerGates;

  /// Gate step -> `canonical_step` read from that gate manifest, or null when
  /// the file is missing or unparseable. Absence of the key means the file was
  /// never loaded.
  final Map<String, String?> gateManifests;

  final Sprint116BetaCoveragePlan? coveragePlan;
  final Sprint116RolloutPlan? rolloutPlan;
  final String pubspecVersion;
  final String betaTarget;
}

class Sprint116GateResult {
  const Sprint116GateResult({
    required this.step,
    required this.ledgerStatus,
    required this.manifestPresent,
    required this.canonicalStepMatches,
  });

  final String step;
  final String? ledgerStatus;
  final bool manifestPresent;
  final bool canonicalStepMatches;

  Map<String, Object?> toJson() => <String, Object?>{
    'step': step,
    'ledger_status': ledgerStatus,
    'manifest_present': manifestPresent,
    'canonical_step_matches': canonicalStepMatches,
  };
}

class Sprint116BetaAcceptanceReport {
  Sprint116BetaAcceptanceReport({
    required this.state,
    required this.verdict,
    required List<String> missingEvidence,
    required List<String> violations,
    required this.registryProviderCount,
    required List<String> certifiedSubset,
    required List<String> limitedConnectors,
    required List<String> blockedConnectors,
    required Map<String, String> visibility,
    required List<Sprint116GateResult> qualityGates,
    required Map<String, int> evidenceCoverage,
    required this.betaTarget,
    required this.pubspecVersion,
    required this.betaVersionCut,
    required List<String> openItems,
    required this.betaPlanCohorts,
    required this.betaPlanConsents,
    required List<String> betaPlanCoverageProviders,
    required List<String> betaPlanExposedConnectors,
    required this.rollbackStopConditions,
    required this.rollbackProcedures,
    required this.rollbackKillSwitches,
    required this.rollbackReady,
    required List<String> limitations,
  }) : missingEvidence = List<String>.unmodifiable(missingEvidence),
       violations = List<String>.unmodifiable(violations),
       certifiedSubset = List<String>.unmodifiable(certifiedSubset),
       limitedConnectors = List<String>.unmodifiable(limitedConnectors),
       blockedConnectors = List<String>.unmodifiable(blockedConnectors),
       visibility = Map<String, String>.unmodifiable(visibility),
       qualityGates = List<Sprint116GateResult>.unmodifiable(qualityGates),
       evidenceCoverage = Map<String, int>.unmodifiable(evidenceCoverage),
       openItems = List<String>.unmodifiable(openItems),
       betaPlanCoverageProviders = List<String>.unmodifiable(
         betaPlanCoverageProviders,
       ),
       betaPlanExposedConnectors = List<String>.unmodifiable(
         betaPlanExposedConnectors,
       ),
       limitations = List<String>.unmodifiable(limitations);

  final Sprint116BetaAcceptanceStatus state;
  final String verdict;
  final List<String> missingEvidence;
  final List<String> violations;
  final int registryProviderCount;
  final List<String> certifiedSubset;
  final List<String> limitedConnectors;
  final List<String> blockedConnectors;
  final Map<String, String> visibility;
  final List<Sprint116GateResult> qualityGates;
  final Map<String, int> evidenceCoverage;
  final String betaTarget;
  final String pubspecVersion;
  final bool betaVersionCut;
  final List<String> openItems;
  final int betaPlanCohorts;
  final int betaPlanConsents;
  final List<String> betaPlanCoverageProviders;
  final List<String> betaPlanExposedConnectors;
  final int rollbackStopConditions;
  final int rollbackProcedures;
  final int rollbackKillSwitches;
  final bool rollbackReady;
  final List<String> limitations;

  String get externalGates => Sprint116BetaAcceptanceContract.externalGates;

  /// Providers the beta build must not show: everything that has not passed.
  List<String> get hiddenFromBeta => blockedConnectors;

  Map<String, Object?> toJson() => <String, Object?>{
    'state': state.name,
    'verdict': verdict,
    'missing_evidence': List<String>.from(missingEvidence),
    'violations': List<String>.from(violations),
    'registry_provider_count': registryProviderCount,
    'certified_subset': List<String>.from(certifiedSubset),
    'limited_connectors': List<String>.from(limitedConnectors),
    'blocked_connectors': List<String>.from(blockedConnectors),
    'visibility': Map<String, String>.from(visibility),
    'quality_gates': qualityGates
        .map((g) => g.toJson())
        .toList(growable: false),
    'evidence_coverage': Map<String, int>.from(evidenceCoverage),
    'beta_target': betaTarget,
    'pubspec_version': pubspecVersion,
    'beta_version_cut': betaVersionCut,
    'open_items': List<String>.from(openItems),
    'beta_plan': <String, Object?>{
      'cohorts': betaPlanCohorts,
      'consents': betaPlanConsents,
      'coverage_providers': List<String>.from(betaPlanCoverageProviders),
      'exposed_connectors': List<String>.from(betaPlanExposedConnectors),
    },
    'rollback_readiness': <String, Object?>{
      'stop_conditions': rollbackStopConditions,
      'rollback_procedures': rollbackProcedures,
      'kill_switches': rollbackKillSwitches,
      'ready': rollbackReady,
    },
    'external_gates': externalGates,
    'limitations': List<String>.from(limitations),
  };
}

abstract final class Sprint116BetaAcceptanceContract {
  static const String canonicalStep = '116.51';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_beta_acceptance_gate.json';
  static const String ledgerPath =
      'docs/sprints/sprint-116-connector-certification.md';
  static const String pubspecPath = 'pubspec.yaml';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The beta release the canonical step asks the gate to assess.
  static const String betaTarget = 'v1.3.0-beta.1';

  /// The seven evidence areas canonical step 116.51 names, in canonical order.
  static const List<String> requiredEvidence = <String>[
    'certification_registry',
    'certified_subset',
    'limited_connectors',
    'blocked_connectors',
    'quality_gates',
    'beta_plan',
    'rollback_readiness',
  ];

  /// Canonical provider ids, mirroring
  /// `lib/features/account/domain/account_center_provider_icon_registry.dart`.
  /// The copy exists so this gate stays inside one feature; a test pins it to
  /// the live icon registry and to both registry count documents, so drift
  /// fails instead of silently redefining the registry.
  static const List<String> registryProviders = <String>[
    'email',
    'google',
    'microsoft',
    'apple',
    'github',
    'discord',
    'x',
    'facebook',
    'google_drive',
    'onedrive',
    'dropbox',
    'mega',
    'local_storage',
    'openai',
    'gemini',
    'anthropic',
    'flux',
    'openrouter',
    'local_ai',
    'gitlab',
    'bitbucket',
    'azure_devops',
    'figma',
    'adobe',
    'canva',
    'blender_cloud',
    'sketchfab',
    'paypal',
    'stripe',
    'midtrans',
    'saweria',
    'kofi',
  ];

  /// Authority documents that state how many providers exist, and the JSON
  /// path holding the count inside each of them.
  static const Map<String, String> registryCountSources = <String, String>{
    'docs/planning/v1.2/sprint_115_provider_connector_manifest.json':
        'standard_manifest.entry_count',
    'docs/planning/v1.2/sprint_116_provider_registry_reconciliation.json':
        'expected_provider_count',
  };

  /// Per-provider certification manifests. Policy, fixture, and cross-cutting
  /// gate manifests are deliberately absent: their records describe harness
  /// fixtures, not a provider claim.
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

  /// Cross-cutting quality gates that must be VERIFIED-LOCAL before the beta
  /// can be accepted, and the two steps that define the beta itself.
  static const List<String> qualityGateSteps = <String>[
    '116.40',
    '116.41',
    '116.42',
    '116.43',
    '116.44',
    '116.45',
    '116.46',
    '116.47',
    '116.48',
  ];

  static const List<String> betaPlanSteps = <String>['116.49', '116.50'];

  static const List<String> requiredGateSteps = <String>[
    ...qualityGateSteps,
    ...betaPlanSteps,
  ];

  static const Map<String, String> gateManifestPaths = <String, String>{
    '116.40':
        'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
    '116.41':
        'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
    '116.42':
        'docs/planning/v1.2/sprint_116_provider_error_state_certification.json',
    '116.43':
        'docs/planning/v1.2/sprint_116_retry_backoff_circuit_breaker_certification.json',
    '116.44':
        'docs/planning/v1.2/sprint_116_offline_cached_metadata_certification.json',
    '116.45': 'docs/planning/v1.2/sprint_116_security_certification_gate.json',
    '116.46': 'docs/planning/v1.2/sprint_116_privacy_compliance_gate.json',
    '116.47':
        'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json',
    '116.48':
        'docs/planning/v1.2/sprint_116_connector_contract_e2e_matrix.json',
    '116.49': 'docs/planning/v1.2/sprint_116_beta_cohort_consent_plan.json',
    '116.50':
        'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json',
  };

  static const List<String> knownVisibility = <String>[
    'visible',
    'visible_limited',
    'hidden',
  ];

  static const List<String> knownCoverageStages = <String>[
    'committed',
    'planned',
    'deferred',
    'excluded',
  ];

  static const List<String> knownRecordStatuses = <String>[
    'UNVERIFIED',
    'CERTIFIED',
    'LIMITED',
    'BLOCKED',
    'EXPIRED',
  ];

  static const List<String> knownConnectorVerdicts = <String>[
    'BLOCKED',
    'LIMITED',
    'SUPPORTED',
  ];

  static const List<String> ledgerKnownStatuses = <String>[
    'VERIFIED-LOCAL',
    'PENDING',
    'BLOCKED',
    'VERIFIED',
  ];

  static const String verifiedStepStatus = 'VERIFIED-LOCAL';
  static const String connectorPrefix = 'conn_';

  /// `conn_openai` -> `openai`; anything without the prefix maps to nothing.
  static String providerIdFromConnector(String connectorId) {
    final trimmed = connectorId.trim();
    if (!trimmed.startsWith(connectorPrefix)) return '';
    final provider = trimmed.substring(connectorPrefix.length).trim();
    return provider.isEmpty ? '' : provider;
  }
}

class Sprint116BetaAcceptanceInputLoader {
  const Sprint116BetaAcceptanceInputLoader();

  Sprint116BetaAcceptanceInput load() => Sprint116BetaAcceptanceInput(
    registryCounts: _loadRegistryCounts(),
    findings: _loadFindings(),
    ledgerGates: _loadLedgerGates(),
    gateManifests: _loadGateManifests(),
    coveragePlan: _loadCoveragePlan(),
    rolloutPlan: _loadRolloutPlan(),
    pubspecVersion: _loadPubspecVersion(),
    betaTarget: Sprint116BetaAcceptanceContract.betaTarget,
  );

  Map<String, int> _loadRegistryCounts() {
    final counts = <String, int>{};
    for (final entry
        in Sprint116BetaAcceptanceContract.registryCountSources.entries) {
      final manifest = _readJsonObject(entry.key);
      if (manifest == null) continue;
      Object? cursor = manifest;
      for (final segment in entry.value.split('.')) {
        if (cursor is! Map) {
          cursor = null;
          break;
        }
        cursor = cursor[segment];
      }
      if (cursor is int) counts[entry.key] = cursor;
    }
    return counts;
  }

  List<Sprint116CertificationFinding> _loadFindings() {
    final findings = <Sprint116CertificationFinding>[];
    for (final path
        in Sprint116BetaAcceptanceContract.certificationManifestPaths) {
      final manifest = _readJsonObject(path);
      if (manifest == null) continue;
      final step = _text(manifest['canonical_step']);
      final manifestStatus = _text(manifest['status']);
      final records = manifest['records'];
      final recordList = records is List ? records : const <Object?>[];

      final manifestProvider = _text(manifest['provider']);
      if (manifestProvider.isNotEmpty) {
        var recordStatus = '';
        var count = 0;
        for (final raw in recordList) {
          if (raw is! Map) continue;
          count += 1;
          if (recordStatus.isEmpty) recordStatus = _text(raw['status']);
        }
        findings.add(
          Sprint116CertificationFinding(
            providerId: manifestProvider,
            step: step,
            sourcePath: path,
            manifestStatus: manifestStatus,
            recordStatus: recordStatus,
            connectorVerdict: '',
            recordCount: count,
          ),
        );
      }

      for (final raw in recordList) {
        if (raw is! Map) continue;
        final providerId = _text(raw['provider_id']);
        if (providerId.isEmpty) continue;
        findings.add(
          Sprint116CertificationFinding(
            providerId: providerId,
            step: step,
            sourcePath: path,
            manifestStatus: manifestStatus,
            recordStatus: _text(raw['status']),
            connectorVerdict: _text(raw['connector_verdict']),
            recordCount: 1,
          ),
        );
      }
    }
    return findings;
  }

  List<Sprint116LedgerGateStatus> _loadLedgerGates() {
    final file = File(Sprint116BetaAcceptanceContract.ledgerPath);
    if (!file.existsSync()) return <Sprint116LedgerGateStatus>[];
    final gates = <Sprint116LedgerGateStatus>[];
    for (final line in file.readAsLinesSync()) {
      if (!line.trimLeft().startsWith('|')) continue;
      var cells = line.split('|');
      if (cells.isNotEmpty && cells.first.trim().isEmpty) {
        cells = cells.sublist(1);
      }
      if (cells.isNotEmpty && cells.last.trim().isEmpty) {
        cells = cells.sublist(0, cells.length - 1);
      }
      if (cells.isEmpty) continue;
      final step = cells.first.trim();
      if (!RegExp(r'^116\.\d+$').hasMatch(step)) continue;
      String? status;
      for (final cell in cells.skip(1)) {
        final candidate = cell.trim();
        if (Sprint116BetaAcceptanceContract.ledgerKnownStatuses.contains(
          candidate,
        )) {
          status = candidate;
          break;
        }
      }
      if (status == null) continue;
      gates.add(Sprint116LedgerGateStatus(step: step, status: status));
    }
    return gates;
  }

  Map<String, String?> _loadGateManifests() {
    final manifests = <String, String?>{};
    for (final entry
        in Sprint116BetaAcceptanceContract.gateManifestPaths.entries) {
      final manifest = _readJsonObject(entry.value);
      manifests[entry.key] = manifest == null
          ? null
          : _text(manifest['canonical_step']);
    }
    return manifests;
  }

  Sprint116BetaCoveragePlan? _loadCoveragePlan() {
    final manifest = _readJsonObject(
      'docs/planning/v1.2/sprint_116_beta_cohort_consent_plan.json',
    );
    if (manifest == null) return null;

    final cohorts = <String>[];
    final selection = manifest['selection'];
    if (selection is List) {
      for (final raw in selection) {
        if (raw is! Map) continue;
        final id = _text(raw['cohort_id']);
        if (id.isNotEmpty) cohorts.add(id);
      }
    }

    final coverage = <Sprint116BetaCoverageEntry>[];
    final rawCoverage = manifest['provider_coverage'];
    if (rawCoverage is List) {
      for (final raw in rawCoverage) {
        if (raw is! Map) continue;
        coverage.add(
          Sprint116BetaCoverageEntry(
            providerId: _text(raw['provider_id']),
            connectorId: _text(raw['connector_id']),
            stage: _text(raw['stage']),
            consentRef: _text(raw['consent_ref']),
          ),
        );
      }
    }

    final consents = <Sprint116BetaConsentEntry>[];
    final rawConsents = manifest['consent'];
    if (rawConsents is List) {
      for (final raw in rawConsents) {
        if (raw is! Map) continue;
        consents.add(
          Sprint116BetaConsentEntry(
            consentId: _text(raw['consent_id']),
            cohortId: _text(raw['cohort_id']),
          ),
        );
      }
    }

    return Sprint116BetaCoveragePlan(
      cohorts: cohorts,
      coverage: coverage,
      consents: consents,
    );
  }

  Sprint116RolloutPlan? _loadRolloutPlan() {
    final manifest = _readJsonObject(
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json',
    );
    if (manifest == null) return null;

    final stages = <Sprint116BetaStage>[];
    final rawStages = manifest['stages'];
    if (rawStages is List) {
      for (final raw in rawStages) {
        if (raw is! Map) continue;
        final connectors = <String>[];
        final rawConnectors = raw['exposed_connectors'];
        if (rawConnectors is List) {
          connectors.addAll(rawConnectors.map((item) => item.toString()));
        }
        stages.add(
          Sprint116BetaStage(
            stageId: _text(raw['stage_id']),
            exposedConnectors: connectors,
          ),
        );
      }
    }

    final flags = <Sprint116BetaFlag>[];
    final rawFlags = manifest['flags'];
    if (rawFlags is List) {
      for (final raw in rawFlags) {
        if (raw is! Map) continue;
        flags.add(
          Sprint116BetaFlag(
            flagKey: _text(raw['flag_key']),
            defaultState: _text(raw['default_state']),
          ),
        );
      }
    }

    final stopStageIds = <String>[];
    final rawStops = manifest['stop_conditions'];
    if (rawStops is List) {
      for (final raw in rawStops) {
        if (raw is! Map) continue;
        final stageId = _text(raw['stage_id']);
        if (stageId.isNotEmpty && !stopStageIds.contains(stageId)) {
          stopStageIds.add(stageId);
        }
      }
    }

    final rollbacks = <Sprint116BetaRollback>[];
    final rawRollbacks = manifest['rollback'];
    if (rawRollbacks is List) {
      for (final raw in rawRollbacks) {
        if (raw is! Map) continue;
        rollbacks.add(
          Sprint116BetaRollback(
            rollbackId: _text(raw['rollback_id']),
            targetScope: _text(raw['target_scope']),
            targetId: _text(raw['target_id']),
            touchesLocalData: raw['local_project_data_touched'] == true,
          ),
        );
      }
    }

    final killSwitches = <Sprint116BetaKillSwitch>[];
    final rawKills = manifest['provider_kill_switches'];
    if (rawKills is List) {
      for (final raw in rawKills) {
        if (raw is! Map) continue;
        final stagesCovered = <String>[];
        final rawStages = raw['stages'];
        if (rawStages is List) {
          stagesCovered.addAll(rawStages.map((item) => item.toString()));
        }
        killSwitches.add(
          Sprint116BetaKillSwitch(
            killId: _text(raw['kill_id']),
            providerId: _text(raw['provider_id']),
            connectorId: _text(raw['connector_id']),
            stages: stagesCovered,
          ),
        );
      }
    }

    return Sprint116RolloutPlan(
      stages: stages,
      flags: flags,
      stopStageIds: stopStageIds,
      rollbacks: rollbacks,
      killSwitches: killSwitches,
    );
  }

  String _loadPubspecVersion() {
    final file = File(Sprint116BetaAcceptanceContract.pubspecPath);
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

  String _text(Object? value) => value == null ? '' : value.toString().trim();
}

class Sprint116BetaAcceptanceGate {
  Sprint116BetaAcceptanceReport evaluate() =>
      evaluateWith(const Sprint116BetaAcceptanceInputLoader().load());

  Sprint116BetaAcceptanceReport evaluateWith(
    Sprint116BetaAcceptanceInput input,
  ) {
    final missing = <String>{};
    final violations = <String>[];
    const registry = Sprint116BetaAcceptanceContract.registryProviders;

    // --- certification_registry -------------------------------------------
    if (input.registryCounts.isEmpty || input.findings.isEmpty) {
      missing.add('certification_registry');
    }
    for (final source
        in Sprint116BetaAcceptanceContract.registryCountSources.keys) {
      final count = input.registryCounts[source];
      if (count == null) {
        missing.add('certification_registry');
      } else if (count != registry.length) {
        violations.add('registry_count:$source:$count');
        missing.add('certification_registry');
      }
    }

    final byProvider = <String, List<Sprint116CertificationFinding>>{};
    for (final finding in input.findings) {
      if (!registry.contains(finding.providerId)) {
        violations.add('phantom_provider:${finding.providerId}');
        continue;
      }
      byProvider.putIfAbsent(finding.providerId, () => []).add(finding);
    }

    // --- certified / limited / blocked ------------------------------------
    final visibility = <String, String>{};
    final certified = <String>[];
    final limited = <String>[];
    final hidden = <String>[];
    final hiddenWire = Sprint116BetaAcceptanceContract.knownVisibility[2];
    final limitedWire = Sprint116BetaAcceptanceContract.knownVisibility[1];
    final visibleWire = Sprint116BetaAcceptanceContract.knownVisibility[0];

    for (final provider in registry) {
      final findings = byProvider[provider];
      if (findings == null || findings.isEmpty) {
        visibility[provider] = hiddenWire;
        hidden.add(provider);
        continue;
      }

      var rejected = false;
      for (final finding in findings) {
        if (finding.manifestStatus !=
            Sprint116BetaAcceptanceContract.verifiedStepStatus) {
          violations.add('certification_source:$provider:${finding.step}');
          rejected = true;
        }
        if (finding.recordStatus.isNotEmpty &&
            !Sprint116BetaAcceptanceContract.knownRecordStatuses.contains(
              finding.recordStatus,
            )) {
          violations.add('record_status:$provider:${finding.recordStatus}');
          rejected = true;
        }
        if (finding.connectorVerdict.isNotEmpty &&
            !Sprint116BetaAcceptanceContract.knownConnectorVerdicts.contains(
              finding.connectorVerdict,
            )) {
          violations.add(
            'connector_verdict:$provider:${finding.connectorVerdict}',
          );
          rejected = true;
        }
      }
      if (rejected) {
        visibility[provider] = hiddenWire;
        hidden.add(provider);
        continue;
      }

      final failed = findings.any(
        (finding) =>
            finding.recordStatus == 'BLOCKED' ||
            finding.recordStatus == 'EXPIRED' ||
            finding.connectorVerdict == 'BLOCKED',
      );
      if (failed) {
        visibility[provider] = hiddenWire;
        hidden.add(provider);
        continue;
      }

      final degraded = findings.any(
        (finding) =>
            finding.recordStatus == 'LIMITED' ||
            finding.connectorVerdict == 'LIMITED',
      );
      if (degraded) {
        visibility[provider] = limitedWire;
        limited.add(provider);
        continue;
      }

      visibility[provider] = visibleWire;
      certified.add(provider);
    }

    if (certified.isEmpty) missing.add('certified_subset');

    // --- quality_gates -----------------------------------------------------
    final gateResults = <Sprint116GateResult>[];
    for (final step in Sprint116BetaAcceptanceContract.requiredGateSteps) {
      String? ledgerStatus;
      for (final gate in input.ledgerGates) {
        if (gate.step == step) {
          ledgerStatus = gate.status;
          break;
        }
      }
      final manifestPresent = input.gateManifests.containsKey(step);
      final canonicalStep = manifestPresent ? input.gateManifests[step] : null;
      final canonicalMatches = manifestPresent && canonicalStep == step;
      gateResults.add(
        Sprint116GateResult(
          step: step,
          ledgerStatus: ledgerStatus,
          manifestPresent: manifestPresent,
          canonicalStepMatches: canonicalMatches,
        ),
      );

      if (ledgerStatus == null ||
          ledgerStatus != Sprint116BetaAcceptanceContract.verifiedStepStatus) {
        violations.add('quality_gate:$step');
      }
      if (!manifestPresent) {
        violations.add('gate_manifest:$step');
      } else if (!canonicalMatches) {
        violations.add('gate_manifest_step:$step');
      }
    }
    final anyGateEvidence = gateResults.any(
      (gate) => gate.ledgerStatus != null || gate.manifestPresent,
    );
    if (!anyGateEvidence) missing.add('quality_gates');

    // --- beta_plan ---------------------------------------------------------
    var cohorts = 0;
    var consents = 0;
    final coverageProviders = <String>[];
    final plan = input.coveragePlan;
    if (plan == null ||
        plan.cohorts.isEmpty ||
        plan.coverage.isEmpty ||
        plan.consents.isEmpty) {
      missing.add('beta_plan');
    } else {
      cohorts = plan.cohorts.length;
      consents = plan.consents.length;
      final consentIds = plan.consents.map((entry) => entry.consentId).toSet();
      for (final entry in plan.coverage) {
        coverageProviders.add(entry.providerId);
        if (!registry.contains(entry.providerId)) {
          violations.add('unknown_coverage_provider:${entry.providerId}');
        }
        if (!Sprint116BetaAcceptanceContract.knownCoverageStages.contains(
          entry.stage,
        )) {
          violations.add('coverage_stage:${entry.providerId}:${entry.stage}');
        }
        if (entry.consentRef.isEmpty ||
            !consentIds.contains(entry.consentRef)) {
          violations.add('consent_ref:${entry.consentRef}');
        }
        final onBetaTrack =
            entry.stage == 'committed' || entry.stage == 'planned';
        if (onBetaTrack && visibility[entry.providerId] == hiddenWire) {
          violations.add('beta_plan_blocked:${entry.providerId}');
        }
      }
      for (final consent in plan.consents) {
        if (consent.consentId.isEmpty) {
          violations.add('consent_id_blank');
          continue;
        }
        if (!plan.cohorts.contains(consent.cohortId)) {
          violations.add('consent_cohort:${consent.consentId}');
        }
      }
    }

    // --- rollback_readiness + exposed connectors ---------------------------
    final rollout = input.rolloutPlan;
    var stops = 0;
    var rollbackProcedures = 0;
    var killSwitches = 0;
    var rollbackReady = false;
    final exposedConnectors = <String>[];
    final readinessIssues = <String>[];

    if (rollout == null ||
        rollout.stages.isEmpty ||
        rollout.rollbacks.isEmpty ||
        rollout.killSwitches.isEmpty) {
      missing.add('rollback_readiness');
    }
    if (rollout != null && rollout.stages.isNotEmpty) {
      stops = rollout.stopStageIds.length;
      rollbackProcedures = rollout.rollbacks.length;
      killSwitches = rollout.killSwitches.length;

      for (final flag in rollout.flags) {
        if (flag.defaultState != 'OFF') {
          violations.add('flag_default:${flag.flagKey}');
        }
      }

      final stopStages = Set<String>.from(rollout.stopStageIds);
      final rollbackStages = <String>{
        for (final rollback in rollout.rollbacks)
          if (rollback.targetScope == 'stage') rollback.targetId,
      };
      final stageIds = rollout.stages.map((stage) => stage.stageId).toSet();
      final flagKeys = rollout.flags.map((flag) => flag.flagKey).toSet();

      for (final stage in rollout.stages) {
        if (!stopStages.contains(stage.stageId)) {
          final issue = 'stage_stop_coverage:${stage.stageId}';
          readinessIssues.add(issue);
          violations.add(issue);
        }
        if (!rollbackStages.contains(stage.stageId)) {
          final issue = 'stage_rollback_coverage:${stage.stageId}';
          readinessIssues.add(issue);
          violations.add(issue);
        }
        for (final connector in stage.exposedConnectors) {
          if (!exposedConnectors.contains(connector)) {
            exposedConnectors.add(connector);
          }
          final provider =
              Sprint116BetaAcceptanceContract.providerIdFromConnector(
                connector,
              );
          if (provider.isEmpty || !registry.contains(provider)) {
            violations.add(
              'exposed_unknown_connector:${stage.stageId}:$connector',
            );
            continue;
          }
          if (visibility[provider] == hiddenWire) {
            violations.add('exposed_blocked:${stage.stageId}:$connector');
          }
          final covered = rollout.killSwitches.any(
            (killSwitch) =>
                killSwitch.connectorId == connector &&
                killSwitch.stages.contains(stage.stageId),
          );
          if (!covered) {
            final issue = 'kill_switch_coverage:${stage.stageId}:$connector';
            readinessIssues.add(issue);
            violations.add(issue);
          }
        }
      }

      for (final rollback in rollout.rollbacks) {
        if (rollback.touchesLocalData) {
          final issue = 'rollback_local_data:${rollback.rollbackId}';
          readinessIssues.add(issue);
          violations.add(issue);
        }
        final resolvable = switch (rollback.targetScope) {
          'stage' => stageIds.contains(rollback.targetId),
          'flag' => flagKeys.contains(rollback.targetId),
          'provider' => registry.contains(rollback.targetId),
          _ => false,
        };
        if (!resolvable) {
          final issue = 'rollback_target:${rollback.rollbackId}';
          readinessIssues.add(issue);
          violations.add(issue);
        }
      }

      rollbackReady =
          readinessIssues.isEmpty &&
          rollout.rollbacks.isNotEmpty &&
          rollout.killSwitches.isNotEmpty;
    }

    // --- verdict -----------------------------------------------------------
    final betaPlanComplete =
        plan != null &&
        plan.cohorts.isNotEmpty &&
        plan.coverage.isNotEmpty &&
        plan.consents.isNotEmpty;
    final expectedTarget =
        Sprint116BetaAcceptanceContract.betaTarget.startsWith('v')
        ? Sprint116BetaAcceptanceContract.betaTarget.substring(1)
        : Sprint116BetaAcceptanceContract.betaTarget;
    final betaVersionCut =
        input.pubspecVersion.isNotEmpty &&
        input.pubspecVersion == expectedTarget;
    final openItems = <String>[
      if (!betaVersionCut)
        'release_cut_pending: pubspec ${input.pubspecVersion.isEmpty ? '(unresolved)' : input.pubspecVersion} != ${Sprint116BetaAcceptanceContract.betaTarget}',
    ];

    final state = missing.isNotEmpty
        ? Sprint116BetaAcceptanceStatus.blocked
        : violations.isNotEmpty
        ? Sprint116BetaAcceptanceStatus.fail
        : Sprint116BetaAcceptanceStatus.pass;
    final verdict = state == Sprint116BetaAcceptanceStatus.pass
        ? 'BETA_ACCEPTANCE_LOCAL_READY'
        : state == Sprint116BetaAcceptanceStatus.fail
        ? 'BETA_ACCEPTANCE_FAILED'
        : 'BETA_ACCEPTANCE_BLOCKED';

    final passingGates = gateResults
        .where(
          (gate) =>
              gate.ledgerStatus ==
                  Sprint116BetaAcceptanceContract.verifiedStepStatus &&
              gate.manifestPresent &&
              gate.canonicalStepMatches,
        )
        .length;

    final evidenceCoverage = <String, int>{
      for (final area in Sprint116BetaAcceptanceContract.requiredEvidence)
        area: 0,
    };
    evidenceCoverage['certification_registry'] = byProvider.length;
    evidenceCoverage['certified_subset'] = certified.length;
    evidenceCoverage['limited_connectors'] = limited.length;
    evidenceCoverage['blocked_connectors'] = hidden.length;
    evidenceCoverage['quality_gates'] = passingGates;
    evidenceCoverage['beta_plan'] = betaPlanComplete ? plan.coverage.length : 0;
    evidenceCoverage['rollback_readiness'] = rollout == null
        ? 0
        : stops + rollbackProcedures + killSwitches;

    return Sprint116BetaAcceptanceReport(
      state: state,
      verdict: verdict,
      missingEvidence: missing.toList(growable: false),
      violations: violations,
      registryProviderCount: registry.length,
      certifiedSubset: certified,
      limitedConnectors: limited,
      blockedConnectors: hidden,
      visibility: visibility,
      qualityGates: gateResults,
      evidenceCoverage: evidenceCoverage,
      betaTarget: Sprint116BetaAcceptanceContract.betaTarget,
      pubspecVersion: input.pubspecVersion,
      betaVersionCut: betaVersionCut,
      openItems: openItems,
      betaPlanCohorts: cohorts,
      betaPlanConsents: consents,
      betaPlanCoverageProviders: coverageProviders,
      betaPlanExposedConnectors: exposedConnectors,
      rollbackStopConditions: stops,
      rollbackProcedures: rollbackProcedures,
      rollbackKillSwitches: killSwitches,
      rollbackReady: rollbackReady,
      limitations: const <String>[
        'Local certification chain only: the certified subset means every Sprint 116 gate in this repository passed for that provider; live provider handshake, credentials, quota, hosted CI, billing settlement, hardware, and publication remain DEFERRED-EXTERNAL.',
        'Record-level live status stays UNVERIFIED for every certified provider; no live beta run, no participant enrolment, and no kill-switch drill against a real system has executed.',
        'Release cut is an open item: the beta target and the pubspec version are reported side by side and are never assumed equal.',
      ],
    );
  }
}
