/// Sprint 115.33 — Session & Device Management.
///
/// Local session/device management metadata and state transitions only.
/// Live identity-provider session inventory, device discovery, revocation
/// propagation, force-logout execution, and alert delivery remain
/// injected/external (`DEFERRED-EXTERNAL`).
library;

import 'dart:collection';

enum SessionDevicePlatform { windows, macos, linux, android, ios, web, unknown }

enum SessionTrustState { trusted, untrusted, unknown }

enum SessionActivityState { active, revoked }

enum SessionAlertSeverity { info, warning, critical }

/// What a security action on a session did, whether it was allowed or not.
///
/// A refused revoke and an attempt that was never made must not look the same,
/// so both are recorded and the outcome is part of the record. The event
/// carries the session, the action, and the instant only: no device label, no
/// location, and no free-text reason, which is what `audit_redaction` is
/// promising.
enum SessionAuditOutcome { revoked, denied }

final class SessionSecurityAuditEvent {
  SessionSecurityAuditEvent({
    required String action,
    required String sessionId,
    required this.outcome,
    required this.occurredAt,
  }) : action = _required(action, 'action'),
       sessionId = _required(sessionId, 'sessionId') {
    if (!occurredAt.isUtc) {
      throw ArgumentError.value(occurredAt, 'occurredAt', 'Must be UTC.');
    }
  }

  /// The action attempted, e.g. `revoke_session`.
  final String action;

  /// The session the action targeted. `*` covers an all-session action.
  final String sessionId;

  final SessionAuditOutcome outcome;
  final DateTime occurredAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'action': action,
    'session_id': sessionId,
    'outcome': outcome.name,
    'occurred_at': occurredAt.toIso8601String(),
  };
}

final class DeviceDetails {
  DeviceDetails({
    required String deviceLabel,
    required this.platform,
    this.appVersion,
    this.locationLabel,
    this.firstSeenAt,
  }) : deviceLabel = _required(deviceLabel, 'deviceLabel') {
    if (appVersion != null && appVersion!.trim().isEmpty) {
      throw ArgumentError.value(appVersion, 'appVersion');
    }
    if (locationLabel != null && locationLabel!.trim().isEmpty) {
      throw ArgumentError.value(locationLabel, 'locationLabel');
    }
    if (firstSeenAt != null && !firstSeenAt!.isUtc) {
      throw ArgumentError.value(firstSeenAt, 'firstSeenAt', 'Must be UTC.');
    }
  }

  final String deviceLabel;
  final SessionDevicePlatform platform;
  final String? appVersion;

  /// Nullable by design: location is never fabricated when unavailable.
  final String? locationLabel;
  final DateTime? firstSeenAt;
}

final class ManagedSession {
  ManagedSession({
    required String sessionId,
    required this.isCurrent,
    required this.lastActiveAt,
    required this.trust,
    required this.state,
    required this.suspicious,
    required this.device,
    this.trustedAt,
    this.revokedAt,
  }) : sessionId = _required(sessionId, 'sessionId') {
    if (!lastActiveAt.isUtc) {
      throw ArgumentError.value(lastActiveAt, 'lastActiveAt', 'Must be UTC.');
    }
    if (trustedAt != null && !trustedAt!.isUtc) {
      throw ArgumentError.value(trustedAt, 'trustedAt', 'Must be UTC.');
    }
    if (revokedAt != null && !revokedAt!.isUtc) {
      throw ArgumentError.value(revokedAt, 'revokedAt', 'Must be UTC.');
    }
    if (state == SessionActivityState.revoked && revokedAt == null) {
      throw ArgumentError('A revoked session requires revokedAt.');
    }
    if (state == SessionActivityState.active && revokedAt != null) {
      throw ArgumentError('An active session cannot carry revokedAt.');
    }
    if (isCurrent && state == SessionActivityState.revoked) {
      throw ArgumentError('The current session must stay active.');
    }
  }

  final String sessionId;
  final bool isCurrent;
  final DateTime lastActiveAt;
  final SessionTrustState trust;
  final SessionActivityState state;
  final bool suspicious;
  final DeviceDetails device;
  final DateTime? trustedAt;
  final DateTime? revokedAt;
}

final class SessionSecurityAlert {
  SessionSecurityAlert({
    required String id,
    required String sessionId,
    required this.severity,
    required String title,
    required this.occurredAt,
  }) : id = _required(id, 'id'),
       sessionId = _required(sessionId, 'sessionId'),
       title = _required(title, 'title') {
    if (!occurredAt.isUtc) {
      throw ArgumentError.value(occurredAt, 'occurredAt', 'Must be UTC.');
    }
  }

