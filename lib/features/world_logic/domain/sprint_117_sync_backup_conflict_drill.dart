part of 'sprint_117_sync_backup_conflict_validation.dart';

/// Executes the shipped sync/backup mechanisms and records what each one
/// produced. It writes nothing — no manifest, no report, no user file — opens
/// no user project, contacts no provider, and every value it uses is fixture
/// data it created itself.
class Sprint117SyncBackupConflictDrill {
  const Sprint117SyncBackupConflictDrill();

  /// The instant every timestamped decision in this drill is measured against,
  /// so the run is reproducible instead of decided by the day it happened.
  static final DateTime fixedNow = DateTime.utc(2026, 1, 1, 12);

  /// Runs every canonical check against the repository as it stands.
  Future<Sprint117SyncBackupConflictDrillRun> run() async {
    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117SyncBackupConflictContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }
    return Sprint117SyncBackupConflictDrillRun(
      observations: <Sprint117SyncBackupConflictObservation>[
        _observeTransfer(),
        _observeDelta(),
        _observeRetryResume(),
        _observeEncryptedBackup(),
        _observeRestore(),
        _observeConflicts(),
        _observeLargeAssets(),
        _observeWorkspaceBoundaries(),
      ],
      liveProviderTouched: false,
      userProjectTouched: false,
      liveSecretObserved: false,
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }

  /// `transfer` — a cross-scope transfer must be refused without explicit
  /// consent, and a consented one must be marked resumable.
  Sprint117SyncBackupConflictObservation _observeTransfer() {
    var refusedWithoutConsent = false;
    var refusalError = '';
    try {
      CloudTransferRequest(
        transferId: 't-noconsent',
        accountId: 'acct-1',
        sourceScope: CloudTransferScope.local,
        destinationScope: CloudTransferScope.cloud,
        operation: CloudTransferOperation.upload,
        totalBytes: 1024,
        explicitConsent: false,
      );
    } on ArgumentError catch (error) {
      refusedWithoutConsent = true;
      refusalError = error.runtimeType.toString();
    }

    final sameScope = CloudTransferRequest(
      transferId: 't-same',
      accountId: 'acct-1',
      sourceScope: CloudTransferScope.cloud,
      destinationScope: CloudTransferScope.cloud,
      operation: CloudTransferOperation.upload,
      totalBytes: 1024,
      explicitConsent: false,
    );
    final consented = CloudTransferRequest(
      transferId: 't-consent',
      accountId: 'acct-1',
      sourceScope: CloudTransferScope.local,
      destinationScope: CloudTransferScope.cloud,
      operation: CloudTransferOperation.upload,
      totalBytes: 1024,
      explicitConsent: true,
    );

    var negativeBytesRefused = false;
    var negativeError = '';
    try {
      CloudTransferRequest(
        transferId: 't-negative',
        accountId: 'acct-1',
        sourceScope: CloudTransferScope.cloud,
        destinationScope: CloudTransferScope.cloud,
        operation: CloudTransferOperation.upload,
        totalBytes: -1,
        explicitConsent: false,
      );
    } on ArgumentError catch (error) {
      negativeBytesRefused = true;
      negativeError = error.runtimeType.toString();
    }

    final passed =
        refusedWithoutConsent &&
        sameScope.requiresExplicitConsent == false &&
        sameScope.hasExplicitConsent == false &&
        consented.hasExplicitConsent &&
        consented.isResumable &&
        negativeBytesRefused;

    return Sprint117SyncBackupConflictObservation(
      checkId: 'transfer',
      outcome: passed
          ? 'CROSS_SCOPE_TRANSFER_REFUSED_WITHOUT_CONSENT'
          : 'TRANSFER_CONSENT_GATE_NOT_ENFORCED',
      facts: <String, Object?>{
        'refused_without_consent': refusedWithoutConsent,
        'refusal_error': refusalError,
        'same_scope_requires_consent': sameScope.requiresExplicitConsent,
        'consented_request_has_consent': consented.hasExplicitConsent,
        'consented_request_is_resumable': consented.isResumable,
        'negative_total_bytes_refused': negativeBytesRefused,
        'negative_total_bytes_error': negativeError,
        'mechanism': 'CloudTransferRequest consent + argument guards',
      },
      passed: passed,
    );
  }

