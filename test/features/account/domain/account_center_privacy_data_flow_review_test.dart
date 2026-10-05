/// Sprint 115.50 — Privacy & Data-Flow Review.
///
/// Locks the eight canonical `required_outputs` for step 115.50 and the eight
/// data subjects the objective asks to document (`account metadata, tokens,
/// usage, storage, billing, diagnostics, retention, and external transfers`),
/// then grounds the review in live code: closed usage fields, opt-in-off
/// metrics, secret redaction, credential-free session JSON, redacted audit
/// details, and a source scan proving no account surface performs network I/O
/// in this build.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/core/auth/auth_session_store.dart';
import 'package:void_scriptor/core/auth/auth_status.dart';
import 'package:void_scriptor/core/observability/privacy_safe_metrics.dart';
import 'package:void_scriptor/core/security/application/secret_redactor.dart';
import 'package:void_scriptor/features/account/domain/account_center_activity_audit_overview.dart';
import 'package:void_scriptor/features/account/domain/account_center_ai_usage_report.dart';
import 'package:void_scriptor/features/account/domain/account_center_privacy_data_flow_review.dart';
import '../../../canonical_source_support.dart';

void main() {
  const canonicalStepsPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/sprint_115.json';
  const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_privacy_data_flow_review.json',
  );

  Map<String, dynamic> readManifest() {
    expect(manifestFile.existsSync(), isTrue, reason: '115.50 manifest');
    return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  }

  group('115.50 required_outputs bucket', () {
    test('locks the eight canonical outputs in canonical order', () {
      expect(AccountCenterPrivacyDataFlowReview.requiredOutputs, const <String>[
        'data_flow',
        'classification',
        'consent',
        'retention',
        'deletion',
        'external_transfer',
        'redaction',
        'privacy_defaults',
      ]);
    });

    test('matches the canonical sprint step definition', () {
      if (skipUnlessExternalCanonical(
        "matches the canonical sprint step definition",
      )) {
        return;
      }
      final file = File(canonicalStepsPath);
      expect(file.existsSync(), isTrue, reason: 'canonical sprint_115.json');
      expect(
        sha256.convert(file.readAsBytesSync()).toString(),
        canonicalSprintSha256,
        reason: 'canonical sprint hash drift',
      );
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final steps = document['steps'] as List<dynamic>;
      final step = steps.cast<Map<String, dynamic>>().firstWhere(
        (entry) => entry['id'] == '115.50',
      );
      expect(step['title'], 'Privacy & Data-Flow Review');
      expect(
        step['required_outputs'],
        AccountCenterPrivacyDataFlowReview.requiredOutputs,
        reason: 'required_outputs must be transcribed, not invented',
      );
    });

    test('rejects a bucket outside the canonical set', () {
      expect(
        () => AccountCenterPrivacyDataFlowReview.buildReport({
          for (final key in AccountCenterPrivacyDataFlowReview.requiredOutputs)
            key: const AccountCenterPrivacyOutput(
              localResult: 'PASS',
              note: 'ok',
            ),
          'extra_bucket': const AccountCenterPrivacyOutput(
            localResult: 'PASS',
            note: 'not canonical',
          ),
        }),
        throwsArgumentError,
      );
    });

    test('fails closed when a canonical bucket is missing', () {
      expect(
        () => AccountCenterPrivacyDataFlowReview.buildReport({
          'data_flow': const AccountCenterPrivacyOutput(
            localResult: 'PASS',
            note: 'only one',
          ),
        }),
        throwsStateError,
      );
    });

    test('isPass only when every canonical bucket reports PASS', () {
      final pass = AccountCenterPrivacyDataFlowReview.buildReport({
        for (final key in AccountCenterPrivacyDataFlowReview.requiredOutputs)
          key: const AccountCenterPrivacyOutput(
            localResult: 'PASS',
            note: 'ok',
          ),
      });
      expect(pass.isPass, isTrue);
      expect(
        pass.toPublicJson().keys.toList(),
        AccountCenterPrivacyDataFlowReview.requiredOutputs,
      );

      final withGap = AccountCenterPrivacyDataFlowReview.buildReport({
        for (final key in AccountCenterPrivacyDataFlowReview.requiredOutputs)
          key: AccountCenterPrivacyOutput(
            localResult: key == 'deletion' ? 'GAP' : 'PASS',
            note: key == 'deletion' ? 'no per-row purge yet' : 'ok',
          ),
      });
      expect(withGap.isPass, isFalse);
      expect(withGap.toPublicJson()['deletion'], 'GAP');
    });
  });

  group('115.50 data subjects', () {
    test('locks the eight subjects named by the objective, in order', () {
      expect(AccountCenterPrivacyDataFlowReview.subjectIds, const <String>[
        'account_metadata',
        'tokens',
        'usage',
        'storage',
        'billing',
        'diagnostics',
        'retention',
        'external_transfers',
      ]);
    });

    test('default inventory documents every subject on every dimension', () {
      final review = AccountCenterPrivacyDataFlowReview.buildReview(
        Map.of(AccountCenterPrivacyDataFlowReview.defaultInventory),
      );
      expect(
        review.keys.toList(),
        AccountCenterPrivacyDataFlowReview.subjectIds,
      );
      for (final record in review.values) {
        expect(record.dataFlow.trim(), isNotEmpty);
        expect(record.retention.trim(), isNotEmpty);
        expect(record.deletion.trim(), isNotEmpty);
        expect(record.redaction.trim(), isNotEmpty);
      }
    });

    test('rejects a subject outside the canonical set', () {
      expect(
        () => AccountCenterPrivacyDataFlowReview.buildReview({
          'unknown_subject': const AccountPrivacySubjectRecord(
            subject: AccountPrivacySubject.accountMetadata,
            dataFlow: 'x',
            classification: AccountDataClass.personalLocal,
            consent: AccountConsentBasis.notRequiredLocalOnly,
            retention: 'x',
            deletion: 'x',
            externalTransfer: AccountExternalTransferKind.noneLocalOnly,
            redaction: 'x',
            privacyDefault: AccountPrivacyDefault.localOnly,
          ),
        }),
        throwsArgumentError,
      );
    });

    test('fails closed when a subject is missing', () {
      final incomplete = Map.of(
        AccountCenterPrivacyDataFlowReview.defaultInventory,
      )..remove('tokens');
      expect(
        () => AccountCenterPrivacyDataFlowReview.buildReview(incomplete),
        throwsStateError,
      );
    });

    test('rejects an empty documentation dimension', () {
      final broken = Map.of(
        AccountCenterPrivacyDataFlowReview.defaultInventory,
      );
      final tokens = broken['tokens']!;
      broken['tokens'] = AccountPrivacySubjectRecord(
        subject: tokens.subject,
        dataFlow: tokens.dataFlow,
        classification: tokens.classification,
        consent: tokens.consent,
        retention: '   ',
        deletion: tokens.deletion,
        externalTransfer: tokens.externalTransfer,
        redaction: tokens.redaction,
        privacyDefault: tokens.privacyDefault,
      );
      expect(
        () => AccountCenterPrivacyDataFlowReview.buildReview(broken),
        throwsArgumentError,
      );
    });

    test('tokens must never be classified below credential/secret', () {
      final broken = Map.of(
        AccountCenterPrivacyDataFlowReview.defaultInventory,
      );
      final tokens = broken['tokens']!;
      broken['tokens'] = AccountPrivacySubjectRecord(
        subject: tokens.subject,
        dataFlow: tokens.dataFlow,
        classification: AccountDataClass.personalLocal,
        consent: tokens.consent,
        retention: tokens.retention,
        deletion: tokens.deletion,
        externalTransfer: tokens.externalTransfer,
        redaction: tokens.redaction,
        privacyDefault: tokens.privacyDefault,
      );
      expect(
        () => AccountCenterPrivacyDataFlowReview.buildReview(broken),
        throwsArgumentError,
      );
    });

    test('a live external transfer demands explicit consent', () {
      final broken = Map.of(
        AccountCenterPrivacyDataFlowReview.defaultInventory,
      );
      final tokens = broken['tokens']!;
      broken['tokens'] = AccountPrivacySubjectRecord(
        subject: tokens.subject,
        dataFlow: tokens.dataFlow,
        classification: tokens.classification,
        consent: AccountConsentBasis.notRequiredLocalOnly,
        retention: tokens.retention,
        deletion: tokens.deletion,
        externalTransfer: AccountExternalTransferKind.deferredProviderApi,
        redaction: tokens.redaction,
        privacyDefault: tokens.privacyDefault,
      );
      expect(
        () => AccountCenterPrivacyDataFlowReview.buildReview(broken),
        throwsArgumentError,
      );

      final fixed = Map.of(broken);
      fixed['tokens'] = AccountPrivacySubjectRecord(
        subject: tokens.subject,
        dataFlow: tokens.dataFlow,
        classification: tokens.classification,
        consent: AccountConsentBasis.deferredScopedOAuth,
        retention: tokens.retention,
        deletion: tokens.deletion,
        externalTransfer: AccountExternalTransferKind.deferredProviderApi,
        redaction: tokens.redaction,
        privacyDefault: tokens.privacyDefault,
      );
      expect(
        AccountCenterPrivacyDataFlowReview.buildReview(fixed).keys.length,
        AccountCenterPrivacyDataFlowReview.subjectIds.length,
      );
    });

    test('no subject claims a live external transfer in this build', () {
      const review = AccountCenterPrivacyDataFlowReview.defaultInventory;
      for (final record in review.values) {
        expect(
          record.externalTransfer,
          AccountExternalTransferKind.noneLocalOnly,
          reason:
              'account feature has no network client; a non-local claim must '
              'come with a live, consented transfer, not documentation',
        );
      }
    });
  });

  group('115.50 live-code grounding', () {
    test('usage rows cannot carry prompt or creative content', () {
      final forbidden = RegExp(
        'prompt|content|excerpt|title|body|manuscript|scene',
        caseSensitive: false,
      );
      expect(
        AiUsageRow.publicFields.where(forbidden.hasMatch),
        isEmpty,
        reason: 'publicFields is the closed set usage analytics may publish',
      );
      expect(
        AiUsageRow.publicFields,
        containsAll(<String>{
          'provider_id',
          'model_id',
          'quantity',
          'unit',
          'billing_period',
          'measured_at',
          'is_estimate',
        }),
      );
    });

    test('diagnostics stay opt-in default OFF and deny-by-default', () {
      final metrics = PrivacySafeMetrics(knownFlags: <String>{'export'});
      expect(metrics.optIn, isFalse, reason: 'privacy default is OFF');
      metrics.increment(flag: 'export', surface: 'account', outcome: 'used');
      expect(metrics.snapshot(), isEmpty, reason: 'opt-in OFF records nothing');

      metrics.optIn = true;
      metrics.increment(
        flag: 'unknown_flag',
        surface: 'account',
        outcome: 'used',
      );
      expect(metrics.snapshot(), isEmpty, reason: 'unknown flag dropped');
      metrics.increment(flag: 'export', surface: 'account', outcome: 'used');
      expect(metrics.snapshot(), hasLength(1));
      expect(metrics.snapshot().single.keys.toSet(), <String>{
        'flag',
        'surface',
        'outcome',
        'count',
      });
    });

    test('secret redaction masks and rewrites secrets', () {
      const redactor = SecretRedactor();
      expect(redactor.mask('sk-abcdefghij'), 'sk-****');
      expect(redactor.mask('ab'), '****');
      expect(
        redactor.redact(
          'key=sk-abcdefghij ok',
          secrets: <String>['sk-abcdefghij'],
        ),
        'key=[REDACTED] ok',
      );
    });

    test('persisted session JSON never carries a credential', () {
      const session = AuthSession(
        status: AuthStatus.authenticated,
        userId: 'u-1',
        displayName: 'Choi',
        email: 'choi@example.test',
      );
      expect(session.toJson().keys.toSet(), <String>{
        'status',
        'displayName',
        'userId',
        'email',
      });
      expect(
        session.toJson().keys.where(
          RegExp('password|secret|token|credential').hasMatch,
        ),
        isEmpty,
      );
    });

    test('audit details redact sensitive keys before publication', () {
      final event = AccountAuditEvent(
        id: 'evt-1',
        category: AccountAuditCategory.security,
        occurredAt: DateTime.utc(2026, 9, 27, 1),
        actor: const AccountAuditActor(id: 'u-1', displayName: 'Choi'),
        result: AccountAuditResult.succeeded,
        details: <String, Object?>{
          'provider': 'drive',
          'api_key': 'sk-super-secret',
        },
        sensitiveDetailKeys: const <String>{'api_key'},
      );
      expect(event.publicDetails['api_key'], '[REDACTED]');
      expect(event.publicDetails['provider'], 'drive');
      expect(event.toPublicJson().toString(), contains('[REDACTED]'));
      expect(
        event.toPublicJson().toString(),
        isNot(contains('sk-super-secret')),
      );
    });

    test('no account surface opens a network client in this build', () {
      final offenders = <String>[];
      final scanRoot = Directory('lib/features/account');
      expect(scanRoot.existsSync(), isTrue);
      for (final entity in scanRoot.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        for (final token in <String>[
          'package:http',
          'package:dio',
          'HttpClient(',
          'WebSocket.connect',
          'url_launcher',
        ]) {
          if (source.contains(token)) {
            offenders.add('${entity.path} -> $token');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'external_transfer=none must be a source fact, not a doc claim',
      );
    });
  });

  group('115.50 manifest', () {
    test('records the canonical step, sources, and every required output', () {
      final manifest = readManifest();
      expect(manifest['canonical_step'], '115.50');
      expect(manifest['title'], 'Privacy & Data-Flow Review');
      final sources = manifest['sources'] as Map<String, dynamic>;
      final canonical = sources['canonical_steps'] as Map<String, dynamic>;
      expect(canonical['sha256'], canonicalSprintSha256);
      expect(
        canonical['required_outputs'],
        AccountCenterPrivacyDataFlowReview.requiredOutputs,
      );
      final outputs = manifest['required_outputs'] as Map<String, dynamic>;
      expect(
        outputs.keys.toList(),
        AccountCenterPrivacyDataFlowReview.requiredOutputs,
      );
      for (final key in AccountCenterPrivacyDataFlowReview.requiredOutputs) {
        final bucket = outputs[key] as Map<String, dynamic>;
        expect(bucket['local_result'], isNotEmpty, reason: key);
        expect(bucket['verified_by'], isNotEmpty, reason: key);
        expect(bucket['note'], isNotEmpty, reason: key);
      }
    });

    test('documents the same subjects as the domain inventory', () {
      final manifest = readManifest();
      final subjects = (manifest['data_subjects'] as List<dynamic>).toList();
      expect(subjects, AccountCenterPrivacyDataFlowReview.subjectIds);
    });
  });
}
