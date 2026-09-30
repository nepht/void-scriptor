/// Canonical step 117.18 — Creative Connector Workflow Validation.
///
/// Objective (external canonical JSON): test certified creative connectors
/// against asset rights, attribution, import/export boundaries, and revoke.
///
/// The six evidence names are the ways a creative connection can over-reach
/// what the user licensed — pull in assets the user has no right to, drop the
/// attribution those rights depend on, or move material across a boundary the
/// grant never covered — so the check and the drill are deliberately separate
/// classes, exactly as 117.5-117.17 did:
///
/// * [Sprint117CreativeConnectorWorkflowDrill] really executes the shipped
///   mechanisms in [AccountCenterCreativeToolsConnections] and
///   [AccountCenterDeveloperToolsConnections]: connect/disconnect, the
///   asset-permission and attribution rule, the transfer scope stored on a
///   connection, the sensitive-action gate, and the audit trail behind them. It
///   writes nothing, opens no user project, contacts no provider, and every
///   provider it names is a locally built manifest, never a certification claim.
/// * [Sprint117CreativeConnectorWorkflowLoader] reads the committed manifests
///   and the external files they pin, and never invents a check or an outcome.
/// * [Sprint117CreativeConnectorWorkflowGate] decides whether the recorded
///   evidence is coherent, synchronously and without side effects.
///
/// Three facts are measured rather than assumed, and all three shape the
/// verdict:
///
/// 1. This step found and fixed a real defect in shipped code. Ending a
///    creative connection was gated only by a caller-supplied `confirmed`
///    boolean and recorded no trail at all, so any caller could drop a
///    connection carrying licensed assets and attribution obligations, and a
///    refusal was indistinguishable from an attempt never made. The spec lists
///    `disconnect_provider` among its sensitive actions and declares
///    `reauth_before_sensitive_action` and `audit_redaction`; the seam honoured
///    none of the three. The drill re-measures all of it, so a regression in
///    either direction fails here.
/// 2. `import` and `export` are stored on the connection and enforced
///    nowhere: no shipped code reads `transferScope` to decide whether a given
///    transfer is allowed. The drill measures that the declaration is carried
///    and immutable, and reports the missing enforcement as an open item
///    instead of dressing a stored enum up as a boundary.
/// 3. No shipped screen drives either manager. The drill exercises the shipped
///    domain rather than a user-visible flow, and that is recorded as an open
///    item instead of being folded into a passing claim of integration.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:void_scriptor/features/account/domain/account_center_creative_tools_connections.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';

part 'sprint_117_creative_connector_workflow_drill.dart';

enum Sprint117CreativeConnectorWorkflowState { pass, fail, blocked }

/// Immutable description of the contract, its sources, and its verdicts.
abstract final class Sprint117CreativeConnectorWorkflowContract {
  static const String canonicalStep = '117.18';

  /// 115.29 supplies the creative connection seam, its asset permissions, the
  /// import/export scope, attribution, and disconnect.
  static const String creativeTools =
      'docs/planning/v1.2/sprint_115_creative_tools_connections.json';

  /// 116.35 supplies the rights record every imported or exported asset has to
  /// carry: source, license, attribution, usage rights, export rights,
  /// retention.
  static const String assetRights =
      'docs/planning/v1.2/sprint_116_creative_asset_rights_verification.json';

  /// 116.32 supplies the per-provider creative certification record, which is
  /// where asset_import_export and attribution are named for a connector.
  static const String figmaCertification =
      'docs/planning/v1.2/sprint_116_figma_certification.json';

  /// 116.34 supplies the Blender Cloud / Sketchfab record, where asset rights
  /// and download/upload scopes appear instead.
  static const String blenderSketchfabCertification =
      'docs/planning/v1.2/sprint_116_blender_sketchfab_certification.json';

  /// Every committed source this validation decides from.
  static const List<String> sourceManifests = <String>[
    creativeTools,
    assetRights,
    figmaCertification,
    blenderSketchfabCertification,
  ];

  /// The external files the committed manifests pin, with the sha256 they
  /// record. A pin that no longer matches is a contradiction of every decision
  /// derived from it, so it is measured, never assumed.
  static const Map<String, String> externalPins = <String, String>{
    'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
            'sprint_116.json':
        '94418211f73b9b318d57749a26bf8e6f1e92afb6c8942b2b003c99d6cef0e809',
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
            'referenced-chatgpt-conversation-this-is-an-2/outputs/'
            'account_cloud_center_spec.json':
        'f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a',
  };

  static const String passVerdict =
      'CREATIVE_CONNECTOR_WORKFLOW_VALIDATED_LOCAL';
  static const String blockedVerdict =
      'CREATIVE_CONNECTOR_WORKFLOW_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'CREATIVE_CONNECTOR_WORKFLOW_INCONSISTENT';

