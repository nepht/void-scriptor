import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/persistence/storage_location_registry_resolver.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('storage-registry-resolver-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'machine registry lives in application support, outside project root',
    () async {
      final support = Directory(p.join(root.path, 'support'));
      final legacy = File(
        p.join(root.path, 'documents', 'storage_locations.json'),
      );

      final resolved = await const StorageLocationRegistryResolver().resolve(
        applicationSupportDirectory: support,
        legacyFile: legacy,
      );

      expect(
        resolved.path,
        p.join(support.path, 'VoidScriptor', 'storage_locations.json'),
      );
      expect(await resolved.exists(), isFalse);
    },
  );

  test(
    // BUG-23 (hunt run197, Referee REAL BUG): contract evolution from the old
    // "copied once without deleting its source" — a one-way copy that never
    // consumes the source lets stale legacy content resurrect over newer
    // durable state if the preferred file is later lost. The source is now
    // consumed by renaming it to <name>.imported (content preserved, not
    // destroyed); the original migration intent (copy once, legacy edits must
    // not override the preferred registry) is unchanged.
    'legacy location choice is migrated once and its source is consumed',
    () async {
      final support = Directory(p.join(root.path, 'support'));
      final legacy = File(
        p.join(root.path, 'documents', 'storage_locations.json'),
      );
      await legacy.parent.create(recursive: true);
      const content =
          '{"schemaVersion":1,"activeLocation":"D:/VoidScriptor_Data/Projects","boundProjectId":null}\n';
      await legacy.writeAsString(content);

      final resolved = await const StorageLocationRegistryResolver().resolve(
        applicationSupportDirectory: support,
        legacyFile: legacy,
      );

      expect(await resolved.readAsString(), content);
      expect(await legacy.exists(), isFalse);
      final imported = File(
        p.join(
          legacy.parent.path,
          '${StorageLocationRegistryResolver.fileName}.imported',
        ),
      );
      expect(await imported.exists(), isTrue);
      expect(await imported.readAsString(), content);

      await legacy.writeAsString('changed legacy');
      final second = await const StorageLocationRegistryResolver().resolve(
        applicationSupportDirectory: support,
        legacyFile: legacy,
      );
      expect(await second.readAsString(), content);
    },
  );

  test('losing the preferred registry cannot re-import the consumed legacy '
      'source (BUG-23 run197)', () async {
    final support = Directory(p.join(root.path, 'support'));
    final preferred = File(
      p.join(support.path, 'VoidScriptor', 'storage_locations.json'),
    );
    final legacy = File(
      p.join(root.path, 'documents', 'storage_locations.json'),
    );
    await legacy.parent.create(recursive: true);
    const content =
        '{"schemaVersion":1,"activeLocation":"D:/VoidScriptor_Data/Projects","boundProjectId":null}\n';
    await legacy.writeAsString(content);

    await const StorageLocationRegistryResolver().resolve(
      applicationSupportDirectory: support,
      legacyFile: legacy,
    );

    // Crash window: the preferred file AND its recovery .bak are lost. The
    // legacy source was consumed at migration time, so nothing may import
    // stale registry state back over the vacated preferred path.
    await preferred.delete();
    final bak = File('${preferred.path}.bak');
    if (await bak.exists()) await bak.delete();

    final resolved = await const StorageLocationRegistryResolver().resolve(
      applicationSupportDirectory: support,
      legacyFile: legacy,
    );

    expect(await legacy.exists(), isFalse);
    expect(await resolved.exists(), isFalse);
  });
}
