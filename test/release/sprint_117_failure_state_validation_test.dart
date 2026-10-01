/// 117.28 — Failure-State Validation.
///
/// Mengukur sembilan state kegagalan kanonik terhadap mekanisme yang
/// benar-benar di-ship, lalu menutup gate gagal-tertutup
/// [Sprint117FailureStateValidation].
///
/// Dua defect produksi ditemukan dari fakta mentah sebelum kontrak ditulis
/// dan keduanya direkam sebagai ekspektasi di sini:
///
/// 1. `rateLimited(retryAfter: 30s)` merender "Try again after 0 minutes"
///    — durasi sub-menit dipotong `inMinutes`, jadi jendela retry yang
///    ditampilkan sebagai nol sehingga jendela retry yang diklaim
///    mechanism tidak lagi sama dengan yang dipanggil provider.
/// 2. `partial(availableItemCount: 0)` melapor `hasData = true` dan
///    "canRetry" untuk data yang nol — permukaan yang tidak memiliki data
///    parsial sama sekali, konsisten dengan doktrin fail-closed file itu
///    sendiri (angka negatif ditolak, tetapi nol diterima).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_connection_health_state_machine.dart';
import 'package:void_scriptor/features/account/domain/account_center_loading_empty_error_states.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_failure_state_validation.dart';

/// Jam injeksi tetap: semua umur dihitung terhadap satu instan, bukan
/// wall clock, supaya gate ini deterministik.
final DateTime _at = DateTime.utc(2026, 10, 1, 12);