  /// The six evidence items canonical step 117.18 names, in canonical order.
  static const List<String> requiredChecks = <String>[
    'asset_access',
    'rights',
    'attribution',
    'import',
    'export',
    'revoke',
  ];
}

/// One canonical check, the method that exercises it, and its outcome.
class Sprint117CreativeConnectorWorkflowCheck {
  Sprint117CreativeConnectorWorkflowCheck({
    required this.checkId,
    required this.method,
    required this.expectedOutcome,
    required this.observedOutcome,
    required this.sourceManifest,
    required this.liveProviderResult,
    required this.drilledAgainstLiveProvider,
  });

  /// The canonical check identity, e.g. `revoke`.
  final String checkId;

  /// The step this validation runs. Empty means the check only wishes for it.
  final String method;

  /// What the method is expected to produce locally.
  final String expectedOutcome;

  /// What the local drill actually produced. Null while no drill has run.
  final String? observedOutcome;

  /// The upstream manifest that defines this check.
  final String sourceManifest;

  /// Whether a live provider produced this outcome. It never has.
  final bool liveProviderResult;

  /// Whether the check ran against a live provider. It never did.
  final bool drilledAgainstLiveProvider;

  bool get executed =>
      observedOutcome != null && observedOutcome!.trim().isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'check_id': checkId,
    'method': method,
    'expected_outcome': expectedOutcome,
    'observed_outcome': observedOutcome,
    'executed': executed,
    'source_manifest': sourceManifest,
    'live_provider_result': liveProviderResult,
    'drilled_against_live_provider': drilledAgainstLiveProvider,
  };
}

/// The evidence this validation is allowed to decide from.
class Sprint117CreativeConnectorWorkflowAnchor {
  Sprint117CreativeConnectorWorkflowAnchor({
    required Map<String, String> declaredContractSizes,
    required Map<String, bool> boundariesDeclared,
    required Map<String, int> rightsRecordsDeclared,
    required this.creativeAcceptanceDeclared,
    required this.assetRightsFieldsDeclared,
    required this.importExportAndAttributionDeclared,
    required this.reauthBeforeSensitiveActionDeclared,
    required this.disconnectProviderSensitiveAction,
    required this.auditRedactionDeclared,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
  }) : declaredContractSizes = Map<String, String>.unmodifiable(
         declaredContractSizes,
       ),
       boundariesDeclared = Map<String, bool>.unmodifiable(boundariesDeclared),
       rightsRecordsDeclared = Map<String, int>.unmodifiable(
         rightsRecordsDeclared,
       );

  /// How many contract items each committed source declares, by path.
  final Map<String, String> declaredContractSizes;

  /// Whether each committed source states where its own evidence stops.
  final Map<String, bool> boundariesDeclared;

  /// How many rights records each certification source carries, by path.
  final Map<String, int> rightsRecordsDeclared;

  /// Whether 115.29 declares the rights, boundary, and attribution items.
  final bool creativeAcceptanceDeclared;

  /// Whether 116.35 declares every rights field an asset must carry.
  final bool assetRightsFieldsDeclared;

  /// Whether a certification record names import/export boundaries and
  /// attribution, the two items 116.32 and 116.34 spell differently.
  final bool importExportAndAttributionDeclared;

  /// Whether the product spec declares reauth before a sensitive action.
  final bool reauthBeforeSensitiveActionDeclared;

  /// Whether the product spec calls disconnecting a provider a sensitive
  /// action.
  final bool disconnectProviderSensitiveAction;

  /// Whether the product spec declares audit redaction.
  final bool auditRedactionDeclared;

  final int externalPinsMatched;
  final int externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117CreativeConnectorWorkflowContract.externalPins.length;

  bool get allExternalPinsMatch =>
      externalPinsResolved && externalPinsMatched == externalPinsChecked;
}

/// The decided-versus-observed input the gate reasons about.
class Sprint117CreativeConnectorWorkflowInput {
  const Sprint117CreativeConnectorWorkflowInput({
    this.rows,
    this.anchor,
    this.drillRun,
    this.externalPinDrift = false,
  });

  final List<Sprint117CreativeConnectorWorkflowCheck>? rows;
  final Sprint117CreativeConnectorWorkflowAnchor? anchor;
  final Sprint117CreativeConnectorWorkflowDrillRun? drillRun;

  /// Whether an external pin no longer matches what its manifest recorded.
  final bool externalPinDrift;
}

/// Whether a canonical acceptance could be satisfied by shipped code at all.
enum Sprint117CreativeConnectorWorkflowAcceptance { satisfied, mechanismAbsent }

