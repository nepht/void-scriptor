import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_session_device_management.dart';

void main() {
  group('AccountCenterSessionDeviceManagement', () {
    test('manifest preserves every canonical 115.33 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_session_device_management.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.33');
      expect(manifest['acceptance'], <String>[
        'list_sessions',
        'device_details',
        'trust_state',
        'revoke',
        'force_logout',
        'security_alert',
      ]);
      expect(
        manifest['implementation'],
        'lib/features/account/domain/account_center_session_device_management.dart',
      );
      expect(
        manifest['evidence'],
        'test/features/account/domain/account_center_session_device_management_test.dart',
      );
    });

    test('lists sessions newest-first with unique ids and one current', () {
      final management = _fixture();

      expect(management.sessions.map((session) => session.sessionId), [
        'sess-laptop',
        'sess-desktop',
        'sess-old',
      ]);
      expect(
        management.sessions
            .where((session) => session.isCurrent)
            .map((session) => session.sessionId),
        ['sess-desktop'],
      );
      expect(management.activeCount, 3);
      expect(management.suspiciousCount, 0);
      expect(management.revokedCount, 0);
      expect(
        () => management.sessions.add(_session('sess-extra')),
        throwsUnsupportedError,
      );
    });

    test('rejects malformed session collections fail-closed', () {
      expect(
        () => AccountCenterSessionDeviceManagement(
          sessions: [_session('dup'), _session('dup')],
          alerts: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterSessionDeviceManagement(
          sessions: [_session('no-current'), _session('also-no-current')],
          alerts: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterSessionDeviceManagement(
          sessions: [
            _session('current-a', isCurrent: true),
            _session('current-b', isCurrent: true),
          ],
          alerts: const [],
        ),
        throwsArgumentError,
      );
      expect(
        AccountCenterSessionDeviceManagement(
          sessions: const [],
          alerts: const [],
        ).sessions,
        isEmpty,
      );
    });

    test('exposes device details without fabricating unknown fields', () {
      final management = _fixture();

      final laptop = management.sessionById('sess-laptop');
      expect(laptop.device.deviceLabel, 'Device sess-laptop');
      expect(laptop.device.platform, SessionDevicePlatform.windows);
      expect(laptop.device.appVersion, '1.3.0-alpha.1');
      expect(laptop.device.locationLabel, isNull);
      expect(laptop.device.firstSeenAt, DateTime.utc(2026, 9, 20));
      expect(laptop.lastActiveAt, DateTime.utc(2026, 9, 26, 3));
      expect(() => management.sessionById('missing'), throwsStateError);

      expect(
        () => DeviceDetails(
          deviceLabel: '   ',
          platform: SessionDevicePlatform.windows,
        ),
        throwsArgumentError,
      );
      expect(
        () => DeviceDetails(
          deviceLabel: 'Desktop',
          platform: SessionDevicePlatform.windows,
          appVersion: ' ',
          locationLabel: null,
          firstSeenAt: DateTime(2026, 9, 20),
        ),
        throwsArgumentError,
      );
    });

    test('trust state transitions are explicit and audited in UTC', () {
      final management = _fixture();
      final trusted = management.trustSession(
        'sess-laptop',
        trusted: true,
        at: DateTime.utc(2026, 9, 26, 4),
      );

      final session = trusted.sessionById('sess-laptop');
      expect(session.trust, SessionTrustState.trusted);
      expect(session.trustedAt, DateTime.utc(2026, 9, 26, 4));

      final untrusted = trusted.trustSession(
        'sess-laptop',
        trusted: false,
        at: DateTime.utc(2026, 9, 26, 5),
      );
      expect(
        untrusted.sessionById('sess-laptop').trust,
        SessionTrustState.untrusted,
      );
      expect(untrusted.sessionById('sess-laptop').trustedAt, isNull);

      // Original snapshot is immutable.
      expect(
        management.sessionById('sess-laptop').trust,
        SessionTrustState.untrusted,
      );

      expect(
        () => management.trustSession(
          'sess-laptop',
          trusted: true,
          at: DateTime(2026, 9, 26),
        ),
        throwsArgumentError,
      );
      expect(
        () => management.trustSession(
          'missing',
          trusted: true,
          at: DateTime.utc(2026, 9, 26),
        ),
        throwsStateError,
      );
    });

    test('suspicious and revoked sessions refuse trust escalation', () {
      final management = _fixture(
        sessions: [
          _session('sess-flagged', isCurrent: true, suspicious: true),
          _session('sess-gone', state: SessionActivityState.revoked),
        ],
        alerts: [
          SessionSecurityAlert(
            id: 'suspicion-sess-flagged',
            sessionId: 'sess-flagged',
            severity: SessionAlertSeverity.warning,
            title: 'Unrecognized sign-in',
            occurredAt: DateTime.utc(2026, 9, 26, 1),
          ),
        ],
      );

      expect(
        () => management.trustSession(
          'sess-flagged',
          trusted: true,
          at: DateTime.utc(2026, 9, 26, 6),
        ),
        throwsArgumentError,
      );
      // Untrusting is the safe direction and stays available while flagged.
      expect(
        management
            .trustSession(
              'sess-flagged',
              trusted: false,
              at: DateTime.utc(2026, 9, 26, 6),
            )
            .sessionById('sess-flagged')
            .trust,
        SessionTrustState.untrusted,
      );
      expect(
        () => management.trustSession(
          'sess-gone',
          trusted: false,
          at: DateTime.utc(2026, 9, 26, 6),
        ),
        throwsArgumentError,
      );
    });

    test('revoke ends exactly one active session with a UTC timestamp', () {
      final management = _fixture();
      final revoked = management.revokeSession(
        'sess-laptop',
        at: DateTime.utc(2026, 9, 26, 6),
      );

      final session = revoked.sessionById('sess-laptop');
      expect(session.state, SessionActivityState.revoked);
      expect(session.revokedAt, DateTime.utc(2026, 9, 26, 6));
      expect(revoked.activeCount, 2);
      expect(revoked.revokedCount, 1);
      expect(
        management.sessionById('sess-laptop').state,
        SessionActivityState.active,
      );

      // Revoking an already-revoked session is a recorded refusal, not a
      // throw: a refused revoke and an attempt never made used to be
      // indistinguishable, and the refusal now carries its own audit entry.
      final alreadyRevoked = revoked.revokeSession(
        'sess-laptop',
        at: DateTime.utc(2026, 9, 26, 7),
      );
      expect(alreadyRevoked.revokedCount, 1);
      expect(
        alreadyRevoked.auditFor('revoke_session').last.outcome,
        SessionAuditOutcome.denied,
      );
      expect(
        () => management.revokeSession(
          'missing',
          at: DateTime.utc(2026, 9, 26, 7),
        ),
        throwsStateError,
      );
      expect(
        () =>
            management.revokeSession('sess-laptop', at: DateTime(2026, 9, 26)),
        throwsArgumentError,
      );
      // The current session is never revoked by the device-management path.
      // The attempt is refused and recorded rather than thrown, so the session
      // list must be untouched and the refusal must still be visible.
      final current = management.revokeSession(
        'sess-desktop',
        at: DateTime.utc(2026, 9, 26, 7),
      );
      expect(
        current.sessionById('sess-desktop').state,
        SessionActivityState.active,
      );
      expect(current.revokedCount, 0);
      final currentAttempts = current.auditFor('revoke_session');
      expect(currentAttempts.single.outcome, SessionAuditOutcome.denied);
      expect(currentAttempts.single.sessionId, 'sess-desktop');
    });

    test(
      'force logout requires confirmation and keeps the current session',
      () {
        final management = _fixture();

        // Confirmation is still required; the refusal is now recorded rather
        // than thrown, so the attempt stays visible.
        final unconfirmed = management.forceLogout(
          confirmed: false,
          at: DateTime.utc(2026, 9, 26, 6),
        );
        expect(unconfirmed.activeCount, 3);
        expect(unconfirmed.revokedCount, 0);
        expect(
          unconfirmed.auditFor('force_logout').single.outcome,
          SessionAuditOutcome.denied,
        );

        final loggedOut = management.forceLogout(
          confirmed: true,
          at: DateTime.utc(2026, 9, 26, 6),
        );
        expect(loggedOut.activeCount, 1);
        expect(loggedOut.revokedCount, 2);
        expect(
          loggedOut.sessionById('sess-desktop').state,
          SessionActivityState.active,
        );
        expect(loggedOut.sessionById('sess-desktop').isCurrent, isTrue);
        expect(
          loggedOut.sessionById('sess-laptop').revokedAt,
          DateTime.utc(2026, 9, 26, 6),
        );

        // Idempotent once every non-current session is already revoked.
        final again = loggedOut.forceLogout(
          confirmed: true,
          at: DateTime.utc(2026, 9, 26, 7),
        );
        expect(again.revokedCount, 2);
        expect(again.activeCount, 1);

        expect(
          () => management.forceLogout(
            confirmed: true,
            at: DateTime(2026, 9, 26),
          ),
          throwsArgumentError,
        );
      },
    );

    test('suspicious-session handling raises an attached security alert', () {
      final management = _fixture();
      final flagged = management.markSuspicious(
        'sess-old',
        reason: 'Impossible-travel sign-in',
        at: DateTime.utc(2026, 9, 26, 6),
      );

      expect(flagged.sessionById('sess-old').suspicious, isTrue);
      expect(flagged.suspiciousCount, 1);
      expect(flagged.alerts.map((alert) => alert.id), ['suspicion-sess-old']);
      expect(flagged.alerts.single.sessionId, 'sess-old');
      expect(flagged.alerts.single.severity, SessionAlertSeverity.warning);
      expect(flagged.alerts.single.occurredAt, DateTime.utc(2026, 9, 26, 6));
      expect(management.alerts, isEmpty);
      expect(
        () => flagged.markSuspicious(
          'sess-old',
          reason: 'Duplicate flag',
          at: DateTime.utc(2026, 9, 26, 7),
        ),
        throwsArgumentError,
      );
      expect(
        () => management.markSuspicious(
          'missing',
          reason: 'No such session',
          at: DateTime.utc(2026, 9, 26, 7),
        ),
        throwsStateError,
      );
      expect(
        () => management.markSuspicious(
          'sess-old',
          reason: '   ',
          at: DateTime.utc(2026, 9, 26, 7),
        ),
        throwsArgumentError,
      );
    });

    test('security alerts validate linkage, ids, and UTC ordering', () {
      expect(
        () => AccountCenterSessionDeviceManagement(
          sessions: [_session('sess-desktop', isCurrent: true)],
          alerts: [
            SessionSecurityAlert(
              id: 'orphan',
              sessionId: 'sess-unknown',
              severity: SessionAlertSeverity.critical,
              title: 'Orphan alert',
              occurredAt: DateTime.utc(2026, 9, 26),
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => SessionSecurityAlert(
          id: '  ',
          sessionId: 'sess-desktop',
          severity: SessionAlertSeverity.info,
          title: 'Blank id',
          occurredAt: DateTime.utc(2026, 9, 26),
        ),
        throwsArgumentError,
      );
      expect(
        () => SessionSecurityAlert(
          id: 'a',
          sessionId: 'sess-desktop',
          severity: SessionAlertSeverity.info,
          title: 'Local time',
          occurredAt: DateTime(2026, 9, 26),
        ),
        throwsArgumentError,
      );

      final management = AccountCenterSessionDeviceManagement(
        sessions: [_session('sess-desktop', isCurrent: true)],
        alerts: [
          SessionSecurityAlert(
            id: 'older',
            sessionId: 'sess-desktop',
            severity: SessionAlertSeverity.info,
            title: 'Older',
            occurredAt: DateTime.utc(2026, 9, 25),
          ),
          SessionSecurityAlert(
            id: 'newer',
            sessionId: 'sess-desktop',
            severity: SessionAlertSeverity.critical,
            title: 'Newer',
            occurredAt: DateTime.utc(2026, 9, 26),
          ),
        ],
      );
      expect(management.alerts.map((alert) => alert.id), ['newer', 'older']);
      expect(() => management.alerts.clear(), throwsUnsupportedError);
    });
  });
}

AccountCenterSessionDeviceManagement _fixture({
  List<ManagedSession>? sessions,
  List<SessionSecurityAlert>? alerts,
}) => AccountCenterSessionDeviceManagement(
  sessions:
      sessions ??
      [
        _session('sess-laptop', lastActiveAt: DateTime.utc(2026, 9, 26, 3)),
        _session(
          'sess-desktop',
          lastActiveAt: DateTime.utc(2026, 9, 26, 2),
          isCurrent: true,
        ),
        _session(
          'sess-old',
          lastActiveAt: DateTime.utc(2026, 9, 24),
          trust: SessionTrustState.untrusted,
        ),
      ],
  alerts: alerts ?? const [],
);

ManagedSession _session(
  String id, {
  DateTime? lastActiveAt,
  bool isCurrent = false,
  bool suspicious = false,
  SessionTrustState trust = SessionTrustState.untrusted,
  SessionActivityState state = SessionActivityState.active,
}) => ManagedSession(
  sessionId: id,
  isCurrent: isCurrent,
  lastActiveAt: lastActiveAt ?? DateTime.utc(2026, 9, 25),
  trust: trust,
  state: state,
  suspicious: suspicious,
  revokedAt: state == SessionActivityState.revoked
      ? DateTime.utc(2026, 9, 23)
      : null,
  device: DeviceDetails(
    deviceLabel: 'Device $id',
    platform: SessionDevicePlatform.windows,
    appVersion: '1.3.0-alpha.1',
    locationLabel: null,
    firstSeenAt: DateTime.utc(2026, 9, 20),
  ),
);
