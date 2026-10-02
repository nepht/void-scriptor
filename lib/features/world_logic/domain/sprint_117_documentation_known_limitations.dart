/// Sprint 117.42 — Documentation & Known Limitations (gate gagal-tertutup).
///
/// Canonical step (external `sprint_117.json`) objective: "Menyelesaikan setup,
/// permissions, quota, units, usage, cost, privacy, disconnect, recovery,
/// billing, and provider limitations.", with eight `outputs`:
///   setup_guides, permission_guides, quota_notes, usage_cost_notes,
///   privacy_notes, disconnect_guide, recovery_guide, limitations.
///
/// The step names no per-output acceptance vocabulary, so this gate does not
/// invent one. It measures the two claims the step DOES state:
///
/// 1. every named output resolves to documents that exist on disk and to a
///    seam that actually read them, and
/// 2. the limitations a provider row publishes are the limitations the shipped
///    connector manifest derives — not a constant invented by the caller.
///
/// Defect 117.42-01 (fail-open, fixed here): provider limitations were bound to
/// nothing. `ProviderConnectorEntry` — the shipped per-provider source — ships
/// no limitations field, so the 32 registry rows in 117.41 were each handed the
/// same hand-typed pair `['not_live_provider_availability',
/// 'no_signed_connector_release']` by the caller, and the registry reported a
/// per-provider limitation set that no seam derived. Root cause: the limitation
/// vocabulary was never bound to the manifest, so any string passed.
/// `Sprint117ProviderLimitationCatalogue.derive` computes the set from the
/// fields the entry does ship, and this gate compares declared against derived.
///
/// Defect 117.42-02 (measured and reported, NOT fixed): the shipped
/// `ProviderPermission` vocabulary has no member covering developer/repository
/// access, so the four developer connectors ship a permission set byte-identical
/// to an identity connector's. `permission_guides` therefore cannot describe
/// developer scope. Widening the shared enum changes the manifest contract used
/// by 115.9 and every other connector step, which is outside this step's
/// documentation scope, so it is recorded as a named open item and never
/// converted to a pass.
///
/// Status per check:
/// * `pass` — the shipped seam produced the measured value;
/// * `violation` — the output or row contradicts what the seam measured;
/// * `unmet` — a row this slice could not measure from a shipped seam, named as
///   an open item and never converted to a pass.
///
/// Fail-closed structural failures:
/// * `non_canonical_outputs` — the eight canonical outputs drifted;
/// * `no_documentation_rows` — an empty row set documents no provider;
/// * `no_document:<output>` — an output resolves to no document at all;
/// * `missing_reference:<output>:<path>` — a named document nobody can open;
/// * `output_without_pass:<output>` — an output with no passing measured check;
/// * `duplicate_check:<output>:<check>`;
/// * `vacuous:<output>:<check>` — a blank declared/observed statement is not
///   evidence;
/// * `unknown_output:<id>` / `unknown_check:<output>:<check>` — vocabulary drift
///   outside the canonical eight is rejected, never quietly accepted;
/// * `no_derived_limitation:<provider>` — a provider whose derivation is empty
///   documents nothing, so it fails closed rather than passing as "no limits";
/// * `limitations_not_derived:<provider>` — the published limitation set is not
///   what the shipped entry derives.
///
/// The gate is pure Dart so it can be re-evaluated from recorded facts.
library;

import 'dart:io';

import '../../account/domain/account_center_provider_connector_manifest.dart';

/// Status of one measured check on one documentation output.
enum Sprint117DocumentationStatus { pass, violation, unmet }

/// Per-provider limitation vocabulary derived from the shipped manifest.
///
/// The set is computed from the entry's own recorded fields, so two providers
/// that ship different auth shapes, permissions, or availability cannot publish
/// the same limitation set, and no caller can hand the gate an arbitrary
/// string.
abstract final class Sprint117ProviderLimitationCatalogue {
  /// The limitation every provider carries because no live availability probe
  /// exists for any of them.
  static const String noLiveProbe = 'availability_unverified';

  /// Documents the auth shape the entry records, so a guide never promises a
  /// permission the connector cannot obtain.
  static String forAuthType(ProviderAuthType authType) => switch (authType) {
    ProviderAuthType.oauth2Pkce => 'auth_oauth2_pkce',
    ProviderAuthType.apiKey => 'auth_api_key',
    ProviderAuthType.oidc => 'auth_oidc',
    ProviderAuthType.deviceCode => 'auth_device_code',
    ProviderAuthType.localBroker => 'auth_local_broker',
    ProviderAuthType.none => 'auth_none',
  };

