library;

import 'dart:convert';
import 'dart:io';

/// Canonical contract for Sprint 116.48, Connector Contract & End-to-End
/// Matrix.
///
/// The step asks for two things that are easy to fake separately: contract
/// tests per suite, and one honest lifecycle run per proposed connector
/// (connect, use, refresh, error, reauth, disconnect, cleanup). A control set
/// that answers one and skips the other has proven nothing, so the joins below
/// exist to refuse exactly that: a connector audited only through its happy
/// path, a lifecycle whose order is impossible, a cleanup that contradicts a
/// later session, and a manifest that lists a connector nobody ever ran.
///
/// Every fixture shipped with this contract is synthetic and UNVERIFIED. No
/// credential, token, secret, or provider availability is asserted here.
enum Sprint116ConnectorMatrixStatus { pass, fail, blocked }

/// One connector as the manifest proposes it. Metadata only.
class Sprint116ConnectorManifestRecord {
  Sprint116ConnectorManifestRecord({
    required this.connectorId,
    required this.providerId,
    required this.connectorVersion,
    required this.authType,
    required this.declaredCapabilities,
    required this.requestedPermissions,
    required this.availability,
    required this.proposed,
    required this.source,
    required this.evidenceRef,
  });

  final String connectorId;
  final String providerId;
  final String connectorVersion;
  final String authType;
  final List<String> declaredCapabilities;
  final List<String> requestedPermissions;
  final String availability;
  final bool proposed;
  final String source;
  final String? evidenceRef;
}

/// The connect step of the lifecycle, including what the app asked for and
/// what the provider actually granted.
class Sprint116ConnectRun {
  Sprint116ConnectRun({
    required this.connectorId,
    required this.pkceMethod,
    required this.stateParameter,
    required this.requestedScopes,
    required this.grantedScopes,
    required this.partialGrantAccepted,
    required this.tokenSha256,
    required this.secretRedactedInLogs,
    required this.connectedAtEpochMs,
    required this.atEpochMs,
    required this.source,
    required this.evidenceRef,
  });

  final String connectorId;
  final String pkceMethod;
  final String stateParameter;
  final List<String> requestedScopes;
  final List<String> grantedScopes;
  final bool partialGrantAccepted;
  final String tokenSha256;
  final bool secretRedactedInLogs;
  final int connectedAtEpochMs;
  final int atEpochMs;
  final String source;
  final String? evidenceRef;
}

class Sprint116CapabilityRun {
  Sprint116CapabilityRun({
    required this.connectorId,
    required this.exercisedCapabilities,
    required this.callSucceeded,
    required this.failureClassified,
    required this.leavesDevice,
    required this.dataEgressEncrypted,
    required this.sessionValid,
    required this.atEpochMs,
    required this.source,
    required this.evidenceRef,
  });

  final String connectorId;
  final List<String> exercisedCapabilities;
  final bool callSucceeded;
  final bool failureClassified;
  final bool leavesDevice;
  final bool dataEgressEncrypted;
  final bool sessionValid;
  final int atEpochMs;
  final String source;
  final String? evidenceRef;
}

class Sprint116UsageRun {
  Sprint116UsageRun({
    required this.connectorId,
    required this.unit,
    required this.meter,
    required this.rawValue,
    required this.valueAvailable,
    required this.attributedCapability,
    required this.observedAtEpochMs,
    required this.freshnessTtlSeconds,
    required this.sessionValid,
    required this.source,
    required this.evidenceRef,
  });

  final String connectorId;
  final String unit;
  final String meter;
  final num rawValue;
  final bool valueAvailable;
  final String attributedCapability;
  final int observedAtEpochMs;
  final int freshnessTtlSeconds;
  final bool sessionValid;
  final String source;
  final String? evidenceRef;
}

class Sprint116ErrorRun {
  Sprint116ErrorRun({
    required this.connectorId,
    required this.errorState,
    required this.httpStatus,
    required this.failureSurfaced,
    required this.userMessage,
    required this.recoveryVerifiedAtEpochMs,
    required this.atEpochMs,
    required this.source,
    required this.evidenceRef,
  });

  final String connectorId;
  final String errorState;
  final int httpStatus;
  final bool failureSurfaced;
  final String userMessage;
  final int recoveryVerifiedAtEpochMs;
  final int atEpochMs;
  final String source;
  final String? evidenceRef;
}

class Sprint116ReauthRun {
  Sprint116ReauthRun({
    required this.connectorId,
    required this.strategy,
    required this.priorTokenSha256,
    required this.refreshedTokenSha256,
    required this.priorTokenInvalidated,
    required this.refreshedTokenExpiresEpochMs,
    required this.refreshedAtEpochMs,
    required this.sessionValidAfterReauth,
    required this.source,
    required this.evidenceRef,
  });

  final String connectorId;
  final String strategy;
  final String priorTokenSha256;
  final String refreshedTokenSha256;
  final bool priorTokenInvalidated;
  final int refreshedTokenExpiresEpochMs;
  final int refreshedAtEpochMs;
  final bool sessionValidAfterReauth;
  final String source;
  final String? evidenceRef;
}

class Sprint116DisconnectRun {
  Sprint116DisconnectRun({
    required this.connectorId,
    required this.stateBeforeDisconnect,
    required this.disconnectRequested,
    required this.callsAfterDisconnectRejected,
    required this.newTokensIssuedAfterDisconnect,
    required this.disconnectedAtEpochMs,
    required this.source,
    required this.evidenceRef,
  });

  final String connectorId;
  final String stateBeforeDisconnect;
  final bool disconnectRequested;
  final bool callsAfterDisconnectRejected;
  final bool newTokensIssuedAfterDisconnect;
  final int disconnectedAtEpochMs;
  final String source;
  final String? evidenceRef;
}

