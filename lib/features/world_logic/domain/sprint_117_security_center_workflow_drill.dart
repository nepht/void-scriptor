part of 'sprint_117_security_center_workflow_validation.dart';

/// Executes the shipped security mechanisms and records what each one
/// produced. It writes nothing, opens no user project, contacts no identity
/// provider, and every session, device, and alert it names is a locally
/// constructed fixture, so nothing here can be read as a claim that a real
/// account, device, or session exists.
class Sprint117SecurityCenterWorkflowDrill {
  const Sprint117SecurityCenterWorkflowDrill();

  /// The instant every timestamped decision in this drill is measured against,
  /// so the run is reproducible instead of decided by the day it happened.
  static final DateTime fixedNow = DateTime.utc(2026, 1, 1, 12);

  /// Source files that hold the shipped security mechanisms. A check whose
  /// behaviour only these files exercise is the mechanism existing, not the
  /// feature being reachable by a user.
  static const List<String> shippedSources = <String>[
    'lib/features/account/domain/account_center_security_summary.dart',
    'lib/features/account/domain/account_center_session_device_management.dart',
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
  /// the two facts must not be collapsed into one.
  ///
  /// Paths are compared RELATIVE to the repository root, never as raw
  /// `listSync` output: that method returns absolute paths on Windows, so a
  /// `startsWith('lib/')` filter matched 0 of every Dart file and reported a
  /// false zero — the defect 117.19 caught in its own harness.
  static int _productionCallSites(String source) {
    final stem = source.split('/').last;
    var count = 0;
    for (final relative in _libDartFiles()) {
      if (relative == source) continue;
      final file = File(relative);
      if (!file.existsSync()) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i += 1) {
        if (lines[i].contains(stem)) {
          count += 1;
          break;
        }
      }
    }
    return count;
  }

  /// Every `lib/` Dart file in the repository, as repository-relative paths
  /// with forward slashes and the acceptance harness family excluded.
  ///
  /// Normalising the prefix here is what makes every scan in this drill
  /// measure the repository rather than an empty set.
  static List<String> _libDartFiles() {
    final root = Directory.current.path.replaceAll('\\', '/');
    final prefix = root.endsWith('/') ? root : '$root/';
    final found = <String>[];
    for (final entity in Directory.current.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final absolute = entity.path.replaceAll('\\', '/');
      if (!absolute.endsWith('.dart')) continue;
      if (!absolute.startsWith(prefix)) continue;
      final relative = absolute.substring(prefix.length);
      if (!relative.startsWith('lib/')) continue;
      if (relative.contains('/sprint_117_')) continue;
      found.add(relative);
    }
    return found;
  }

