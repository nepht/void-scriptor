import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_security_summary.dart';
import 'package:void_scriptor/features/account/domain/account_center_session_device_management.dart';
import 'package:void_scriptor/features/account/domain/account_center_trusted_device_aggregator.dart';

/// Closes the 117.20 open item for device trust. `DeviceSecuritySummary` took
/// both its status and its count from the caller, and nothing connected either
/// field to the sessions they claim to describe - so a panel could report one
/// trusted device while three active sessions were untrusted.
void main() {
  const aggregator = TrustedDeviceAggregator();

  group('TrustedDeviceAggregator derives the panel from the sessions', () {
    test('all-trusted active sessions are healthy and counted', () {
      final sessions = [
        _session(id: 'a', trust: SessionTrustState.trusted),
        _session(id: 'b', trust: SessionTrustState.trusted),
      ];

      final summary = aggregator.reconcile(
        sessions,
        whenEmpty: SessionTrustState.unknown,
      );

      expect(summary.status, SecuritySignalStatus.healthy);
      expect(summary.count, 2);
    });

    test('one untrusted active session makes the panel unhealthy', () {
      final sessions = [
        _session(id: 'a', trust: SessionTrustState.trusted),
        _session(id: 'b', trust: SessionTrustState.untrusted),
      ];

      final summary = aggregator.reconcile(
        sessions,
        whenEmpty: SessionTrustState.unknown,
      );

      expect(summary.status, SecuritySignalStatus.attention);
      expect(summary.count, 1);
    });

    test('a partly unreadable set is attention, not a pass', () {
      final sessions = [
        _session(id: 'a', trust: SessionTrustState.trusted),
        _session(id: 'b', trust: SessionTrustState.unknown),
      ];

      final summary = aggregator.reconcile(
        sessions,
        whenEmpty: SessionTrustState.unknown,
      );

      expect(summary.status, SecuritySignalStatus.attention);
      expect(summary.count, 1);
    });

    test('a fully unreadable set is unknown', () {
      final sessions = [
        _session(id: 'a', trust: SessionTrustState.unknown),
        _session(id: 'b', trust: SessionTrustState.unknown),
      ];

      final summary = aggregator.reconcile(
        sessions,
        whenEmpty: SessionTrustState.unknown,
      );

      expect(summary.status, SecuritySignalStatus.unknown);
      expect(summary.count, 0);
    });

    test('a suspicious active session is critical', () {
      final sessions = [
        _session(id: 'a', trust: SessionTrustState.trusted),
        _session(id: 'b', trust: SessionTrustState.untrusted, suspicious: true),
      ];

      final summary = aggregator.reconcile(
        sessions,
        whenEmpty: SessionTrustState.unknown,
      );

      expect(summary.status, SecuritySignalStatus.critical);
    });

    test('revoked sessions are excluded from trust and count', () {
      final sessions = [
        _session(id: 'a', trust: SessionTrustState.trusted),
        _session(
          id: 'b',
          trust: SessionTrustState.untrusted,
          state: SessionActivityState.revoked,
        ),
        _session(
          id: 'c',
          trust: SessionTrustState.trusted,
          state: SessionActivityState.revoked,
        ),
      ];

      final summary = aggregator.reconcile(
        sessions,
        whenEmpty: SessionTrustState.unknown,
      );

      // Revoking an untrusted session must not make the account look worse, and
      // a revoked trusted session must not keep counting as a live grant.
      expect(summary.status, SecuritySignalStatus.healthy);
      expect(summary.count, 1);
    });

    test('no active session is unavailable, not healthy', () {
      final summary = aggregator.reconcile(
        const <ManagedSession>[],
        whenEmpty: SessionTrustState.unknown,
      );

      expect(summary.status, SecuritySignalStatus.unavailable);
      expect(summary.count, 0);
    });

    test('the empty-case trust value is returned when asked directly', () {
      expect(
        aggregator.aggregateTrust(
          const <ManagedSession>[],
          whenEmpty: SessionTrustState.untrusted,
        ),
        SessionTrustState.untrusted,
      );
    });

    test('a revoked-only account does not report a trust level it lacks', () {
      final sessions = [
        _session(
          id: 'revoked-a',
          trust: SessionTrustState.trusted,
          state: SessionActivityState.revoked,
        ),
      ];

      expect(
        aggregator.aggregateTrust(
          sessions,
          whenEmpty: SessionTrustState.unknown,
        ),
        SessionTrustState.unknown,
      );
    });

    test('an unreadable session blocks a trusted aggregate', () {
      final sessions = [
        _session(id: 'a', trust: SessionTrustState.trusted),
        _session(id: 'b', trust: SessionTrustState.unknown),
      ];

      // The readable session is trusted, but the aggregate must not claim the
      // account is clean while a second session could not be read.
      expect(
        aggregator.aggregateTrust(
          sessions,
          whenEmpty: SessionTrustState.unknown,
        ),
        SessionTrustState.unknown,
      );
    });
  });

  group('a supplied panel can be checked against the sessions', () {
    test('a panel matching the sessions agrees', () {
      final sessions = [_session(id: 'a', trust: SessionTrustState.trusted)];

      expect(
        aggregator.agreesWithSessions(
          DeviceSecuritySummary(status: SecuritySignalStatus.healthy, count: 1),
          sessions,
          whenEmpty: SessionTrustState.unknown,
        ),
        isTrue,
      );
    });

    test('a panel overstating trust is reported as disagreeing', () {
      final sessions = [
        _session(id: 'a', trust: SessionTrustState.trusted),
        _session(id: 'b', trust: SessionTrustState.untrusted),
      ];

      expect(
        aggregator.agreesWithSessions(
          DeviceSecuritySummary(status: SecuritySignalStatus.healthy, count: 2),
          sessions,
          whenEmpty: SessionTrustState.unknown,
        ),
        isFalse,
      );
    });

    test('a panel with the right status but wrong count is caught', () {
      final sessions = [_session(id: 'a', trust: SessionTrustState.trusted)];

      expect(
        aggregator.agreesWithSessions(
          DeviceSecuritySummary(status: SecuritySignalStatus.healthy, count: 4),
          sessions,
          whenEmpty: SessionTrustState.unknown,
        ),
        isFalse,
      );
    });

    test('contradictions name the active sessions that are not trusted', () {
      final sessions = [
        _session(id: 'a', trust: SessionTrustState.trusted),
        _session(id: 'z', trust: SessionTrustState.untrusted),
        _session(id: 'b', trust: SessionTrustState.unknown),
        _session(
          id: 'r',
          trust: SessionTrustState.untrusted,
          state: SessionActivityState.revoked,
        ),
      ];

      final flagged = aggregator.contradictionsFor(
        DeviceSecuritySummary(status: SecuritySignalStatus.healthy, count: 3),
        sessions,
        whenEmpty: SessionTrustState.unknown,
      );

      expect(flagged, ['b', 'z']);
    });

    test('an agreeing panel lists no contradictions', () {
      final sessions = [_session(id: 'a', trust: SessionTrustState.trusted)];

      expect(
        aggregator.contradictionsFor(
          DeviceSecuritySummary(status: SecuritySignalStatus.healthy, count: 1),
          sessions,
          whenEmpty: SessionTrustState.unknown,
        ),
        isEmpty,
      );
    });
  });
}

ManagedSession _session({
  required String id,
  required SessionTrustState trust,
  SessionActivityState state = SessionActivityState.active,
  bool suspicious = false,
}) => ManagedSession(
  sessionId: id,
  // The current session can never be revoked (ManagedSession forbids it), so a
  // revoked fixture must not also claim to be current.
  isCurrent: id == 'a' && state == SessionActivityState.active,
  lastActiveAt: DateTime.utc(2026, 10, 1),
  trust: trust,
  state: state,
  suspicious: suspicious,
  device: DeviceDetails(
    deviceLabel: 'Device $id',
    platform: SessionDevicePlatform.windows,
  ),
  trustedAt: trust == SessionTrustState.trusted
      ? DateTime.utc(2026, 9, 1)
      : null,
  revokedAt: state == SessionActivityState.revoked
      ? DateTime.utc(2026, 9, 2)
      : null,
);