  final String id;
  final String sessionId;
  final SessionAlertSeverity severity;
  final String title;
  final DateTime occurredAt;
}

final class AccountCenterSessionDeviceManagement {
  AccountCenterSessionDeviceManagement({
    required Iterable<ManagedSession> sessions,
    required Iterable<SessionSecurityAlert> alerts,
    Iterable<SessionSecurityAuditEvent> audit =
        const <SessionSecurityAuditEvent>[],
  }) : _sessions = List<ManagedSession>.of(sessions),
       _alerts = List<SessionSecurityAlert>.of(alerts),
       _audit = List<SessionSecurityAuditEvent>.of(audit) {
    _requireUnique(_sessions.map((session) => session.sessionId), 'session.id');
    _requireUnique(_alerts.map((alert) => alert.id), 'alert.id');
    final knownIds = _sessions.map((session) => session.sessionId).toSet();
    for (final alert in _alerts) {
      if (!knownIds.contains(alert.sessionId)) {
        throw ArgumentError.value(
          alert.sessionId,
          'alert.sessionId',
          'Unknown session.',
        );
      }
    }
    if (_sessions.isNotEmpty &&
        _sessions.where((session) => session.isCurrent).length != 1) {
      throw ArgumentError(
        'A non-empty session list requires exactly one current session.',
      );
    }
    _sessions.sort((left, right) {
      final byActivity = right.lastActiveAt.compareTo(left.lastActiveAt);
      return byActivity != 0
          ? byActivity
          : left.sessionId.compareTo(right.sessionId);
    });
    _alerts.sort((left, right) {
      final byTime = right.occurredAt.compareTo(left.occurredAt);
      return byTime != 0 ? byTime : left.id.compareTo(right.id);
    });
  }

  final List<ManagedSession> _sessions;
  final List<SessionSecurityAlert> _alerts;
  final List<SessionSecurityAuditEvent> _audit;

  List<ManagedSession> get sessions => UnmodifiableListView(_sessions);

  List<SessionSecurityAlert> get alerts => UnmodifiableListView(_alerts);

  /// Every security action taken against a session, allowed or refused.
  ///
  /// Before this trail existed the seam had no record at all, so a refused
  /// revoke and an attempt that was never made were indistinguishable.
  List<SessionSecurityAuditEvent> get audit => UnmodifiableListView(_audit);

  /// The trail entries for one action, in the order they happened.
  List<SessionSecurityAuditEvent> auditFor(String action) =>
      UnmodifiableListView(
        _audit.where((event) => event.action == action).toList(growable: false),
      );

  int get activeCount => _sessions
      .where((session) => session.state == SessionActivityState.active)
      .length;

  int get revokedCount => _sessions
      .where((session) => session.state == SessionActivityState.revoked)
      .length;

  int get suspiciousCount =>
      _sessions.where((session) => session.suspicious).length;

  ManagedSession sessionById(String sessionId) {
    final normalized = sessionId.trim();
    for (final session in _sessions) {
      if (session.sessionId == normalized) return session;
    }
    throw StateError('Unknown session: $sessionId');
  }

  AccountCenterSessionDeviceManagement trustSession(
    String sessionId, {
    required bool trusted,
    required DateTime at,
  }) {
    _requireUtc(at, 'at');
    final target = sessionById(sessionId);
    if (target.state != SessionActivityState.active) {
      throw ArgumentError('Only an active session can change trust state.');
    }
    if (trusted && target.suspicious) {
      throw ArgumentError(
        'A suspicious session must be revoked before it can be trusted.',
      );
    }
    final updated = ManagedSession(
      sessionId: target.sessionId,
      isCurrent: target.isCurrent,
      lastActiveAt: target.lastActiveAt,
      trust: trusted ? SessionTrustState.trusted : SessionTrustState.untrusted,
      state: target.state,
      suspicious: target.suspicious,
      device: target.device,
      trustedAt: trusted ? at : null,
      revokedAt: target.revokedAt,
    );
    return _withSession(updated);
  }