/// One measured local observation behind a canonical check.
class Sprint117CreativeConnectorWorkflowObservation {
  Sprint117CreativeConnectorWorkflowObservation({
    required this.checkId,
    required this.outcome,
    required this.facts,
    required this.passed,
    this.acceptance = Sprint117CreativeConnectorWorkflowAcceptance.satisfied,
    this.unresolvable = const <String>[],
  });

  /// The canonical check this observation decides.
  final String checkId;

  /// Exactly what the executed method produced.
  final String outcome;

  /// The measured values behind [outcome]. Never a restatement of the prose.
  final Map<String, Object?> facts;

  /// Whether the shipped mechanism behaved as the canonical source requires.
  final bool passed;

  /// Whether shipped code can satisfy this acceptance at all.
  final Sprint117CreativeConnectorWorkflowAcceptance acceptance;

  /// References this validation could not resolve, reported rather than
  /// silently dropped.
  final List<String> unresolvable;

  Map<String, Object?> toJson() => <String, Object?>{
    'check_id': checkId,
    'outcome': outcome,
    'passed': passed,
    'acceptance': acceptance.name,
    'facts': Map<String, Object?>.from(facts),
    'unresolvable': List<String>.from(unresolvable),
  };
}

/// Everything one measured run produced.
class Sprint117CreativeConnectorWorkflowDrillRun {
  Sprint117CreativeConnectorWorkflowDrillRun({
    required List<Sprint117CreativeConnectorWorkflowObservation> observations,
    required this.liveProviderTouched,
    required this.userProjectTouched,
    required this.liveCredentialObserved,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
    this.productionCallerPresent = true,
    this.transferScopeEnforcedSomewhere = true,
  }) : observations =
           List<Sprint117CreativeConnectorWorkflowObservation>.unmodifiable(
             observations,
           );

  final List<Sprint117CreativeConnectorWorkflowObservation> observations;

  /// Whether any provider endpoint or OS vault was contacted. It never is.
  final bool liveProviderTouched;

  /// Whether any user project was opened. It never is.
  final bool userProjectTouched;

  /// Whether any real credential was observed. It never is.
  final bool liveCredentialObserved;

  final int externalPinsMatched;
  final int externalPinsChecked;

  /// Whether any production file outside this acceptance harness imports the
  /// connector mechanisms the checks above exercise.
  ///
  /// Defaults to true so a hand-built run is never charged with an integration
  /// gap it never measured; only the repository scan can clear it.
  final bool productionCallerPresent;

  /// Whether any shipped file outside the manager that stores it reads a
  /// creative transfer scope to decide whether a transfer is allowed.
  ///
  /// Defaults to true for the same reason: an unmeasured run must not be
  /// charged with a missing enforcement it never looked for.
  final bool transferScopeEnforcedSomewhere;

  bool get allPassed => observations.every((entry) => entry.passed);

  bool get allExternalPinsMatchForDrill =>
      externalPinsChecked > 0 && externalPinsMatched == externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117CreativeConnectorWorkflowContract.externalPins.length;

  List<String> get acceptanceSatisfied => <String>[
    for (final entry in observations)
      if (entry.acceptance ==
          Sprint117CreativeConnectorWorkflowAcceptance.satisfied)
        entry.checkId,
  ];

  List<String> get acceptanceUnmet => <String>[
    for (final entry in observations)
      if (entry.acceptance ==
          Sprint117CreativeConnectorWorkflowAcceptance.mechanismAbsent)
        entry.checkId,
  ];

  List<String> get unresolvableReferences => <String>[
    for (final entry in observations) ...entry.unresolvable,
  ];

  Sprint117CreativeConnectorWorkflowObservation? observationFor(
    String checkId,
  ) {
    for (final entry in observations) {
      if (entry.checkId == checkId) return entry;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'live_provider_touched': liveProviderTouched,
    'user_project_touched': userProjectTouched,
    'live_credential_observed': liveCredentialObserved,
    'external_pins_matched': externalPinsMatched,
    'external_pins_checked': externalPinsChecked,
    'production_caller_present': productionCallerPresent,
    'transfer_scope_enforced_somewhere': transferScopeEnforcedSomewhere,
    'observations': <Map<String, Object?>>[
      for (final entry in observations) entry.toJson(),
    ],
  };
}

/// Reads the committed manifests and never invents a subject.
class Sprint117CreativeConnectorWorkflowLoader {
  const Sprint117CreativeConnectorWorkflowLoader();

  Sprint117CreativeConnectorWorkflowInput load() =>
      Sprint117CreativeConnectorWorkflowInput(
        rows: _loadRows(),
        anchor: _loadAnchor(),
      );