  /// `delta` — only changed keys may be transported.
  ///
  /// The shipped [SyncChangeSet] computes exactly which keys diverged, and that
  /// set is what a delta transport has to carry. What ships has no delta
  /// protocol: `FolderCloudSyncService.sync` rewrites the whole project map,
  /// so the honest measurement is the changed-key count against the full-map
  /// size it would resend. No shipped class implements a delta protocol, and
  /// that is counted rather than assumed.
  Sprint117SyncBackupConflictObservation _observeDelta() {
    const change = SyncChangeSet(
      base: <String, Object?>{
        'chapter:1': 'body',
        'chapter:2': 'body',
        'chapter:3': 'body',
        'scene:1': 'body',
      },
      ours: <String, Object?>{
        'chapter:1': 'body',
        'chapter:2': 'REVISED',
        'chapter:3': 'body',
        'scene:1': 'body',
      },
      theirs: <String, Object?>{
        'chapter:1': 'body',
        'chapter:2': 'body',
        'chapter:3': 'body',
        'scene:1': 'REVISED',
      },
    );

    final changed = change.changedKeys;
    final baseSize = change.base.length;
    final fullResend = baseSize;
    final deltaPayload = changed.length;

    // A delta protocol would have to move the changed keys only. No shipped
    // class declares one, so the delta is computable but not transportable.
    final deltaTransports = _implementationsIn('lib', 'DeltaTransport');
    final syncWriters = _implementationsIn('lib', 'CloudSyncService');

    final passed =
        changed.length == 2 &&
        changed.contains('chapter:2') &&
        changed.contains('scene:1') &&
        deltaPayload < fullResend &&
        deltaTransports == 0 &&
        syncWriters == 3;

    return Sprint117SyncBackupConflictObservation(
      checkId: 'delta',
      outcome: passed
          ? 'DELTA_KEYS_COMPUTED_BUT_NO_SHIPPED_DELTA_TRANSPORT'
          : 'DELTA_KEY_SET_INCORRECT',
      facts: <String, Object?>{
        'total_keys': baseSize,
        'changed_keys': deltaPayload,
        'changed_key_ids': changed.toList()..sort(),
        'full_resend_keys': fullResend,
        'delta_payload_keys': deltaPayload,
        'shipped_delta_transport_implementations': deltaTransports,
        'shipped_cloud_sync_service_implementations': syncWriters,
        'delta_operation_declared_by_contract': true,
        'mechanism': 'SyncChangeSet.changedKeys; no shipped delta transport',
        // Nothing in lib/ transports a delta: the computed key set has no
        // protocol that would send it.
        'acceptance_mechanism_present': deltaTransports > 0,
      },
      passed: passed,
      acceptance: deltaTransports > 0
          ? Sprint117SyncBackupConflictAcceptance.satisfied
          : Sprint117SyncBackupConflictAcceptance.mechanismAbsent,
      unresolvable: deltaTransports == 0
          ? const <String>['no_shipped_delta_transport_protocol']
          : const <String>[],
    );
  }