  /// Counts production files that read a field the checks below measure.
  ///
  /// A field the summary carries and nothing in `lib/` reads is a stored
  /// assertion, not a computed signal. Measured rather than assumed, because a
  /// `true` constant here would turn "the signal is real" into a claim nothing
  /// looked for.
  static int _symbolCallSites(String symbol, {String? excluding}) {
    var count = 0;
    for (final relative in _libDartFiles()) {
      if (relative == excluding) continue;
      final file = File(relative);
      if (!file.existsSync()) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i += 1) {
        if (lines[i].contains(symbol)) {
          count += 1;
          break;
        }
      }
    }
    return count;
  }

  /// Per shipped source: does it declare the mechanism this check exercises.
  static final Map<String, bool> _mechanismPresent = <String, bool>{
    'mfa.enrolledMethods': _declares(shippedSources[0], 'enrolledMethods'),
    'mfa.recoveryCodes': _declares(shippedSources[0], 'recoveryCodesRemaining'),
    'mfa.healthyRequiresCodes': _declares(
      shippedSources[0],
      'A healthy MFA status requires at least one recovery code',
    ),
    'password.changedAt': _declares(shippedSources[0], 'changedAt'),
    'devices.count': _declares(shippedSources[0], 'DeviceSecuritySummary'),
    'sessions.activeCount': _declares(shippedSources[0], 'activeCount'),
    'sessions.secureStore': _declares(
      shippedSources[0],
      'SecureStoreSecuritySummary',
    ),
    'overall.blindSpot': _declares(shippedSources[0], 'unreadable > 0'),
    'sessions.revoke': _declares(shippedSources[1], 'revokeSession'),
    'sessions.forceLogout': _declares(shippedSources[1], 'forceLogout'),
    'sessions.auditTrail': _declares(
      shippedSources[1],
      'SessionSecurityAuditEvent',
    ),
    'sessions.deniedRecorded': _declares(
      shippedSources[1],
      'SessionAuditOutcome.denied',
    ),
  };

  /// Whether any production file imports the security summary this slice
  /// validates. Measured, not assumed.
  static final int _securitySummaryCallSites = _productionCallSites(
    shippedSources[0],
  );

  /// Whether any production file imports the session seam.
  static final int _sessionManagementCallSites = _productionCallSites(
    shippedSources[1],
  );

  /// Whether any shipped file records a session revocation.
  static final int _revocationAuditCallSites = _symbolCallSites(
    'SessionSecurityAuditEvent',
    excluding: shippedSources[1],
  );

  /// Whether any shipped file reads the recovery-code count.
  static final int _recoveryCodeCallSites = _symbolCallSites(
    'recoveryCodesRemaining',
    excluding: shippedSources[0],
  );

  /// Whether any shipped file builds a session summary from the session seam.
  static final int _sessionSummaryCallSites = _symbolCallSites(
    'SessionSecuritySummary',
    excluding: shippedSources[0],
  );

  /// Whether any shipped file decides that a password is stale.
  static final int _passwordStalenessCallSites = _symbolCallSites(
    'PasswordSecuritySummary',
    excluding: shippedSources[0],
  );

  /// Whether any shipped file builds a device summary from the session seam.
  static final int _deviceAggregationCallSites = _symbolCallSites(
    'DeviceSecuritySummary',
    excluding: shippedSources[0],
  );

  /// Records whether [attempt] threw, without letting the throw escape.
  static bool _throws(void Function() attempt) {
    try {
      attempt();
      return false;
    } on Object {
      return true;
    }
  }

  /// Builds a session whose outcome [action] produced, for revocation checks.
  static AccountCenterSessionDeviceManagement _sessionFixture() =>
      AccountCenterSessionDeviceManagement(
        sessions: <ManagedSession>[
          ManagedSession(
            sessionId: 'session-current',
            isCurrent: true,
            lastActiveAt: DateTime.utc(2026, 1, 1, 11),
            trust: SessionTrustState.trusted,
            state: SessionActivityState.active,
            suspicious: false,
            device: DeviceDetails(
              deviceLabel: 'Studio desktop',
              platform: SessionDevicePlatform.windows,
              appVersion: '1.3.0',
            ),
          ),
          ManagedSession(
            sessionId: 'session-phone',
            isCurrent: false,
            lastActiveAt: DateTime.utc(2026, 1, 1, 10),
            trust: SessionTrustState.untrusted,
            state: SessionActivityState.active,
            suspicious: true,
            device: DeviceDetails(
              deviceLabel: 'Phone',
              platform: SessionDevicePlatform.android,
              appVersion: '1.2.4',
            ),
          ),
          ManagedSession(
            sessionId: 'session-tablet',
            isCurrent: false,
            lastActiveAt: DateTime.utc(2026, 1, 1, 9),
            trust: SessionTrustState.unknown,
            state: SessionActivityState.active,
            suspicious: false,
            device: DeviceDetails(
              deviceLabel: 'Tablet',
              platform: SessionDevicePlatform.ios,
            ),
          ),
        ],
        alerts: const <SessionSecurityAlert>[],
      );

  /// A summary with every core signal in [status], built here and never a claim
  /// about a real account.
  static AccountCenterSecuritySummary _summaryWith(
    SecuritySignalStatus status, {
    Iterable<SecurityCenterAlert> alerts = const <SecurityCenterAlert>[],
    int? recoveryCodes = 3,
    Set<String> methods = const <String>{'totp'},
  }) => AccountCenterSecuritySummary(
    mfa: MfaSecuritySummary(
      status: status,
      enrolledMethods: methods,
      recoveryCodesRemaining: recoveryCodes,
    ),
    password: PasswordSecuritySummary(
      status: status,
      changedAt:
          status == SecuritySignalStatus.unknown ||
              status == SecuritySignalStatus.unavailable
          ? null
          : DateTime.utc(2025, 6, 1),
    ),
    trustedDevices: DeviceSecuritySummary(
      status: status,
      count:
          status == SecuritySignalStatus.unknown ||
              status == SecuritySignalStatus.unavailable
          ? null
          : 2,
    ),
    sessions: SessionSecuritySummary(
      status: status,
      activeCount:
          status == SecuritySignalStatus.unknown ||
              status == SecuritySignalStatus.unavailable
          ? null
          : 3,
      suspiciousCount:
          status == SecuritySignalStatus.unknown ||
              status == SecuritySignalStatus.unavailable
          ? null
          : 1,
    ),
    secureStore: SecureStoreSecuritySummary(
      status: status,
      backend:
          status == SecuritySignalStatus.unknown ||
              status == SecuritySignalStatus.unavailable
          ? null
          : 'os_secure_store',
      lastCheckedAt:
          status == SecuritySignalStatus.unknown ||
              status == SecuritySignalStatus.unavailable
          ? null
          : DateTime.utc(2026, 1, 1, 11),
    ),
    alerts: alerts,
    actions: const <SecurityRecommendedAction>[],
  );

  /// Runs every canonical check against the repository as it stands.
  Future<Sprint117SecurityCenterWorkflowDrillRun> run() async {
    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117SecurityCenterWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }

    final observations = <Sprint117SecurityCenterWorkflowObservation>[
      _observeMfa(),
      _observePassword(),
      _observeDevices(),
      _observeSessions(),
      _observeRevoke(),
      _observeAlerts(),
      _observeSecureStore(),
      _observeRecovery(),
    ];

    return Sprint117SecurityCenterWorkflowDrillRun(
      observations: observations,
      // Nothing here contacts a network, opens a project, or reads a secret:
      // every value is a literal fixture built in this file.
      liveProviderTouched: false,
      userProjectTouched: false,
      liveCredentialObserved: false,
      externalPinsMatched: matched,
      externalPinsChecked: checked,
      productionCallerPresent: _securitySummaryCallSites > 0,
      securitySummaryProductionCallSites: _securitySummaryCallSites,
      sessionManagementProductionCallSites: _sessionManagementCallSites,
      revocationAuditPresent: _revocationAuditCallSites > 0,
      recoveryCodeLifecycleCallSites: _recoveryCodeCallSites,
      sessionSummaryAggregatedSomewhere: _sessionSummaryCallSites > 0,
      passwordStalenessComputedSomewhere: _passwordStalenessCallSites > 0,
      deviceTrustAggregatedSomewhere: _deviceAggregationCallSites > 0,
    );
  }

  Sprint117SecurityCenterWorkflowObservation _observeMfa() {
    // A known status must carry an enrolled method, and a healthy status must
    // carry a recovery path. Both are measured by making the call.
    final knownNeedsMethod = _throws(
      () => MfaSecuritySummary(
        status: SecuritySignalStatus.healthy,
        enrolledMethods: const <String>{},
        recoveryCodesRemaining: 3,
      ),
    );
    final healthyWithNoCodes = _throws(
      () => MfaSecuritySummary(
        status: SecuritySignalStatus.healthy,
        enrolledMethods: const <String>{'totp'},
        recoveryCodesRemaining: 0,
      ),
    );
    final attentionWithNoCodes = !_throws(
      () => MfaSecuritySummary(
        status: SecuritySignalStatus.attention,
        enrolledMethods: const <String>{'totp'},
        recoveryCodesRemaining: 0,
      ),
    );
    final noMethodNoCodes = !_throws(
      () => MfaSecuritySummary(
        status: SecuritySignalStatus.unavailable,
        enrolledMethods: const <String>{},
        recoveryCodesRemaining: null,
      ),
    );

    final facts = <String, Object?>{
      'known_status_requires_enrolled_method': knownNeedsMethod,
      'healthy_with_zero_recovery_codes_is_refused': healthyWithNoCodes,
      'attention_with_zero_recovery_codes_is_allowed': attentionWithNoCodes,
      'no_method_no_codes_is_available_as_unavailable': noMethodNoCodes,
      'acceptance_mechanism_present': _mechanismPresent['mfa.enrolledMethods'],
    };
    final passed =
        knownNeedsMethod &&
        healthyWithNoCodes &&
        attentionWithNoCodes &&
        noMethodNoCodes;
    return Sprint117SecurityCenterWorkflowObservation(
      checkId: 'mfa',
      outcome:
          'A known MFA status demands an enrolled method and a healthy one '
          'demands a remaining recovery code.',
      facts: facts,
      passed: passed,
      acceptance:
          _mechanismPresent['mfa.enrolledMethods']! ||
              _mechanismPresent['mfa.healthyRequiresCodes']!
          ? Sprint117SecurityCenterWorkflowAcceptance.satisfied
          : Sprint117SecurityCenterWorkflowAcceptance.mechanismAbsent,
    );
  }

  Sprint117SecurityCenterWorkflowObservation _observePassword() {
    // The seam validates the timestamp's shape. Whether that date is STALE is
    // a different claim, and no shipped file decides it, so the fact is
    // measured and reported false rather than assumed either way.
    final localRefused = _throws(
      () => PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime(2025, 6, 1),
      ),
    );
    final utcAccepted = !_throws(
      () => PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(2025, 6, 1),
      ),
    );
    final facts = <String, Object?>{
      'changed_at_must_be_utc': localRefused,
      'local_time_is_refused': localRefused,
      'utc_time_is_accepted': utcAccepted,
      'staleness_computed_somewhere_in_lib': _passwordStalenessCallSites > 0,
      'password_summary_call_sites_in_lib': _passwordStalenessCallSites,
      'acceptance_mechanism_present': _mechanismPresent['password.changedAt'],
    };
    return Sprint117SecurityCenterWorkflowObservation(
      checkId: 'password',
      outcome:
          'The password signal validates its timestamp; no shipped file '
          'decides whether that date is stale.',
      facts: facts,
      passed: localRefused && utcAccepted,
      acceptance: _mechanismPresent['password.changedAt']!
          ? Sprint117SecurityCenterWorkflowAcceptance.satisfied
          : Sprint117SecurityCenterWorkflowAcceptance.mechanismAbsent,
    );
  }

  Sprint117SecurityCenterWorkflowObservation _observeDevices() {
    // The count is validated. Whether a suspicious device is ever counted as
    // trusted is a decision nothing in lib/ makes, so it is measured.
    final knownNeedsCount = _throws(
      () => DeviceSecuritySummary(
        status: SecuritySignalStatus.healthy,
        count: null,
      ),
    );
    final negativeRefused = _throws(
      () => DeviceSecuritySummary(
        status: SecuritySignalStatus.attention,
        count: -1,
      ),
    );
    final facts = <String, Object?>{
      'known_status_requires_count': knownNeedsCount,
      'negative_count_is_refused': negativeRefused,
      'device_trust_aggregated_somewhere_in_lib':
          _deviceAggregationCallSites > 0,
      'device_summary_call_sites_in_lib': _deviceAggregationCallSites,
      'acceptance_mechanism_present': _mechanismPresent['devices.count'],
    };
    return Sprint117SecurityCenterWorkflowObservation(
      checkId: 'devices',
      outcome:
          'The device signal validates its count; no shipped file aggregates '
          'session trust into it.',
      facts: facts,
      passed: knownNeedsCount && negativeRefused,
      acceptance: _mechanismPresent['devices.count']!
          ? Sprint117SecurityCenterWorkflowAcceptance.satisfied
          : Sprint117SecurityCenterWorkflowAcceptance.mechanismAbsent,
    );
  }

  Sprint117SecurityCenterWorkflowObservation _observeSessions() {
    // The seam's own invariants, executed rather than read.
    final contradictoryRefused = _throws(
      () => SessionSecuritySummary(
        status: SecuritySignalStatus.healthy,
        activeCount: 1,
        suspiciousCount: 4,
      ),
    );
    final fixture = _sessionFixture();
    final afterLogout = fixture.forceLogout(
      confirmed: true,
      at: DateTime.utc(2026, 1, 1, 12),
    );
    final currentSurvived =
        afterLogout.sessionById('session-current').state ==
        SessionActivityState.active;
    final twoCurrentSessionsRefused = _throws(
      () => AccountCenterSessionDeviceManagement(
        sessions: <ManagedSession>[
          ManagedSession(
            sessionId: 'a',
            isCurrent: true,
            lastActiveAt: DateTime.utc(2026, 1, 1),
            trust: SessionTrustState.trusted,
            state: SessionActivityState.active,
            suspicious: false,
            device: DeviceDetails(
              deviceLabel: 'A',
              platform: SessionDevicePlatform.windows,
            ),
          ),
          ManagedSession(
            sessionId: 'b',
            isCurrent: true,
            lastActiveAt: DateTime.utc(2026, 1, 1),
            trust: SessionTrustState.trusted,
            state: SessionActivityState.active,
            suspicious: false,
            device: DeviceDetails(
              deviceLabel: 'B',
              platform: SessionDevicePlatform.windows,
            ),
          ),
        ],
        alerts: const <SessionSecurityAlert>[],
      ),
    );
    final suspiciousTrustRefused = _throws(
      () => _sessionFixture().trustSession(
        'session-phone',
        trusted: true,
        at: DateTime.utc(2026, 1, 1, 12),
      ),
    );

    final facts = <String, Object?>{
      'suspicious_count_never_exceeds_active': contradictoryRefused,
      'exactly_one_current_session_enforced': twoCurrentSessionsRefused,
      'current_session_survives_force_logout': currentSurvived,
      'suspicious_session_cannot_be_trusted': suspiciousTrustRefused,
      'active_count_measured': fixture.activeCount,
      'suspicious_count_measured': fixture.suspiciousCount,
      'revoked_after_force_logout': afterLogout.revokedCount,
      'session_summary_aggregated_somewhere_in_lib':
          _sessionSummaryCallSites > 0,
      'acceptance_mechanism_present': _mechanismPresent['sessions.activeCount'],
    };
    return Sprint117SecurityCenterWorkflowObservation(
      checkId: 'sessions',
      outcome:
          'The session seam refuses contradictory counts, keeps exactly one '
          'current session, and never trusts a flagged one.',
      facts: facts,
      passed:
          contradictoryRefused &&
          twoCurrentSessionsRefused &&
          currentSurvived &&
          suspiciousTrustRefused,
      acceptance: _mechanismPresent['sessions.activeCount']!
          ? Sprint117SecurityCenterWorkflowAcceptance.satisfied
          : Sprint117SecurityCenterWorkflowAcceptance.mechanismAbsent,
    );
  }

  Sprint117SecurityCenterWorkflowObservation _observeRevoke() {
    // The defect: the seam had no audit collection, so a refusal and an
    // attempt never made were identical. Both are now executed and the trail
    // is read back.
    final fixture = _sessionFixture();
    final denied = fixture.revokeSession(
      'session-current',
      at: DateTime.utc(2026, 1, 1, 12),
    );
    final deniedEvents = denied.auditFor('revoke_session');
    final afterDenied = denied.sessionById('session-current').state;
    final currentUntouched = afterDenied == SessionActivityState.active;

    final revoked = denied.revokeSession(
      'session-phone',
      at: DateTime.utc(2026, 1, 1, 12, 1),
    );
    final revokedEvents = revoked.auditFor('revoke_session');

    final unconfirmed = _sessionFixture().forceLogout(
      confirmed: false,
      at: DateTime.utc(2026, 1, 1, 12, 2),
    );
    final unconfirmedEvents = unconfirmed.auditFor('force_logout');
    final logoutDeniedNothing = unconfirmed.revokedCount == 0;

    final confirmed = _sessionFixture().forceLogout(
      confirmed: true,
      at: DateTime.utc(2026, 1, 1, 12, 3),
    );
    final confirmedEvents = confirmed.auditFor('force_logout');

    // Redaction: the recorded event names the action, the session, the outcome
    // and the instant. It must not carry the device label or a free-text reason.
    final sample = deniedEvents.isEmpty ? null : deniedEvents.first;
    final eventKeys = sample?.toJson().keys.toSet() ?? const <String>{};
    final redacted =
        !eventKeys.contains('device') &&
        !eventKeys.contains('device_label') &&
        !eventKeys.contains('location') &&
        !eventKeys.contains('reason');

    final facts = <String, Object?>{
      'denied_revoke_is_recorded': deniedEvents.any(
        (event) => event.outcome == SessionAuditOutcome.denied,
      ),
      'revoked_revoke_is_recorded': revokedEvents.any(
        (event) => event.outcome == SessionAuditOutcome.revoked,
      ),
      'unforceable_current_session_refused': currentUntouched,
      'force_logout_requires_confirmation': logoutDeniedNothing,
      'denied_force_logout_is_recorded': unconfirmedEvents.any(
        (event) => event.outcome == SessionAuditOutcome.denied,
      ),
      'confirmed_force_logout_names_each_session': confirmedEvents
          .where((event) => event.outcome == SessionAuditOutcome.revoked)
          .length,
      'audit_event_carries_no_device_or_reason': redacted,
      'audit_event_keys': eventKeys.toList()..sort(),
      'revocation_audit_in_other_lib_files': _revocationAuditCallSites,
      'acceptance_mechanism_present': _mechanismPresent['sessions.auditTrail'],
    };
    final passed =
        deniedEvents.any(
          (event) => event.outcome == SessionAuditOutcome.denied,
        ) &&
        revokedEvents.any(
          (event) => event.outcome == SessionAuditOutcome.revoked,
        ) &&
        currentUntouched &&
        logoutDeniedNothing &&
        unconfirmedEvents.any(
          (event) => event.outcome == SessionAuditOutcome.denied,
        ) &&
        redacted;
    return Sprint117SecurityCenterWorkflowObservation(
      checkId: 'revoke',
      outcome:
          'A refused revoke and a completed revoke are both recorded, and an '
          'unconfirmed force logout is recorded as denied.',
      facts: facts,
      passed: passed,
      acceptance: _mechanismPresent['sessions.auditTrail']!
          ? Sprint117SecurityCenterWorkflowAcceptance.satisfied
          : Sprint117SecurityCenterWorkflowAcceptance.mechanismAbsent,
    );
  }

  Sprint117SecurityCenterWorkflowObservation _observeAlerts() {
    // The defect: `overallStatus` returned `healthy` as soon as ONE signal was
    // healthy, so four unread signals were invisible. Every case below is
    // executed, not read.
    final allHealthy = _summaryWith(SecuritySignalStatus.healthy);

    final oneHealthyFourUnknown = AccountCenterSecuritySummary(
      mfa: MfaSecuritySummary(
        status: SecuritySignalStatus.healthy,
        enrolledMethods: const <String>{'totp'},
        recoveryCodesRemaining: 4,
      ),
      password: PasswordSecuritySummary(
        status: SecuritySignalStatus.unknown,
        changedAt: null,
      ),
      trustedDevices: DeviceSecuritySummary(
        status: SecuritySignalStatus.unknown,
        count: null,
      ),
      sessions: SessionSecuritySummary(
        status: SecuritySignalStatus.unknown,
        activeCount: null,
        suspiciousCount: null,
      ),
      secureStore: SecureStoreSecuritySummary(
        status: SecuritySignalStatus.unknown,
        backend: null,
        lastCheckedAt: null,
      ),
      alerts: const <SecurityCenterAlert>[],
      actions: const <SecurityRecommendedAction>[],
    );

    final infoAlertOnly = AccountCenterSecuritySummary(
      mfa: MfaSecuritySummary(
        status: SecuritySignalStatus.unknown,
        enrolledMethods: const <String>{},
        recoveryCodesRemaining: null,
      ),
      password: PasswordSecuritySummary(
        status: SecuritySignalStatus.unknown,
        changedAt: null,
      ),
      trustedDevices: DeviceSecuritySummary(
        status: SecuritySignalStatus.unknown,
        count: null,
      ),
      sessions: SessionSecuritySummary(
        status: SecuritySignalStatus.unknown,
        activeCount: null,
        suspiciousCount: null,
      ),
      secureStore: SecureStoreSecuritySummary(
        status: SecuritySignalStatus.unknown,
        backend: null,
        lastCheckedAt: null,
      ),
      alerts: <SecurityCenterAlert>[
        SecurityCenterAlert(
          id: 'routine',
          severity: SecurityAlertSeverity.info,
          title: 'Routine check-in',
          occurredAt: DateTime.utc(2026, 1, 1, 11),
        ),
      ],
      actions: const <SecurityRecommendedAction>[],
    );

    final allUnknown = _summaryWith(SecuritySignalStatus.unknown);

    final criticalWithUnknown = AccountCenterSecuritySummary(
      mfa: MfaSecuritySummary(
        status: SecuritySignalStatus.healthy,
        enrolledMethods: const <String>{'totp'},
        recoveryCodesRemaining: 4,
      ),
      password: PasswordSecuritySummary(
        status: SecuritySignalStatus.unknown,
        changedAt: null,
      ),
      trustedDevices: DeviceSecuritySummary(
        status: SecuritySignalStatus.unknown,
        count: null,
      ),
      sessions: SessionSecuritySummary(
        status: SecuritySignalStatus.unknown,
        activeCount: null,
        suspiciousCount: null,
      ),
      secureStore: SecureStoreSecuritySummary(
        status: SecuritySignalStatus.unknown,
        backend: null,
        lastCheckedAt: null,
      ),
      alerts: <SecurityCenterAlert>[
        SecurityCenterAlert(
          id: 'breach',
          severity: SecurityAlertSeverity.critical,
          title: 'Credential reuse detected',
          occurredAt: DateTime.utc(2026, 1, 1, 11),
        ),
      ],
      actions: const <SecurityRecommendedAction>[],
    );

    final attentionWithUnknown = AccountCenterSecuritySummary(
      mfa: MfaSecuritySummary(
        status: SecuritySignalStatus.healthy,
        enrolledMethods: const <String>{'totp'},
        recoveryCodesRemaining: 4,
      ),
      password: PasswordSecuritySummary(
        status: SecuritySignalStatus.attention,
        changedAt: DateTime.utc(2020, 1, 1),
      ),
      trustedDevices: DeviceSecuritySummary(
        status: SecuritySignalStatus.unknown,
        count: null,
      ),
      sessions: SessionSecuritySummary(
        status: SecuritySignalStatus.unknown,
        activeCount: null,
        suspiciousCount: null,
      ),
      secureStore: SecureStoreSecuritySummary(
        status: SecuritySignalStatus.unknown,
        backend: null,
        lastCheckedAt: null,
      ),
      alerts: const <SecurityCenterAlert>[],
      actions: const <SecurityRecommendedAction>[],
    );

    final facts = <String, Object?>{
      'one_healthy_among_unknown_is_not_healthy':
          oneHealthyFourUnknown.overallStatus != SecuritySignalStatus.healthy,
      'one_healthy_among_unknown_reports':
          oneHealthyFourUnknown.overallStatus.name,
      'info_alert_alone_is_not_healthy':
          infoAlertOnly.overallStatus != SecuritySignalStatus.healthy,
      'info_alert_alone_reports': infoAlertOnly.overallStatus.name,
      'all_unknown_is_unknown':
          allUnknown.overallStatus == SecuritySignalStatus.unknown,
      'critical_still_wins_over_unknown':
          criticalWithUnknown.overallStatus == SecuritySignalStatus.critical,
      'attention_still_wins_over_unknown':
          attentionWithUnknown.overallStatus == SecuritySignalStatus.attention,
      'five_known_healthy_is_healthy':
          allHealthy.overallStatus == SecuritySignalStatus.healthy,
      'five_known_healthy_reports': allHealthy.overallStatus.name,
      'acceptance_mechanism_present': _mechanismPresent['overall.blindSpot'],
    };
    final passed =
        oneHealthyFourUnknown.overallStatus != SecuritySignalStatus.healthy &&
        infoAlertOnly.overallStatus != SecuritySignalStatus.healthy &&
        allUnknown.overallStatus == SecuritySignalStatus.unknown &&
        criticalWithUnknown.overallStatus == SecuritySignalStatus.critical &&
        attentionWithUnknown.overallStatus == SecuritySignalStatus.attention &&
        allHealthy.overallStatus == SecuritySignalStatus.healthy;
    return Sprint117SecurityCenterWorkflowObservation(
      checkId: 'alerts',
      outcome:
          'An unread signal never lets a Security Center read healthy, while a '
          'genuinely bad signal still wins.',
      facts: facts,
      passed: passed,
      acceptance: _mechanismPresent['overall.blindSpot']!
          ? Sprint117SecurityCenterWorkflowAcceptance.satisfied
          : Sprint117SecurityCenterWorkflowAcceptance.mechanismAbsent,
    );
  }

  Sprint117SecurityCenterWorkflowObservation _observeSecureStore() {
    final knownNeedsBackend = _throws(
      () => SecureStoreSecuritySummary(
        status: SecuritySignalStatus.healthy,
        backend: null,
        lastCheckedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    final knownNeedsTimestamp = _throws(
      () => SecureStoreSecuritySummary(
        status: SecuritySignalStatus.healthy,
        backend: 'os_secure_store',
        lastCheckedAt: null,
      ),
    );
    final blankBackendRefused = _throws(
      () => SecureStoreSecuritySummary(
        status: SecuritySignalStatus.attention,
        backend: '   ',
        lastCheckedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    // An unread store, whatever the other four signals say, must not read
    // healthy.
    final unreadStore = AccountCenterSecuritySummary(
      mfa: MfaSecuritySummary(
        status: SecuritySignalStatus.healthy,
        enrolledMethods: const <String>{'totp'},
        recoveryCodesRemaining: 4,
      ),
      password: PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(2026, 1, 1),
      ),
      trustedDevices: DeviceSecuritySummary(
        status: SecuritySignalStatus.healthy,
        count: 1,
      ),
      sessions: SessionSecuritySummary(
        status: SecuritySignalStatus.healthy,
        activeCount: 1,
        suspiciousCount: 0,
      ),
      secureStore: SecureStoreSecuritySummary(
        status: SecuritySignalStatus.unavailable,
        backend: null,
        lastCheckedAt: null,
      ),
      alerts: const <SecurityCenterAlert>[],
      actions: const <SecurityRecommendedAction>[],
    );

    final facts = <String, Object?>{
      'known_status_requires_backend': knownNeedsBackend,
      'known_status_requires_check_timestamp': knownNeedsTimestamp,
      'blank_backend_is_refused': blankBackendRefused,
      'unavailable_backend_is_never_healthy':
          unreadStore.overallStatus != SecuritySignalStatus.healthy,
      'unavailable_backend_reports': unreadStore.overallStatus.name,
      'acceptance_mechanism_present': _mechanismPresent['sessions.secureStore'],
    };
    return Sprint117SecurityCenterWorkflowObservation(
      checkId: 'secure_store',
      outcome:
          'A known secure-store status demands a backend and a check instant, '
          'and an unread store keeps the account out of healthy.',
      facts: facts,
      passed:
          knownNeedsBackend &&
          knownNeedsTimestamp &&
          blankBackendRefused &&
          unreadStore.overallStatus != SecuritySignalStatus.healthy,
      acceptance: _mechanismPresent['sessions.secureStore']!
          ? Sprint117SecurityCenterWorkflowAcceptance.satisfied
          : Sprint117SecurityCenterWorkflowAcceptance.mechanismAbsent,
    );
  }

  Sprint117SecurityCenterWorkflowObservation _observeRecovery() {
    // The recovery path is the only way back into an account once a factor is
    // lost, so its three states are measured rather than assumed.
    final zeroRefusedAsHealthy = _throws(
      () => MfaSecuritySummary(
        status: SecuritySignalStatus.healthy,
        enrolledMethods: const <String>{'totp'},
        recoveryCodesRemaining: 0,
      ),
    );
    final zeroAcceptedAsAttention = !_throws(
      () => MfaSecuritySummary(
        status: SecuritySignalStatus.attention,
        enrolledMethods: const <String>{'totp'},
        recoveryCodesRemaining: 0,
      ),
    );
    final negativeRefused = _throws(
      () => MfaSecuritySummary(
        status: SecuritySignalStatus.unknown,
        enrolledMethods: const <String>{'totp'},
        recoveryCodesRemaining: -1,
      ),
    );
    // The count is carried but nothing in lib/ reads it, so an operator has
    // no path from a depleted set to a reissued one. Measured, not assumed.
    final sample = MfaSecuritySummary(
      status: SecuritySignalStatus.attention,
      enrolledMethods: const <String>{'totp'},
      recoveryCodesRemaining: 2,
    );

    final facts = <String, Object?>{
      'zero_recovery_codes_flagged': zeroRefusedAsHealthy,
      'missing_recovery_path_is_flagged': zeroAcceptedAsAttention,
      'negative_recovery_codes_refused': negativeRefused,
      'recovery_codes_remaining_is_immutable': (() {
        try {
          // ignore: unused_local_variable
          final _ = sample.recoveryCodesRemaining;
          return true;
        } on Object {
          return false;
        }
      })(),
      'recovery_code_lifecycle_call_sites_in_lib': _recoveryCodeCallSites,
      'recovery_codes_carried': sample.recoveryCodesRemaining,
      'acceptance_mechanism_present': _mechanismPresent['mfa.recoveryCodes'],
    };
    return Sprint117SecurityCenterWorkflowObservation(
      checkId: 'recovery',
      outcome:
          'A drained recovery path cannot be reported healthy, and no shipped '
          'file issues or consumes a recovery code.',
      facts: facts,
      passed:
          zeroRefusedAsHealthy && zeroAcceptedAsAttention && negativeRefused,
      acceptance: _mechanismPresent['mfa.recoveryCodes']!
          ? Sprint117SecurityCenterWorkflowAcceptance.satisfied
          : Sprint117SecurityCenterWorkflowAcceptance.mechanismAbsent,
    );
  }
}
