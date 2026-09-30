/// Canonical step 117.12 — Identity Workflow Validation.
///
/// Objective (external canonical JSON): exercise connect, link, collision,
/// reauth, unlink, last-method protection, recovery, and revoke for certified
/// identities.
///
/// The eight required-evidence names read like an end-to-end account identity
/// story. What the shipped code actually offers is a set of local, injectable
/// domain seams and no live provider at all, so the check and the drill are
/// deliberately separate classes, exactly as 117.5-117.11 did:
///
/// * [Sprint117IdentityWorkflowDrill] really executes the shipped mechanisms:
///   the OAuth authorization-code + PKCE exchange through [AccountOAuthFlow]
///   with an injected broker, the collision and last-method guards in
///   [IdentityLinkingService], the reauthentication gate in
///   [AccountSecureTokenVault], the revoke transition in
///   [AccountConnectionHealthStateMachine], and the local-data-preserved
///   states in [AccountCenterTokenExpiryReauthenticationUx]. It writes nothing
///   and never contacts a provider.
/// * [Sprint117IdentityWorkflowLoader] reads the committed manifests and the
///   external files they pin, and never invents a check or an outcome.
/// * [Sprint117IdentityWorkflowGate] decides whether the recorded evidence is
///   coherent, synchronously and without side effects.
///
/// Two facts are measured rather than assumed, and both shape the verdict:
///
/// 1. `connect` cannot be exercised against a real identity provider. Every
///    entry the shipped `ProviderConnectorManifest.standard` builds comes from
///    the icon registry with `availability: UNVERIFIED`, so
///    [ProviderConnectorEntry.isConnectable] is false for all of them and
///    [AccountOAuthFlow] refuses them before any exchange runs. The drill
///    therefore declares a fixture connector that satisfies the shipped gate
///    exactly as a certified entry would, completes a real exchange against
///    it, and records the count of shipped connectors that would have been
///    accepted as `zero`. The certification snapshot records 8 identity
///    providers as CERTIFIED, so the gap is precisely between the recorded
///    certification and the shipped manifest — reported, not papered over.
/// 2. [IdentityLinkingService], [AccountConnectedAccountsManagement],
///    [AccountOAuthFlow], and [AccountConnectionHealthStateMachine] have zero
///    call sites in `lib/` outside the file that declares them. Every gate is
///    defined, drilled, and correct, and none of them is yet invoked by a
///    shipped production path. That absence is reported per check with the
///    exact symbol spelling.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/account/domain/account_center_api_keys_manager.dart';
import 'package:void_scriptor/features/account/domain/account_center_connected_accounts_management.dart';
import 'package:void_scriptor/features/account/domain/account_center_connection_health_state_machine.dart';
import 'package:void_scriptor/features/account/domain/account_center_identity_linking_collision.dart';
import 'package:void_scriptor/features/account/domain/account_center_oauth_linked_identity_flow.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';
import 'package:void_scriptor/features/account/domain/account_center_token_expiry_reauthentication_ux.dart';

part 'sprint_117_identity_workflow_drill.dart';

enum Sprint117IdentityWorkflowState { pass, fail, blocked }

/// Immutable description of the contract, its sources, and its verdicts.
abstract final class Sprint117IdentityWorkflowContract {
  static const String canonicalStep = '117.12';

  /// 115.9 supplies the connector manifest whose availability decides whether
  /// any identity connector is connectable at all.
  static const String providerConnector =
      'docs/planning/v1.2/sprint_115_provider_connector_manifest.json';

  /// 115.10 supplies the connection state machine that owns the revoke path
  /// and the reauthenticate transition.
  static const String connectionHealth =
      'docs/planning/v1.2/sprint_115_connection_health_state_machine.json';

  /// 115.11 supplies the OAuth and linked-identity flow, including the unlink
  /// rule this validation drills verbatim.
  static const String identityFlow =
      'docs/planning/v1.2/sprint_115_oauth_linked_identity_flow.json';

  /// 115.12 supplies the secure vault whose read path is gated on
  /// reauthentication.
  static const String secureVault =
      'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json';

  /// 115.14 supplies connected-accounts management, including the unlink
  /// confirmation that must precede removal.
  static const String connectedAccounts =
      'docs/planning/v1.2/sprint_115_connected_accounts_management.json';

