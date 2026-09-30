/// Canonical step 117.13 — Cloud Storage & Quota Validation.
///
/// Objective (external canonical JSON): test quota accuracy, units,
/// freshness, partial totals, unavailable values, local separation, and
/// refresh.
///
/// The seven evidence names are properties of numbers a user is shown, so the
/// check and the drill are deliberately separate classes, exactly as
/// 117.5-117.12 did:
///
/// * [Sprint117CloudStorageQuotaDrill] really executes the shipped mechanisms:
///   [ProviderQuotaReading]'s raw-bytes contract, the [ProviderQuotaResult]
///   freshness and unavailable states, the [CloudStorageAggregation] partial
///   and stale reductions, [StorageUsageCardData]'s display units, the
///   [AccountCenterStorageDistributionReport] local/remote separation, and
///   [LocalStorageSummary]'s refusal to combine local with cloud. It writes
///   nothing and contacts no provider.
/// * [Sprint117CloudStorageQuotaLoader] reads the committed manifests and the
///   external files they pin, and never invents a check or an outcome.
/// * [Sprint117CloudStorageQuotaGate] decides whether the recorded evidence is
///   coherent, synchronously and without side effects.
///
/// Two facts are measured rather than assumed, and both shape the verdict:
///
/// 1. No shipped code reads a provider. [ProviderQuotaAdapter] has zero
///    implementations in `lib/` — the only one in the repository is declared
///    inside a test — so no quota in this validation came from a provider API.
///    Every byte value here is fixture data that entered through the shipped
///    contracts, which is what `provider_api_values` can honestly mean today.
/// 2. The freshness of a multi-provider total was wrong until this step. The
///    shipped reduction kept the *oldest* included reading, so a total built
///    from accounts measured at different instants was dated to a measurement
///    no included account produced. The drill re-measures that reduction
///    directly, so a regression in either direction fails here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:void_scriptor/features/account/domain/account_center_cloud_storage_aggregation.dart';
import 'package:void_scriptor/features/account/domain/account_center_local_storage_summary.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_quota_adapter.dart';
import 'package:void_scriptor/features/account/domain/account_center_storage_distribution_report.dart';
import 'package:void_scriptor/features/account/domain/account_center_storage_usage_card.dart';

part 'sprint_117_cloud_storage_quota_drill.dart';

enum Sprint117CloudStorageQuotaState { pass, fail, blocked }

/// Immutable description of the contract, its sources, and its verdicts.
abstract final class Sprint117CloudStorageQuotaContract {
  static const String canonicalStep = '117.13';

  /// 115.16 supplies the account model whose quota capability decides which
  /// provider can report a quota at all.
  static const String cloudAccountModel =
      'docs/planning/v1.2/sprint_115_cloud_storage_account_model.json';

  /// 115.17 supplies the raw-bytes quota reading and its fresh/stale/
  /// unavailable states.
  static const String quotaAdapters =
      'docs/planning/v1.2/sprint_115_provider_quota_adapters.json';

  /// 115.18 supplies the remote-only total, its partial and stale indicators,
  /// and `last_updated`.
  static const String aggregation =
      'docs/planning/v1.2/sprint_115_cloud_storage_aggregation.json';

  /// 115.19 supplies the display units, the unknown-quota state, and the
  /// freshness label a card renders.
  static const String usageCards =
      'docs/planning/v1.2/sprint_115_storage_usage_cards.json';

  /// 115.20 supplies the local scan summary and the rule that local bytes are
  /// never combined with cloud quota.
  static const String localSummary =
      'docs/planning/v1.2/sprint_115_local_storage_summary.json';

  /// 115.41 supplies the remote/local filter and the merged-total warning that
  /// keeps both scopes distinguishable.
  static const String distribution =
      'docs/planning/v1.2/sprint_115_storage_distribution_chart_table.json';

  /// Every committed source this validation decides from.
  static const List<String> sourceManifests = <String>[
    cloudAccountModel,
    quotaAdapters,
    aggregation,
    usageCards,
    localSummary,
    distribution,
  ];