  /// Folds the measured drill into the committed record.
  Sprint117CreativeConnectorWorkflowInput loadWithDrill(
    Sprint117CreativeConnectorWorkflowDrillRun run,
  ) => Sprint117CreativeConnectorWorkflowInput(
    rows: _loadRows(run),
    anchor: _loadAnchor(),
    drillRun: run,
    // A run that could not read every pin cannot prove drift either; only a
    // readable pin that no longer matches is a contradiction.
    externalPinDrift:
        run.externalPinsResolved && !run.allExternalPinsMatchForDrill,
  );

  Sprint117CreativeConnectorWorkflowAnchor? _loadAnchor() {
    final declared = <String, String>{};
    final boundaries = <String, bool>{};
    final rightsRecords = <String, int>{};
    for (final path
        in Sprint117CreativeConnectorWorkflowContract.sourceManifests) {
      final source = _readJsonFile(path);
      if (source == null) return null;
      declared[path] = _declaredContractSize(source);
      boundaries[path] = _declaresBoundary(source);
      rightsRecords[path] = _rightsRecordCount(source);
    }

    // The guarantees themselves live in the external product spec, which the
    // committed manifests point at rather than embed. Reading
    // `security_contract` out of a manifest instead of out of the spec it pins
    // yields nothing, which would silently leave every guarantee unmeasured.
    final spec = _readJsonFile(
      Sprint117CreativeConnectorWorkflowContract.externalPins.keys.last,
    );
    if (spec == null) return null;
    final secrets = spec['security_contract']?['secrets'];
    final sensitive = spec['security_contract']?['sensitive_actions'];

    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117CreativeConnectorWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }

    return Sprint117CreativeConnectorWorkflowAnchor(
      declaredContractSizes: declared,
      boundariesDeclared: boundaries,
      rightsRecordsDeclared: rightsRecords,
      creativeAcceptanceDeclared: _declares(
        Sprint117CreativeConnectorWorkflowContract.creativeTools,
        <String>[
          'asset_permissions',
          'import_export_scope',
          'disconnect',
          'attribution',
        ],
      ),
      assetRightsFieldsDeclared: _declares(
        Sprint117CreativeConnectorWorkflowContract.assetRights,
        <String>[
          'source',
          'license',
          'attribution',
          'usage_rights',
          'export_rights',
          'retention',
        ],
      ),
      // 116.32 spells the boundary `asset_import_export` and 116.34 spells it
      // `download_scopes`/`upload_scopes`; both name `attribution`. A check
      // that demanded one exact spelling would report the other source as
      // silent, which is a false zero rather than a measured gap.
      importExportAndAttributionDeclared:
          _declares(
            Sprint117CreativeConnectorWorkflowContract.figmaCertification,
            <String>['asset_import_export', 'attribution'],
          ) ||
          _declares(
            Sprint117CreativeConnectorWorkflowContract
                .blenderSketchfabCertification,
            <String>['asset_rights', 'attribution'],
          ),
      reauthBeforeSensitiveActionDeclared:
          secrets is List && secrets.contains('reauth_before_sensitive_action'),
      disconnectProviderSensitiveAction:
          sensitive is List && sensitive.contains('disconnect_provider'),
      auditRedactionDeclared:
          secrets is List && secrets.contains('audit_redaction'),
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }

  /// Whether the committed source at [path] declares every item in [items].
  ///
  /// Measured by reading the source's own `required_fields` or `acceptance`
  /// list, not by comparing against a copy of that list written here. A
  /// constant list would be the same defect 117.16 rejected: it makes the
  /// guarantee look declared by something that never looked at the file.
  static bool _declares(String path, List<String> items) {
    final source = _readJsonFile(path);
    if (source == null) return false;
    for (final key in const <String>['required_fields', 'acceptance']) {
      final declared = source[key];
      if (declared is! List<dynamic>) continue;
      final names = declared.map((entry) => entry.toString()).toSet();
      if (items.every(names.contains)) return true;
    }
    return false;
  }

  List<Sprint117CreativeConnectorWorkflowCheck>? _loadRows([
    Sprint117CreativeConnectorWorkflowDrillRun? run,
  ]) {
    if (_loadAnchor() == null) return null;
    return <Sprint117CreativeConnectorWorkflowCheck>[
      for (final checkId
          in Sprint117CreativeConnectorWorkflowContract.requiredChecks)
        if (_defined(checkId))
          Sprint117CreativeConnectorWorkflowCheck(
            checkId: checkId,
            method: _method(checkId),
            expectedOutcome: _expectedOutcome(checkId),
            // Only the measured drill may supply an outcome. With no drill the
            // check stays undetermined rather than borrowing a verdict.
            observedOutcome: run?.observationFor(checkId)?.outcome,
            sourceManifest: _sourceFor(checkId),
            liveProviderResult: false,
            drilledAgainstLiveProvider: false,
          ),
    ];
  }