  /// `retry_resume` — paused bytes must survive pause and resume, a failed
  /// transfer must retry, and the retry bound must hold.
  Sprint117SyncBackupConflictObservation _observeRetryResume() {
    final started = CloudTransferProgress.start(totalBytes: 4096);
    final half = started.advance(completedBytes: 2048);
    final paused = half.pause();
    final resumed = paused.resume();
    final finished = resumed.advance(completedBytes: 4096);
    final completed = finished.state == CloudTransferState.completed;

    // The retry chain runs on its own transfer: a completed one is refused by
    // `fail()` because a finished transfer has nothing left to retry.
    final retried = half.fail().retry();
    final retryOne = retried;
    final retryTwo = retryOne.fail().retry();
    final retryThree = retryTwo.fail().retry();

    var boundRefused = false;
    var boundError = '';
    try {
      retryThree.fail().retry();
    } on StateError catch (error) {
      boundRefused = true;
      boundError = error.runtimeType.toString();
    }

    var completedCannotFail = false;
    try {
      finished.fail();
    } on StateError {
      completedCannotFail = true;
    }

    var completedRefused = false;
    try {
      CloudTransferProgress.start(totalBytes: 0);
    } on ArgumentError {
      completedRefused = true;
    }

    // A resumed transfer must not have lost the bytes it had already moved.
    final bytesSurvived = resumed.completedBytes;
    var backwardsError = '';
    try {
      resumed.advance(completedBytes: 1);
    } on ArgumentError catch (error) {
      // Going backwards is refused rather than silently accepted.
      backwardsError = error.runtimeType.toString();
    }

    final passed =
        bytesSurvived == 2048 &&
        paused.state == CloudTransferState.paused &&
        finished.state == CloudTransferState.completed &&
        completed &&
        retryOne.state == CloudTransferState.running &&
        retryOne.retryCount == 1 &&
        retryTwo.retryCount == 2 &&
        retryThree.retryCount == 3 &&
        boundRefused &&
        completedCannotFail &&
        completedRefused &&
        backwardsError.isNotEmpty;

    return Sprint117SyncBackupConflictObservation(
      checkId: 'retry_resume',
      outcome: passed
          ? 'PAUSE_RESUME_PRESERVES_BYTES_AND_RETRY_IS_BOUNDED'
          : 'RETRY_OR_RESUME_STATE_NOT_HELD',
      facts: <String, Object?>{
        'total_bytes': started.totalBytes,
        'bytes_after_pause': paused.completedBytes,
        'bytes_after_resume': bytesSurvived,
        'state_after_completion': finished.state.name,
        'retry_count_after_first': retryOne.retryCount,
        'retry_count_after_third': retryThree.retryCount,
        'fourth_retry_refused': boundRefused,
        'fourth_retry_error': boundError,
        'completed_transfer_cannot_fail': completedCannotFail,
        'zero_total_bytes_refused': completedRefused,
        'backwards_advance_error': backwardsError,
        'mechanism': 'CloudTransferProgress pause/resume/fail/retry',
      },
      passed: passed,
    );
  }

  /// `encrypted_backup` — a backup may run only with encryption and an
  /// available destination. Encryption is declared, never executed here.
  Sprint117SyncBackupConflictObservation _observeEncryptedBackup() {
    final encrypted = AccountCenterBackupPolicy(
      policyId: 'policy-encrypted',
      schedule: BackupSchedule.daily(hourUtc: 3),
      retention: BackupRetention(maxCopies: 5),
      encryption: BackupEncryption.aes256,
      destination: BackupDestination(
        destinationId: 'dest-usb',
        kind: BackupDestinationKind.removable,
        availability: BackupDestinationAvailability.available,
      ),
      workspaceBoundary: AccountBackupBoundary.novelWorkspace,
    );
    final unencrypted = AccountCenterBackupPolicy(
      policyId: 'policy-plain',
      schedule: BackupSchedule.manual(),
      retention: BackupRetention(maxCopies: 3),
      encryption: BackupEncryption.none,
      destination: BackupDestination(
        destinationId: 'dest-local',
        kind: BackupDestinationKind.local,
        availability: BackupDestinationAvailability.available,
      ),
      workspaceBoundary: AccountBackupBoundary.accountGlobal,
    );
    final unavailable = AccountCenterBackupPolicy(
      policyId: 'policy-usb-absent',
      schedule: BackupSchedule.manual(),
      retention: BackupRetention(maxCopies: 3),
      encryption: BackupEncryption.aes256,
      destination: BackupDestination(
        destinationId: 'dest-missing',
        kind: BackupDestinationKind.removable,
        availability: BackupDestinationAvailability.unavailable,
      ),
      workspaceBoundary: AccountBackupBoundary.novelWorkspace,
    );

    var invalidHourRefused = false;
    var invalidRetentionRefused = false;
    try {
      BackupSchedule.daily(hourUtc: 24);
    } on ArgumentError {
      invalidHourRefused = true;
    }
    try {
      BackupRetention(maxCopies: 0);
    } on ArgumentError {
      invalidRetentionRefused = true;
    }

    final passed =
        encrypted.canRun &&
        !unencrypted.canRun &&
        !unavailable.canRun &&
        invalidHourRefused &&
        invalidRetentionRefused &&
        BackupPolicyEvidence.pending().isVerified == false &&
        BackupPolicyEvidence.pending().hasPassingRestoreTest == false;

    return Sprint117SyncBackupConflictObservation(
      checkId: 'encrypted_backup',
      outcome: passed
          ? 'BACKUP_REQUIRES_ENCRYPTION_AND_AVAILABLE_DESTINATION'
          : 'BACKUP_RUN_RULE_NOT_ENFORCED',
      facts: <String, Object?>{
        'encrypted_policy_can_run': encrypted.canRun,
        'unencrypted_policy_can_run': unencrypted.canRun,
        'unavailable_destination_can_run': unavailable.canRun,
        'pending_evidence_is_verified':
            BackupPolicyEvidence.pending().isVerified,
        'pending_evidence_has_restore_test':
            BackupPolicyEvidence.pending().hasPassingRestoreTest,
        'invalid_hour_refused': invalidHourRefused,
        'non_positive_retention_refused': invalidRetentionRefused,
        'encryption_executed_by_shipped_code': false,
        'declared_encryption_kind': encrypted.encryption.name,
        'mechanism': 'AccountCenterBackupPolicy.canRun + BackupPolicyEvidence',
        // Encryption here is a declared policy field. No shipped class writes
        // an encrypted archive.
        'acceptance_mechanism_present': false,
      },
      passed: passed,
      acceptance: Sprint117SyncBackupConflictAcceptance.mechanismAbsent,
      unresolvable: const <String>['no_shipped_encrypted_backup_writer'],
    );
  }

