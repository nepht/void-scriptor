/// Canonical step 117.16 — API Key Workflow Validation.
///
/// Objective (external canonical JSON): test add, replace, validate, mask,
/// scope, secure copy, revoke, audit, and no-plaintext guarantees.
///
/// The nine evidence names are the ways a user can lose a credential or leak
/// one, so the check and the drill are deliberately separate classes, exactly
/// as 117.5-117.14 and 117.15 did:
///
/// * [Sprint117ApiKeyWorkflowDrill] really executes the shipped credential
///   mechanisms: [AccountCenterApiKeysManager] add/replace/validate/markUsed/
///   revoke/secureCopy, the [AccountSecureTokenVault] namespace, reauth gate,
///   clipboard window and [AccountSecureTokenVault.clearClipboard], and the
///   [EncryptedCredentialStore] encryption envelope. It writes nothing, opens
///   no user project, contacts no provider, and every secret it uses is
///   fixture data it created itself.
/// * [Sprint117ApiKeyWorkflowLoader] reads the committed manifests and the
///   external files they pin, and never invents a check or an outcome.
/// * [Sprint117ApiKeyWorkflowGate] decides whether the recorded evidence is
///   coherent, synchronously and without side effects.
///
/// Two facts are measured rather than assumed, and both shape the verdict:
///
/// 1. This step found and fixed two real defects in shipped code. A validation
///    refused at the reauthentication gate returned `false` with no state
///    change and no audit row, so a key that could not be validated was
///    indistinguishable from a key nobody had validated yet; and a revoked or
///    rotated key left its material live on the clipboard until the timeout
///    expired on its own. The drill re-measures both, so a regression in either
///    direction fails here.
/// 2. No shipped screen drives this manager. `AccountCenterApiKeysManager` is
///    constructed only by sprint harnesses, so `mask`, `scope`, and `audit`
///    are drilled against the shipped domain rather than a user-visible flow.
///    The AI workspace screen keeps its own credential, which is recorded as
///    a fact rather than folded into a passing claim of integration.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/core/security/application/encrypted_credential_store.dart';
import 'package:void_scriptor/features/account/domain/account_center_api_keys_manager.dart';
import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';

part 'sprint_117_api_key_workflow_drill.dart';

enum Sprint117ApiKeyWorkflowState { pass, fail, blocked }

/// Immutable description of the contract, its sources, and its verdicts.
abstract final class Sprint117ApiKeyWorkflowContract {
  static const String canonicalStep = '117.16';

  /// 115.27 supplies add_replace, validate, revoke, scope, last_used,
  /// masked_only, and secure_copy for the managed key.
  static const String apiKeysManager =
      'docs/planning/v1.2/sprint_115_api_keys_manager.json';

  /// 115.12 supplies os_secure_store, no_plaintext, masked_display, reauth,
  /// audit_redaction, and clipboard_timeout for the vault behind it.
  static const String secureTokenVault =
      'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json';

  /// 115.54 supplies the cross-cutting secret guarantees the product spec
  /// declares, including `never_plaintext_database`, `reauth_before_sensitive_
  /// action`, and `audit_redaction`.
  static const String securityBilling =
      'docs/planning/v1.2/sprint_115_security_billing_verification.json';

  /// Every committed source this validation decides from.
  static const List<String> sourceManifests = <String>[
    apiKeysManager,
    secureTokenVault,
    securityBilling,
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
  };

  static const String passVerdict = 'API_KEY_WORKFLOW_VALIDATED_LOCAL';
  static const String blockedVerdict =
      'API_KEY_WORKFLOW_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'API_KEY_WORKFLOW_INCONSISTENT';

  /// The nine evidence items canonical step 117.16 names, in canonical order.
  static const List<String> requiredChecks = <String>[
    'add_replace',
    'validate',
    'mask',
    'scope',
    'secure_copy',
    'revoke',
    'audit',
    'no_plaintext',
    // Not named by step 117.16, but the anchor this gate binds to is 115.27,
    // whose acceptance list declares `last_used`. A declared anchor item with
    // no row is the unmapped gap this gate rejects elsewhere as
    // `check_unmapped`, so it is decided here rather than passed over.
    'last_used',
  ];
}

