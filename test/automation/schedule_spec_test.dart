import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/missed_run_policy.dart';
import 'package:void_scriptor/automation/schedule_spec.dart';

/// Sprint 104 / 104.9 — schedules run through ONE canonical spec with an
/// explicit timezone offset and a computable next run.
void main() {
  // 2026-08-24 03:00 UTC == 10:00 WIB (+07:00).
  final anchor = DateTime.utc(2026, 8, 24, 3, 0);

  group('dailyAt', () {
    final nineJakarta = ScheduleSpec.dailyAt(
      hour: 9,
      minute: 0,
      timeZoneOffsetMinutes: 420,
    );

    test(
      'computes the next run inside the same local day before fire time',
      () {
        // Local time 06:30 → fires today 09:00 local (02:00 UTC).
        final next = nineJakarta.nextRunAfter(
          anchor.subtract(const Duration(minutes: 90)),
        );
        expect(next.toUtc(), DateTime.utc(2026, 8, 24, 2, 0));
      },
    );

    test('rolls to tomorrow when the moment already passed locally', () {
      // Local 10:00 → next fire is tomorrow 09:00 local.
      final next = nineJakarta.nextRunAfter(anchor);
      expect(next.toUtc(), DateTime.utc(2026, 8, 25, 2, 0));
    });

    test('is deterministic across repeated evaluation', () {
      expect(
        nineJakarta.nextRunAfter(anchor),
        nineJakarta.nextRunAfter(anchor),
      );
    });
  });

  test('interval schedules advance by exact multiples', () {
    final everyHour = ScheduleSpec.every(const Duration(hours: 1));
    expect(everyHour.nextRunAfter(anchor), DateTime.utc(2026, 8, 24, 4, 0));
  });

  test('rejects invalid construction fail-closed', () {
    expect(
      () => ScheduleSpec.dailyAt(hour: 24, minute: 0),
      throwsArgumentError,
    );
    expect(() => ScheduleSpec.every(Duration.zero), throwsArgumentError);
    expect(
      () => ScheduleSpec.every(const Duration(minutes: -5)),
      throwsArgumentError,
    );
  });

  test('carries missed-run policy and enabled flag canonically', () {
    final spec = ScheduleSpec.every(
      const Duration(hours: 2),
      missedRunPolicy: MissedRunPolicy.runOnceAtStartup,
      enabled: false,
    );
    expect(spec.missedRunPolicy, MissedRunPolicy.runOnceAtStartup);
    expect(spec.enabled, isFalse);
    expect(spec.timeZoneOffsetMinutes, 0, reason: 'UTC default');
  });
}
