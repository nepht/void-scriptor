library;

import 'missed_run_policy.dart';

/// Sprint 104 / 104.9 — ONE canonical schedule specification with an
/// explicit timezone offset and a computable next run.
///
/// Timezone is expressed as a fixed UTC offset in minutes (e.g. +420 for
/// Asia/Jakarta). A full IANA zone database (DST history) is deliberately
/// out of scope for the automation core; callers that need named zones
/// resolve them to an offset at configuration time.

class ScheduleSpec {
  const ScheduleSpec._({
    required this.kind,
    required this.hour,
    required this.minute,
    required this.interval,
    this.timeZoneOffsetMinutes = 0,
    this.missedRunPolicy = MissedRunPolicy.skip,
    this.enabled = true,
  });

  /// Daily at [hour]:[minute] in the spec's fixed UTC offset. Throws
  /// ArgumentError on invalid wall-clock values (fail-closed).
  factory ScheduleSpec.dailyAt({
    required int hour,
    required int minute,
    int timeZoneOffsetMinutes = 0,
    MissedRunPolicy missedRunPolicy = MissedRunPolicy.skip,
    bool enabled = true,
  }) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'must be 0..23');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'must be 0..59');
    }
    return ScheduleSpec._(
      kind: _kindDaily,
      hour: hour,
      minute: minute,
      interval: Duration.zero,
      timeZoneOffsetMinutes: timeZoneOffsetMinutes,
      missedRunPolicy: missedRunPolicy,
      enabled: enabled,
    );
  }

  /// Fixed-interval schedule. The interval must be strictly positive.
  factory ScheduleSpec.every(
    Duration interval, {
    int timeZoneOffsetMinutes = 0,
    MissedRunPolicy missedRunPolicy = MissedRunPolicy.skip,
    bool enabled = true,
  }) {
    if (interval <= Duration.zero) {
      throw ArgumentError.value(interval, 'interval', 'must be positive');
    }
    return ScheduleSpec._(
      kind: _kindInterval,
      hour: -1,
      minute: -1,
      interval: interval,
      timeZoneOffsetMinutes: timeZoneOffsetMinutes,
      missedRunPolicy: missedRunPolicy,
      enabled: enabled,
    );
  }

  static const _kindDaily = 'dailyAt';
  static const _kindInterval = 'every';

  final String kind;
  final int hour;
  final int minute;

  /// Zero for daily specs.
  final Duration interval;
  final int timeZoneOffsetMinutes;
  final MissedRunPolicy missedRunPolicy;
  final bool enabled;

  /// The next instant strictly after [after], computed in the spec's
  /// timezone so "daily at 09:00 local" stays local across UTC shifts.
  DateTime nextRunAfter(DateTime after) {
    if (kind == _kindInterval) {
      return after.toUtc().add(interval);
    }
    // Daily: work in the spec's local wall clock.
    final offset = Duration(minutes: timeZoneOffsetMinutes);
    final local = after.toUtc().add(offset);
    var candidateLocal = DateTime.utc(
      local.year,
      local.month,
      local.day,
      hour,
      minute,
    );
    if (!candidateLocal.isAfter(local)) {
      candidateLocal = candidateLocal.add(const Duration(days: 1));
    }
    return candidateLocal.subtract(offset);
  }

  /// Whether the schedule was missed as of [now] (only meaningful when
  /// the app was not running; see MissedRunPolicy).
  bool isMissed(DateTime scheduledFor, DateTime now) =>
      now.isAfter(scheduledFor);
}
