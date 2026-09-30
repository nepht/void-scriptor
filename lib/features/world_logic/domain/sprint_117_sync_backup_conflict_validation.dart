/// Canonical step 117.14 — Sync, Backup & Conflict Validation.
///
/// Objective (external canonical JSON): test transfer, delta, retry, resume,
/// encrypted backup, restore, conflicts, large assets, and workspace
/// boundaries.
///
/// The eight evidence names are properties of state a user can lose, so the
/// check and the drill are deliberately separate classes, exactly as
/// 117.5-117.13 did:
///
/// * [Sprint117SyncBackupConflictDrill] really executes the shipped
///   mechanisms: the [CloudTransferRequest] consent gate, [CloudTransferState]
///   pause/resume/retry with its bounded retry limit, the [ConflictDetector]
///   three-way rule, the [ConflictResolver] merge, the
///   [AccountCenterSyncConflictCenter] backup-before-resolution gate, the
///   [AccountCenterBackupPolicy] encryption/destination rule, the
///   [BackupRetentionService] per-category pruning, and the workspace boundary
///   gates. It writes nothing and contacts no provider.
/// * [Sprint117SyncBackupConflictLoader] reads the committed manifests and the
///   external files they pin, and never invents a check or an outcome.
/// * [Sprint117SyncBackupConflictGate] decides whether the recorded evidence is
///   coherent, synchronously and without side effects.
///
/// Two facts are measured rather than assumed, and both shape the verdict:
///
/// 1. No shipped code performs a sync. `FolderCloudSyncService` is the only
///    filesystem-backed implementation and it exists to round-trip a JSON map
///    through one file per project; there is no delta protocol, no chunked
///    transfer, no encrypted archive, and no retry against a real endpoint.
///    `transfer`, `delta`, `encrypted_backup`, and `large_assets` are therefore
///    drilled against the contracts that describe them, and the ones that cannot
///    be satisfied are recorded as `acceptance_unmet` with the exact reason.
/// 2. The merge dropped every remote-only change. [ConflictResolver.resolve]
///    walked `ours` alone, so a key only the remote side changed was never
///    emitted: a remote edit was reverted to the base value the user had
///    already replaced, and a remote-only addition vanished with no trace. This
///    step fixes it and the drill re-measures it directly, so a regression in
///    either direction fails here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:void_scriptor/features/account/domain/account_center_backup_policy.dart';
import 'package:void_scriptor/features/account/domain/account_center_cloud_transfer_controls.dart';
import 'package:void_scriptor/features/account/domain/account_center_sync_conflict_center.dart';
import 'package:void_scriptor/features/account/domain/account_center_workspace_boundary_contract.dart';
import 'package:void_scriptor/features/collaboration/application/conflict_resolver.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_models.dart';
import 'package:void_scriptor/features/project_resilience/application/backup_retention_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_repository.dart';

part 'sprint_117_sync_backup_conflict_drill.dart';

enum Sprint117SyncBackupConflictState { pass, fail, blocked }

/// Immutable description of the contract, its sources, and its verdicts.
abstract final class Sprint117SyncBackupConflictContract {
  static const String canonicalStep = '117.14';

  /// 115.21 supplies upload, download, delta sync, pause, resume, retry,
  /// bandwidth, and the explicit transfer consent gate.
  static const String transferControls =
      'docs/planning/v1.2/sprint_115_cloud_transfer_sync_controls.json';

  /// 115.23 supplies conflict detection, version preview, keep-local,
  /// keep-remote, merge, history, and the backup-before-resolution gate.
  static const String conflictCenter =
      'docs/planning/v1.2/sprint_115_sync_conflict_center.json';

  /// 115.22 supplies schedule, retention, encryption, destination, the
  /// Novel/Character boundary, verification, and the restore test.
  static const String backupPolicies =
      'docs/planning/v1.2/sprint_115_backup_policies_destinations.json';