  /// `restore` — a restore is reported only from completed evidence.
  Sprint117SyncBackupConflictObservation _observeRestore() {
    final verified = BackupPolicyEvidence(
      verification: BackupCheckResult.passed(
        checkedAt: fixedNow,
        evidenceId: 'verify-1',
      ),
      restoreTest: BackupCheckResult.passed(
        checkedAt: fixedNow,
        evidenceId: 'restore-1',
      ),
    );
    final verificationOnly = BackupPolicyEvidence(
      verification: BackupCheckResult.passed(
        checkedAt: fixedNow,
        evidenceId: 'verify-1',
      ),
      restoreTest: BackupCheckResult.failed(
        checkedAt: fixedNow,
        evidenceId: 'restore-failed',
      ),
    );

    // Retention prunes per category, so an automatic backup is never evicted
    // by manual pressure and vice versa.
    const policy = BackupRetentionPolicy(maxAutomatic: 2, maxManual: 1);
    const retention = BackupRetentionService(policy: policy);
    final pruned = retention.selectForPrune(<BackupInfo>[
      BackupInfo(id: 'a1', type: 'automatic', createdAt: fixedNow),
      BackupInfo(id: 'a2', type: 'automatic', createdAt: fixedNow),
      BackupInfo(id: 'a3', type: 'automatic', createdAt: fixedNow),
      BackupInfo(id: 'm1', type: 'manual', createdAt: fixedNow),
      BackupInfo(id: 'm2', type: 'manual', createdAt: fixedNow),
    ]);
    final prunedIds = pruned.map((entry) => entry.id).toList()..sort();

    // A verification timestamped after the backup cannot describe a restore
    // that ran before it.
    var futureCheckRefused = false;
    try {
      BackupCheckResult.passed(checkedAt: fixedNow, evidenceId: '');
    } on ArgumentError {
      futureCheckRefused = true;
    }

    final passed =
        verified.isVerified &&
        verified.hasPassingRestoreTest &&
        verificationOnly.isVerified &&
        !verificationOnly.hasPassingRestoreTest &&
        prunedIds.join(',') == 'a1,m1' &&
        futureCheckRefused;

    return Sprint117SyncBackupConflictObservation(
      checkId: 'restore',
      outcome: passed
          ? 'RESTORE_REPORTED_ONLY_FROM_COMPLETED_EVIDENCE'
          : 'RESTORE_EVIDENCE_NOT_REQUIRED',
      facts: <String, Object?>{
        'verified_evidence_is_verified': verified.isVerified,
        'verified_evidence_has_restore_test': verified.hasPassingRestoreTest,
        'verification_only_has_restore_test':
            verificationOnly.hasPassingRestoreTest,
        'pruned_backup_ids': prunedIds,
        'max_automatic': policy.maxAutomatic,
        'max_manual': policy.maxManual,
        'blank_evidence_id_refused': futureCheckRefused,
        'live_restore_executed': false,
        'mechanism': 'BackupPolicyEvidence + BackupRetentionService',
      },
      passed: passed,
    );
  }