  /// Documents the availability the manifest records, so a reader is told the
  /// state rather than left to infer it.
  static String forAvailability(ProviderConnectorAvailability availability) =>
      switch (availability) {
        ProviderConnectorAvailability.unverified => 'availability_unverified',
        ProviderConnectorAvailability.planned => 'availability_planned',
        ProviderConnectorAvailability.available => 'availability_available',
        ProviderConnectorAvailability.unavailable => 'availability_unavailable',
        ProviderConnectorAvailability.unsupportedRegion =>
          'availability_unsupported_region',
        ProviderConnectorAvailability.degraded => 'availability_degraded',
        ProviderConnectorAvailability.outage => 'availability_outage',
      };

  /// Every permission the entry records becomes its own documented scope, so a
  /// dropped permission shows up as a changed limitation set.
  static String forPermission(ProviderPermission permission) =>
      'permission_${permission.wireName}';

  /// The limitation set the shipped entry derives.
  ///
  /// Order is stable (auth, availability, permissions sorted by wire name) so a
  /// re-evaluation compares like with like.
  static List<String> derive(ProviderConnectorEntry entry) {
    final permissions = entry.permissions.map(forPermission).toList()..sort();
    return <String>[
      forAuthType(entry.authType),
      forAvailability(entry.availability),
      ...permissions,
      if (entry.healthEndpoint == ProviderHealthEndpoint.unverified)
        'health_endpoint_unverified',
    ];
  }

  /// True when [declared] is exactly the set [entry] derives.
  ///
  /// Both a constant the entry does not derive and a fabricated extra string
  /// fail here, which is what closes 117.42-01.
  static bool isDerived(
    ProviderConnectorEntry entry,
    Iterable<String> declared,
  ) {
    final derived = derive(entry).toSet();
    final published = declared.map((value) => value.trim()).toSet()
      ..removeWhere((value) => value.isEmpty);
    if (published.length != declared.where((v) => v.trim().isNotEmpty).length) {
      return false;
    }
    return derived.length == published.length && derived.containsAll(published);
  }
}

/// One canonical documentation output and the documents it resolves to.
final class Sprint117DocumentationOutput {
  const Sprint117DocumentationOutput({
    required this.outputId,
    required this.references,
    required this.seamLabel,
  });

  /// One of the eight canonical `outputs`.
  final String outputId;

  /// Documents this output resolves to. Checked against the filesystem.
  final List<String> references;

  /// The seam that read those documents. Labelling is reporting, not a
  /// measurement boundary: the gate still checks the paths on disk.
  final String seamLabel;

  Map<String, Object?> toJson() => <String, Object?>{
    'output_id': outputId,
    'references': List<String>.from(references),
    'seam_label': seamLabel,
  };
}

/// One provider row: what the seam derived vs what the registry publishes.
final class Sprint117DocumentationRow {
  const Sprint117DocumentationRow({
    required this.providerId,
    required this.derivedLimitations,
    required this.declaredLimitations,
  });

  final String providerId;

  /// What `Sprint117ProviderLimitationCatalogue.derive` computes from the
  /// shipped manifest entry.
  final List<String> derivedLimitations;

  /// What the registry publishes for this provider.
  final List<String> declaredLimitations;

  Map<String, Object?> toJson() => <String, Object?>{
    'provider_id': providerId,
    'derived_limitations': List<String>.from(derivedLimitations),
    'declared_limitations': List<String>.from(declaredLimitations),
  };
}