  /// A check exists only where its source records a contract, so a manifest
  /// that never declared the item cannot silently produce a passing row.
  static bool _defined(String checkId) {
    final source = _readJsonFile(_sourceFor(checkId));
    if (source == null) return false;
    return _declaredContractSize(source).isNotEmpty;
  }

  /// The committed manifest that owns a check.
  static String _sourceFor(String checkId) => switch (checkId) {
    'asset_access' ||
    'attribution' => Sprint117CreativeConnectorWorkflowContract.creativeTools,
    'rights' => Sprint117CreativeConnectorWorkflowContract.assetRights,
    'import' ||
    'export' => Sprint117CreativeConnectorWorkflowContract.figmaCertification,
    'revoke' =>
      Sprint117CreativeConnectorWorkflowContract.blenderSketchfabCertification,
    _ => '',
  };

  /// The step this validation runs for a check.
  static String _method(String checkId) => switch (checkId) {
    'asset_access' =>
      'connect with owned, licensed, and public-domain permissions and record '
          'that the stored set is deduplicated, immutable, and never empty, '
          'and that a connector the manifest marks unavailable is refused',
    'rights' =>
      'read the committed 116.35 rights records and record that every field an '
          'imported or exported asset must carry is declared, that each record '
          'is still UNVERIFIED, and that no record claims a live license',
    'attribution' =>
      'connect with and without attribution and record that licensed assets '
          'are refused without it, that blank attribution is treated as absent, '
          'and that the stored text is preserved verbatim afterwards',
    'import' =>
      'connect under each transfer scope and record that the declared scope is '
          'carried on the connection and cannot be widened or narrowed '
          'afterwards, and record that no shipped file reads it to decide a '
          'transfer',
    'export' =>
      'connect under each transfer scope and record that an export-only grant '
          'is distinguishable from an import-only one, that the two are never '
          'collapsed into a single "both" value, and that the scope survives a '
          'disconnect decision',
    'revoke' =>
      'end a creative connection and record that it is refused when the '
          'reauthentication gate refuses, that it is refused when no gate is '
          'supplied at all, that a refused attempt leaves the connection and '
          'its attribution intact, and that the refusal is audited',
    _ => '',
  };

  /// What the method is expected to produce locally.
  static String _expectedOutcome(String checkId) => switch (checkId) {
    'asset_access' =>
      'a connection carries exactly the permissions it was granted and cannot '
          'be widened, narrowed, or emptied afterwards',
    'rights' =>
      'every asset rights record declares source, license, attribution, usage '
          'rights, export rights, and retention, and none claims a live license',
    'attribution' =>
      'licensed assets cannot be connected without attribution, and the stored '
          'attribution is preserved exactly as given',
    'import' =>
      'a transfer scope is carried on the connection and cannot be changed '
          'afterwards',
    'export' =>
      'import-only, export-only, and import-export grants stay distinct and '
          'are never collapsed',
    'revoke' =>
      'ending a creative connection requires the gate and is audited either '
          'way, leaving the connection and its rights intact on refusal',
    _ => '',
  };

  /// How many contract items a source declares, or empty when it declares none.
  static String _declaredContractSize(Map<String, dynamic> source) {
    for (final key in const <String>[
      'acceptance',
      'required_fields',
      'required_states',
      'required_outputs',
    ]) {
      final declared = source[key];
      if (declared is List<dynamic> && declared.isNotEmpty) {
        return 'DECLARED:$key:${declared.length}';
      }
      if (declared is Map<String, dynamic> && declared.isNotEmpty) {
        return 'DECLARED:$key:${declared.length}';
      }
    }
    final records = source['records'];
    if (records is List<dynamic> && records.isNotEmpty) {
      return 'DECLARED:records:${records.length}';
    }
    return '';
  }

  /// Whether a source states where its own evidence stops.
  static bool _declaresBoundary(Map<String, dynamic> source) {
    for (final key in const <String>[
      'boundary',
      'evidence_boundary',
      'external_gates',
    ]) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) return true;
    }
    for (final key in const <String>[
      'limitations',
      'deferred_scope',
      'deferred_external',
    ]) {
      final value = source[key];
      if (value is List<dynamic> && value.isNotEmpty) return true;
      if (value is Map<String, dynamic> && value.isNotEmpty) return true;
    }
    return false;
  }

  /// How many rights records a certification source carries.
  static int _rightsRecordCount(Map<String, dynamic> source) {
    final records = source['records'];
    return records is List<dynamic> ? records.length : 0;
  }
}

/// Decides whether the recorded creative connector evidence is coherent.
class Sprint117CreativeConnectorWorkflowGate {
  const Sprint117CreativeConnectorWorkflowGate();