  /// 115.18's own freshness acceptance, drilled verbatim.
  static const String lastUpdatedAcceptance = 'last_updated';

  /// 115.20's own separation acceptance, drilled verbatim.
  static const String freeSpaceAcceptance = 'free_space';

  static const String passVerdict = 'CLOUD_STORAGE_QUOTA_VALIDATED_LOCAL';
  static const String blockedVerdict =
      'CLOUD_STORAGE_QUOTA_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'CLOUD_STORAGE_QUOTA_INCONSISTENT';

  /// The seven evidence items canonical step 117.13 names, in canonical order.
  static const List<String> requiredChecks = <String>[
    'provider_api_values',
    'raw_bytes',
    'display_units',
    'freshness',
    'partial_total',
    'unavailable',
    'local_separation',
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
class Sprint117CloudStorageQuotaCheck {
  Sprint117CloudStorageQuotaCheck({
    required this.checkId,
    required this.method,
    required this.expectedOutcome,
    required this.observedOutcome,
    required this.sourceManifest,
    required this.liveProviderResult,
    required this.drilledAgainstLiveProvider,
  });

  /// The canonical check identity, e.g. `raw_bytes`.
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
class Sprint117CloudStorageQuotaAnchor {
  Sprint117CloudStorageQuotaAnchor({
    required Map<String, String> declaredContractSizes,
    required Map<String, bool> boundariesDeclared,
    required this.lastUpdatedAcceptanceDeclared,
    required this.freeSpaceAcceptanceDeclared,
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

  /// Whether 115.18 records the `last_updated` acceptance this validation
  /// drills.
  final bool lastUpdatedAcceptanceDeclared;

  /// Whether 115.20 records the `free_space` acceptance that keeps free disk
  /// space outside the used total.
  final bool freeSpaceAcceptanceDeclared;

  /// How many external pins matched their recorded sha256.
  final int externalPinsMatched;

  /// How many external pins were readable and therefore comparable.
  final int externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117CloudStorageQuotaContract.externalPins.length;

  bool get allExternalPinsMatch =>
      externalPinsResolved && externalPinsMatched == externalPinsChecked;
}

/// The decided-versus-observed input the gate reasons about.
class Sprint117CloudStorageQuotaInput {
  const Sprint117CloudStorageQuotaInput({
    this.rows,
    this.anchor,
    this.drillRun,
    this.externalPinDrift = false,
  });

  final List<Sprint117CloudStorageQuotaCheck>? rows;
  final Sprint117CloudStorageQuotaAnchor? anchor;
  final Sprint117CloudStorageQuotaDrillRun? drillRun;

  /// Whether an external pin no longer matches what its manifest recorded.
  final bool externalPinDrift;
}

/// Whether a canonical acceptance could be satisfied by shipped code at all.
enum Sprint117CloudStorageQuotaAcceptance { satisfied, mechanismAbsent }

/// One measured local observation behind a canonical check.
class Sprint117CloudStorageQuotaObservation {
  Sprint117CloudStorageQuotaObservation({
    required this.checkId,
    required this.outcome,
    required this.facts,
    required this.passed,
    this.acceptance = Sprint117CloudStorageQuotaAcceptance.satisfied,
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
  final Sprint117CloudStorageQuotaAcceptance acceptance;

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
class Sprint117CloudStorageQuotaDrillRun {
  Sprint117CloudStorageQuotaDrillRun({
    required List<Sprint117CloudStorageQuotaObservation> observations,
    required this.liveProviderTouched,
    required this.userProjectTouched,
    required this.liveSecretObserved,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
  }) : observations = List<Sprint117CloudStorageQuotaObservation>.unmodifiable(
         observations,
       );

  final List<Sprint117CloudStorageQuotaObservation> observations;

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
      Sprint117CloudStorageQuotaContract.externalPins.length;

  List<String> get acceptanceSatisfied => <String>[
    for (final entry in observations)
      if (entry.acceptance == Sprint117CloudStorageQuotaAcceptance.satisfied)
        entry.checkId,
  ];

  List<String> get acceptanceUnmet => <String>[
    for (final entry in observations)
      if (entry.acceptance ==
          Sprint117CloudStorageQuotaAcceptance.mechanismAbsent)
        entry.checkId,
  ];

  List<String> get unresolvableReferences => <String>[
    for (final entry in observations) ...entry.unresolvable,
  ];

  Sprint117CloudStorageQuotaObservation? observationFor(String checkId) {
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
class Sprint117CloudStorageQuotaLoader {
  const Sprint117CloudStorageQuotaLoader();

  Sprint117CloudStorageQuotaInput load() =>
      Sprint117CloudStorageQuotaInput(rows: _loadRows(), anchor: _loadAnchor());

  /// Folds the measured drill into the committed record.
  Sprint117CloudStorageQuotaInput loadWithDrill(
    Sprint117CloudStorageQuotaDrillRun run,
  ) => Sprint117CloudStorageQuotaInput(
    rows: _loadRows(run),
    anchor: _loadAnchor(),
    drillRun: run,
    // A run that could not read every pin cannot prove drift either; only a
    // readable pin that no longer matches is a contradiction.
    externalPinDrift:
        run.externalPinsResolved && !run.allExternalPinsMatchForDrill,
  );

  Sprint117CloudStorageQuotaAnchor? _loadAnchor() {
    final declared = <String, String>{};
    final boundaries = <String, bool>{};
    Map<String, dynamic>? aggregation;
    Map<String, dynamic>? localSummary;
    for (final path in Sprint117CloudStorageQuotaContract.sourceManifests) {
      final source = _readJsonFile(path);
      if (source == null) return null;
      declared[path] = _declaredContractSize(source);
      boundaries[path] = _declaresBoundary(source);
      if (path == Sprint117CloudStorageQuotaContract.aggregation) {
        aggregation = source;
      }
      if (path == Sprint117CloudStorageQuotaContract.localSummary) {
        localSummary = source;
      }
    }
    if (aggregation == null || localSummary == null) return null;

    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117CloudStorageQuotaContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }

    return Sprint117CloudStorageQuotaAnchor(
      declaredContractSizes: declared,
      boundariesDeclared: boundaries,
      lastUpdatedAcceptanceDeclared: _declaresAcceptance(
        aggregation,
        Sprint117CloudStorageQuotaContract.lastUpdatedAcceptance,
      ),
      freeSpaceAcceptanceDeclared: _declaresAcceptance(
        localSummary,
        Sprint117CloudStorageQuotaContract.freeSpaceAcceptance,
      ),
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }

  List<Sprint117CloudStorageQuotaCheck>? _loadRows([
    Sprint117CloudStorageQuotaDrillRun? run,
  ]) {
    if (_loadAnchor() == null) return null;
    return <Sprint117CloudStorageQuotaCheck>[
      for (final checkId in Sprint117CloudStorageQuotaContract.requiredChecks)
        if (_defined(checkId))
          Sprint117CloudStorageQuotaCheck(
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

  /// A check exists only where its source records a contract. The whole
  /// 115 storage family declares `acceptance`, so one key reads all of them;
  /// `_declaredContractSize` still accepts the other spellings so a future
  /// manifest cannot silently read as undeclared.
  static bool _defined(String checkId) {
    final source = _readJsonFile(_sourceFor(checkId));
    if (source == null) return false;
    return _declaredContractSize(source).isNotEmpty;
  }

  /// The committed manifest that owns a check.
  static String _sourceFor(String checkId) => switch (checkId) {
    'provider_api_values' =>
      Sprint117CloudStorageQuotaContract.cloudAccountModel,
    'raw_bytes' ||
    'freshness' ||
    'partial_total' ||
    'unavailable' => Sprint117CloudStorageQuotaContract.quotaAdapters,
    'display_units' => Sprint117CloudStorageQuotaContract.usageCards,
    'local_separation' => Sprint117CloudStorageQuotaContract.localSummary,
    _ => '',
  };

  /// The step this validation runs for a check.
  static String _method(String checkId) => switch (checkId) {
    'provider_api_values' =>
      'count the shipped ProviderQuotaAdapter implementations in lib/ and record '
          'the quota_support capability each cloud account model declares',
    'raw_bytes' =>
      'construct provider readings with raw byte counts and a provider unit, '
          'and record the byte totals the aggregation derives',
    'display_units' =>
      'render provider byte counts and an unknown quota through the shipped '
          'storage-unit formatter and the usage card',
    'freshness' =>
      'measure readings inside and outside the stale window, aggregate them, '
          'and read back the freshness label and last_updated value',
    'partial_total' =>
      'aggregate a mix of included, unavailable, and provider-defined-unit '
          'readings and record the partial status, totals, and exclusions',
    'unavailable' =>
      'request an unavailable reading and confirm no total, unit label, or '
          'percentage is fabricated in its place',
    'local_separation' =>
      'scan local storage, filter the distribution to each scope, and confirm '
          'local bytes never enter a cloud quota total and free space is never '
          'added to a used total',
    _ => '',
  };

  /// What the step is expected to produce locally.
  static String _expectedOutcome(String checkId) => switch (checkId) {
    'provider_api_values' =>
      'no shipped adapter reads a provider, and quota support is recorded as '
          'a declared capability rather than a fetched value',
    'raw_bytes' =>
      'provider byte counts are preserved exactly and summed without a unit '
          'conversion the provider did not report',
    'display_units' =>
      'byte counts render in decimal units and an unknown quota renders as '
          'unavailable rather than zero',
    'freshness' =>
      'a reading inside the window is fresh, one outside it is stale, and an '
          'aggregate is dated by its newest included measurement',
    'partial_total' =>
      'a total with excluded accounts is partial and names them, and a total '
          'with no compatible reading is unavailable rather than zero',
    'unavailable' =>
      'an unavailable provider yields no bytes, no quota, and no percentage',
    'local_separation' =>
      'local and remote totals stay separable, a merged total is labelled and '
          'warned, and free space is never added to a used total',
    _ => '',
  };

  /// How many contract items a source declares, or empty when it declares
  /// none.
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

  /// Whether a source states where its own evidence stops. The 115 storage
  /// family spells that `boundary`; the other 115 spellings are accepted so a
  /// real subject is never reported as undeclared.
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

  /// Whether a source records one named acceptance item verbatim.
  static bool _declaresAcceptance(
    Map<String, dynamic> source,
    String acceptance,
  ) {
    final declared = source['acceptance'];
    if (declared is! List<dynamic>) return false;
    for (final item in declared) {
      if (item is String && item.trim() == acceptance) return true;
    }
    return false;
  }
}

/// Decides whether the recorded quota evidence is coherent.
class Sprint117CloudStorageQuotaGate {
  const Sprint117CloudStorageQuotaGate();

  /// Runs the drill, then decides from its measured output.
  Future<Sprint117CloudStorageQuotaReport> evaluateWithDrill([
    Sprint117CloudStorageQuotaDrillRun? run,
  ]) async {
    final measured = run ?? await const Sprint117CloudStorageQuotaDrill().run();
    return evaluateWith(
      const Sprint117CloudStorageQuotaLoader().loadWithDrill(measured),
    );
  }

  Sprint117CloudStorageQuotaReport evaluate() =>
      evaluateWith(const Sprint117CloudStorageQuotaLoader().load());

  Sprint117CloudStorageQuotaReport evaluateWith(
    Sprint117CloudStorageQuotaInput input,
  ) {
    final missing = <String>{};
    final violations = <String>{};

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('quota_anchor');
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
      if (!anchor.lastUpdatedAcceptanceDeclared) {
        missing.add(
          'aggregation_last_updated_acceptance:'
          '${Sprint117CloudStorageQuotaContract.lastUpdatedAcceptance}',
        );
      }
      if (!anchor.freeSpaceAcceptanceDeclared) {
        missing.add(
          'local_free_space_acceptance:'
          '${Sprint117CloudStorageQuotaContract.freeSpaceAcceptance}',
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
                Sprint117CloudStorageQuotaAcceptance.satisfied) {
          violations.add(
            'acceptance_claimed_without_mechanism:${observation.checkId}',
          );
        }
      }
    }

    final rows = input.rows;
    final rowIds = <String>{};
    final checks = <Sprint117CloudStorageQuotaCheck>[];
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
    if (anchor != null && !missing.contains('quota_anchor')) {
      for (final checkId in Sprint117CloudStorageQuotaContract.requiredChecks) {
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
    final total = Sprint117CloudStorageQuotaContract.requiredChecks.length;
    final coverage = total == 0 ? 0.0 : decidedCount / total;

    final complete = missing.isEmpty && violations.isEmpty;
    final state = violations.isNotEmpty
        ? Sprint117CloudStorageQuotaState.fail
        : (complete
              ? Sprint117CloudStorageQuotaState.pass
              : Sprint117CloudStorageQuotaState.blocked);

    return Sprint117CloudStorageQuotaReport(
      status: state,
      verdict: switch (state) {
        Sprint117CloudStorageQuotaState.pass =>
          Sprint117CloudStorageQuotaContract.passVerdict,
        Sprint117CloudStorageQuotaState.fail =>
          Sprint117CloudStorageQuotaContract.failVerdict,
        Sprint117CloudStorageQuotaState.blocked =>
          Sprint117CloudStorageQuotaContract.blockedVerdict,
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
    Sprint117CloudStorageQuotaCheck row,
    Sprint117CloudStorageQuotaDrillRun? drillRun,
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
    Sprint117CloudStorageQuotaDrillRun? drillRun,
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
      'quota_defined_not_executed_live',
      'external_storage_specs_outside_repository',
    };
    return items.toList(growable: false)..sort();
  }
}

/// The gate's verdict, with the evidence it decided from.
class Sprint117CloudStorageQuotaReport {
  Sprint117CloudStorageQuotaReport({
    required this.status,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required List<String> unmappedChecks,
    required List<String> undeterminedChecks,
    required this.coverage,
    required List<String> acceptanceSatisfied,
    required List<String> acceptanceUnmet,
    required List<Sprint117CloudStorageQuotaCheck> checks,
    required this.anchor,
    required List<String> openItems,
  }) : acceptanceSatisfied = List<String>.unmodifiable(acceptanceSatisfied),
       acceptanceUnmet = List<String>.unmodifiable(acceptanceUnmet),
       missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       unmappedChecks = List<String>.unmodifiable(unmappedChecks),
       undeterminedChecks = List<String>.unmodifiable(undeterminedChecks),
       checks = List<Sprint117CloudStorageQuotaCheck>.unmodifiable(checks),
       openItems = List<String>.unmodifiable(openItems);

  final Sprint117CloudStorageQuotaState status;

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

  final List<Sprint117CloudStorageQuotaCheck> checks;
  final Sprint117CloudStorageQuotaAnchor? anchor;

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

extension on Sprint117CloudStorageQuotaAnchor {
  Map<String, Object?> toJson() => <String, Object?>{
    'declared_contract_sizes': Map<String, String>.from(declaredContractSizes),
    'boundaries_declared': Map<String, bool>.from(boundariesDeclared),
    'last_updated_acceptance_declared': lastUpdatedAcceptanceDeclared,
    'free_space_acceptance_declared': freeSpaceAcceptanceDeclared,
    'external_pins_matched': externalPinsMatched,
    'external_pins_checked': externalPinsChecked,
    'external_pins_resolved': externalPinsResolved,
  };
}

extension on Sprint117CloudStorageQuotaDrillRun {
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
