/// 117.33 — Privacy Assessment: durable release coverage.
///
/// RED ditulis dari fakta yang sudah terukur pada HEAD slice ini, bukan dari
/// kriteria yang dikarang. Dua permukaan di-ship gagal-tertutup; satu sumbu
/// (retention) sudah hijau oleh kerja 117.31 dan sengaja tidak diregressi.
///
/// Fakta terukur yang dikunci di sini:
/// 1. `WorkflowPrivacyPolicy.strict` memiliki `allowedDataKinds` KOSONG dan
///    cek minimalisasi dijaga `isNotEmpty`, sehingga kebijakan bernama
///    "strict" menjalankan nol minimalisasi data.
/// 2. `ArchiveSecretPolicy.isSecretPath` mengembalikan `false` untuk
///    `.git/config`, `sub/.git/config`, dan `project.sqlite` — kredensial dan
///    database proyek lolos dari arsip portabel yang meant to drop-nya.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/observability/privacy_safe_metrics.dart';
import 'package:void_scriptor/features/intent/domain/privacy_policy.dart';
import 'package:void_scriptor/features/project_resilience/application/archive_secret_policy.dart';
import 'package:void_scriptor/features/account/domain/account_center_activity_audit_overview.dart';
import 'package:void_scriptor/features/account/domain/account_center_connected_accounts_management.dart';
import 'package:void_scriptor/workflow/workflow_security.dart';
import 'package:void_scriptor/automation/external_integrations.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_privacy_assessment.dart';

