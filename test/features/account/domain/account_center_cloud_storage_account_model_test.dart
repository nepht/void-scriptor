import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_cloud_storage_account_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_cloud_storage_account_model.json',
  );

  group('115.16 Cloud Storage Account Model contract', () {
    test('pins the canonical step and required fields', () {
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;

      expect(manifest['canonical_step'], '115.16');
      expect(manifest['acceptance'], <String>[
        'account_id',
        'provider_id',
        'capabilities',
        'root_scope',
        'quota_support',
        'sync_support',
        'backup_support',
        'freshness',
      ]);
      expect(manifest['boundary'], contains('does not claim'));
    });

    test('models an account with explicit capabilities and root scope', () {
      final account = CloudStorageAccount(
        accountId: 'google/account-42',
        providerId: 'google_drive',
        displayName: 'Writing Drive',
        capabilities: const {
          CloudStorageCapability.storage,
          CloudStorageCapability.sync,
        },
        rootScope: CloudStorageRootScope.account,
        quotaSupport: CloudStorageSupport.supported,
        syncSupport: CloudStorageSupport.supported,
        backupSupport: CloudStorageSupport.unsupported,
        freshness: CloudStorageFreshness.unknown,
      );

      expect(account.accountId, 'google/account-42');
      expect(account.providerId, 'google_drive');
      expect(account.capabilities, {
        CloudStorageCapability.storage,
        CloudStorageCapability.sync,
      });
      expect(account.rootScope, CloudStorageRootScope.account);
      expect(account.quotaSupport, CloudStorageSupport.supported);
      expect(account.syncSupport, CloudStorageSupport.supported);
      expect(account.backupSupport, CloudStorageSupport.unsupported);
      expect(account.freshness, CloudStorageFreshness.unknown);
    });

    test('normalizes identifiers and prevents mutable capability state', () {
      final account = CloudStorageAccount(
        accountId: '  account-1 ',
        providerId: '  OneDrive ',
        displayName: ' Personal ',
        capabilities: const {CloudStorageCapability.storage},
        rootScope: CloudStorageRootScope.account,
        quotaSupport: CloudStorageSupport.unknown,
        syncSupport: CloudStorageSupport.unsupported,
        backupSupport: CloudStorageSupport.unknown,
        freshness: CloudStorageFreshness.stale,
      );

      expect(account.accountId, 'account-1');
      expect(account.providerId, 'onedrive');
      expect(account.displayName, 'Personal');
      expect(
        () => account.capabilities.add(CloudStorageCapability.backup),
        throwsUnsupportedError,
      );
    });

    test(
      'rejects blank identity, empty capabilities, and invalid freshness',
      () {
        CloudStorageAccount build({
          String accountId = 'account-1',
          Iterable<CloudStorageCapability> capabilities = const {
            CloudStorageCapability.storage,
          },
          CloudStorageFreshness freshness = CloudStorageFreshness.unknown,
        }) => CloudStorageAccount(
          accountId: accountId,
          providerId: 'drive',
          displayName: 'Drive',
          capabilities: capabilities,
          rootScope: CloudStorageRootScope.account,
          quotaSupport: CloudStorageSupport.unknown,
          syncSupport: CloudStorageSupport.unknown,
          backupSupport: CloudStorageSupport.unknown,
          freshness: freshness,
        );

        expect(() => build(accountId: ' '), throwsArgumentError);
        expect(() => build(capabilities: const {}), throwsArgumentError);
        expect(
          () => build(freshness: CloudStorageFreshness.invalid),
          throwsArgumentError,
        );
      },
    );
  });
}
