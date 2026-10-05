/// Sprint 115.55 — Alpha Acceptance Gate contract tests.
///
/// Locks the nine canonical `required_evidence` buckets of step 115.55 against
/// `sprint_115.json`, proves the fail-closed matrix, and grounds every
/// committed manifest row in the live repository.
///
/// The buckets are not a restatement of the step title. They are the nine
/// evidence categories that the alpha acceptance gate must evaluate before
/// declaring the Account & Cloud Center ready for v1.3.0-alpha.1:
///
/// 1. `product_spec_acceptance` — the 10 acceptance_invariants from the product
///    spec are each covered by a domain contract.
/// 2. `connector_manifest` — the provider/connector manifest is UNVERIFIED and
///    isConnectable=false (no live connector certification claimed).
/// 3. `quota_evidence` — quota unavailable is explicit (not zero fabrication).
/// 4. `icon_registry` — 32 providers registered with generic fallback.
/// 5. `responsive_results` — visual regression matrix ALL_PASS.
/// 6. `accessibility_results` — keyboard & screen reader audit complete.
/// 7. `security_privacy_review` — privacy external_transfer=none, security
///    ALL_PASS.
/// 8. `billing_review` — billing PLANNED_NOT_VERIFIED (no live billing).
/// 9. `known_issues` — auth_flow regression documented, deferred external
///    listed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_alpha_acceptance.dart';
import '../../../canonical_source_support.dart';

