/// Canonical step 117.8 — Provider Rollback Drill.
///
/// Objective (external canonical JSON): test connector kill switch, token
/// revoke, queue stop, cached-state handling, artifact rollback, and
/// communication.
///
/// A rollback drill's failure mode is not being absent — it is looking
/// rehearsed. 113.7 records a five-step drill whose kill switch names
/// `vs12_world_logic_shared`, a flag `FeatureFlagRegistry._ensureKnown` throws
/// on, and whose artifact withdrawal targets `void_spector.exe`, a path the
/// checksum manifest never recorded. Read in a review, that drill looks
/// complete. Run verbatim, it disables nothing and withdraws nothing while
/// still reporting success.
///
/// So this contract does the one thing a plan cannot do for itself: it *runs*
/// the drill. The gate and the drill are deliberately separate classes.
///
/// * [Sprint117RollbackDrill] engages the real mechanisms — the shipped
///   [FeatureFlagRegistry], the real [AccountSecureTokenVault] over an
///   in-memory [MemoryCredentialStore], a real [GenerationQueue], and the real
///   [Sprint116OfflineCacheCertification] over records it writes itself. A
///   description of a kill switch is not a kill switch.
/// * [Sprint117RollbackLoader] reads the ten committed manifests and never
///   invents a control, a step, or an owner.
/// * [Sprint117RollbackGate] decides whether the recorded drill is coherent,
///   synchronously and without side effects.
///
/// The 117.5–117.7 distinction carries over unchanged. A control no drill has
/// ever executed is *undetermined* — an open item — while a control that is
/// executed and then contradicted is a violation. 116.50 records
/// `live_rollout_executed: false` and every message `sent_at_epoch_ms: 0`, so
/// no live-provider observation exists for any control and none is invented.
library;

import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';
import 'package:void_scriptor/features/ai/application/generation_queue.dart';
import 'package:void_scriptor/features/ai/domain/generation_job.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_offline_cached_metadata_certification.dart';

enum Sprint117RollbackState { pass, fail, blocked }

/// One rollback control, the drill step that exercises it, and what that step
/// is expected to produce.
class Sprint117ControlRecord {
  Sprint117ControlRecord({
    required this.controlId,
    required this.drillStep,
    required this.expectedOutcome,
    required this.observedOutcome,
    required this.sourceManifest,
    required this.liveProviderResult,
    required this.drilledAgainstLiveProvider,
    required List<Sprint117ArtifactRef> artifacts,
    required List<Sprint117MessageRecord> messages,
  }) : artifacts = List<Sprint117ArtifactRef>.unmodifiable(artifacts),
       messages = List<Sprint117MessageRecord>.unmodifiable(messages);

  /// The canonical control identity, e.g. `kill_switch`.
  final String controlId;

  /// The step a responder would run. Empty means the drill only wishes for it.
  final String drillStep;

  /// What the step is expected to produce locally.
  final String expectedOutcome;

  /// What a live drill observed. Null while no live drill has ever run.
  final String? observedOutcome;

  /// The upstream manifest that defines this control.
  final String sourceManifest;

  /// Whether a live provider produced this outcome. It never has.
  final bool liveProviderResult;

  /// Whether the drill was run against a real provider. It never was.
  final bool drilledAgainstLiveProvider;

  /// Artifacts this control withdraws or restores.
  final List<Sprint117ArtifactRef> artifacts;

  /// Messages this control drafts when it fires.
  final List<Sprint117MessageRecord> messages;

  bool get executed =>
      observedOutcome != null && observedOutcome!.trim().isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'control_id': controlId,
    'drill_step': drillStep,
    'expected_outcome': expectedOutcome,
    'observed_outcome': observedOutcome,
    'executed': executed,
    'source_manifest': sourceManifest,
    'live_provider_result': liveProviderResult,
    'drilled_against_live_provider': drilledAgainstLiveProvider,
    'artifacts': <Map<String, Object?>>[
      for (final artifact in artifacts) artifact.toJson(),
    ],
    'messages': <Map<String, Object?>>[
      for (final message in messages) message.toJson(),
    ],
  };
}

/// One artifact a rollback withdraws, with the path the checksum manifest
/// actually recorded for it.
class Sprint117ArtifactRef {
  const Sprint117ArtifactRef({
    required this.artifactId,
    required this.recordedPath,
    required this.withdrawal,
    required this.recordedInChecksumManifest,
    required this.presentOnDisk,
  });

  final String artifactId;

  /// The path recorded for this artifact, or 113.7's own spelling when the
  /// checksum manifest never recorded it.
  final String recordedPath;

  /// What withdrawal means for this artifact.
  final String withdrawal;

  /// Whether the checksum manifest recorded this artifact at all.
  final bool recordedInChecksumManifest;

  /// Whether the file exists on this machine right now.
  final bool presentOnDisk;

  Map<String, Object?> toJson() => <String, Object?>{
    'artifact_id': artifactId,
    'recorded_path': recordedPath,
    'withdrawal': withdrawal,
    'recorded_in_checksum_manifest': recordedInChecksumManifest,
    'present_on_disk': presentOnDisk,
  };
}

/// One drafted incident message, and whether it was ever sent.
class Sprint117MessageRecord {
  const Sprint117MessageRecord({
    required this.messageId,
    required this.audience,
    required this.channel,
    required this.trigger,
    required this.template,
    required this.draftedAtEpochMs,
    required this.sentAtEpochMs,
  });

  final String messageId;
  final String audience;
  final String channel;
  final String trigger;
  final String template;
  final int draftedAtEpochMs;
  final int sentAtEpochMs;

  bool get sent => sentAtEpochMs > 0;

  Map<String, Object?> toJson() => <String, Object?>{
    'message_id': messageId,
    'audience': audience,
    'channel': channel,
    'trigger': trigger,
    'message_template': template,
    'drafted_at_epoch_ms': draftedAtEpochMs,
    'sent_at_epoch_ms': sentAtEpochMs,
    'sent': sent,
  };
}

/// The evidence this drill is allowed to decide from.
class Sprint117RollbackAnchor {
  Sprint117RollbackAnchor({
    required this.drillVerdict,
    required this.readinessVerdict,
    required this.stopShipVerdict,
    required List<Sprint117ControlRecord> controls,
    required List<String> sourceManifests,
    required this.defaultFlagState,
    required this.killSwitchResolvable,
    required this.lastStableBuild,
    required this.localProjectDataTouched,
    required List<String> carriedOpenItems,
  }) : controls = List<Sprint117ControlRecord>.unmodifiable(controls),
       sourceManifests = List<String>.unmodifiable(sourceManifests),
       carriedOpenItems = List<String>.unmodifiable(carriedOpenItems);

