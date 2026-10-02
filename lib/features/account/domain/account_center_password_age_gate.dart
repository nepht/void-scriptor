import 'account_center_security_summary.dart';

/// How long a password may go unchanged before the account needs attention.
///
/// These are policy, not fact, so they are declared in one place instead of
/// being re-derived - and possibly re-derived differently - by each caller.
final class PasswordAgePolicy {
  /// Stored as whole days rather than [Duration] because a [Duration] property
  /// cannot be read inside a const expression, and a policy constant should be
  /// const so it can be compared cheaply on every verdict.
  const PasswordAgePolicy({
    required this.reviewAfterDays,
    required this.criticalAfterDays,
  }) : assert(reviewAfterDays > 0),
       assert(criticalAfterDays > reviewAfterDays);

  final int reviewAfterDays;
  final int criticalAfterDays;

  Duration get reviewAfter => Duration(days: reviewAfterDays);
  Duration get criticalAfter => Duration(days: criticalAfterDays);

  /// The policy a shipped account starts from: a year is due for review, five
  /// is long enough that a breach elsewhere should have forced a change.
  static const PasswordAgePolicy standard = PasswordAgePolicy(
    reviewAfterDays: 365,
    criticalAfterDays: 1825,
  );
}

/// What the password signal actually is, derived from its timestamp.
enum PasswordAgeVerdict {
  /// Changed recently enough to need no action.
  current,

  /// Older than [PasswordAgePolicy.reviewAfter] but not yet
  /// [PasswordAgePolicy.criticalAfter].
  stale,

  /// Older than [PasswordAgePolicy.criticalAfter].
  overdue,

  /// The timestamp was never recorded, so nothing can be claimed.
  unknown,
}

/// The security signal a password timestamp deserves, and the arithmetic behind
/// it.
///
/// [PasswordSecuritySummary] validates that `changedAt` is UTC and then stops:
/// nothing ever read it to decide whether the password was old. The status was
/// supplied by the caller instead, which means a caller could report `healthy`
/// for a password last changed in 2019 while carrying a perfectly valid
/// timestamp in the very same object - the field carrying the evidence was
/// never consulted about the claim made beside it.
///
/// This gate is that missing reader. It derives the status from the timestamp
/// and the policy, so the two can no longer disagree, and it is deliberately
/// built so a caller cannot quietly opt out: `healthy` is only reachable from a
/// timestamp that is actually recent.
///
/// Age is judged against a clock the caller supplies, never `DateTime.now()`,
/// so a verdict is reproducible and testable; [advanceTo] moves that clock for
/// tests without a wall-clock dependency.
final class PasswordSecurityGate {
  PasswordSecurityGate({
    this.policy = PasswordAgePolicy.standard,
    DateTime? now,
  }) : _constructedAt = (now ?? DateTime.now()).toUtc();

  final PasswordAgePolicy policy;

  /// The clock captured at construction; [advanceTo] overrides it for tests so
  /// a verdict never depends on a second boundary crossing mid-test.
  final DateTime _constructedAt;
  DateTime? _overriddenClock;

  /// The clock this gate judges against, in UTC.
  DateTime get now => _overriddenClock ?? _constructedAt;

  /// Move the gate's clock forward, for tests.
  ///
  /// @visibleForTesting
  void advanceTo(DateTime at) {
    _overriddenClock = at.toUtc();
  }

  /// How long ago the password was changed, or null when never recorded.
  Duration? ageOf(PasswordSecuritySummary password) {
    final changedAt = password.changedAt;
    if (changedAt == null) return null;
    final age = now.difference(changedAt.toUtc());
    // A timestamp in the future is not a young password, it is a clock that
    // disagrees. Clamping to zero would report it as current, which is the
    // reading that fails open.
    return age.isNegative ? null : age;
  }

  /// The verdict for one password, derived rather than supplied.
  PasswordAgeVerdict classify(PasswordSecuritySummary password) {
    final age = ageOf(password);
    if (age == null) {
      final timestamp = password.changedAt;
      // A future timestamp means the value is unreliable, not recent.
      if (timestamp != null && now.difference(timestamp.toUtc()).isNegative) {
        return PasswordAgeVerdict.unknown;
      }
      return PasswordAgeVerdict.unknown;
    }
    if (age >= policy.criticalAfter) return PasswordAgeVerdict.overdue;
    if (age >= policy.reviewAfter) return PasswordAgeVerdict.stale;
    return PasswordAgeVerdict.current;
  }

  /// The security signal this password deserves, computed from the timestamp.
  ///
  /// The mapping is total and one-way: a caller cannot pass a `healthy` status
  /// next to a six-year-old timestamp and have it stand, and a caller cannot
  /// invent `unknown` for a timestamp that clearly reads stale.
  SecuritySignalStatus statusOf(PasswordSecuritySummary password) =>
      switch (classify(password)) {
        PasswordAgeVerdict.current => SecuritySignalStatus.healthy,
        PasswordAgeVerdict.stale => SecuritySignalStatus.attention,
        PasswordAgeVerdict.overdue => SecuritySignalStatus.critical,
        PasswordAgeVerdict.unknown => SecuritySignalStatus.unknown,
      };

  /// Whether the summary's supplied status agrees with what its own timestamp
  /// proves, so a caller can be told rather than trusted.
  ///
  /// A disagreement is not automatically a fault in the caller - the status may
  /// come from a policy this gate was not given - but it must be visible, since
  /// a summary whose two halves contradict each other cannot be rendered
  /// honestly.
  bool agreesWithTimestamp(PasswordSecuritySummary password) =>
      statusOf(password) == password.status;

  /// Every password in a set whose stated status contradicts its timestamp.
  List<String> contradictoryPasswordIds(
    Map<String, PasswordSecuritySummary> passwords,
  ) {
    final contradictions =
        passwords.entries
            .where((entry) => !agreesWithTimestamp(entry.value))
            .map((entry) => entry.key)
            .toList()
          ..sort();
    return List.unmodifiable(contradictions);
  }

  /// A summary rebuilt with its status taken from its own timestamp.
  ///
  /// This is how a caller stops supplying the verdict: the evidence decides,
  /// and the object stops being able to disagree with itself.
  PasswordSecuritySummary reconcile(PasswordSecuritySummary password) =>
      PasswordSecuritySummary(
        status: statusOf(password),
        changedAt: password.changedAt,
      );
}