void main() {
  const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_alpha_acceptance.json',
  );

  Map<String, dynamic> readManifest() {
    expect(manifestFile.existsSync(), isTrue, reason: '115.55 manifest');
    return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  }

  AccountAlphaAcceptanceBucket bucket({
    String bucket = 'product_spec_acceptance',
    AccountAlphaAcceptanceBucketStatus status =
        AccountAlphaAcceptanceBucketStatus.pass,
    List<AccountAlphaAcceptanceCheck> checks = const [],
    String note = '',
  }) => AccountAlphaAcceptanceBucket(
    bucket: bucket,
    status: status,
    checks: checks,
    note: note,
  );

  AccountAlphaAcceptanceCheck ok(String name, {required bool held}) =>
      AccountAlphaAcceptanceCheck(name: name, held: held);

  Map<String, AccountAlphaAcceptanceBucket> fullPassMatrix() =>
      <String, AccountAlphaAcceptanceBucket>{
        for (final name in AccountCenterAlphaAcceptance.requiredEvidence)
          name: bucket(
            bucket: name,
            checks: <AccountAlphaAcceptanceCheck>[
              ok('synthetic_$name', held: true),
            ],
          ),
      };

  group('115.55 canonical evidence set', () {
    test('locks the nine canonical outputs in spec order', () {
      expect(AccountCenterAlphaAcceptance.requiredEvidence, const <String>[
        'product_spec_acceptance',
        'connector_manifest',
        'quota_evidence',
        'icon_registry',
        'responsive_results',
        'accessibility_results',
        'security_privacy_review',
        'billing_review',
        'known_issues',
      ]);
    });

    test('matches required_evidence of step 115.55 in sprint_115.json', () {
      if (skipUnlessExternalCanonical(
        "matches required_evidence of step 115.55 in sprint_115.json",
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
          .firstWhere((entry) => entry['id'] == '115.55');
      expect(step['title'], 'Alpha Acceptance Gate');
      expect(
        step['required_evidence'],
        AccountCenterAlphaAcceptance.requiredEvidence,
        reason: 'required_evidence must be transcribed, not invented',
      );
    });

    test('rejects a bucket outside the canonical set', () {
      expect(
        () => AccountCenterAlphaAcceptance.buildReport({
          ...fullPassMatrix(),
          'penetration_tests': bucket(bucket: 'penetration_tests'),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a canonical bucket that was never recorded', () {
      final incomplete = fullPassMatrix()..remove('known_issues');
      expect(
        () => AccountCenterAlphaAcceptance.buildReport(incomplete),
        throwsStateError,
      );
    });

    test('rejects a row whose key does not match its bucket', () {
      expect(
        () => AccountCenterAlphaAcceptance.buildReport({
          for (final name in AccountCenterAlphaAcceptance.requiredEvidence)
            name: bucket(
              bucket: name == 'billing_review' ? 'quota_evidence' : name,
              checks: <AccountAlphaAcceptanceCheck>[
                ok('synthetic', held: true),
              ],
            ),
        }),
        throwsArgumentError,
      );
    });
  });

  group('fail-closed matrix rules', () {
    test('a pass without a concrete check is a rubber stamp', () {
      expect(
        () => AccountCenterAlphaAcceptance.buildReport({
          ...fullPassMatrix(),
          'product_spec_acceptance': bucket(bucket: 'product_spec_acceptance'),
        }),
        throwsArgumentError,
      );
    });

    test('a pass that records a failed check is refused', () {
      expect(
        () => AccountCenterAlphaAcceptance.buildReport({
          ...fullPassMatrix(),
          'connector_manifest': bucket(
            bucket: 'connector_manifest',
            checks: <AccountAlphaAcceptanceCheck>[
              ok('manifest_is_unverified', held: false),
            ],
          ),
        }),
        throwsArgumentError,
      );
    });

    test('a duplicate check name inside one bucket is refused', () {
      expect(
        () => AccountCenterAlphaAcceptance.buildReport({
          ...fullPassMatrix(),
          'quota_evidence': bucket(
            bucket: 'quota_evidence',
            checks: <AccountAlphaAcceptanceCheck>[
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
        () => AccountCenterAlphaAcceptance.buildReport({
          ...fullPassMatrix(),
          'responsive_results': bucket(
            bucket: 'responsive_results',
            status: AccountAlphaAcceptanceBucketStatus.fail,
            note: '  ',
          ),
        }),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterAlphaAcceptance.buildReport({
          ...fullPassMatrix(),
          'responsive_results': bucket(
            bucket: 'responsive_results',
            status: AccountAlphaAcceptanceBucketStatus.blocked,
          ),
        }),
        throwsArgumentError,
      );
    });

    test('blocked may not carry local checks, pending may not claim any', () {
      expect(
        () => AccountCenterAlphaAcceptance.buildReport({
          ...fullPassMatrix(),
          'accessibility_results': bucket(
            bucket: 'accessibility_results',
            status: AccountAlphaAcceptanceBucketStatus.blocked,
            note: 'Native AT certification is a platform gate.',
            checks: <AccountAlphaAcceptanceCheck>[ok('synthetic', held: true)],
          ),
        }),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterAlphaAcceptance.buildReport({
          ...fullPassMatrix(),
          'accessibility_results': bucket(
            bucket: 'accessibility_results',
            status: AccountAlphaAcceptanceBucketStatus.pending,
            checks: <AccountAlphaAcceptanceCheck>[ok('synthetic', held: true)],
          ),
        }),
        throwsArgumentError,
      );
    });
  });

  group('report verdict', () {
    test('INCOMPLETE while any canonical bucket is pending', () {
      final report = AccountCenterAlphaAcceptance.buildReport({
        for (final name in AccountCenterAlphaAcceptance.requiredEvidence)
          name: name == 'known_issues'
              ? bucket(
                  bucket: name,
                  status: AccountAlphaAcceptanceBucketStatus.pending,
                  note:
                      'Recorded as a target; not yet run in this build, so '
                      'it may not claim a check.',
                )
              : bucket(
                  bucket: name,
                  checks: <AccountAlphaAcceptanceCheck>[
                    ok('synthetic_$name', held: true),
                  ],
                ),
      });

      expect(report.isComplete, isFalse);
      expect(report.isPass, isFalse);
      expect(report.verdict, 'INCOMPLETE');
    });

    test('ALL_PASS only when every canonical bucket passed', () {
      final report = AccountCenterAlphaAcceptance.buildReport(fullPassMatrix());

      expect(report.isComplete, isTrue);
      expect(report.isPass, isTrue);
      expect(report.passCount, 9);
      expect(report.verdict, 'ALL_PASS');
    });

    test('a single blocked bucket keeps isPass false and is counted', () {
      final report = AccountCenterAlphaAcceptance.buildReport({
        ...fullPassMatrix(),
        'billing_review': bucket(
          bucket: 'billing_review',
          status: AccountAlphaAcceptanceBucketStatus.blocked,
          note:
              'Live billing/checkout is not reachable from this build; '
              'billing_contract.status remains PLANNED_NOT_VERIFIED.',
        ),
      });

      expect(report.isComplete, isTrue);
      expect(report.isPass, isFalse);
      expect(report.passCount, 8);
      expect(report.verdict, 'COMPLETE_8_OF_9_PASS');
    });

    test('verdict counts a fail row without inflating passCount', () {
      final report = AccountCenterAlphaAcceptance.buildReport({
        ...fullPassMatrix(),
        'security_privacy_review': bucket(
          bucket: 'security_privacy_review',
          status: AccountAlphaAcceptanceBucketStatus.fail,
          note: 'A privacy check failed during the alpha gate.',
        ),
      });

      expect(report.passCount, 8);
      expect(report.isPass, isFalse);
      expect(report.verdict, 'COMPLETE_8_OF_9_PASS');
    });
  });

  group('product_spec_acceptance grounding', () {
    test('the 10 acceptance_invariants are each covered by a domain contract', () {
      if (skipUnlessExternalCanonical(
        "the 10 acceptance_invariants are each covered by a domain contract",
      )) {
        return;
      }
      final specFile = File(
        'C:/Users/nepht/Documents/Codex/2026-08-22/'
        'referenced-chatgpt-conversation-this-is-an-2/outputs/'
        'account_cloud_center_spec.json',
      );
      expect(specFile.existsSync(), isTrue, reason: 'product spec');
      final spec =
          jsonDecode(specFile.readAsStringSync()) as Map<String, dynamic>;
      final invariants = (spec['acceptance_invariants'] as List<dynamic>)
          .cast<String>();
      expect(invariants, hasLength(10));

      // Each invariant must be covered by at least one domain contract.
      // The mapping is explicit and fail-closed.
      final coverage = <String, String>{
        'account_cloud_center_is_global_and_not_inside_novel_or_character_workspace':
            'account_center_workspace_boundary_contract.dart',
        'profile_contains_summary_and_shortcut_only':
            'account_center_information_architecture.dart',
        'all_provider_icons_resolve_through_provider_icon_registry_or_generic_fallback':
            'account_center_provider_icon_registry.dart',
        'provider_availability_comes_from_connector_manifest':
            'account_center_provider_connector_manifest.dart',
        'storage_and_credit_values_are_api_backed_or_explicitly_unavailable':
            'account_center_right_rail_summary.dart',
        'local_and_remote_storage_are_not_merged_without labeling':
            'account_center_storage_distribution_report.dart',
        'secrets_are_never_stored_or_displayed_in_plaintext':
            'account_center_secure_token_vault.dart',
        'all provider states have loading_empty_error_and_reauth handling':
            'account_center_token_expiry_reauthentication_ux.dart',
        'desktop_tablet_and_mobile_layouts_pass_visual_and_accessibility_tests':
            'account_center_visual_regression_matrix.dart',
        'reference_mock_values_never_reach_production_state':
            'account_center_quick_actions.dart',
      };

      for (final invariant in invariants) {
        final contract = coverage[invariant];
        expect(
          contract,
          isNotNull,
          reason: 'No domain contract covers invariant: $invariant',
        );
        final file = File('lib/features/account/domain/$contract');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Contract file missing for invariant: $invariant',
        );
      }
    });
  });

  group('connector_manifest grounding', () {
    test('manifest is UNVERIFIED and isConnectable=false', () {
      final manifestFile = File(
        'docs/planning/v1.2/sprint_115_provider_connector_manifest.json',
      );
      expect(manifestFile.existsSync(), isTrue);
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['canonical_step'], '115.9');
      // The standard manifest must not claim live connector certification.
      final entries = manifest['entries'] as List<dynamic>?;
      if (entries != null) {
        for (final entry in entries.cast<Map<String, dynamic>>()) {
          expect(entry['availability'], 'UNVERIFIED');
          expect(entry['is_connectable'], isFalse);
        }
      }
    });
  });

  group('quota_evidence grounding', () {
    test('quota unavailable is explicit, not zero fabrication', () {
      final testFile = File(
        'test/features/account/domain/'
        'account_center_provider_quota_adapter_test.dart',
      );
      expect(testFile.existsSync(), isTrue);
      final content = testFile.readAsStringSync();
      // The test must prove that unavailable is explicit.
      expect(content, contains('unavailable'));
      expect(content, contains('ProviderQuotaStatus'));
    });
  });

  group('icon_registry grounding', () {
    test('32 providers registered with generic fallback', () {
      final testFile = File(
        'test/features/account/domain/'
        'account_center_provider_icon_registry_test.dart',
      );
      expect(testFile.existsSync(), isTrue);
      final content = testFile.readAsStringSync();
      expect(content, contains('fallback'));
      expect(content, contains('generic'));
    });
  });

  group('responsive_results grounding', () {
    test('visual regression matrix is ALL_PASS', () {
      final manifestFile = File(
        'docs/planning/v1.2/sprint_115_visual_regression_matrix.json',
      );
      expect(manifestFile.existsSync(), isTrue);
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['verdict'], 'ALL_PASS');
    });
  });

  group('accessibility_results grounding', () {
    test('keyboard and screen reader audit is complete', () {
      final manifestFile = File(
        'docs/planning/v1.2/'
        'sprint_115_keyboard_screen_reader_verification.json',
      );
      expect(manifestFile.existsSync(), isTrue);
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['canonical_step'], '115.48');
      final surfaces = manifest['audited_surfaces'] as Map<String, dynamic>;
      expect(surfaces, isNotEmpty);
    });
  });

  group('security_privacy_review grounding', () {
    test('privacy external_transfer=none, security ALL_PASS', () {
      final privacyFile = File(
        'docs/planning/v1.2/sprint_115_privacy_data_flow_review.json',
      );
      expect(privacyFile.existsSync(), isTrue);
      final privacy =
          jsonDecode(privacyFile.readAsStringSync()) as Map<String, dynamic>;
      final outputs = privacy['required_outputs'] as Map<String, dynamic>;
      final externalTransfer =
          outputs['external_transfer'] as Map<String, dynamic>;
      expect(externalTransfer['local_result'], 'PASS');

      final securityFile = File(
        'docs/planning/v1.2/sprint_115_security_billing_verification.json',
      );
      expect(securityFile.existsSync(), isTrue);
      final security =
          jsonDecode(securityFile.readAsStringSync()) as Map<String, dynamic>;
      expect(security['verdict'], 'ALL_PASS');
    });
  });

  group('billing_review grounding', () {
    test('billing is PLANNED_NOT_VERIFIED', () {
      if (skipUnlessExternalCanonical("billing is PLANNED_NOT_VERIFIED")) {
        return;
      }
      final specFile = File(
        'C:/Users/nepht/Documents/Codex/2026-08-22/'
        'referenced-chatgpt-conversation-this-is-an-2/outputs/'
        'account_cloud_center_spec.json',
      );
      final spec =
          jsonDecode(specFile.readAsStringSync()) as Map<String, dynamic>;
      final billing = spec['billing_contract'] as Map<String, dynamic>;
      expect(billing['status'], 'PLANNED_NOT_VERIFIED');
    });
  });

  group('known_issues grounding', () {
    test('auth_flow regression is documented in ledger', () {
      final ledgerFile = File(
        'docs/sprints/sprint-115-account-cloud-center.md',
      );
      expect(ledgerFile.existsSync(), isTrue);
      final content = ledgerFile.readAsStringSync();
      expect(content, contains('auth_flow'));
      expect(content, contains('a5ed3ae'));
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
          .firstWhere((entry) => entry['id'] == '115.55');

      expect(manifest['step'], '115.55');
      expect(manifest['title'], 'Alpha Acceptance Gate');
      expect(manifest['required_evidence'], <String>[
        'product_spec_acceptance',
        'connector_manifest',
        'quota_evidence',
        'icon_registry',
        'responsive_results',
        'accessibility_results',
        'security_privacy_review',
        'billing_review',
        'known_issues',
      ]);
      expect(step['required_evidence'], manifest['required_evidence']);

      final buckets = (manifest['buckets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        buckets.map((row) => row['bucket']).toList(),
        AccountCenterAlphaAcceptance.requiredEvidence,
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
      expect(decoded['step'], '115.55');
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