void main() {
  group('117.33 gate structure', () {
    test('areas are the canonical eight, verbatim, with no additions', () {
      expect(Sprint117PrivacyAssessment.requiredAreas, <String>[
        'consent',
        'minimization',
        'destinations',
        'content_exclusion',
        'retention',
        'deletion',
        'disconnect',
        'telemetry_controls',
      ]);
      expect(Sprint117PrivacyAssessment.requiredAreas.length, 8);
      expect(
        Sprint117PrivacyAssessment.surfaceLabels.keys.toSet(),
        Sprint117PrivacyAssessment.requiredAreas.toSet(),
      );
    });

    test('empty check list fails closed', () {
      final result = Sprint117PrivacyAssessment.evaluate(
        const <Sprint117PrivacyCheck>[],
      );
      expect(result.pass, isFalse);
      expect(result.failures, contains('no_checks'));
    });

    test('every canonical area must be present', () {
      final result =
          Sprint117PrivacyAssessment.evaluate(const <Sprint117PrivacyCheck>[
            Sprint117PrivacyCheck.pass_(
              area: 'consent',
              check: 'revoke_denies',
              declared: 'revoked consent denies capture',
              observed: 'revoked consent denies capture',
            ),
          ]);
      expect(result.pass, isFalse);
      expect(
        result.failures.where((f) => f.startsWith('missing_area:')),
        hasLength(7),
      );
    });

    test(
      'an area carrying a violation cannot be covered by a passing sibling',
      () {
        // A bookmark `pass` beside a measured `violation` must not let the area
        // look validated, and the failure must NAME the area.
        final result =
            Sprint117PrivacyAssessment.evaluate(const <Sprint117PrivacyCheck>[
              Sprint117PrivacyCheck.pass_(
                area: 'minimization',
                check: 'declared_kinds_rejected',
                declared: 'undeclared dataKind denied',
                observed: 'undeclared dataKind denied',
              ),
              Sprint117PrivacyCheck.violation(
                area: 'minimization',
                check: 'strict_policy_minimizes',
                declared: 'strict policy declares an allowlist',
                observed: 'strict policy allowlist is empty',
              ),
            ]);
        expect(result.pass, isFalse);
        expect(
          result.failures,
          contains('violation:minimization:strict_policy_minimizes'),
        );
        expect(result.failures, contains('area_without_pass:minimization'));
      },
    );

    test('vacuous and unknown areas fail closed', () {
      final result =
          Sprint117PrivacyAssessment.evaluate(const <Sprint117PrivacyCheck>[
            Sprint117PrivacyCheck.pass_(
              area: 'not_a_canonical_axis',
              check: 'c',
              declared: '',
              observed: '',
            ),
          ]);
      expect(result.pass, isFalse);
      expect(result.failures, contains('vacuous:not_a_canonical_axis:c'));
      expect(result.failures, contains('unknown_area:not_a_canonical_axis'));
    });

    test('duplicate checks for one area fail closed', () {
      const check = Sprint117PrivacyCheck.pass_(
        area: 'consent',
        check: 'same',
        declared: 'd',
        observed: 'd',
      );
      final result = Sprint117PrivacyAssessment.evaluate(
        const <Sprint117PrivacyCheck>[check, check],
      );
      expect(result.pass, isFalse);
      expect(result.failures, contains('duplicate_check:consent:same'));
    });

    test('unmet is reported as an open item, never as a pass', () {
      // Every canonical area carries a passing measurement; only `deletion`
      // also carries an unmet demand, which must surface as an open item and
      // must not be counted as either a violation or a missing axis.
      final checks = <Sprint117PrivacyCheck>[
        for (final area in Sprint117PrivacyAssessment.requiredAreas)
          Sprint117PrivacyCheck.pass_(
            area: area,
            check: 'measured',
            declared: 'measured on the shipped surface',
            observed: 'measured on the shipped surface',
          ),
        const Sprint117PrivacyCheck.unmet(
          area: 'deletion',
          check: 'irreversible_delete_decision',
          declared: 'an irreversible decision exists',
          observed: 'only unlink is offered',
        ),
      ];
      final result = Sprint117PrivacyAssessment.evaluate(checks);
      expect(result.pass, isTrue, reason: 'unmet is not a violation');
      expect(result.failures, isEmpty);
      expect(
        result.openItems,
        contains('deletion:irreversible_delete_decision'),
      );
      expect(result.violationCodes, isEmpty);
    });

    test(
      'classification rejects unknown data kinds instead of assuming safe',
      () {
        expect(classifyDataKind('token'), Sprint117DataClass.credential);
        expect(
          classifyDataKind('manuscript'),
          Sprint117DataClass.creativeContent,
        );
        expect(
          classifyDataKind('user.profile'),
          Sprint117DataClass.transferBound,
        );
        expect(classifyDataKind('scene_count'), Sprint117DataClass.operational);
        // Fail-closed: an unrecognised name is not operational by default.
        expect(classifyDataKind('brand_new_kind'), Sprint117DataClass.unknown);
        expect(classifyDataKind(null), Sprint117DataClass.unknown);
        expect(classifyDataKind(''), Sprint117DataClass.unknown);
      },
    );

    test('encoded evidence is stable and round-trips the verdict', () {
      const result = Sprint117PrivacyAssessmentResult(
        checks: <Sprint117PrivacyCheck>[
          Sprint117PrivacyCheck.pass_(
            area: 'consent',
            check: 'revoke_denies',
            declared: 'd',
            observed: 'd',
          ),
        ],
        failures: <String>['missing_area:minimization'],
      );
      final json = encodeAssessment(result);
      expect(json, contains('117.33'));
      expect(json, contains('missing_area:minimization'));
      // `export` is not a canonical axis and must not appear in the area list,
      // even though the telemetry label mentions export surfaces.
      expect(result.toJson()['required_areas'], isNot(contains('export')));
    });
  });

  group('117.33 axis: consent (measured fail-closed, locked)', () {
    test('revoked consent denies every input permission', () {
      const policy = PrivacyPolicy(
        consent: InputConsent(voice: true, revoked: true),
      );
      for (final input in InputPermission.values) {
        final decision = policy.evaluate(PrivacyRequest(input: input));
        expect(decision.allowed, isFalse, reason: input.name);
        expect(decision.reason, PrivacyDenialReason.consentRevoked);
      }
    });

    test('ungranted permissions are denied by default', () {
      const policy = PrivacyPolicy(consent: InputConsent());
      for (final input in <InputPermission>[
        InputPermission.gaze,
        InputPermission.gesture,
        InputPermission.bci,
      ]) {
        expect(policy.evaluate(PrivacyRequest(input: input)).allowed, isFalse);
      }
    });
  });

  group('117.33 axis: minimization (DEFECT — strict policy is fail-open)', () {
    test('WorkflowPrivacyPolicy.strict actually declares data kinds', () {
      // RED: the policy named "strict" ships with an empty allowlist, so the
      // guarded check below can never run under it.
      expect(
        WorkflowPrivacyPolicy.strict.allowedDataKinds,
        isNotEmpty,
        reason: 'strict must declare an allowlist for minimization to be real',
      );
    });

    test('an undeclared dataKind is denied under the strict policy', () {
      // The defect was that `strict` shipped an empty allowlist while the check
      // was `isNotEmpty`-guarded, so nothing was ever minimized. A declared but
      // unlisted kind must now be denied.
      final verdict = WorkflowPrivacyEvaluator().evaluate(
        policy: WorkflowPrivacyPolicy.strict,
        transfers: <DataTransfer>[
          const DataTransfer(
            kind: DataTransferKind.inProcess,
            dataKind: 'not_declared_anywhere',
          ),
        ],
      );
      expect(
        verdict.violations.where((v) => v.contains('data_minimization')),
        isNotEmpty,
      );
    });

    test(
      'creative content and credentials are denied under the strict policy',
      () {
        // Both are the kinds a privacy policy must never pass implicitly.
        for (final kind in <String>['manuscript', 'api_key']) {
          final verdict = WorkflowPrivacyEvaluator().evaluate(
            policy: WorkflowPrivacyPolicy.strict,
            transfers: <DataTransfer>[
              DataTransfer(kind: DataTransferKind.inProcess, dataKind: kind),
            ],
          );
          expect(
            verdict.violations.where((v) => v.contains('data_minimization')),
            isNotEmpty,
            reason: 'strict must deny $kind',
          );
        }
      },
    );

    test('a transfer with no declared kind stays allowed (103.21 contract)', () {
      // An undeclared transfer carries no payload category, so minimization has
      // nothing to constrain; the shipped 103.21 test pins this behavior.
      final verdict = WorkflowPrivacyEvaluator().evaluate(
        policy: WorkflowPrivacyPolicy.strict,
        transfers: <DataTransfer>[
          const DataTransfer(kind: DataTransferKind.inProcess),
        ],
      );
      expect(verdict.allowed, isTrue);
      expect(verdict.violations, isEmpty);
    });

    test('a declared dataKind is still audited under the strict policy', () {
      final verdict = WorkflowPrivacyEvaluator().evaluate(
        policy: WorkflowPrivacyPolicy.strict,
        transfers: <DataTransfer>[
          const DataTransfer(
            kind: DataTransferKind.inProcess,
            dataKind: 'scene_count',
          ),
        ],
      );
      expect(verdict.violations, isEmpty);
    });
  });

  group('117.33 axis: destinations (measured deny-by-default, locked)', () {
    test('an empty allowlist denies every destination', () {
      final policy = AutomationNetworkPolicy(allowedDestinations: const {});
      expect(
        policy.checkRequest(destination: 'x.example', capability: 'publish'),
        NetworkDecision.deniedByDefault,
      );
    });

    test('only an explicitly allowlisted destination passes', () {
      final policy = AutomationNetworkPolicy(
        allowedDestinations: const {'good.example'},
      );
      expect(
        policy.checkRequest(destination: 'good.example', capability: 'c'),
        NetworkDecision.allowed,
      );
      expect(
        policy.checkRequest(destination: 'bad.example', capability: 'c'),
        NetworkDecision.deniedByDefault,
      );
    });
  });

  group('117.33 axis: content_exclusion (DEFECT — secrets survive export)', () {
    test('git config carries credentials and must be excluded', () {
      expect(
        ArchiveSecretPolicy.isSecretPath('.git/config'),
        isTrue,
        reason: '.git/config can hold remote URLs with embedded tokens',
      );
      expect(ArchiveSecretPolicy.isSecretPath('sub/.git/config'), isTrue);
    });

    test('shareable templates are still allowed', () {
      expect(ArchiveSecretPolicy.isSecretPath('.env.example'), isFalse);
      expect(ArchiveSecretPolicy.isSecretPath('notes.md'), isFalse);
    });
  });

  group('117.33 axis: retention (green since 117.31, locked)', () {
    test('non-positive retention is rejected', () {
      for (final retention in <Duration>[
        Duration.zero,
        const Duration(days: -1),
      ]) {
        expect(
          () => AccountCenterActivityAuditOverview(
            retention: retention,
            events: const <AccountAuditEvent>[],
            now: () => DateTime.utc(2026),
          ),
          throwsArgumentError,
          reason: 'retention=$retention',
        );
      }
    });

    test('events older than the cutoff are not retained', () {
      final overview = AccountCenterActivityAuditOverview(
        retention: const Duration(days: 30),
        events: <AccountAuditEvent>[
          AccountAuditEvent(
            id: 'old',
            category: AccountAuditCategory.account,
            occurredAt: DateTime.utc(2020),
            actor: const AccountAuditActor(id: 'u1', displayName: 'U'),
            result: AccountAuditResult.succeeded,
            details: const <String, Object?>{'k': 'v'},
            sensitiveDetailKeys: const <String>{'k'},
          ),
        ],
        now: () => DateTime.utc(2026, 10, 1),
      );
      expect(overview.retainedEvents, isEmpty);
    });
  });

  group('117.33 axis: disconnect (measured, locked)', () {
    test('a result cannot claim a revocation that was never attempted', () {
      // The constructor itself rejects the impossible combination, so a
      // caller can trust the flag it reads.
      expect(
        () => AccountDisconnectResult(
          connectionId: 'c1',
          providerRevokeAttempted: false,
          providerRevoked: true,
          localRemoved: false,
        ),
        throwsArgumentError,
      );
    });

    test('an unattempted revoke is reported as unattempted, not granted', () {
      final result = AccountDisconnectResult(
        connectionId: 'c1',
        providerRevokeAttempted: false,
        providerRevoked: false,
        localRemoved: false,
      );
      expect(result.providerRevoked, isFalse);
      expect(result.providerRevokeAttempted, isFalse);
    });
  });

  group('117.33 axis: telemetry_controls (DEFECT — unbounded surface)', () {
    test('metric rows never carry creative content keys', () {
      final metrics = PrivacySafeMetrics(knownFlags: const {'flag_a'})
        ..optIn = true;
      metrics.increment(
        flag: 'flag_a',
        surface: 'chapter_editor',
        outcome: 'used',
      );
      for (final row in metrics.snapshot()) {
        for (final key in row.keys) {
          expect(kAllowedMetricKeys, contains(key));
        }
      }
    });

    test('an unknown flag is dropped rather than recorded', () {
      final metrics = PrivacySafeMetrics(knownFlags: const {'known'})
        ..optIn = true;
      metrics.increment(flag: 'unknown_flag', surface: 's', outcome: 'used');
      expect(metrics.snapshot(), isEmpty);
    });

    test('metrics are opt-in: nothing is recorded before opt-in', () {
      final metrics = PrivacySafeMetrics(knownFlags: const {'known'});
      metrics.increment(flag: 'known', surface: 's', outcome: 'used');
      expect(metrics.snapshot(), isEmpty);
      expect(metrics.isOptIn, isFalse);
    });
  });
}
