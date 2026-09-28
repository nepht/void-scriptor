import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_midtrans_billing_certification.dart';

void main() {
  group('116.38 Midtrans Billing Certification', () {
    test(
      'locks payment methods, redirects, notifications, signature, region, settlement and errors',
      () {
        expect(Sprint116MidtransBillingContract.requiredFields, <String>[
          'payment_methods',
          'redirects',
          'notifications',
          'signature',
          'region',
          'settlement',
          'errors',
        ]);
      },
    );

    test(
      'synthetic local billing records pass without live Midtrans claims',
      () {
        final report = Sprint116MidtransBillingCertification().evaluate([
          Sprint116MidtransBillingRecord(
            billingId: 'synthetic_snap_qris_flow',
            paymentMethods: 'synthetic payment methods fixture',
            redirects: 'synthetic redirect fixture',
            notifications: 'synthetic notification fixture',
            signature: 'synthetic signature fixture',
            region: 'synthetic region fixture',
            settlement: 'synthetic settlement fixture',
            errors: 'synthetic error fixture',
          ),
          Sprint116MidtransBillingRecord(
            billingId: 'synthetic_webhook_settlement_flow',
            paymentMethods: 'synthetic payment methods fixture',
            redirects: 'synthetic redirect fixture',
            notifications: 'synthetic notification fixture',
            signature: 'synthetic signature fixture',
            region: 'synthetic region fixture',
            settlement: 'synthetic settlement fixture',
            errors: 'synthetic error fixture',
          ),
        ]);
        expect(report.state, Sprint116MidtransBillingState.pass);
        expect(report.invalidRecords, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test('missing billing controls fail closed per record', () {
      final report = Sprint116MidtransBillingCertification().evaluate([
        Sprint116MidtransBillingRecord(
          billingId: 'synthetic_snap_qris_flow',
          paymentMethods: '',
          redirects: '',
          notifications: '',
          signature: '',
          region: '',
          settlement: '',
          errors: '',
        ),
        Sprint116MidtransBillingRecord(
          billingId: 'synthetic_webhook_settlement_flow',
          paymentMethods: 'synthetic payment methods fixture',
          redirects: 'synthetic redirect fixture',
          notifications: '',
          signature: 'synthetic signature fixture',
          region: 'synthetic region fixture',
          settlement: '',
          errors: 'synthetic error fixture',
        ),
      ]);
      expect(report.state, Sprint116MidtransBillingState.fail);
      expect(
        report.invalidRecords,
        contains('payment_methods:synthetic_snap_qris_flow'),
      );
      expect(
        report.invalidRecords,
        contains('redirects:synthetic_snap_qris_flow'),
      );
      expect(
        report.invalidRecords,
        contains('notifications:synthetic_snap_qris_flow'),
      );
      expect(
        report.invalidRecords,
        contains('signature:synthetic_snap_qris_flow'),
      );
      expect(
        report.invalidRecords,
        contains('region:synthetic_snap_qris_flow'),
      );
      expect(
        report.invalidRecords,
        contains('settlement:synthetic_snap_qris_flow'),
      );
      expect(
        report.invalidRecords,
        contains('errors:synthetic_snap_qris_flow'),
      );
      expect(
        report.invalidRecords,
        contains('notifications:synthetic_webhook_settlement_flow'),
      );
      expect(
        report.invalidRecords,
        contains('settlement:synthetic_webhook_settlement_flow'),
      );
      expect(report.invalidRecords.length, 9);
    });

    test('empty record set is blocked, not a pass', () {
      final report = Sprint116MidtransBillingCertification().evaluate([]);
      expect(report.state, Sprint116MidtransBillingState.blocked);
      expect(report.invalidRecords, contains('records'));
    });

    test(
      'manifest is local-only and carries no production secrets or live billing claims',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116MidtransBillingContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.38');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['records'], isNotEmpty);
        final ids = (manifest['records'] as List<dynamic>)
            .map((record) => (record as Map<String, dynamic>)['billing_id'])
            .toList();
        expect(
          ids,
          containsAll(<String>[
            'synthetic_snap_qris_flow',
            'synthetic_webhook_settlement_flow',
          ]),
        );
        for (final record in manifest['records'] as List<dynamic>) {
          expect((record as Map<String, dynamic>)['status'], 'UNVERIFIED');
        }
        expect(
          manifest.keys
              .where(
                (key) =>
                    key.toLowerCase().contains('secret') ||
                    key.toLowerCase().contains('api_key'),
              )
              .toList(),
          isEmpty,
        );
      },
    );
  });
}
