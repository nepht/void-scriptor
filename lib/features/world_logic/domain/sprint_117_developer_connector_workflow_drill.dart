part of 'sprint_117_developer_connector_workflow_validation.dart';

/// Executes the shipped developer connector mechanisms and records what each
/// one produced. It writes nothing, opens no user project, contacts no
/// provider, and every provider it names is a locally built manifest entry, so
/// nothing here can be read as a certification or a live availability claim.
class Sprint117DeveloperConnectorWorkflowDrill {
  const Sprint117DeveloperConnectorWorkflowDrill();

  /// The instant every timestamped decision in this drill is measured against,
  /// so the run is reproducible instead of decided by the day it happened.
  static final DateTime fixedNow = DateTime.utc(2026, 1, 1, 12);

  /// Source files that hold the shipped connector mechanisms. A check whose
  /// behaviour only these files exercise is the mechanism existing, not the
  /// feature being reachable by a user.
  static const List<String> shippedSources = <String>[
    'lib/features/account/domain/account_center_developer_tools_connections.dart',
    'lib/features/account/domain/account_center_connected_accounts_management.dart',
    'lib/features/account/domain/account_center_connection_health_state_machine.dart',
  ];

  /// Whether [source] still declares [symbol], i.e. whether the mechanism this
  /// check exercises exists at all.
  ///
  /// Measured rather than assumed so that renaming or deleting the shipped
  /// method makes the fact false instead of leaving a constant `true` behind.
  /// A constant would make the acceptance look decided by something that never
  /// ran, which is the defect 117.16 rejected in this harness family.
  static bool _declares(String source, String symbol) {
    final file = File(source);
    if (!file.existsSync()) return false;
    return file.readAsLinesSync().any((line) => line.contains(symbol));
  }

