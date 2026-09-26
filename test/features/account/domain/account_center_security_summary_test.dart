import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_security_summary.dart';

void main() {
  group('AccountCenterSecuritySummary', () {
    test('manifest preserves every canonical 115.32 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_security_center_summary.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.32');
      expect(manifest['acceptance'], <String>[
        'mfa',
        'password_health',
        'trusted_devices',
        'sessions',
        'secure_store_health',
        'alerts',
        'actions',
      ]);
    });

    test(
      'summarizes every local security signal without inferring live state',
      () {
        final summary = AccountCenterSecuritySummary(
          mfa: MfaSecuritySummary(
            status: SecuritySignalStatus.attention,
            enrolledMethods: {'totp'},
            recoveryCodesRemaining: 4,
          ),
          password: PasswordSecuritySummary(
            status: SecuritySignalStatus.healthy,
            changedAt: DateTime.utc(2026, 9, 20),
          ),
          trustedDevices: DeviceSecuritySummary(
            status: SecuritySignalStatus.healthy,
            count: 2,
          ),
          sessions: SessionSecuritySummary(
            status: SecuritySignalStatus.attention,
            activeCount: 3,
            suspiciousCount: 1,
          ),
          secureStore: SecureStoreSecuritySummary(
            status: SecuritySignalStatus.unknown,
            backend: null,
            lastCheckedAt: null,
          ),
          alerts: [
            SecurityCenterAlert(
              id: 'older',
              severity: SecurityAlertSeverity.warning,
              title: 'Review old session',
              occurredAt: DateTime.utc(2026, 9, 25),
            ),
            SecurityCenterAlert(
              id: 'newer',
              severity: SecurityAlertSeverity.critical,
              title: 'Suspicious session',
              occurredAt: DateTime.utc(2026, 9, 26),
            ),
          ],
          actions: [
            SecurityRecommendedAction(
              id: 'review-session',
              title: 'Review suspicious session',
              priority: 10,
              route: '/account/cloud-center?tab=security&action=review-session',
            ),
            SecurityRecommendedAction(
              id: 'add-mfa',
              title: 'Add another MFA method',
              priority: 20,
              route: '/account/cloud-center?tab=security&action=add-mfa',
            ),
          ],
        );

        expect(summary.mfa.enrolledMethods, {'totp'});
        expect(summary.password.changedAt, DateTime.utc(2026, 9, 20));
        expect(summary.trustedDevices.count, 2);
        expect(summary.sessions.activeCount, 3);
        expect(summary.sessions.suspiciousCount, 1);
        expect(summary.secureStore.status, SecuritySignalStatus.unknown);
        expect(summary.secureStore.backend, isNull);
        expect(summary.alerts.map((alert) => alert.id), ['newer', 'older']);
        expect(summary.actions.map((action) => action.id), [
          'review-session',
          'add-mfa',
        ]);
        expect(summary.overallStatus, SecuritySignalStatus.critical);
      },
    );

    test(
      'keeps collections immutable and accepts explicit unavailable state',
      () {
        final summary = AccountCenterSecuritySummary(
          mfa: MfaSecuritySummary(
            status: SecuritySignalStatus.unavailable,
            enrolledMethods: {},
            recoveryCodesRemaining: null,
          ),
          password: PasswordSecuritySummary(
            status: SecuritySignalStatus.unavailable,
            changedAt: null,
          ),
          trustedDevices: DeviceSecuritySummary(
            status: SecuritySignalStatus.unavailable,
            count: null,
          ),
          sessions: SessionSecuritySummary(
            status: SecuritySignalStatus.unavailable,
            activeCount: null,
            suspiciousCount: null,
          ),
          secureStore: SecureStoreSecuritySummary(
            status: SecuritySignalStatus.unavailable,
            backend: null,
            lastCheckedAt: null,
          ),
          alerts: const [],
          actions: [],
        );

        expect(summary.overallStatus, SecuritySignalStatus.unavailable);
        expect(
          () => summary.alerts.add(_alert('extra')),
          throwsUnsupportedError,
        );
        expect(() => summary.actions.clear(), throwsUnsupportedError);
      },
    );

    test('fails closed for contradictory counts and unsafe action routes', () {
      expect(
        () => SessionSecuritySummary(
          status: SecuritySignalStatus.healthy,
          activeCount: 1,
          suspiciousCount: 2,
        ),
        throwsArgumentError,
      );
      expect(
        () => DeviceSecuritySummary(
          status: SecuritySignalStatus.healthy,
          count: null,
        ),
        throwsArgumentError,
      );
      expect(
        () => SecurityRecommendedAction(
          id: 'external',
          title: 'Open external page',
          priority: 1,
          route: 'https://example.invalid/security',
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterSecuritySummary(
          mfa: MfaSecuritySummary(
            status: SecuritySignalStatus.unknown,
            enrolledMethods: {},
            recoveryCodesRemaining: null,
          ),
          password: PasswordSecuritySummary(
            status: SecuritySignalStatus.unknown,
            changedAt: null,
          ),
          trustedDevices: DeviceSecuritySummary(
            status: SecuritySignalStatus.unknown,
            count: null,
          ),
          sessions: SessionSecuritySummary(
            status: SecuritySignalStatus.unknown,
            activeCount: null,
            suspiciousCount: null,
          ),
          secureStore: SecureStoreSecuritySummary(
            status: SecuritySignalStatus.unknown,
            backend: null,
            lastCheckedAt: null,
          ),
          alerts: [_alert('duplicate'), _alert('duplicate')],
          actions: [],
        ),
        throwsArgumentError,
      );
    });
  });
}

SecurityCenterAlert _alert(String id) => SecurityCenterAlert(
  id: id,
  severity: SecurityAlertSeverity.info,
  title: 'Security notice',
  occurredAt: DateTime.utc(2026, 9, 26),
);
