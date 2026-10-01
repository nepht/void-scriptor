part of 'sprint_117_identity_workflow_validation.dart';

/// Executes the shipped identity mechanisms and records what each one
/// produced. It writes nothing — no manifest, no report, no user file — it
/// contacts no provider, and the only secret material it ever holds is fixture
/// text the drill itself created inside an in-memory credential store.
class Sprint117IdentityWorkflowDrill {
  const Sprint117IdentityWorkflowDrill();

  /// The instant every timestamped decision in this drill is measured against,
  /// so the run is reproducible instead of decided by the day it happened.
  static final DateTime fixedNow = DateTime.utc(2026, 1, 1, 12);

  /// Runs every canonical check against the repository as it stands.
  Future<Sprint117IdentityWorkflowDrillRun> run() async {
    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117IdentityWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }
    return Sprint117IdentityWorkflowDrillRun(
      observations: <Sprint117IdentityWorkflowObservation>[
        await _observeConnect(),
        _observeLink(),
        _observeCollision(),
        await _observeReauth(),
        await _observeUnlink(),
        _observeLastMethod(),
        _observeRecovery(),
        await _observeRevoke(),
      ],
      liveProviderTouched: false,
      userProjectTouched: false,
      liveSecretObserved: false,
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }

  /// `connect` — count what the shipped manifest would actually let a user
  /// connect, then prove the authorization-code flow itself still works.
  ///
  /// The honest finding is the gap between the two: the certification snapshot
  /// records identity providers as certified, while every entry the shipped
  /// `ProviderConnectorManifest.standard` builds carries
  /// `availability: UNVERIFIED`, so `isConnectable` is false for all of them
  /// and [AccountOAuthFlow] refuses each one before an exchange is attempted.
  Future<Sprint117IdentityWorkflowObservation> _observeConnect() async {
    final standard = ProviderConnectorManifest.standard;
    final total = standard.all.length;
    var connectable = 0;
    var identityConnectable = 0;
    final availabilities = <String, int>{};
    for (final entry in standard.all) {
      availabilities.update(
        entry.availability.wireName,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (entry.isConnectable) {
        connectable += 1;
        if (entry.category == ProviderConnectorCategory.identity) {
          identityConnectable += 1;
        }
      }
    }

    // The refusal is measured, not assumed: hand the flow a shipped identity
    // connector and record the error the shipped gate raises.
    final shippedIdentity = standard.all.firstWhere(
      (entry) =>
          entry.category == ProviderConnectorCategory.identity &&
          entry.authType == ProviderAuthType.oauth2Pkce,
    );
    final refusal = _captureOAuthError(
      () => _flow(broker: _DrillBroker()).beginAuthorization(
        configuration: _configurationFor(shippedIdentity),
        consent: _consent(),
      ),
    );

    // The working path: a fixture connector that satisfies the same shipped
    // gate, then a real exchange, a real callback, and a real token grant.
    final flow = _flow(broker: _DrillBroker());
    final request = flow.beginAuthorization(
      configuration: _fixtureConfiguration(),
      consent: _consent(),
    );
    final result = await _captureOAuth(
      () => flow.completeAuthorization(callback: _callbackFor(request)),
    );
    final grant = result?.tokenGrant;
    final identities = flow.linkedIdentities;

    // A single-use authorization state is a security property worth measuring
    // rather than trusting: replaying the same callback must be refused.
    final replayError = await _captureOAuthAsync(
      () => flow.completeAuthorization(callback: _callbackFor(request)),
    );

    // A grant from a superseded generation must not stay usable: rotate first,
    // then prove the old grant can neither unlink nor rotate again.
    final rotating = _flow(broker: _DrillBroker());
    final rotatingResult = await _completeExchange(rotating);
    final rotated = await _captureOAuth(
      () => rotating.rotateTokens(currentGrant: rotatingResult.tokenGrant),
    );
    final staleUnlinkError = await _captureOAuthAsync(
      () => rotating.unlink(
        grant: rotatingResult.tokenGrant,
        decision: OAuthUnlinkDecision.unlink,
      ),
    );
    final staleRotateError = await _captureOAuthAsync(
      () => rotating.rotateTokens(currentGrant: rotatingResult.tokenGrant),
    );

    final passed =
        connectable == 0 &&
        identityConnectable == 0 &&
        refusal == 'connectorUnavailable' &&
        result != null &&
        result.identity.connectionId.isNotEmpty &&
        identities.length == 1 &&
        grant != null &&
        grant.scopes.contains('account.read') &&
        grant.generation == 1 &&
        replayError == 'stateMismatch' &&
        rotated != null &&
        rotated.tokenGrant.generation == 2 &&
        staleUnlinkError == 'staleTokenGeneration' &&
        staleRotateError == 'staleTokenGeneration';

    return Sprint117IdentityWorkflowObservation(
      checkId: 'connect',
      outcome: passed
          ? 'NO_SHIPPED_CONNECTOR_CONNECTABLE_FLOW_COMPLETES_ON_FIXTURE'
          : 'CONNECT_PATH_NOT_ESTABLISHED',
      facts: <String, Object?>{
        'shipped_connector_count': total,
        'shipped_connectable_count': connectable,
        'shipped_identity_connectable_count': identityConnectable,
        'shipped_availability_mix': availabilities,
        'refused_connector_id': shippedIdentity.providerId,
        'refused_with_error': refusal,
        'fixture_exchange_completed': result != null,
        'fixture_connection_id': result?.identity.connectionId,
        'fixture_token_generation': grant?.generation,
        'fixture_granted_scopes': grant?.scopes.toList(growable: false)
          ?..sort(),
        'linked_identities_in_memory': identities.length,
        'pkce_code_challenge_present':
            request.codeChallenge.length == 43 &&
            !request.codeChallenge.contains('='),
        'authorization_host': request.authorizationUri.host,
        'callback_replay_error': replayError,
        'rotated_generation': rotated?.tokenGrant.generation,
        'stale_generation_unlink_error': staleUnlinkError,
        'stale_generation_rotate_error': staleRotateError,
        'mechanism': 'AccountOAuthFlow + ProviderConnectorManifest.standard',
        // The recorded fact that decides whether this acceptance can be
        // satisfied: zero shipped connectors are connectable today.
        'acceptance_mechanism_present': connectable > 0,
      },
      passed: passed,
      acceptance: connectable > 0
          ? Sprint117IdentityWorkflowAcceptance.satisfied
          : Sprint117IdentityWorkflowAcceptance.mechanismAbsent,
      unresolvable: connectable == 0
          ? const <String>['no_shipped_identity_connector_connectable']
          : const <String>[],
    );
  }

  /// `link` — a second provider identity must join the account and be readable
  /// back, and a credential owned by another account must never be stolen.
  Sprint117IdentityWorkflowObservation _observeLink() {
    const googleSubject = IdentityCredential('google', 'google-subject-1');
    final service = IdentityLinkingService(<IdentityAccount>[
      IdentityAccount(
        accountId: 'account-a',
        email: 'writer@example.test',
        identities: <IdentityCredential>{googleSubject},
        recoveryEmail: null,
      ),
    ]);
    const second = IdentityCredential('github', 'github-subject-9');
    final linked = service.link(
      targetAccountId: 'account-a',
      candidate: second,
      candidateEmail: 'github@example.test',
      confirmedSafeMerge: false,
    );
    final reread = service.find('account-a')!;

    // A confirmed safe merge must keep both identities and drop the secondary.
    const githubSubject = IdentityCredential('github', 'github-subject-2');
    final mergeService = IdentityLinkingService(<IdentityAccount>[
      IdentityAccount(
        accountId: 'account-a',
        email: 'a@example.test',
        identities: <IdentityCredential>{googleSubject},
        recoveryEmail: null,
      ),
      IdentityAccount(
        accountId: 'account-b',
        email: 'b@example.test',
        identities: <IdentityCredential>{githubSubject},
        recoveryEmail: null,
      ),
    ]);
    final merged = mergeService.merge(
      primaryAccountId: 'account-a',
      secondaryAccountId: 'account-b',
      confirmedSafeMerge: true,
    );

    // Linking a credential owned by another account must be refused even with
    // the merge confirmed, and the owner must keep it.
    const foreign = IdentityCredential('x', 'x-subject-3');
    final foreignService = IdentityLinkingService(<IdentityAccount>[
      IdentityAccount(
        accountId: 'account-b',
        email: 'b@example.test',
        identities: <IdentityCredential>{foreign},
        recoveryEmail: null,
      ),
      IdentityAccount(
        accountId: 'account-a',
        email: 'a@example.test',
        identities: <IdentityCredential>{githubSubject},
        recoveryEmail: null,
      ),
    ]);
    final takeoverError = _captureLinkingError(
      () => foreignService.link(
        targetAccountId: 'account-a',
        candidate: foreign,
        candidateEmail: 'b@example.test',
        confirmedSafeMerge: true,
      ),
    );

    final passed =
        linked.identities.contains(second) &&
        reread.identities.length == 2 &&
        merged.identities.containsAll(<IdentityCredential>[
          googleSubject,
          githubSubject,
        ]) &&
        mergeService.find('account-b') == null &&
        takeoverError == 'IdentityTakeoverException' &&
        foreignService.find('account-b')!.identities.contains(foreign);

    return Sprint117IdentityWorkflowObservation(
      checkId: 'link',
      outcome: passed
          ? 'SECOND_IDENTITY_LINKED_MERGED_AND_READABLE_BACK'
          : 'LINK_DID_NOT_PERSIST',
      facts: <String, Object?>{
        'identities_after_link': linked.identities.length,
        'identities_after_reread': reread.identities.length,
        'linked_credential': '${second.providerId}/${second.subject}',
        'merged_identity_count': merged.identities.length,
        'secondary_account_after_merge': mergeService.find('account-b'),
        'takeover_attempt_error': takeoverError,
        'mechanism': 'IdentityLinkingService.link + merge',
        'acceptance_mechanism_present': true,
      },
      passed: passed,
      acceptance: Sprint117IdentityWorkflowAcceptance.satisfied,
      unresolvable: const <String>[],
    );
  }

  /// `collision` — duplicate email, duplicate identity, unconfirmed merge, and
  /// overlapping merge must each be rejected without mutating either account.
  Sprint117IdentityWorkflowObservation _observeCollision() {
    const googleSubject = IdentityCredential('google', 'google-subject-1');
    const githubSubject = IdentityCredential('github', 'github-subject-2');
    IdentityLinkingService service() =>
        IdentityLinkingService(<IdentityAccount>[
          IdentityAccount(
            accountId: 'account-a',
            email: 'writer@example.test',
            identities: <IdentityCredential>{googleSubject},
            recoveryEmail: null,
          ),
          IdentityAccount(
            accountId: 'account-b',
            email: 'other@example.test',
            identities: <IdentityCredential>{githubSubject},
            recoveryEmail: null,
          ),
        ]);

    final duplicateEmail = service();
    final duplicateEmailError = _captureLinkingError(
      () => duplicateEmail.link(
        targetAccountId: 'account-a',
        candidate: const IdentityCredential('discord', 'discord-1'),
        candidateEmail: 'OTHER@example.test',
        confirmedSafeMerge: false,
      ),
    );

    final duplicateIdentity = service();
    final duplicateIdentityError = _captureLinkingError(
      () => duplicateIdentity.link(
        targetAccountId: 'account-a',
        candidate: googleSubject,
        candidateEmail: 'writer-alt@example.test',
        confirmedSafeMerge: false,
      ),
    );

    final unconfirmedMerge = service();
    final unconfirmedError = _captureLinkingError(
      () => unconfirmedMerge.merge(
        primaryAccountId: 'account-a',
        secondaryAccountId: 'account-b',
        confirmedSafeMerge: false,
      ),
    );

    const shared = IdentityCredential('google', 'shared-1');
    final overlappingMerge = IdentityLinkingService(<IdentityAccount>[
      IdentityAccount(
        accountId: 'account-a',
        email: 'a@example.test',
        identities: <IdentityCredential>{shared},
        recoveryEmail: null,
      ),
      IdentityAccount(
        accountId: 'account-b',
        email: 'b@example.test',
        identities: <IdentityCredential>{shared},
        recoveryEmail: null,
      ),
    ]);
    final overlappingError = _captureLinkingError(
      () => overlappingMerge.merge(
        primaryAccountId: 'account-a',
        secondaryAccountId: 'account-b',
        confirmedSafeMerge: true,
      ),
    );

    final passed =
        duplicateEmailError == 'IdentityCollisionException' &&
        duplicateIdentityError == 'IdentityCollisionException' &&
        unconfirmedError == 'IdentityMergeConfirmationException' &&
        overlappingError == 'IdentityCollisionException' &&
        duplicateEmail.accounts.length == 2 &&
        duplicateEmail.find('account-a')!.identities.length == 1 &&
        duplicateIdentity.accounts.length == 2 &&
        unconfirmedMerge.accounts.length == 2 &&
        overlappingMerge.accounts.length == 2;

    return Sprint117IdentityWorkflowObservation(
      checkId: 'collision',
      outcome: passed
          ? 'EVERY_COLLISION_REJECTED_WITHOUT_MUTATION'
          : 'COLLISION_NOT_REJECTED',
      facts: <String, Object?>{
        'duplicate_email_error': duplicateEmailError,
        'duplicate_identity_error': duplicateIdentityError,
        'unconfirmed_merge_error': unconfirmedError,
        'overlapping_merge_error': overlappingError,
        'accounts_unchanged_after_collisions': duplicateEmail.accounts.length,
        'identities_unchanged_after_collisions': duplicateEmail
            .find('account-a')!
            .identities
            .length,
        'mechanism': 'IdentityLinkingService.link + merge',
        'acceptance_mechanism_present': true,
      },
      passed: passed,
      acceptance: Sprint117IdentityWorkflowAcceptance.satisfied,
      unresolvable: const <String>[],
    );
  }

  /// `reauth` — a refused reauthentication must yield no secret, a granted one
  /// must yield the secret, and an expired connection must be able to move
  /// back to connecting instead of staying stuck.
  Future<Sprint117IdentityWorkflowObservation> _observeReauth() async {
    const accountId = 'drill_reauth';
    final store = MemoryCredentialStore();
    final audit = <String>[];
    var allowReauth = false;
    final vault = AccountSecureTokenVault(
      store: store,
      reauthenticate: () async => allowReauth,
      auditSink: (event) => audit.add(event.action),
    );
    await vault.save(
      accountId: accountId,
      secret: 'drill-refresh-token',
      kind: VaultSecretKind.oauthRefreshToken,
    );
    final vaultKey = vault.keyFor(accountId, VaultSecretKind.oauthRefreshToken);
    final denied = await vault.read(
      accountId: accountId,
      kind: VaultSecretKind.oauthRefreshToken,
    );
    allowReauth = true;
    final granted = await vault.read(
      accountId: accountId,
      kind: VaultSecretKind.oauthRefreshToken,
    );

    // The same gate in the connection state machine: connected -> expire ->
    // reauthenticate -> connected, and an expired connection must not offer a
    // retry that would skip the proof.
    final machine = _connectedMachine();
    final live = machine.transition(
      AccountConnectionTransition.connectSucceeded,
      at: fixedNow,
    );
    final expired = machine.transition(
      AccountConnectionTransition.expire,
      at: fixedNow,
    );
    final expiredTransitions = machine.availableTransitions
        .map((transition) => transition.wireName)
        .toList(growable: false);
    final retryWithoutReauth = _captureStateError(
      () => machine.transition(AccountConnectionTransition.retry, at: fixedNow),
    );
    final reauthenticating = machine.transition(
      AccountConnectionTransition.reauthenticate,
      at: fixedNow,
    );
    final restored = machine.transition(
      AccountConnectionTransition.connectSucceeded,
      at: fixedNow,
    );

    // Management surface: a reauthentication request must be produced from the
    // connection record and must carry the same scope set.
    final management = AccountConnectedAccountsManagement();
    management.add(
      AccountConnectedAccount(
        connectionId: 'fixture/account-1',
        providerId: 'fixture-identity',
        accountLabel: 'Drill Identity',
        scopes: const <String>{'account.read'},
        connectionState: AccountConnectionState.expired,
        healthState: AccountHealthState.unknown,
        lastCheckedAt: fixedNow,
        reauthRequired: true,
      ),
    );
    final request = management.reauthenticate('fixture/account-1');
    final markedRequired = management.connections.single.reauthRequired;

    final vaultHolds =
        denied == null &&
        granted == 'drill-refresh-token' &&
        vaultKey == 'account/drill_reauth/oauth_refresh_token' &&
        audit.where((action) => action == 'read').length == 1;
    final statesHold =
        live.connectionState == AccountConnectionState.connected &&
        expired.reauthRequired &&
        expired.connectionState == AccountConnectionState.expired &&
        expiredTransitions.contains('REAUTHENTICATE') &&
        !expiredTransitions.contains('RETRY') &&
        retryWithoutReauth == 'StateError' &&
        reauthenticating.connectionState == AccountConnectionState.connecting &&
        !reauthenticating.reauthRequired &&
        restored.connectionState == AccountConnectionState.connected;
    final managementHolds =
        request.connectionId == 'fixture/account-1' &&
        request.scopes.contains('account.read') &&
        markedRequired;

    return Sprint117IdentityWorkflowObservation(
      checkId: 'reauth',
      outcome: vaultHolds && statesHold && managementHolds
          ? 'REAUTH_GATE_DENIES_WITHOUT_PROOF_AND_RESTORES_WITH_IT'
          : 'REAUTH_GATE_NOT_ENFORCED',
      facts: <String, Object?>{
        'read_without_reauth': denied,
        'read_with_reauth': granted,
        'vault_key_scheme_resolved': vaultKey,
        'audit_actions': audit,
        'state_before_expiry': live.connectionState.wireName,
        'expired_state': expired.connectionState.wireName,
        'expired_notice': expired.userVisibleError,
        'expired_offers_reauth': expiredTransitions.contains('REAUTHENTICATE'),
        'expired_offers_retry': expiredTransitions.contains('RETRY'),
        'retry_without_reauth_error': retryWithoutReauth,
        'state_after_reauthenticate': reauthenticating.connectionState.wireName,
        'state_after_reauth_success': restored.connectionState.wireName,
        'reauth_required_cleared': !restored.reauthRequired,
        'management_request_scopes': request.scopes.toList(growable: false)
          ..sort(),
        'mechanism':
            'AccountSecureTokenVault.read + '
            'AccountConnectionHealthStateMachine',
        'acceptance_mechanism_present': true,
      },
      passed: vaultHolds && statesHold && managementHolds,
      acceptance: Sprint117IdentityWorkflowAcceptance.satisfied,
      unresolvable: const <String>[],
    );
  }

  /// `unlink` — the 115.11 rule says the local link is removed only after
  /// revocation succeeds. Every one of those three outcomes is measured.
  Future<Sprint117IdentityWorkflowObservation> _observeUnlink() async {
    // 1. Keeping the link must do nothing at all.
    final keeper = _DrillBroker();
    final keepFlow = _flow(broker: keeper);
    final keepResult = await _completeExchange(keepFlow);
    final kept = await keepFlow.unlink(
      grant: keepResult.tokenGrant,
      decision: OAuthUnlinkDecision.keepLinked,
    );
    final keptIdentities = keepFlow.linkedIdentities.length;
    final keptProviderRevocations = keeper.revokedGrants.length;

    // 2. A failing provider revocation must preserve the local link.
    final failing = _DrillBroker(failRevocation: true);
    final failFlow = _flow(broker: failing);
    final failResult = await _completeExchange(failFlow);
    final failError = await _captureOAuthAsync(
      () => failFlow.unlink(
        grant: failResult.tokenGrant,
        decision: OAuthUnlinkDecision.unlink,
      ),
    );
    final preservedAfterFailure = failFlow.linkedIdentities.length;

    // 3. A successful revocation removes the link, and a second attempt on the
    // same grant is refused because that generation is gone.
    final working = _DrillBroker();
    final okFlow = _flow(broker: working);
    final okResult = await _completeExchange(okFlow);
    final revoked = await okFlow.unlink(
      grant: okResult.tokenGrant,
      decision: OAuthUnlinkDecision.unlink,
    );
    final identitiesAfterRevoke = okFlow.linkedIdentities.length;
    final replayAfterUnlink = await _captureOAuthAsync(
      () => okFlow.unlink(
        grant: okResult.tokenGrant,
        decision: OAuthUnlinkDecision.unlink,
      ),
    );

    // 4. Management-level unlink still requires explicit confirmation.
    final management = AccountConnectedAccountsManagement();
    management.add(
      AccountConnectedAccount(
        connectionId: 'fixture/account-1',
        providerId: 'fixture-identity',
        accountLabel: 'Drill Identity',
        scopes: const <String>{'account.read'},
        connectionState: AccountConnectionState.connected,
        healthState: AccountHealthState.healthy,
        lastCheckedAt: fixedNow,
        reauthRequired: false,
      ),
    );
    final unconfirmed = await management.unlink(
      'fixture/account-1',
      confirmed: false,
    );
    final stillPresent = management.connections.length;
    final confirmed = await management.unlink(
      'fixture/account-1',
      confirmed: true,
    );
    final goneAfterConfirm = management.connections.length;

    final passed =
        !kept &&
        keptIdentities == 1 &&
        keptProviderRevocations == 0 &&
        failError == 'revocationFailed' &&
        preservedAfterFailure == 1 &&
        revoked &&
        identitiesAfterRevoke == 0 &&
        working.revokedGrants.length == 1 &&
        replayAfterUnlink == 'staleTokenGeneration' &&
        !unconfirmed.localRemoved &&
        !unconfirmed.providerRevokeAttempted &&
        stillPresent == 1 &&
        // This drill constructs the management seam without a revoker, so the
        // disconnect is local-only by declaration. The result says so
        // explicitly instead of returning an indistinguishable `true`.
        confirmed.localRemoved &&
        !confirmed.providerRevokeAttempted &&
        !confirmed.providerRevoked &&
        goneAfterConfirm == 0;

    return Sprint117IdentityWorkflowObservation(
      checkId: 'unlink',
      outcome: passed
          ? 'LINK_REMOVED_ONLY_AFTER_PROVIDER_REVOCATION'
          : 'UNLINK_RULE_NOT_ENFORCED',
      facts: <String, Object?>{
        'keep_linked_result': kept,
        'identities_after_keep': keptIdentities,
        'provider_revocations_after_keep': keptProviderRevocations,
        'failed_revocation_error': failError,
        'identities_after_failed_revocation': preservedAfterFailure,
        'successful_unlink_result': revoked,
        'identities_after_successful_unlink': identitiesAfterRevoke,
        'provider_revocations_recorded': working.revokedGrants.length,
        'second_unlink_error': replayAfterUnlink,
        // The fact keys stay boolean: `unlink` now returns an
        // `AccountDisconnectResult`, and recording the object itself made these
        // declared-boolean facts compare against an unrelated type. Each keeps
        // its original meaning — whether the call dropped the local row — while
        // the provider-call detail that motivated the richer return value is
        // reported beside it rather than dropped.
        'management_unlink_without_confirmation': unconfirmed.localRemoved,
        'connections_after_unconfirmed': stillPresent,
        'management_unlink_with_confirmation': confirmed.localRemoved,
        'management_unlink_provider_called': confirmed.providerRevokeAttempted,
        'management_unlink_provider_revoked': confirmed.providerRevoked,
        'connections_after_confirmed': goneAfterConfirm,
        'mechanism':
            'AccountOAuthFlow.unlink + AccountConnectedAccountsManagement',
        'acceptance_mechanism_present': true,
      },
      passed: passed,
      acceptance: Sprint117IdentityWorkflowAcceptance.satisfied,
      unresolvable: const <String>[],
    );
  }

  /// `last_method` — an account must not be able to remove its only way in.
  Sprint117IdentityWorkflowObservation _observeLastMethod() {
    const sole = IdentityCredential('google', 'google-subject-1');
    final locked = IdentityLinkingService(<IdentityAccount>[
      IdentityAccount(
        accountId: 'account-locked',
        email: 'writer@example.test',
        identities: <IdentityCredential>{sole},
        recoveryEmail: null,
      ),
    ]);
    final lockedError = _captureLinkingError(
      () => locked.unlink(accountId: 'account-locked', credential: sole),
    );
    final stillLinked = locked.find('account-locked')!.identities.length;

    // With a second identity, unlinking the first is allowed.
    final twoWays = IdentityLinkingService(<IdentityAccount>[
      IdentityAccount(
        accountId: 'account-open',
        email: 'writer2@example.test',
        identities: <IdentityCredential>{
          sole,
          const IdentityCredential('github', 'github-subject-7'),
        },
        recoveryEmail: null,
      ),
    ]);
    final withSpare = twoWays.unlink(
      accountId: 'account-open',
      credential: sole,
    );
    final remaining = twoWays.find('account-open')!.identities.length;

    // With a recovery email recorded, even the last identity may be removed.
    final recovered = IdentityLinkingService(<IdentityAccount>[
      IdentityAccount(
        accountId: 'account-recovered',
        email: 'writer3@example.test',
        identities: <IdentityCredential>{sole},
        recoveryEmail: null,
      ),
    ]);
    recovered.recover(
      accountId: 'account-recovered',
      recoveryEmail: 'recover@example.test',
    );
    final afterRecovery = recovered.unlink(
      accountId: 'account-recovered',
      credential: sole,
    );
    final remainingAfterRecovery = recovered
        .find('account-recovered')!
        .identities
        .length;

    final passed =
        lockedError == 'LastLoginMethodException' &&
        stillLinked == 1 &&
        withSpare &&
        remaining == 1 &&
        afterRecovery &&
        remainingAfterRecovery == 0;

    return Sprint117IdentityWorkflowObservation(
      checkId: 'last_method',
      outcome: passed
          ? 'LAST_IDENTITY_PROTECTED_UNTIL_RECOVERY_EXISTS'
          : 'LAST_METHOD_NOT_PROTECTED',
      facts: <String, Object?>{
        'sole_identity_unlink_error': lockedError,
        'identities_after_refusal': stillLinked,
        'unlink_with_spare_identity': withSpare,
        'identities_remaining': remaining,
        'unlink_after_recovery': afterRecovery,
        'identities_after_recovery_unlink': remainingAfterRecovery,
        'mechanism': 'IdentityLinkingService.unlink',
        'acceptance_mechanism_present': true,
      },
      passed: passed,
      acceptance: Sprint117IdentityWorkflowAcceptance.satisfied,
      unresolvable: const <String>[],
    );
  }

  /// `recovery` — a malformed recovery email is refused, a valid one is stored,
  /// and expiry or revocation must not cost the user local data.
  Sprint117IdentityWorkflowObservation _observeRecovery() {
    const googleSubject = IdentityCredential('google', 'google-subject-1');
    final service = IdentityLinkingService(<IdentityAccount>[
      IdentityAccount(
        accountId: 'account-a',
        email: 'writer@example.test',
        identities: <IdentityCredential>{googleSubject},
        recoveryEmail: null,
      ),
    ]);
    final malformed = _captureLinkingError(
      () => service.recover(
        accountId: 'account-a',
        recoveryEmail: 'not-an-email',
      ),
    );
    final storedAfterMalformed = service.find('account-a')!.recoveryEmail;
    final stored = service.recover(
      accountId: 'account-a',
      recoveryEmail: '  recover@example.test  ',
    );
    final unknownAccount = _captureLinkingError(
      () => service.recover(accountId: 'nope', recoveryEmail: 'x@example.test'),
    );

    // Local data survives expiry and revocation, per 115.43.
    final expired = AccountCenterTokenExpiryReauthenticationUx.expired(
      providerId: 'drill_identity',
      accountLabel: 'Drill Identity',
      affectedCapabilities: const <String>['account.read'],
      hasLocalData: true,
    );
    final revoked = expired.revoked();
    final retryWhileExpired = expired.retry('account.read');
    final retryAfterReauth = expired.reauthenticated().retry('account.read');
    final retryAfterRevoke = revoked.retry('account.read');

    final passed =
        malformed == 'ArgumentError' &&
        storedAfterMalformed == null &&
        stored.recoveryEmail == 'recover@example.test' &&
        unknownAccount == 'StateError' &&
        expired.requiresReauthentication &&
        !expired.canRetry &&
        expired.localDataPreserved &&
        !retryWhileExpired.accepted &&
        retryAfterReauth.accepted &&
        revoked.isRevoked &&
        !revoked.canRevoke &&
        revoked.localDataPreserved &&
        !retryAfterRevoke.accepted;

    return Sprint117IdentityWorkflowObservation(
      checkId: 'recovery',
      outcome: passed
          ? 'RECOVERY_EMAIL_VALIDATED_AND_LOCAL_DATA_PRESERVED'
          : 'RECOVERY_PATH_NOT_ENFORCED',
      facts: <String, Object?>{
        'malformed_email_error': malformed,
        'recovery_email_after_malformed': storedAfterMalformed,
        'recovery_email_stored': stored.recoveryEmail,
        'unknown_account_error': unknownAccount,
        'expired_requires_reauth': expired.requiresReauthentication,
        'expired_notice': expired.notice,
        'retry_while_expired_accepted': retryWhileExpired.accepted,
        'retry_while_expired_reason': retryWhileExpired.reason,
        'retry_after_reauth_accepted': retryAfterReauth.accepted,
        'revoked_preserves_local_data': revoked.localDataPreserved,
        'revoked_allows_no_retry': !retryAfterRevoke.accepted,
        'local_data_preserved': expired.localDataPreserved,
        'mechanism':
            'IdentityLinkingService.recover + '
            'AccountCenterTokenExpiryReauthenticationUx',
        'acceptance_mechanism_present': true,
      },
      passed: passed,
      acceptance: Sprint117IdentityWorkflowAcceptance.satisfied,
      unresolvable: const <String>[],
    );
  }

  /// `revoke` — the vault key disappears, the managed key goes inert, and a
  /// revoked connection has no way back without a new configuration.
  Future<Sprint117IdentityWorkflowObservation> _observeRevoke() async {
    const accountId = 'drill_revoke';
    final store = MemoryCredentialStore();
    final audit = <String>[];
    final vault = AccountSecureTokenVault(
      store: store,
      reauthenticate: () async => true,
      auditSink: (event) => audit.add(event.action),
    );
    final manager = AccountCenterApiKeysManager(
      accountId: accountId,
      vault: vault,
      validator: (request) async => true,
    );
    await manager.add(
      id: 'key-1',
      providerId: 'drill_provider',
      label: 'Drill key',
      secret: 'drill-api-secret-value',
      scopes: const <String>{'generate'},
    );
    final keyPath = vault.keyFor(
      accountId,
      VaultSecretKind.apiKey,
      secretId: 'key-1',
    );
    final before = await store.read(keyPath);
    await manager.revoke('key-1');
    final after = await store.read(keyPath);
    final statusAfter = manager.keys.single.status;
    // A revoked key must be inert: reading, replacing, and re-validating it
    // are all refused rather than silently returning a stale secret.
    final readAfter = await vault.read(
      accountId: accountId,
      kind: VaultSecretKind.apiKey,
      secretId: 'key-1',
    );
    final replaceError = await _captureApiKeyError(
      () => manager.replace(id: 'key-1', secret: 'drill-rotated-secret'),
    );
    final validateError = await _captureApiKeyError(
      () => manager.validate('key-1'),
    );

    final machine = _connectedMachine();
    machine.transition(
      AccountConnectionTransition.connectSucceeded,
      at: fixedNow,
    );
    final revokedSnapshot = machine.transition(
      AccountConnectionTransition.revoke,
      at: fixedNow,
    );
    final outgoing = machine.availableTransitions
        .map((transition) => transition.wireName)
        .toList(growable: false);
    final retryAfterRevoke = _captureStateError(
      () => machine.transition(AccountConnectionTransition.retry, at: fixedNow),
    );

    // And the provider side: the grant revocation unlink depends on.
    final broker = _DrillBroker();
    final flow = _flow(broker: broker);
    final linked = await _completeExchange(flow);
    final unlinked = await flow.unlink(
      grant: linked.tokenGrant,
      decision: OAuthUnlinkDecision.unlink,
    );

    final passed =
        before == 'drill-api-secret-value' &&
        after == null &&
        readAfter == null &&
        statusAfter == ApiKeyStatus.revoked &&
        replaceError == 'StateError' &&
        validateError == 'StateError' &&
        revokedSnapshot.connectionState == AccountConnectionState.revoked &&
        revokedSnapshot.userVisibleError != null &&
        outgoing.isEmpty &&
        retryAfterRevoke == 'StateError' &&
        audit.contains('revoke') &&
        unlinked &&
        broker.revokedGrants.length == 1;

    return Sprint117IdentityWorkflowObservation(
      checkId: 'revoke',
      outcome: passed
          ? 'REVOKE_REMOVES_SECRET_AND_CLOSES_THE_CONNECTION'
          : 'REVOKE_LEAVES_STATE_USABLE',
      facts: <String, Object?>{
        'vault_key': keyPath,
        'secret_present_before': before != null,
        'secret_present_after': after != null,
        'read_after_revoke': readAfter,
        'managed_key_status': statusAfter.name,
        'replace_after_revoke_error': replaceError,
        'validate_after_revoke_error': validateError,
        'connection_state_after_revoke':
            revokedSnapshot.connectionState.wireName,
        'revoke_notice': revokedSnapshot.userVisibleError,
        'outgoing_transitions_after_revoke': outgoing,
        'retry_after_revoke_error': retryAfterRevoke,
        'provider_revocations': broker.revokedGrants.length,
        'audit_actions': audit,
        'mechanism':
            'AccountCenterApiKeysManager.revoke + '
            'AccountConnectionHealthStateMachine',
        'acceptance_mechanism_present': true,
      },
      passed: passed,
      acceptance: Sprint117IdentityWorkflowAcceptance.satisfied,
      unresolvable: const <String>[],
    );
  }
}

/// The instant this drill measures against, at file scope so the helper
/// factories below can reach it.
final DateTime fixedNow = Sprint117IdentityWorkflowDrill.fixedNow;

/// A state machine that has already begun connecting, so the drill measures
/// the transitions that follow `CONNECTING` instead of rebuilding the same
/// prefix in every check.
AccountConnectionHealthStateMachine _connectedMachine() {
  final machine = AccountConnectionHealthStateMachine.notConfigured(
    providerId: 'drill_identity',
    accountLabel: 'Drill Identity',
  );
  machine.transition(AccountConnectionTransition.beginConnecting, at: fixedNow);
  return machine;
}

/// Builds the flow the drill exercises, with a fixed clock so the token
/// expiry check is decided by the shipped validator and not by the run date.
AccountOAuthFlow _flow({required OAuthTokenBroker broker}) =>
    AccountOAuthFlow(broker: broker, clock: () => fixedNow);

/// The scopes the drill's fixture identity connector asks for.
const List<String> _drillScopes = <String>['account.read'];

/// A fixture identity connector that satisfies the shipped connect gate
/// exactly as a certified entry would: available, OAuth2-PKCE, identity
/// capability. It is a drill fixture, never a claim about a real provider.
OAuthProviderConfiguration _fixtureConfiguration() =>
    OAuthProviderConfiguration(
      connector: ProviderConnectorEntry(
        providerId: 'drill_identity',
        displayName: 'Drill Identity',
        category: ProviderConnectorCategory.identity,
        capabilities: const <ProviderConnectorCapability>{
          ProviderConnectorCapability.identity,
          ProviderConnectorCapability.health,
        },
        availability: ProviderConnectorAvailability.available,
        regions: const <ProviderRegion>{ProviderRegion.global},
        connectorVersion: 'drill-v1',
        authType: ProviderAuthType.oauth2Pkce,
        permissions: const <ProviderPermission>{
          ProviderPermission.accountMetadata,
          ProviderPermission.providerConnection,
        },
      ),
      authorizationEndpoint: Uri.parse(
        'https://identity.example.test/oauth/authorize',
      ),
      redirectUri: Uri.parse('https://app.example.test/oauth/callback'),
      scopes: _drillScopes,
    );

/// The provider configuration for an entry that already ships in the manifest,
/// with the drill's endpoints and scopes, used to measure the gate's refusal.
OAuthProviderConfiguration _configurationFor(ProviderConnectorEntry entry) =>
    OAuthProviderConfiguration(
      connector: entry,
      authorizationEndpoint: Uri.parse(
        'https://identity.example.test/oauth/authorize',
      ),
      redirectUri: Uri.parse('https://app.example.test/oauth/callback'),
      scopes: _drillScopes,
    );

/// The explicit consent the shipped validator requires: requested and granted
/// scopes must match the configuration exactly.
OAuthScopeConsent _consent() => OAuthScopeConsent(
  requestedScopes: _drillScopes,
  grantedScopes: _drillScopes,
  explicitlyApproved: true,
);

/// Runs a full authorization-code exchange against a fresh flow.
Future<LinkedIdentityResult> _completeExchange(AccountOAuthFlow flow) async {
  final configuration = _fixtureConfiguration();
  final request = flow.beginAuthorization(
    configuration: configuration,
    consent: _consent(),
  );
  return flow.completeAuthorization(callback: _callbackFor(request));
}

/// Builds the callback the flow requires: absolute, exact state, and the
/// nonce the request actually issued.
Uri _callbackFor(OAuthAuthorizationRequest request) =>
    request.redirectUri.replace(
      queryParameters: <String, String>{
        'code': 'drill-authorization-code',
        'state': request.state,
        if (request.nonce != null) 'nonce': request.nonce!,
      },
    );

/// The error code a synchronous OAuth call raised, or null when it raised
/// nothing this drill records.
String? _captureOAuthError(Object? Function() action) {
  try {
    action();
  } on OAuthFlowException catch (error) {
    return error.code.name;
  } on ArgumentError {
    return 'ArgumentError';
  } on StateError {
    return 'StateError';
  }
  return null;
}

/// The error code an asynchronous OAuth call raised, or null.
Future<String?> _captureOAuthAsync(Future<Object?> Function() action) async {
  try {
    await action();
  } on OAuthFlowException catch (error) {
    return error.code.name;
  } on StateError {
    return 'StateError';
  }
  return null;
}

/// The linked identity a full exchange produced, or null when it raised.
Future<LinkedIdentityResult?> _captureOAuth(
  Future<LinkedIdentityResult> Function() action,
) async {
  try {
    return await action();
  } on OAuthFlowException {
    return null;
  }
}

/// The exception name a linking call raised, or null.
String? _captureLinkingError(Object? Function() action) {
  try {
    action();
  } on IdentityCollisionException {
    return 'IdentityCollisionException';
  } on IdentityMergeConfirmationException {
    return 'IdentityMergeConfirmationException';
  } on IdentityTakeoverException {
    return 'IdentityTakeoverException';
  } on LastLoginMethodException {
    return 'LastLoginMethodException';
  } on ArgumentError {
    return 'ArgumentError';
  } on StateError {
    return 'StateError';
  }
  return null;
}

/// The exception name a state-machine transition raised, or null.
String? _captureStateError(Object? Function() action) {
  try {
    action();
  } on StateError {
    return 'StateError';
  } on ArgumentError {
    return 'ArgumentError';
  }
  return null;
}

/// The exception name an API-key manager call raised, or null.
Future<String?> _captureApiKeyError(Future<Object?> Function() action) async {
  try {
    await action();
  } on StateError {
    return 'StateError';
  } on ArgumentError {
    return 'ArgumentError';
  }
  return null;
}

/// The drill's token broker: a fixture provider that answers exchanges and
/// refreshes deterministically, and can be told to fail a revocation.
class _DrillBroker implements OAuthTokenBroker {
  _DrillBroker({this.failRevocation = false});

