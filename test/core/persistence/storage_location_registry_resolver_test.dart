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
    'legacy location choice is copied once without deleting its source',
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
      expect(await legacy.readAsString(), content);

      await legacy.writeAsString('changed legacy');
      final second = await const StorageLocationRegistryResolver().resolve(
        applicationSupportDirectory: support,
        legacyFile: legacy,
      );
      expect(await second.readAsString(), content);
    },
  );
}