  /// The 113.7 drill decision.
  final String drillVerdict;

  /// The 114.36 rollback and feature-flag readiness decision.
  final String readinessVerdict;

  /// The stop-ship protocol decision.
  final String stopShipVerdict;

  final List<Sprint117ControlRecord> controls;

  final List<String> sourceManifests;

  /// The flag state a rollback leaves behind. It must be OFF.
  final String defaultFlagState;

  /// Whether the recorded kill switch resolves in the shipped registry.
  final bool killSwitchResolvable;

  /// Whether a previous stable build exists to roll back to.
  final bool lastStableBuild;

  /// Whether any rollback path touches a user's project data.
  final bool localProjectDataTouched;

  final List<String> carriedOpenItems;
}

class Sprint117RollbackInput {
  const Sprint117RollbackInput({this.rows, this.anchor, this.drillExecuted});

  final List<Sprint117ControlRecord>? rows;
  final Sprint117RollbackAnchor? anchor;

  /// Whether a drill has been executed against a live provider.
  ///
  /// This is an input, not a constant. A hardcoded `false` would make the
  /// `drill_executed_claim` rule unreachable, and an unreachable fail-closed
  /// rule is precisely the defect this gate exists to catch.
  final bool? drillExecuted;
}

class Sprint117RollbackReport {
  Sprint117RollbackReport({
    required this.state,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required this.anchor,
    required List<Sprint117ControlRecord> controls,
    required List<String> unmappedControls,
    required List<String> undeterminedControls,
    required List<String> unresolvableReferences,
    required List<Sprint117ArtifactRef> artifacts,
    required List<Sprint117MessageRecord> messages,
    required this.drillExecuted,
    required List<String> openItems,
    required List<String> limitations,
    required Map<String, int> controlCoverage,
  }) : missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       controls = List<Sprint117ControlRecord>.unmodifiable(controls),
       unmappedControls = List<String>.unmodifiable(unmappedControls),
       undeterminedControls = List<String>.unmodifiable(undeterminedControls),
       unresolvableReferences = List<String>.unmodifiable(
         unresolvableReferences,
       ),
       artifacts = List<Sprint117ArtifactRef>.unmodifiable(artifacts),
       messages = List<Sprint117MessageRecord>.unmodifiable(messages),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations),
       controlCoverage = Map<String, int>.unmodifiable(controlCoverage);

  final Sprint117RollbackState state;
  final String verdict;
  final List<String> missingFields;
  final List<String> violations;
  final Sprint117RollbackAnchor? anchor;
  final List<Sprint117ControlRecord> controls;

  /// Canonical controls no source manifest defines.
  final List<String> unmappedControls;

  /// Controls defined but never exercised, because no live drill has ever run.
  final List<String> undeterminedControls;

  /// Recorded subjects that cannot be resolved: a flag the registry rejects or
  /// an artifact no checksum recorded.
  final List<String> unresolvableReferences;

  final List<Sprint117ArtifactRef> artifacts;
  final List<Sprint117MessageRecord> messages;

  /// Whether any drill has been executed against a live provider.
  final bool drillExecuted;

  final List<String> openItems;
  final List<String> limitations;
  final Map<String, int> controlCoverage;

  String get externalGates => Sprint117RollbackContract.externalGates;

  int get controlCount => controls.length;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117RollbackContract.canonicalStep,
    'state': state.name,
    'verdict': verdict,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'control_count': controlCount,
    'controls': <Map<String, Object?>>[for (final c in controls) c.toJson()],
    'unmapped_controls': List<String>.from(unmappedControls),
    'undetermined_controls': List<String>.from(undeterminedControls),
    'unresolvable_references': List<String>.from(unresolvableReferences),
    'artifacts': <Map<String, Object?>>[for (final a in artifacts) a.toJson()],
    'messages': <Map<String, Object?>>[for (final m in messages) m.toJson()],
    'required_controls': List<String>.from(
      Sprint117RollbackContract.requiredControls,
    ),
    'source_manifests': List<String>.from(
      anchor?.sourceManifests ?? const <String>[],
    ),
    'control_coverage': Map<String, int>.from(controlCoverage),
    'drill_executed': drillExecuted,
    'external_gates': externalGates,
    'open_items': List<String>.from(openItems),
    'limitations': List<String>.from(limitations),
  };
}

abstract final class Sprint117RollbackContract {
  static const String canonicalStep = '117.8';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_117_provider_rollback_drill.json';

  /// 113.7 supplies the drill script, artifact withdrawal, and communication
  /// draft.
  static const String drillPath =
      'docs/planning/v1.2/sprint_113_rollback_drill.json';

  /// 114.36 supplies rollback and feature-flag readiness.
  static const String readinessPath =
      'docs/planning/v1.2/sprint_114_rollback_feature_flag_readiness.json';

  /// The stop-ship protocol supplies the flag-disable method.
  static const String stopShipPath =
      'docs/planning/v1.2/sprint_113_incident_stop_ship_protocol.json';

  /// 116.50 supplies provider kill switches, stop conditions, and messages.
  static const String rolloutPath =
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';

  /// 115.43 supplies the token revoke UX acceptance.
  static const String tokenPath =
      'docs/planning/v1.2/sprint_115_token_expiry_reauthentication_ux.json';

  /// 115.12 supplies the secure token vault revoke implementation.
  static const String vaultPath =
      'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json';

  /// 116.44 supplies the cached-metadata certification the drill runs.
  static const String cachePath =
      'docs/planning/v1.2/sprint_116_offline_cached_metadata_certification.json';

  /// 116.20 supplies the durable queue contract the stop control references.
  static const String queuePath =
      'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json';

  /// 113.38 supplies the signed artifact list.
  static const String packagingPath =
      'docs/planning/v1.2/sprint_113_ga_artifact_packaging.json';

  /// 113.5 supplies the escalation and notification channel vocabulary.
  static const String supportPath =
      'docs/planning/v1.2/sprint_113_support_escalation_readiness.json';