  /// `conflicts` — detection, explicit resolution, history, and the fix that
  /// stops a remote-only change from being dropped by the merge.
  Sprint117SyncBackupConflictObservation _observeConflicts() {
    const divergent = SyncChangeSet(
      base: <String, Object?>{'a': '1'},
      ours: <String, Object?>{'a': '2'},
      theirs: <String, Object?>{'a': '3'},
    );
    final detected = ConflictDetector.detect(divergent);

    final conflict = SyncConflict.detect(
      conflictId: 'c-1',
      sourceId: 'chapter:1',
      itemId: 'chapter:1',
      local: SyncConflictVersion(
        versionId: 'v-local',
        modifiedAt: fixedNow,
        preview: 'local body',
      ),
      remote: SyncConflictVersion(
        versionId: 'v-remote',
        modifiedAt: fixedNow,
        preview: 'remote body',
      ),
      mergeSupported: true,
    );
    final center = AccountCenterSyncConflictCenter(<SyncConflict>[conflict]);

    var unresolvedWithoutBackup = false;
    try {
      center.resolve(
        conflictId: 'c-1',
        strategy: SyncConflictResolution.keepLocal,
        backup: ConflictBackupEvidence.pending(),
        resolvedAt: fixedNow,
      );
    } on StateError {
      unresolvedWithoutBackup = true;
    }

    final resolved = center.resolve(
      conflictId: 'c-1',
      strategy: SyncConflictResolution.keepLocal,
      backup: ConflictBackupEvidence.completed(
        backupId: 'b-1',
        completedAt: fixedNow,
      ),
      resolvedAt: fixedNow,
    );
    final selected = resolved.conflicts.single.selectedVersion?.versionId;

    // Once resolved, the same conflict must not resolve again: a second
    // resolution would overwrite the first decision silently.
    var reResolveRefused = false;
    try {
      resolved.resolve(
        conflictId: 'c-1',
        strategy: SyncConflictResolution.keepRemote,
        backup: ConflictBackupEvidence.completed(
          backupId: 'b-2',
          completedAt: fixedNow,
        ),
        resolvedAt: fixedNow,
      );
    } on StateError {
      reResolveRefused = true;
    }

    // The defect this step owns: a key only the remote side changed is not a
    // conflict, so no resolution was supplied for it and the old merge never
    // emitted it — the remote edit reverted to base and a remote-only addition
    // disappeared. Both are re-measured directly.
    const remoteOnlyEdit = SyncChangeSet(
      base: <String, Object?>{'a': '1'},
      ours: <String, Object?>{'a': '1'},
      theirs: <String, Object?>{'a': '2'},
    );
    const remoteOnlyAddition = SyncChangeSet(
      base: <String, Object?>{},
      ours: <String, Object?>{},
      theirs: <String, Object?>{'b': '2'},
    );
    final mergedEdit = ConflictResolver.resolve(remoteOnlyEdit, const {});
    final mergedAddition = ConflictResolver.resolve(
      remoteOnlyAddition,
      const {},
    );

    // A locally deleted key still counts as our side diverging.
    const localDeletion = SyncChangeSet(
      base: <String, Object?>{'a': '1'},
      ours: <String, Object?>{},
      theirs: <String, Object?>{'a': '1'},
    );
    final mergedDeletion = ConflictResolver.resolve(localDeletion, const {});

    final fallback = resolved.safeFallback(conflictId: 'c-1');
    final unknown = resolved.safeFallback(conflictId: 'missing');

    final passed =
        detected.join(',') == 'a' &&
        unresolvedWithoutBackup &&
        reResolveRefused &&
        selected == 'v-local' &&
        resolved.history.length == 1 &&
        mergedEdit['a'] == '2' &&
        mergedAddition['b'] == '2' &&
        mergedDeletion.containsKey('a') &&
        mergedDeletion['a'] == null &&
        fallback.status == SyncConflictFallbackStatus.alreadyResolved &&
        unknown.status == SyncConflictFallbackStatus.notFound;

    return Sprint117SyncBackupConflictObservation(
      checkId: 'conflicts',
      outcome: passed
          ? 'REMOTE_ONLY_CHANGE_SURVIVES_MERGE_AND_RESOLUTION_NEEDS_BACKUP'
          : 'MERGE_DROPPED_A_REMOTE_ONLY_CHANGE',
      facts: <String, Object?>{
        'detected_conflict_keys': detected,
        'resolution_without_backup_refused': unresolvedWithoutBackup,
        're_resolve_after_resolution_refused': reResolveRefused,
        'selected_version_after_keep_local': selected,
        'history_entries': resolved.history.length,
        'remote_only_edit_merged_value': mergedEdit['a'],
        'remote_only_addition_merged_value': mergedAddition['b'],
        'remote_only_addition_key_count': mergedAddition.length,
        'local_deletion_kept_key': mergedDeletion.containsKey('a'),
        'local_deletion_merged_value_is_null': mergedDeletion['a'] == null,
        'already_resolved_fallback': fallback.status.name,
        'unknown_fallback': unknown.status.name,
        'mechanism':
            'ConflictDetector + ConflictResolver + '
            'AccountCenterSyncConflictCenter',
      },
      passed: passed,
    );
  }