  final bool failRevocation;
  final List<OAuthTokenGrant> revokedGrants = <OAuthTokenGrant>[];
  int _refreshGeneration = 1;

  @override
  Future<OAuthTokenResponse> exchange(
    OAuthTokenExchangeRequest request,
  ) async => _response(
    providerId: request.configuration.connector.providerId,
    scopes: request.scopes,
    supportsRefresh: request.configuration.supportsRefresh,
    generation: 1,
  );

  @override
  Future<OAuthTokenResponse> refresh(OAuthTokenRefreshRequest request) async {
    _refreshGeneration += 1;
    return _response(
      providerId: request.grant.providerId,
      scopes: request.grant.scopes,
      supportsRefresh: request.grant.supportsRefresh,
      generation: _refreshGeneration,
    );
  }

  @override
  Future<void> revoke(OAuthTokenGrant grant) async {
    if (failRevocation) {
      throw StateError('Fixture revocation refused.');
    }
    revokedGrants.add(grant);
  }

  static OAuthTokenResponse _response({
    required String providerId,
    required Set<String> scopes,
    required bool supportsRefresh,
    required int generation,
  }) => OAuthTokenResponse(
    providerId: providerId,
    providerAccountId: 'drill-account-1',
    displayName: 'Drill Identity',
    accessToken: 'drill-access-token-$generation',
    refreshToken: 'drill-refresh-token-$generation',
    accessTokenExpiresAt: fixedNow.add(const Duration(hours: 1)),
    supportsRefresh: supportsRefresh,
    scopes: scopes,
  );
}
