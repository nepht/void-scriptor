import 'account_center_session_device_management.dart';
import 'account_center_security_summary.dart';

/// What aggregating trusted-device sessions actually proves.
///
/// [DeviceSecuritySummary] takes a `status` and a `count` from its caller, and
/// nothing in the shipped code connects those two fields to the sessions they
/// are supposed to describe. A caller could report one trusted device while
/// three active sessions were untrusted, or report `healthy` with no sessions
/// at all, and no code would object: the count and the status were both
/// assertions rather than readings.
///
/// This aggregator is that missing reading. It derives the count and the status
/// from the sessions themselves, so the panel describes the sessions that exist
/// rather than what a caller hoped they were.
final class TrustedDeviceAggregator {
  const TrustedDeviceAggregator();

  /// The trust state of the whole account, judged across every session.
  ///
  /// A revoked session is excluded: it is history, not a standing grant of
  /// access, and counting it would let an account look more trusted after the
  /// user revoked something than before.
  SessionTrustState aggregateTrust(
    Iterable<ManagedSession> sessions, {
    required SessionTrustState whenEmpty,
  }) {
    final active = sessions
        .where((session) => session.state == SessionActivityState.active)
        .toList();
    if (active.isEmpty) return whenEmpty;

    // `unknown` is not a quiet pass. If any active session's trust could not be
    // read, the aggregate cannot claim to be clean, so it stays `unknown`
    // rather than being decided by the sessions that happened to be readable.
    if (active.any((session) => session.trust == SessionTrustState.unknown)) {
      return SessionTrustState.unknown;
    }
    // One untrusted active session is enough: trust is a floor, not an average,
    // and an account with a single unknown door is not a trusted account.
    if (active.any((session) => session.trust == SessionTrustState.untrusted)) {
      return SessionTrustState.untrusted;
    }
    return SessionTrustState.trusted;
  }

  /// How many active sessions are trusted right now.
  int trustedCount(Iterable<ManagedSession> sessions) => sessions
      .where(
        (session) =>
            session.state == SessionActivityState.active &&
            session.trust == SessionTrustState.trusted,
      )
      .length;

  /// The security signal for the trusted-devices panel, computed.
  ///
  /// `critical` is reserved for a suspicious session, because that is the fact
  /// that warrants action rather than review. Everything else follows from the
  /// aggregate: no readable session is `unknown`, a partial read is `attention`
  /// rather than a pass, and only a fully trusted active set is `healthy`.
  SecuritySignalStatus statusOf(
    Iterable<ManagedSession> sessions, {
    required SessionTrustState whenEmpty,
  }) {
    final active = sessions
        .where((session) => session.state == SessionActivityState.active)
        .toList();
    if (active.isEmpty) return SecuritySignalStatus.unavailable;
    if (active.any((session) => session.suspicious)) {
      return SecuritySignalStatus.critical;
    }

    final unreadable = active
        .where((session) => session.trust == SessionTrustState.unknown)
        .length;
    if (unreadable == active.length) return SecuritySignalStatus.unknown;
    if (unreadable > 0) return SecuritySignalStatus.attention;

    return switch (aggregateTrust(sessions, whenEmpty: whenEmpty)) {
      SessionTrustState.trusted => SecuritySignalStatus.healthy,
      SessionTrustState.untrusted => SecuritySignalStatus.attention,
      SessionTrustState.unknown => SecuritySignalStatus.unknown,
    };
  }

  /// A device summary rebuilt from the sessions that exist.
  ///
  /// [DeviceSecuritySummary] refuses a known status without a count, so the
  /// count comes from the same sessions the status came from - the two can no
  /// longer describe different worlds.
  DeviceSecuritySummary reconcile(
    Iterable<ManagedSession> sessions, {
    required SessionTrustState whenEmpty,
  }) => DeviceSecuritySummary(
    status: statusOf(sessions, whenEmpty: whenEmpty),
    count: trustedCount(sessions),
  );

  /// Whether a supplied panel agrees with the sessions behind it.
  bool agreesWithSessions(
    DeviceSecuritySummary summary,
    Iterable<ManagedSession> sessions, {
    required SessionTrustState whenEmpty,
  }) =>
      reconcile(sessions, whenEmpty: whenEmpty).status == summary.status &&
      summary.count == trustedCount(sessions);

  /// Session ids whose trust contradicts the panel's claim.
  ///
  /// [AccountCenterSessionDeviceManagement.trustSession] already refuses to
  /// trust a suspicious session, so the contradiction this surfaces is narrower
  /// than it looks: it is the trusted panel claiming a count that the session
  /// list cannot support, which is the shape of a stale or fabricated panel.
  List<String> contradictionsFor(
    DeviceSecuritySummary summary,
    Iterable<ManagedSession> sessions, {
    required SessionTrustState whenEmpty,
  }) {
    final reconciled = reconcile(sessions, whenEmpty: whenEmpty);
    if (reconciled.status == summary.status &&
        reconciled.count == summary.count) {
      return const <String>[];
    }
    final flagged =
        sessions
            .where(
              (session) =>
                  session.state == SessionActivityState.active &&
                  session.trust != SessionTrustState.trusted,
            )
            .map((session) => session.sessionId)
            .toList()
          ..sort();
    return List.unmodifiable(flagged);
  }
}
