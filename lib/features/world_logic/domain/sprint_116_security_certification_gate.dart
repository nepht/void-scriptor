import 'dart:convert';
import 'dart:io';

/// Outcome of the step 116.45 security gate.
enum Sprint116SecurityGateStatus { pass, fail, blocked }

/// One OAuth flow, described the way an attacker would probe it: which client
/// type, whether PKCE and `state` are actually used, and which scopes were
/// requested against which were granted.
class Sprint116OAuthFlow {
  const Sprint116OAuthFlow({
    required this.controlId,
    required this.providerId,
    required this.clientType,
    required this.pkceEnabled,
    required this.codeChallengeMethod,
    required this.stateParameter,
    required this.allowedRedirectUris,
    required this.allowedRedirectHosts,
    required this.redirectUri,
    required this.requestedScopes,
    required this.grantedScopes,
    required this.source,
    this.evidenceRef,
  });

  final String controlId;
  final String providerId;

  /// `public` or `confidential`. Both need PKCE; a confidential client that
  /// can still present a client secret is the case that most often drops it.
  final String clientType;

  final bool pkceEnabled;
  final String codeChallengeMethod;

  /// The anti-CSRF value. An empty string means the flow shipped without one.
  final String stateParameter;

  final List<String> allowedRedirectUris;
  final List<String> allowedRedirectHosts;
  final String redirectUri;
  final List<String> requestedScopes;
  final List<String> grantedScopes;

  final String source;
  final String? evidenceRef;
}

/// One secret at rest, plus every way it could escape without anyone noticing.
class Sprint116VaultEntry {
  const Sprint116VaultEntry({
    required this.vaultId,
    required this.ownerScope,
    required this.secretStoredPlaintext,
    required this.encryptedAtRest,
    required this.keyId,
    required this.keySeparated,
    required this.toStringIncludesSecret,
    required this.toJsonIncludesSecret,
    required this.logRedactionEnabled,
    required this.source,
    this.evidenceRef,
  });

  final String vaultId;
  final String ownerScope;
  final bool secretStoredPlaintext;
  final bool encryptedAtRest;

  /// Which key protected this secret. Every entry sharing one key means one
  /// compromise decrypts all of them.
  final String keyId;

  final bool keySeparated;

  final bool toStringIncludesSecret;
  final bool toJsonIncludesSecret;
  final bool logRedactionEnabled;

  final String source;
  final String? evidenceRef;
}

/// One redirect target after the chain has been followed.
class Sprint116RedirectCheck {
  const Sprint116RedirectCheck({
    required this.redirectId,
    required this.finalUrl,
    required this.allowedHosts,
    required this.requireHttps,
    required this.resolvedAfterRedirects,
    required this.source,
    this.evidenceRef,
  });

  final String redirectId;

  /// Where the browser actually lands, not where it was asked to land.
  final String finalUrl;

  final List<String> allowedHosts;
  final bool requireHttps;

  /// False when the chain was not followed, so the destination is unproven.
  final bool resolvedAfterRedirects;

  final String source;
  final String? evidenceRef;
}

/// One live session and the guarantees it is supposed to carry.
class Sprint116SessionCheck {
  const Sprint116SessionCheck({
    required this.sessionId,
    required this.subjectId,
    required this.issuedAtEpochMs,
    required this.expiresAtEpochMs,
    required this.absoluteMaxLifetimeMs,
    required this.lastSeenAtEpochMs,
    required this.idleTimeoutMs,
    required this.tokenInQueryString,
    required this.rotatedOnLogin,
    required this.invalidatedOnLogout,
    required this.stillActive,
    required this.source,
    this.evidenceRef,
  });

  final String sessionId;
  final String subjectId;
  final int issuedAtEpochMs;
  final int expiresAtEpochMs;

  /// The ceiling the product committed to; a session that outlives it has
  /// silently abandoned the commitment.
  final int absoluteMaxLifetimeMs;

  final int lastSeenAtEpochMs;
  final int idleTimeoutMs;

  /// Session tokens end up in browser history, referrers, and access logs
  /// when they ride in a query string.
  final bool tokenInQueryString;

  final bool rotatedOnLogin;
  final bool invalidatedOnLogout;
  final bool stillActive;

  final String source;
  final String? evidenceRef;
}

/// One permission grant, compared against what the resource actually declares.
class Sprint116PermissionGrant {
  const Sprint116PermissionGrant({
    required this.grantId,
    required this.subjectId,
    required this.resourceId,
    required this.declaredPermissions,
    required this.requestedPermissions,
    required this.grantedPermissions,
    required this.defaultDecision,
    required this.escalationOnRefresh,
    required this.source,
    this.evidenceRef,
  });