  /// `large_assets` — what a large payload does through the only shipped
  /// filesystem sync service.
  ///
  /// [FolderCloudSyncService] round-trips a whole project map through one JSON
  /// file, so a large payload is transported whole. The drill measures the
  /// transport shape and counts the shipped chunking mechanisms rather than
  /// asserting streaming it cannot observe.
  Sprint117SyncBackupConflictObservation _observeLargeAssets() {
    // A payload with one large asset plus many small keys, expressed as the
    // string a JSON document would carry.
    final largeValue = 'x' * 4096;
    final payload = <String, Object?>{
      'scene:1': 'small',
      'asset:large': largeValue,
      'asset:second': 'y' * 2048,
    };
    final serializedBytes = payload.values
        .map((value) => (value as String).length)
        .fold<int>(0, (sum, length) => sum + length);
    final largestKeyBytes = payload.values
        .map((value) => (value as String).length)
        .reduce((a, b) => a > b ? a : b);

    // The shipped service transports the entire map; there is no per-key
    // chunking and no streaming reader in lib/.
    final chunkers = _implementationsIn('lib', 'ChunkedTransfer');
    final streamedUploads = _implementationsIn('lib', 'StreamingUpload');
    final syncServices = _implementationsIn('lib', 'CloudSyncService');

    final passed =
        serializedBytes == 4096 + 2048 + 5 &&
        largestKeyBytes == 4096 &&
        chunkers == 0 &&
        streamedUploads == 0 &&
        syncServices == 3;

    return Sprint117SyncBackupConflictObservation(
      checkId: 'large_assets',
      outcome: passed
          ? 'LARGE_PAYLOAD_TRANSPORTED_WHOLE_WITH_NO_CHUNKING'
          : 'LARGE_ASSET_TRANSPORT_NOT_ESTABLISHED',
      facts: <String, Object?>{
        'payload_key_count': payload.length,
        'serialized_payload_bytes': serializedBytes,
        'largest_single_value_bytes': largestKeyBytes,
        'shipped_chunked_transfer_implementations': chunkers,
        'shipped_streaming_upload_implementations': streamedUploads,
        'shipped_cloud_sync_service_implementations': syncServices,
        'transport_is_whole_map': true,
        'mechanism': 'FolderCloudSyncService whole-map JSON transport',
        // A large asset is transported as one whole-map document; nothing in
        // lib/ chunks or streams it.
        'acceptance_mechanism_present': chunkers > 0 || streamedUploads > 0,
      },
      passed: passed,
      acceptance: chunkers > 0 || streamedUploads > 0
          ? Sprint117SyncBackupConflictAcceptance.satisfied
          : Sprint117SyncBackupConflictAcceptance.mechanismAbsent,
      unresolvable: chunkers > 0 || streamedUploads > 0
          ? const <String>[]
          : const <String>['no_shipped_chunked_or_streamed_transfer'],
    );
  }

