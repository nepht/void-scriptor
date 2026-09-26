import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_loading_empty_error_states.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_loading_empty_error_states.json',
  );

  test('pins the canonical step and required state vocabulary', () {
    expect(manifestFile.existsSync(), isTrue);
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    expect(manifest['canonical_step'], '115.42');
    expect(
      manifest['required_states'],
      AccountCenterLoadingEmptyErrorStates.canonicalRequiredStates,
    );
    expect(
      AccountCenterLoadingEmptyErrorStates.canonicalSprintSha256,
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
    );
  });

  test('exposes explicit loading and empty states without fabricated data', () {
    final loading = AccountCenterLoadingEmptyErrorStates.loading(
      source: 'storage',
    );
    expect(loading.state, AccountCenterSurfaceState.loading);
    expect(loading.message, 'Loading storage…');
    expect(loading.hasData, isFalse);
    expect(loading.canRetry, isFalse);

    final empty = AccountCenterLoadingEmptyErrorStates.empty(source: 'storage');
    expect(empty.state, AccountCenterSurfaceState.empty);
    expect(empty.message, 'No storage data available.');
    expect(empty.hasData, isFalse);
    expect(empty.canRetry, isFalse);
  });

  test('preserves partial data and identifies recovery actions', () {
    final partial = AccountCenterLoadingEmptyErrorStates.partial(
      source: 'storage',
      availableItemCount: 3,
      unavailableReason: 'One provider did not respond.',
    );
    expect(partial.state, AccountCenterSurfaceState.partial);
    expect(partial.hasData, isTrue);
    expect(partial.availableItemCount, 3);
    expect(partial.message, contains('One provider did not respond.'));
    expect(partial.canRetry, isTrue);

    final offline = AccountCenterLoadingEmptyErrorStates.offline(
      source: 'storage',
      hasCachedData: true,
    );
    expect(offline.state, AccountCenterSurfaceState.offline);
    expect(offline.hasData, isTrue);
    expect(offline.canRetry, isTrue);
    expect(offline.message, contains('cached'));
  });

  test(
    'models denied, limited, outage, unavailable, and error fail-closed',
    () {
      final denied = AccountCenterLoadingEmptyErrorStates.permissionDenied(
        source: 'billing',
        message: 'Permission is required to view billing.',
      );
      expect(denied.state, AccountCenterSurfaceState.permissionDenied);
      expect(denied.canRetry, isFalse);
      expect(denied.requiresPermission, isTrue);

      final limited = AccountCenterLoadingEmptyErrorStates.rateLimited(
        source: 'provider',
        retryAfter: const Duration(minutes: 2),
      );
      expect(limited.state, AccountCenterSurfaceState.rateLimited);
      expect(limited.canRetry, isTrue);
      expect(limited.message, contains('2 minutes'));

      final outage = AccountCenterLoadingEmptyErrorStates.outage(
        source: 'provider',
      );
      expect(outage.state, AccountCenterSurfaceState.outage);
      expect(outage.canRetry, isTrue);

      final unavailable = AccountCenterLoadingEmptyErrorStates.unavailable(
        source: 'provider',
        reason: 'Connector is not configured.',
      );
      expect(unavailable.state, AccountCenterSurfaceState.unavailable);
      expect(unavailable.canRetry, isFalse);

      final error = AccountCenterLoadingEmptyErrorStates.error(
        source: 'provider',
        message: 'The provider connection failed.',
        canRetry: true,
      );
      expect(error.state, AccountCenterSurfaceState.error);
      expect(error.canRetry, isTrue);
      expect(error.message, 'The provider connection failed.');
    },
  );

  test('reauth preserves local data and requires explicit action', () {
    final state = AccountCenterLoadingEmptyErrorStates.reauth(
      source: 'provider',
      hasLocalData: true,
    );
    expect(state.state, AccountCenterSurfaceState.reauth);
    expect(state.hasData, isTrue);
    expect(state.requiresReauthentication, isTrue);
    expect(state.canRetry, isFalse);
    expect(state.message, contains('Reauthenticate'));
  });

  test('rejects unsafe or ambiguous construction', () {
    expect(
      () => AccountCenterLoadingEmptyErrorStates.loading(source: ' '),
      throwsArgumentError,
    );
    expect(
      () => AccountCenterLoadingEmptyErrorStates.partial(
        source: 'storage',
        availableItemCount: -1,
        unavailableReason: 'missing',
      ),
      throwsArgumentError,
    );
    expect(
      () => AccountCenterLoadingEmptyErrorStates.error(
        source: 'provider',
        message: 'Bearer secret',
        canRetry: true,
      ),
      throwsArgumentError,
    );
    expect(
      () => AccountCenterLoadingEmptyErrorStates.rateLimited(
        source: 'provider',
        retryAfter: Duration.zero,
      ),
      throwsArgumentError,
    );
  });
}