  /// 115.4 supplies the backup boundary separation and the cross-scope consent
  /// rule that keep account data out of workspace data.
  static const String workspaceBoundary =
      'docs/planning/v1.2/sprint_115_workspace_boundary_contract.json';

  /// 116.20 supplies the cross-storage record whose required outputs name
  /// delta, retry/resume, encrypted backup, restore, boundaries, and large
  /// assets — the same surface this step drills from the other side.
  static const String crossStorageCertification =
      'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json';

  /// Every committed source this validation decides from.
  static const List<String> sourceManifests = <String>[
    transferControls,
    conflictCenter,
    backupPolicies,
    workspaceBoundary,
    crossStorageCertification,
  ];

  /// 115.23's own backup-before-resolution acceptance, drilled verbatim.
  static const String backupBeforeResolutionAcceptance =
      'backup_before_resolution';

  /// 115.21's own explicit-consent acceptance, drilled verbatim.
  static const String explicitConsentAcceptance = 'explicit_transfer_consent';

  static const String passVerdict = 'SYNC_BACKUP_CONFLICT_VALIDATED_LOCAL';
  static const String blockedVerdict =
      'SYNC_BACKUP_CONFLICT_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'SYNC_BACKUP_CONFLICT_INCONSISTENT';

  /// The eight evidence items canonical step 117.14 names, in canonical order.
  static const List<String> requiredChecks = <String>[
    'transfer',
    'delta',
    'retry_resume',
    'encrypted_backup',
    'restore',
    'conflicts',
    'large_assets',
    'workspace_boundaries',
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
class Sprint117SyncBackupConflictCheck {
  Sprint117SyncBackupConflictCheck({
    required this.checkId,
    required this.method,
    required this.expectedOutcome,
    required this.observedOutcome,
    required this.sourceManifest,
    required this.liveProviderResult,
    required this.drilledAgainstLiveProvider,
  });

  /// The canonical check identity, e.g. `retry_resume`.
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
class Sprint117SyncBackupConflictAnchor {
  Sprint117SyncBackupConflictAnchor({
    required Map<String, String> declaredContractSizes,
    required Map<String, bool> boundariesDeclared,
    required this.backupBeforeResolutionDeclared,
    required this.explicitConsentDeclared,
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

  /// Whether 115.23 records the `backup_before_resolution` acceptance this
  /// validation drills.
  final bool backupBeforeResolutionDeclared;

  /// Whether 115.21 records the `explicit_transfer_consent` acceptance.
  final bool explicitConsentDeclared;

  /// How many external pins matched their recorded sha256.
  final int externalPinsMatched;

  /// How many external pins were readable and therefore comparable.
  final int externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117SyncBackupConflictContract.externalPins.length;

  bool get allExternalPinsMatch =>
      externalPinsResolved && externalPinsMatched == externalPinsChecked;
}

/// The decided-versus-observed input the gate reasons about.
class Sprint117SyncBackupConflictInput {
  const Sprint117SyncBackupConflictInput({
    this.rows,
    this.anchor,
    this.drillRun,
    this.externalPinDrift = false,
  });

  final List<Sprint117SyncBackupConflictCheck>? rows;
  final Sprint117SyncBackupConflictAnchor? anchor;
  final Sprint117SyncBackupConflictDrillRun? drillRun;

  /// Whether an external pin no longer matches what its manifest recorded.
  final bool externalPinDrift;
}

/// Whether a canonical acceptance could be satisfied by shipped code at all.
enum Sprint117SyncBackupConflictAcceptance { satisfied, mechanismAbsent }

/// One measured local observation behind a canonical check.
class Sprint117SyncBackupConflictObservation {
  Sprint117SyncBackupConflictObservation({
    required this.checkId,
    required this.outcome,
    required this.facts,
    required this.passed,
    this.acceptance = Sprint117SyncBackupConflictAcceptance.satisfied,
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
  final Sprint117SyncBackupConflictAcceptance acceptance;

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
class Sprint117SyncBackupConflictDrillRun {
  Sprint117SyncBackupConflictDrillRun({
    required List<Sprint117SyncBackupConflictObservation> observations,
    required this.liveProviderTouched,
    required this.userProjectTouched,
    required this.liveSecretObserved,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
  }) : observations = List<Sprint117SyncBackupConflictObservation>.unmodifiable(
         observations,
       );

  final List<Sprint117SyncBackupConflictObservation> observations;

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
      Sprint117SyncBackupConflictContract.externalPins.length;

  List<String> get acceptanceSatisfied => <String>[
    for (final entry in observations)
      if (entry.acceptance == Sprint117SyncBackupConflictAcceptance.satisfied)
        entry.checkId,
  ];

  List<String> get acceptanceUnmet => <String>[
    for (final entry in observations)
      if (entry.acceptance ==
          Sprint117SyncBackupConflictAcceptance.mechanismAbsent)
        entry.checkId,
  ];

  List<String> get unresolvableReferences => <String>[
    for (final entry in observations) ...entry.unresolvable,
  ];

  Sprint117SyncBackupConflictObservation? observationFor(String checkId) {
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
class Sprint117SyncBackupConflictLoader {
  const Sprint117SyncBackupConflictLoader();

  Sprint117SyncBackupConflictInput load() => Sprint117SyncBackupConflictInput(
    rows: _loadRows(),
    anchor: _loadAnchor(),
  );

  /// Folds the measured drill into the committed record.
  Sprint117SyncBackupConflictInput loadWithDrill(
    Sprint117SyncBackupConflictDrillRun run,
  ) => Sprint117SyncBackupConflictInput(
    rows: _loadRows(run),
    anchor: _loadAnchor(),
    drillRun: run,
    // A run that could not read every pin cannot prove drift either; only a
    // readable pin that no longer matches is a contradiction.
    externalPinDrift:
        run.externalPinsResolved && !run.allExternalPinsMatchForDrill,
  );

  Sprint117SyncBackupConflictAnchor? _loadAnchor() {
    final declared = <String, String>{};
    final boundaries = <String, bool>{};
    Map<String, dynamic>? conflictCenter;
    Map<String, dynamic>? transferControls;
    for (final path in Sprint117SyncBackupConflictContract.sourceManifests) {
      final source = _readJsonFile(path);
      if (source == null) return null;
      declared[path] = _declaredContractSize(source);
      boundaries[path] = _declaresBoundary(source);
      if (path == Sprint117SyncBackupConflictContract.conflictCenter) {
        conflictCenter = source;
      }
      if (path == Sprint117SyncBackupConflictContract.transferControls) {
        transferControls = source;
      }
    }
    if (conflictCenter == null || transferControls == null) return null;

    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117SyncBackupConflictContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }

    return Sprint117SyncBackupConflictAnchor(
      declaredContractSizes: declared,
      boundariesDeclared: boundaries,
      backupBeforeResolutionDeclared: _declaresAcceptance(
        conflictCenter,
        Sprint117SyncBackupConflictContract.backupBeforeResolutionAcceptance,
      ),
      explicitConsentDeclared: _declaresAcceptance(
        transferControls,
        Sprint117SyncBackupConflictContract.explicitConsentAcceptance,
      ),
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }

  List<Sprint117SyncBackupConflictCheck>? _loadRows([
    Sprint117SyncBackupConflictDrillRun? run,
  ]) {
    if (_loadAnchor() == null) return null;
    return <Sprint117SyncBackupConflictCheck>[
      for (final checkId in Sprint117SyncBackupConflictContract.requiredChecks)
        if (_defined(checkId))
          Sprint117SyncBackupConflictCheck(
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
    'transfer' ||
    'delta' ||
    'retry_resume' => Sprint117SyncBackupConflictContract.transferControls,
    'conflicts' => Sprint117SyncBackupConflictContract.conflictCenter,
    'encrypted_backup' ||
    'restore' => Sprint117SyncBackupConflictContract.backupPolicies,
    'workspace_boundaries' =>
      Sprint117SyncBackupConflictContract.workspaceBoundary,
    'large_assets' =>
      Sprint117SyncBackupConflictContract.crossStorageCertification,
    _ => '',
  };

  /// The step this validation runs for a check.
  static String _method(String checkId) => switch (checkId) {
    'transfer' =>
      'construct cross-scope transfers and record whether the shipped consent '
          'gate rejects a cross-scope transfer that lacks explicit consent',
    'delta' =>
      'measure whether a shipped mechanism transports only the changed keys, '
          'and record what a changedKeys-only transfer actually carries',
    'retry_resume' =>
      'pause, resume, fail, and retry a shipped transfer and record the '
          'completed bytes that survive the round trip and the retry bound',
    'encrypted_backup' =>
      'construct backup policies and record that a backup may run only with '
          'encryption and an available destination, and that encryption is '
          'never executed here',
    'restore' =>
      'verify and restore-test evidence objects and record that a policy is '
          'not evidence of a completed restore',
    'conflicts' =>
      'detect three-way conflicts and resolve them, and record that a '
          'remote-only change survives the merge while a manual conflict does '
          'not resolve itself',
    'large_assets' =>
      'record what a large payload round-trips through the only shipped '
          'filesystem sync service, and that no shipped chunking or streaming '
          'mechanism exists',
    'workspace_boundaries' =>
      'resolve workspace access, cross-scope transfer, and backup boundary '
          'violations and record that each gate denies rather than repairs',
    _ => '',
  };

  /// What the method is expected to produce locally.
  static String _expectedOutcome(String checkId) => switch (checkId) {
    'transfer' =>
      'a cross-scope transfer without explicit consent is refused at '
          'construction, and a consented one is marked resumable',
    'delta' =>
      'only changed keys are transported and no unchanged payload is resent',
    'retry_resume' =>
      'paused bytes survive pause and resume, a failed transfer retries up to '
          'its bound, and an unbounded retry is refused',
    'encrypted_backup' =>
      'a backup may run only with encryption and an available destination',
    'restore' =>
      'a restore is reported only from completed evidence, never from a policy',
    'conflicts' =>
      'a conflict is detected, resolved explicitly, and history is kept; a '
          'remote-only change is never dropped',
    'large_assets' =>
      'a large payload round-trips through the shipped sync service',
    'workspace_boundaries' =>
      'workspace access, cross-scope transfer, and boundary mixing are denied '
          'without the permission or consent they require',
    _ => '',
  };

  /// How many contract items a source declares, or empty when it declares
  /// none. 116.20 spells its contract `required_outputs`, so that spelling is
  /// read too.
  static String _declaredContractSize(Map<String, dynamic> source) {
    for (final key in const <String>[
      'acceptance',
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

/// Decides whether the recorded sync/backup evidence is coherent.
class Sprint117SyncBackupConflictGate {
  const Sprint117SyncBackupConflictGate();

  /// Runs the drill, then decides from its measured output.
  Future<Sprint117SyncBackupConflictReport> evaluateWithDrill([
    Sprint117SyncBackupConflictDrillRun? run,
  ]) async {
    final measured =
        run ?? await const Sprint117SyncBackupConflictDrill().run();
    return evaluateWith(
      const Sprint117SyncBackupConflictLoader().loadWithDrill(measured),
    );
  }

  Sprint117SyncBackupConflictReport evaluate() =>
      evaluateWith(const Sprint117SyncBackupConflictLoader().load());

  Sprint117SyncBackupConflictReport evaluateWith(
    Sprint117SyncBackupConflictInput input,
  ) {
    final missing = <String>{};
    final violations = <String>{};

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('sync_anchor');
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
      if (!anchor.backupBeforeResolutionDeclared) {
        missing.add(
          'conflict_backup_before_resolution_acceptance:'
          '${Sprint117SyncBackupConflictContract.backupBeforeResolutionAcceptance}',
        );
      }
      if (!anchor.explicitConsentDeclared) {
        missing.add(
          'transfer_explicit_consent_acceptance:'
          '${Sprint117SyncBackupConflictContract.explicitConsentAcceptance}',
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
                Sprint117SyncBackupConflictAcceptance.satisfied) {
          violations.add(
            'acceptance_claimed_without_mechanism:${observation.checkId}',
          );
        }
      }
    }

    final rows = input.rows;
    final rowIds = <String>{};
    final checks = <Sprint117SyncBackupConflictCheck>[];
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
    if (anchor != null && !missing.contains('sync_anchor')) {
      for (final checkId
          in Sprint117SyncBackupConflictContract.requiredChecks) {
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
    final total = Sprint117SyncBackupConflictContract.requiredChecks.length;
    final coverage = total == 0 ? 0.0 : decidedCount / total;

    final complete = missing.isEmpty && violations.isEmpty;
    final state = violations.isNotEmpty
        ? Sprint117SyncBackupConflictState.fail
        : (complete
              ? Sprint117SyncBackupConflictState.pass
              : Sprint117SyncBackupConflictState.blocked);

    return Sprint117SyncBackupConflictReport(
      status: state,
      verdict: switch (state) {
        Sprint117SyncBackupConflictState.pass =>
          Sprint117SyncBackupConflictContract.passVerdict,
        Sprint117SyncBackupConflictState.fail =>
          Sprint117SyncBackupConflictContract.failVerdict,
        Sprint117SyncBackupConflictState.blocked =>
          Sprint117SyncBackupConflictContract.blockedVerdict,
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
    Sprint117SyncBackupConflictCheck row,
    Sprint117SyncBackupConflictDrillRun? drillRun,
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
    Sprint117SyncBackupConflictDrillRun? drillRun,
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
      'sync_defined_not_executed_live',
      'external_sync_specs_outside_repository',
    };
    return items.toList(growable: false)..sort();
  }
}

/// The gate's verdict, with the evidence it decided from.
class Sprint117SyncBackupConflictReport {
  Sprint117SyncBackupConflictReport({
    required this.status,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required List<String> unmappedChecks,
    required List<String> undeterminedChecks,
    required this.coverage,
    required List<String> acceptanceSatisfied,
    required List<String> acceptanceUnmet,
    required List<Sprint117SyncBackupConflictCheck> checks,
    required this.anchor,
    required List<String> openItems,
  }) : acceptanceSatisfied = List<String>.unmodifiable(acceptanceSatisfied),
       acceptanceUnmet = List<String>.unmodifiable(acceptanceUnmet),
       missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       unmappedChecks = List<String>.unmodifiable(unmappedChecks),
       undeterminedChecks = List<String>.unmodifiable(undeterminedChecks),
       checks = List<Sprint117SyncBackupConflictCheck>.unmodifiable(checks),
       openItems = List<String>.unmodifiable(openItems);

  final Sprint117SyncBackupConflictState status;

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

  final List<Sprint117SyncBackupConflictCheck> checks;
  final Sprint117SyncBackupConflictAnchor? anchor;

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

extension on Sprint117SyncBackupConflictAnchor {
  Map<String, Object?> toJson() => <String, Object?>{
    'declared_contract_sizes': Map<String, String>.from(declaredContractSizes),
    'boundaries_declared': Map<String, bool>.from(boundariesDeclared),
    'backup_before_resolution_declared': backupBeforeResolutionDeclared,
    'explicit_consent_declared': explicitConsentDeclared,
    'external_pins_matched': externalPinsMatched,
    'external_pins_checked': externalPinsChecked,
    'external_pins_resolved': externalPinsResolved,
  };
}

extension on Sprint117SyncBackupConflictDrillRun {
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
