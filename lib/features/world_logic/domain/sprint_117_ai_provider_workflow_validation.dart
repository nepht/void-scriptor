/// Canonical step 117.15 — AI Provider Workflow Validation.
///
/// Objective (external canonical JSON): test connect, model discovery,
/// execution, cancellation, usage, cost, privacy destination, fallback, and
/// errors.
///
/// The nine evidence names are properties a user can lose money or privacy
/// over, so the check and the drill are deliberately separate classes, exactly
/// as 117.5-117.14 did:
///
/// * [Sprint117AiProviderWorkflowDrill] really executes the shipped AI
///   mechanisms: the [OpenAiProvider] credential gate, [AiProviderHealthProbe]
///   health probe, [AiModelRegistry] discovery with its offline cache
///   fallback, the [ProviderRouter] fallback chain, the [GenerationQueue]
///   priority/cancel/retry behaviour, the [AiProviderRateLimiter] window and
///   retry-after, the [AiProviderWithTimeout] deadline, the
///   [AiProviderCostPolicy] cheapest-capable selection, the
///   [AiWorkflowIntegration] cost attribution, and the
///   [AutomationNetworkPolicy] deny-by-default destination gate. It writes
///   nothing and contacts no provider.
/// * [Sprint117AiProviderWorkflowLoader] reads the committed manifests and the
///   external files they pin, and never invents a check or an outcome.
/// * [Sprint117AiProviderWorkflowGate] decides whether the recorded evidence is
///   coherent, synchronously and without side effects.
///
/// Two facts are measured rather than assumed, and both shape the verdict:
///
/// 1. This step found and fixed a real defect. [AiWorkflowIntegration] booked
///    every call against the provider it ASKED for (`preferredProviderId ??
///    'auto'`) rather than the one that served it, so a request that fell back
///    to a second provider was charged to a provider that produced nothing; and
///    its own `costOf` field was accepted and stored but never read, so every
///    automated AI call reported zero cost. The drill re-measures both, so a
///    regression in either direction fails here.
/// 2. No shipped code records AI usage or price. [AiUsageLogRepository] is
///    read by the account metrics screen but has no writer anywhere in `lib/`,
///    and the pricing surface returns a constant. `usage` and `cost` are
///    therefore recorded as `acceptance_unmet` with the exact reason rather than
///    folded into a passing row.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:void_scriptor/automation/automation_condition.dart';
import 'package:void_scriptor/automation/automation_rule.dart';
import 'package:void_scriptor/automation/external_integrations.dart';
import 'package:void_scriptor/automation/workflow_trigger.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/ai/application/ai_model_registry.dart';
import 'package:void_scriptor/features/ai/application/generation_queue.dart';
import 'package:void_scriptor/features/ai/application/model_catalog_repository.dart';
import 'package:void_scriptor/features/ai/application/provider_cost_policy.dart';
import 'package:void_scriptor/features/ai/application/provider_diagnostics.dart';
import 'package:void_scriptor/features/ai/application/provider_health.dart';
import 'package:void_scriptor/features/ai/application/provider_rate_limiter.dart';
import 'package:void_scriptor/features/ai/application/provider_router.dart';
import 'package:void_scriptor/features/ai/application/provider_timeout.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/generation_job.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/openai/openai_provider.dart';

part 'sprint_117_ai_provider_workflow_drill.dart';

enum Sprint117AiProviderWorkflowState { pass, fail, blocked }

/// Immutable description of the contract, its sources, and its verdicts.
abstract final class Sprint117AiProviderWorkflowContract {
  static const String canonicalStep = '117.15';

  /// 115.25 supplies connect, model select, fallback, timeout, budget,
  /// prefer-local, and the health-test contract this step drills from the
  /// execution side.
  static const String connectionModelSettings =
      'docs/planning/v1.2/sprint_115_ai_connection_model_settings.json';

  /// 115.24 supplies the eight provider-registry fields, including
  /// `pricing_metadata` and `privacy_metadata`, which are what `cost` and
  /// `privacy_destination` are measured against.
  static const String providerRegistry =
      'docs/planning/v1.2/sprint_115_ai_provider_registry.json';

  /// 115.26 supplies `provider_usage`, `estimated_label`, and
  /// `unavailable_state`, which is what `usage` is measured against.
  static const String usageCreditsCostView =
      'docs/planning/v1.2/sprint_115_ai_usage_credits_cost_view.json';