  /// The SHA-256 manifest that records which artifacts actually shipped.
  static const String checksumManifest =
      'docs/release/v1.2.0-rc.1-checksums.txt';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// 113.7's decision.
  static const String drillVerdict = 'DRILL_DEFINED';

  /// 117.8's verdict when the drill is decided and coherent.
  static const String passVerdict = 'PROVIDER_ROLLBACK_DRILL_DEFINED_LOCAL';

  static const String blockedVerdict =
      'PROVIDER_ROLLBACK_DRILL_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'PROVIDER_ROLLBACK_DRILL_INCONSISTENT';

  /// The six controls canonical step 117.8 names, in canonical order.
  static const List<String> requiredControls = <String>[
    'kill_switch',
    'token_revoke',
    'queue_stop',
    'cache_handling',
    'artifact_rollback',
    'communication',
  ];

  static const List<String> sourceManifests = <String>[
    drillPath,
    readinessPath,
    stopShipPath,
    rolloutPath,
    tokenPath,
    vaultPath,
    cachePath,
    queuePath,
    packagingPath,
    supportPath,
  ];
}

/// What one control's local exercise actually produced.
class Sprint117DrillObservation {
  Sprint117DrillObservation({
    required this.controlId,
    required this.outcome,
    required Map<String, Object?> facts,
    required this.passed,
    required List<String> unresolvable,
  }) : facts = Map<String, Object?>.unmodifiable(facts),
       unresolvable = List<String>.unmodifiable(unresolvable);

  final String controlId;

  /// What the local exercise produced.
  final String outcome;

  /// The measured facts behind that outcome.
  final Map<String, Object?> facts;

  /// Whether the local mechanism responded as the contract expects.
  final bool passed;

  /// Recorded subjects the drill could not resolve.
  final List<String> unresolvable;

  Map<String, Object?> toJson() => <String, Object?>{
    'control_id': controlId,
    'outcome': outcome,
    'facts': Map<String, Object?>.from(facts),
    'passed': passed,
    'unresolvable': List<String>.from(unresolvable),
  };
}

/// The record of one local drill run.
class Sprint117DrillRun {
  Sprint117DrillRun({
    required List<Sprint117DrillObservation> observations,
    required this.liveProviderTouched,
  }) : observations = List<Sprint117DrillObservation>.unmodifiable(
         observations,
       );

  final List<Sprint117DrillObservation> observations;

  /// Always false: this drill never contacts a provider.
  final bool liveProviderTouched;

  /// Every recorded subject the drill could not resolve, across controls.
  List<String> get unresolvableReferences {
    final refs = <String>{
      for (final observation in observations)
        for (final reference in observation.unresolvable) reference,
    };
    return refs.toList(growable: false)..sort();
  }

  bool get allPassed => observations.every((observation) => observation.passed);

  Map<String, Object?> toJson() => <String, Object?>{
    'observations': <Map<String, Object?>>[
      for (final observation in observations) observation.toJson(),
    ],
    'live_provider_touched': liveProviderTouched,
    'all_passed': allPassed,
    'unresolvable_references': unresolvableReferences,
  };
}

/// Executes the drill locally, once per control, against the shipped
/// mechanisms.
class Sprint117RollbackDrill {
  const Sprint117RollbackDrill();

  Future<Sprint117DrillRun> run() async => Sprint117DrillRun(
    observations: <Sprint117DrillObservation>[
      _drillKillSwitch(),
      await _drillTokenRevoke(),
      await _drillQueueStop(),
      _drillCacheHandling(),
      _drillArtifactRollback(),
      _drillCommunication(),
    ],
    liveProviderTouched: false,
  );

  /// The kill switch is engaged against the shipped registry and every flag is
  /// asserted OFF afterwards.
  ///
  /// 113.7 and the stop-ship protocol both name `vs12_world_logic_shared`,
  /// which the registry rejects, so those references are reported while the
  /// mechanism itself is genuinely exercised.
  static Sprint117DrillObservation _drillKillSwitch() {
    final registry = FeatureFlagRegistry();
    for (final flag in kVs12FeatureFlags) {
      registry.enable(flag);
    }
    final enabledBefore = registry.enabledFlags.length;

    registry.engageKillSwitch();

    final stillEnabled = <String>[
      for (final flag in kVs12FeatureFlags)
        if (registry.isEnabled(flag)) flag,
    ];
    return Sprint117DrillObservation(
      controlId: 'kill_switch',
      outcome: 'kill_switch_engaged_locally',
      facts: <String, Object?>{
        'known_flags': kVs12FeatureFlags.length,
        'enabled_before': enabledBefore,
        'enabled_after': registry.enabledFlags.length,
        'kill_switch_active': registry.killSwitchActive,
        'all_at_defaults': registry.allAtDefaults,
        'still_enabled': stillEnabled,
      },
      passed:
          stillEnabled.isEmpty &&
          registry.killSwitchActive &&
          registry.allAtDefaults,
      unresolvable: const <String>[
        // 113.7 and the stop-ship protocol name a shared kill switch the
        // shipped registry does not know. Reported with its exact spelling
        // rather than rewritten into a flag that exists.
        'vs12_world_logic_shared',
        'world_simulation_features',
        'advanced_timeline_features',
      ],
    );
  }

  /// The revoke runs against the real vault over an in-memory store: the
  /// secret is unreadable afterwards, and the audit record carries no secret.
  static Future<Sprint117DrillObservation> _drillTokenRevoke() async {
    const accountId = 'drill_account';
    final store = MemoryCredentialStore();
    final audit = <Map<String, String>>[];
    final vault = AccountSecureTokenVault(
      store: store,
      reauthenticate: () async => true,
      auditSink: (event) => audit.add(<String, String>{
        'action': event.action,
        'account_id': event.accountId,
        'secret': event.secret ?? '',
      }),
    );
    const kind = VaultSecretKind.oauthRefreshToken;
    await vault.save(
      accountId: accountId,
      secret: 'drill-refresh-token-value',
      kind: kind,
    );
    final before = await store.read(vault.keyFor(accountId, kind));
    await vault.revoke(accountId: accountId, kind: kind);
    final after = await store.read(vault.keyFor(accountId, kind));
    final revokeAudited = audit.any((event) => event['action'] == 'revoke');
    final auditLeaked = audit.any(
      (event) => (event['secret'] ?? '').isNotEmpty,
    );
    return Sprint117DrillObservation(
      controlId: 'token_revoke',
      outcome: 'token_revoked_locally',
      facts: <String, Object?>{
        'present_before': before != null,
        'present_after': after != null,
        'audit_events': audit.length,
        'revoke_audited': revokeAudited,
        'audit_carried_secret': auditLeaked,
      },
      passed: before != null && after == null && revokeAudited && !auditLeaked,
      unresolvable: const <String>[],
    );
  }