  final String grantId;
  final String subjectId;
  final String resourceId;

  /// What the resource is able to authorize, not what this subject may.
  final List<String> declaredPermissions;

  final List<String> requestedPermissions;
  final List<String> grantedPermissions;

  /// `deny` or `allow`. Anything unknown is treated as a defect, because a
  /// fail-open default is a defect that only announces itself under attack.
  final String defaultDecision;

  final bool escalationOnRefresh;

  final String source;
  final String? evidenceRef;
}

/// One inbound webhook endpoint and the order in which it trusted the payload.
class Sprint116WebhookEndpoint {
  const Sprint116WebhookEndpoint({
    required this.webhookId,
    required this.providerId,
    required this.signatureVerifiedBeforeProcessing,
    required this.constantTimeCompare,
    required this.replayWindowSeconds,
    required this.eventTimestampEpochMs,
    required this.processingEpochMs,
    required this.duplicateDeliveryDetected,
    required this.duplicateDeliveryRejected,
    required this.source,
    this.evidenceRef,
  });

  final String webhookId;
  final String providerId;

  /// Verification has to happen before any effect, not after.
  final bool signatureVerifiedBeforeProcessing;

  final bool constantTimeCompare;
  final int replayWindowSeconds;
  final int eventTimestampEpochMs;
  final int processingEpochMs;

  final bool duplicateDeliveryDetected;

  /// False while a duplicate was actually observed means the guard is
  /// unproven rather than working.
  final bool duplicateDeliveryRejected;

  final String source;
  final String? evidenceRef;
}

/// One resolved dependency, pinned to a lockfile and checked for advisories.
class Sprint116Dependency {
  const Sprint116Dependency({
    required this.dependencyId,
    required this.package,
    required this.versionConstraint,
    required this.license,
    required this.vulnerabilityStatus,
    required this.pinnedToLockfile,
    required this.devOnly,
    required this.referencedFromProductionCode,
    required this.source,
    this.evidenceRef,
  });

  final String dependencyId;
  final String package;
  final String versionConstraint;
  final String license;

  /// `clean`, `mitigated`, `remediated`, or a finding. `unknown` is not a
  /// clean bill of health and must never certify.
  final String vulnerabilityStatus;

  final bool pinnedToLockfile;
  final bool devOnly;
  final bool referencedFromProductionCode;

  final String source;
  final String? evidenceRef;
}

/// One audit record and the two ways an audit trail stops being evidence.
class Sprint116AuditEntry {
  const Sprint116AuditEntry({
    required this.entryId,
    required this.actorId,
    required this.action,
    required this.targetId,
    required this.occurredAtEpochMs,
    required this.mutatedAfterWrite,
    required this.payloadContainsSecret,
    required this.source,
    this.evidenceRef,
  });

  final String entryId;

  /// Empty means the record cannot be attributed to anyone.
  final String actorId;

  final String action;
  final String targetId;
  final int occurredAtEpochMs;

  /// A trail that can be rewritten proves nothing.
  final bool mutatedAfterWrite;

  final bool payloadContainsSecret;

  final String source;
  final String? evidenceRef;
}

/// The complete control set the gate certifies.
class Sprint116SecurityControlSet {
  Sprint116SecurityControlSet({
    required this.oauthFlows,
    required this.vaultEntries,
    required this.redirects,
    required this.sessions,
    required this.permissions,
    required this.webhooks,
    required this.dependencies,
    required this.auditEntries,
  });

  List<Sprint116OAuthFlow> oauthFlows;
  List<Sprint116VaultEntry> vaultEntries;
  List<Sprint116RedirectCheck> redirects;
  List<Sprint116SessionCheck> sessions;
  List<Sprint116PermissionGrant> permissions;
  List<Sprint116WebhookEndpoint> webhooks;
  List<Sprint116Dependency> dependencies;
  List<Sprint116AuditEntry> auditEntries;
}

class Sprint116SecurityReport {
  Sprint116SecurityReport({
    required this.state,
    required this.invalidRecords,
    required this.coveredAreas,
    required this.unloggedSecurityActions,
  });

  final Sprint116SecurityGateStatus state;
  final List<String> invalidRecords;
  final List<String> coveredAreas;

  /// Security-relevant actions the trail never recorded.
  final List<String> unloggedSecurityActions;

  String get externalGates => Sprint116SecurityContract.externalGates;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'canonical_step': Sprint116SecurityContract.canonicalStep,
      'state': state.name,
      'invalid_records': invalidRecords,
      'covered_areas': coveredAreas,
      'unlogged_security_actions': unloggedSecurityActions,
      'live_security_verification': false,
      'external_gates': externalGates,
    };
  }
}

