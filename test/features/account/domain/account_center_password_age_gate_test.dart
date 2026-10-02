import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_password_age_gate.dart';
import 'package:void_scriptor/features/account/domain/account_center_security_summary.dart';

/// Closes the 117.20 open item for password age. `changedAt` was validated as
/// UTC and then never read: nothing decided whether the password was old, and
/// the status was whatever the caller supplied - so a caller could carry a
/// perfectly valid six-year-old timestamp beside a `healthy` status and no code
/// would object.
void main() {
  PasswordSecurityGate gateAt(DateTime now) => PasswordSecurityGate(now: now);

  group('PasswordSecurityGate reads the timestamp nothing else read', () {
    test('a recent password is healthy', () {
      final gate = gateAt(DateTime.utc(2026, 10, 2));
      final password = PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(2026, 9, 2),
      );

      expect(gate.classify(password), PasswordAgeVerdict.current);
      expect(gate.statusOf(password), SecuritySignalStatus.healthy);
    });

    test('a password past the review window needs attention', () {
      final gate = gateAt(DateTime.utc(2026, 10, 2));
      final password = PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(2025, 1, 1),
      );

      expect(gate.classify(password), PasswordAgeVerdict.stale);
      expect(gate.statusOf(password), SecuritySignalStatus.attention);
    });

    test('a very old password is critical', () {
      final gate = gateAt(DateTime.utc(2026, 10, 2));
      final password = PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(2019, 6, 1),
      );

      expect(gate.classify(password), PasswordAgeVerdict.overdue);
      expect(gate.statusOf(password), SecuritySignalStatus.critical);
    });

    test('an unrecorded password is unknown, never healthy', () {
      final gate = gateAt(DateTime.utc(2026, 10, 2));
      final password = PasswordSecuritySummary(
        status: SecuritySignalStatus.unknown,
        changedAt: null,
      );

      expect(gate.classify(password), PasswordAgeVerdict.unknown);
      expect(gate.statusOf(password), SecuritySignalStatus.unknown);
    });

    test('the review boundary itself counts as stale, not current', () {
      final gate = gateAt(DateTime.utc(2026, 10, 2));
      final password = PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(
          2026,
          10,
          2,
        ).subtract(const Duration(days: 365)),
      );

      expect(gate.classify(password), PasswordAgeVerdict.stale);
    });

    test('the critical boundary itself counts as overdue', () {
      final gate = gateAt(DateTime.utc(2026, 10, 2));
      final password = PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(
          2026,
          10,
          2,
        ).subtract(const Duration(days: 1825)),
      );

      expect(gate.classify(password), PasswordAgeVerdict.overdue);
    });

    test('a password changed in the future is unknown, not young', () {
      final gate = gateAt(DateTime.utc(2026, 10, 2));
      final password = PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(2027, 1, 1),
      );

      // Clamping the negative age to zero would report this as `current`,
      // which fails open on a clock that disagrees with the record.
      expect(gate.ageOf(password), isNull);
      expect(gate.classify(password), PasswordAgeVerdict.unknown);
      expect(gate.statusOf(password), SecuritySignalStatus.unknown);
    });

    test('a caller cannot keep healthy next to an old timestamp', () {
      final gate = gateAt(DateTime.utc(2026, 10, 2));
      final password = PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(2019, 1, 1),
      );

      expect(gate.agreesWithTimestamp(password), isFalse);
    });

    test('reconcile rebuilds the summary from its own evidence', () {
      final gate = gateAt(DateTime.utc(2026, 10, 2));
      final password = PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(2019, 1, 1),
      );

      final reconciled = gate.reconcile(password);

      expect(reconciled.status, SecuritySignalStatus.critical);
      expect(reconciled.changedAt, DateTime.utc(2019, 1, 1));
      expect(gate.agreesWithTimestamp(reconciled), isTrue);
    });

    test('contradicting summaries are reported by id, in order', () {
      final gate = gateAt(DateTime.utc(2026, 10, 2));
      final passwords = {
        'primary': PasswordSecuritySummary(
          status: SecuritySignalStatus.healthy,
          changedAt: DateTime.utc(2019, 1, 1),
        ),
        'archive': PasswordSecuritySummary(
          status: SecuritySignalStatus.healthy,
          changedAt: DateTime.utc(2026, 9, 1),
        ),
        'shared': PasswordSecuritySummary(
          status: SecuritySignalStatus.unknown,
          changedAt: DateTime.utc(2015, 1, 1),
        ),
      };

      expect(gate.contradictoryPasswordIds(passwords), ['primary', 'shared']);
    });

    test('advanceTo moves the clock without touching the constructor time', () {
      final gate = gateAt(DateTime.utc(2026, 1, 1));
      final password = PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(2026, 1, 1),
      );
      expect(gate.statusOf(password), SecuritySignalStatus.healthy);

      // 2026-01-01 to 2032-01-01 is six years, past the five-year critical mark.
      gate.advanceTo(DateTime.utc(2032, 1, 1));

      expect(gate.statusOf(password), SecuritySignalStatus.critical);
      expect(gate.now, DateTime.utc(2032, 1, 1));
    });

    test('the verdict depends on the supplied clock, not the wall clock', () {
      final password = PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(2015, 5, 5),
      );

      final fresh = gateAt(DateTime.utc(2015, 5, 6));
      final old = gateAt(DateTime.utc(2030, 5, 5));

      expect(fresh.statusOf(password), SecuritySignalStatus.healthy);
      expect(old.statusOf(password), SecuritySignalStatus.critical);
    });

    test('a custom policy moves the boundary rather than the status', () {
      final password = PasswordSecuritySummary(
        status: SecuritySignalStatus.healthy,
        changedAt: DateTime.utc(2026, 1, 1),
      );
      final strict = PasswordSecurityGate(
        policy: const PasswordAgePolicy(
          reviewAfterDays: 30,
          criticalAfterDays: 60,
        ),
        now: DateTime.utc(2026, 10, 2),
      );
      final lenient = PasswordSecurityGate(
        policy: const PasswordAgePolicy(
          reviewAfterDays: 3650,
          criticalAfterDays: 7300,
        ),
        now: DateTime.utc(2026, 10, 2),
      );

      expect(strict.statusOf(password), SecuritySignalStatus.critical);
      expect(lenient.statusOf(password), SecuritySignalStatus.healthy);
    });

    test('an invalid policy is refused at construction', () {
      expect(
        () => PasswordAgePolicy(reviewAfterDays: 365, criticalAfterDays: 365),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PasswordAgePolicy(reviewAfterDays: 0, criticalAfterDays: 10),
        throwsA(isA<AssertionError>()),
      );
    });

    test('every verdict is reachable and total', () {
      final gate = gateAt(DateTime.utc(2026, 10, 2));
      final cases = <DateTime?, PasswordAgeVerdict>{
        DateTime.utc(2026, 10, 1): PasswordAgeVerdict.current,
        DateTime.utc(2025, 1, 1): PasswordAgeVerdict.stale,
        DateTime.utc(2019, 1, 1): PasswordAgeVerdict.overdue,
        null: PasswordAgeVerdict.unknown,
        DateTime.utc(2027, 1, 1): PasswordAgeVerdict.unknown,
      };

      for (final entry in cases.entries) {
        final password = PasswordSecuritySummary(
          status: SecuritySignalStatus.unknown,
          changedAt: entry.key,
        );
        expect(
          gate.classify(password),
          entry.value,
          reason: 'changedAt=${entry.key}',
        );
      }
    });
  });
}