  /// 116.42 supplies the eight required error states, which is what `errors`
  /// is measured against.
  static const String providerErrorStates =
      'docs/planning/v1.2/sprint_116_provider_error_state_certification.json';

  /// 116.26 supplies model discovery, privacy, and offline use for the local
  /// provider, which is the offline half of `models` and `privacy_destination`.
  static const String localAiCertification =
      'docs/planning/v1.2/sprint_116_local_ai_certification.json';

  /// Every committed source this validation decides from.
  static const List<String> sourceManifests = <String>[
    connectionModelSettings,
    providerRegistry,
    usageCreditsCostView,
    providerErrorStates,
    localAiCertification,
  ];

  /// 116.42's own live-verification flag. This step never sets it.
  static const String liveProviderVerification = 'live_provider_verification';

  static const String passVerdict = 'AI_PROVIDER_WORKFLOW_VALIDATED_LOCAL';
  static const String blockedVerdict =
      'AI_PROVIDER_WORKFLOW_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'AI_PROVIDER_WORKFLOW_INCONSISTENT';

  /// The nine evidence items canonical step 117.15 names, in canonical order.
  static const List<String> requiredChecks = <String>[
    'connect',
    'models',
    'execution',
    'cancellation',
    'usage',
    'cost',
    'privacy_destination',
    'fallback',
    'errors',
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
class Sprint117AiProviderWorkflowCheck {
  Sprint117AiProviderWorkflowCheck({
    required this.checkId,
    required this.method,
    required this.expectedOutcome,
    required this.observedOutcome,
    required this.sourceManifest,
    required this.liveProviderResult,
    required this.drilledAgainstLiveProvider,
  });

  /// The canonical check identity, e.g. `fallback`.
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
class Sprint117AiProviderWorkflowAnchor {
  Sprint117AiProviderWorkflowAnchor({
    required Map<String, String> declaredContractSizes,
    required Map<String, bool> boundariesDeclared,
    required this.localAiPrivacyDeclared,
    required this.errorStatesDeclared,
    required this.errorStatesCount,
    required this.localLiveVerificationClaimed,
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

  /// Whether 116.26 records a privacy field for the local provider.
  final bool localAiPrivacyDeclared;

  /// Whether 116.42 records the error states this validation drills.
  final bool errorStatesDeclared;

  /// How many error states 116.42 declares.
  final int errorStatesCount;

  /// Whether any committed source claims a live provider run. It never does.
  final bool localLiveVerificationClaimed;

  /// How many external pins matched their recorded sha256.
  final int externalPinsMatched;

  /// How many external pins were readable and therefore comparable.
  final int externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117AiProviderWorkflowContract.externalPins.length;

  bool get allExternalPinsMatch =>
      externalPinsResolved && externalPinsMatched == externalPinsChecked;
}

/// The decided-versus-observed input the gate reasons about.
class Sprint117AiProviderWorkflowInput {
  const Sprint117AiProviderWorkflowInput({
    this.rows,
    this.anchor,
    this.drillRun,
    this.externalPinDrift = false,
  });

  final List<Sprint117AiProviderWorkflowCheck>? rows;
  final Sprint117AiProviderWorkflowAnchor? anchor;
  final Sprint117AiProviderWorkflowDrillRun? drillRun;

  /// Whether an external pin no longer matches what its manifest recorded.
  final bool externalPinDrift;
}

/// Whether a canonical acceptance could be satisfied by shipped code at all.
enum Sprint117AiProviderWorkflowAcceptance { satisfied, mechanismAbsent }

/// One measured local observation behind a canonical check.
class Sprint117AiProviderWorkflowObservation {
  Sprint117AiProviderWorkflowObservation({
    required this.checkId,
    required this.outcome,
    required this.facts,
    required this.passed,
    this.acceptance = Sprint117AiProviderWorkflowAcceptance.satisfied,
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
  final Sprint117AiProviderWorkflowAcceptance acceptance;

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
class Sprint117AiProviderWorkflowDrillRun {
  Sprint117AiProviderWorkflowDrillRun({
    required List<Sprint117AiProviderWorkflowObservation> observations,
    required this.liveProviderTouched,
    required this.userProjectTouched,
    required this.liveSecretObserved,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
  }) : observations = List<Sprint117AiProviderWorkflowObservation>.unmodifiable(
         observations,
       );

  final List<Sprint117AiProviderWorkflowObservation> observations;

  /// Whether any provider endpoint was contacted. It never is.
  final bool liveProviderTouched;

  /// Whether any user project was opened. It never is.
  final bool userProjectTouched;

  /// Whether any real secret was observed. It never is.
  final bool liveSecretObserved;

  final int externalPinsMatched;
  final int externalPinsChecked;

  bool get allPassed => observations.every((entry) => entry.passed);

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117AiProviderWorkflowContract.externalPins.length;

  List<String> get acceptanceSatisfied => <String>[
    for (final entry in observations)
      if (entry.acceptance == Sprint117AiProviderWorkflowAcceptance.satisfied)
        entry.checkId,
  ];

  List<String> get acceptanceUnmet => <String>[
    for (final entry in observations)
      if (entry.acceptance ==
          Sprint117AiProviderWorkflowAcceptance.mechanismAbsent)
        entry.checkId,
  ];

  List<String> get unresolvableReferences => <String>[
    for (final entry in observations) ...entry.unresolvable,
  ];

  Sprint117AiProviderWorkflowObservation? observationFor(String checkId) {
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
    'observations': <Map<String, Object?>>[
      for (final entry in observations) entry.toJson(),
    ],
  };
}

/// Reads the committed manifests and never invents a subject.
class Sprint117AiProviderWorkflowLoader {
  const Sprint117AiProviderWorkflowLoader();

  Sprint117AiProviderWorkflowInput load() => Sprint117AiProviderWorkflowInput(
    rows: _loadRows(),
    anchor: _loadAnchor(),
  );

  /// Folds the measured drill into the committed record.
  Sprint117AiProviderWorkflowInput loadWithDrill(
    Sprint117AiProviderWorkflowDrillRun run,
  ) => Sprint117AiProviderWorkflowInput(
    rows: _loadRows(run),
    anchor: _loadAnchor(),
    drillRun: run,
    // A run that could not read every pin cannot prove drift either; only a
    // readable pin that no longer matches is a contradiction.
    externalPinDrift:
        run.externalPinsResolved && !run.allExternalPinsMatchForDrill,
  );

  Sprint117AiProviderWorkflowAnchor? _loadAnchor() {
    final declared = <String, String>{};
    final boundaries = <String, bool>{};
    Map<String, dynamic>? localAi;
    Map<String, dynamic>? errorStates;
    for (final path in Sprint117AiProviderWorkflowContract.sourceManifests) {
      final source = _readJsonFile(path);
      if (source == null) return null;
      declared[path] = _declaredContractSize(source);
      boundaries[path] = _declaresBoundary(source);
      if (path == Sprint117AiProviderWorkflowContract.localAiCertification) {
        localAi = source;
      }
      if (path == Sprint117AiProviderWorkflowContract.providerErrorStates) {
        errorStates = source;
      }
    }
    if (localAi == null || errorStates == null) return null;

    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117AiProviderWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }

    final requiredStates = errorStates['required_states'];
    final localFields = localAi['required_fields'];

    return Sprint117AiProviderWorkflowAnchor(
      declaredContractSizes: declared,
      boundariesDeclared: boundaries,
      localAiPrivacyDeclared:
          localFields is List<dynamic> && localFields.contains('privacy'),
      errorStatesDeclared:
          requiredStates is List<dynamic> && requiredStates.isNotEmpty,
      errorStatesCount: requiredStates is List<dynamic>
          ? requiredStates.length
          : 0,
      localLiveVerificationClaimed: _declaresLiveVerification(errorStates),
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }

  List<Sprint117AiProviderWorkflowCheck>? _loadRows([
    Sprint117AiProviderWorkflowDrillRun? run,
  ]) {
    if (_loadAnchor() == null) return null;
    return <Sprint117AiProviderWorkflowCheck>[
      for (final checkId in Sprint117AiProviderWorkflowContract.requiredChecks)
        if (_defined(checkId))
          Sprint117AiProviderWorkflowCheck(
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
    'connect' ||
    'fallback' => Sprint117AiProviderWorkflowContract.connectionModelSettings,
    'models' || 'privacy_destination' =>
      Sprint117AiProviderWorkflowContract.providerRegistry,
    'usage' ||
    'cost' => Sprint117AiProviderWorkflowContract.usageCreditsCostView,
    'errors' => Sprint117AiProviderWorkflowContract.providerErrorStates,
    'execution' ||
    'cancellation' => Sprint117AiProviderWorkflowContract.localAiCertification,
    _ => '',
  };

  /// The step this validation runs for a check.
  static String _method(String checkId) => switch (checkId) {
    'connect' =>
      'construct a provider with an empty credential store and record that '
          'every credentialed call is refused before any transport is built',
    'models' =>
      'list models from a live-shaped provider, cache them, then break the '
          'provider and record that discovery falls back to the cache and '
          'rethrows when the cache is empty',
    'execution' =>
      'queue a generation job, run the queue, and record the terminal status '
          'and that a failing job ends failed rather than silently dropped',
    'cancellation' =>
      'cancel a queued job and a running job and record that neither keeps '
          'producing output and that a cancelled job is not resurrected',
    'usage' =>
      'count the shipped writers of AI usage rows and record that a reader '
          'with no writer reports zero tokens rather than a provider number',
    'cost' =>
      'run an automated call with a configured price table and record that '
          'the cost line names the provider that served it, not the one '
          'requested',
    'privacy_destination' =>
      'gate an allowlisted and an unknown destination and record that the '
          'unknown one is denied by default and audited',
    'fallback' =>
      'fail the preferred provider and record that the next capable provider '
          'serves the request and is the provider cost and usage are booked to',
    'errors' =>
      'raise each transport error class a provider emits and record that the '
          'message never echoes credential material',
    _ => '',
  };

  /// What the method is expected to produce locally.
  static String _expectedOutcome(String checkId) => switch (checkId) {
    'connect' =>
      'a provider with no configured credential fails closed before any '
          'transport is used',
    'models' =>
      'model discovery returns the provider catalog and falls back to the '
          'cache when the provider is unreachable, rethrowing when no cache '
          'exists',
    'execution' =>
      'a queued job runs to completion and a failing job ends failed with its '
          'error recorded',
    'cancellation' =>
      'a cancelled job stops producing output and its result is never '
          'persisted',
    'usage' =>
      'a completed generation records its token usage against the provider '
          'that served it',
    'cost' =>
      'cost is attributed to the provider that served the call and is not '
          'invented when no price table is configured',
    'privacy_destination' =>
      'an unlisted destination is denied by default and every decision is '
          'audited',
    'fallback' =>
      'a failed preferred provider falls back to a capable provider and the '
          'fallback provider is the one charged',
    'errors' => 'a provider error surfaces without echoing credential material',
    _ => '',
  };

  /// How many contract items a source declares, or empty when it declares
  /// none. 116.42 spells its contract `required_states`, so that spelling is
  /// read too.
  static String _declaredContractSize(Map<String, dynamic> source) {
    for (final key in const <String>[
      'acceptance',
      'required_states',
      'required_outputs',
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
      'limitations_list',
    ]) {
      final value = source[key];
      if (value is List<dynamic> && value.isNotEmpty) return true;
      if (value is Map<String, dynamic> && value.isNotEmpty) return true;
    }
    return false;
  }

  /// Whether a source claims a live provider run. None of them may.
  static bool _declaresLiveVerification(Map<String, dynamic> source) {
    final value =
        source[Sprint117AiProviderWorkflowContract.liveProviderVerification];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}

/// Decides whether the recorded provider evidence is coherent.
class Sprint117AiProviderWorkflowGate {
  const Sprint117AiProviderWorkflowGate();

  /// Runs the drill, then decides from its measured output.
  Future<Sprint117AiProviderWorkflowReport> evaluateWithDrill([
    Sprint117AiProviderWorkflowDrillRun? run,
  ]) async {
    final measured =
        run ?? await const Sprint117AiProviderWorkflowDrill().run();
    return evaluateWith(
      const Sprint117AiProviderWorkflowLoader().loadWithDrill(measured),
    );
  }

  Sprint117AiProviderWorkflowReport evaluate() =>
      evaluateWith(const Sprint117AiProviderWorkflowLoader().load());

  Sprint117AiProviderWorkflowReport evaluateWith(
    Sprint117AiProviderWorkflowInput input,
  ) {
    final missing = <String>{};
    final violations = <String>{};

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('ai_provider_anchor');
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
      if (!anchor.localAiPrivacyDeclared) {
        missing.add('local_ai_privacy_acceptance');
      }
      if (!anchor.errorStatesDeclared) {
        missing.add(
          'error_states_acceptance:'
          '${Sprint117AiProviderWorkflowContract.providerErrorStates}',
        );
      }
      if (anchor.localLiveVerificationClaimed) {
        violations.add('live_provider_claim_in_source');
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
                Sprint117AiProviderWorkflowAcceptance.satisfied) {
          violations.add(
            'acceptance_claimed_without_mechanism:${observation.checkId}',
          );
        }
      }
    }

    final rows = input.rows;
    final rowIds = <String>{};
    final checks = <Sprint117AiProviderWorkflowCheck>[];
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
    if (anchor != null && !missing.contains('ai_provider_anchor')) {
      for (final checkId
          in Sprint117AiProviderWorkflowContract.requiredChecks) {
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
        anchor != null && !missing.contains('ai_provider_anchor');
    var decidedCount = 0;
    for (final row in checks) {
      if (row.executed && anchorResolved) decidedCount += 1;
    }
    final total = Sprint117AiProviderWorkflowContract.requiredChecks.length;
    final coverage = total == 0 ? 0.0 : decidedCount / total;

    final complete = missing.isEmpty && violations.isEmpty;
    final state = violations.isNotEmpty
        ? Sprint117AiProviderWorkflowState.fail
        : (complete
              ? Sprint117AiProviderWorkflowState.pass
              : Sprint117AiProviderWorkflowState.blocked);

    return Sprint117AiProviderWorkflowReport(
      status: state,
      verdict: switch (state) {
        Sprint117AiProviderWorkflowState.pass =>
          Sprint117AiProviderWorkflowContract.passVerdict,
        Sprint117AiProviderWorkflowState.fail =>
          Sprint117AiProviderWorkflowContract.failVerdict,
        Sprint117AiProviderWorkflowState.blocked =>
          Sprint117AiProviderWorkflowContract.blockedVerdict,
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
    Sprint117AiProviderWorkflowCheck row,
    Sprint117AiProviderWorkflowDrillRun? drillRun,
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
    Sprint117AiProviderWorkflowDrillRun? drillRun,
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
      'ai_provider_defined_not_executed_live',
      'external_ai_specs_outside_repository',
    };
    return items.toList(growable: false)..sort();
  }
}

/// The gate's verdict, with the evidence it decided from.
class Sprint117AiProviderWorkflowReport {
  Sprint117AiProviderWorkflowReport({
    required this.status,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required List<String> unmappedChecks,
    required List<String> undeterminedChecks,
    required this.coverage,
    required List<String> acceptanceSatisfied,
    required List<String> acceptanceUnmet,
    required List<Sprint117AiProviderWorkflowCheck> checks,
    required this.anchor,
    required List<String> openItems,
  }) : acceptanceSatisfied = List<String>.unmodifiable(acceptanceSatisfied),
       acceptanceUnmet = List<String>.unmodifiable(acceptanceUnmet),
       missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       unmappedChecks = List<String>.unmodifiable(unmappedChecks),
       undeterminedChecks = List<String>.unmodifiable(undeterminedChecks),
       checks = List<Sprint117AiProviderWorkflowCheck>.unmodifiable(checks),
       openItems = List<String>.unmodifiable(openItems);

  final Sprint117AiProviderWorkflowState status;

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

  final List<Sprint117AiProviderWorkflowCheck> checks;
  final Sprint117AiProviderWorkflowAnchor? anchor;

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

extension on Sprint117AiProviderWorkflowAnchor {
  Map<String, Object?> toJson() => <String, Object?>{
    'declared_contract_sizes': Map<String, String>.from(declaredContractSizes),
    'boundaries_declared': Map<String, bool>.from(boundariesDeclared),
    'local_ai_privacy_declared': localAiPrivacyDeclared,
    'error_states_declared': errorStatesDeclared,
    'error_states_count': errorStatesCount,
    'local_live_verification_claimed': localLiveVerificationClaimed,
    'external_pins_matched': externalPinsMatched,
    'external_pins_checked': externalPinsChecked,
    'external_pins_resolved': externalPinsResolved,
  };
}

extension on Sprint117AiProviderWorkflowDrillRun {
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