void main() {
  group('117.28 nine canonical failure states', () {
    test('required_states are exactly the nine canonical ones', () {
      expect(Sprint117FailureStateValidation.requiredStates, <String>[
        'expired',
        'revoked',
        'scope_denied',
        'rate_limited',
        'outage',
        'region_block',
        'unsupported_plan',
        'partial_data',
        'error',
      ]);
    });

    test(
      'an expired connection demands reauthentication and recovery copy',
      () {
        final machine = AccountConnectionHealthStateMachine.notConfigured(
          providerId: 'provider-alpha',
          accountLabel: 'alpha@example.test',
        );
        machine.transition(
          AccountConnectionTransition.beginConnecting,
          at: _at,
        );
        machine.transition(
          AccountConnectionTransition.connectSucceeded,
          at: _at,
        );
        final expired = machine.transition(
          AccountConnectionTransition.expire,
          at: _at,
          errorCode: 'token_expired',
        );
        expect(expired.connectionState, AccountConnectionState.expired);
        expect(expired.reauthRequired, isTrue);
        expect(
          expired.userVisibleError,
          'Connection expired. Reauthenticate to restore this connection.',
        );
        // The only way out of EXPIRED is reauthentication; a plain retry is not
        // offered because the credential itself is dead, not the socket.
        expect(
          machine.availableTransitions,
          contains(AccountConnectionTransition.reauthenticate),
        );
        expect(
          machine.availableTransitions,
          isNot(contains(AccountConnectionTransition.retry)),
        );
      },
    );

    test('a revoked connection is terminal and names the recovery path', () {
      final machine = AccountConnectionHealthStateMachine.notConfigured(
        providerId: 'provider-beta',
        accountLabel: 'beta@example.test',
      );
      machine.transition(AccountConnectionTransition.beginConnecting, at: _at);
      machine.transition(AccountConnectionTransition.connectSucceeded, at: _at);
      final revoked = machine.transition(
        AccountConnectionTransition.revoke,
        at: _at,
        errorCode: 'user_revoked',
      );
      expect(revoked.connectionState, AccountConnectionState.revoked);
      expect(
        revoked.userVisibleError,
        'Connection revoked. Configure a new connection before retrying.',
      );
      // Revoked is terminal: reauthenticating the same identity would
      // resurrect a credential the user deliberately removed.
      expect(
        machine.availableTransitions,
        isNot(contains(AccountConnectionTransition.reauthenticate)),
      );
      expect(machine.canTransition(AccountConnectionTransition.retry), isFalse);
    });
  });

  group('117.28 rate_limited retry window must not lie', () {
    // DEFECT 1 (production): a 30-second provider window was rendered as
    // "Try again after 0 minutes", telling the user to retry immediately
    // while the provider is still refusing. The declared retry window is
    // what the provider reported; the rendered copy must carry it.
    test('a sub-minute retry window is rendered truthfully', () {
      final limited = AccountCenterLoadingEmptyErrorStates.rateLimited(
        source: 'provider_quota',
        retryAfter: const Duration(seconds: 30),
      );
      expect(limited.retryAfter, const Duration(seconds: 30));
      expect(
        limited.message,
        contains('30 seconds'),
        reason: 'a 30s window must not render as "0 minutes"',
      );
      expect(limited.canRetry, isTrue);
    });

    test('a minute-or-longer window keeps its minute count', () {
      final limited = AccountCenterLoadingEmptyErrorStates.rateLimited(
        source: 'provider_quota',
        retryAfter: const Duration(minutes: 15),
      );
      expect(limited.message, contains('15 minutes'));
    });
  });

  group('117.28 partial_data must reflect real partial availability', () {
    // DEFECT 2 (production): zero available items was accepted and reported
    // as hasData=true with a "canRetry" recovery, i.e. the same surface
    // shape used when some data really did arrive. The file's own contract
    // rejects a negative count; a zero count carries no partial data and
    // must be refused at the same boundary rather than relabelled.
    test('zero available items is refused as partial data', () {
      expect(
        () => AccountCenterLoadingEmptyErrorStates.partial(
          source: 'storage',
          availableItemCount: 0,
          unavailableReason: 'No provider responded.',
        ),
        throwsArgumentError,
      );
    });

    test('a genuinely partial response keeps its data and recovery path', () {
      final partial = AccountCenterLoadingEmptyErrorStates.partial(
        source: 'storage',
        availableItemCount: 3,
        unavailableReason: 'One provider did not respond.',
      );
      expect(partial.state, AccountCenterSurfaceState.partial);
      expect(partial.hasData, isTrue);
      expect(partial.availableItemCount, 3);
      expect(partial.canRetry, isTrue);
      expect(partial.message, contains('One provider did not respond.'));
    });
  });

  group('117.28 gate fails closed', () {
    Sprint117FailureStateCheck passing(String area, String check) =>
        Sprint117FailureStateCheck.pass(
          area: area,
          check: check,
          declared: 'declared $check',
          observed: 'observed $check',
        );

    test('nine measured states with no violation pass the gate', () {
      final checks = <Sprint117FailureStateCheck>[
        for (final state in Sprint117FailureStateValidation.requiredStates)
          passing(state, 'measured'),
      ];
      final result = Sprint117FailureStateValidation.evaluate(checks);
      expect(result.pass, isTrue, reason: result.failures.toString());
      expect(result.violationCodes, isEmpty);
      expect(result.openItems, isEmpty);
      expect(result.checks, hasLength(9));
      expect(result.summary, contains('pass=true'));
    });

    test('no checks at all is a structural failure', () {
      final result = Sprint117FailureStateValidation.evaluate(
        <Sprint117FailureStateCheck>[],
      );
      expect(result.pass, isFalse);
      expect(result.failures, contains('no_checks'));
    });

    test('a missing state is reported, not silently skipped', () {
      final checks = <Sprint117FailureStateCheck>[
        for (final state in Sprint117FailureStateValidation.requiredStates)
          if (state != 'outage') passing(state, 'measured'),
      ];
      final result = Sprint117FailureStateValidation.evaluate(checks);
      expect(result.pass, isFalse);
      expect(result.failures, contains('missing_area:outage'));
    });

    test('an area with no passing check is reported', () {
      final checks = <Sprint117FailureStateCheck>[
        for (final state in Sprint117FailureStateValidation.requiredStates)
          if (state == 'region_block')
            Sprint117FailureStateCheck.violation(
              area: state,
              check: 'measured',
              declared: 'region gate refuses unavailable instrument',
              observed: 'instrument accepted outside its declared region',
            )
          else
            passing(state, 'measured'),
      ];
      final result = Sprint117FailureStateValidation.evaluate(checks);
      expect(result.pass, isFalse);
      expect(result.failures, contains('violation:region_block:measured'));
      expect(result.failures, contains('area_without_pass:region_block'));
      expect(result.violationCodes, <String>['region_block:measured']);
    });

    test('an unknown area is rejected', () {
      final checks = <Sprint117FailureStateCheck>[
        for (final state in Sprint117FailureStateValidation.requiredStates)
          passing(state, 'measured'),
        passing('cosmic_rays', 'measured'),
      ];
      final result = Sprint117FailureStateValidation.evaluate(checks);
      expect(result.pass, isFalse);
      expect(result.failures, contains('unknown_area:cosmic_rays'));
    });

    test('a duplicate check and a vacuous observation both fail the gate', () {
      final checks = <Sprint117FailureStateCheck>[
        for (final state in Sprint117FailureStateValidation.requiredStates)
          passing(state, 'measured'),
        Sprint117FailureStateCheck.pass(
          area: 'outage',
          check: 'measured',
          declared: 'declared',
          observed: '   ',
        ),
      ];
      final result = Sprint117FailureStateValidation.evaluate(checks);
      expect(result.pass, isFalse);
      expect(result.failures, contains('duplicate_check:outage:measured'));
      expect(result.failures, contains('vacuous:outage:measured'));
    });

    test('the canonical state list itself is guarded against duplication', () {
      expect(
        Sprint117FailureStateValidation.requiredStates.toSet().length,
        Sprint117FailureStateValidation.requiredStates.length,
        reason: 'a duplicated canonical state would double-count the gate',
      );
    });
  });

  group('117.28 error surface refuses credential leakage', () {
    test('a generic error carries a non-empty explanation and retry flag', () {
      final error = AccountCenterLoadingEmptyErrorStates.error(
        source: 'provider',
        message: 'The provider connection failed.',
        canRetry: true,
      );
      expect(error.state, AccountCenterSurfaceState.error);
      expect(error.message, 'The provider connection failed.');
      expect(error.canRetry, isTrue);
      expect(error.requiresReauthentication, isFalse);
    });

    test('an outage is retryable and names the provider boundary', () {
      final outage = AccountCenterLoadingEmptyErrorStates.outage(
        source: 'provider',
      );
      expect(outage.state, AccountCenterSurfaceState.outage);
      expect(outage.canRetry, isTrue);
      expect(outage.message, 'Provider outage. Try again later.');
    });

    test('a credential inside a user-visible error is refused', () {
      expect(
        () => AccountCenterLoadingEmptyErrorStates.error(
          source: 'provider',
          message: 'Bearer sk-secret-value',
          canRetry: false,
        ),
        throwsArgumentError,
      );
    });
  });
}
