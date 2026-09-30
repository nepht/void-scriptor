/// Canonical step 117.17 — Developer Connector Workflow Validation.
///
/// Objective (external canonical JSON): test certified developer connectors
/// against scopes, organizations/workspaces, rate limits, revoke, and audit.
///
/// The six evidence names are the ways an authorized repository connection can
/// be over-granted, silently expired, or left behind after the user ended it,
/// so the check and the drill are deliberately separate classes, exactly as
/// 117.5-117.16 did:
///
/// * [Sprint117DeveloperConnectorWorkflowDrill] really executes the shipped
///   mechanisms: [AccountCenterDeveloperToolsConnections] connect/disconnect,
///   scope normalization and the repository-access/scopes consistency rule,
///   [AccountConnectedAccountsManagement.reauthenticate] and
///   `recordHealthCheck`, and [AccountConnectionHealthStateMachine]
///   refresh/revoke transitions. It writes nothing, opens no user project,
///   contacts no provider, and every provider it names is a locally built
///   manifest, never a certification claim.
/// * [Sprint117DeveloperConnectorWorkflowLoader] reads the committed manifests
///   and the external file they pin, and never invents a check or an outcome.
/// * [Sprint117DeveloperConnectorWorkflowGate] decides whether the recorded
///   evidence is coherent, synchronously and without side effects.
///
/// Two facts are measured rather than assumed, and both shape the verdict:
///
/// 1. This step found and fixed two real defects in shipped code. Ending a
///    developer connection was gated only by a caller-supplied `confirmed`
///    boolean, so any caller could drop an authorized connection by passing
///    `true` even though the product spec lists `disconnect_provider` as a
///    sensitive action and declares `reauth_before_sensitive_action`; and a
///    refused disconnect left no audit row, so a sensitive action that was
///    refused and one that was never attempted looked identical. Separately,
///    a recorded health observation never cleared a pending reauthentication
///    request, so a connection that demonstrably worked kept asking the user
///    to reauthenticate. The drill re-measures all three, so a regression in
///    either direction fails here.
/// 2. No shipped screen drives either manager. The drill exercises the shipped
///    domain rather than a user-visible flow, and that is recorded as an open
///    item instead of being folded into a passing claim of integration.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:void_scriptor/features/account/domain/account_center_connected_accounts_management.dart';
import 'package:void_scriptor/features/account/domain/account_center_connection_health_state_machine.dart';
import 'package:void_scriptor/features/account/domain/account_center_developer_tools_connections.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';

part 'sprint_117_developer_connector_workflow_drill.dart';

enum Sprint117DeveloperConnectorWorkflowState { pass, fail, blocked }

/// Immutable description of the contract, its sources, and its verdicts.
abstract final class Sprint117DeveloperConnectorWorkflowContract {
  static const String canonicalStep = '117.17';

  /// 115.28 supplies scopes, repository_access (canonical 117.17 calls it
  /// resource_access), and the audit trail behind them.
  static const String developerTools =
      'docs/planning/v1.2/sprint_115_developer_tools_connections.json';

  /// 115.14 supplies the reauthentication request and the health observation
  /// that has to clear it.
  static const String connectedAccounts =
      'docs/planning/v1.2/sprint_115_connected_accounts_management.json';

  /// 115.10 supplies the health vocabulary, the bounded retry, and the
  /// terminal revoke transition.
  static const String connectionHealth =
      'docs/planning/v1.2/sprint_115_connection_health_state_machine.json';

  /// Every committed source this validation decides from.
  static const List<String> sourceManifests = <String>[
    developerTools,
    connectedAccounts,
    connectionHealth,
  ];

  /// The external file the committed manifests pin, with the sha256 they
  /// record. A pin that no longer matches is a contradiction of every decision
  /// derived from it, so it is measured, never assumed.
  static const Map<String, String> externalPins = <String, String>{
    'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
            'sprint_115.json':
        'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
            'referenced-chatgpt-conversation-this-is-an-2/outputs/'
            'account_cloud_center_spec.json':
        'f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a',
  };