  /// 115.43 supplies the expiry and reauthentication UX, including the
  /// preserved-local-data invariant.
  static const String tokenExpiryUx =
      'docs/planning/v1.2/sprint_115_token_expiry_reauthentication_ux.json';

  /// 116.14 supplies collision detection, safe merge, last-method protection,
  /// takeover prevention, unlink, and recovery.
  static const String identityLinking =
      'docs/planning/v1.2/sprint_116_identity_linking_collision.json';

  /// Every committed source this validation decides from.
  static const List<String> sourceManifests = <String>[
    providerConnector,
    connectionHealth,
    identityFlow,
    secureVault,
    connectedAccounts,
    tokenExpiryUx,
    identityLinking,
  ];

  /// 115.11's recorded unlink rule, drilled verbatim rather than paraphrased.
  static const String unlinkRule = 'protocol.unlink';

  /// The production key scheme of [AccountSecureTokenVault.keyFor].
  static const String vaultKeyScheme = 'account/<id>/<kind>[/<secretId>]';

  static const String passVerdict = 'IDENTITY_WORKFLOW_VALIDATED_LOCAL';
  static const String blockedVerdict =
      'IDENTITY_WORKFLOW_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'IDENTITY_WORKFLOW_INCONSISTENT';

  /// The eight evidence items canonical step 117.12 names, in canonical order.
  static const List<String> requiredChecks = <String>[
    'connect',
    'link',
    'collision',
    'reauth',
    'unlink',
    'last_method',
    'recovery',
    'revoke',
  ];

  /// The external files the committed manifests pin, with the sha256 each
  /// manifest records. A pin that no longer matches is a contradiction of
  /// every decision derived from it, so it is measured, never assumed.
  static const Map<String, String> externalPins = <String, String>{
    'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
            'sprint_115.json':
        'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
            'referenced-chatgpt-conversation-this-is-an-2/outputs/'
            'account_cloud_center_spec.json':
        'f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a',
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
            'referenced-chatgpt-conversation-this-is-an-2/outputs/'
            'connector_sdk_spec.json':
        '052e8b240f772887bf39ce1337cef2919e52251e59c569440403cd6aa41528dc',
  };
}

/// One canonical check, the method that exercises it, and its outcome.
class Sprint117IdentityWorkflowCheck {
  Sprint117IdentityWorkflowCheck({
    required this.checkId,
    required this.method,
    required this.expectedOutcome,
    required this.observedOutcome,
    required this.sourceManifest,
    required this.liveProviderResult,
    required this.drilledAgainstLiveProvider,
  });