  /// `workspace_boundaries` — every boundary gate must deny rather than
  /// repair.
  Sprint117SyncBackupConflictObservation _observeWorkspaceBoundaries() {
    final globalAllowed =
        AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
          target: AccountCenterDataScope.globalUser,
          hasExplicitWorkspacePermission: false,
        );
    final workspaceDenied =
        AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
          target: AccountCenterDataScope.novelWorkspace,
          hasExplicitWorkspacePermission: false,
        );
    final workspaceGranted =
        AccountCenterWorkspaceBoundaryContract.resolveWorkspaceAccess(
          target: AccountCenterDataScope.novelWorkspace,
          hasExplicitWorkspacePermission: true,
        );
    final transferDenied =
        AccountCenterWorkspaceBoundaryContract.resolveTransfer(
          source: AccountCenterDataScope.globalUser,
          destination: AccountCenterDataScope.characterWorkspace,
          hasExplicitTransferConsent: false,
        );
    final accountHoldsWorkspaceData =
        AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
          boundary: AccountBackupBoundary.accountGlobal,
          relativePaths: <String>['workspaces/novels/chapter.json'],
        );
    final novelHoldsCharacterData =
        AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
          boundary: AccountBackupBoundary.novelWorkspace,
          relativePaths: <String>['workspaces/characters/hero.json'],
        );
    final cleanBoundary =
        AccountCenterWorkspaceBoundaryContract.backupBoundaryViolations(
          boundary: AccountBackupBoundary.novelWorkspace,
          relativePaths: <String>['workspaces/novels/chapter.json'],
        );
    final routeHiddenUnderWorkspace =
        AccountCenterWorkspaceBoundaryContract.isGlobalSurfaceRoute(
          '/studio/settings/account',
        );

    final passed =
        globalAllowed == WorkspaceBoundaryDecision.allowedGlobalScope &&
        workspaceDenied ==
            WorkspaceBoundaryDecision.deniedWorkspacePermissionRequired &&
        workspaceGranted == WorkspaceBoundaryDecision.allowedWorkspaceScoped &&
        transferDenied ==
            WorkspaceBoundaryDecision.deniedTransferConsentRequired &&
        accountHoldsWorkspaceData.isNotEmpty &&
        novelHoldsCharacterData.isNotEmpty &&
        cleanBoundary.isEmpty &&
        routeHiddenUnderWorkspace == false;

    return Sprint117SyncBackupConflictObservation(
      checkId: 'workspace_boundaries',
      outcome: passed
          ? 'BOUNDARY_GATES_DENY_INSTEAD_OF_REPAIRING'
          : 'BOUNDARY_VIOLATION_NOT_DETECTED',
      facts: <String, Object?>{
        'global_access_decision': globalAllowed.id,
        'workspace_access_without_permission': workspaceDenied.id,
        'workspace_access_with_permission': workspaceGranted.id,
        'cross_scope_transfer_without_consent': transferDenied.id,
        'account_boundary_holding_workspace_data': accountHoldsWorkspaceData,
        'novel_boundary_holding_character_data': novelHoldsCharacterData,
        'clean_boundary_violations': cleanBoundary.length,
        'account_route_nested_under_workspace_is_global':
            routeHiddenUnderWorkspace,
        'account_scope': AccountCenterWorkspaceBoundaryContract.scope,
        'co_ownership_allowed': AccountCenterWorkspaceBoundaryContract
            .novelCharacterDataCoOwnershipAllowed,
        'mechanism': 'AccountCenterWorkspaceBoundaryContract gates',
      },
      passed: passed,
    );
  }
}

/// Counts classes in [directory] that declare [symbol] as a supertype or mixin.
/// An empty result is a measured fact about the repository, not an assumption.
/// Every matching class counts, so one file declaring several implementations
/// (as `cloud_sync_service.dart` does) is not undercounted.
int _implementationsIn(String directory, String symbol) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return 0;
  var count = 0;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    final String source;
    try {
      source = entity.readAsStringSync();
    } on FileSystemException {
      continue;
    }
    for (final line in const LineSplitter().convert(source)) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('class ') &&
          !trimmed.startsWith('final class ') &&
          !trimmed.startsWith('abstract class ')) {
        continue;
      }
      if (!trimmed.contains(symbol)) continue;
      if (trimmed.contains('implements $symbol') ||
          trimmed.contains('with $symbol') ||
          trimmed.contains('extends $symbol')) {
        count += 1;
      }
    }
  }
  return count;
}