  /// Runs the drill, then decides from its measured output.
  Future<Sprint117CreativeConnectorWorkflowReport> evaluateWithDrill([
    Sprint117CreativeConnectorWorkflowDrillRun? run,
  ]) async {
    final measured =
        run ?? await const Sprint117CreativeConnectorWorkflowDrill().run();
    return evaluateWith(
      const Sprint117CreativeConnectorWorkflowLoader().loadWithDrill(measured),
    );
  }

  Sprint117CreativeConnectorWorkflowReport evaluate() =>
      evaluateWith(const Sprint117CreativeConnectorWorkflowLoader().load());

  Sprint117CreativeConnectorWorkflowReport evaluateWith(
    Sprint117CreativeConnectorWorkflowInput input,
  ) {
    final missing = <String>{};
    final violations = <String>{};

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('creative_connector_anchor');
    } else {
      for (final entry in anchor.declaredContractSizes.entries) {
        if (entry.value.trim().isEmpty) {
          missing.add('contract_not_declared:${entry.key}');
        }
      }
      for (final entry in anchor.boundariesDeclared.entries) {
        if (!entry.value) {
          violations.add('external_boundary_not_declared:${entry.key}');
        }
      }
      // Only the certification sources promise rights *records*; the 115.29
      // contract manifest promises an acceptance list, and demanding records
      // of it would be a false zero of the same kind 117.17 removed — a gap
      // measured against a contract that never promised the thing.
      for (final path in <String>[
        Sprint117CreativeConnectorWorkflowContract.assetRights,
        Sprint117CreativeConnectorWorkflowContract.figmaCertification,
        Sprint117CreativeConnectorWorkflowContract
            .blenderSketchfabCertification,
      ]) {
        if ((anchor.rightsRecordsDeclared[path] ?? 0) == 0) {
          missing.add('rights_record_absent:$path');
        }
      }
      if (!anchor.creativeAcceptanceDeclared) {
        missing.add('creative_rights_boundary_and_attribution_acceptance');
      }
      if (!anchor.assetRightsFieldsDeclared) {
        missing.add('asset_rights_fields');
      }
      if (!anchor.importExportAndAttributionDeclared) {
        missing.add('import_export_and_attribution_fields');
      }
      if (!anchor.reauthBeforeSensitiveActionDeclared) {
        missing.add('reauth_before_sensitive_action_acceptance');
      }
      if (!anchor.disconnectProviderSensitiveAction) {
        missing.add('disconnect_provider_sensitive_action');
      }
      if (!anchor.auditRedactionDeclared) {
        missing.add('audit_redaction_acceptance');
      }
      if (!anchor.externalPinsResolved) {
        missing.add('external_pin_unreadable');
      } else if (!anchor.allExternalPinsMatch) {
        violations.add('external_source_drift');
      }
    }

    // An external file whose hash no longer matches the committed pin
    // contradicts every decision derived from it, whether the loader saw it
    // or only the drill did.
    if (input.externalPinDrift) violations.add('external_source_drift');

    final drillRun = input.drillRun;
    if (drillRun == null) {
      // Without a measured run there is no observed outcome to decide from, so
      // the report is blocked rather than passed on prose.
      missing.add('drill_run');
    } else {
      if (drillRun.liveProviderTouched) violations.add('live_provider_touched');
      if (drillRun.userProjectTouched) violations.add('user_project_touched');
      if (drillRun.liveCredentialObserved) {
        violations.add('live_credential_observed');
      }
      if (drillRun.externalPinsResolved &&
          !drillRun.allExternalPinsMatchForDrill) {
        violations.add('external_source_drift');
      }
      if (!drillRun.allPassed) {
        for (final observation in drillRun.observations) {
          if (!observation.passed) {
            violations.add('drill_observation_failed:${observation.checkId}');
            violations.add('drill_outcome:${observation.outcome}');
          }
        }
      }
      // A check whose own recorded fact says the mechanism is absent must not
      // also be reported as acceptance-satisfied: the two claims contradict.
      for (final observation in drillRun.observations) {
        if (!observation.passed) continue;
        final acceptance = observation.facts['acceptance_mechanism_present'];
        if (acceptance == false &&
            observation.acceptance ==
                Sprint117CreativeConnectorWorkflowAcceptance.satisfied) {
          violations.add(
            'acceptance_claimed_without_mechanism:${observation.checkId}',
          );
        }
      }
    }

    final rows = input.rows;
    final rowIds = <String>{};
    final checks = <Sprint117CreativeConnectorWorkflowCheck>[];
    final undetermined = <String>[];

    if (rows == null || rows.isEmpty) {
      missing.add('check_rows');
    } else {
      for (final row in rows) {
        final checkId = row.checkId.trim();
        if (checkId.isEmpty) {
          violations.add('check_id_blank');
          continue;
        }
        if (!rowIds.add(checkId)) {
          violations.add('check_duplicate:$checkId');
          continue;
        }
        checks.add(row);
        _checkCheck(row, drillRun, missing, violations);
        if (!row.executed) {
          undetermined.add(checkId);
          if (drillRun != null) {
            missing.add('check_observed_outcome:$checkId');
          }
        }
      }
    }