  static const String passVerdict =
      'DEVELOPER_CONNECTOR_WORKFLOW_VALIDATED_LOCAL';
  static const String blockedVerdict =
      'DEVELOPER_CONNECTOR_WORKFLOW_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'DEVELOPER_CONNECTOR_WORKFLOW_INCONSISTENT';

  /// The six evidence items canonical step 117.17 names, in canonical order.
  static const List<String> requiredChecks = <String>[
    'scopes',
    'resource_access',
    'rate_limits',
    'reauth',
    'revoke',
    'audit',
  ];
}

/// One canonical check, the method that exercises it, and its outcome.
class Sprint117DeveloperConnectorWorkflowCheck {
  Sprint117DeveloperConnectorWorkflowCheck({
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
class Sprint117DeveloperConnectorWorkflowAnchor {
  Sprint117DeveloperConnectorWorkflowAnchor({
    required Map<String, String> declaredContractSizes,
    required Map<String, bool> boundariesDeclared,
    required this.developerAcceptanceDeclared,
    required this.reauthAcceptanceDeclared,
    required this.healthAcceptanceDeclared,
    required this.reauthBeforeSensitiveActionDeclared,
    required this.disconnectProviderSensitiveAction,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
  }) : declaredContractSizes = Map<String, String>.unmodifiable(
         declaredContractSizes,
       ),
       boundariesDeclared = Map<String, bool>.unmodifiable(boundariesDeclared);

  /// How many contract items each committed source declares, by path.
  final Map<String, String> declaredContractSizes;

  /// Whether each committed source states where its own evidence stops.
  final Map<String, bool> boundariesDeclared;

  /// Whether 115.28 declares scopes and a repository-access guarantee.
  final bool developerAcceptanceDeclared;

  /// Whether 115.14 declares a reauthentication acceptance item.
  final bool reauthAcceptanceDeclared;

  /// Whether 115.10 declares the health/retry/revoke acceptance items.
  final bool healthAcceptanceDeclared;

  /// Whether the product spec declares reauth before a sensitive action.
  final bool reauthBeforeSensitiveActionDeclared;

  /// Whether the product spec calls disconnecting a provider a sensitive
  /// action.
  final bool disconnectProviderSensitiveAction;

  final int externalPinsMatched;
  final int externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117DeveloperConnectorWorkflowContract.externalPins.length;

  bool get allExternalPinsMatch =>
      externalPinsResolved && externalPinsMatched == externalPinsChecked;
}

/// The decided-versus-observed input the gate reasons about.
class Sprint117DeveloperConnectorWorkflowInput {
  const Sprint117DeveloperConnectorWorkflowInput({
    this.rows,
    this.anchor,
    this.drillRun,
    this.externalPinDrift = false,
  });

  final List<Sprint117DeveloperConnectorWorkflowCheck>? rows;
  final Sprint117DeveloperConnectorWorkflowAnchor? anchor;
  final Sprint117DeveloperConnectorWorkflowDrillRun? drillRun;

  /// Whether an external pin no longer matches what its manifest recorded.
  final bool externalPinDrift;
}

/// Whether a canonical acceptance could be satisfied by shipped code at all.
enum Sprint117DeveloperConnectorWorkflowAcceptance {
  satisfied,
  mechanismAbsent,
}

/// One measured local observation behind a canonical check.
class Sprint117DeveloperConnectorWorkflowObservation {
  Sprint117DeveloperConnectorWorkflowObservation({
    required this.checkId,
    required this.outcome,
    required this.facts,
    required this.passed,
    this.acceptance = Sprint117DeveloperConnectorWorkflowAcceptance.satisfied,
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
  final Sprint117DeveloperConnectorWorkflowAcceptance acceptance;

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
class Sprint117DeveloperConnectorWorkflowDrillRun {
  Sprint117DeveloperConnectorWorkflowDrillRun({
    required List<Sprint117DeveloperConnectorWorkflowObservation> observations,
    required this.liveProviderTouched,
    required this.userProjectTouched,
    required this.liveCredentialObserved,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
    this.productionCallerPresent = true,
  }) : observations =
           List<Sprint117DeveloperConnectorWorkflowObservation>.unmodifiable(
             observations,
           );

  final List<Sprint117DeveloperConnectorWorkflowObservation> observations;

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

  bool get allPassed => observations.every((entry) => entry.passed);

  bool get allExternalPinsMatchForDrill =>
      externalPinsChecked > 0 && externalPinsMatched == externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117DeveloperConnectorWorkflowContract.externalPins.length;

  List<String> get acceptanceSatisfied => <String>[
    for (final entry in observations)
      if (entry.acceptance ==
          Sprint117DeveloperConnectorWorkflowAcceptance.satisfied)
        entry.checkId,
  ];

  List<String> get acceptanceUnmet => <String>[
    for (final entry in observations)
      if (entry.acceptance ==
          Sprint117DeveloperConnectorWorkflowAcceptance.mechanismAbsent)
        entry.checkId,
  ];

  List<String> get unresolvableReferences => <String>[
    for (final entry in observations) ...entry.unresolvable,
  ];

  Sprint117DeveloperConnectorWorkflowObservation? observationFor(
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
    'observations': <Map<String, Object?>>[
      for (final entry in observations) entry.toJson(),
    ],
  };
}

/// Reads the committed manifests and never invents a subject.
class Sprint117DeveloperConnectorWorkflowLoader {
  const Sprint117DeveloperConnectorWorkflowLoader();

  Sprint117DeveloperConnectorWorkflowInput load() =>
      Sprint117DeveloperConnectorWorkflowInput(
        rows: _loadRows(),
        anchor: _loadAnchor(),
      );

  /// Folds the measured drill into the committed record.
  Sprint117DeveloperConnectorWorkflowInput loadWithDrill(
    Sprint117DeveloperConnectorWorkflowDrillRun run,
  ) => Sprint117DeveloperConnectorWorkflowInput(
    rows: _loadRows(run),
    anchor: _loadAnchor(),
    drillRun: run,
    // A run that could not read every pin cannot prove drift either; only a
    // readable pin that no longer matches is a contradiction.
    externalPinDrift:
        run.externalPinsResolved && !run.allExternalPinsMatchForDrill,
  );

  Sprint117DeveloperConnectorWorkflowAnchor? _loadAnchor() {
    final declared = <String, String>{};
    final boundaries = <String, bool>{};
    Map<String, dynamic>? spec;
    var specPath = '';
    var declaredSubtrees = <String>{};
    for (final path
        in Sprint117DeveloperConnectorWorkflowContract.sourceManifests) {
      final source = _readJsonFile(path);
      if (source == null) return null;
      declared[path] = _declaredContractSize(source);
      boundaries[path] = _declaresBoundary(source);
      if (path ==
          Sprint117DeveloperConnectorWorkflowContract.connectionHealth) {
        // 115.10 records only the spec's *path* and the token subtrees it
        // reads; the guarantees themselves live in that file. Reading
        // `security_contract` out of 115.10 instead of out of the spec it pins
        // yields nothing, which would silently leave every guarantee
        // unmeasured.
        spec = Map<String, dynamic>.from(
          source['sources'] is Map<dynamic, dynamic>
              ? (source['sources'] as Map<dynamic, dynamic>)['product_spec']
                        as Map<dynamic, dynamic>? ??
                    const <dynamic, dynamic>{}
              : const <dynamic, dynamic>{},
        );
        specPath = spec['path'] as String? ?? '';
        declaredSubtrees = spec['subtrees'] is List<dynamic>
            ? (spec['subtrees'] as List<dynamic>)
                  .map((e) => e.toString())
                  .toSet()
            : <String>{};
      }
    }
    if (spec == null || specPath.isEmpty) return null;

    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117DeveloperConnectorWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }

    // The guarantees themselves live in the file 115.10 pins, not in 115.10
    // itself, so they are read from there. The pin is measured separately in
    // the loop above; a drifted or unread spec therefore cannot report
    // guarantees it did not actually contain.
    final specFile = _readJsonFile(specPath);
    final secrets = specFile?['security_contract']?['secrets'];
    final sensitive = specFile?['security_contract']?['sensitive_actions'];
    // 115.10 names the subtrees it read; if it never named the ones this
    // validation depends on, the guarantees are undeclared regardless of what
    // the spec file happens to contain.
    //
    // The names are matched the way 115.10 records them — as the top-level
    // subtree (`security_contract`), not as dotted leaves. Matching dotted
    // leaves makes this term false for a manifest that plainly declares the
    // subtree, which is the same false-zero the drill hit when a symbol search
    // returned nothing for the wrong reason: a zero that means "measured with
    // the wrong pattern", not "not declared". A prefix match accepts either
    // spelling, so the term is true exactly when the subtree is covered.
    final requiredSubtrees = <String>[
      'security_contract.secrets',
      'security_contract.sensitive_actions',
    ];
    final subtreesDeclared = requiredSubtrees.every(
      (required) => declaredSubtrees.any(
        (declared) => declared == required || required.startsWith('$declared.'),
      ),
    );

    return Sprint117DeveloperConnectorWorkflowAnchor(
      declaredContractSizes: declared,
      boundariesDeclared: boundaries,
      developerAcceptanceDeclared: _declares(
        Sprint117DeveloperConnectorWorkflowContract.developerTools,
        <String>['scopes', 'repository_access'],
      ),
      reauthAcceptanceDeclared: _declares(
        Sprint117DeveloperConnectorWorkflowContract.connectedAccounts,
        <String>['reauth'],
      ),
      healthAcceptanceDeclared: _declares(
        Sprint117DeveloperConnectorWorkflowContract.connectionHealth,
        <String>['health_refresh', 'revoke_path'],
      ),
      reauthBeforeSensitiveActionDeclared:
          secrets is List &&
          secrets.contains('reauth_before_sensitive_action') &&
          subtreesDeclared,
      disconnectProviderSensitiveAction:
          sensitive is List &&
          sensitive.contains('disconnect_provider') &&
          subtreesDeclared,
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }

  /// Whether the committed source at [path] declares every item in [items].
  ///
  /// Measured by reading the source's own acceptance list, not by comparing
  /// against a copy of that list written here. A constant list would be the
  /// same defect 117.16 rejected: it makes the guarantee look declared by
  /// something that never looked at the file.
  static bool _declares(String path, List<String> items) {
    final source = _readJsonFile(path);
    if (source == null) return false;
    final declared = source['acceptance'];
    if (declared is! List<dynamic>) return false;
    final names = declared.map((entry) => entry.toString()).toSet();
    return items.every(names.contains);
  }

  List<Sprint117DeveloperConnectorWorkflowCheck>? _loadRows([
    Sprint117DeveloperConnectorWorkflowDrillRun? run,
  ]) {
    if (_loadAnchor() == null) return null;
    return <Sprint117DeveloperConnectorWorkflowCheck>[
      for (final checkId
          in Sprint117DeveloperConnectorWorkflowContract.requiredChecks)
        if (_defined(checkId))
          Sprint117DeveloperConnectorWorkflowCheck(
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
    'scopes' ||
    'resource_access' ||
    'audit' => Sprint117DeveloperConnectorWorkflowContract.developerTools,
    'reauth' => Sprint117DeveloperConnectorWorkflowContract.connectedAccounts,
    'rate_limits' ||
    'revoke' => Sprint117DeveloperConnectorWorkflowContract.connectionHealth,
    _ => '',
  };

  /// The step this validation runs for a check.
  static String _method(String checkId) => switch (checkId) {
    'scopes' =>
      'connect with duplicated, cased, and padded scope text and record that '
          'the stored set is normalized, deduplicated, and unmodifiable, and '
          'that an empty or blank-only scope set is refused outright',
    'resource_access' =>
      'drive the repository-access rule in every direction and record that a '
          'declared access level wider than the granted scopes is refused, '
          'that a narrower level is refused, and that the shipped rule cannot '
          'be satisfied by a scope it never received',
    'rate_limits' =>
      'move a live connection through the RATE_LIMITED health state and '
          'record that the connection stays usable, that the limit is visible '
          'in the user-facing text, and that the limit is never laundered into '
          'a healthy or unknown state',
    'reauth' =>
      'request reauthentication, then record a health observation and prove '
          'the request is cleared by proof rather than left outstanding, and '
          'that the refresh carries the timestamp it claims',
    'revoke' =>
      'revoke a live connection and record that the state is terminal, that no '
          'further transition is possible from it, that the refusal is visible, '
          'and that ending a developer connection is refused when the '
          'reauthentication gate refuses and recorded when it does not',
    'audit' =>
      'walk every action a developer connection can take and record that each '
          'one emits exactly one row, that a refused sensitive action is '
          'audited as a refusal rather than as an absence, and that no row '
          'carries scope or repository-access material',
    _ => '',
  };

  /// What the method is expected to produce locally.
  static String _expectedOutcome(String checkId) => switch (checkId) {
    'scopes' =>
      'a connection carries exactly the normalized scopes it was granted and '
          'cannot be widened or emptied afterwards',
    'resource_access' =>
      'declared repository access never exceeds the granted scopes, in either '
          'direction',
    'rate_limits' =>
      'a rate-limited connection stays connected, says so, and is never '
          'reported as healthy',
    'reauth' =>
      'a reauthentication request is cleared by a health observation and not '
          'left outstanding',
    'revoke' =>
      'a revoked connection is terminal, and ending a connection requires the '
          'gate and is audited either way',
    'audit' =>
      'every action, including every refusal, is audited and no row carries '
          'scope material',
    _ => '',
  };

  /// How many contract items a source declares, or empty when it declares none.
  static String _declaredContractSize(Map<String, dynamic> source) {
    for (final key in const <String>[
      'acceptance',
      'required_states',
      'required_outputs',
      'required_fields',
    ]) {
      final declared = source[key];
      if (declared is List<dynamic> && declared.isNotEmpty) {
        return 'DECLARED:$key:${declared.length}';
      }
      if (declared is Map<String, dynamic> && declared.isNotEmpty) {
        return 'DECLARED:$key:${declared.length}';
      }
    }
    final standard = source['standard_manifest'];
    if (standard is Map<String, dynamic> && standard.isNotEmpty) {
      return 'DECLARED:standard_manifest:${standard.length}';
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
}

/// Decides whether the recorded connector evidence is coherent.
class Sprint117DeveloperConnectorWorkflowGate {
  const Sprint117DeveloperConnectorWorkflowGate();

  /// Runs the drill, then decides from its measured output.
  Future<Sprint117DeveloperConnectorWorkflowReport> evaluateWithDrill([
    Sprint117DeveloperConnectorWorkflowDrillRun? run,
  ]) async {
    final measured =
        run ?? await const Sprint117DeveloperConnectorWorkflowDrill().run();
    return evaluateWith(
      const Sprint117DeveloperConnectorWorkflowLoader().loadWithDrill(measured),
    );
  }

  Sprint117DeveloperConnectorWorkflowReport evaluate() =>
      evaluateWith(const Sprint117DeveloperConnectorWorkflowLoader().load());

  Sprint117DeveloperConnectorWorkflowReport evaluateWith(
    Sprint117DeveloperConnectorWorkflowInput input,
  ) {
    final missing = <String>{};
    final violations = <String>{};

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('developer_connector_anchor');
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
      if (!anchor.developerAcceptanceDeclared) {
        missing.add('developer_scopes_and_resource_access_acceptance');
      }
      if (!anchor.reauthAcceptanceDeclared) {
        missing.add('reauth_acceptance');
      }
      if (!anchor.healthAcceptanceDeclared) {
        missing.add('health_refresh_and_revoke_acceptance');
      }
      if (!anchor.reauthBeforeSensitiveActionDeclared) {
        missing.add('reauth_before_sensitive_action_acceptance');
      }
      if (!anchor.disconnectProviderSensitiveAction) {
        missing.add('disconnect_provider_sensitive_action');
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
                Sprint117DeveloperConnectorWorkflowAcceptance.satisfied) {
          violations.add(
            'acceptance_claimed_without_mechanism:${observation.checkId}',
          );
        }
      }
    }

    final rows = input.rows;
    final rowIds = <String>{};
    final checks = <Sprint117DeveloperConnectorWorkflowCheck>[];
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
    if (anchor != null && !missing.contains('developer_connector_anchor')) {
      for (final checkId
          in Sprint117DeveloperConnectorWorkflowContract.requiredChecks) {
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
        anchor != null && !missing.contains('developer_connector_anchor');
    var decidedCount = 0;
    for (final row in checks) {
      if (row.executed && anchorResolved) decidedCount += 1;
    }
    final total =
        Sprint117DeveloperConnectorWorkflowContract.requiredChecks.length;
    final coverage = total == 0 ? 0.0 : decidedCount / total;

    final complete = missing.isEmpty && violations.isEmpty;
    final state = violations.isNotEmpty
        ? Sprint117DeveloperConnectorWorkflowState.fail
        : (complete
              ? Sprint117DeveloperConnectorWorkflowState.pass
              : Sprint117DeveloperConnectorWorkflowState.blocked);

    return Sprint117DeveloperConnectorWorkflowReport(
      status: state,
      verdict: switch (state) {
        Sprint117DeveloperConnectorWorkflowState.pass =>
          Sprint117DeveloperConnectorWorkflowContract.passVerdict,
        Sprint117DeveloperConnectorWorkflowState.fail =>
          Sprint117DeveloperConnectorWorkflowContract.failVerdict,
        Sprint117DeveloperConnectorWorkflowState.blocked =>
          Sprint117DeveloperConnectorWorkflowContract.blockedVerdict,
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
    Sprint117DeveloperConnectorWorkflowCheck row,
    Sprint117DeveloperConnectorWorkflowDrillRun? drillRun,
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
    Sprint117DeveloperConnectorWorkflowDrillRun? drillRun,
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
      // harness imports the developer connector managers, so every check above
      // exercises code no user path reaches. The mechanisms are declared and
      // correct; they are simply not wired to anything yet. A run without a
      // drill measured nothing, so it claims nothing.
      if (drillRun != null && !drillRun.productionCallerPresent)
        'no_shipped_consumer_for_developer_connector_managers',
      // The canonical 117.17 wording names organizations/workspaces; no anchor
      // source declares an organization or workspace acceptance item, so the
      // guarantee is exercised through scopes and repository access only and
      // the gap is reported rather than papered over with a check that was
      // never promised by any source.
      'organization_workspace_acceptance_undeclared_by_anchor_sources',
      'rate_limit_acceptance_undeclared_by_anchor_sources',
      'developer_connector_workflow_defined_not_executed_live',
      'external_connector_specs_outside_repository',
    };
    return items.toList(growable: false)..sort();
  }
}

/// The gate's verdict, with the evidence it decided from.
class Sprint117DeveloperConnectorWorkflowReport {
  Sprint117DeveloperConnectorWorkflowReport({
    required this.status,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required List<String> unmappedChecks,
    required List<String> undeterminedChecks,
    required this.coverage,
    required List<String> acceptanceSatisfied,
    required List<String> acceptanceUnmet,
    required List<Sprint117DeveloperConnectorWorkflowCheck> checks,
    required this.anchor,
    required List<String> openItems,
  }) : acceptanceSatisfied = List<String>.unmodifiable(acceptanceSatisfied),
       acceptanceUnmet = List<String>.unmodifiable(acceptanceUnmet),
       missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       unmappedChecks = List<String>.unmodifiable(unmappedChecks),
       undeterminedChecks = List<String>.unmodifiable(undeterminedChecks),
       checks = List<Sprint117DeveloperConnectorWorkflowCheck>.unmodifiable(
         checks,
       ),
       openItems = List<String>.unmodifiable(openItems);

  final Sprint117DeveloperConnectorWorkflowState status;

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

  final List<Sprint117DeveloperConnectorWorkflowCheck> checks;
  final Sprint117DeveloperConnectorWorkflowAnchor? anchor;

  /// What this report leaves open, including every deferred external gate.
  final List<String> openItems;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117DeveloperConnectorWorkflowContract.canonicalStep,
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
            'developer_acceptance_declared':
                anchor!.developerAcceptanceDeclared,
            'reauth_acceptance_declared': anchor!.reauthAcceptanceDeclared,
            'health_acceptance_declared': anchor!.healthAcceptanceDeclared,
            'reauth_before_sensitive_action_declared':
                anchor!.reauthBeforeSensitiveActionDeclared,
            'disconnect_provider_sensitive_action':
                anchor!.disconnectProviderSensitiveAction,
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