  /// The canonical check identity, e.g. `connect`.
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
class Sprint117IdentityWorkflowAnchor {
  Sprint117IdentityWorkflowAnchor({
    required Map<String, String> declaredContractSizes,
    required Map<String, bool> boundariesDeclared,
    required this.unlinkRuleDeclared,
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

  /// Whether 115.11 records the unlink rule this validation drills.
  final bool unlinkRuleDeclared;

  /// How many external pins matched their recorded sha256.
  final int externalPinsMatched;

  /// How many external pins were readable and therefore comparable.
  final int externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117IdentityWorkflowContract.externalPins.length;

  bool get allExternalPinsMatch =>
      externalPinsResolved && externalPinsMatched == externalPinsChecked;
}

/// The decided-versus-observed input the gate reasons about.
class Sprint117IdentityWorkflowInput {
  const Sprint117IdentityWorkflowInput({
    this.rows,
    this.anchor,
    this.drillRun,
    this.externalPinDrift = false,
  });

  final List<Sprint117IdentityWorkflowCheck>? rows;
  final Sprint117IdentityWorkflowAnchor? anchor;
  final Sprint117IdentityWorkflowDrillRun? drillRun;

  /// Whether an external pin no longer matches what its manifest recorded.
  final bool externalPinDrift;
}

/// Whether a canonical acceptance could be satisfied by shipped code at all.
enum Sprint117IdentityWorkflowAcceptance { satisfied, mechanismAbsent }

/// One measured local observation behind a canonical check.
class Sprint117IdentityWorkflowObservation {
  Sprint117IdentityWorkflowObservation({
    required this.checkId,
    required this.outcome,
    required Map<String, Object?> facts,
    required this.passed,
    required this.acceptance,
    required List<String> unresolvable,
  }) : facts = Map<String, Object?>.unmodifiable(facts),
       unresolvable = List<String>.unmodifiable(unresolvable);

  final String checkId;

  /// What the local exercise produced.
  final String outcome;

  /// The measured facts behind that outcome.
  final Map<String, Object?> facts;

  /// Whether the local mechanism responded as the contract expects.
  final bool passed;

  /// Whether the evidence item this check stands for could be satisfied.
  final Sprint117IdentityWorkflowAcceptance acceptance;

  /// Recorded subjects the check could not resolve, spelled exactly.
  final List<String> unresolvable;

  bool get acceptanceSatisfied =>
      acceptance == Sprint117IdentityWorkflowAcceptance.satisfied;

  Map<String, Object?> toJson() => <String, Object?>{
    'check_id': checkId,
    'outcome': outcome,
    'facts': Map<String, Object?>.from(facts),
    'passed': passed,
    'acceptance': acceptance.name,
    'acceptance_satisfied': acceptanceSatisfied,
    'unresolvable': List<String>.from(unresolvable),
  };
}

/// The record of one local drill run.
class Sprint117IdentityWorkflowDrillRun {
  Sprint117IdentityWorkflowDrillRun({
    required List<Sprint117IdentityWorkflowObservation> observations,
    required this.liveProviderTouched,
    required this.userProjectTouched,
    required this.liveSecretObserved,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
  }) : observations = List<Sprint117IdentityWorkflowObservation>.unmodifiable(
         observations,
       );

  final List<Sprint117IdentityWorkflowObservation> observations;

  /// Always false: this drill contacts no provider.
  final bool liveProviderTouched;

  /// Always false: this drill writes nothing to a user project.
  final bool userProjectTouched;

  /// Always false: no live secret is ever read; only fixture material the
  /// drill itself created is scanned and then discarded.
  final bool liveSecretObserved;

  /// How many external pins matched during this run.
  final int externalPinsMatched;

  /// How many external pins were readable during this run.
  final int externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117IdentityWorkflowContract.externalPins.length;

  bool get allPassed => observations.every((observation) => observation.passed);

  /// Every recorded subject the drill could not resolve, across checks.
  List<String> get unresolvableReferences {
    final refs = <String>{
      for (final observation in observations)
        for (final reference in observation.unresolvable) reference,
    };
    return refs.toList(growable: false)..sort();
  }

  /// Checks whose acceptance shipped code can actually satisfy, sorted.
  List<String> get acceptanceSatisfied {
    final satisfied = <String>[
      for (final observation in observations)
        if (observation.acceptanceSatisfied) observation.checkId,
    ];
    return satisfied..sort();
  }

  /// Checks whose acceptance cannot be satisfied, sorted.
  List<String> get acceptanceUnmet {
    final unmet = <String>[
      for (final observation in observations)
        if (!observation.acceptanceSatisfied) observation.checkId,
    ];
    return unmet..sort();
  }

  Sprint117IdentityWorkflowObservation? observationFor(String checkId) {
    for (final observation in observations) {
      if (observation.checkId == checkId) return observation;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'observations': <Map<String, Object?>>[
      for (final observation in observations) observation.toJson(),
    ],
    'live_provider_touched': liveProviderTouched,
    'user_project_touched': userProjectTouched,
    'live_secret_observed': liveSecretObserved,
    'external_pins_matched': externalPinsMatched,
    'external_pins_checked': externalPinsChecked,
    'external_pins_resolved': externalPinsResolved,
    'all_passed': allPassed,
    'acceptance_satisfied': acceptanceSatisfied,
    'acceptance_unmet': acceptanceUnmet,
    'unresolvable_references': unresolvableReferences,
  };
}

/// Reads the committed manifests and never invents a subject.
class Sprint117IdentityWorkflowLoader {
  const Sprint117IdentityWorkflowLoader();

  Sprint117IdentityWorkflowInput load() =>
      Sprint117IdentityWorkflowInput(rows: _loadRows(), anchor: _loadAnchor());

  /// Folds the measured drill into the committed record.
  Sprint117IdentityWorkflowInput loadWithDrill(
    Sprint117IdentityWorkflowDrillRun run,
  ) => Sprint117IdentityWorkflowInput(
    rows: _loadRows(run),
    anchor: _loadAnchor(),
    drillRun: run,
    // A run that could not read every pin cannot prove drift either; only a
    // readable pin that no longer matches is a contradiction.
    externalPinDrift:
        run.externalPinsResolved && !run.allExternalPinsMatchForDrill,
  );

  Sprint117IdentityWorkflowAnchor? _loadAnchor() {
    final declared = <String, String>{};
    final boundaries = <String, bool>{};
    Map<String, dynamic>? identityFlow;
    for (final path in Sprint117IdentityWorkflowContract.sourceManifests) {
      final source = _readJsonFile(path);
      if (source == null) return null;
      declared[path] = _declaredContractSize(source);
      boundaries[path] = _declaresBoundary(source);
      if (path == Sprint117IdentityWorkflowContract.identityFlow) {
        identityFlow = source;
      }
    }
    if (identityFlow == null) return null;

    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117IdentityWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }

    return Sprint117IdentityWorkflowAnchor(
      declaredContractSizes: declared,
      boundariesDeclared: boundaries,
      unlinkRuleDeclared:
          _nestedText(identityFlow, const <String>['protocol', 'unlink']) !=
          null,
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }

  List<Sprint117IdentityWorkflowCheck>? _loadRows([
    Sprint117IdentityWorkflowDrillRun? run,
  ]) {
    if (_loadAnchor() == null) return null;
    return <Sprint117IdentityWorkflowCheck>[
      for (final checkId in Sprint117IdentityWorkflowContract.requiredChecks)
        if (_defined(checkId))
          Sprint117IdentityWorkflowCheck(
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

  /// A check exists only where its source records a contract. 115.9 is not
  /// uniform with the rest of the 115 family: it declares `required_fields`
  /// and a `standard_manifest` block instead of an `acceptance` list, and
  /// reading one key for all of them would report a real subject as
  /// undeclared.
  static bool _defined(String checkId) {
    final source = _readJsonFile(_sourceFor(checkId));
    if (source == null) return false;
    return _declaredContractSize(source).isNotEmpty;
  }

  /// The committed manifest that owns a check.
  static String _sourceFor(String checkId) => switch (checkId) {
    'connect' => Sprint117IdentityWorkflowContract.providerConnector,
    'link' ||
    'collision' ||
    'last_method' ||
    'recovery' => Sprint117IdentityWorkflowContract.identityLinking,
    'reauth' => Sprint117IdentityWorkflowContract.secureVault,
    'unlink' => Sprint117IdentityWorkflowContract.identityFlow,
    'revoke' => Sprint117IdentityWorkflowContract.connectionHealth,
    _ => '',
  };

  /// The step this validation runs for a check.
  static String _method(String checkId) => switch (checkId) {
    'connect' =>
      'count shipped connectors the manifest marks connectable, then run a '
          'real authorization-code exchange against a fixture connector that '
          'satisfies the same gate',
    'link' =>
      'add a second provider identity to an account through '
          'IdentityLinkingService.link and read the account back',
    'collision' =>
      'attempt duplicate-email, already-linked, and cross-account identity '
          'links and record which guard rejected each',
    'reauth' =>
      'read through the vault with reauthentication refused and granted, mark '
          'a connection reauthRequired, and drive the expire -> reauthenticate '
          'transitions',
    'unlink' =>
      'keep linked, fail provider revocation, and succeed at revocation, then '
          'confirm management-level unlink without confirmation',
    'last_method' =>
      'unlink the only identity of an account without a recovery email, then '
          'again after recovery is recorded',
    'recovery' =>
      'reject a malformed recovery email, record a valid one, and confirm the '
          'expired and revoked states preserve local data',
    'revoke' =>
      'revoke through the vault and the key manager, and drive the connected '
          '-> revoked transition with its dead end',
    _ => '',
  };

  /// What the step is expected to produce locally.
  static String _expectedOutcome(String checkId) => switch (checkId) {
    'connect' =>
      'no shipped identity connector is connectable, and a real exchange '
          'completes only through a fixture that satisfies the shipped gate',
    'link' =>
      'a second provider identity joins the account and is readable back',
    'collision' =>
      'duplicate email, duplicate identity, and cross-account takeover are '
          'all rejected without mutating either account',
    'reauth' =>
      'a refused reauthentication yields no secret and a granted one yields '
          'the secret, and the connection returns to connecting state',
    'unlink' =>
      'a kept link is untouched, a failed revocation preserves the link, and '
          'a successful revocation removes it',
    'last_method' =>
      'the last identity cannot be unlinked until a recovery email exists',
    'recovery' =>
      'a malformed recovery email is rejected, a valid one is stored, and '
          'local data survives expiry and revocation',
    'revoke' =>
      'the vault key is gone, the managed key is inert, and a revoked '
          'connection has no outgoing transition',
    _ => '',
  };

  /// How many contract items a source declares, or empty when it declares
  /// none. 115.9 declares `required_fields` plus a `standard_manifest` block;
  /// the 115 identity family declares `acceptance`; 116.14 declares
  /// `acceptance` as well.
  static String _declaredContractSize(Map<String, dynamic> source) {
    for (final key in const <String>[
      'acceptance',
      'required_fields',
      'field_contracts',
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
  ///
  /// The 115 family spells that `evidence_boundary`; the 115.12/115.14/115.43
  /// manifests spell it `boundary`; and 116.14 spells it `limitations` plus
  /// `external_gates`. Reading only one spelling would report a real subject
  /// as undeclared, so every spelling that genuinely bounds the evidence
  /// counts.
  static bool _declaresBoundary(Map<String, dynamic> source) {
    for (final key in const <String>['boundary', 'evidence_boundary']) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) return true;
    }
    for (final key in const <String>['limitations', 'deferred_scope']) {
      final value = source[key];
      if (value is List<dynamic> && value.isNotEmpty) return true;
      if (value is Map<String, dynamic> && value.isNotEmpty) return true;
    }
    return false;
  }
}

/// Decides whether the recorded identity-workflow evidence is coherent.
class Sprint117IdentityWorkflowGate {
  const Sprint117IdentityWorkflowGate();

  /// Runs the drill, then decides from its measured output.
  Future<Sprint117IdentityWorkflowReport> evaluateWithDrill([
    Sprint117IdentityWorkflowDrillRun? run,
  ]) async {
    final measured = run ?? await const Sprint117IdentityWorkflowDrill().run();
    return evaluateWith(
      const Sprint117IdentityWorkflowLoader().loadWithDrill(measured),
    );
  }

  Sprint117IdentityWorkflowReport evaluate() =>
      evaluateWith(const Sprint117IdentityWorkflowLoader().load());

  Sprint117IdentityWorkflowReport evaluateWith(
    Sprint117IdentityWorkflowInput input,
  ) {
    final missing = <String>{};
    final violations = <String>{};

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('identity_workflow_anchor');
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
      if (!anchor.unlinkRuleDeclared) {
        missing.add(
          'identity_unlink_rule:${Sprint117IdentityWorkflowContract.unlinkRule}',
        );
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
      if (drillRun.liveSecretObserved) violations.add('live_secret_observed');
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
                Sprint117IdentityWorkflowAcceptance.satisfied) {
          violations.add(
            'acceptance_claimed_without_mechanism:${observation.checkId}',
          );
        }
      }
    }

    final rows = input.rows;
    final rowIds = <String>{};
    final checks = <Sprint117IdentityWorkflowCheck>[];
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
          if (drillRun != null) missing.add('check_observed_outcome:$checkId');
        }
      }
    }

    final unmapped = <String>[];
    if (anchor != null && !missing.contains('identity_workflow_anchor')) {
      for (final checkId in Sprint117IdentityWorkflowContract.requiredChecks) {
        if (!rowIds.contains(checkId)) unmapped.add(checkId);
      }
      for (final checkId in unmapped) {
        violations.add('check_unmapped:$checkId');
      }
    }

    // Coverage counts canonical checks the evidence has actually decided, not
    // rows a manifest happened to declare.
    var decidedCount = 0;
    for (final row in checks) {
      if (row.executed) decidedCount += 1;
    }
    final total = Sprint117IdentityWorkflowContract.requiredChecks.length;
    final coverage = total == 0 ? 0.0 : decidedCount / total;

    final complete = missing.isEmpty && violations.isEmpty;
    final state = violations.isNotEmpty
        ? Sprint117IdentityWorkflowState.fail
        : (complete
              ? Sprint117IdentityWorkflowState.pass
              : Sprint117IdentityWorkflowState.blocked);

    return Sprint117IdentityWorkflowReport(
      status: state,
      verdict: switch (state) {
        Sprint117IdentityWorkflowState.pass =>
          Sprint117IdentityWorkflowContract.passVerdict,
        Sprint117IdentityWorkflowState.fail =>
          Sprint117IdentityWorkflowContract.failVerdict,
        Sprint117IdentityWorkflowState.blocked =>
          Sprint117IdentityWorkflowContract.blockedVerdict,
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
    Sprint117IdentityWorkflowCheck row,
    Sprint117IdentityWorkflowDrillRun? drillRun,
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
      return;
    }
    if (row.observedOutcome != measured.outcome) {
      violations.add('check_outcome_contradicts_drill:$checkId');
      violations.add('recorded_outcome:${row.observedOutcome}');
      violations.add('measured_outcome:${measured.outcome}');
    }
  }

  List<String> _openItems(
    Sprint117IdentityWorkflowDrillRun? drillRun,
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
      'identity_workflow_defined_not_executed_live',
      'external_identity_specs_outside_repository',
    };
    return items.toList(growable: false)..sort();
  }
}

/// The gate's verdict, with the evidence it decided from.
class Sprint117IdentityWorkflowReport {
  Sprint117IdentityWorkflowReport({
    required this.status,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required List<String> unmappedChecks,
    required List<String> undeterminedChecks,
    required this.coverage,
    required List<String> acceptanceSatisfied,
    required List<String> acceptanceUnmet,
    required List<Sprint117IdentityWorkflowCheck> checks,
    required this.anchor,
    required List<String> openItems,
  }) : acceptanceSatisfied = List<String>.unmodifiable(acceptanceSatisfied),
       acceptanceUnmet = List<String>.unmodifiable(acceptanceUnmet),
       missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       unmappedChecks = List<String>.unmodifiable(unmappedChecks),
       undeterminedChecks = List<String>.unmodifiable(undeterminedChecks),
       checks = List<Sprint117IdentityWorkflowCheck>.unmodifiable(checks),
       openItems = List<String>.unmodifiable(openItems);

  final Sprint117IdentityWorkflowState status;

  /// The decision this report carries.
  final String verdict;

  final List<String> missingFields;
  final List<String> violations;
  final List<String> unmappedChecks;

  /// Checks that are defined but that no drill has decided yet.
  final List<String> undeterminedChecks;

  /// Fraction of the canonical checks the evidence decided.
  final double coverage;

  /// Checks whose acceptance shipped code can satisfy.
  final List<String> acceptanceSatisfied;

  /// Checks whose acceptance cannot be satisfied because no mechanism ships.
  final List<String> acceptanceUnmet;

  final List<Sprint117IdentityWorkflowCheck> checks;
  final Sprint117IdentityWorkflowAnchor? anchor;

  /// Every open item this validation carries forward.
  final List<String> openItems;

  Map<String, Object?> toJson() => <String, Object?>{
    'verdict': verdict,
    'status': status.name,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'unmapped_checks': List<String>.from(unmappedChecks),
    'undetermined_checks': List<String>.from(undeterminedChecks),
    'coverage': coverage,
    'acceptance_satisfied': List<String>.from(acceptanceSatisfied),
    'acceptance_unmet': List<String>.from(acceptanceUnmet),
    'open_items': List<String>.from(openItems),
    'anchor': anchor?.toJson(),
    'checks': <Map<String, Object?>>[
      for (final check in checks) check.toJson(),
    ],
  };
}

extension on Sprint117IdentityWorkflowAnchor {
  Map<String, Object?> toJson() => <String, Object?>{
    'declared_contract_sizes': Map<String, String>.from(declaredContractSizes),
    'boundaries_declared': Map<String, bool>.from(boundariesDeclared),
    'unlink_rule_declared': unlinkRuleDeclared,
    'external_pins_matched': externalPinsMatched,
    'external_pins_checked': externalPinsChecked,
    'external_pins_resolved': externalPinsResolved,
  };
}

extension on Sprint117IdentityWorkflowDrillRun {
  /// Whether every readable pin matched during this run.
  bool get allExternalPinsMatchForDrill =>
      externalPinsMatched == externalPinsChecked;
}

/// Reads a committed JSON object, or null when it cannot be read or decoded.
Map<String, dynamic>? _readJsonFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// The sha256 of a file, or null when it cannot be read.
String? _sha256OfFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    return sha256.convert(file.readAsBytesSync()).toString();
  } on FileSystemException {
    return null;
  }
}

/// Reads a nested string by key path, or null when any level is absent.
String? _nestedText(Map<String, dynamic> source, List<String> keys) {
  Object? current = source;
  for (final key in keys) {
    if (current is! Map<String, dynamic>) return null;
    current = current[key];
  }
  return current is String ? current : null;
}
