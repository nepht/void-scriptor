import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_storage_connector_interface.dart';

void main() {
  group('119.12 Storage Connector Interface', () {
    test('root handles are opaque and malformed handles are dropped', () {
      final root = StorageRootId.tryParse('storageref:drive:primary');
      expect(root, isNotNull);
      expect(root!.value, 'storageref:drive:primary');
      expect(root.toString(), '[REDACTED]');
      expect(StorageRootId.tryParse('raw-root'), isNull);
      expect(StorageRootId.tryParse('/mnt/data'), isNull);

      final roots = StorageConnectorInterface.listRoots(<String>[
        'storageref:drive:primary',
        'raw-root',
        'storageref:cloud:backup',
      ]);
      expect(roots, hasLength(2));
      expect(roots.last.value, 'storageref:cloud:backup');
    });

    test('paths are canonicalized and escapes fail closed', () {
      expect(StorageConnectorInterface.canonicalPath('a/b/c'), 'a/b/c');
      expect(StorageConnectorInterface.canonicalPath('a//b'), 'a/b');
      expect(StorageConnectorInterface.canonicalPath('./a/./b'), 'a/b');

      expect(StorageConnectorInterface.canonicalPath('a/../b'), isNull);
      expect(StorageConnectorInterface.canonicalPath('../etc'), isNull);
      expect(StorageConnectorInterface.canonicalPath('/etc/passwd'), isNull);
      expect(StorageConnectorInterface.canonicalPath('C:/windows'), isNull);
      expect(StorageConnectorInterface.canonicalPath(r'a\b'), isNull);
      expect(StorageConnectorInterface.canonicalPath('   '), isNull);
    });

    test('entry metadata is provider-neutral and UTC-normalized', () {
      final entry = StorageEntry(
        path: 'notes/a.md',
        isDirectory: false,
        sizeBytes: 42,
        revision: 'rev-0007',
        modifiedUtc: DateTime.utc(2026, 1, 1),
      );

      final json = entry.toJson();
      expect(json['path'], 'notes/a.md');
      expect(json['is_directory'], isFalse);
      expect(json['size_bytes'], 42);
      expect(json['revision'], 'rev-0007');
      expect(json['modified_utc'], '2026-01-01T00:00:00.000Z');
    });

    test('every operation is denied without its declared permission', () {
      expect(
        StorageConnectorInterface.authorize(
          StoragePermission.readEntries,
          <StoragePermission>{StoragePermission.readEntries},
        ),
        StorageOperationResult.ok,
      );
      expect(
        StorageConnectorInterface.authorize(
          StoragePermission.writeDelete,
          <StoragePermission>{StoragePermission.readEntries},
        ),
        StorageOperationResult.deniedMissingPermission,
      );
      expect(
        StorageConnectorInterface.authorize(
          StoragePermission.writeUpload,
          <StoragePermission>{},
        ),
        StorageOperationResult.deniedMissingPermission,
      );
    });

    test('delete is denied without explicit confirmation', () {
      expect(
        StorageConnectorInterface.delete('a/b.txt', confirmed: false),
        StorageOperationResult.deniedUnconfirmed,
      );
      expect(
        StorageConnectorInterface.delete('a/b.txt', confirmed: true),
        StorageOperationResult.ok,
      );
      expect(
        StorageConnectorInterface.delete('../escape.txt', confirmed: true),
        StorageOperationResult.deniedInvalidPath,
      );
    });

    test('delta classifies uploads, downloads, deletes, and conflicts', () {
      final plan = StorageConnectorInterface.planDelta(
        localRevisions: <String, String>{'a': 'r1', 'b': 'r2', 'd': 'r4'},
        remoteRevisions: <String, String>{'b': 'r9', 'c': 'r3', 'd': 'r4'},
        removedLocally: <String>{'d'},
      );

      expect(plan.uploads, <String>['a']);
      expect(plan.downloads, <String>['c']);
      expect(plan.deletes, <String>['d']);
      expect(plan.conflicts, <String>['b']);
      expect(plan.requiresResolution, isTrue);
      expect(plan.isEmpty, isFalse);
    });

    test('delta is empty when revisions already agree', () {
      final plan = StorageConnectorInterface.planDelta(
        localRevisions: <String, String>{'a': 'r1'},
        remoteRevisions: <String, String>{'a': 'r1'},
      );

      expect(plan.isEmpty, isTrue);
      expect(plan.requiresResolution, isFalse);
      expect(plan.uploads, isEmpty);
      expect(plan.downloads, isEmpty);
      expect(plan.deletes, isEmpty);
    });

    test('health reports unavailable, degraded, and ok deterministically', () {
      expect(
        StorageConnectorInterface.health(
          reachable: false,
          authorized: true,
          withinQuota: true,
        ),
        StorageHealthStatus.unavailable,
      );
      expect(
        StorageConnectorInterface.health(
          reachable: true,
          authorized: false,
          withinQuota: true,
        ),
        StorageHealthStatus.degraded,
      );
      expect(
        StorageConnectorInterface.health(
          reachable: true,
          authorized: true,
          withinQuota: false,
        ),
        StorageHealthStatus.degraded,
      );
      expect(
        StorageConnectorInterface.health(
          reachable: true,
          authorized: true,
          withinQuota: true,
        ),
        StorageHealthStatus.ok,
      );
    });

    test('diagnostics redact opaque storage references', () {
      expect(
        StorageConnectorInterface.redact(
          'root storageref:drive:primary failed',
        ),
        'root [REDACTED] failed',
      );
      expect(
        StorageConnectorInterface.redact('jobref:export:primary'),
        '[REDACTED]',
      );
    });

    test('validates the canonical manifest and rejects missing methods', () {
      expect(StorageConnectorInterface.validateCanonicalManifest(), isEmpty);

      final missing = <String, dynamic>{
        'canonical_step': '119.12',
        'unknown_field_policy': 'REJECT',
        'required_methods': <String>['list_roots'],
        'acceptance': <String, dynamic>{},
      };
      expect(
        StorageConnectorInterface.validateManifest(missing),
        containsAll(<String>[
          'method_missing:list_entries',
          'method_missing:delta',
          'method_missing:health',
          'acceptance_missing:permissions',
        ]),
      );
      expect(
        StorageConnectorInterface.validateManifest(<String, dynamic>{
          'canonical_step': '119.11',
          'unknown_field_policy': 'ALLOW',
        }),
        containsAll(<String>[
          'canonical_step_invalid',
          'unknown_field_policy_invalid',
        ]),
      );
    });
  });
}