    final unmapped = <String>[];
    if (anchor != null && !missing.contains('creative_connector_anchor')) {
      for (final checkId
          in Sprint117CreativeConnectorWorkflowContract.requiredChecks) {
        if (!rowIds.contains(checkId)) unmapped.add(checkId);
      }
      for (final checkId in unmapped) {
        violations.add('check_unmapped:$checkId');
      }
    }

    // Coverage counts canonical checks the evidence has actually decided, not
    // rows a manifest happened to declare. Without an anchor nothing is bound
    // to a committed source, so nothing counts as decided however green the
    // rows look: a full-coverage report would otherwise be reachable while the
    // evidence it claims to rest on is unreadable.
    final anchorResolved =
        anchor != null && !missing.contains('creative_connector_anchor');
    var decidedCount = 0;
    for (final row in checks) {
      if (row.executed && anchorResolved) decidedCount += 1;
    }
    final total =
        Sprint117CreativeConnectorWorkflowContract.requiredChecks.length;
    final coverage = total == 0 ? 0.0 : decidedCount / total;

    final complete = missing.isEmpty && violations.isEmpty;
    final state = violations.isNotEmpty
        ? Sprint117CreativeConnectorWorkflowState.fail
        : (complete
              ? Sprint117CreativeConnectorWorkflowState.pass
              : Sprint117CreativeConnectorWorkflowState.blocked);

    return Sprint117CreativeConnectorWorkflowReport(
      status: state,
      verdict: switch (state) {
        Sprint117CreativeConnectorWorkflowState.pass =>
          Sprint117CreativeConnectorWorkflowContract.passVerdict,
        Sprint117CreativeConnectorWorkflowState.fail =>
          Sprint117CreativeConnectorWorkflowContract.failVerdict,
        Sprint117CreativeConnectorWorkflowState.blocked =>
          Sprint117CreativeConnectorWorkflowContract.blockedVerdict,
      },
      missingFields: missing.toList(growable: false)..sort(),
      violations: violations.toList(growable: false)..sort(),
      unmappedChecks: unmapped.toList(growable: false)..sort(),
      undeterminedChecks: undetermined.toList(growable: false)..sort(),
      coverage: coverage,
      acceptanceSatisfied: List<String>.of(
        drillRun?.acceptanceSatisfied ?? const <String>[],
      )..sort(),
      acceptanceUnmet: List<String>.of(
        drillRun?.acceptanceUnmet ?? const <String>[],
      )..sort(),
      checks: checks,
      anchor: anchor,
      openItems: _openItems(drillRun, undetermined),
    );
  }

  void _checkCheck(
    Sprint117CreativeConnectorWorkflowCheck row,
    Sprint117CreativeConnectorWorkflowDrillRun? drillRun,
    Set<String> missing,
    Set<String> violations,
  ) {
    final checkId = row.checkId.trim();
    if (row.method.trim().isEmpty) missing.add('check_method:$checkId');
    if (row.expectedOutcome.trim().isEmpty) {
      missing.add('check_expected_outcome:$checkId');
    }
    if (row.sourceManifest.trim().isEmpty) {
      missing.add('check_source_manifest:$checkId');
    } else if (!File(row.sourceManifest).existsSync()) {
      missing.add('check_source_manifest_missing:$checkId');
    }
    if (row.liveProviderResult) violations.add('live_provider_claim:$checkId');
    if (row.drilledAgainstLiveProvider) {
      violations.add('live_provider_claim:$checkId');
    }
    if (row.observedOutcome == null) {
      // Nothing has run, so the check stays undetermined — an open item, never
      // a violation this gate invents an observation for.
      return;
    }
    final measured = drillRun?.observationFor(checkId);
    if (measured == null) {
      violations.add('check_observation_unsourced:$checkId');
    } else if (row.observedOutcome != measured.outcome) {
      violations.add('check_outcome_contradicts_drill:$checkId');
      violations.add('recorded_outcome:${row.observedOutcome}');
      violations.add('measured_outcome:${measured.outcome}');
    }
  }

  List<String> _openItems(
    Sprint117CreativeConnectorWorkflowDrillRun? drillRun,
    List<String> undetermined,
  ) {
    final items = <String>{
      for (final checkId in undetermined)
        'check_observed_outcome_null:$checkId',
      for (final checkId in drillRun?.acceptanceUnmet ?? const <String>[])
        'check_acceptance_unmet:$checkId',
      for (final reference
          in drillRun?.unresolvableReferences ?? const <String>[])
        'unresolvable_reference:$reference',
      // Measured, not asserted: no file under `lib/` outside the acceptance
      // harness imports the creative connector manager, so every check above
      // exercises code no user path reaches. The mechanisms are declared and
      // correct; they are simply not wired to anything yet. A run without a
      // drill measured nothing, so it claims nothing.
      if (drillRun != null && !drillRun.productionCallerPresent)
        'no_shipped_consumer_for_creative_connector_manager',
      // Measured: `transferScope` is stored on a creative connection but no
      // shipped file outside the manager that writes it ever reads it, so the
      // declared import/export boundary is a declaration with no enforcement
      // behind it. Reporting it as an open item keeps a stored enum from being
      // read as a working boundary.
      if (drillRun != null && !drillRun.transferScopeEnforcedSomewhere)
        'transfer_scope_declared_but_never_enforced_by_shipped_code',
      'creative_connector_workflow_defined_not_executed_live',
      'external_connector_specs_outside_repository',
    };
    return items.toList(growable: false)..sort();
  }
}

