import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_quick_actions.dart';

const String _productSpecPath =
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
    'referenced-chatgpt-conversation-this-is-an-2/outputs/'
    'account_cloud_center_spec.json';

const Set<QuickActionKind> _allActions = <QuickActionKind>{
  QuickActionKind.syncNow,
  QuickActionKind.backupNow,
  QuickActionKind.manageApiKeys,
  QuickActionKind.inviteTeamMember,
  QuickActionKind.browseMarketplace,
  QuickActionKind.openSettings,
};

void main() {
  group('AccountCenterQuickActions', () {
    test('manifest preserves every canonical 115.39 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_quick_actions.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.39');
      expect(manifest['acceptance'], <String>[
        'permission_aware',
        'disabled_reason',
        'confirmation',
        'progress',
        'result',
        'audit',
      ]);
      expect(
        manifest['implementation'],
        'lib/features/account/domain/account_center_quick_actions.dart',
      );
      expect(
        manifest['evidence'],
        'test/features/account/domain/account_center_quick_actions_test.dart',
      );
    });

    test('acceptance list is pinned to canonical sprint 115.39', () {
      final file = File(AccountCenterQuickActions.canonicalSprintPath);
      expect(file.existsSync(), isTrue);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final step = (json['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == '115.39');

      expect(step['title'], 'Quick Actions');
      expect(step['acceptance'], AccountCenterQuickActions.canonicalAcceptance);
      expect(
        AccountCenterQuickActions.canonicalSprintSha256,
        'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
      );
    });

    test('product spec keeps quick actions and the no-fake-data rules', () {
      final spec =
          jsonDecode(File(_productSpecPath).readAsStringSync())
              as Map<String, Object?>;
      final sections = spec['information_architecture'] as Map<String, Object?>;

      expect(sections['right_summary_sections'], contains('quick_actions'));
      expect(
        (spec['acceptance_invariants'] as List<dynamic>),
        contains(
          'storage_and_credit_values_are_api_backed_or_explicitly_unavailable',
        ),
      );
      expect(
        (spec['acceptance_invariants'] as List<dynamic>),
        contains('reference_mock_values_never_reach_production_state'),
      );
      expect(
        (spec['security_contract']
            as Map<String, Object?>)['sensitive_actions'],
        contains('reveal_or_replace_key'),
      );
      expect(
        (spec['settings_entitlements_payment_integration']
            as Map<String, Object?>)['settings_authority'],
        contains('PREFERENCES'),
      );
      expect((spec['ui_states'] as List<dynamic>), contains('REAUTH_REQUIRED'));
    });

    test('the six canonical quick actions are the ones the rail offers', () {
      expect(AccountCenterQuickActions.canonicalActionKinds, <QuickActionKind>[
        QuickActionKind.syncNow,
        QuickActionKind.backupNow,
        QuickActionKind.manageApiKeys,
        QuickActionKind.inviteTeamMember,
        QuickActionKind.browseMarketplace,
        QuickActionKind.openSettings,
      ]);
    });

    group('permission_aware', () {
      test('unknown permission state disables every action', () {
        final surface = _surface();

        for (final kind in AccountCenterQuickActions.canonicalActionKinds) {
          final resolution = surface.resolve(kind);
          expect(
            resolution.isEnabled,
            isFalse,
            reason:
                '${kind.wireName} must be disabled when permission is unknown',
          );
          expect(resolution.availability, QuickActionAvailability.disabled);
        }
      });

      test('granted permission enables only the declared actions', () {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
        );

        expect(surface.resolve(QuickActionKind.syncNow).isEnabled, isTrue);
        expect(surface.resolve(QuickActionKind.openSettings).isEnabled, isTrue);
        expect(
          surface.resolve(QuickActionKind.browseMarketplace).isEnabled,
          isTrue,
        );
      });

      test('a denied permission disables only the action it names', () {
        final surface = _surface(
          permissions: const QuickActionPermissionSet(
            denied: <QuickActionKind>{QuickActionKind.inviteTeamMember},
          ),
        );

        expect(surface.resolve(QuickActionKind.syncNow).isEnabled, isTrue);
        expect(
          surface.resolve(QuickActionKind.inviteTeamMember).isEnabled,
          isFalse,
        );
      });

      test('a permission that names an undeclared action is rejected', () {
        final surface = _surface(
          actions: const <QuickActionKind>{QuickActionKind.openSettings},
          permissions: const QuickActionPermissionSet(
            denied: <QuickActionKind>{QuickActionKind.syncNow},
          ),
        );

        expect(surface.resolve(QuickActionKind.openSettings).isGranted, isTrue);
        expect(
          () => surface.resolve(QuickActionKind.syncNow),
          throwsA(isA<StateError>()),
        );
      });

      test('an undeclared action cannot be resolved or run', () {
        final surface = _surface(
          actions: const <QuickActionKind>{QuickActionKind.syncNow},
          permissions: const QuickActionPermissionSet.grantedAll(),
        );

        expect(
          () => surface.resolve(QuickActionKind.browseMarketplace),
          throwsA(isA<StateError>()),
        );
        expect(
          () => surface.run(QuickActionKind.browseMarketplace),
          throwsA(isA<StateError>()),
        );
      });

      test('the surface exposes its declared actions in canonical order', () {
        expect(
          _surface().actions,
          AccountCenterQuickActions.canonicalActionKinds,
        );
      });
    });

    group('disabled_reason', () {
      test('every disabled action carries a non-blank reason', () {
        final surface = _surface(
          permissions: const QuickActionPermissionSet(
            denied: <QuickActionKind>{QuickActionKind.backupNow},
          ),
        );

        var checked = 0;
        for (final kind in AccountCenterQuickActions.canonicalActionKinds) {
          final resolution = surface.resolve(kind);
          if (resolution.isEnabled) continue;
          checked++;
          expect(
            resolution.disabledReason,
            isNotNull,
            reason: '${kind.wireName} is disabled without a reason',
          );
          expect(resolution.disabledReason!.trim(), isNotEmpty);
        }
        expect(checked, greaterThan(0));
      });

      test('an enabled action has no disabled reason', () {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
        );

        final resolution = surface.resolve(QuickActionKind.syncNow);
        expect(resolution.isEnabled, isTrue);
        expect(resolution.disabledReason, isNull);
      });

      test('a caller-supplied denial reason survives to the surface', () {
        final surface = _surface(
          permissions: const QuickActionPermissionSet(
            denied: <QuickActionKind>{QuickActionKind.inviteTeamMember},
            denialReasons: <QuickActionKind, String>{
              QuickActionKind.inviteTeamMember: 'Seat limit reached',
            },
          ),
        );

        expect(
          surface.resolve(QuickActionKind.inviteTeamMember).disabledReason,
          'Seat limit reached',
        );
      });

      test('a denied action with no reason falls back to a generic one', () {
        final surface = _surface(
          permissions: const QuickActionPermissionSet(
            denied: <QuickActionKind>{QuickActionKind.inviteTeamMember},
          ),
        );

        expect(
          surface.resolve(QuickActionKind.inviteTeamMember).disabledReason,
          'Not permitted',
        );
      });

      test('an unknown permission source names itself as the reason', () {
        expect(
          _surface().denialReasonFor(QuickActionKind.syncNow),
          'Permission state unavailable',
        );
      });
    });

    group('confirmation', () {
      test('a consequential action is unavailable until confirmed', () {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
        );

        final unconfirmed = surface.resolve(QuickActionKind.backupNow);
        expect(unconfirmed.availability, QuickActionAvailability.disabled);
        expect(unconfirmed.requiresConfirmation, isTrue);
        expect(unconfirmed.disabledReason, isNotNull);

        final confirmed = surface.resolve(
          QuickActionKind.backupNow,
          confirmed: true,
        );
        expect(confirmed.availability, QuickActionAvailability.enabled);
        expect(confirmed.disabledReason, isNull);
      });

      test('an unconfirmed run is refused and records no result', () {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
        );

        expect(
          () => surface.run(QuickActionKind.backupNow),
          throwsA(isA<QuickActionStateError>()),
        );
        expect(surface.stateOf(QuickActionKind.backupNow), isNull);
        expect(surface.results, isEmpty);
      });

      test('a confirmed consequential action runs', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          execute: (kind) async => 'Backup written',
        );

        final result = await surface.run(
          QuickActionKind.backupNow,
          confirmed: true,
        );

        expect(result.isSuccess, isTrue);
        expect(result.message, 'Backup written');
      });

      test('non-consequential actions need no confirmation', () {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
        );

        expect(
          surface.resolve(QuickActionKind.openSettings).requiresConfirmation,
          isFalse,
        );
        expect(surface.resolve(QuickActionKind.openSettings).isEnabled, isTrue);
      });

      test('a denied action cannot be confirmed into running', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet(
            denied: <QuickActionKind>{QuickActionKind.backupNow},
          ),
          execute: (kind) async => 'Backup written',
        );

        // The refusal is synchronous: nothing was ever scheduled.
        expect(
          () => surface.run(QuickActionKind.backupNow, confirmed: true),
          throwsA(isA<QuickActionStateError>()),
        );
        expect(surface.results, isEmpty);
      });
    });

    test('an action mapped to sensitive_actions refuses before reauth', () {
      final surface = _surface(
        permissions: const QuickActionPermissionSet.grantedAll(),
        reauthenticate: () => false,
      );

      final resolution = surface.resolve(QuickActionKind.manageApiKeys);
      expect(QuickActionKind.manageApiKeys.isSensitive, isTrue);
      expect(resolution.availability, QuickActionAvailability.disabled);
      expect(resolution.requiresReauthentication, isTrue);

      expect(
        () => surface.run(QuickActionKind.manageApiKeys),
        throwsA(isA<QuickActionStateError>()),
      );
      expect(
        surface.audit.where(
          (event) => event.outcome == QuickActionAuditOutcome.denied,
        ),
        hasLength(1),
      );
    });

    test('a missing reauth broker is fail-closed for a sensitive action', () {
      final surface = _surface(
        permissions: const QuickActionPermissionSet.grantedAll(),
      );

      expect(
        () => surface.run(QuickActionKind.manageApiKeys),
        throwsA(isA<QuickActionStateError>()),
      );
      expect(surface.audit.single.outcome, QuickActionAuditOutcome.denied);
    });

    test(
      'reauthentication happens before the run and unlocks the action',
      () async {
        var reauthCalls = 0;
        var executed = 0;
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          reauthenticate: () {
            reauthCalls++;
            return true;
          },
          execute: (kind) async {
            executed++;
            return 'Keys opened';
          },
        );

        final result = await surface.run(QuickActionKind.manageApiKeys);

        expect(reauthCalls, 1);
        expect(executed, 1);
        expect(result.isSuccess, isTrue);
        expect(surface.audit.last.outcome, QuickActionAuditOutcome.succeeded);
      },
    );

    group('progress', () {
      test(
        'a run starts idle, reports monotonic progress, and succeeds',
        () async {
          final surface = _surface(
            permissions: const QuickActionPermissionSet.grantedAll(),
            execute: (kind) async => 'Synced',
          );

          expect(surface.stateOf(QuickActionKind.syncNow), isNull);

          final progress = <QuickActionProgress>[];
          final result = await surface.run(
            QuickActionKind.syncNow,
            onProgress: progress.add,
          );

          expect(result.isSuccess, isTrue);
          expect(
            surface.stateOf(QuickActionKind.syncNow)!.phase,
            QuickActionPhase.succeeded,
          );
          expect(progress, isNotEmpty);
          for (var i = 1; i < progress.length; i++) {
            expect(
              progress[i].fraction,
              greaterThanOrEqualTo(progress[i - 1].fraction),
              reason: 'progress must never go backwards',
            );
          }
          expect(progress.first.fraction, 0);
          expect(progress.last.fraction, 1);
          expect(
            surface.progressOf(QuickActionKind.syncNow).map((s) => s.fraction),
            progress.map((s) => s.fraction),
          );
        },
      );

      test('reported progress is clamped into 0..1 and never NaN', () {
        expect(QuickActionProgress(fraction: double.nan).fraction, 0);
        expect(QuickActionProgress(fraction: -5).fraction, 0);
        expect(QuickActionProgress(fraction: 7).fraction, 1);
        expect(QuickActionProgress(fraction: 0.25).fraction, 0.25);
      });

      test('a concurrent run of the same action is refused', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          execute: (kind) async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return 'Synced';
          },
        );

        final first = surface.run(QuickActionKind.syncNow);
        expect(
          () => surface.run(QuickActionKind.syncNow),
          throwsA(isA<QuickActionStateError>()),
        );
        final result = await first;

        expect(result.isSuccess, isTrue);
        expect(surface.results, hasLength(1));
      });

      test('a different action may run while one is in flight', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          execute: (kind) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 'Done';
          },
        );

        final first = surface.run(QuickActionKind.syncNow);
        final second = surface.run(QuickActionKind.browseMarketplace);

        expect((await first).isSuccess, isTrue);
        expect((await second).isSuccess, isTrue);
      });
    });

    group('result', () {
      test(
        'a successful run records the message the executor returned',
        () async {
          final surface = _surface(
            permissions: const QuickActionPermissionSet.grantedAll(),
            execute: (kind) async => '3 files synced',
          );

          final result = await surface.run(QuickActionKind.syncNow);

          expect(result.isSuccess, isTrue);
          expect(result.message, '3 files synced');
          expect(result.completedAt, isNotNull);
          expect(result.completedAt.isUtc, isTrue);
          expect(surface.results.single.message, '3 files synced');
          expect(result.toPublicJson()['action'], 'sync_now');
        },
      );

      test(
        'a failing executor records a failed result, not an exception',
        () async {
          final surface = _surface(
            permissions: const QuickActionPermissionSet.grantedAll(),
            execute: (kind) async => throw StateError('provider unavailable'),
          );

          final result = await surface.run(QuickActionKind.syncNow);

          expect(result.isSuccess, isFalse);
          expect(result.message, contains('provider unavailable'));
          expect(
            surface.stateOf(QuickActionKind.syncNow)!.phase,
            QuickActionPhase.failed,
          );
        },
      );

      test(
        'a missing executor is a failed result, never a silent success',
        () async {
          final surface = AccountCenterQuickActions(
            actions: _allActions,
            permissions: const QuickActionPermissionSet.grantedAll(),
          );

          final result = await surface.run(QuickActionKind.syncNow);

          expect(result.isSuccess, isFalse);
          expect(result.message, contains('no executor'));
        },
      );

      test('a blank executor message still yields a visible message', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          execute: (kind) async => '   ',
        );

        final result = await surface.run(QuickActionKind.syncNow);

        expect(result.isSuccess, isTrue);
        expect(result.message!.trim(), isNotEmpty);
      });

      test('a run cancelled before it starts lands in cancelled', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          execute: (kind) async => 'Synced',
        );

        surface.cancel(QuickActionKind.syncNow);
        final result = await surface.run(QuickActionKind.syncNow);

        expect(result.isSuccess, isFalse);
        expect(result.phase, QuickActionPhase.cancelled);
        expect(result.message, isNotNull);
      });

      test('a run that is cancelled mid-flight lands in cancelled', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          execute: (kind) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 'Synced';
          },
        );

        final run = surface.run(QuickActionKind.syncNow);
        surface.cancel(QuickActionKind.syncNow);
        final result = await run;

        expect(result.phase, QuickActionPhase.cancelled);
        expect(surface.audit.single.outcome, QuickActionAuditOutcome.cancelled);
      });

      test('a cancelled action can be run again afterwards', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          execute: (kind) async => 'Synced',
        );

        surface.cancel(QuickActionKind.syncNow);
        expect(
          (await surface.run(QuickActionKind.syncNow)).phase,
          QuickActionPhase.cancelled,
        );
        expect((await surface.run(QuickActionKind.syncNow)).isSuccess, isTrue);
      });

      test('results are exposed as an unmodifiable view', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          execute: (kind) async => 'Synced',
        );

        await surface.run(QuickActionKind.syncNow);

        expect(() => surface.results.clear(), throwsUnsupportedError);
      });
    });

    group('audit', () {
      test('each attempt appends exactly one event', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          execute: (kind) async => 'Synced',
        );

        await surface.run(QuickActionKind.syncNow);
        await surface.run(QuickActionKind.syncNow);

        expect(surface.audit, hasLength(2));
        expect(
          surface.audit.every(
            (event) => event.outcome == QuickActionAuditOutcome.succeeded,
          ),
          isTrue,
        );
        expect(
          surface.audit.map((event) => event.action),
          everyElement(QuickActionKind.syncNow),
        );
        expect(surface.audit.every((event) => event.at.isUtc), isTrue);
      });

      test('a denial is audited before it throws', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet(
            denied: <QuickActionKind>{QuickActionKind.syncNow},
          ),
          execute: (kind) async => 'Synced',
        );

        expect(
          () => surface.run(QuickActionKind.syncNow),
          throwsA(isA<QuickActionStateError>()),
        );

        expect(surface.audit, hasLength(1));
        expect(surface.audit.single.outcome, QuickActionAuditOutcome.denied);
        expect(surface.audit.single.reason, isNotNull);
      });

      test('a missing-confirmation attempt is audited as denied', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          execute: (kind) async => 'Synced',
        );

        expect(
          () => surface.run(QuickActionKind.backupNow),
          throwsA(isA<QuickActionStateError>()),
        );

        expect(surface.audit.single.outcome, QuickActionAuditOutcome.denied);
        expect(surface.audit.single.reason, contains('confirm'));
      });

      test('a failed run is audited as failed with a reason', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          execute: (kind) async => throw StateError('nope'),
        );

        await surface.run(QuickActionKind.syncNow);

        expect(surface.audit.single.outcome, QuickActionAuditOutcome.failed);
        expect(surface.audit.single.reason, isNotNull);
      });

      test('audit never carries the executor payload of a success', () async {
        final surface = _surface(
          permissions: const QuickActionPermissionSet.grantedAll(),
          execute: (kind) async => 'secret-token-value',
        );

        await surface.run(QuickActionKind.syncNow);

        final rendered = surface.audit
            .map((event) => jsonEncode(event.toPublicJson()))
            .join(' ');
        expect(rendered, isNot(contains('secret-token-value')));
        expect(surface.audit.single.reason, isNull);
      });

      test('audit is exposed as an unmodifiable view', () {
        expect(() => _surface().audit.clear(), throwsUnsupportedError);
      });
    });

    test('surface metadata mirrors the unverified product-spec state', () {
      expect(
        AccountCenterQuickActions.billingContractStatus,
        'PLANNED_NOT_VERIFIED',
      );
      expect(AccountCenterQuickActions.referenceMockValuesAllowed, isFalse);
      expect(AccountCenterQuickActions.externalGateStatus, 'DEFERRED-EXTERNAL');
    });
  });
}

AccountCenterQuickActions _surface({
  Set<QuickActionKind>? actions,
  QuickActionPermissionSet? permissions,
  QuickActionExecutor? execute,
  QuickActionReauthentication? reauthenticate,
  DateTime Function()? now,
}) {
  return AccountCenterQuickActions(
    actions: actions ?? _allActions,
    permissions: permissions,
    executor: execute ?? (QuickActionKind kind) async => 'Done',
    reauthenticate: reauthenticate,
    now: now,
  );
}