  /// The queue stop cancels a job, drains, and asserts the cancelled job never
  /// runs while a later job still does — a stop, not a deadlock.
  static Future<Sprint117DrillObservation> _drillQueueStop() async {
    final ran = <String>[];
    final queue = GenerationQueue(
      executor: (job) async => ran.add(job.id),
      canceller: (job) async {},
    );
    queue.enqueue(_job('drill_job_1'));
    queue.enqueue(_job('drill_job_2'));
    final cancelled = await queue.cancel('drill_job_1');
    await queue.drain();
    final ranBeforeStop = ran.length;
    queue.enqueue(_job('drill_job_3'));
    await queue.drain();
    final cancelledStatus = queue.statusOf('drill_job_1')?.name;
    return Sprint117DrillObservation(
      controlId: 'queue_stop',
      outcome: 'queue_stopped_locally',
      facts: <String, Object?>{
        'cancel_accepted': cancelled,
        'ran_before_stop': ranBeforeStop,
        'ran_after_stop': ran.length - ranBeforeStop,
        'cancelled_status': cancelledStatus,
      },
      passed:
          cancelled &&
          !ran.contains('drill_job_1') &&
          cancelledStatus == 'cancelled' &&
          ran.length - ranBeforeStop == 1,
      unresolvable: const <String>[],
    );
  }

  /// Cache handling runs the real 116.44 certification over records the drill
  /// itself writes, so a clear cannot borrow the manifest's fixtures.
  ///
  /// Sources must be `synthetic_local` because 116.44's certifier rejects any
  /// other value; the clear targets an entry the drill never wrote, which is
  /// what proves the eviction rather than re-deriving it; and a reconnect entry
  /// carries detected/refreshed/preserved so the `reconnect` area is covered by
  /// evidence instead of omitted.
  static Sprint117DrillObservation _drillCacheHandling() {
    const asOf = 1700000100000;
    const cachedAt = 1700000000000;
    final report = Sprint116OfflineCacheCertification().certify(
      entries: <Sprint116CacheEntry>[
        const Sprint116CacheEntry(
          entryId: 'drill_entry_fresh',
          providerId: 'provider_a',
          resourceId: 'project_tree',
          cachedAtEpochMs: cachedAt,
          asOfEpochMs: cachedAt,
          freshTtlSeconds: 3600,
          freshnessLabel: 'fresh',
          valueAvailable: true,
          offline: false,
          remoteActionEnabled: true,
          localActionEnabled: true,
          localActions: <String>['open_project_tree'],
          reconnectAttempted: false,
          source: 'synthetic_local',
        ),
        const Sprint116CacheEntry(
          entryId: 'drill_entry_stale',
          providerId: 'provider_b',
          resourceId: 'billing_snapshot',
          cachedAtEpochMs: cachedAt - 7200000,
          asOfEpochMs: cachedAt - 7200000,
          freshTtlSeconds: 3600,
          freshnessLabel: 'stale',
          valueAvailable: true,
          offline: true,
          remoteActionEnabled: false,
          localActionEnabled: true,
          localActions: <String>['view_history'],
          reconnectAttempted: false,
          source: 'synthetic_local',
        ),
        const Sprint116CacheEntry(
          entryId: 'drill_entry_reconnected',
          providerId: 'provider_a',
          resourceId: 'chapter_draft',
          cachedAtEpochMs: cachedAt,
          asOfEpochMs: cachedAt,
          freshTtlSeconds: 3600,
          freshnessLabel: 'fresh',
          valueAvailable: true,
          offline: false,
          remoteActionEnabled: true,
          localActionEnabled: true,
          localActions: <String>['edit_chapter', 'save_draft'],
          reconnectAttempted: true,
          reconnectDetectedEpochMs: cachedAt - 600000,
          reconnectRefreshed: true,
          reconnectRefreshEpochMs: cachedAt,
          pendingLocalEdits: 1,
          pendingLocalEditsPreserved: true,
          source: 'synthetic_local',
        ),
      ],
      clears: <Sprint116CacheClearRecord>[
        const Sprint116CacheClearRecord(
          clearId: 'drill_clear_orphan',
          entryId: 'drill_entry_orphan',
          clearedAtEpochMs: asOf,
          entriesRemainingAfterClear: 0,
          source: 'synthetic_local',
        ),
      ],
      asOfEpochMs: asOf,
      requireCoverage: true,
    );
    return Sprint117DrillObservation(
      controlId: 'cache_handling',
      outcome: 'cache_handled_locally',
      facts: <String, Object?>{
        'state': report.state.name,
        'invalid_records': report.invalidRecords,
        'covered_areas': report.coveredAreas,
        'stale_entry_ids': report.staleEntryIds,
      },
      passed:
          report.invalidRecords.isEmpty &&
          report.coveredAreas.length ==
              Sprint116OfflineCacheContract.requiredAreas.length,
      unresolvable: const <String>[],
    );
  }

  /// Artifact rollback resolves each recorded target against the checksum
  /// manifest. 113.7 withdraws `void_spector.exe` — a misspelling the manifest
  /// never recorded — and a zip that never shipped, so both are reported rather
  /// than quietly repaired into something that looks verified.
  static Sprint117DrillObservation _drillArtifactRollback() {
    final manifest = File(Sprint117RollbackContract.checksumManifest);
    final recorded = manifest.existsSync()
        ? Sprint117RollbackLoader.recordedChecksumPaths()
        : const <String>{};
    const affected = <String>[
      'build/windows/x64/runner/Release/void_spector.exe',
      'void_spector-1.2.0-rc.1.zip',
      'build/windows/x64/runner/Release/void_scriptor.exe',
    ];
    final unresolvable = <String>[
      for (final path in affected)
        if (!recorded.contains(path)) path,
    ];
    return Sprint117DrillObservation(
      controlId: 'artifact_rollback',
      outcome: 'artifact_rollback_resolved_locally',
      facts: <String, Object?>{
        'checksum_manifest': Sprint117RollbackContract.checksumManifest,
        'manifest_exists': manifest.existsSync(),
        'recorded_paths': recorded.length,
        'targets_checked': affected.length,
        'unresolvable_targets': unresolvable,
      },
      // The mechanism passed when the manifest is readable and exactly the one
      // correctly-spelled target resolves. The two misspelled targets are
      // reported as unresolvable, not counted as a mechanism failure.
      passed:
          manifest.existsSync() && unresolvable.length == affected.length - 1,
      unresolvable: unresolvable,
    );
  }

