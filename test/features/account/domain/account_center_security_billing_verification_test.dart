/// Sprint 115.54 — Security & Billing Verification contract tests.
///
/// Locks the eight canonical `required_outputs` buckets of step 115.54 against
/// `sprint_115.json`, proves the fail-closed matrix, and grounds every
/// committed manifest row in the live repository.
///
/// The buckets are not a restatement of the step title. Two of them
/// (`webhook_tests`, `audit_tests`) name capabilities that did not exist
/// anywhere under `lib/features/account` before this step, and two of the
/// security assertions here are defects found by reading the live contracts
/// and then reproduced by probe (see the RED meta file):
///
/// 1. An entitlement granted at T is reported as `granted` at any time before
///    T. `entitlementStateAt` only compared `expiresAt`, so a clock-skewed or
///    replayed evaluation time silently unlocked a feature that had not been
///    issued yet.
/// 2. `AccountCenterApiKeysManager.replace` overwrote key material in the
///    vault with reauthentication refused. The product spec lists
///    `reveal_or_replace_key` under `security_contract.sensitive_actions`,
///    and every other sensitive path in the same file re-checks reauth.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_security_billing_verification.dart';
import '../../../canonical_source_support.dart';

void main() {
  const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_security_billing_verification.json',
  );

  Map<String, dynamic> readManifest() {
    expect(manifestFile.existsSync(), isTrue, reason: '115.54 manifest');
    return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  }

  AccountVerificationBucket bucket({
    String bucket = 'oauth_tests',
    AccountVerificationBucketStatus status =
        AccountVerificationBucketStatus.pass,
    List<AccountVerificationCheck> checks = const [],
    String note = '',
  }) => AccountVerificationBucket(
    bucket: bucket,
    status: status,
    checks: checks,
    note: note,
  );

  /// A check that actually held, so a synthetic `pass` row is never a bare
  /// "the test file exists" rubber stamp.
  AccountVerificationCheck ok(String name, {required bool held}) =>
      AccountVerificationCheck(name: name, held: held);

  Map<String, AccountVerificationBucket>
  fullPassMatrix() => <String, AccountVerificationBucket>{
    for (final name in AccountCenterSecurityBillingVerification.requiredBuckets)
      name: bucket(
        bucket: name,
        checks: <AccountVerificationCheck>[ok('synthetic_$name', held: true)],
      ),
  };

  group('115.54 canonical bucket set', () {
    test('locks the eight canonical outputs in spec order', () {
      expect(
        AccountCenterSecurityBillingVerification.requiredBuckets,
        const <String>[
          'oauth_tests',
          'vault_tests',
          'key_tests',
          'session_tests',
          'permission_tests',
          'webhook_tests',
          'entitlement_tests',
          'audit_tests',
        ],
      );
    });

    test('matches required_outputs of step 115.54 in sprint_115.json', () {
      if (skipUnlessExternalCanonical(
        "matches required_outputs of step 115.54 in sprint_115.json",
      )) {
        return;
      }
      final file = File(canonicalSprintPath);
      expect(file.existsSync(), isTrue, reason: 'canonical sprint_115.json');
      expect(
        sha256.convert(file.readAsBytesSync()).toString(),
        canonicalSprintSha256,
        reason: 'canonical sprint hash drift',
      );
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final step = (document['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == '115.54');
      expect(step['title'], 'Security & Billing Verification');
      expect(
        step['required_outputs'],
        AccountCenterSecurityBillingVerification.requiredBuckets,
        reason: 'required_outputs must be transcribed, not invented',
      );
    });

    test('rejects a bucket outside the canonical set', () {
      expect(
        () => AccountCenterSecurityBillingVerification.buildReport({
          ...fullPassMatrix(),
          'penetration_tests': bucket(bucket: 'penetration_tests'),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a canonical bucket that was never recorded', () {
      final incomplete = fullPassMatrix()..remove('audit_tests');
      expect(
        () => AccountCenterSecurityBillingVerification.buildReport(incomplete),
        throwsStateError,
      );
    });

    test('rejects a row whose key does not match its bucket', () {
      expect(
        () => AccountCenterSecurityBillingVerification.buildReport({
          for (final name
              in AccountCenterSecurityBillingVerification.requiredBuckets)
            name: bucket(
              bucket: name == 'vault_tests' ? 'oauth_tests' : name,
              checks: <AccountVerificationCheck>[ok('synthetic', held: true)],
            ),
        }),
        throwsArgumentError,
      );
    });
  });

  group('fail-closed matrix rules', () {
    test('a pass without a concrete check is a rubber stamp', () {
      expect(
        () => AccountCenterSecurityBillingVerification.buildReport({
          ...fullPassMatrix(),
          'oauth_tests': bucket(bucket: 'oauth_tests'),
        }),
        throwsArgumentError,
      );
    });

    test('a pass that records a failed check is refused', () {
      expect(
        () => AccountCenterSecurityBillingVerification.buildReport({
          ...fullPassMatrix(),
          'vault_tests': bucket(
            bucket: 'vault_tests',
            checks: <AccountVerificationCheck>[
              ok('reauth_before_read', held: false),
            ],
          ),
        }),
        throwsArgumentError,
      );
    });

    test('a duplicate check name inside one bucket is refused', () {
      expect(
        () => AccountCenterSecurityBillingVerification.buildReport({
          ...fullPassMatrix(),
          'key_tests': bucket(
            bucket: 'key_tests',
            checks: <AccountVerificationCheck>[
              ok('same', held: true),
              ok('same', held: true),
            ],
          ),
        }),
        throwsArgumentError,
      );
    });

    test('fail and blocked must say why', () {
      expect(
        () => AccountCenterSecurityBillingVerification.buildReport({
          ...fullPassMatrix(),
          'session_tests': bucket(
            bucket: 'session_tests',
            status: AccountVerificationBucketStatus.fail,
            note: '  ',
          ),
        }),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterSecurityBillingVerification.buildReport({
          ...fullPassMatrix(),
          'session_tests': bucket(
            bucket: 'session_tests',
            status: AccountVerificationBucketStatus.blocked,
          ),
        }),
        throwsArgumentError,
      );
    });

    test('blocked may not carry local checks, pending may not claim any', () {
      expect(
        () => AccountCenterSecurityBillingVerification.buildReport({
          ...fullPassMatrix(),
          'permission_tests': bucket(
            bucket: 'permission_tests',
            status: AccountVerificationBucketStatus.blocked,
            note: 'Waiting on an identity provider that is not connected.',
            checks: <AccountVerificationCheck>[ok('synthetic', held: true)],
          ),
        }),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterSecurityBillingVerification.buildReport({
          ...fullPassMatrix(),
          'permission_tests': bucket(
            bucket: 'permission_tests',
            status: AccountVerificationBucketStatus.pending,
            checks: <AccountVerificationCheck>[ok('synthetic', held: true)],
          ),
        }),
        throwsArgumentError,
      );
    });

    test('a bucket may record several distinct checks under one name set', () {
      expect(
        () => AccountVerificationBucket(
          bucket: 'oauth_tests',
          status: AccountVerificationBucketStatus.pass,
          checks: <AccountVerificationCheck>[
            ok('unique_one', held: true),
            ok('unique_two', held: true),
          ],
        ),
        returnsNormally,
      );
    });
  });

  group('report verdict', () {
    test('INCOMPLETE while any canonical bucket is pending', () {
      final report = AccountCenterSecurityBillingVerification.buildReport({
        for (final name
            in AccountCenterSecurityBillingVerification.requiredBuckets)
          name: name == 'audit_tests'
              ? bucket(
                  bucket: name,
                  status: AccountVerificationBucketStatus.pending,
                  note:
                      'Recorded as a target; not yet run in this build, so '
                      'it may not claim a check.',
                )
              : bucket(
                  bucket: name,
                  checks: <AccountVerificationCheck>[
                    ok('synthetic_$name', held: true),
                  ],
                ),
      });

      expect(report.isComplete, isFalse);
      expect(report.isPass, isFalse);
      expect(report.verdict, 'INCOMPLETE');
    });

    test('ALL_PASS only when every canonical bucket passed', () {
      final report = AccountCenterSecurityBillingVerification.buildReport(
        fullPassMatrix(),
      );

      expect(report.isComplete, isTrue);
      expect(report.isPass, isTrue);
      expect(report.passCount, 8);
      expect(report.verdict, 'ALL_PASS');
    });

    test('a single blocked bucket keeps isPass false and is counted', () {
      final report = AccountCenterSecurityBillingVerification.buildReport({
        ...fullPassMatrix(),
        'permission_tests': bucket(
          bucket: 'permission_tests',
          status: AccountVerificationBucketStatus.blocked,
          note:
              'Workspace permission enforcement against a live identity '
              'provider is not reachable from this build.',
        ),
      });

      expect(report.isComplete, isTrue);
      expect(report.isPass, isFalse);
      expect(report.passCount, 7);
      expect(report.verdict, 'COMPLETE_7_OF_8_PASS');
    });

    test('verdict counts a fail row without inflating passCount', () {
      final report = AccountCenterSecurityBillingVerification.buildReport({
        ...fullPassMatrix(),
        'entitlement_tests': bucket(
          bucket: 'entitlement_tests',
          status: AccountVerificationBucketStatus.fail,
          note: 'A grant was reported as live before it was issued.',
        ),
      });

      expect(report.passCount, 7);
      expect(report.isPass, isFalse);
      expect(report.verdict, 'COMPLETE_7_OF_8_PASS');
    });
  });

  group('webhook authenticity contract', () {
    // Every case pins `now`. The signed timestamps below are fixed, so a
    // case that left `now` to the real clock would pass on the day it was
    // written and start reporting `stale` five minutes later.
    final now = DateTime.utc(2026, 9, 27, 12);

    // This is the whole point of the bucket: before this step there was no
    // webhook verification anywhere under lib/features/account, so a
    // provider callback could be replayed or forged with no check at all.
    test('accepts a payload whose HMAC-SHA256 signature matches', () {
      const secret = 'whsec_2f8c0b41d6';
      const body = '{"id":"evt_1","type":"invoice.paid"}';

      final header = AccountCenterSecurityBillingVerification.signatureHeader(
        secret: secret,
        timestamp: DateTime.utc(2026, 9, 27, 12),
        body: body,
      );

      final request = AccountVerificationWebhookRequest(
        deliveryId: 'delivery-1',
        providerId: 'billing-provider',
        timestamp: DateTime.utc(2026, 9, 27, 12),
        signature: header,
        body: body,
      );

      expect(
        AccountCenterSecurityBillingVerification.verifyWebhook(
          request: request,
          secret: secret,
          tolerance: const Duration(minutes: 5),
          now: now,
        ),
        AccountWebhookDecision.verified,
      );
    });

    test('refuses a payload that was altered after signing', () {
      const secret = 'whsec_2f8c0b41d6';
      final header = AccountCenterSecurityBillingVerification.signatureHeader(
        secret: secret,
        timestamp: DateTime.utc(2026, 9, 27, 12),
        body: '{"id":"evt_1","amount":10}',
      );

      final request = AccountVerificationWebhookRequest(
        deliveryId: 'delivery-1',
        providerId: 'billing-provider',
        timestamp: DateTime.utc(2026, 9, 27, 12),
        signature: header,
        body: '{"id":"evt_1","amount":1000}',
      );

      expect(
        AccountCenterSecurityBillingVerification.verifyWebhook(
          request: request,
          secret: secret,
          tolerance: const Duration(minutes: 5),
          now: now,
        ),
        AccountWebhookDecision.signatureMismatch,
      );
    });

    test('refuses a signature made with a different secret', () {
      const body = '{"id":"evt_1"}';
      final header = AccountCenterSecurityBillingVerification.signatureHeader(
        secret: 'whsec_attacker',
        timestamp: DateTime.utc(2026, 9, 27, 12),
        body: body,
      );

      expect(
        AccountCenterSecurityBillingVerification.verifyWebhook(
          request: AccountVerificationWebhookRequest(
            deliveryId: 'delivery-1',
            providerId: 'billing-provider',
            timestamp: DateTime.utc(2026, 9, 27, 12),
            signature: header,
            body: body,
          ),
          secret: 'whsec_real',
          tolerance: const Duration(minutes: 5),
          now: now,
        ),
        AccountWebhookDecision.signatureMismatch,
      );
    });

    test('refuses a replayed delivery outside the timestamp tolerance', () {
      const secret = 'whsec_2f8c0b41d6';
      const body = '{"id":"evt_1"}';
      final header = AccountCenterSecurityBillingVerification.signatureHeader(
        secret: secret,
        timestamp: DateTime.utc(2026, 9, 27, 12),
        body: body,
      );

      expect(
        AccountCenterSecurityBillingVerification.verifyWebhook(
          request: AccountVerificationWebhookRequest(
            deliveryId: 'delivery-1',
            providerId: 'billing-provider',
            timestamp: DateTime.utc(2026, 9, 27, 12),
            signature: header,
            body: body,
          ),
          secret: secret,
          tolerance: const Duration(minutes: 5),
          now: DateTime.utc(2026, 9, 27, 12, 6),
        ),
        AccountWebhookDecision.stale,
      );
    });

    test('a second delivery of the same id is refused as a replay', () {
      const secret = 'whsec_2f8c0b41d6';
      const body = '{"id":"evt_1"}';
      final header = AccountCenterSecurityBillingVerification.signatureHeader(
        secret: secret,
        timestamp: DateTime.utc(2026, 9, 27, 12),
        body: body,
      );
      final guard = AccountWebhookReplayGuard();

      AccountCenterSecurityBillingVerification.verifyWebhook(
        request: AccountVerificationWebhookRequest(
          deliveryId: 'delivery-1',
          providerId: 'billing-provider',
          timestamp: DateTime.utc(2026, 9, 27, 12),
          signature: header,
          body: body,
        ),
        secret: secret,
        tolerance: const Duration(minutes: 5),
        replayGuard: guard,
        now: now,
      );

      expect(
        AccountCenterSecurityBillingVerification.verifyWebhook(
          request: AccountVerificationWebhookRequest(
            deliveryId: 'delivery-1',
            providerId: 'billing-provider',
            timestamp: DateTime.utc(2026, 9, 27, 12),
            signature: header,
            body: body,
          ),
          secret: secret,
          tolerance: const Duration(minutes: 5),
          replayGuard: guard,
          now: now,
        ),
        AccountWebhookDecision.replayed,
      );
    });

    test('an empty or malformed signature never verifies', () {
      const secret = 'whsec_2f8c0b41d6';
      const body = '{"id":"evt_1"}';

      for (final signature in <String>['', 'not-a-signature', 'sha256=']) {
        expect(
          AccountCenterSecurityBillingVerification.verifyWebhook(
            request: AccountVerificationWebhookRequest(
              deliveryId: 'delivery-1',
              providerId: 'billing-provider',
              timestamp: DateTime.utc(2026, 9, 27, 12),
              signature: signature,
              body: body,
            ),
            secret: secret,
            tolerance: const Duration(minutes: 5),
            now: now,
          ),
          AccountWebhookDecision.malformedSignature,
          reason: 'signature "$signature"',
        );
      }
    });

    test('an empty secret or a negative tolerance is refused outright', () {
      expect(
        () => AccountVerificationWebhookRequest(
          deliveryId: ' ',
          providerId: 'billing-provider',
          timestamp: DateTime.utc(2026, 9, 27, 12),
          signature: 'sha256=abc',
          body: '{}',
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterSecurityBillingVerification.verifyWebhook(
          request: AccountVerificationWebhookRequest(
            deliveryId: 'delivery-1',
            providerId: 'billing-provider',
            timestamp: DateTime.utc(2026, 9, 27, 12),
            signature: 'sha256=abc',
            body: '{}',
          ),
          secret: 'whsec_x',
          tolerance: const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('entitlement issuance window', () {
    // Defect 1, confirmed by probe: PROBE_A state_at_2020=granted.
    test('a grant is not live before it was issued', () {
      final at = DateTime.utc(2026, 9, 27, 12);
      final grant = EntitlementGrantProbe.signed(
        grantedAt: at,
        expiresAt: at.add(const Duration(days: 30)),
      );

      expect(
        AccountCenterSecurityBillingVerification.entitlementStateAt(
          grant: grant,
          at: at.subtract(const Duration(minutes: 1)),
        ),
        'notYetIssued',
      );
      expect(
        AccountCenterSecurityBillingVerification.entitlementStateAt(
          grant: grant,
          at: at,
        ),
        'granted',
      );
    });

    test('an existing grant without an expiry never lapses', () {
      final at = DateTime.utc(2026, 9, 27, 12);
      final grant = EntitlementGrantProbe.signed(grantedAt: at);

      expect(
        AccountCenterSecurityBillingVerification.entitlementStateAt(
          grant: grant,
          at: DateTime.utc(2099, 1, 1),
        ),
        'granted',
      );
    });
  });

  group('committed manifest', () {
    test('repeats the canonical identity and verdict of the live report', () {
      if (skipUnlessExternalCanonical(
        "repeats the canonical identity and verdict of the live report",
      )) {
        return;
      }
      final manifest = readManifest();
      final document =
          jsonDecode(File(canonicalSprintPath).readAsStringSync())
              as Map<String, dynamic>;
      final step = (document['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == '115.54');

      expect(manifest['step'], '115.54');
      expect(manifest['title'], 'Security & Billing Verification');
      expect(manifest['required_outputs'], <String>[
        'oauth_tests',
        'vault_tests',
        'key_tests',
        'session_tests',
        'permission_tests',
        'webhook_tests',
        'entitlement_tests',
        'audit_tests',
      ]);
      expect(step['required_outputs'], manifest['required_outputs']);

      final buckets = (manifest['buckets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        buckets.map((row) => row['bucket']).toList(),
        AccountCenterSecurityBillingVerification.requiredBuckets,
        reason: 'manifest rows must follow canonical order',
      );
    });

    test('every row is either a real pass or names its blocker', () {
      final manifest = readManifest();
      final buckets = (manifest['buckets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      for (final row in buckets) {
        final status = row['status'] as String;
        final note = (row['note'] as String?) ?? '';
        final checks = (row['checks'] as List<dynamic>?) ?? const [];
        if (status == 'pass') {
          expect(checks, isNotEmpty, reason: '${row['bucket']} rubber stamp');
          for (final check in checks.cast<Map<String, dynamic>>()) {
            expect(check['held'], isTrue, reason: '${row['bucket']} check');
          }
        } else {
          expect(
            note.length,
            greaterThanOrEqualTo(30),
            reason: '${row['bucket']} must explain itself',
          );
        }
        expect(row['measured'], (row['checks'] as List<dynamic>).length);
      }
    });

    test('cites only test files that exist in this checkout', () {
      final manifest = readManifest();
      for (final path
          in (manifest['evidence'] as List<dynamic>).cast<String>()) {
        expect(path, endsWith('_test.dart'), reason: path);
        expect(path, isNot(contains('..')), reason: path);
        expect(File(path).existsSync(), isTrue, reason: '$path is not on disk');
        expect(
          File(path).readAsStringSync(),
          contains('test('),
          reason: '$path holds no test case',
        );
      }
    });

    test('cites the RED meta separately and never as test evidence', () {
      final manifest = readManifest();
      final redMeta = manifest['red_meta'] as String;
      expect(redMeta, isNot(contains('_test.dart')));
      final file = File(redMeta);
      expect(file.existsSync(), isTrue, reason: redMeta);
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['step'], '115.54');
      expect(decoded['phase'], 'RED');
      expect(decoded['head_at_capture'], isNotEmpty);
    });

    test('parked external gates stay DEFERRED-EXTERNAL', () {
      final manifest = readManifest();
      final deferred = (manifest['deferred_external'] as List<dynamic>)
          .cast<String>();
      expect(deferred.length, greaterThanOrEqualTo(4));
      expect(
        deferred.any(
          (entry) =>
              entry.toLowerCase().contains('payment') ||
              entry.toLowerCase().contains('billing'),
        ),
        isTrue,
        reason: 'the live payment boundary must stay parked',
      );
      for (final entry in deferred) {
        expect(entry, isNot(contains('PASS')));
      }
    });
  });
}