/// One canonical check, the method that exercises it, and its outcome.
class Sprint117ApiKeyWorkflowCheck {
  Sprint117ApiKeyWorkflowCheck({
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

  /// Whether a live provider or OS vault produced this outcome. It never has.
  final bool liveProviderResult;

  /// Whether the check ran against a live credential store. It never did.
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
class Sprint117ApiKeyWorkflowAnchor {
  Sprint117ApiKeyWorkflowAnchor({
    required Map<String, String> declaredContractSizes,
    required Map<String, bool> boundariesDeclared,
    required this.secretGuaranteesDeclared,
    required this.neverPlaintextDeclared,
    required this.reauthBeforeSensitiveActionDeclared,
    required this.auditRedactionDeclared,
    required this.sensitiveActionsDeclared,
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

  /// Whether the product spec declares its secret guarantees at all.
  final bool secretGuaranteesDeclared;

  /// Whether `never_plaintext_database` is one of them.
  final bool neverPlaintextDeclared;

  /// Whether `reauth_before_sensitive_action` is one of them.
  final bool reauthBeforeSensitiveActionDeclared;

  /// Whether `audit_redaction` is one of them.
  final bool auditRedactionDeclared;

  /// Whether `reveal_or_replace_key` is listed as a sensitive action.
  final bool sensitiveActionsDeclared;

  /// How many external pins matched their recorded sha256.
  final int externalPinsMatched;

  /// How many external pins were readable and therefore comparable.
  final int externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117ApiKeyWorkflowContract.externalPins.length;

  bool get allExternalPinsMatch =>
      externalPinsResolved && externalPinsMatched == externalPinsChecked;
}

/// The decided-versus-observed input the gate reasons about.
class Sprint117ApiKeyWorkflowInput {
  const Sprint117ApiKeyWorkflowInput({
    this.rows,
    this.anchor,
    this.drillRun,
    this.externalPinDrift = false,
  });

  final List<Sprint117ApiKeyWorkflowCheck>? rows;
  final Sprint117ApiKeyWorkflowAnchor? anchor;
  final Sprint117ApiKeyWorkflowDrillRun? drillRun;

  /// Whether an external pin no longer matches what its manifest recorded.
  final bool externalPinDrift;
}

/// Whether a canonical acceptance could be satisfied by shipped code at all.
enum Sprint117ApiKeyWorkflowAcceptance { satisfied, mechanismAbsent }

/// One measured local observation behind a canonical check.
class Sprint117ApiKeyWorkflowObservation {
  Sprint117ApiKeyWorkflowObservation({
    required this.checkId,
    required this.outcome,
    required this.facts,
    required this.passed,
    this.acceptance = Sprint117ApiKeyWorkflowAcceptance.satisfied,
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
  final Sprint117ApiKeyWorkflowAcceptance acceptance;

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
class Sprint117ApiKeyWorkflowDrillRun {
  Sprint117ApiKeyWorkflowDrillRun({
    required List<Sprint117ApiKeyWorkflowObservation> observations,
    required this.liveProviderTouched,
    required this.userProjectTouched,
    required this.liveSecretObserved,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
    this.productionCallerPresent = true,
  }) : observations = List<Sprint117ApiKeyWorkflowObservation>.unmodifiable(
         observations,
       );

  final List<Sprint117ApiKeyWorkflowObservation> observations;

  /// Whether any OS credential store or provider endpoint was contacted.
  final bool liveProviderTouched;

  /// Whether any user project was opened. It never is.
  final bool userProjectTouched;

  /// Whether any real secret was observed. It never is.
  final bool liveSecretObserved;

  final int externalPinsMatched;
  final int externalPinsChecked;

  /// Whether any production file outside this acceptance harness imports the
  /// credential mechanisms the checks above exercise.
  ///
  /// Defaults to true so a hand-built run is never charged with an integration
  /// gap it never measured; only the repository scan can clear it.
  final bool productionCallerPresent;

  bool get allPassed => observations.every((entry) => entry.passed);

  bool get allExternalPinsMatchForDrill =>
      externalPinsChecked > 0 && externalPinsMatched == externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117ApiKeyWorkflowContract.externalPins.length;

  List<String> get acceptanceSatisfied => <String>[
    for (final entry in observations)
      if (entry.acceptance == Sprint117ApiKeyWorkflowAcceptance.satisfied)
        entry.checkId,
  ];

  List<String> get acceptanceUnmet => <String>[
    for (final entry in observations)
      if (entry.acceptance == Sprint117ApiKeyWorkflowAcceptance.mechanismAbsent)
        entry.checkId,
  ];

  List<String> get unresolvableReferences => <String>[
    for (final entry in observations) ...entry.unresolvable,
  ];

  Sprint117ApiKeyWorkflowObservation? observationFor(String checkId) {
    for (final entry in observations) {
      if (entry.checkId == checkId) return entry;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'live_provider_touched': liveProviderTouched,
    'user_project_touched': userProjectTouched,
    'live_secret_observed': liveSecretObserved,
    'external_pins_matched': externalPinsMatched,
    'external_pins_checked': externalPinsChecked,
    'production_caller_present': productionCallerPresent,
    'observations': <Map<String, Object?>>[
      for (final entry in observations) entry.toJson(),
    ],
  };
}

/// Reads the committed manifests and never invents a subject.
class Sprint117ApiKeyWorkflowLoader {
  const Sprint117ApiKeyWorkflowLoader();

  Sprint117ApiKeyWorkflowInput load() =>
      Sprint117ApiKeyWorkflowInput(rows: _loadRows(), anchor: _loadAnchor());

  /// Folds the measured drill into the committed record.
  Sprint117ApiKeyWorkflowInput loadWithDrill(
    Sprint117ApiKeyWorkflowDrillRun run,
  ) => Sprint117ApiKeyWorkflowInput(
    rows: _loadRows(run),
    anchor: _loadAnchor(),
    drillRun: run,
    // A run that could not read every pin cannot prove drift either; only a
    // readable pin that no longer matches is a contradiction.
    externalPinDrift:
        run.externalPinsResolved && !run.allExternalPinsMatchForDrill,
  );

  Sprint117ApiKeyWorkflowAnchor? _loadAnchor() {
    final declared = <String, String>{};
    final boundaries = <String, bool>{};
    Map<String, dynamic>? spec;
    var specPath = '';
    var declaredSubtrees = <String>{};
    for (final path in Sprint117ApiKeyWorkflowContract.sourceManifests) {
      final source = _readJsonFile(path);
      if (source == null) return null;
      declared[path] = _declaredContractSize(source);
      boundaries[path] = _declaresBoundary(source);
      if (path == Sprint117ApiKeyWorkflowContract.securityBilling) {
        // 115.54 records only the spec's *path* and the token subtrees it
        // reads; the secret guarantees themselves live in that file. Reading
        // `security_contract` out of 115.54 instead of out of the spec it
        // pins yields nothing, which would silently leave every guarantee
        // unmeasured.
        spec = Map<String, dynamic>.from(
          source['product_spec'] as Map<dynamic, dynamic>? ?? const {},
        );
        specPath = source['product_spec'] is Map<dynamic, dynamic>
            ? (source['product_spec'] as Map<dynamic, dynamic>)['path']
                      as String? ??
                  ''
            : '';
        declaredSubtrees = source['product_spec'] is Map<dynamic, dynamic>
            ? ((source['product_spec']
                              as Map<dynamic, dynamic>)['token_subtrees']
                          as List<dynamic>? ??
                      const <dynamic>[])
                  .map((e) => e.toString())
                  .toSet()
            : <String>{};
      }
    }
    if (spec == null) return null;

    var matched = 0;
    var checked = 0;
    for (final entry in Sprint117ApiKeyWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }

    // The guarantees themselves live in the file 115.54 pins, not in 115.54
    // itself, so they are read from there. The pin is measured separately in
    // the loop above; a drifted or unread spec therefore cannot report
    // guarantees it did not actually contain.
    final specFile = _readJsonFile(specPath);
    final secrets = specFile?['security_contract']?['secrets'];
    final sensitive = specFile?['security_contract']?['sensitive_actions'];
    // 115.54 names the subtrees it read; if it never named the ones this
    // validation depends on, the guarantees are undeclared regardless of
    // what the spec file happens to contain.
    final subtreesDeclared = <String>{
      'security_contract.secrets',
      'security_contract.sensitive_actions',
    }.every(declaredSubtrees.contains);

    return Sprint117ApiKeyWorkflowAnchor(
      declaredContractSizes: declared,
      boundariesDeclared: boundaries,
      secretGuaranteesDeclared:
          secrets is List && secrets.isNotEmpty && subtreesDeclared,
      neverPlaintextDeclared:
          secrets is List && secrets.contains('never_plaintext_database'),
      reauthBeforeSensitiveActionDeclared:
          secrets is List && secrets.contains('reauth_before_sensitive_action'),
      auditRedactionDeclared:
          secrets is List && secrets.contains('audit_redaction'),
      sensitiveActionsDeclared:
          sensitive is List && sensitive.contains('reveal_or_replace_key'),
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }

  List<Sprint117ApiKeyWorkflowCheck>? _loadRows([
    Sprint117ApiKeyWorkflowDrillRun? run,
  ]) {
    if (_loadAnchor() == null) return null;
    return <Sprint117ApiKeyWorkflowCheck>[
      for (final checkId in Sprint117ApiKeyWorkflowContract.requiredChecks)
        if (_defined(checkId))
          Sprint117ApiKeyWorkflowCheck(
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
    'add_replace' ||
    'validate' ||
    'revoke' ||
    'scope' ||
    'last_used' => Sprint117ApiKeyWorkflowContract.apiKeysManager,
    'mask' ||
    'secure_copy' ||
    'audit' ||
    'no_plaintext' => Sprint117ApiKeyWorkflowContract.secureTokenVault,
    _ => '',
  };

  /// The step this validation runs for a check.
  static String _method(String checkId) => switch (checkId) {
    'add_replace' =>
      'add a key, rotate its secret, and record that the stored material is '
          'the rotated one, the public view stays masked, and a refused '
          'rotation leaves both the old secret and its validation untouched',
    'validate' =>
      'validate a good and a bad key, then refuse reauthentication at the '
          'gate and record that the refusal is a decided result with a '
          'timestamp and an audit row rather than an untouched key',
    'mask' =>
      'render the public view of a key and record that neither the metadata '
          'nor its JSON projection contains the secret or a masked prefix of it',
    'scope' =>
      'add keys with disjoint scopes and record that each key keeps its own '
          'scope set unmodifiable, that the validator receives that exact set, '
          'and that an empty or duplicated scope set is refused',
    'secure_copy' =>
      'copy a secret to the clipboard with and without reauthentication and '
          'record that the copy is refused before the value is read when the '
          'gate refuses',
    'revoke' =>
      'revoke a key and record that the stored material is gone, the key is '
          'inert for every later action, and any clipboard copy of the revoked '
          'secret is wiped at the revoke rather than left to the timeout',
    'audit' =>
      'walk every action the manager can take and record that each one emits '
          'exactly one audit row whose fields carry no secret material',
    'no_plaintext' =>
      'store a secret through the encrypted credential store and record that '
          'the bytes at rest contain neither the secret nor a fragment of it, '
          'and that every audit row, public view, and masked display omits it',
    'last_used' =>
      'mark a key as used and record that the stamp appears on the key '
          'metadata only after that call, never before, and never carries the '
          'secret it recorded having been read',
    _ => '',
  };

  /// What the method is expected to produce locally.
  static String _expectedOutcome(String checkId) => switch (checkId) {
    'add_replace' =>
      'a rotated key serves the new secret, its public view stays masked, and '
          'a refused rotation changes nothing',
    'validate' =>
      'a validation is decided, timestamped, and audited even when the '
          'reauthentication gate refuses it',
    'mask' => 'a key is never rendered as its secret',
    'scope' =>
      'a key carries exactly the scopes it was added with and cannot be '
          'widened afterwards',
    'secure_copy' =>
      'a secret is copied only after reauthentication and never when the gate '
          'refuses',
    'revoke' =>
      'a revoked key keeps no stored secret, no usable clipboard copy, and no '
          'working action',
    'audit' => 'every action emits one audit row that carries no secret',
    'no_plaintext' =>
      'no credential is at rest or in a public view as readable plaintext',
    'last_used' =>
      'a use is stamped on the key metadata and that stamp never exposes the '
          'secret',
    _ => '',
  };

  /// How many contract items a source declares, or empty when it declares
  /// none.
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

/// Decides whether the recorded credential evidence is coherent.
class Sprint117ApiKeyWorkflowGate {
  const Sprint117ApiKeyWorkflowGate();

  /// Runs the drill, then decides from its measured output.
  Future<Sprint117ApiKeyWorkflowReport> evaluateWithDrill([
    Sprint117ApiKeyWorkflowDrillRun? run,
  ]) async {
    final measured = run ?? await const Sprint117ApiKeyWorkflowDrill().run();
    return evaluateWith(
      const Sprint117ApiKeyWorkflowLoader().loadWithDrill(measured),
    );
  }

  Sprint117ApiKeyWorkflowReport evaluate() =>
      evaluateWith(const Sprint117ApiKeyWorkflowLoader().load());

  Sprint117ApiKeyWorkflowReport evaluateWith(
    Sprint117ApiKeyWorkflowInput input,
  ) {
    final missing = <String>{};
    final violations = <String>{};

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('api_key_anchor');
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
      if (!anchor.secretGuaranteesDeclared) {
        missing.add('secret_guarantees_acceptance');
      }
      if (!anchor.neverPlaintextDeclared) {
        missing.add('never_plaintext_acceptance');
      }
      if (!anchor.reauthBeforeSensitiveActionDeclared) {
        missing.add('reauth_before_sensitive_action_acceptance');
      }
      if (!anchor.auditRedactionDeclared) {
        missing.add('audit_redaction_acceptance');
      }
      if (!anchor.sensitiveActionsDeclared) {
        missing.add('reveal_or_replace_key_sensitive_action');
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
                Sprint117ApiKeyWorkflowAcceptance.satisfied) {
          violations.add(
            'acceptance_claimed_without_mechanism:${observation.checkId}',
          );
        }
      }
    }

    final rows = input.rows;
    final rowIds = <String>{};
    final checks = <Sprint117ApiKeyWorkflowCheck>[];
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
    if (anchor != null && !missing.contains('api_key_anchor')) {
      for (final checkId in Sprint117ApiKeyWorkflowContract.requiredChecks) {
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
        anchor != null && !missing.contains('api_key_anchor');
    var decidedCount = 0;
    for (final row in checks) {
      if (row.executed && anchorResolved) decidedCount += 1;
    }
    final total = Sprint117ApiKeyWorkflowContract.requiredChecks.length;
    final coverage = total == 0 ? 0.0 : decidedCount / total;

    final complete = missing.isEmpty && violations.isEmpty;
    final state = violations.isNotEmpty
        ? Sprint117ApiKeyWorkflowState.fail
        : (complete
              ? Sprint117ApiKeyWorkflowState.pass
              : Sprint117ApiKeyWorkflowState.blocked);

    return Sprint117ApiKeyWorkflowReport(
      status: state,
      verdict: switch (state) {
        Sprint117ApiKeyWorkflowState.pass =>
          Sprint117ApiKeyWorkflowContract.passVerdict,
        Sprint117ApiKeyWorkflowState.fail =>
          Sprint117ApiKeyWorkflowContract.failVerdict,
        Sprint117ApiKeyWorkflowState.blocked =>
          Sprint117ApiKeyWorkflowContract.blockedVerdict,
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
    Sprint117ApiKeyWorkflowCheck row,
    Sprint117ApiKeyWorkflowDrillRun? drillRun,
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
    Sprint117ApiKeyWorkflowDrillRun? drillRun,
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
      // harness imports the credential manager or its vault, so every check
      // above exercises code no user path reaches. The mechanisms are
      // declared and correct; they are simply not wired to anything yet.
      // A run without a drill measured nothing, so it claims nothing.
      if (drillRun != null && !drillRun.productionCallerPresent)
        'no_shipped_consumer_for_credential_managers',
      'api_key_workflow_defined_not_executed_live',
      'external_credential_specs_outside_repository',
    };
    return items.toList(growable: false)..sort();
  }
}

/// The gate's verdict, with the evidence it decided from.
class Sprint117ApiKeyWorkflowReport {
  Sprint117ApiKeyWorkflowReport({
    required this.status,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required List<String> unmappedChecks,
    required List<String> undeterminedChecks,
    required this.coverage,
    required List<String> acceptanceSatisfied,
    required List<String> acceptanceUnmet,
    required List<Sprint117ApiKeyWorkflowCheck> checks,
    required this.anchor,
    required List<String> openItems,
  }) : acceptanceSatisfied = List<String>.unmodifiable(acceptanceSatisfied),
       acceptanceUnmet = List<String>.unmodifiable(acceptanceUnmet),
       missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       unmappedChecks = List<String>.unmodifiable(unmappedChecks),
       undeterminedChecks = List<String>.unmodifiable(undeterminedChecks),
       checks = List<Sprint117ApiKeyWorkflowCheck>.unmodifiable(checks),
       openItems = List<String>.unmodifiable(openItems);

  final Sprint117ApiKeyWorkflowState status;

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

  final List<Sprint117ApiKeyWorkflowCheck> checks;
  final Sprint117ApiKeyWorkflowAnchor? anchor;

  /// What this report leaves open, including every deferred external gate.
  final List<String> openItems;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117ApiKeyWorkflowContract.canonicalStep,
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
            'never_plaintext_declared': anchor!.neverPlaintextDeclared,
            'reauth_before_sensitive_action_declared':
                anchor!.reauthBeforeSensitiveActionDeclared,
            'audit_redaction_declared': anchor!.auditRedactionDeclared,
            'sensitive_actions_declared': anchor!.sensitiveActionsDeclared,
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