abstract final class Sprint116SecurityContract {
  static const String canonicalStep = '116.45';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_security_certification_gate.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The eight evidence areas canonical step 116.45 requires.
  static const List<String> requiredAreas = <String>[
    'oauth_tests',
    'vault_tests',
    'redirect_tests',
    'session_tests',
    'permission_tests',
    'webhook_tests',
    'dependency_scan',
    'audit_tests',
  ];

  static const List<String> supportedSources = <String>[
    'synthetic_local',
    'live',
  ];

  /// The only vulnerability verdicts that count as a pass. `unknown` is
  /// deliberately absent: an unanswered scan question is not a clean result.
  static const List<String> cleanVulnerabilityStatuses = <String>[
    'clean',
    'mitigated',
    'remediated',
  ];

  /// Licenses that cannot ship inside a proprietary desktop application.
  static const List<String> blockedLicenses = <String>[
    'AGPL-3.0-only',
    'GPL-3.0-only',
    'SSPL-1.0',
  ];

  /// Actions that must leave an audit trace. A trail full of cosmetic events
  /// while token revocation goes unlogged is the gap this list exists to
  /// catch.
  static const List<String> securityRelevantActions = <String>[
    'token_revoke',
    'vault_write',
    'session_invalidate',
    'permission_revoke',
    'oauth_link',
    'oauth_unlink',
  ];

  static const List<String> clientTypes = <String>['public', 'confidential'];

  static const List<String> codeChallengeMethods = <String>['S256'];

  /// The only acceptable default when a permission is not explicitly granted.
  /// `allow` is a real decision the runtime can make, but as a *default* it is
  /// least-privilege inverted, so it cannot certify.
  static const String leastPrivilegeDefault = 'deny';

  /// The audit actions a populated control set obliges the trail to contain.
  ///
  /// Derived from the controls actually present rather than demanded
  /// unconditionally: a deployment with no OAuth connector has no `oauth_link`
  /// to log, and demanding one would make the gate unfalsifiable.
  static List<String> requiredAuditActions(
    Sprint116SecurityControlSet controls,
  ) {
    return <String>[
      if (controls.vaultEntries.isNotEmpty) 'token_revoke',
      if (controls.vaultEntries.isNotEmpty) 'vault_write',
      if (controls.sessions.isNotEmpty) 'session_invalidate',
      if (controls.permissions.isNotEmpty) 'permission_revoke',
      if (controls.oauthFlows.isNotEmpty) 'oauth_link',
    ];
  }

  /// Host match, not string match. A prefix check would let
  /// `app.voidscriptor.dev.evil.example` inherit an allow-listed host, which
  /// is the oldest open-redirect trick there is.
  static bool isRedirectUriAllowed(String uri, List<String> allowedHosts) {
    final trimmed = uri.trim();
    if (trimmed.isEmpty) return false;

    final Uri? parsed = Uri.tryParse(trimmed);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      // Scheme-relative targets (`//evil.example`) are resolved by the
      // browser, not by us, so an unresolved URL is never allowed.
      return false;
    }
    if (parsed.scheme != 'https') return false;
    // `https://user:pass@host` renders our host next to attacker-chosen
    // credentials, which is a phishing primitive rather than a redirect.
    if (parsed.userInfo.isNotEmpty) return false;

    final host = parsed.host.toLowerCase();
    return allowedHosts
        .map((allowed) => allowed.trim().toLowerCase())
        .where((allowed) => allowed.isNotEmpty)
        .any((allowed) => host == allowed);
  }
}