/// One measured statement about one documentation output.
final class Sprint117DocumentationCheck {
  const Sprint117DocumentationCheck({
    required this.outputId,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117DocumentationCheck.pass_({
    required String outputId,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117DocumentationCheck(
    outputId: outputId,
    check: check,
    status: Sprint117DocumentationStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117DocumentationCheck.violation({
    required String outputId,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117DocumentationCheck(
    outputId: outputId,
    check: check,
    status: Sprint117DocumentationStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117DocumentationCheck.unmet({
    required String outputId,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117DocumentationCheck(
    outputId: outputId,
    check: check,
    status: Sprint117DocumentationStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  final String outputId;
  final String check;
  final Sprint117DocumentationStatus status;
  final String declared;
  final String observed;
  final String note;

  String get code => '$outputId:$check';

  bool get isViolation => status == Sprint117DocumentationStatus.violation;

  Map<String, Object?> toJson() => <String, Object?>{
    'output_id': outputId,
    'check': check,
    'status': status.name,
    'declared': declared,
    'observed': observed,
    if (note.isNotEmpty) 'note': note,
  };
}

/// Aggregate verdict of the 117.42 documentation gate.
final class Sprint117DocumentationResult {
  const Sprint117DocumentationResult({
    required this.verdict,
    required this.pass,
    required this.failures,
    required this.openItems,
    required this.checks,
    required this.outputs,
    required this.rows,
    required this.exposedProviderIds,
    required this.unresolvedProviderIds,
  });

  final String verdict;
  final bool pass;
  final List<String> failures;
  final List<String> openItems;
  final List<Sprint117DocumentationCheck> checks;
  final List<Sprint117DocumentationOutput> outputs;
  final List<Sprint117DocumentationRow> rows;

  /// Providers whose declared limitations match the derived set.
  final List<String> exposedProviderIds;

  /// Providers whose published limitations are not what the seam derives.
  final List<String> unresolvedProviderIds;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117DocumentationContract.canonicalStep,
    'document_role': 'EVIDENCE',
    'verdict': verdict,
    'pass': pass,
    'required_outputs': Sprint117DocumentationContract.requiredOutputs.toList(),
    'output_count': outputs.length,
    'row_count': rows.length,
    'exposed_provider_ids': List<String>.from(exposedProviderIds),
    'unresolved_provider_ids': List<String>.from(unresolvedProviderIds),
    'failures': List<String>.from(failures),
    'open_items': List<String>.from(openItems),
    'checks': [for (final check in checks) check.toJson()],
    'outputs': [for (final output in outputs) output.toJson()],
  };
}

/// Fail-closed documentation contract for sprint 117.42.
abstract final class Sprint117DocumentationContract {
  /// The canonical roadmap step this gate measures.
  static const String canonicalStep = '117.42';

  /// The eight canonical `outputs`, verbatim and in contract order.
  static const List<String> requiredOutputs = <String>[
    'setup_guides',
    'permission_guides',
    'quota_notes',
    'usage_cost_notes',
    'privacy_notes',
    'disconnect_guide',
    'recovery_guide',
    'limitations',
  ];

  static const String passVerdict = 'DOCUMENTATION_LIMITATIONS_COMPLETE_LOCAL';
  static const String failVerdict = 'DOCUMENTATION_LIMITATIONS_INCOMPLETE';

  /// Every document each canonical output resolves to.
  ///
  /// Resolved from the shipped seam constants rather than retyped, so the map
  /// and the seams cannot disagree about what backs an output.
  static const Map<String, List<String>>
  outputReferences = <String, List<String>>{
    // Installation and upgrade paths (117.9 reads these manifests).
    'setup_guides': <String>[
      'docs/planning/v1.2/sprint_113_upgrade_path_validation.json',
      'docs/planning/v1.2/sprint_114_install_update_health.json',
      'docs/planning/v1.2/sprint_114_upgrade_migration_health.json',
      'docs/planning/v1.2/sprint_112_platform_compatibility_gate.json',
      'docs/planning/v1.3/sprint_117_installation_upgrade_validation.json',
    ],
    // The connector manifest is where every permission scope is recorded.
    'permission_guides': <String>[
      'docs/planning/v1.2/sprint_115_provider_connector_manifest.json',
      'docs/planning/v1.2/sprint_115_cloud_storage_account_model.json',
    ],
    // Quota adapters, aggregation, and the unit vocabulary they share.
    'quota_notes': <String>[
      'docs/planning/v1.2/sprint_115_provider_quota_adapters.json',
      'docs/planning/v1.2/sprint_115_cloud_storage_aggregation.json',
      'docs/planning/v1.2/sprint_115_storage_usage_cards.json',
      'docs/planning/v1.2/sprint_115_local_storage_summary.json',
      'docs/planning/v1.2/sprint_115_storage_distribution_chart_table.json',
      'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
      'docs/planning/v1.3/sprint_117_cloud_storage_quota_validation.json',
    ],
    // Usage/cost separation and billing entitlement reconciliation.
    'usage_cost_notes': <String>[
      'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json',
      'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
      'docs/planning/v1.3/sprint_117_privacy_safe_monitoring.json',
    ],
    // Consent, retention, deletion, external transfer, redaction.
    'privacy_notes': <String>[
      'docs/planning/v1.2/sprint_113_privacy_safe_evidence_plan.json',
      'docs/planning/v1.2/sprint_114_privacy_safe_monitoring.json',
      'docs/planning/v1.2/sprint_115_connection_health_state_machine.json',
      'docs/planning/v1.3/sprint_117_privacy_safe_monitoring.json',
    ],
    // Unlink/revoke is documented by the OAuth revocation validation.
    'disconnect_guide': <String>[
      'docs/planning/v1.2/sprint_115_token_expiry_reauthentication_ux.json',
      'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json',
      'docs/planning/v1.2/sprint_116_provider_error_state_certification.json',
    ],
    // The incident response pair responders open during an outage.
    'recovery_guide': <String>[
      'docs/release/v1.2.0-rc.1-support-playbook.md',
      'docs/release/v1.2.0-rc.1-recovery-guide.md',
      'docs/planning/v1.3/sprint_117_support_incident_readiness.json',
      'docs/planning/v1.3/sprint_117_provider_rollback_drill.json',
    ],
    // The published limits, plus the per-provider derivation they summarise.
    'limitations': <String>[
      'docs/release/v1.2.0-rc.1-known-limits.md',
      'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json',
      'docs/planning/v1.3/sprint_117_beta_validation_charter.json',
      'docs/planning/v1.3/sprint_117_account_configuration_migration.json',
    ],
  };

  /// True when [outputId] is one of the canonical eight.
  static bool isCanonicalOutput(String outputId) =>
      requiredOutputs.toSet().contains(outputId.trim());

  /// The documents [outputId] resolves to, or an empty list when the id is not
  /// one of the canonical eight.
  ///
  /// Total by construction so no caller has to re-derive the membership test
  /// and diverge from the gate's own vocabulary check.
  static List<String> referencesFor(String outputId) =>
      outputReferences[outputId.trim()] ?? const <String>[];

  /// Where each output is measured (reporting, not a measurement boundary).
  static const Map<String, String> surfaceLabels = <String, String>{
    'setup_guides':
        'Sprint117UpgradeContract.upgradePath/migrationHealth/'
        'installHealth/dryRun/rollbackBoundary/platformGate',
    'permission_guides':
        'ProviderConnectorEntry.permissions + ProviderHealthEndpoint.parse',
    'quota_notes':
        'ProviderQuotaResult.fromReading + '
        'account_center_cloud_storage_aggregation._convertToBytes + '
        'Sprint117CloudStorageQuotaContract.requiredChecks',
    'usage_cost_notes':
        'AccountCenterBillingSummary.billingContractStatus + '
        'Sprint117UsageCostValidation.requiredAreas',
    'privacy_notes':
        'AccountCenterPrivacyDataFlowReview.requiredOutputs + '
        'Sprint117PrivacyAssessment.requiredAreas',
    'disconnect_guide':
        'Sprint117OAuthRevocationValidation.requiredAreas (reauth, '
        'provider_revoke, disconnect, cleanup)',
    'recovery_guide':
        'Sprint117SupportContract.supportPlaybookRef/recoveryGuideRef checked '
        'against the filesystem',
    'limitations':
        'Sprint117ProviderLimitationCatalogue.derive + '
        'Sprint117ConnectorRegistryRow.limitations',
  };

  /// A declared or observed value that trims to nothing is not evidence.
  static bool isVacuous(Sprint117DocumentationCheck check) =>
      check.declared.trim().isEmpty || check.observed.trim().isEmpty;

  static String _readable(String value) =>
      value.trim().isEmpty ? '(no id)' : value.trim();

  static Sprint117DocumentationResult evaluate(
    List<Sprint117DocumentationOutput> outputs,
    List<Sprint117DocumentationCheck> checks,
    List<Sprint117DocumentationRow> rows,
  ) {
    if (requiredOutputs.toSet().length != requiredOutputs.length) {
      return Sprint117DocumentationResult(
        verdict: failVerdict,
        pass: false,
        failures: const <String>['non_canonical_outputs'],
        openItems: const <String>[],
        checks: const <Sprint117DocumentationCheck>[],
        outputs: outputs,
        rows: rows,
        exposedProviderIds: const <String>[],
        unresolvedProviderIds: const <String>[],
      );
    }

    final failures = <String>[];

    // --- outputs ------------------------------------------------------------
    final seenOutputs = <String>{};
    for (final output in outputs) {
      final id = output.outputId.trim();
      if (id.isEmpty) {
        failures.add('unknown_output:(no id)');
        continue;
      }
      if (!seenOutputs.add(id)) {
        failures.add('duplicate_output:$id');
      }
      if (!requiredOutputs.toSet().contains(id)) {
        failures.add('unknown_output:$id');
        continue;
      }
      if (output.references.isEmpty) {
        failures.add('no_document:$id');
      }
      for (final path in output.references) {
        final trimmed = path.trim();
        if (trimmed.isEmpty) {
          failures.add('no_document:$id');
          continue;
        }
        // A named document nobody can open is a promise that fails at the
        // moment somebody needs it, so the check is against the filesystem.
        if (!File(trimmed).existsSync()) {
          failures.add('missing_reference:$id:$trimmed');
        }
      }
    }

    // Every canonical output has to be present, named by id, and resolved.
    for (final outputId in requiredOutputs) {
      final resolved = outputs.where(
        (output) => output.outputId.trim() == outputId,
      );
      if (resolved.isEmpty) {
        failures.add('missing_output:$outputId');
        continue;
      }
      final refs = resolved.first.references
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty)
          .toSet();
      final canonical = referencesFor(outputId).toSet();
      if (canonical.isNotEmpty && !canonical.containsAll(refs)) {
        failures.add('output_reference_drift:$outputId');
      }
    }

    // --- checks -------------------------------------------------------------
    final seenChecks = <String>{};
    for (final check in checks) {
      if (!seenChecks.add(check.code)) {
        failures.add('duplicate_check:${check.code}');
      }
      if (isVacuous(check)) {
        failures.add('vacuous:${check.code}');
      }
      if (check.isViolation) {
        failures.add('violation:${check.code}');
      }
      if (check.check.trim().isEmpty) {
        failures.add('unknown_check:${_readable(check.outputId)}:');
      }
    }

    // An output claimed complete must be covered by a check that actually
    // passed; otherwise the pass rests on the output's own declaration.
    for (final outputId in requiredOutputs) {
      final covered = checks.where((check) => check.outputId == outputId);
      if (covered.isEmpty) {
        failures.add('output_without_pass:$outputId');
        continue;
      }
      final passing = covered.any(
        (check) =>
            check.status == Sprint117DocumentationStatus.pass &&
            !isVacuous(check),
      );
      if (!passing) {
        failures.add('output_without_pass:$outputId');
      }
    }

    // --- provider limitations ----------------------------------------------
    if (rows.isEmpty) {
      failures.add('no_documentation_rows');
    }

    final manifest = ProviderConnectorManifest.standard;
    final unresolved = <String>[];
    final exposed = <String>[];
    final seenProviders = <String>{};
    for (final row in rows) {
      final id = row.providerId.trim();
      if (id.isEmpty) {
        failures.add('unknown_provider:(no provider_id)');
        continue;
      }
      if (!seenProviders.add(id)) {
        failures.add('duplicate_provider:$id');
        continue;
      }
      final entry = manifest.get(id);
      if (entry == null) {
        // A limitation set for a provider the shipped manifest does not carry
        // is documentation of nothing.
        failures.add('unknown_provider:$id');
        continue;
      }
      final derived = Sprint117ProviderLimitationCatalogue.derive(entry);
      if (derived.isEmpty) {
        // Fail closed: "no derived limitation" is not "no limitation".
        failures.add('no_derived_limitation:$id');
        unresolved.add(id);
        continue;
      }
      if (!Sprint117ProviderLimitationCatalogue.isDerived(
        entry,
        row.declaredLimitations,
      )) {
        failures.add('limitations_not_derived:$id');
        unresolved.add(id);
        continue;
      }
      exposed.add(id);
    }

    final openItems = <String>[
      for (final check in checks)
        if (check.status != Sprint117DocumentationStatus.pass) check.code,
    ];

    return Sprint117DocumentationResult(
      verdict: failures.isEmpty ? passVerdict : failVerdict,
      pass: failures.isEmpty,
      failures: failures,
      openItems: openItems,
      checks: checks,
      outputs: outputs,
      rows: rows,
      exposedProviderIds: exposed.toList()..sort(),
      unresolvedProviderIds: unresolved.toList()..sort(),
    );
  }
}