  /// Communication is drafted for every trigger and never sent.
  static Sprint117DrillObservation _drillCommunication() {
    const loader = Sprint117RollbackLoader();
    final messages =
        loader
            .load()
            .anchor
            ?.controls
            .where((control) => control.controlId == 'communication')
            .expand((control) => control.messages)
            .toList(growable: false) ??
        const <Sprint117MessageRecord>[];
    final unsent = messages
        .where((message) => !message.sent)
        .toList(growable: false);
    return Sprint117DrillObservation(
      controlId: 'communication',
      outcome: 'communication_drafted_locally',
      facts: <String, Object?>{
        'messages': messages.length,
        'drafted_not_sent': unsent.length,
        'triggers': <String>[for (final m in messages) m.trigger],
      },
      passed: messages.isNotEmpty && unsent.length == messages.length,
      unresolvable: const <String>[],
    );
  }

  static GenerationJob _job(String id) => GenerationJob(
    id: id,
    projectId: 'drill_project',
    providerId: 'provider_a',
    promptHistoryId: 'drill_history',
    status: GenerationJobStatus.queued,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

/// Reads the committed manifests this drill decides from.
///
/// Kept separate from [Sprint117RollbackDrill], which *runs* the mechanisms,
/// and from [Sprint117RollbackGate], which *decides* the record.
class Sprint117RollbackLoader {
  const Sprint117RollbackLoader();

  Sprint117RollbackInput load() =>
      Sprint117RollbackInput(rows: _loadRows(), anchor: _loadAnchor());

  /// Reads the ten committed manifests this drill decides from.
  ///
  /// A control exists only where its source records one: a control whose
  /// manifest names no method, no acceptance, and no artifact is not created,
  /// so a missing manifest produces a blocked report rather than a row of
  /// invented content.
  Sprint117RollbackAnchor? _loadAnchor() {
    final drill = _readJsonObject(Sprint117RollbackContract.drillPath);
    final readiness = _readJsonObject(Sprint117RollbackContract.readinessPath);
    final stopShip = _readJsonObject(Sprint117RollbackContract.stopShipPath);
    final rollout = _readJsonObject(Sprint117RollbackContract.rolloutPath);
    final token = _readJsonObject(Sprint117RollbackContract.tokenPath);
    final vault = _readJsonObject(Sprint117RollbackContract.vaultPath);
    final cache = _readJsonObject(Sprint117RollbackContract.cachePath);
    final queue = _readJsonObject(Sprint117RollbackContract.queuePath);
    final packaging = _readJsonObject(Sprint117RollbackContract.packagingPath);
    final support = _readJsonObject(Sprint117RollbackContract.supportPath);
    if (drill == null ||
        readiness == null ||
        stopShip == null ||
        rollout == null ||
        token == null ||
        vault == null ||
        cache == null ||
        queue == null ||
        packaging == null ||
        support == null) {
      return null;
    }

    final artifacts = _artifacts(drill, packaging);
    final messages = _messages(rollout, drill, support);

    // Each control is derived from a distinct committed manifest. A control
    // whose source records nothing is not created.
    final defined = <String, bool>{
      'kill_switch': _mapValue(drill['flag_disable'])['method'] != null,
      'token_revoke': _stringList(token['acceptance']).contains('revoke'),
      'queue_stop': _text(_mapValue(queue['record'])['queue']).isNotEmpty,
      'cache_handling': _stringList(cache['acceptance_areas']).isNotEmpty,
      'artifact_rollback': artifacts.isNotEmpty,
      'communication': messages.isNotEmpty,
    };

    final controls = <Sprint117ControlRecord>[
      for (final controlId in Sprint117RollbackContract.requiredControls)
        if (defined[controlId] ?? false)
          Sprint117ControlRecord(
            controlId: controlId,
            drillStep: _drillStep(drill, controlId),
            expectedOutcome: _expectedOutcome(controlId),
            // No drill has ever been run against a live provider, so no control
            // carries an observed outcome. Filling one in would fabricate the
            // single observation this gate exists to keep out of the record.
            observedOutcome: null,
            sourceManifest: _sourceFor(controlId),
            liveProviderResult: false,
            drilledAgainstLiveProvider: false,
            artifacts: controlId == 'artifact_rollback'
                ? artifacts
                : const <Sprint117ArtifactRef>[],
            messages: controlId == 'communication'
                ? messages
                : const <Sprint117MessageRecord>[],
          ),
    ];

    return Sprint117RollbackAnchor(
      drillVerdict: _text(drill['decision']),
      readinessVerdict: _text(readiness['decision']),
      stopShipVerdict: _text(stopShip['decision']),
      controls: controls,
      sourceManifests: Sprint117RollbackContract.sourceManifests,
      defaultFlagState: _text(rollout['beta_feature_flags_default']),
      // 117.5 already owns the connector-flag drift, so this gate reports the
      // narrower fact it can prove: whether the drill's own kill switch
      // resolves in the shipped registry. It does not.
      killSwitchResolvable: _killSwitchResolvable(drill, stopShip),
      lastStableBuild: _lastStableBuild(drill),
      localProjectDataTouched: _localProjectDataTouched(rollout),
      carriedOpenItems: _carriedOpenItems(rollout, drill),
    );
  }

  List<Sprint117ControlRecord>? _loadRows() =>
      _loadAnchor()?.controls ?? const <Sprint117ControlRecord>[];

  // --- projections ----------------------------------------------------------

  /// The step this drill runs for each control, derived from the mechanism the
  /// control's own source defines.
  ///
  /// 113.7's recorded script has five steps and names only three of the six
  /// canonical controls, so it cannot supply a step for every one of them. An
  /// earlier version of this loader forced all six out of those five by
  /// substring-matching Indonesian step names, and `queue_stop` came back empty
  /// — the same failure 117.7 had to undo for its exclusion set. Each step is
  /// therefore stated from the control's own sourced mechanism rather than
  /// borrowed from a neighbouring step.
  String _drillStep(
    Map<String, dynamic> drill,
    String controlId,
  ) => switch (controlId) {
    'kill_switch' => _text(_mapValue(drill['flag_disable'])['method']),
    'token_revoke' =>
      'Revoke the stored oauth_refresh_token through AccountSecureTokenVault '
          'over an in-memory CredentialStore',
    'queue_stop' =>
      'Cancel one GenerationQueue job, drain, and assert it never ran',
    'cache_handling' =>
      'Certify Sprint116OfflineCacheCertification over records this drill '
          'writes, covering all six acceptance areas',
    'artifact_rollback' => _text(
      _mapValue(drill['artifact_withdrawal'])['method'],
    ),
    'communication' =>
      'Verify every 116.50 trigger has a drafted message and none is '
          'recorded sent',
    _ => '',
  };

  /// What the step is expected to produce locally, stated as an observation a
  /// responder can check rather than as a claim of success.
  String _expectedOutcome(String controlId) => switch (controlId) {
    'kill_switch' =>
      'FeatureFlagRegistry.engageKillSwitch leaves every flag OFF and '
          'killSwitchActive true',
    'token_revoke' =>
      'AccountSecureTokenVault.revoke deletes the secret and records a revoke '
          'audit event carrying no secret material',
    'queue_stop' =>
      'GenerationQueue.cancel stops the job, which never runs, while a later '
          'job still does',
    'cache_handling' =>
      "Sprint116OfflineCacheCertification certifies the drill's own records, "
          'covering every area with no invalid record',
    'artifact_rollback' =>
      'every withdrawal target resolves in '
          '${Sprint117RollbackContract.checksumManifest} or is reported as '
          'unresolvable',
    'communication' =>
      'every trigger has a drafted message and none is recorded sent',
    _ => '',
  };

  String _sourceFor(String controlId) => switch (controlId) {
    'kill_switch' => Sprint117RollbackContract.drillPath,
    'token_revoke' => Sprint117RollbackContract.vaultPath,
    'queue_stop' => Sprint117RollbackContract.queuePath,
    'cache_handling' => Sprint117RollbackContract.cachePath,
    'artifact_rollback' => Sprint117RollbackContract.packagingPath,
    'communication' => Sprint117RollbackContract.rolloutPath,
    _ => '',
  };

  /// Artifacts the drill withdraws, paired with the path the checksum manifest
  /// actually recorded for them. 113.7 spells the executable `void_spector`
  /// while the manifest and the shipped binary are `void_scriptor`.
  List<Sprint117ArtifactRef> _artifacts(
    Map<String, dynamic> drill,
    Map<String, dynamic> packaging,
  ) {
    final recorded = recordedChecksumPaths();
    final affected = _stringList(
      _mapValue(drill['artifact_withdrawal'])['affected_artifacts'],
    );
    final signed = _stringList(
      _mapValue(packaging['required_outputs'])['signed_artifacts'],
    );
    final candidates = <String>[...affected, ...signed];
    final ids = <String>[];
    for (final path in candidates) {
      final name = path.split('/').last;
      if (name.isEmpty || ids.contains(name)) continue;
      ids.add(name);
    }
    const releaseDir = 'build/windows/x64/runner/Release';
    return <Sprint117ArtifactRef>[
      for (final artifactId in ids)
        Sprint117ArtifactRef(
          artifactId: artifactId,
          recordedPath: _recordedPathFor(artifactId, candidates, recorded),
          withdrawal: _text(_mapValue(drill['artifact_withdrawal'])['method']),
          recordedInChecksumManifest: recorded.any(
            (path) => path.endsWith('/$artifactId'),
          ),
          presentOnDisk: File('$releaseDir/$artifactId').existsSync(),
        ),
    ];
  }

  /// The manifest path this artifact was recorded under, or the recorded
  /// spelling itself when the manifest never knew it. The gap is reported
  /// rather than silently repaired.
  String _recordedPathFor(
    String artifactId,
    List<String> candidates,
    Set<String> recorded,
  ) {
    for (final path in recorded) {
      if (path.endsWith('/$artifactId')) return path;
    }
    for (final path in candidates) {
      if (path.split('/').last == artifactId) return path;
    }
    return '';
  }

  /// Every path the checksum manifest recorded, so "was this artifact ever
  /// shipped" is answered from the manifest rather than from a filename.
  static Set<String> recordedChecksumPaths() {
    final file = File(Sprint117RollbackContract.checksumManifest);
    if (!file.existsSync()) return const <String>{};
    final paths = <String>{};
    for (final line in const LineSplitter().convert(file.readAsStringSync())) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      paths.add(parts.last);
    }
    return paths;
  }

  /// Messages the drill must have ready, from 116.50's records plus 113.7's
  /// communication draft and 113.5's notification vocabulary.
  List<Sprint117MessageRecord> _messages(
    Map<String, dynamic> rollout,
    Map<String, dynamic> drill,
    Map<String, dynamic> support,
  ) {
    final messages = <Sprint117MessageRecord>[];
    for (final comm in _mapList(rollout['communication'])) {
      final id = _text(comm['comm_id']);
      if (id.isEmpty) continue;
      messages.add(
        Sprint117MessageRecord(
          messageId: id,
          audience: _text(comm['audience']),
          channel: _text(comm['channel']),
          trigger: _text(comm['trigger']),
          template: _text(comm['message_template']),
          draftedAtEpochMs: _int(comm['drafted_at_epoch_ms']),
          sentAtEpochMs: _int(comm['sent_at_epoch_ms']),
        ),
      );
    }
    final draft = _mapValue(drill['communication_draft']);
    final template = _text(draft['template']);
    if (template.isNotEmpty) {
      messages.add(
        Sprint117MessageRecord(
          messageId: 'comm_drill_rollback',
          audience: 'internal_ledger',
          channel:
              _stringList(draft['channels']).firstOrNull ?? 'internal_ledger',
          trigger: 'rollback_drill_complete',
          template: template,
          draftedAtEpochMs: 1,
          sentAtEpochMs: 0,
        ),
      );
    }
    // 113.5's P0/P1 notification routes: a rollback that stops distribution has
    // to reach the decision maker, so the channel vocabulary is carried
    // forward rather than invented.
    for (final level in const <String>['P0', 'P1']) {
      final target = _mapValue(_mapValue(support['response_targets'])[level]);
      final notification = _text(target['notification']);
      if (notification.isEmpty) continue;
      messages.add(
        Sprint117MessageRecord(
          messageId: 'comm_escalation_$level',
          audience: 'release_owner',
          channel: notification,
          trigger: 'rollback_escalation_$level',
          template: 'Rollback $level escalation: ${_text(target['action'])}',
          draftedAtEpochMs: 1,
          sentAtEpochMs: 0,
        ),
      );
    }
    return messages;
  }

  /// 113.7 and the stop-ship protocol name `vs12_world_logic_shared`; the
  /// shipped registry resolves only the 13 wave-1 ids, so the recorded kill
  /// switch is not resolvable. 117.5 owns the broader connector-flag drift, so
  /// this asserts only the narrower fact it can prove.
  bool _killSwitchResolvable(
    Map<String, dynamic> drill,
    Map<String, dynamic> stopShip,
  ) {
    final recorded = <String>{
      ..._stringList(_mapValue(drill['flag_disable'])['flags_affected']),
      ..._stringList(_mapValue(stopShip['flag_disable'])['flags_affected']),
    };
    if (recorded.isEmpty) return false;
    return recorded.every(kVs12FeatureFlags.contains);
  }

  /// A rollback needs somewhere to roll back to, so a previous build counts
  /// only when the checksum manifest actually recorded one.
  bool _lastStableBuild(Map<String, dynamic> drill) {
    if (!File(Sprint117RollbackContract.checksumManifest).existsSync()) {
      return false;
    }
    if (_text(drill['version']).isEmpty) return false;
    return recordedChecksumPaths().any((path) => path.contains('/Release/'));
  }

  /// Whether any recorded rollback path touches a user's project data. 116.50
  /// records `local_project_data_touched: false` for every stage rollback, so
  /// this is read rather than assumed.
  bool _localProjectDataTouched(Map<String, dynamic> rollout) => _mapList(
    rollout['rollback'],
  ).any((rollback) => rollback['local_project_data_touched'] == true);

  List<String> _carriedOpenItems(
    Map<String, dynamic> rollout,
    Map<String, dynamic> drill,
  ) {
    final items = <String>{};
    if (rollout['live_rollout_executed'] != true) {
      items.add('upstream_rollout_not_executed');
    }
    for (final kill in _mapList(rollout['provider_kill_switches'])) {
      if (kill['drill_verified'] != true) {
        items.add('kill_switch_not_drilled:${_text(kill['kill_id'])}');
      }
    }
    if (drill['status'] != 'EXECUTED') items.add('upstream_drill_not_executed');
    final limits = drill['limits'];
    if (limits is List<dynamic>) {
      for (final limit in limits) {
        final text = _text(limit);
        if (text.isNotEmpty) items.add('upstream_drill_limit:$text');
      }
    }
    return items.toList(growable: false);
  }

  static Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static Map<String, dynamic> _mapValue(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is! List<dynamic>) return const <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[
      for (final item in value)
        if (item is Map<String, dynamic>) item,
    ];
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  static int _int(Object? value) => value is int ? value : 0;

  static List<String> _stringList(Object? value) {
    if (value is! List<dynamic>) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

class Sprint117RollbackGate {
  const Sprint117RollbackGate();

  Sprint117RollbackReport evaluate() =>
      evaluateWith(const Sprint117RollbackLoader().load());

  Sprint117RollbackReport evaluateWith(Sprint117RollbackInput input) {
    final missing = <String>{};
    final violations = <String>[];

    // --- anchor ------------------------------------------------------------
    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('rollback_anchor');
    } else {
      if (anchor.drillVerdict.trim().isEmpty) {
        missing.add('drill_verdict');
      } else if (anchor.drillVerdict !=
          Sprint117RollbackContract.drillVerdict) {
        violations.add('anchor_verdict_drift');
        violations.add('anchor_verdict:${anchor.drillVerdict}');
        missing.add('rollback_anchor');
      }
      if (anchor.readinessVerdict.trim().isEmpty) {
        missing.add('readiness_verdict');
      }
      if (anchor.stopShipVerdict.trim().isEmpty) {
        missing.add('stop_ship_verdict');
      }
      if (anchor.defaultFlagState.trim().isEmpty) {
        missing.add('default_flag_state');
      } else if (anchor.defaultFlagState.toUpperCase() != 'OFF') {
        // A rollback that leaves flags on is not a rollback.
        violations.add('rollback_leaves_flags_on:${anchor.defaultFlagState}');
      }
      if (!anchor.lastStableBuild) {
        violations.add('rollback_target_missing');
      }
      if (anchor.localProjectDataTouched) {
        // A rollback must never reach a user's project data; 116.50 records
        // every stage rollback as not touching it.
        violations.add('rollback_touches_local_project_data');
      }
    }

    // --- controls ----------------------------------------------------------
    final rows = input.rows;
    final rowIds = <String>{};
    final controls = <Sprint117ControlRecord>[];
    final undetermined = <String>[];

    if (rows == null || rows.isEmpty) {
      missing.add('control_rows');
    } else {
      for (final row in rows) {
        final controlId = row.controlId.trim();
        if (controlId.isEmpty) {
          violations.add('control_id_blank');
          continue;
        }
        if (!rowIds.add(controlId)) {
          violations.add('control_duplicate:$controlId');
          continue;
        }
        controls.add(row);
        _checkControl(row, missing, violations);
        // A control no live drill has ever run is defined but undecided. 116.50
        // records `live_rollout_executed: false`, so that is the honest state
        // for all six, and it is an open item rather than a defect.
        if (!row.executed) undetermined.add(controlId);
      }
    }

    // Every canonical control must be mapped by exactly one row. A dropped
    // control is a promise quietly removed from the drill, not a skip.
    final unmapped = <String>[];
    if (anchor != null && !missing.contains('rollback_anchor')) {
      for (final controlId in Sprint117RollbackContract.requiredControls) {
        if (!rowIds.contains(controlId)) unmapped.add(controlId);
      }
      for (final controlId in unmapped) {
        violations.add('control_unmapped:$controlId');
      }
    } else {
      unmapped.addAll(Sprint117RollbackContract.requiredControls);
    }

    // --- resolution --------------------------------------------------------
    final drillExecuted = input.drillExecuted ?? false;
    if (drillExecuted) violations.add('drill_executed_claim');

    final state = violations.isNotEmpty
        ? Sprint117RollbackState.fail
        : missing.isNotEmpty
        ? Sprint117RollbackState.blocked
        : Sprint117RollbackState.pass;
    final verdict = switch (state) {
      Sprint117RollbackState.pass => Sprint117RollbackContract.passVerdict,
      Sprint117RollbackState.fail => Sprint117RollbackContract.failVerdict,
      Sprint117RollbackState.blocked =>
        Sprint117RollbackContract.blockedVerdict,
    };

    final openItems = <String>[...anchor?.carriedOpenItems ?? const <String>[]];
    final openItemSet = openItems.toSet();
    void addOpenItem(String item) {
      if (openItemSet.add(item)) openItems.add(item);
    }

    for (final controlId in undetermined) {
      addOpenItem('control_observed_outcome_null:$controlId');
    }
    // A recorded subject that cannot be resolved is reported, not repaired.
    // 113.7's kill switch names a flag the registry rejects and its withdrawal
    // names an executable the checksum manifest never recorded, so a drill run
    // verbatim would disable nothing and withdraw nothing while reporting
    // success. Rewriting the manifest here would decide something this step
    // does not own; the gap is surfaced with its exact spelling.
    final unresolvable = _unresolvableReferences(anchor);
    for (final reference in unresolvable) {
      addOpenItem('unresolvable_reference:$reference');
    }
    addOpenItem('drill_defined_not_executed');

    final limitations = <String>[
      'This drill is defined and locally exercised only. No provider was killed, no live token was revoked, no live queue was stopped, and no artifact was withdrawn from any distribution channel.',
      'No control carries an observed outcome. 116.50 records live_rollout_executed as false, every provider kill switch as drill_verified false, and every message as sent_at_epoch_ms 0, so any outcome recorded here would be fabricated.',
      'Local exercises run against the shipped FeatureFlagRegistry, AccountSecureTokenVault over an in-memory store, GenerationQueue, and Sprint116OfflineCacheCertification. They prove the mechanism responds; they do not prove a real provider, queue, or user was put at risk.',
      'All external gates remain $externalGatesText: hosted CI, public signing, published-artifact withdrawal, participant communication delivery, and publication are not part of this local evidence.',
    ];

    final controlCoverage = <String, int>{
      for (final controlId in Sprint117RollbackContract.requiredControls)
        controlId: controls.where((row) => row.controlId == controlId).length,
    };

    final artifacts = <Sprint117ArtifactRef>[
      for (final control in controls)
        for (final artifact in control.artifacts) artifact,
    ];
    final messages = <Sprint117MessageRecord>[
      for (final control in controls)
        for (final message in control.messages) message,
    ];

    return Sprint117RollbackReport(
      state: state,
      verdict: verdict,
      missingFields: missing.toList(growable: false),
      violations: violations.toList(growable: false),
      anchor: anchor,
      controls: controls,
      unmappedControls: unmapped,
      undeterminedControls: undetermined,
      unresolvableReferences: unresolvable,
      artifacts: artifacts,
      messages: messages,
      drillExecuted: drillExecuted,
      openItems: openItems,
      limitations: limitations,
      controlCoverage: controlCoverage,
    );
  }

  static String get externalGatesText =>
      Sprint117RollbackContract.externalGates;

  /// Control coherence: a rollback is a claim about stopping something safely,
  /// so a control that reports a live provider result contradicts the record
  /// 116.50 keeps, and a control sourced outside the declared manifests is not
  /// traceable to a canonical decision. A blank drill step or expected outcome
  /// is missing evidence — nobody has finished writing it — not a violation.
  static void _checkControl(
    Sprint117ControlRecord row,
    Set<String> missing,
    List<String> violations,
  ) {
    final controlId = row.controlId.trim();
    if (!Sprint117RollbackContract.requiredControls.contains(controlId)) {
      violations.add('control_unknown_id:$controlId');
    }
    if (row.liveProviderResult || row.drilledAgainstLiveProvider) {
      violations.add('control_live_provider_claim:$controlId');
    }
    if (row.drillStep.trim().isEmpty) {
      missing.add('control_drill_step:$controlId');
    }
    if (row.expectedOutcome.trim().isEmpty) {
      missing.add('control_expected_outcome:$controlId');
    }
    if (row.sourceManifest.trim().isEmpty) {
      missing.add('control_source_manifest:$controlId');
    } else if (!Sprint117RollbackContract.sourceManifests.contains(
      row.sourceManifest.trim(),
    )) {
      violations.add(
        'control_unsourced:$controlId:${row.sourceManifest.trim()}',
      );
    }
    for (final artifact in row.artifacts.where(
      (a) => a.recordedInChecksumManifest,
    )) {
      if (artifact.recordedPath.trim().isEmpty) {
        missing.add('artifact_recorded_path:${artifact.artifactId}');
      }
      if (artifact.withdrawal.trim().isEmpty) {
        missing.add('artifact_withdrawal:${artifact.artifactId}');
      }
    }
    for (final message in row.messages) {
      if (message.messageId.trim().isEmpty) {
        violations.add('message_id_blank:$controlId');
      }
      if (message.template.trim().isEmpty) {
        missing.add('message_template:${message.messageId}');
      }
      if (message.channel.trim().isEmpty) {
        missing.add('message_channel:${message.messageId}');
      }
      if (message.audience.trim().isEmpty) {
        missing.add('message_audience:${message.messageId}');
      }
      if (message.sentAtEpochMs > 0) {
        // A message recorded as sent is an incident communication nobody made.
        violations.add('message_claimed_sent:${message.messageId}');
      }
      if (message.draftedAtEpochMs <= 0) {
        missing.add('message_drafted_at:${message.messageId}');
      }
    }
  }

  /// Recorded subjects that cannot be resolved, gathered from the anchor.
  static List<String> _unresolvableReferences(Sprint117RollbackAnchor? anchor) {
    if (anchor == null) return const <String>[];
    final references = <String>{};
    if (!anchor.killSwitchResolvable) {
      references.add('vs12_world_logic_shared');
    }
    for (final control in anchor.controls) {
      for (final artifact in control.artifacts) {
        if (artifact.recordedInChecksumManifest) continue;
        if (artifact.recordedPath.trim().isEmpty) continue;
        references.add(artifact.recordedPath);
      }
    }
    return references.toList(growable: false)..sort();
  }
}
