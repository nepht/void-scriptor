import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_activity_audit_overview.dart';

void main() {
  group('AccountCenterActivityAuditOverview', () {
    test('manifest preserves every canonical 115.31 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_activity_audit_overview.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.31');
      expect(manifest['acceptance'], <String>[
        'filters',
        'timestamps',
        'actor',
        'result',
        'redaction',
        'retention',
        'detail_link',
      ]);
    });

    test('filters retained events and orders them by newest timestamp', () {
      final overview = AccountCenterActivityAuditOverview(
        retention: const Duration(days: 30),
        now: () => DateTime.utc(2026, 9, 26, 12),
        events: [
          _event(
            id: 'old',
            category: AccountAuditCategory.backup,
            occurredAt: DateTime.utc(2026, 8, 1),
          ),
          _event(
            id: 'newer',
            category: AccountAuditCategory.security,
            result: AccountAuditResult.denied,
            occurredAt: DateTime.utc(2026, 9, 26, 10),
          ),
          _event(
            id: 'older',
            category: AccountAuditCategory.security,
            result: AccountAuditResult.succeeded,
            occurredAt: DateTime.utc(2026, 9, 25, 10),
          ),
        ],
      );

      final events = overview.query(
        AccountAuditFilter(
          categories: const {AccountAuditCategory.security},
          results: const {
            AccountAuditResult.succeeded,
            AccountAuditResult.denied,
          },
          from: DateTime.utc(2026, 9, 24),
          to: DateTime.utc(2026, 9, 26, 12),
        ),
      );

      expect(events.map((event) => event.id), ['newer', 'older']);
      expect(overview.retentionCutoff, DateTime.utc(2026, 8, 27, 12));
      expect(overview.retainedEvents.map((event) => event.id), [
        'newer',
        'older',
      ]);
    });

    test('preserves actor result and a validated detail link', () {
      final event = _event(
        id: 'connection-1',
        category: AccountAuditCategory.connection,
        result: AccountAuditResult.failed,
        occurredAt: DateTime.utc(2026, 9, 26, 9),
        detailLink: '/account/cloud-center?tab=connections&event=connection-1',
      );

      expect(event.actor.id, 'account-owner');
      expect(event.actor.displayName, 'Account Owner');
      expect(event.result, AccountAuditResult.failed);
      expect(
        event.detailLink,
        '/account/cloud-center?tab=connections&event=connection-1',
      );
      expect(event.occurredAt.isUtc, isTrue);
    });

    test('redacts sensitive values without mutating source details', () {
      final source = <String, Object?>{
        'provider': 'github',
        'token': 'secret-value',
        'billing_reference': 'invoice-private',
      };
      final event = AccountAuditEvent(
        id: 'sensitive-1',
        category: AccountAuditCategory.sensitiveAction,
        occurredAt: DateTime.utc(2026, 9, 26, 8),
        actor: const AccountAuditActor(
          id: 'account-owner',
          displayName: 'Account Owner',
        ),
        result: AccountAuditResult.succeeded,
        details: source,
        sensitiveDetailKeys: const {'token', 'billing_reference'},
        detailLink: '/account/cloud-center?tab=security&event=sensitive-1',
      );

      expect(event.publicDetails, <String, Object?>{
        'provider': 'github',
        'token': '[REDACTED]',
        'billing_reference': '[REDACTED]',
      });
      expect(source['token'], 'secret-value');
      expect(() => event.publicDetails['extra'] = true, throwsUnsupportedError);
      expect(event.toPublicJson().toString(), isNot(contains('secret-value')));
      expect(
        event.toPublicJson().toString(),
        isNot(contains('invoice-private')),
      );
    });

    test(
      'fails closed for invalid retention ids timestamps and detail links',
      () {
        expect(
          () => AccountCenterActivityAuditOverview(
            retention: Duration.zero,
            events: const [],
          ),
          throwsArgumentError,
        );
        expect(
          () => AccountAuditEvent(
            id: ' ',
            category: AccountAuditCategory.account,
            occurredAt: DateTime.utc(2026, 9, 26),
            actor: const AccountAuditActor(id: 'actor', displayName: 'Actor'),
            result: AccountAuditResult.succeeded,
            details: const {},
            sensitiveDetailKeys: const {},
          ),
          throwsArgumentError,
        );
        expect(
          () => _event(
            id: 'local-time',
            category: AccountAuditCategory.account,
            occurredAt: DateTime(2026, 9, 26),
          ),
          throwsArgumentError,
        );
        expect(
          () => _event(
            id: 'external-link',
            category: AccountAuditCategory.account,
            occurredAt: DateTime.utc(2026, 9, 26),
            detailLink: 'https://example.invalid/event',
          ),
          throwsArgumentError,
        );
      },
    );
  });
}

AccountAuditEvent _event({
  required String id,
  required AccountAuditCategory category,
  required DateTime occurredAt,
  AccountAuditResult result = AccountAuditResult.succeeded,
  String? detailLink,
}) => AccountAuditEvent(
  id: id,
  category: category,
  occurredAt: occurredAt,
  actor: const AccountAuditActor(
    id: 'account-owner',
    displayName: 'Account Owner',
  ),
  result: result,
  details: const {'summary': 'Recorded locally'},
  sensitiveDetailKeys: const {},
  detailLink: detailLink,
);