class Sprint116SecurityCertificationGate {
  /// Certifies the eight security areas of step 116.45.
  ///
  /// Manifest fixtures are consulted only when [controls] is omitted, so an
  /// explicit control set can never borrow fixture data to pass.
  Sprint116SecurityReport certify({
    Sprint116SecurityControlSet? controls,
    int? asOfEpochMs,
    bool requireCoverage = false,
  }) {
    // Borrowed only when the caller supplies nothing, so an explicit set can
    // never pass on fixture values it did not send.
    final usedManifest = controls == null;
    final manifest = _readManifest();
    final effective = controls ?? _controlsFromManifest(manifest);
    final effectiveAsOf =
        asOfEpochMs ?? (usedManifest ? _manifestAsOf(manifest) : null);

    if (effectiveAsOf == null || effectiveAsOf <= 0) {
      return _blocked('as_of_epoch_ms');
    }

    final emptySet = <String>[
      if (effective.oauthFlows.isEmpty) 'oauth_tests',
      if (effective.vaultEntries.isEmpty) 'vault_tests',
      if (effective.redirects.isEmpty) 'redirect_tests',
      if (effective.sessions.isEmpty) 'session_tests',
      if (effective.permissions.isEmpty) 'permission_tests',
      if (effective.webhooks.isEmpty) 'webhook_tests',
      if (effective.dependencies.isEmpty) 'dependency_scan',
      if (effective.auditEntries.isEmpty) 'audit_tests',
    ];
    if (emptySet.isNotEmpty) {
      // Absent controls are not passing controls; an unrun area is a gap.
      return _blocked(emptySet.first);
    }

    final invalid = <String>[];
    final covered = <String>[];
    final loggedActions = <String>{};

    void collect({
      required String group,
      required int index,
      required String identity,
      required Set<String> failed,
      required Set<String> evidence,
      required String source,
      String? evidenceRef,
    }) {
      if (identity.isEmpty) {
        // Without an identity the record cannot be attributed, so it is
        // rejected on identity alone rather than by guessing a key.
        invalid.add('record_id:$group:$index');
        return;
      }
      for (final area in failed) {
        invalid.add('$area:$identity');
      }
      for (final area in evidence) {
        if (!covered.contains(area)) covered.add(area);
      }
      if (!Sprint116SecurityContract.supportedSources.contains(source) ||
          (source == 'live' &&
              (evidenceRef == null || evidenceRef.trim().isEmpty))) {
        invalid.add('no_mock_values:$identity');
      }
    }

    for (var index = 0; index < effective.oauthFlows.length; index++) {
      final flow = effective.oauthFlows[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyOAuth(flow, failed, evidence);
      collect(
        group: 'oauth',
        index: index,
        identity: flow.controlId.trim(),
        failed: failed,
        evidence: evidence,
        source: flow.source.trim(),
        evidenceRef: flow.evidenceRef,
      );
    }

    for (var index = 0; index < effective.vaultEntries.length; index++) {
      final entry = effective.vaultEntries[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyVault(entry, failed, evidence);
      collect(
        group: 'vault',
        index: index,
        identity: entry.vaultId.trim(),
        failed: failed,
        evidence: evidence,
        source: entry.source.trim(),
        evidenceRef: entry.evidenceRef,
      );
    }

    for (var index = 0; index < effective.redirects.length; index++) {
      final redirect = effective.redirects[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyRedirect(redirect, failed, evidence);
      collect(
        group: 'redirect',
        index: index,
        identity: redirect.redirectId.trim(),
        failed: failed,
        evidence: evidence,
        source: redirect.source.trim(),
        evidenceRef: redirect.evidenceRef,
      );
    }

    for (var index = 0; index < effective.sessions.length; index++) {
      final session = effective.sessions[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifySession(session, effectiveAsOf, failed, evidence);
      collect(
        group: 'session',
        index: index,
        identity: session.sessionId.trim(),
        failed: failed,
        evidence: evidence,
        source: session.source.trim(),
        evidenceRef: session.evidenceRef,
      );
    }

    for (var index = 0; index < effective.permissions.length; index++) {
      final grant = effective.permissions[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyPermission(grant, failed, evidence);
      collect(
        group: 'permission',
        index: index,
        identity: grant.grantId.trim(),
        failed: failed,
        evidence: evidence,
        source: grant.source.trim(),
        evidenceRef: grant.evidenceRef,
      );
    }

    for (var index = 0; index < effective.webhooks.length; index++) {
      final hook = effective.webhooks[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyWebhook(hook, effectiveAsOf, failed, evidence);
      collect(
        group: 'webhook',
        index: index,
        identity: hook.webhookId.trim(),
        failed: failed,
        evidence: evidence,
        source: hook.source.trim(),
        evidenceRef: hook.evidenceRef,
      );
    }

    for (var index = 0; index < effective.dependencies.length; index++) {
      final dependency = effective.dependencies[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyDependency(dependency, failed, evidence);
      collect(
        group: 'dependency',
        index: index,
        identity: dependency.dependencyId.trim(),
        failed: failed,
        evidence: evidence,
        source: dependency.source.trim(),
        evidenceRef: dependency.evidenceRef,
      );
    }

    for (var index = 0; index < effective.auditEntries.length; index++) {
      final entry = effective.auditEntries[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyAudit(entry, failed, evidence);
      collect(
        group: 'audit',
        index: index,
        identity: entry.entryId.trim(),
        failed: failed,
        evidence: evidence,
        source: entry.source.trim(),
        evidenceRef: entry.evidenceRef,
      );
      if (entry.mutatedAfterWrite || entry.payloadContainsSecret) continue;
      final action = entry.action.trim();
      if (action.isNotEmpty) loggedActions.add(action);
    }

    // Every security-relevant action the configured controls imply has to
    // appear in the trail, or the trail is decorative for exactly the events
    // that matter.
    final requiredActions = Sprint116SecurityContract.requiredAuditActions(
      effective,
    );
    final unlogged = <String>[
      for (final action in requiredActions)
        if (!loggedActions.contains(action)) action,
    ];
    for (final action in unlogged) {
      invalid.add('audit_action_coverage:$action');
    }

    if (requireCoverage) {
      for (final area in Sprint116SecurityContract.requiredAreas) {
        if (!covered.contains(area)) {
          invalid.add('area_coverage:$area');
        }
      }
    }

    return Sprint116SecurityReport(
      state: invalid.isEmpty
          ? Sprint116SecurityGateStatus.pass
          : Sprint116SecurityGateStatus.fail,
      invalidRecords: invalid,
      coveredAreas: covered,
      unloggedSecurityActions: unlogged,
    );
  }

  void _certifyOAuth(
    Sprint116OAuthFlow flow,
    Set<String> failed,
    Set<String> evidence,
  ) {
    final clientType = flow.clientType.trim();
    if (!Sprint116SecurityContract.clientTypes.contains(clientType)) {
      failed.add('oauth_tests');
      return;
    }

    // PKCE is what stops an intercepted authorization code from being
    // redeemable, so its absence is a defect for either client type.
    if (!flow.pkceEnabled) {
      failed.add('oauth_tests');
      return;
    }
    if (!Sprint116SecurityContract.codeChallengeMethods.contains(
      flow.codeChallengeMethod.trim(),
    )) {
      failed.add('oauth_tests');
      return;
    }
    // Without `state` the callback cannot be tied to the request that started
    // it, which is the login CSRF hole.
    if (flow.stateParameter.trim().isEmpty) {
      failed.add('oauth_tests');
      return;
    }

    if (flow.requestedScopes.isEmpty || flow.grantedScopes.isEmpty) {
      failed.add('oauth_tests');
      return;
    }
    for (final scope in <String>[
      ...flow.requestedScopes,
      ...flow.grantedScopes,
    ]) {
      if (scope.trim() == '*' || scope.trim().toLowerCase() == 'all') {
        // A wildcard scope makes the "minimum permissions" rule unenforceable.
        failed.add('oauth_tests');
        return;
      }
    }
    for (final granted in flow.grantedScopes) {
      final scope = granted.trim();
      if (scope.isNotEmpty && !flow.requestedScopes.contains(scope)) {
        // A grant the user never asked for is a scope escalation.
        failed.add('oauth_tests');
        return;
      }
    }

    if (flow.redirectUri.trim().isEmpty) {
      failed.add('oauth_tests');
      return;
    }
    final allowedHosts = <String>[
      ...flow.allowedRedirectHosts,
      ...flow.allowedRedirectUris.expand((uri) {
        final parsed = Uri.tryParse(uri.trim());
        return parsed == null ? const <String>[] : <String>[parsed.host];
      }),
    ].where((host) => host.trim().isNotEmpty).toList();
    if (allowedHosts.isEmpty) {
      failed.add('oauth_tests');
      return;
    }
    if (!Sprint116SecurityContract.isRedirectUriAllowed(
      flow.redirectUri,
      allowedHosts,
    )) {
      failed.add('oauth_tests');
      return;
    }

    evidence.add('oauth_tests');
  }

  void _certifyVault(
    Sprint116VaultEntry entry,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (entry.secretStoredPlaintext || !entry.encryptedAtRest) {
      failed.add('vault_tests');
      return;
    }
    if (entry.keyId.trim().isEmpty || !entry.keySeparated) {
      // One shared key turns a single compromise into a total one.
      failed.add('vault_tests');
      return;
    }
    // Serialization is where secrets escape: a `toString` in a log line or a
    // `toJson` in a crash report is a plaintext copy nobody tracked.
    if (entry.toStringIncludesSecret || entry.toJsonIncludesSecret) {
      failed.add('vault_tests');
      return;
    }
    if (!entry.logRedactionEnabled) {
      failed.add('vault_tests');
      return;
    }
    if (entry.ownerScope.trim().isEmpty) {
      failed.add('vault_tests');
      return;
    }
    evidence.add('vault_tests');
  }

  void _certifyRedirect(
    Sprint116RedirectCheck redirect,
    Set<String> failed,
    Set<String> evidence,
  ) {
    // An unresolved chain means the final destination was never observed, so
    // no allow-list verdict can be trusted for it.
    if (!redirect.resolvedAfterRedirects) {
      failed.add('redirect_tests');
      return;
    }
    if (redirect.allowedHosts.isEmpty) {
      failed.add('redirect_tests');
      return;
    }

    final target = redirect.finalUrl.trim();
    if (redirect.requireHttps && !target.toLowerCase().startsWith('https://')) {
      failed.add('redirect_tests');
      return;
    }
    if (!Sprint116SecurityContract.isRedirectUriAllowed(
      target,
      redirect.allowedHosts,
    )) {
      failed.add('redirect_tests');
      return;
    }
    evidence.add('redirect_tests');
  }

  void _certifySession(
    Sprint116SessionCheck session,
    int asOfEpochMs,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (session.subjectId.trim().isEmpty) {
      failed.add('session_tests');
      return;
    }
    if (session.issuedAtEpochMs <= 0 ||
        session.expiresAtEpochMs <= 0 ||
        session.absoluteMaxLifetimeMs <= 0) {
      failed.add('session_tests');
      return;
    }
    if (session.expiresAtEpochMs <= session.issuedAtEpochMs) {
      failed.add('session_tests');
      return;
    }

    // An absolute lifetime beyond the committed ceiling is the commitment
    // quietly abandoned.
    final lifetimeMs = session.expiresAtEpochMs - session.issuedAtEpochMs;
    if (lifetimeMs > session.absoluteMaxLifetimeMs) {
      failed.add('session_tests');
      return;
    }
    if (session.expiresAtEpochMs > asOfEpochMs && !session.stillActive) {
      // Claimed dead while its own expiry is still in the future is a
      // contradiction, not extra safety.
      failed.add('session_tests');
      return;
    }
    if (session.stillActive && session.lastSeenAtEpochMs > asOfEpochMs) {
      failed.add('session_tests');
      return;
    }

    if (session.idleTimeoutMs <= 0 ||
        session.idleTimeoutMs > session.absoluteMaxLifetimeMs) {
      failed.add('session_tests');
      return;
    }
    // An idle timeout that cannot actually idle out is no timeout at all.
    if (session.stillActive &&
        asOfEpochMs > session.lastSeenAtEpochMs &&
        (asOfEpochMs - session.lastSeenAtEpochMs) >= session.idleTimeoutMs) {
      failed.add('session_tests');
      return;
    }

    if (session.tokenInQueryString) {
      failed.add('session_tests');
      return;
    }
    // No rotation on login is session fixation; no invalidation on logout is a
    // session that outlives the user closing the app.
    if (!session.rotatedOnLogin || !session.invalidatedOnLogout) {
      failed.add('session_tests');
      return;
    }

    evidence.add('session_tests');
  }

  void _certifyPermission(
    Sprint116PermissionGrant grant,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (grant.subjectId.trim().isEmpty || grant.resourceId.trim().isEmpty) {
      failed.add('permission_tests');
      return;
    }
    // A default other than deny is least-privilege inverted: anything not
    // explicitly granted is then reachable.
    if (grant.defaultDecision.trim() !=
        Sprint116SecurityContract.leastPrivilegeDefault) {
      failed.add('permission_tests');
      return;
    }
    if (grant.declaredPermissions.isEmpty) {
      failed.add('permission_tests');
      return;
    }
    for (final granted in grant.grantedPermissions) {
      final permission = granted.trim();
      if (permission.isEmpty) {
        failed.add('permission_tests');
        return;
      }
      if (!grant.declaredPermissions.contains(permission)) {
        // Granted beyond what the resource can authorize.
        failed.add('permission_tests');
        return;
      }
    }
    for (final requested in grant.requestedPermissions) {
      final permission = requested.trim();
      if (permission.isNotEmpty &&
          !grant.declaredPermissions.contains(permission)) {
        failed.add('permission_tests');
        return;
      }
    }
    // A refresh that quietly widens the grant turns a consent screen into a
    // suggestion.
    if (grant.escalationOnRefresh) {
      failed.add('permission_tests');
      return;
    }
    evidence.add('permission_tests');
  }

  void _certifyWebhook(
    Sprint116WebhookEndpoint hook,
    int asOfEpochMs,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (hook.providerId.trim().isEmpty) {
      failed.add('webhook_tests');
      return;
    }
    // Unauthenticated processing is the whole attack: the signature decides
    // whether the body is real, and it has to decide it first.
    if (!hook.signatureVerifiedBeforeProcessing) {
      failed.add('webhook_tests');
      return;
    }
    if (!hook.constantTimeCompare) {
      failed.add('webhook_tests');
      return;
    }
    if (hook.replayWindowSeconds <= 0 ||
        hook.eventTimestampEpochMs <= 0 ||
        hook.processingEpochMs <= 0) {
      failed.add('webhook_tests');
      return;
    }
    if (hook.eventTimestampEpochMs > asOfEpochMs) {
      // An event from the future is a forged timestamp, not a fresh one.
      failed.add('webhook_tests');
      return;
    }
    final ageMs = hook.processingEpochMs - hook.eventTimestampEpochMs;
    if (ageMs < 0 || ageMs > hook.replayWindowSeconds * 1000) {
      // A stale delivery is a replay, whether or not the attacker admits it.
      failed.add('webhook_tests');
      return;
    }
    if (hook.duplicateDeliveryDetected && !hook.duplicateDeliveryRejected) {
      failed.add('webhook_tests');
      return;
    }
    evidence.add('webhook_tests');
  }

  void _certifyDependency(
    Sprint116Dependency dependency,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (dependency.package.trim().isEmpty) {
      failed.add('dependency_scan');
      return;
    }
    // An unresolved vulnerability question is not a clean bill of health.
    if (!Sprint116SecurityContract.cleanVulnerabilityStatuses.contains(
      dependency.vulnerabilityStatus.trim(),
    )) {
      failed.add('dependency_scan');
      return;
    }
    final constraint = dependency.versionConstraint.trim();
    if (constraint.isEmpty || constraint.toLowerCase() == 'any') {
      failed.add('dependency_scan');
      return;
    }
    if (!dependency.pinnedToLockfile && !dependency.devOnly) {
      // Unpinned means the build that gets scanned is not necessarily the
      // build that ships.
      failed.add('dependency_scan');
      return;
    }
    if (Sprint116SecurityContract.blockedLicenses.contains(
      dependency.license.trim(),
    )) {
      failed.add('dependency_scan');
      return;
    }
    if (dependency.license.trim().isEmpty) {
      failed.add('dependency_scan');
      return;
    }
    if (!dependency.devOnly && !dependency.referencedFromProductionCode) {
      // A shipped dependency nothing references is a phantom, and a phantom
      // that appears only in an old manifest hides real exposure.
      failed.add('dependency_scan');
      return;
    }
    evidence.add('dependency_scan');
  }

  void _certifyAudit(
    Sprint116AuditEntry entry,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (entry.actorId.trim().isEmpty) {
      failed.add('audit_tests');
      return;
    }
    if (entry.action.trim().isEmpty || entry.targetId.trim().isEmpty) {
      failed.add('audit_tests');
      return;
    }
    if (entry.occurredAtEpochMs <= 0) {
      failed.add('audit_tests');
      return;
    }
    // A rewritable trail is not a trail, and a secret inside a payload turns
    // the audit store into a second, worse vault.
    if (entry.mutatedAfterWrite || entry.payloadContainsSecret) {
      failed.add('audit_tests');
      return;
    }
    evidence.add('audit_tests');
  }

  Sprint116SecurityReport _blocked(String reason) {
    return Sprint116SecurityReport(
      state: Sprint116SecurityGateStatus.blocked,
      invalidRecords: <String>[reason],
      coveredAreas: const <String>[],
      unloggedSecurityActions: const <String>[],
    );
  }

  Map<String, dynamic>? _readManifest() {
    final file = File(Sprint116SecurityContract.manifestPath);
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

  Sprint116SecurityControlSet _controlsFromManifest(
    Map<String, dynamic>? manifest,
  ) {
    return Sprint116SecurityControlSet(
      oauthFlows: _mapList(manifest, 'oauth_flows', _oauthFromManifest),
      vaultEntries: _mapList(manifest, 'vault_entries', _vaultFromManifest),
      redirects: _mapList(manifest, 'redirects', _redirectFromManifest),
      sessions: _mapList(manifest, 'sessions', _sessionFromManifest),
      permissions: _mapList(manifest, 'permissions', _permissionFromManifest),
      webhooks: _mapList(manifest, 'webhooks', _webhookFromManifest),
      dependencies: _mapList(manifest, 'dependencies', _dependencyFromManifest),
      auditEntries: _mapList(manifest, 'audit_entries', _auditFromManifest),
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
    return raw.map((item) => item?.toString() ?? '').toList(growable: false);
  }

  int _int(Object? raw) => (raw as num?)?.toInt() ?? 0;

  Sprint116OAuthFlow _oauthFromManifest(Map<Object?, Object?> item) {
    return Sprint116OAuthFlow(
      controlId: item['control_id']?.toString() ?? '',
      providerId: item['provider_id']?.toString() ?? '',
      clientType: item['client_type']?.toString() ?? '',
      pkceEnabled: item['pkce_enabled'] == true,
      codeChallengeMethod: item['code_challenge_method']?.toString() ?? '',
      stateParameter: item['state_parameter']?.toString() ?? '',
      allowedRedirectUris: _stringList(item['allowed_redirect_uris']),
      allowedRedirectHosts: _stringList(item['allowed_redirect_hosts']),
      redirectUri: item['redirect_uri']?.toString() ?? '',
      requestedScopes: _stringList(item['requested_scopes']),
      grantedScopes: _stringList(item['granted_scopes']),
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116VaultEntry _vaultFromManifest(Map<Object?, Object?> item) {
    return Sprint116VaultEntry(
      vaultId: item['vault_id']?.toString() ?? '',
      ownerScope: item['owner_scope']?.toString() ?? '',
      secretStoredPlaintext: item['secret_stored_plaintext'] == true,
      encryptedAtRest: item['encrypted_at_rest'] == true,
      keyId: item['key_id']?.toString() ?? '',
      keySeparated: item['key_separated'] == true,
      toStringIncludesSecret: item['to_string_includes_secret'] == true,
      toJsonIncludesSecret: item['to_json_includes_secret'] == true,
      logRedactionEnabled: item['log_redaction_enabled'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116RedirectCheck _redirectFromManifest(Map<Object?, Object?> item) {
    return Sprint116RedirectCheck(
      redirectId: item['redirect_id']?.toString() ?? '',
      finalUrl: item['final_url']?.toString() ?? '',
      allowedHosts: _stringList(item['allowed_hosts']),
      requireHttps: item['require_https'] == true,
      resolvedAfterRedirects: item['resolved_after_redirects'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116SessionCheck _sessionFromManifest(Map<Object?, Object?> item) {
    return Sprint116SessionCheck(
      sessionId: item['session_id']?.toString() ?? '',
      subjectId: item['subject_id']?.toString() ?? '',
      issuedAtEpochMs: _int(item['issued_at_epoch_ms']),
      expiresAtEpochMs: _int(item['expires_at_epoch_ms']),
      absoluteMaxLifetimeMs: _int(item['absolute_max_lifetime_ms']),
      lastSeenAtEpochMs: _int(item['last_seen_at_epoch_ms']),
      idleTimeoutMs: _int(item['idle_timeout_ms']),
      tokenInQueryString: item['token_in_query_string'] == true,
      rotatedOnLogin: item['rotated_on_login'] == true,
      invalidatedOnLogout: item['invalidated_on_logout'] == true,
      stillActive: item['still_active'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116PermissionGrant _permissionFromManifest(Map<Object?, Object?> item) {
    return Sprint116PermissionGrant(
      grantId: item['grant_id']?.toString() ?? '',
      subjectId: item['subject_id']?.toString() ?? '',
      resourceId: item['resource_id']?.toString() ?? '',
      declaredPermissions: _stringList(item['declared_permissions']),
      requestedPermissions: _stringList(item['requested_permissions']),
      grantedPermissions: _stringList(item['granted_permissions']),
      defaultDecision: item['default_decision']?.toString() ?? '',
      escalationOnRefresh: item['escalation_on_refresh'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116WebhookEndpoint _webhookFromManifest(Map<Object?, Object?> item) {
    return Sprint116WebhookEndpoint(
      webhookId: item['webhook_id']?.toString() ?? '',
      providerId: item['provider_id']?.toString() ?? '',
      signatureVerifiedBeforeProcessing:
          item['signature_verified_before_processing'] == true,
      constantTimeCompare: item['constant_time_compare'] == true,
      replayWindowSeconds: _int(item['replay_window_seconds']),
      eventTimestampEpochMs: _int(item['event_timestamp_epoch_ms']),
      processingEpochMs: _int(item['processing_epoch_ms']),
      duplicateDeliveryDetected: item['duplicate_delivery_detected'] == true,
      duplicateDeliveryRejected: item['duplicate_delivery_rejected'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116Dependency _dependencyFromManifest(Map<Object?, Object?> item) {
    return Sprint116Dependency(
      dependencyId: item['dependency_id']?.toString() ?? '',
      package: item['package']?.toString() ?? '',
      versionConstraint: item['version_constraint']?.toString() ?? '',
      license: item['license']?.toString() ?? '',
      vulnerabilityStatus: item['vulnerability_status']?.toString() ?? '',
      pinnedToLockfile: item['pinned_to_lockfile'] == true,
      devOnly: item['dev_only'] == true,
      referencedFromProductionCode:
          item['referenced_from_production_code'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116AuditEntry _auditFromManifest(Map<Object?, Object?> item) {
    return Sprint116AuditEntry(
      entryId: item['entry_id']?.toString() ?? '',
      actorId: item['actor_id']?.toString() ?? '',
      action: item['action']?.toString() ?? '',
      targetId: item['target_id']?.toString() ?? '',
      occurredAtEpochMs: _int(item['occurred_at_epoch_ms']),
      mutatedAfterWrite: item['mutated_after_write'] == true,
      payloadContainsSecret: item['payload_contains_secret'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }
}