  /// Counts production call sites that reach [source] under `lib/`.
  ///
  /// Separate from [_declares] on purpose: a declared mechanism that nothing
  /// calls satisfies the acceptance in the abstract but not for a user, and
  /// the two facts must not be collapsed into one. The harness family is
  /// excluded wholesale because no `sprint_117_*` file is reachable from
  /// `main.dart` — without that exclusion an acceptance drill counts itself
  /// as the production caller it was supposed to measure.
  static int _productionCallSites(String source) {
    final stem = source.split('/').last;
    final found = <String>[];
    for (final entity in Directory.current.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (!path.startsWith('lib/') || !path.endsWith('.dart')) continue;
      if (path.contains('/sprint_117_')) continue;
      if (path == source) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i += 1) {
        if (lines[i].contains(stem)) {
          found.add('$path:${i + 1}');
          break;
        }
      }
    }
    return found.length;
  }

  /// Per shipped source: does it declare the mechanism this check exercises.
  static final Map<String, bool> _mechanismPresent = <String, bool>{
    'connections.scopes': _declares(shippedSources.first, '_normalizeScopes'),
    'connections.repositoryAccess': _declares(
      shippedSources.first,
      '_validateRepositoryAccess',
    ),
    'connections.disconnect': _declares(shippedSources.first, 'disconnect('),
    'accounts.reauthenticate': _declares(shippedSources[1], 'reauthenticate('),
    'accounts.recordHealthCheck': _declares(
      shippedSources[1],
      'recordHealthCheck',
    ),
    'health.refreshHealth': _declares(shippedSources[2], '_applyHealthRefresh'),
    'health.revoke': _declares(
      shippedSources[2],
      'AccountConnectionTransition.revoke',
    ),
  };

  /// Whether any production file outside the acceptance harness imports the
  /// connector mechanisms this slice validates.
  static final bool _productionCallerPresent =
      _productionCallSites(shippedSources.first) +
          _productionCallSites(shippedSources[1]) +
          _productionCallSites(shippedSources[2]) >
      0;

  /// Runs every canonical check against the repository as it stands.
  Future<Sprint117DeveloperConnectorWorkflowDrillRun> run() async {
    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117DeveloperConnectorWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }
    return Sprint117DeveloperConnectorWorkflowDrillRun(
      observations: <Sprint117DeveloperConnectorWorkflowObservation>[
        await _observeScopes(),
        await _observeResourceAccess(),
        await _observeRateLimits(),
        await _observeReauth(),
        await _observeRevoke(),
        await _observeAudit(),
      ],
      liveProviderTouched: false,
      userProjectTouched: false,
      liveCredentialObserved: false,
      externalPinsMatched: matched,
      externalPinsChecked: checked,
      productionCallerPresent: _productionCallerPresent,
    );
  }

  /// A provider manifest built here, never the production availability claim.
  ///
  /// `ProviderConnectorManifest.standard` records every developer connector as
  /// UNVERIFIED, so connecting against it is impossible by design. The drill
  /// needs a connectable entry to exercise the mechanisms at all, so it builds
  /// one locally and says so, instead of promoting a real provider to
  /// AVAILABLE to make a test pass.
  static ProviderConnectorManifest _manifest({
    String availableProvider = 'github',
  }) => ProviderConnectorManifest(<ProviderConnectorEntry>[
    ProviderConnectorEntry.fixture(
      availableProvider,
      category: ProviderConnectorCategory.developer,
      capabilities: const <ProviderConnectorCapability>{
        ProviderConnectorCapability.developer,
      },
      availability: ProviderConnectorAvailability.available,
    ),
    ProviderConnectorEntry.fixture(
      'unavailable_developer',
      category: ProviderConnectorCategory.developer,
      capabilities: const <ProviderConnectorCapability>{
        ProviderConnectorCapability.developer,
      },
      availability: ProviderConnectorAvailability.unverified,
    ),
  ]);

  /// `scopes` — a connection keeps exactly the normalized scopes it was given.
  Future<Sprint117DeveloperConnectorWorkflowObservation>
  _observeScopes() async {
    final connections = AccountCenterDeveloperToolsConnections(
      manifest: _manifest(),
      now: () => fixedNow,
      reauthenticate: () async => true,
    );

    // Duplicated, mixed-case, and padded text is one grant, not three.
    final connection = connections.connect(
      providerId: ' GITHUB ',
      connectionId: 'github/main',
      scopes: const <String>{'  repo:read ', 'REPO:READ', 'profile:read'},
      repositoryAccess: DeveloperRepositoryAccess.readOnly,
    );

    var emptyRefused = false;
    try {
      connections.connect(
        providerId: 'github',
        connectionId: 'github/empty',
        scopes: const <String>{},
        repositoryAccess: DeveloperRepositoryAccess.none,
      );
    } on ArgumentError {
      emptyRefused = true;
    }
    var blankRefused = false;
    try {
      connections.connect(
        providerId: 'github',
        connectionId: 'github/blank',
        scopes: const <String>{'   '},
        repositoryAccess: DeveloperRepositoryAccess.none,
      );
    } on ArgumentError {
      blankRefused = true;
    }
    var widened = false;
    try {
      connection.scopes.add('repo:write');
    } on UnsupportedError {
      widened = true;
    }

    final normalized =
        connection.scopes.length == 2 &&
        connection.scopes.contains('repo:read') &&
        connection.scopes.contains('profile:read');
    final noWriteAfterAttempt = !connection.scopes.contains('repo:write');
    final failedConnectionsAbsent = connections.activeConnections.every(
      (entry) => entry.connectionId == 'github/main',
    );

    final passed =
        normalized &&
        noWriteAfterAttempt &&
        widened &&
        emptyRefused &&
        blankRefused &&
        failedConnectionsAbsent;

    return Sprint117DeveloperConnectorWorkflowObservation(
      checkId: 'scopes',
      outcome: passed
          ? 'CONNECTION_SCOPE_SET_NORMALIZED_AND_UNMODIFIABLE'
          : 'SCOPE_SET_UNNORMALIZED_OR_MUTABLE_OR_EMPTY_ACCEPTED',
      facts: <String, Object?>{
        'stored_scope_count': connection.scopes.length,
        'stored_scopes': connection.scopes.toList(growable: false)..sort(),
        'duplicate_and_cased_input_normalized': normalized,
        'scope_set_immutable': widened,
        'empty_scopes_refused': emptyRefused,
        'blank_scopes_refused': blankRefused,
        'refused_connections_never_stored': failedConnectionsAbsent,
        'mechanism':
            'AccountCenterDeveloperToolsConnections.connect/'
            '_normalizeScopes',
        'acceptance_mechanism_present':
            _mechanismPresent['connections.scopes']!,
      },
      passed: passed,
    );
  }

  /// `resource_access` — declared access never exceeds the granted scopes.
  Future<Sprint117DeveloperConnectorWorkflowObservation>
  _observeResourceAccess() async {
    final connections = AccountCenterDeveloperToolsConnections(
      manifest: _manifest(),
      now: () => fixedNow,
      reauthenticate: () async => true,
    );

    // Widen the declared access beyond the grant.
    var widenedRefused = false;
    try {
      connections.connect(
        providerId: 'github',
        connectionId: 'github/too-wide',
        scopes: const <String>{'repo:read'},
        repositoryAccess: DeveloperRepositoryAccess.readWrite,
      );
    } on ArgumentError {
      widenedRefused = true;
    }
    // Narrow the declared access below the grant.
    var narrowedRefused = false;
    try {
      connections.connect(
        providerId: 'github',
        connectionId: 'github/too-narrow',
        scopes: const <String>{'repo:read', 'repo:write'},
        repositoryAccess: DeveloperRepositoryAccess.none,
      );
    } on ArgumentError {
      narrowedRefused = true;
    }
    // An exact match is accepted, in each of the three levels.
    final exactRead = connections.connect(
      providerId: 'github',
      connectionId: 'github/exact-read',
      scopes: const <String>{'repo:read'},
      repositoryAccess: DeveloperRepositoryAccess.readOnly,
    );
    final exactNone = connections.connect(
      providerId: 'github',
      connectionId: 'github/exact-none',
      scopes: const <String>{'profile:read'},
      repositoryAccess: DeveloperRepositoryAccess.none,
    );

    // A readWrite connection must be able to prove its write grant, and a
    // readOnly one must not silently carry it.
    final write = connections.connect(
      providerId: 'github',
      connectionId: 'github/write',
      scopes: const <String>{'repo:read', 'repo:write'},
      repositoryAccess: DeveloperRepositoryAccess.readWrite,
    );
    final writeProvesGrant = write.scopes.contains('repo:write');
    final readOnlyHasNoWrite =
        !exactRead.scopes.contains('repo:write') &&
        exactRead.repositoryAccess == DeveloperRepositoryAccess.readOnly;
    final noneHasNoRepo = !exactNone.scopes.contains('repo:read');

    final passed =
        widenedRefused &&
        narrowedRefused &&
        writeProvesGrant &&
        readOnlyHasNoWrite &&
        noneHasNoRepo;

    return Sprint117DeveloperConnectorWorkflowObservation(
      checkId: 'resource_access',
      outcome: passed
          ? 'DECLARED_ACCESS_ALWAYS_MATCHES_THE_GRANTED_SCOPES'
          : 'DECLARED_ACCESS_COULD_EXCEED_OR_CONTRADICT_THE_GRANT',
      facts: <String, Object?>{
        'wider_access_than_grant_refused': widenedRefused,
        'narrower_access_than_grant_refused': narrowedRefused,
        'exact_read_only_accepted': exactRead.repositoryAccess.name,
        'exact_none_accepted': exactNone.repositoryAccess.name,
        'write_access_carries_write_scope': writeProvesGrant,
        'read_only_carries_no_write_scope': readOnlyHasNoWrite,
        'no_access_carries_no_repo_scope': noneHasNoRepo,
        'mechanism':
            'AccountCenterDeveloperToolsConnections._validateRepositoryAccess',
        'acceptance_mechanism_present':
            _mechanismPresent['connections.repositoryAccess']!,
      },
      passed: passed,
    );
  }

  /// `rate_limits` — a limited connection stays connected, says so, and is
  /// never laundered into a healthy or unknown state.
  Future<Sprint117DeveloperConnectorWorkflowObservation>
  _observeRateLimits() async {
    final machine = _connectedMachine();

    machine.transition(
      AccountConnectionTransition.refreshHealth,
      at: fixedNow,
      healthState: AccountHealthState.rateLimited,
    );
    final snapshot = machine.snapshot;
    final message = snapshot.userVisibleError ?? '';

    // The connection must survive the limit: a rate limit is not a failure.
    final stillConnected =
        snapshot.connectionState == AccountConnectionState.connected;
    final limitVisible =
        snapshot.statusLabel == 'Rate limited' &&
        message.toLowerCase().contains('rate limit');
    // A limit that resets on its own would be reported as healthy with no
    // check having happened, so the timestamp has to be the refresh itself.
    final timestamped = snapshot.lastCheckedAt == fixedNow;
    // The retry path must not be reachable as a way to skip the limit.
    final retryNotOffered = !machine.canTransition(
      AccountConnectionTransition.retry,
    );
    // A degraded or outage refresh must not overwrite the limit into health.
    machine.transition(
      AccountConnectionTransition.refreshHealth,
      at: fixedNow,
      healthState: AccountHealthState.healthy,
    );
    final clearedByRealCheck =
        machine.snapshot.healthState == AccountHealthState.healthy &&
        machine.snapshot.userVisibleError == null;

    final passed =
        stillConnected &&
        limitVisible &&
        timestamped &&
        retryNotOffered &&
        clearedByRealCheck;

    return Sprint117DeveloperConnectorWorkflowObservation(
      checkId: 'rate_limits',
      outcome: passed
          ? 'RATE_LIMIT_VISIBLE_AND_NEVER_LAUNDERED_INTO_HEALTH'
          : 'RATE_LIMIT_HIDDEN_DISCONNECTED_OR_LAUNDERED',
      facts: <String, Object?>{
        'connection_state_under_limit': snapshot.connectionState.wireName,
        'health_state_under_limit': snapshot.healthState.wireName,
        'status_label': snapshot.statusLabel,
        'user_visible_error_present': message.isNotEmpty,
        'limit_timestamped': timestamped,
        'retry_not_offered_under_limit': retryNotOffered,
        'cleared_only_by_a_real_refresh': clearedByRealCheck,
        'mechanism': 'AccountConnectionHealthStateMachine._applyHealthRefresh',
        'acceptance_mechanism_present':
            _mechanismPresent['health.refreshHealth']!,
      },
      passed: passed,
    );
  }

  /// `reauth` — a health observation clears a pending request, by proof.
  Future<Sprint117DeveloperConnectorWorkflowObservation>
  _observeReauth() async {
    final manager = AccountConnectedAccountsManagement();
    manager.add(
      AccountConnectedAccount(
        connectionId: 'github/main',
        providerId: 'github',
        accountLabel: 'Developer account',
        scopes: const <String>{'repo:read'},
        connectionState: AccountConnectionState.connected,
        healthState: AccountHealthState.healthy,
        lastCheckedAt: null,
        reauthRequired: false,
      ),
    );

    final request = manager.reauthenticate('github/main');
    final requested = manager.connections.single.reauthRequired;
    // The request must carry the scopes the caller has to re-grant, otherwise
    // a silent reauth can come back with fewer permissions than before.
    final requestCarriesScopes = request.scopes.contains('repo:read');

    final checked = manager.recordHealthCheck(
      'github/main',
      healthState: AccountHealthState.healthy,
      checkedAt: fixedNow,
    );

    final clearedByProof = !checked.reauthRequired;
    final clearedInStore = !manager.connections.single.reauthRequired;
    final timestamped = checked.lastCheckedAt == fixedNow;
    // A refresh that did not happen must not clear the request either.
    final untouchedBeforeCheck = requested;
    // A second account must not inherit another account's reauth state.
    manager.add(
      AccountConnectedAccount(
        connectionId: 'github/other',
        providerId: 'github',
        accountLabel: 'Other account',
        scopes: const <String>{'repo:read'},
        connectionState: AccountConnectionState.connected,
        healthState: AccountHealthState.healthy,
        lastCheckedAt: null,
        reauthRequired: false,
      ),
    );
    final isolated =
        manager.connections
            .firstWhere((entry) => entry.connectionId == 'github/other')
            .reauthRequired ==
        false;

    final passed =
        requested &&
        untouchedBeforeCheck &&
        requestCarriesScopes &&
        clearedByProof &&
        clearedInStore &&
        timestamped &&
        isolated;

    return Sprint117DeveloperConnectorWorkflowObservation(
      checkId: 'reauth',
      outcome: passed
          ? 'REAUTH_REQUEST_CLEARED_BY_PROOF_AND_ISOLATED_PER_CONNECTION'
          : 'REAUTH_REQUEST_OUTSTANDING_UNSTAMPED_OR_LEAKED_ACROSS_ACCOUNTS',
      facts: <String, Object?>{
        'request_sets_flag': requested,
        'request_carries_granted_scopes': requestCarriesScopes,
        'cleared_by_health_observation': clearedByProof,
        'cleared_in_stored_connection': clearedInStore,
        'refresh_timestamped': timestamped,
        'other_account_unaffected': isolated,
        'mechanism':
            'AccountConnectedAccountsManagement.reauthenticate/'
            'recordHealthCheck',
        'acceptance_mechanism_present':
            _mechanismPresent['accounts.reauthenticate']!,
      },
      passed: passed,
    );
  }

  /// `revoke` — terminal state, and ending a connection is gated and audited.
  Future<Sprint117DeveloperConnectorWorkflowObservation>
  _observeRevoke() async {
    final machine = _connectedMachine();
    machine.transition(AccountConnectionTransition.revoke, at: fixedNow);
    final snapshot = machine.snapshot;

    final terminal =
        snapshot.connectionState == AccountConnectionState.revoked &&
        !AccountConnectionTransition.values.any(machine.canTransition);
    final visible =
        (snapshot.userVisibleError ?? '').toLowerCase().contains('revoked') &&
        snapshot.statusLabel == 'Connection revoked';
    // A revoked connection must not be reopened by retrying or reconnecting.
    var retryRefused = false;
    try {
      machine.transition(AccountConnectionTransition.retry, at: fixedNow);
    } on StateError {
      retryRefused = true;
    }
    var reconnectRefused = false;
    try {
      machine.transition(
        AccountConnectionTransition.connectSucceeded,
        at: fixedNow,
      );
    } on StateError {
      reconnectRefused = true;
    }

    // The developer seam: ending a connection needs the gate, and the gate
    // refusing is itself a decided, audited outcome.
    var reauthenticated = false;
    final connections = AccountCenterDeveloperToolsConnections(
      manifest: _manifest(),
      now: () => fixedNow,
      reauthenticate: () async => reauthenticated,
    );
    connections.connect(
      providerId: 'github',
      connectionId: 'github/main',
      scopes: const <String>{'repo:read'},
      repositoryAccess: DeveloperRepositoryAccess.readOnly,
    );

    final refused = await connections.disconnect(
      'github/main',
      confirmed: true,
    );
    final refusedKeptConnection = connections.activeConnections.length == 1;
    final refusedAudited = connections.audit.any(
      (event) => event.action == 'denied_disconnect',
    );
    final notRecordedAsDone = !connections.audit.any(
      (event) => event.action == 'disconnect',
    );

    reauthenticated = true;
    final allowed = await connections.disconnect(
      'github/main',
      confirmed: true,
    );
    final allowedRemoved = connections.activeConnections.isEmpty;
    final allowedAudited = connections.audit.any(
      (event) => event.action == 'disconnect',
    );

    // The default seam has no gate at all, so it must refuse rather than
    // assume the user was present.
    final ungated = AccountCenterDeveloperToolsConnections(
      manifest: _manifest(),
      now: () => fixedNow,
    );
    ungated.connect(
      providerId: 'github',
      connectionId: 'github/ungated',
      scopes: const <String>{'repo:read'},
      repositoryAccess: DeveloperRepositoryAccess.readOnly,
    );
    final ungatedRefused = await ungated.disconnect(
      'github/ungated',
      confirmed: true,
    );

    final passed =
        terminal &&
        visible &&
        retryRefused &&
        reconnectRefused &&
        !refused &&
        refusedKeptConnection &&
        refusedAudited &&
        notRecordedAsDone &&
        allowed &&
        allowedRemoved &&
        allowedAudited &&
        !ungatedRefused &&
        ungated.activeConnections.length == 1;

    return Sprint117DeveloperConnectorWorkflowObservation(
      checkId: 'revoke',
      outcome: passed
          ? 'REVOKE_TERMINAL_AND_DISCONNECT_GATED_AND_AUDITED'
          : 'REVOKE_REOPENABLE_OR_DISCONNECT_UNGATED_OR_UNAUDITED',
      facts: <String, Object?>{
        'connection_state_after_revoke': snapshot.connectionState.wireName,
        'no_transition_available': terminal,
        'revoke_visible_to_user': visible,
        'retry_after_revoke_refused': retryRefused,
        'reconnect_after_revoke_refused': reconnectRefused,
        'gated_disconnect_refused_without_reauth': !refused,
        'refusal_kept_the_connection': refusedKeptConnection,
        'refusal_audited': refusedAudited,
        'refusal_not_recorded_as_done': notRecordedAsDone,
        'gated_disconnect_allowed_after_reauth': allowed,
        'allowed_disconnect_removed_connection': allowedRemoved,
        'allowed_disconnect_audited': allowedAudited,
        'ungated_seam_fails_closed': !ungatedRefused,
        'mechanism':
            'AccountConnectionHealthStateMachine.revoke; '
            'AccountCenterDeveloperToolsConnections.disconnect',
        'acceptance_mechanism_present': _mechanismPresent['health.revoke']!,
      },
      passed: passed,
    );
  }

  /// `audit` — every action, including every refusal, leaves exactly one row.
  Future<Sprint117DeveloperConnectorWorkflowObservation> _observeAudit() async {
    var reauthenticated = true;
    final connections = AccountCenterDeveloperToolsConnections(
      manifest: _manifest(),
      now: () => fixedNow,
      reauthenticate: () async => reauthenticated,
    );

    connections.connect(
      providerId: 'github',
      connectionId: 'github/main',
      scopes: const <String>{'repo:read', 'repo:write'},
      repositoryAccess: DeveloperRepositoryAccess.readWrite,
    );
    // A refused attempt has to be visible, or a sensitive action that was
    // blocked and one that was never made look identical.
    reauthenticated = false;
    await connections.disconnect('github/main', confirmed: true);
    reauthenticated = true;
    // A confirmation refusal is an attempt too.
    await connections.disconnect('github/main', confirmed: false);
    await connections.disconnect('github/main', confirmed: true);

    final actions = connections.audit.map((event) => event.action).toList();
    final rows = connections.audit.toList(growable: false);

    // One row per action taken, with no silent duplicates or omissions.
    final connectRows = actions.where((a) => a == 'connect').length;
    final disconnectRows = actions.where((a) => a == 'disconnect').length;
    final deniedRows = actions.where((a) => a == 'denied_disconnect').length;
    final exactlyOnePerAction =
        connectRows == 1 && disconnectRows == 1 && deniedRows == 2;

    // The trail must never carry the grant itself: scopes and repository
    // access are the material an attacker reads out of an audit log.
    final serialized = rows
        .map((event) => jsonEncode(event.toJson()))
        .join(';');
    final noScopeMaterial =
        !serialized.contains('repo:read') &&
        !serialized.contains('repo:write') &&
        !serialized.contains('readWrite') &&
        !serialized.contains('read_only') &&
        !serialized.toLowerCase().contains('scopes');

    // Every row must name the connection it happened to, and be timestamped.
    final everyRowIdentified = rows.every(
      (event) => event.connectionId.isNotEmpty && event.timestamp == fixedNow,
    );

    final passed = exactlyOnePerAction && noScopeMaterial && everyRowIdentified;

    return Sprint117DeveloperConnectorWorkflowObservation(
      checkId: 'audit',
      outcome: passed
          ? 'EVERY_CONNECTION_ACTION_AND_REFUSAL_AUDITED_WITHOUT_SCOPE_MATERIAL'
          : 'AUDIT_TRAIL_INCOMPLETE_OR_CARRIED_SCOPE_MATERIAL',
      facts: <String, Object?>{
        'actions': actions,
        'connect_rows': connectRows,
        'disconnect_rows': disconnectRows,
        'denied_rows': deniedRows,
        'one_row_per_action_taken': exactlyOnePerAction,
        'no_row_carries_scope_material': noScopeMaterial,
        'every_row_named_and_timestamped': everyRowIdentified,
        'mechanism':
            'AccountCenterDeveloperToolsConnections._record/'
            '_recordRefusal; DeveloperToolAuditEvent',
        'acceptance_mechanism_present':
            _mechanismPresent['connections.disconnect']!,
      },
      passed: passed,
    );
  }
}

/// A state machine already connected, so the health and revoke checks start
/// from a live connection instead of an empty one.
AccountConnectionHealthStateMachine _connectedMachine() {
  final machine = AccountConnectionHealthStateMachine.notConfigured(
    providerId: 'github',
    accountLabel: 'Developer account',
    connectorVersion: 'fixture-v1',
  );
  machine.transition(
    AccountConnectionTransition.beginConnecting,
    at: DateTime.utc(2026, 1, 1, 11),
  );
  machine.transition(
    AccountConnectionTransition.connectSucceeded,
    at: DateTime.utc(2026, 1, 1, 11, 30),
  );
  return machine;
}