class Sprint116CleanupRun {
  Sprint116CleanupRun({
    required this.connectorId,
    required this.tokenRemoved,
    required this.cacheRemoved,
    required this.vaultEntryRemoved,
    required this.postCleanupProbeAuthorized,
    required this.localProjectDataDeleted,
    required this.auditRetained,
    required this.cleanedAtEpochMs,
    required this.source,
    required this.evidenceRef,
  });

  final String connectorId;
  final bool tokenRemoved;
  final bool cacheRemoved;
  final bool vaultEntryRemoved;

  /// The decisive probe: after cleanup the old credential must be refused.
  final bool postCleanupProbeAuthorized;

  /// Unlinking a provider is not the app's right to delete the author's work.
  final bool localProjectDataDeleted;
  final bool auditRetained;
  final int cleanedAtEpochMs;
  final String source;
  final String? evidenceRef;
}

class Sprint116RegressionRun {
  Sprint116RegressionRun({
    required this.connectorId,
    required this.runId,
    required this.command,
    required this.exitCode,
    required this.passed,
    required this.total,
    required this.skipped,
    required this.skipReason,
    required this.coveredSuites,
    required this.headSha,
    required this.source,
    required this.evidenceRef,
  });

  final String connectorId;
  final String runId;
  final String command;
  final int exitCode;
  final int passed;
  final int total;
  final int skipped;
  final String skipReason;
  final List<String> coveredSuites;
  final String headSha;
  final String source;
  final String? evidenceRef;
}

class Sprint116ConnectorControlSet {
  Sprint116ConnectorControlSet({
    required this.manifests,
    required this.connectRuns,
    required this.capabilityRuns,
    required this.usageRuns,
    required this.errorRuns,
    required this.reauthRuns,
    required this.disconnectRuns,
    required this.cleanupRuns,
    required this.regressionRuns,
  });

  final List<Sprint116ConnectorManifestRecord> manifests;
  final List<Sprint116ConnectRun> connectRuns;
  final List<Sprint116CapabilityRun> capabilityRuns;
  final List<Sprint116UsageRun> usageRuns;
  final List<Sprint116ErrorRun> errorRuns;
  final List<Sprint116ReauthRun> reauthRuns;
  final List<Sprint116DisconnectRun> disconnectRuns;
  final List<Sprint116CleanupRun> cleanupRuns;
  final List<Sprint116RegressionRun> regressionRuns;
}

class Sprint116ConnectorMatrixReport {
  Sprint116ConnectorMatrixReport({
    required this.state,
    required this.invalidRecords,
    required this.coveredSuites,
    required this.unauditedConnectors,
  });

  final Sprint116ConnectorMatrixStatus state;
  final List<String> invalidRecords;
  final List<String> coveredSuites;

  /// Connectors the manifest proposes but no suite ever ran against.
  final List<String> unauditedConnectors;

  String get externalGates => Sprint116ConnectorMatrixContract.externalGates;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'canonical_step': Sprint116ConnectorMatrixContract.canonicalStep,
      'state': state.name,
      'invalid_records': invalidRecords,
      'covered_suites': coveredSuites,
      'unaudited_connectors': unauditedConnectors,
      'live_connector_execution': false,
      'external_gates': externalGates,
    };
  }
}

abstract final class Sprint116ConnectorMatrixContract {
  static const String canonicalStep = '116.48';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_connector_contract_e2e_matrix.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The nine suites canonical step 116.48 names.
  static const List<String> requiredSuites = <String>[
    'manifest',
    'auth',
    'capability',
    'usage',
    'error',
    'reauth',
    'disconnect',
    'cleanup',
    'regression',
  ];

  /// `local_run` is an executed local test command, not a fixture, but it still
  /// has to name the evidence file it produced.
  static const List<String> supportedSources = <String>[
    'synthetic_local',
    'live',
    'local_run',
  ];

  /// Sources that may only be believed when they point at evidence.
  static const List<String> evidencedSources = <String>['live', 'local_run'];

  static const List<String> knownAuthTypes = <String>[
    'oauth2_pkce',
    'oidc',
    'device_code',
    'api_key',
    'local_broker',
    'none',
  ];

  static const List<String> knownCapabilities = <String>[
    'identity',
    'storage',
    'sync',
    'backup',
    'ai_text',
    'ai_image',
    'ai_audio',
    'ai_video',
    'developer',
    'creative',
    'payment',
    'health',
  ];

  static const List<String> knownErrorStates = <String>[
    'invalid_credentials',
    'expired',
    'revoked',
    'scope_denied',
    'rate_limited',
    'outage',
    'unsupported_region',
    'unsupported_plan',
  ];

  static const List<String> knownUsageUnits = <String>[
    'tokens',
    'bytes',
    'requests',
    'count',
    'seconds',
    'credits',
  ];

  /// A state a provider can actually be in when the app tries to unlink it.
  static const List<String> knownPreDisconnectStates = <String>[
    'connected',
    'reauthenticated',
  ];

  /// Auth types that can hold a renewable credential at all.
  static const List<String> renewableAuthTypes = <String>[
    'oauth2_pkce',
    'oidc',
    'device_code',
  ];

  /// Auth types whose connect step necessarily carries a PKCE challenge and a
  /// state parameter. An api-key or local-broker connector has no redirect
  /// handshake, so demanding one of those would be a rule it cannot satisfy.
  static const List<String> pkceAuthTypes = <String>[
    'oauth2_pkce',
    'oidc',
    'device_code',
  ];

  /// How a reauth run renewed the session. This is a different question from
  /// which auth type the connector uses, so it has its own vocabulary.
  static const List<String> knownReauthStrategies = <String>[
    'token_refresh',
    'reauthorize',
    'not_applicable',
  ];

  /// A refresh that leaves less headroom than this is an outage already
  /// scheduled for the next half hour of use.
  static const int minimumRefreshHeadroomMs = 1800000;