/// The gate's verdict, with the evidence it decided from.
class Sprint117CreativeConnectorWorkflowReport {
  Sprint117CreativeConnectorWorkflowReport({
    required this.status,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required List<String> unmappedChecks,
    required List<String> undeterminedChecks,
    required this.coverage,
    required List<String> acceptanceSatisfied,
    required List<String> acceptanceUnmet,
    required List<Sprint117CreativeConnectorWorkflowCheck> checks,
    required this.anchor,
    required List<String> openItems,
  }) : acceptanceSatisfied = List<String>.unmodifiable(acceptanceSatisfied),
       acceptanceUnmet = List<String>.unmodifiable(acceptanceUnmet),
       missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       unmappedChecks = List<String>.unmodifiable(unmappedChecks),
       undeterminedChecks = List<String>.unmodifiable(undeterminedChecks),
       checks = List<Sprint117CreativeConnectorWorkflowCheck>.unmodifiable(
         checks,
       ),
       openItems = List<String>.unmodifiable(openItems);

  final Sprint117CreativeConnectorWorkflowState status;

  /// The decision this report carries.
  final String verdict;

  final List<String> missingFields;
  final List<String> violations;
  final List<String> unmappedChecks;

  /// Checks that are defined but that no drill has decided yet.
  final List<String> undeterminedChecks;

  /// Fraction of the canonical checks the evidence decided.
  final double coverage;

  /// Canonical acceptances shipped code satisfies.
  final List<String> acceptanceSatisfied;

  /// Canonical acceptances shipped code cannot satisfy, reported rather than
  /// folded into a passing row.
  final List<String> acceptanceUnmet;

  final List<Sprint117CreativeConnectorWorkflowCheck> checks;
  final Sprint117CreativeConnectorWorkflowAnchor? anchor;

  /// What this report leaves open, including every deferred external gate.
  final List<String> openItems;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117CreativeConnectorWorkflowContract.canonicalStep,
    'status': status.name,
    'verdict': verdict,
    'coverage': coverage,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'unmapped_checks': List<String>.from(unmappedChecks),
    'undetermined_checks': List<String>.from(undeterminedChecks),
    'acceptance_satisfied': List<String>.from(acceptanceSatisfied),
    'acceptance_unmet': List<String>.from(acceptanceUnmet),
    'open_items': List<String>.from(openItems),
    'checks': <Map<String, Object?>>[
      for (final entry in checks) entry.toJson(),
    ],
    'anchor': anchor == null
        ? null
        : <String, Object?>{
            'declared_contract_sizes': Map<String, String>.from(
              anchor!.declaredContractSizes,
            ),
            'boundaries_declared': Map<String, bool>.from(
              anchor!.boundariesDeclared,
            ),
            'rights_records_declared': Map<String, int>.from(
              anchor!.rightsRecordsDeclared,
            ),
            'creative_acceptance_declared': anchor!.creativeAcceptanceDeclared,
            'asset_rights_fields_declared': anchor!.assetRightsFieldsDeclared,
            'import_export_and_attribution_declared':
                anchor!.importExportAndAttributionDeclared,
            'reauth_before_sensitive_action_declared':
                anchor!.reauthBeforeSensitiveActionDeclared,
            'disconnect_provider_sensitive_action':
                anchor!.disconnectProviderSensitiveAction,
            'audit_redaction_declared': anchor!.auditRedactionDeclared,
            'external_pins_matched': anchor!.externalPinsMatched,
            'external_pins_checked': anchor!.externalPinsChecked,
          },
  };
}

Map<String, dynamic>? _readJsonFile(String path) {
  if (path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

String? _sha256OfFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    return sha256.convert(file.readAsBytesSync()).toString();
  } on FileSystemException {
    return null;
  }
}