  /// Revokes a session, recording the attempt either way.
  ///
  /// The previous version threw on both refusals, so a caller that caught the
  /// error had no record that anything had been tried, and a caller that did
  /// not catch it learned nothing about the other sessions. Refusals are now
  /// returned as a manager whose audit trail carries `denied`, and the session
  /// list is left exactly as it was. Unknown session ids still throw, because
  /// there is no session to attach the refusal to.
  AccountCenterSessionDeviceManagement revokeSession(
    String sessionId, {
    required DateTime at,
  }) {
    _requireUtc(at, 'at');
    final target = sessionById(sessionId);
    if (target.isCurrent || target.state != SessionActivityState.active) {
      return _withAudit(
        SessionSecurityAuditEvent(
          action: 'revoke_session',
          sessionId: target.sessionId,
          outcome: SessionAuditOutcome.denied,
          occurredAt: at,
        ),
      );
    }
    return _withSession(
      _replace(target, state: SessionActivityState.revoked, revokedAt: at),
    )._withAudit(
      SessionSecurityAuditEvent(
        action: 'revoke_session',
        sessionId: target.sessionId,
        outcome: SessionAuditOutcome.revoked,
        occurredAt: at,
      ),
    );
  }

  /// Ends every other active session, recording what it did and what it did
  /// not.
  ///
  /// Confirmation is still required, but a missing confirmation is now recorded
  /// as a denial instead of vanishing, and each dropped session gets its own
  /// entry so the trail says which sessions went. The current session is
  /// skipped by design and is not recorded as a denial: it was never a target.
  AccountCenterSessionDeviceManagement forceLogout({
    required bool confirmed,
    required DateTime at,
  }) {
    _requireUtc(at, 'at');
    if (!confirmed) {
      return _withAudit(
        SessionSecurityAuditEvent(
          action: 'force_logout',
          sessionId: '*',
          outcome: SessionAuditOutcome.denied,
          occurredAt: at,
        ),
      );
    }
    final revoked = <SessionSecurityAuditEvent>[];
    final updated = _sessions
        .map((session) {
          if (session.isCurrent ||
              session.state != SessionActivityState.active) {
            return session;
          }
          revoked.add(
            SessionSecurityAuditEvent(
              action: 'force_logout',
              sessionId: session.sessionId,
              outcome: SessionAuditOutcome.revoked,
              occurredAt: at,
            ),
          );
          return _replace(
            session,
            state: SessionActivityState.revoked,
            revokedAt: at,
          );
        })
        .toList(growable: false);
    return AccountCenterSessionDeviceManagement(
      sessions: updated,
      alerts: _alerts,
      audit: [..._audit, ...revoked],
    );
  }

  AccountCenterSessionDeviceManagement markSuspicious(
    String sessionId, {
    required String reason,
    required DateTime at,
  }) {
    _requireUtc(at, 'at');
    final title = _required(reason, 'reason');
    final target = sessionById(sessionId);
    if (target.state != SessionActivityState.active) {
      throw ArgumentError('Only an active session can be flagged.');
    }
    if (target.suspicious) {
      throw ArgumentError('The session is already flagged as suspicious.');
    }
    final flagged = _replace(target, suspicious: true);
    final alert = SessionSecurityAlert(
      id: 'suspicion-${target.sessionId}',
      sessionId: target.sessionId,
      severity: SessionAlertSeverity.warning,
      title: title,
      occurredAt: at,
    );
    return AccountCenterSessionDeviceManagement(
      sessions: _sessions.map((session) {
        return session.sessionId == flagged.sessionId ? flagged : session;
      }),
      alerts: [..._alerts, alert],
    );
  }

  AccountCenterSessionDeviceManagement _withSession(ManagedSession updated) =>
      AccountCenterSessionDeviceManagement(
        sessions: _sessions.map((session) {
          return session.sessionId == updated.sessionId ? updated : session;
        }),
        alerts: _alerts,
        audit: _audit,
      );

  /// Appends one security action to the trail and changes nothing else.
  AccountCenterSessionDeviceManagement _withAudit(
    SessionSecurityAuditEvent event,
  ) => AccountCenterSessionDeviceManagement(
    sessions: _sessions,
    alerts: _alerts,
    audit: [..._audit, event],
  );

  ManagedSession _replace(
    ManagedSession session, {
    SessionActivityState? state,
    bool? suspicious,
    DateTime? revokedAt,
  }) => ManagedSession(
    sessionId: session.sessionId,
    isCurrent: session.isCurrent,
    lastActiveAt: session.lastActiveAt,
    trust: session.trust,
    state: state ?? session.state,
    suspicious: suspicious ?? session.suspicious,
    device: session.device,
    trustedAt: session.trustedAt,
    revokedAt: revokedAt ?? session.revokedAt,
  );
}

void _requireUtc(DateTime value, String field) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, field, 'Must be UTC.');
  }
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}

void _requireUnique(Iterable<String> values, String field) {
  final seen = <String>{};
  for (final value in values) {
    if (!seen.add(value)) {
      throw ArgumentError.value(value, field, 'Must be unique.');
    }
  }
}