  /// Evidence older than this describes a connector nobody runs any more.
  static const int maxEvidenceAgeDays = 180;
}

class Sprint116ConnectorE2EMatrix {
  /// Certifies the nine suites of step 116.48.
  ///
  /// The manifest fixture is consulted only when [controls] is omitted, so an
  /// explicit control set can never borrow fixture rows to pass.
  Sprint116ConnectorMatrixReport certify({
    Sprint116ConnectorControlSet? controls,
    int? asOfEpochMs,
    bool requireCoverage = false,
  }) {
    final usedManifest = controls == null;
    final manifest = _readManifest();
    final effective = controls ?? _controlsFromManifest(manifest);
    final effectiveAsOf =
        asOfEpochMs ?? (usedManifest ? _manifestAsOf(manifest) : null);

    if (effectiveAsOf == null || effectiveAsOf <= 0) {
      return _blocked('as_of_epoch_ms');
    }

    // An unrun suite is a gap, not a pass. Naming it first keeps the report
    // honest about what was never attempted.
    final emptySuites = <String>[
      if (effective.manifests.isEmpty) 'manifest',
      if (effective.connectRuns.isEmpty) 'auth',
      if (effective.capabilityRuns.isEmpty) 'capability',
      if (effective.usageRuns.isEmpty) 'usage',
      if (effective.errorRuns.isEmpty) 'error',
      if (effective.reauthRuns.isEmpty) 'reauth',
      if (effective.disconnectRuns.isEmpty) 'disconnect',
      if (effective.cleanupRuns.isEmpty) 'cleanup',
      if (effective.regressionRuns.isEmpty) 'regression',
    ];
    if (emptySuites.isNotEmpty) {
      return _blocked(emptySuites.first);
    }

    final invalid = <String>[];
    final covered = <String>[];
    const maxAgeMs =
        Sprint116ConnectorMatrixContract.maxEvidenceAgeDays * 86400000;

    void collect({
      required String group,
      required String identity,
      required Set<String> failed,
      required Set<String> evidence,
      required String source,
      String? evidenceRef,
      int? atEpochMs,
    }) {
      final key = identity.trim();
      if (key.isEmpty) {
        // Without an identity the row cannot be attributed to a connector, so
        // it is rejected on identity alone rather than by guessing a key.
        invalid.add('record_id:$group');
        return;
      }
      if (_staleAt(atEpochMs, effectiveAsOf, maxAgeMs)) {
        failed.add(group);
      }
      for (final suite in failed) {
        invalid.add('$suite:$key');
      }
      for (final suite in evidence) {
        if (!covered.contains(suite)) covered.add(suite);
      }
      final trimmedSource = source.trim();
      if (!Sprint116ConnectorMatrixContract.supportedSources.contains(
        trimmedSource,
      )) {
        invalid.add('no_mock_values:$key');
      } else if (Sprint116ConnectorMatrixContract.evidencedSources.contains(
            trimmedSource,
          ) &&
          (evidenceRef == null || evidenceRef.trim().isEmpty)) {
        invalid.add('no_mock_values:$key');
      }
    }

    for (final record in effective.manifests) {
      final failed = <String>{};
      final evidence = <String>{};
      _certifyManifest(record, failed, evidence);
      collect(
        group: 'manifest',
        identity: record.connectorId,
        failed: failed,
        evidence: evidence,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    final authTypeByConnector = <String, String>{
      for (final record in effective.manifests)
        record.connectorId.trim(): record.authType.trim(),
    };

    for (final run in effective.connectRuns) {
      final failed = <String>{};
      final evidence = <String>{};
      _certifyConnect(
        run,
        authTypeByConnector[run.connectorId.trim()],
        failed,
        evidence,
      );
      collect(
        group: 'auth',
        identity: run.connectorId,
        failed: failed,
        evidence: evidence,
        source: run.source,
        evidenceRef: run.evidenceRef,
        atEpochMs: run.atEpochMs,
      );
    }

    for (final run in effective.capabilityRuns) {
      final failed = <String>{};
      final evidence = <String>{};
      _certifyCapability(run, failed, evidence);
      collect(
        group: 'capability',
        identity: run.connectorId,
        failed: failed,
        evidence: evidence,
        source: run.source,
        evidenceRef: run.evidenceRef,
        atEpochMs: run.atEpochMs,
      );
    }

    for (final run in effective.usageRuns) {
      final failed = <String>{};
      final evidence = <String>{};
      _certifyUsage(run, effectiveAsOf, failed, evidence);
      collect(
        group: 'usage',
        identity: run.connectorId,
        failed: failed,
        evidence: evidence,
        source: run.source,
        evidenceRef: run.evidenceRef,
        atEpochMs: run.observedAtEpochMs,
      );
    }

    for (final run in effective.errorRuns) {
      final failed = <String>{};
      final evidence = <String>{};
      _certifyError(run, failed, evidence);
      collect(
        group: 'error',
        identity: run.connectorId,
        failed: failed,
        evidence: evidence,
        source: run.source,
        evidenceRef: run.evidenceRef,
        atEpochMs: run.atEpochMs,
      );
    }

    for (final run in effective.reauthRuns) {
      final failed = <String>{};
      final evidence = <String>{};
      _certifyReauth(run, failed, evidence);
      collect(
        group: 'reauth',
        identity: run.connectorId,
        failed: failed,
        evidence: evidence,
        source: run.source,
        evidenceRef: run.evidenceRef,
      );
    }

    for (final run in effective.disconnectRuns) {
      final failed = <String>{};
      final evidence = <String>{};
      _certifyDisconnect(run, failed, evidence);
      collect(
        group: 'disconnect',
        identity: run.connectorId,
        failed: failed,
        evidence: evidence,
        source: run.source,
        evidenceRef: run.evidenceRef,
      );
    }

    for (final run in effective.cleanupRuns) {
      final failed = <String>{};
      final evidence = <String>{};
      _certifyCleanup(run, failed, evidence);
      collect(
        group: 'cleanup',
        identity: run.connectorId,
        failed: failed,
        evidence: evidence,
        source: run.source,
        evidenceRef: run.evidenceRef,
      );
    }

    for (final run in effective.regressionRuns) {
      final failed = <String>{};
      final evidence = <String>{};
      _certifyRegression(run, failed, evidence);
      final identity = run.connectorId.trim();
      final runId = run.runId.trim();
      if (identity.isEmpty || runId.isEmpty) {
        invalid.add('record_id:regression');
        continue;
      }
      for (final _ in failed) {
        invalid.add('regression:$identity:$runId');
      }
      for (final suite in evidence) {
        if (!covered.contains(suite)) covered.add(suite);
      }
      if (run.skipped > 0 && run.skipReason.trim().isEmpty) {
        // A skipped test with no reason is a hole dressed as a green run.
        invalid.add('regression_skip:$identity:$runId');
      }
      if (!Sprint116ConnectorMatrixContract.supportedSources.contains(
        run.source.trim(),
      )) {
        invalid.add('no_mock_values:$identity');
      } else if (Sprint116ConnectorMatrixContract.evidencedSources.contains(
            run.source.trim(),
          ) &&
          (run.evidenceRef == null || run.evidenceRef!.trim().isEmpty)) {
        invalid.add('no_mock_values:$identity');
      }
    }

    invalid.addAll(_crossRecordJoins(effective, effectiveAsOf, covered));

    if (requireCoverage) {
      for (final suite in Sprint116ConnectorMatrixContract.requiredSuites) {
        if (!covered.contains(suite)) {
          invalid.add('area_coverage:$suite');
        }
      }
    }

    covered.sort();
    final unaudited = _unauditedConnectors(effective, invalid);
    unaudited.sort();
    return Sprint116ConnectorMatrixReport(
      state: invalid.isEmpty
          ? Sprint116ConnectorMatrixStatus.pass
          : Sprint116ConnectorMatrixStatus.fail,
      invalidRecords: invalid.toList(growable: false),
      coveredSuites: covered,
      unauditedConnectors: unaudited,
    );
  }

  void _certifyManifest(
    Sprint116ConnectorManifestRecord record,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (record.providerId.trim().isEmpty ||
        record.connectorVersion.trim().isEmpty) {
      failed.add('manifest');
    }
    if (!Sprint116ConnectorMatrixContract.knownAuthTypes.contains(
      record.authType.trim(),
    )) {
      failed.add('manifest');
    }
    if (record.declaredCapabilities.isEmpty) {
      // A connector that declares no capability is a name, not a contract.
      failed.add('manifest');
    }
    for (final capability in record.declaredCapabilities) {
      if (!Sprint116ConnectorMatrixContract.knownCapabilities.contains(
        capability.trim(),
      )) {
        failed.add('manifest');
      }
    }
    if (record.requestedPermissions.isEmpty) {
      failed.add('manifest');
    }
    final availability = record.availability.trim();
    if (availability.isEmpty) {
      failed.add('manifest');
    }
    if (availability.toUpperCase() != 'UNVERIFIED' &&
        (record.source.trim() != 'live' ||
            record.evidenceRef == null ||
            record.evidenceRef!.trim().isEmpty)) {
      // Availability is a live fact. A local fixture cannot promote a
      // connector to AVAILABLE, no matter how complete the row looks.
      failed.add('manifest');
    }
    if (failed.isEmpty) evidence.add('manifest');
  }

  void _certifyConnect(
    Sprint116ConnectRun run,
    String? manifestAuthType,
    Set<String> failed,
    Set<String> evidence,
  ) {
    final authType = manifestAuthType ?? '';
    final usesPkce =
        authType.isEmpty ||
        Sprint116ConnectorMatrixContract.pkceAuthTypes.contains(authType);
    if (usesPkce) {
      if (run.pkceMethod.trim().toUpperCase() != 'S256') {
        // plain is a downgrade, not a hardening.
        failed.add('auth');
      }
      if (run.stateParameter.trim().isEmpty) {
        // No state parameter means the callback cannot be tied to the request.
        failed.add('auth');
      }
    }
    if (run.requestedScopes.isEmpty || run.grantedScopes.isEmpty) {
      failed.add('auth');
    }
    final granted = run.grantedScopes.map((scope) => scope.trim()).toSet();
    final requested = run.requestedScopes.map((scope) => scope.trim()).toSet();
    if (!granted.every(requested.contains)) {
      // A grant the app never asked for is a consent defect, not a bonus.
      failed.add('auth');
    }
    if (!requested.every(granted.contains)) {
      // A short grant silently accepted turns a refused scope into a broken
      // feature discovered at runtime.
      if (!run.partialGrantAccepted) {
        failed.add('auth');
      }
    }
    if (run.tokenSha256.trim().isEmpty) {
      failed.add('auth');
    }
    if (!run.secretRedactedInLogs) {
      failed.add('auth');
    }
    if (failed.isEmpty) evidence.add('auth');
  }

  void _certifyCapability(
    Sprint116CapabilityRun run,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (run.exercisedCapabilities.isEmpty) {
      failed.add('capability');
    }
    for (final capability in run.exercisedCapabilities) {
      if (!Sprint116ConnectorMatrixContract.knownCapabilities.contains(
        capability.trim(),
      )) {
        failed.add('capability');
      }
    }
    if (!run.callSucceeded) {
      // A failed probe that was never classified is a known state misfiled
      // as an unknown one.
      if (!run.failureClassified) {
        failed.add('capability');
      }
    }
    if (run.leavesDevice && !run.dataEgressEncrypted) {
      // Anything that leaves the device in the clear is a transport defect.
      failed.add('capability');
    }
    if (failed.isEmpty) evidence.add('capability');
  }

  void _certifyUsage(
    Sprint116UsageRun run,
    int asOfEpochMs,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (!Sprint116ConnectorMatrixContract.knownUsageUnits.contains(
      run.unit.trim(),
    )) {
      failed.add('usage');
    }
    if (run.meter.trim().isEmpty) {
      // A figure with no meter behind it is a number somebody typed.
      failed.add('usage');
    }
    if (run.rawValue.isNaN || run.rawValue.isNegative) {
      failed.add('usage');
    }
    if (!run.valueAvailable) {
      // Unknown usage reported as zero is worse than no usage at all.
      failed.add('usage');
    }
    if (run.attributedCapability.trim().isEmpty) {
      failed.add('usage');
    }
    if (run.freshnessTtlSeconds <= 0) {
      failed.add('usage');
    }
    if (run.observedAtEpochMs <= 0) {
      failed.add('usage');
    } else if (run.observedAtEpochMs > asOfEpochMs) {
      // A reading from the future is a fabrication, not a measurement.
      failed.add('usage');
    }
    if (failed.isEmpty) evidence.add('usage');
  }

  void _certifyError(
    Sprint116ErrorRun run,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (!Sprint116ConnectorMatrixContract.knownErrorStates.contains(
      run.errorState.trim(),
    )) {
      failed.add('error');
    }
    if (run.httpStatus < 400 || run.httpStatus > 599) {
      failed.add('error');
    }
    if (!run.failureSurfaced) {
      // Swallowed failures are invisible to the author until the bill arrives.
      failed.add('error');
    }
    if (run.userMessage.trim().isEmpty) {
      failed.add('error');
    }
    if (run.recoveryVerifiedAtEpochMs <= 0 ||
        run.recoveryVerifiedAtEpochMs < run.atEpochMs) {
      // "It recovers" without a verified recovery is a hope, not a test.
      failed.add('error');
    }
    if (failed.isEmpty) evidence.add('error');
  }

  void _certifyReauth(
    Sprint116ReauthRun run,
    Set<String> failed,
    Set<String> evidence,
  ) {
    final prior = run.priorTokenSha256.trim();
    final refreshed = run.refreshedTokenSha256.trim();
    if (prior.isEmpty || refreshed.isEmpty) {
      failed.add('reauth');
    }
    final strategy = run.strategy.trim();
    if (strategy != 'not_applicable' &&
        prior.isNotEmpty &&
        prior == refreshed) {
      // Returning the same credential is not a refresh; it is a no-op that
      // leaves the old expiry in place. When no strategy applies the
      // credential is supposed to be untouched, so the join checks that half.
      failed.add('reauth');
    }
    if (!run.priorTokenInvalidated) {
      // The old token staying usable after a refresh is the usual way one
      // leaked credential becomes two.
      failed.add('reauth');
    }
    if (!Sprint116ConnectorMatrixContract.knownReauthStrategies.contains(
      strategy,
    )) {
      failed.add('reauth');
    }
    if (strategy != 'not_applicable') {
      final headroomMs =
          run.refreshedTokenExpiresEpochMs - run.refreshedAtEpochMs;
      if (headroomMs <= 0 ||
          headroomMs <
              Sprint116ConnectorMatrixContract.minimumRefreshHeadroomMs) {
        failed.add('reauth');
      }
      if (!run.sessionValidAfterReauth) {
        failed.add('reauth');
      }
    }
    if (failed.isEmpty) evidence.add('reauth');
  }

  void _certifyDisconnect(
    Sprint116DisconnectRun run,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (!Sprint116ConnectorMatrixContract.knownPreDisconnectStates.contains(
      run.stateBeforeDisconnect.trim(),
    )) {
      // Unlinking something that was never linked, or was already unlinked,
      // proves nothing about the unlink path.
      failed.add('disconnect');
    }
    if (!run.disconnectRequested) {
      failed.add('disconnect');
    }
    if (!run.callsAfterDisconnectRejected) {
      // A connector that still answers after unlink keeps sending the
      // author's data to a vendor they just left.
      failed.add('disconnect');
    }
    if (run.newTokensIssuedAfterDisconnect) {
      failed.add('disconnect');
    }
    if (failed.isEmpty) evidence.add('disconnect');
  }

  void _certifyCleanup(
    Sprint116CleanupRun run,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (!run.tokenRemoved || !run.cacheRemoved || !run.vaultEntryRemoved) {
      failed.add('cleanup');
    }
    if (run.postCleanupProbeAuthorized) {
      // The only proof of cleanup is that the old credential stops working.
      failed.add('cleanup');
    }
    if (run.localProjectDataDeleted) {
      // Unlinking a provider never entitles the app to delete the manuscript.
      failed.add('cleanup');
    }
    if (!run.auditRetained) {
      // Deleting the trail along with the token destroys the security gate.
      failed.add('cleanup');
    }
    if (failed.isEmpty) evidence.add('cleanup');
  }

  void _certifyRegression(
    Sprint116RegressionRun run,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (run.exitCode != 0) {
      failed.add('regression');
    }
    if (run.passed <= 0 || run.total <= 0 || run.passed > run.total) {
      // A regression run that exercised nothing cannot vouch for anything.
      failed.add('regression');
    }
    if (run.command.trim().isEmpty || run.headSha.trim().length < 7) {
      failed.add('regression');
    }
    if (run.coveredSuites.isEmpty) {
      failed.add('regression');
    }
    if (failed.isEmpty) evidence.add('regression');
  }

  /// Every connector the manifest proposes owes all nine suites, and every
  /// suite that ran has to belong to a connector somebody proposed.
  List<String> _crossRecordJoins(
    Sprint116ConnectorControlSet set,
    int asOfEpochMs,
    List<String> covered,
  ) {
    final invalid = <String>[];

    final byConnector = <String, Map<String, int>>{};
    void mark(String connectorId, String suite) {
      final id = connectorId.trim();
      if (id.isEmpty) return;
      (byConnector[id] ??= <String, int>{})[suite] =
          (byConnector[id]![suite] ?? 0) + 1;
    }

    for (final record in set.manifests) {
      if (record.proposed) mark(record.connectorId, 'manifest');
    }
    for (final run in set.connectRuns) {
      mark(run.connectorId, 'auth');
    }
    for (final run in set.capabilityRuns) {
      mark(run.connectorId, 'capability');
    }
    for (final run in set.usageRuns) {
      mark(run.connectorId, 'usage');
    }
    for (final run in set.errorRuns) {
      mark(run.connectorId, 'error');
    }
    for (final run in set.reauthRuns) {
      mark(run.connectorId, 'reauth');
    }
    for (final run in set.disconnectRuns) {
      mark(run.connectorId, 'disconnect');
    }
    for (final run in set.cleanupRuns) {
      mark(run.connectorId, 'cleanup');
    }
    for (final run in set.regressionRuns) {
      mark(run.connectorId, 'regression');
    }

    for (final entry in byConnector.entries) {
      for (final suite in Sprint116ConnectorMatrixContract.requiredSuites) {
        if (!entry.value.containsKey(suite)) {
          invalid.add('suite_coverage:${entry.key}');
        }
      }
    }

    // A run against a connector the manifest never proposed is a phantom: it
    // cannot be certified because nothing declares what it is allowed to do.
    final proposed = <String>{
      for (final record in set.manifests)
        if (record.proposed) record.connectorId.trim(),
    }..removeWhere((id) => id.isEmpty);
    for (final entry in byConnector.entries) {
      if (!proposed.contains(entry.key)) {
        invalid.add('manifest_agreement:${entry.key}');
      }
    }

    // Capability nobody declared: the matrix can pass while a run exercises a
    // surface the manifest never authorised, which makes the manifest a lie
    // rather than a contract.
    for (final run in set.capabilityRuns) {
      final id = run.connectorId.trim();
      if (id.isEmpty) continue;
      final declared = <String>{
        for (final record in set.manifests)
          if (record.connectorId.trim() == id)
            for (final capability in record.declaredCapabilities)
              capability.trim(),
      };
      if (declared.isEmpty) continue;
      for (final capability in run.exercisedCapabilities) {
        final trimmed = capability.trim();
        if (trimmed.isNotEmpty && !declared.contains(trimmed)) {
          invalid.add('capability_undeclared:$id:$trimmed');
        }
      }
    }

    // Declared capability nobody probed: the manifest can advertise a surface
    // that no run ever touched, and the matrix would still be green.
    for (final record in set.manifests) {
      final id = record.connectorId.trim();
      if (id.isEmpty) continue;
      final exercised = <String>{
        for (final run in set.capabilityRuns)
          if (run.connectorId.trim() == id)
            for (final capability in run.exercisedCapabilities)
              capability.trim(),
      };
      for (final declared in record.declaredCapabilities) {
        final capability = declared.trim();
        if (capability.isNotEmpty && !exercised.contains(capability)) {
          invalid.add('capability_unexercised:$id:$capability');
        }
      }
    }

    // Auth type decides whether a refresh is even possible, and a run cannot
    // say "no strategy applies" while handing back a different credential
    // than the one it started with. Both halves of that row cannot be true.
    for (final record in set.manifests) {
      final id = record.connectorId.trim();
      if (id.isEmpty) continue;
      if (Sprint116ConnectorMatrixContract.renewableAuthTypes.contains(
        record.authType.trim(),
      )) {
        continue;
      }
      for (final run in set.reauthRuns) {
        if (run.connectorId.trim() != id) continue;
        final strategy = run.strategy.trim();
        if (strategy != 'not_applicable') {
          invalid.add('reauth:$id');
          continue;
        }
        final prior = run.priorTokenSha256.trim();
        final refreshed = run.refreshedTokenSha256.trim();
        if (prior.isNotEmpty && prior != refreshed) {
          invalid.add('reauth:$id');
        }
      }
    }

    // Lifecycle ordering: a matrix that disconnects before it connected, or
    // cleans up before it disconnected, describes a run that never happened.
    for (final id in byConnector.keys) {
      final connectedAt = _connectEpochMs(set, id);
      final disconnectedAt = _disconnectEpochMs(set, id);
      final cleanedAt = _cleanupEpochMs(set, id);
      final refreshedAt = _reauthEpochMs(set, id);
      if (connectedAt == null) continue;
      if (disconnectedAt != null && disconnectedAt < connectedAt) {
        invalid.add('lifecycle_ordering:$id');
      }
      if (cleanedAt != null) {
        // Cleanup without a preceding disconnect means the unlink path was
        // never exercised before the vault was wiped.
        if (disconnectedAt == null || cleanedAt < disconnectedAt) {
          invalid.add('lifecycle_ordering:$id');
        }
      }
      if (refreshedAt != null && refreshedAt < connectedAt) {
        invalid.add('lifecycle_ordering:$id');
      }
    }

    // Credential residue: cleanup claims removal, so any later run reporting a
    // valid session contradicts it. Both rows look healthy on their own.
    for (final id in byConnector.keys) {
      final disconnectedAt = _disconnectEpochMs(set, id);
      final cleanedAt = _cleanupEpochMs(set, id);
      if (disconnectedAt == null && cleanedAt == null) continue;
      final revokedFrom = <int>[
        if (disconnectedAt != null) disconnectedAt,
        if (cleanedAt != null) cleanedAt,
      ].reduce((a, b) => a < b ? a : b);

      for (final run in set.usageRuns) {
        if (run.connectorId.trim() != id || !run.sessionValid) continue;
        if (run.observedAtEpochMs > revokedFrom) {
          invalid.add('credential_residue:$id');
        }
      }
      for (final run in set.capabilityRuns) {
        if (run.connectorId.trim() != id || !run.sessionValid) continue;
        if (run.atEpochMs > revokedFrom) {
          invalid.add('credential_residue:$id');
        }
      }
    }

    // A regression run only vouches for the suites it actually exercised.
    for (final run in set.regressionRuns) {
      final id = run.connectorId.trim();
      if (id.isEmpty) continue;
      for (final suite in Sprint116ConnectorMatrixContract.requiredSuites) {
        if (!run.coveredSuites.contains(suite)) {
          invalid.add('regression_suite_coverage:$suite');
        }
      }
    }

    // Every declared suite needs at least one clean record, not merely a file
    // that exists.
    for (final suite in Sprint116ConnectorMatrixContract.requiredSuites) {
      if (!covered.contains(suite)) {
        invalid.add('suite_evidence:$suite');
      }
    }

    return invalid;
  }

  int? _connectEpochMs(Sprint116ConnectorControlSet set, String id) {
    for (final run in set.connectRuns) {
      if (run.connectorId.trim() == id) return run.connectedAtEpochMs;
    }
    return null;
  }

  int? _disconnectEpochMs(Sprint116ConnectorControlSet set, String id) {
    for (final run in set.disconnectRuns) {
      if (run.connectorId.trim() == id) return run.disconnectedAtEpochMs;
    }
    return null;
  }

  int? _cleanupEpochMs(Sprint116ConnectorControlSet set, String id) {
    for (final run in set.cleanupRuns) {
      if (run.connectorId.trim() == id) return run.cleanedAtEpochMs;
    }
    return null;
  }

  int? _reauthEpochMs(Sprint116ConnectorControlSet set, String id) {
    for (final run in set.reauthRuns) {
      if (run.connectorId.trim() == id) return run.refreshedAtEpochMs;
    }
    return null;
  }

  List<String> _unauditedConnectors(
    Sprint116ConnectorControlSet set,
    List<String> invalid,
  ) {
    final proposed = <String>{
      for (final record in set.manifests)
        if (record.proposed) record.connectorId.trim(),
    }..removeWhere((id) => id.isEmpty);
    return proposed
        .where((id) => invalid.contains('suite_coverage:$id'))
        .toList(growable: false);
  }

  bool _staleAt(int? atEpochMs, int asOfEpochMs, int maxAgeMs) {
    if (atEpochMs == null) return false;
    if (atEpochMs <= 0) return true;
    if (atEpochMs > asOfEpochMs) return true;
    return asOfEpochMs - atEpochMs > maxAgeMs;
  }

  Sprint116ConnectorMatrixReport _blocked(String reason) {
    return Sprint116ConnectorMatrixReport(
      state: Sprint116ConnectorMatrixStatus.blocked,
      invalidRecords: <String>[reason],
      coveredSuites: const <String>[],
      unauditedConnectors: const <String>[],
    );
  }

  Map<String, dynamic>? _readManifest() {
    final file = File(Sprint116ConnectorMatrixContract.manifestPath);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  int? _manifestAsOf(Map<String, dynamic>? manifest) {
    final raw = manifest?['as_of_epoch_ms'];
    return raw is num ? raw.toInt() : null;
  }

  Sprint116ConnectorControlSet _controlsFromManifest(
    Map<String, dynamic>? manifest,
  ) {
    return Sprint116ConnectorControlSet(
      manifests: _mapList(manifest, 'manifests', _manifestFromManifest),
      connectRuns: _mapList(manifest, 'connect_runs', _connectFromManifest),
      capabilityRuns: _mapList(manifest, 'capability_runs', _capabilityFrom),
      usageRuns: _mapList(manifest, 'usage_runs', _usageFrom),
      errorRuns: _mapList(manifest, 'error_runs', _errorFrom),
      reauthRuns: _mapList(manifest, 'reauth_runs', _reauthFrom),
      disconnectRuns: _mapList(manifest, 'disconnect_runs', _disconnectFrom),
      cleanupRuns: _mapList(manifest, 'cleanup_runs', _cleanupFrom),
      regressionRuns: _mapList(manifest, 'regression_runs', _regressionFrom),
    );
  }

  List<T> _mapList<T>(
    Map<String, dynamic>? manifest,
    String key,
    T Function(Map<Object?, Object?> item) build,
  ) {
    if (manifest == null) return <T>[];
    final raw = manifest[key];
    if (raw is! List) return <T>[];
    return raw.whereType<Map>().map(build).toList(growable: false);
  }

  List<String> _stringList(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw.whereType<String>().toList(growable: false);
  }

  String _string(Object? raw) => raw is String ? raw : '';

  int _int(Object? raw) => (raw as num?)?.toInt() ?? 0;

  num _num(Object? raw) => (raw as num?) ?? 0;

  bool _bool(Object? raw) => raw == true;

  Sprint116ConnectorManifestRecord _manifestFromManifest(
    Map<Object?, Object?> item,
  ) {
    return Sprint116ConnectorManifestRecord(
      connectorId: _string(item['connector_id']),
      providerId: _string(item['provider_id']),
      connectorVersion: _string(item['connector_version']),
      authType: _string(item['auth_type']),
      declaredCapabilities: _stringList(item['declared_capabilities']),
      requestedPermissions: _stringList(item['requested_permissions']),
      availability: _string(item['availability']),
      proposed: _bool(item['proposed']),
      source: _string(item['source']),
      evidenceRef: item['evidence_ref'] is String
          ? item['evidence_ref'] as String
          : null,
    );
  }

  Sprint116ConnectRun _connectFromManifest(Map<Object?, Object?> item) {
    return Sprint116ConnectRun(
      connectorId: _string(item['connector_id']),
      pkceMethod: _string(item['pkce_method']),
      stateParameter: _string(item['state_parameter']),
      requestedScopes: _stringList(item['requested_scopes']),
      grantedScopes: _stringList(item['granted_scopes']),
      partialGrantAccepted: _bool(item['partial_grant_accepted']),
      tokenSha256: _string(item['token_sha256']),
      secretRedactedInLogs: _bool(item['secret_redacted_in_logs']),
      connectedAtEpochMs: _int(item['connected_at_epoch_ms']),
      atEpochMs: _int(item['at_epoch_ms']),
      source: _string(item['source']),
      evidenceRef: item['evidence_ref'] is String
          ? item['evidence_ref'] as String
          : null,
    );
  }

  Sprint116CapabilityRun _capabilityFrom(Map<Object?, Object?> item) {
    return Sprint116CapabilityRun(
      connectorId: _string(item['connector_id']),
      exercisedCapabilities: _stringList(item['exercised_capabilities']),
      callSucceeded: _bool(item['call_succeeded']),
      failureClassified: _bool(item['failure_classified']),
      leavesDevice: _bool(item['leaves_device']),
      dataEgressEncrypted: _bool(item['data_egress_encrypted']),
      sessionValid: _bool(item['session_valid']),
      atEpochMs: _int(item['at_epoch_ms']),
      source: _string(item['source']),
      evidenceRef: item['evidence_ref'] is String
          ? item['evidence_ref'] as String
          : null,
    );
  }

  Sprint116UsageRun _usageFrom(Map<Object?, Object?> item) {
    return Sprint116UsageRun(
      connectorId: _string(item['connector_id']),
      unit: _string(item['unit']),
      meter: _string(item['meter']),
      rawValue: _num(item['raw_value']),
      valueAvailable: _bool(item['value_available']),
      attributedCapability: _string(item['attributed_capability']),
      observedAtEpochMs: _int(item['observed_at_epoch_ms']),
      freshnessTtlSeconds: _int(item['freshness_ttl_seconds']),
      sessionValid: _bool(item['session_valid']),
      source: _string(item['source']),
      evidenceRef: item['evidence_ref'] is String
          ? item['evidence_ref'] as String
          : null,
    );
  }

  Sprint116ErrorRun _errorFrom(Map<Object?, Object?> item) {
    return Sprint116ErrorRun(
      connectorId: _string(item['connector_id']),
      errorState: _string(item['error_state']),
      httpStatus: _int(item['http_status']),
      failureSurfaced: _bool(item['failure_surfaced']),
      userMessage: _string(item['user_message']),
      recoveryVerifiedAtEpochMs: _int(item['recovery_verified_at_epoch_ms']),
      atEpochMs: _int(item['at_epoch_ms']),
      source: _string(item['source']),
      evidenceRef: item['evidence_ref'] is String
          ? item['evidence_ref'] as String
          : null,
    );
  }

  Sprint116ReauthRun _reauthFrom(Map<Object?, Object?> item) {
    return Sprint116ReauthRun(
      connectorId: _string(item['connector_id']),
      strategy: _string(item['strategy']),
      priorTokenSha256: _string(item['prior_token_sha256']),
      refreshedTokenSha256: _string(item['refreshed_token_sha256']),
      priorTokenInvalidated: _bool(item['prior_token_invalidated']),
      refreshedTokenExpiresEpochMs: _int(
        item['refreshed_token_expires_epoch_ms'],
      ),
      refreshedAtEpochMs: _int(item['refreshed_at_epoch_ms']),
      sessionValidAfterReauth: _bool(item['session_valid_after_reauth']),
      source: _string(item['source']),
      evidenceRef: item['evidence_ref'] is String
          ? item['evidence_ref'] as String
          : null,
    );
  }

  Sprint116DisconnectRun _disconnectFrom(Map<Object?, Object?> item) {
    return Sprint116DisconnectRun(
      connectorId: _string(item['connector_id']),
      stateBeforeDisconnect: _string(item['state_before_disconnect']),
      disconnectRequested: _bool(item['disconnect_requested']),
      callsAfterDisconnectRejected: _bool(
        item['calls_after_disconnect_rejected'],
      ),
      newTokensIssuedAfterDisconnect: _bool(
        item['new_tokens_issued_after_disconnect'],
      ),
      disconnectedAtEpochMs: _int(item['disconnected_at_epoch_ms']),
      source: _string(item['source']),
      evidenceRef: item['evidence_ref'] is String
          ? item['evidence_ref'] as String
          : null,
    );
  }

  Sprint116CleanupRun _cleanupFrom(Map<Object?, Object?> item) {
    return Sprint116CleanupRun(
      connectorId: _string(item['connector_id']),
      tokenRemoved: _bool(item['token_removed']),
      cacheRemoved: _bool(item['cache_removed']),
      vaultEntryRemoved: _bool(item['vault_entry_removed']),
      postCleanupProbeAuthorized: _bool(item['post_cleanup_probe_authorized']),
      localProjectDataDeleted: _bool(item['local_project_data_deleted']),
      auditRetained: _bool(item['audit_retained']),
      cleanedAtEpochMs: _int(item['cleaned_at_epoch_ms']),
      source: _string(item['source']),
      evidenceRef: item['evidence_ref'] is String
          ? item['evidence_ref'] as String
          : null,
    );
  }

  Sprint116RegressionRun _regressionFrom(Map<Object?, Object?> item) {
    return Sprint116RegressionRun(
      connectorId: _string(item['connector_id']),
      runId: _string(item['run_id']),
      command: _string(item['command']),
      exitCode: _int(item['exit_code']),
      passed: _int(item['passed']),
      total: _int(item['total']),
      skipped: _int(item['skipped']),
      skipReason: _string(item['skip_reason']),
      coveredSuites: _stringList(item['covered_suites']),
      headSha: _string(item['head_sha']),
      source: _string(item['source']),
      evidenceRef: item['evidence_ref'] is String
          ? item['evidence_ref'] as String
          : null,
    );
  }
}
